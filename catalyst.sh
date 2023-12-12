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

export SCRIPTNAME="iSSH2"

#Functions

getLibssh2Version () {
  if type git >/dev/null 2>&1; then
    LIBSSH_VERSION=`git ls-remote --tags https://github.com/libssh2/libssh2.git | egrep "libssh2-[0-9]+\.[1-9][0-9](\.[0-9])*[a-zA-Z]?$" | cut -f 2 -d - | sort -t . -r | head -n 1`
    LIBSSH_AUTO=true
  else
    echo "Install git to automatically get the latest Libssh2 version or use the --libssh2 argument"
    echo "Try '$SCRIPTNAME --help' for more information."
    exit 2
  fi
}

getOpensslVersion () {
  if type git >/dev/null 2>&1; then
    LIBSSL_VERSION=`git ls-remote --tags git://git.openssl.org/openssl.git | egrep "openssl-3\.0\.([1-9][0-9])[a-zA-Z]?$" | cut -f 2 -d - | sort -t . -r | head -n 1`
    LIBSSL_AUTO=true
  else
    echo "Install git to automatically get the latest OpenSSL version or use the --openssl argument"
    echo "Try '$SCRIPTNAME --help' for more information."
    exit 2
  fi
}

getBuildSetting () {
  echo "${1}" | grep -i "^\s*${2}\s*=\s*" | cut -d= -f2 | xargs echo -n
}

