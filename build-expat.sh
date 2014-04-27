#!/bin/sh

#  Automatic build script for expat 
#  for iPhoneOS and iPhoneSimulator
#
#  Created by Felix Schulze on 19.02.12.
#  Copyright 2012 Felix Schulze. All rights reserved.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
###########################################################################
#  Change values here													  #
#																		  #
VERSION="2.1.0"                                                           #
SDKVERSION="7.1"                                                          #
MIN_VERSION="7.0"                                                         #
#																		  #
###########################################################################
#																		  #
# Don't change anything under this line!								  #
#																		  #
###########################################################################


CURRENTPATH=`pwd`
ARCHS="i386 x86_64 armv7 armv7s arm64"
DEVELOPER=`xcode-select -print-path`

set -e
if [ ! -e expat-${VERSION}.tar.gz ]; then
	echo "Downloading expat-${VERSION}.tar.gz"
    curl -O http://ncu.dl.sourceforge.net/project/expat/expat/${VERSION}/expat-${VERSION}.tar.gz
else
	echo "Using expat-${VERSION}.tar.gz"
fi

mkdir -p "${CURRENTPATH}/src"
mkdir -p "${CURRENTPATH}/bin"
mkdir -p "${CURRENTPATH}/lib"

for ARCH in ${ARCHS}
do
	tar zxf expat-${VERSION}.tar.gz -C "${CURRENTPATH}/src"
	cd "${CURRENTPATH}/src/expat-${VERSION}"

	if [[ "${ARCH}" == "i386" || "${ARCH}" == "x86_64" ]];
	then
		PLATFORM="iPhoneSimulator"
	else
		PLATFORM="iPhoneOS"
	fi
	
	echo "Building expat-${VERSION} for ${PLATFORM} ${SDKVERSION} ${ARCH}"
	echo "Please stand by..."
	
	export DEVROOT="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	export SDKROOT="${DEVROOT}/SDKs/${PLATFORM}${SDKVERSION}.sdk"

    export LD=${DEVROOT}/usr/bin/ld
	export CC=${DEVELOPER}/usr/bin/gcc
    export CXX=${DEVELOPER}/usr/bin/g++

	unset AR
	unset AS

    if [[ "${ARCH}" == "i386" || "${ARCH}" == "x86_64" ]];
    then
        export NM=${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/nm
        export RANLIB=${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/ranlib
    else
        export NM=${DEVROOT}/usr/bin/nm
        export RANLIB=${DEVROOT}/usr/bin/ranlib
    fi

    export LDFLAGS="-arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${SDKROOT} -L${CURRENTPATH}/lib -miphoneos-version-min=${MIN_VERSION}"
	export CFLAGS="-arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${SDKROOT} -I${CURRENTPATH}/include -miphoneos-version-min=${MIN_VERSION}"
	export CXXFLAGS="-arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${SDKROOT} -I${CURRENTPATH}/include -miphoneos-version-min=${MIN_VERSION}"

	mkdir -p "${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk"
	LOG="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/build-expat-${VERSION}.log"

    echo "Configure..."
	./configure --prefix="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk" --host="${ARCH}-apple-darwin" --enable-static > "${LOG}" 2>&1
    echo "Make..."
    make >> "${LOG}" 2>&1
    echo "Make install..."
    make install >> "${LOG}" 2>&1
	cd "${CURRENTPATH}"
	rm -rf "${CURRENTPATH}/src/expat-${VERSION}"
done

echo "Build library..."
lipo -create ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-i386.sdk/lib/libexpat.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv6.sdk/lib/libexpat.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7.sdk/lib/libexpat.a -output ${CURRENTPATH}/lib/libexpat.a
mkdir -p ${CURRENTPATH}/include/expat
cp  ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-i386.sdk/include/expat* ${CURRENTPATH}/include/expat
echo "Building done."
echo "Done."