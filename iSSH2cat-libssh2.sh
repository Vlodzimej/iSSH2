#!/bin/bash
                                   #########
#################################### iSSH2 #####################################
#                                  #########                                   #
# Copyright (c) 2013 Tommaso Madonia. All rights reserved.                     #
#                                                                              #
# Permission is hereby granted, free of charge, to any person obtaining a copy #
# of this software and associated documentation files (the "Software"), to deal#
# in the Software without restriction, including without limitation the rights #
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell    #
# copies of the Software, and to permit persons to whom the Software is        #
# furnished to do so, subject to the following conditions:                     #
#                                                                              #
# The above copyright notice and this permission notice shall be included in   #
# all copies or substantial portions of the Software.                          #
#                                                                              #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR   #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,     #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE  #
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER       #
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,#
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN    #
# THE SOFTWARE.                                                                #
################################################################################

source "$BASEPATH/iSSH2-commons"

set -e

mkdir -p "$LIBSSHDIR"

LIBSSH_TAR="libssh2-$LIBSSH_VERSION.tar.gz"

downloadFile "http://www.libssh2.org/download/$LIBSSH_TAR" "$LIBSSHDIR/$LIBSSH_TAR"

LIBSSHSRC="$LIBSSHDIR/src/"
mkdir -p "$LIBSSHSRC"

set +e
echo "Extracting $LIBSSH_TAR"
tar -zxkf "$LIBSSHDIR/$LIBSSH_TAR" -C "$LIBSSHDIR/src" --strip-components 1 2>&-
set -e

OSX_PLATFORM="macosx"
OSX_VERSION=10.15
OSX_PLATFORM="$(platformName "$OSX_PLATFORM" "x86_64")"
OSX_PLATFORM_OUT="$LIBSSHDIR/${OSX_PLATFORM}_$OSX_VERSION-x86_64/install"
OSX_LIPO_SSH2="$OSX_PLATFORM_OUT/lib/libssh2.a"

echo "Building Libssh2 $LIBSSH_VERSION:"

for ARCH in $ARCHS
do
  PLATFORM="$(platformName "$SDK_PLATFORM" "$ARCH")"
  OPENSSLDIR="$BASEPATH/openssl_$SDK_PLATFORM/"
  PLATFORM_SRC="$LIBSSHDIR/${PLATFORM}_$SDK_VERSION-$ARCH/src"
  PLATFORM_OUT="$LIBSSHDIR/${PLATFORM}_$SDK_VERSION-$ARCH/install"
  LIPO_SSH2="$LIPO_SSH2 $PLATFORM_OUT/lib/libssh2.a"

  if [[ -f "$PLATFORM_OUT/lib/libssh2.a" ]] && [[ "$ARCH" != "x86_64" ]]; then
    echo "libssh2.a for $ARCH already exists in $PLATFORM_OUT/lib/"
  else
    rm -rf "$PLATFORM_SRC"
    rm -rf "$PLATFORM_OUT"
    mkdir -p "$PLATFORM_OUT"
    cp -R "$LIBSSHSRC" "$PLATFORM_SRC"
    cd "$PLATFORM_SRC"

    LOG="$PLATFORM_OUT/build-libssh2.log"
    touch $LOG

    if [[ "$ARCH" == arm64* ]]; then
      HOST="aarch64-apple-darwin"
    else
      HOST="$ARCH-apple-darwin"
    fi

    export DEVROOT="$DEVELOPER/Platforms/$PLATFORM.platform/Developer"
    export SDKROOT="$DEVROOT/SDKs/$PLATFORM$SDK_VERSION.sdk"
    export CC="$CLANG"
    export CPP="$CLANG -E"
    export CFLAGS="-arch $ARCH -pipe -no-cpp-precomp -isysroot $SDKROOT -m$SDK_PLATFORM-version-min=$MIN_VERSION $EMBED_BITCODE"
    export CPPFLAGS="-arch $ARCH -pipe -no-cpp-precomp -isysroot $SDKROOT -m$SDK_PLATFORM-version-min=$MIN_VERSION"

    if [[ "$ARCH" == "x86_64" ]] && [[ "$MIN_VERSION" == "10.15" ]]; then
      SDK_PLATFORM="macosx"
      SDK_VERSION=`xcrun --sdk $SDK_PLATFORM --show-sdk-version`
      MIN_VERSION=10.15
      PLATFORM="$OSX_PLATFORM"
      PLATFORM_OUT="$OSX_PLATFORM_OUT"
      LIPO_SSH2="$OSX_LIPO_SSH2"
      export DEVROOT="$DEVELOPER/Platforms/$PLATFORM.platform/Developer"
      export SDKROOT="$DEVROOT/SDKs/$PLATFORM$SDK_VERSION.sdk"
      export CC="$CLANG"
      export CPP="$CLANG -E"
      export CFLAGS="-arch $ARCH -pipe -no-cpp-precomp -isysroot $SDKROOT -target x86_64-apple-ios-macabi -m$SDK_PLATFORM-version-min=$MIN_VERSION $EMBED_BITCODE"
      export CPPFLAGS="-arch $ARCH -pipe -no-cpp-precomp -isysroot $SDKROOT -m$SDK_PLATFORM-version-min=$MIN_VERSION"
    fi
    if [[ $(./configure --help | grep -c -- --with-openssl) -eq 0 ]]; then
      CRYPTO_BACKEND_OPTION="--with-crypto=openssl"
    else
      CRYPTO_BACKEND_OPTION="--with-openssl"
    fi