version () {
  printf "%02d%02d%02d" ${1//./ }
}

#Config

export SDK_VERSION=
export LIBSSH_VERSION=
export LIBSSL_VERSION=
export MIN_VERSION=8.0
export ARCHS=x86_64
export SDK_PLATFORM=iphoneos
export EMBED_BITCODE="-fembed-bitcode"

BUILD_OSX=false
BUILD_SSL=true
BUILD_SSH=true
CLEAN_BUILD=true

XCODE_PROJECT=
TARGET_NAME=

echo "Initializing..."

XCODE_VERSION=`xcodebuild -version | grep Xcode | cut -d' ' -f2`

if [[ ! -z "$XCODE_PROJECT" ]] && [[ ! -z "$TARGET_NAME" ]]; then
  BUILD_SETTINGS=`xcodebuild -project "$XCODE_PROJECT" -target "$TARGET_NAME" -showBuildSettings`
fi

if [[ -z "$MIN_VERSION" ]]; then
  echo "$SCRIPTNAME: Minimum platform version must be specified."
  echo "Run '$SCRIPTNAME --help' for more information."
  exit 1
fi

if [[  "$SDK_PLATFORM" == "macosx" ]] || [[ "$SDK_PLATFORM" == "iphoneos" ]] || [[ "$SDK_PLATFORM" == "appletvos" ]] || [[ "$SDK_PLATFORM" == "watchos" ]]; then
  if [[ -z "$ARCHS" ]]; then
    ARCHS="$TARGET_ARCHS"

    if [[ "$SDK_PLATFORM" == "macosx" ]]; then
      if [[ -z "$ARCHS" ]]; then
        ARCHS="x86_64"
      fi
    elif [[ "$SDK_PLATFORM" == "iphoneos" ]]; then
      if [[ -z "$ARCHS" ]]; then
        ARCHS="arm64"

        if [[ $(version "$XCODE_VERSION") == $(version "10.1") ]] || [[ $(version "$XCODE_VERSION") > $(version "10.1") ]]; then
          ARCHS="$ARCHS arm64e"
        fi
      fi

      ARCHS="$ARCHS x86_64"

      if [[ $(version "$MIN_VERSION") < $(version "10.0") ]]; then
        ARCHS="$ARCHS"
      fi
    elif [[ "$SDK_PLATFORM" == "appletvos" ]]; then
      ARCHS="$ARCHS arm64 x86_64"
    elif [[ "$SDK_PLATFORM" == "watchos" ]]; then

      if [[ $(version "$XCODE_VERSION") == $(version "10.0") ]] || [[ $(version "$XCODE_VERSION") > $(version "10.0") ]]; then
        ARCHS="$ARCHS arm64_32"
      fi
    fi
  fi
else
  echo "$SCRIPTNAME: Unknown platform '$SDK_PLATFORM'"
  echo "Run '$SCRIPTNAME --help' for more information."
  exit 1
fi

ARCHS="$(echo "$ARCHS" | tr ' ' '\n' | sort -u | tr '\n' ' ')"

LIBSSH_AUTO=false
if [[ -z "$LIBSSH_VERSION" ]]; then
  getLibssh2Version
fi

LIBSSL_AUTO=false
if [[ -z "$LIBSSL_VERSION" ]]; then
  getOpensslVersion
fi

SDK_AUTO=false
if [[ -z "$SDK_VERSION" ]]; then
   SDK_VERSION=`xcrun --sdk $SDK_PLATFORM --show-sdk-version`
   SDK_AUTO=true
fi

export BUILD_THREADS=$(sysctl hw.ncpu | awk '{print $2}')

export CLANG=`xcrun --find clang`
export GCC=`xcrun --find gcc`
export DEVELOPER=`xcode-select --print-path`

export BASEPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export TEMPPATH="$TMPDIR$SCRIPTNAME"
export LIBSSLDIR="$TEMPPATH/openssl-$LIBSSL_VERSION"
export LIBSSHDIR="$TEMPPATH/libssh2-$LIBSSH_VERSION"

#Env

echo
if [[ $LIBSSH_AUTO == true ]]; then
  echo "Libssh2 version: $LIBSSH_VERSION (Automatically detected)"
else
  echo "Libssh2 version: $LIBSSH_VERSION"
fi

if [[ $LIBSSL_AUTO == true ]]; then
  echo "OpenSSL version: $LIBSSL_VERSION (Automatically detected)"
else
  echo "OpenSSL version: $LIBSSL_VERSION"
fi

if [[ $SDK_AUTO == true ]]; then
  echo "SDK version: $SDK_VERSION (Automatically detected)"
else
  echo "SDK version: $SDK_VERSION"
fi

echo "Xcode version: $XCODE_VERSION (Automatically detected)"
echo "Architectures: $ARCHS"
echo "Platform: $SDK_PLATFORM"
echo "Platform min version: $MIN_VERSION"
echo

#Build

set -e

rm -rf $TMPDIR/iSSH2
./iSSH2.sh --platform=iphoneos --min-version=8.0 --sdk-version=$SDK_VERSION --archs="arm64 arm64e"
rm -rf ./libssh2_iphoneos/lib
rm -rf ./openssl_iphoneos/lib
OSX_MIN_VERSION="10.15"
OSX_SDK_PLATFORM="MacOSX"
OSX_SDK_VERSION=`xcrun --sdk macosx --show-sdk-version`
echo CFLAGS="-target x86_64-apple-ios-macabi" ./iSSH2cat.sh --platform=iphoneos --target=macosx --min-version=$OSX_MIN_VERSION --archs="x86_64" --sdk-version=$SDK_VERSION
CFLAGS="-target x86_64-apple-ios-macabi" ./iSSH2cat.sh --platform=iphoneos --target=macosx --min-version=$OSX_MIN_VERSION --archs="x86_64" --sdk-version=$SDK_VERSION
echo "Building fat files"
mkdir -p ./libssh2_iphoneos/lib
mkdir -p ./openssl_iphoneos/lib
lipo -create ${TMPDIR}iSSH2/libssh2-$LIBSSH_VERSION/${OSX_SDK_PLATFORM}_${OSX_MIN_VERSION}-x86_64/install/lib/libssh2.a \
${TMPDIR}iSSH2/libssh2-$LIBSSH_VERSION/iPhoneOS_$SDK_VERSION-arm64/install/lib/libssh2.a \
${TMPDIR}iSSH2/libssh2-$LIBSSH_VERSION/iPhoneOS_$SDK_VERSION-arm64e/install/lib/libssh2.a -output ./libssh2_iphoneos/lib/libssh2.a
echo lipo -create \${TMPDIR}iSSH2/libssh2-$LIBSSH_VERSION/${OSX_SDK_PLATFORM}_${OSX_MIN_VERSION}-x86_64/install/lib/libssh2.a \\
echo \${TMPDIR}iSSH2/libssh2-$LIBSSH_VERSION/iPhoneOS_$SDK_VERSION-arm64/install/lib/libssh2.a \\
echo \${TMPDIR}iSSH2/libssh2-$LIBSSH_VERSION/iPhoneOS_$SDK_VERSION-arm64e/install/lib/libssh2.a -output ./libssh2_iphoneos/lib/libssh2.a
lipo -info ./libssh2_iphoneos/lib/libssh2.a
lipo -create ${TMPDIR}iSSH2/openssl-$LIBSSL_VERSION/${OSX_SDK_PLATFORM}_${OSX_MIN_VERSION}-x86_64/install/lib/libcrypto.a \
${TMPDIR}iSSH2/openssl-$LIBSSL_VERSION/iPhoneOS_$SDK_VERSION-arm64/libcrypto.a \
${TMPDIR}iSSH2/openssl-$LIBSSL_VERSION/iPhoneOS_$SDK_VERSION-arm64e/libcrypto.a -output ./openssl_iphoneos/lib/libcrypto.a
echo lipo -create \${TMPDIR}iSSH2/openssl-$LIBSSL_VERSION/${OSX_SDK_PLATFORM}_${OSX_MIN_VERSION}-x86_64/install/lib/libcrypto.a \\
echo \${TMPDIR}iSSH2/openssl-$LIBSSL_VERSION/iPhoneOS_$SDK_VERSION-arm64/libcrypto.a \\
echo \${TMPDIR}iSSH2/openssl-$LIBSSL_VERSION/iPhoneOS_$SDK_VERSION-arm64e/libcrypto.a -output ./openssl_iphoneos/lib/libcrypto.a
lipo -info ./openssl_iphoneos/lib/libcrypto.a
lipo -create ${TMPDIR}iSSH2/openssl-$LIBSSL_VERSION/${OSX_SDK_PLATFORM}_${OSX_MIN_VERSION}-x86_64/install/lib/libssl.a \
${TMPDIR}iSSH2/openssl-$LIBSSL_VERSION/iPhoneOS_$SDK_VERSION-arm64/libssl.a \
${TMPDIR}iSSH2/openssl-$LIBSSL_VERSION/iPhoneOS_$SDK_VERSION-arm64e/libssl.a -output ./openssl_iphoneos/lib/libssl.a
echo lipo -create \${TMPDIR}iSSH2/openssl-$LIBSSL_VERSION/${OSX_SDK_PLATFORM}_${OSX_MIN_VERSION}-x86_64/install/lib/libssl.a \\
echo \${TMPDIR}iSSH2/openssl-$LIBSSL_VERSION/iPhoneOS_$SDK_VERSION-arm64/libssl.a \\
echo \${TMPDIR}iSSH2/openssl-$LIBSSL_VERSION/iPhoneOS_$SDK_VERSION-arm64e/libssl.a -output ./openssl_iphoneos/lib/libssl.a
lipo -info ./openssl_iphoneos/lib/libssl.a
