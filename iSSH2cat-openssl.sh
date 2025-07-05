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

mkdir -p "$LIBSSLDIR"

LIBSSL_TAR="openssl-$LIBSSL_VERSION.tar.gz"

downloadFile "https://www.openssl.org/source/$LIBSSL_TAR" "$LIBSSLDIR/$LIBSSL_TAR"

LIBSSLSRC="$LIBSSLDIR/src/"
mkdir -p "$LIBSSLSRC"

set +e
echo "Extracting $LIBSSL_TAR"
tar -zxkf "$LIBSSLDIR/$LIBSSL_TAR" -C "$LIBSSLSRC" --strip-components 1 2>&-
set -e

echo "Building OpenSSL $LIBSSL_VERSION, please wait..."

for ARCH in $ARCHS
do
  if [[ "$SDK_PLATFORM" == "macosx" ]]; then
    CONF="no-shared"
  else
    CONF="no-asm no-hw no-shared no-async"
  fi

  PLATFORM="$(platformName "$SDK_PLATFORM" "$ARCH")"
  OPENSSLDIR="$LIBSSLDIR/${PLATFORM}_$MIN_VERSION-$ARCH"
  PLATFORM_OUT="$LIBSSLDIR/${PLATFORM}_$MIN_VERSION-$ARCH/install"
  LIPO_LIBSSL="$LIPO_LIBSSL $OPENSSLDIR/libssl.a"
  LIPO_LIBCRYPTO="$LIPO_LIBCRYPTO $OPENSSLDIR/libcrypto.a"

  if [[ -f "$OPENSSLDIR/libssl.a" ]] && [[ -f "$OPENSSLDIR/libcrypto.a" ]] ; then
    echo "libssl.a and libcrypto.a for $ARCH already exist in $OPENSSLDIR"
  else
    rm -rf "$OPENSSLDIR"
    cp -R "$LIBSSLSRC"  "$OPENSSLDIR"
    cd "$OPENSSLDIR"

    LOG="$OPENSSLDIR/build-openssl.log"
    touch $LOG

    if [[ "$MIN_VERSION" == "10.15" ]]; then
      HOST="darwin64-$ARCH-cc"
      SDK_PLATFORM="macosx"
      CONF="no-shared"
      SDK_VERSION=`xcrun --sdk $SDK_PLATFORM --show-sdk-version`
      PLATFORM="$(platformName "$SDK_PLATFORM" "$ARCH")"
      OPENSSLDIR="$LIBSSLDIR/${PLATFORM}_$MIN_VERSION-$ARCH"
      PLATFORM_OUT="$LIBSSLDIR/${PLATFORM}_$MIN_VERSION-$ARCH/install"
    else
      HOST="iphoneos-cross"
    fi
    if [[ "${ARCH}" == *64 ]] || [[ "${ARCH}" == arm64* ]]; then
      CONF="$CONF enable-ec_nistp_64_gcc_128"
    fi

    export CROSS_TOP="$DEVELOPER/Platforms/$PLATFORM.platform/Developer"
    export CROSS_SDK="$PLATFORM$SDK_VERSION.sdk"
    export SDKROOT="$CROSS_TOP/SDKs/$CROSS_SDK"
    export CC="$CLANG -arch $ARCH"

    CONF="$CONF -m$SDK_PLATFORM-version-min=$MIN_VERSION $EMBED_BITCODE"
    ./Configure $HOST --prefix=$PLATFORM_OUT $CONF

    sed -ie "s!^CFLAG=!CFLAG=-isysroot $SDKROOT !" "Makefile"
    if [[ "$MIN_VERSION" == "10.15" ]]; then
      echo "Building OpenSSL $LIBSSL_VERSION $ARCH for $HOST, please wait..."
    fi
    make depend >> "$LOG" 2>&1
    make -j "$BUILD_THREADS" build_libs >> "$LOG" 2>&1
    if [[ "$MIN_VERSION" == "10.15" ]]; then
      if [ -f $PLATFORM_OUT ]
      then
        rm -f $PLATFORM_OUT
      fi
      mkdir -p $PLATFORM_OUT
      make install >> "$LOG" 2>&1
    fi
#bash
    if [[ "$MIN_VERSION" == "10.15" ]]; then
      SDK_PLATFORM="macosx"
      echo "SDK_VERSION = $SDK_VERSION"
      SDK_VERSION="14.4"
      PLATFORM="$(platformName "$SDK_PLATFORM" "$ARCH")"
      OPENSSLDIR="$LIBSSLDIR/${PLATFORM}_$MIN_VERSION-$ARCH"
    fi

    if [[ "$MIN_VERSION" == "10.15" ]]; then
      echo "- Mac Catalyst for $HOST $ARCH done!"
    else
      echo "- $PLATFORM $ARCH done!"
    fi

  fi
done

lipoFatLibrary "$LIPO_LIBSSL" "$BASEPATH/openssl_$SDK_PLATFORM/lib/libssl.a"
lipoFatLibrary "$LIPO_LIBCRYPTO" "$BASEPATH/openssl_$SDK_PLATFORM/lib/libcrypto.a"

importHeaders "$OPENSSLDIR/include/" "$BASEPATH/openssl_$SDK_PLATFORM/include"

echo "Building Mac Catalyst openssl lib done."