export ARCH="$ARCH"
export PLATFORM_OUT="$PLATFORM_OUT"
export OPENSSLDIR="$OPENSSLDIR"
export HOST="$HOST"
export CC="$CC"
echo CRYPTO_BACKEND_OPTION = $CRYPTO_BACKEND_OPTION
echo OPENSSLDIR = $OPENSSLDIR
echo CFLAGS="-target x86_64-apple-ios-macabi" ./configure --host=$HOST --prefix="$PLATFORM_OUT" --disable-debug --disable-dependency-tracking --disable-silent-rules --disable-examples-build --without-libz $CRYPTO_BACKEND_OPTION --with-libssl-prefix=$TMPDIR/iSSH2/openssl-$LIBSSL_VERSION/MacOSX_$MIN_VERSION-x86_64/install --disable-shared --enable-static
#bash

     CFLAGS="-target x86_64-apple-ios-macabi" ./configure --host=$HOST --prefix="$PLATFORM_OUT" --disable-debug --disable-dependency-tracking --disable-silent-rules --disable-examples-build --without-libz $CRYPTO_BACKEND_OPTION --with-libssl-prefix=$TMPDIR/iSSH2/openssl-$LIBSSL_VERSION/MacOSX_$MIN_VERSION-x86_64/install --disable-shared --enable-static >> "$LOG" 2>&1

# If you get a popup here to install the Command Line Developer Tools: install them and rerun the script
#
# version:          1.9.0
# Host type:        x86_64-apple-darwin
# Install prefix:   /var/folders/ch/5g2lmkmn0ks617mw07xkc_q80000gn/T/iSSH2/libssh2-1.9.0/MacOSX_10.15-x86_64/install
# Compiler:         /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang
# Compiler flags:   -target x86_64-apple-ios-macabi -DLIBSSH2_DARWIN
# Library types:    Shared=no, Static=yes
# Crypto library:   OpenSSL (AES-CTR: yes)
# Clear memory:     unsupported
# Debug build:      no
# Build examples:   no
# Path to sshd:     /usr/sbin/sshd (only for self-tests)
# zlib compression: no

#    if [[ "$ARCH" != "x86_64" ]]; then
#      perl -pi.bak -e "s/-miphoneos-version-min=10.15/-target $ARCH-apple-ios-macabi -miphoneos-version-min=10.15/gi" src/Makefile
#      perl -pi.bak -e "s/-miphoneos-version-min=10.15/-target $ARCH-apple-ios-macabi -miphoneos-version-min=10.15/gi" tests/Makefile
#      perl -pi.bak -e "s/-miphoneos-version-min=10.15/-target $ARCH-apple-ios-macabi -miphoneos-version-min=10.15/gi" Makefile
#    fi
#bash
    make >> "$LOG" 2>&1
    make -j "$BUILD_THREADS" install >> "$LOG" 2>&1

    echo "- $PLATFORM $ARCH done!"
  fi
done

find $PLATFORM_OUT -name libssh2.a

if [[ -f "$OSX_LIPO_SSH2" ]] && [[ "$ARCH" != "x86_64" ]]; then
  echo "todo: lipo -create $OSX_LIPO_SSH2 $LIPO_SSH2 -output $BASEPATH/libssh2_$SDK_PLATFORM/lib/libssh2.a"
  touch "$BASEPATH/libssh2_$SDK_PLATFORM/lib/libssh2.a"
else
  echo "todo: lipo -create $LIPO_SSH2 -output $BASEPATH/libssh2_iphoneos/lib/libssh2.a"
fi

importHeaders "$LIBSSHSRC/include/" "$BASEPATH/libssh2_$SDK_PLATFORM/include"

echo "Building Mac Catalyst libssh2 lib done."
