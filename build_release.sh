#!/bin/bash
#
# Release build script for Platypus
# Must be run from src root
#

XCODE_PROJ="Platypus.xcodeproj"

if [ ! -e "${XCODE_PROJ}" ]; then
    echo "Build script must be run from src root"
    exit 1
fi

SRC_DIR=$PWD
BUILD_DIR="/tmp/"
REMOTE_DIR="root@sveinbjorn.org:/www/sveinbjorn/html/files/software/platypus/"

VERSION=`perl -e 'open(FH,"< Common.h") or die($!);@lines=<FH>;close(FH);foreach(@lines){if($_=~m/PROGRAM_VERSION.+@.+(\d\.\d+)\"/){print $1;exit;}}'`
APP_NAME=`perl -e 'open(FH,"< Common.h") or die($!);@lines=<FH>;close(FH);foreach(@lines){if($_=~m/PROGRAM_NAME.+\"(.+)\"/){print $1;exit;}}'`

APP_NAME_LC=`echo "${APP_NAME}" | perl -ne 'print lc'` # lowercase name
APP_BUNDLE_NAME="${APP_NAME}.app"

APP_ZIP_NAME="${APP_NAME_LC}${VERSION}.zip"
APP_SRC_ZIP_NAME="${APP_NAME_LC}${VERSION}.src.zip"

# Remove any previous app bundle
rm -r "${BUILD_DIR}/${APP_BUNDLE_NAME}" &> /dev/null

echo "Building ${APP_NAME} version ${VERSION}"

xcodebuild  -parallelizeTargets \
            -project "${XCODE_PROJ}" \
            -target "${APP_NAME}" \
            -configuration "Deployment" \
            CONFIGURATION_BUILD_DIR="${BUILD_DIR}" \
            clean \
            build
#1> /dev/null

# Check if build succeeded
if test $? -eq 0 ; then
    echo "Build successful"
else
    echo "Build failed"
    exit 1
fi

# Create app zip archive and move to desktop
echo "Creating application archive ${APP_ZIP_NAME}..."
cd "${BUILD_DIR}"
zip -q --symlinks "${APP_ZIP_NAME}" -r "${APP_BUNDLE_NAME}"

FINAL_APP_ARCHIVE_PATH=~/Desktop/${APP_ZIP_NAME}

echo "Moving application archive to Desktop"
mv "${APP_ZIP_NAME}" ${FINAL_APP_ARCHIVE_PATH}

# Create source archive and move to desktop
echo "Creating source archive ${APP_SRC_ZIP_NAME}..."
cd "${SRC_DIR}"
zip -q --symlinks -r "${APP_SRC_ZIP_NAME}" "." -x *.git* -x *.zip* -x *.tgz* -x *.gz* -x *.DS_Store* -x *dsa_priv.pem* -x *Sparkle/dsa_priv.pem* -x \*build/\* -x \*Releases\* -x \*Assets\*

FINAL_SRC_ARCHIVE_PATH=~/Desktop/${APP_SRC_ZIP_NAME}

echo "Moving source archive to Desktop"
mv "${APP_SRC_ZIP_NAME}" ${FINAL_SRC_ARCHIVE_PATH}

# Sparkle
echo "Generating Sparkle signature"
ruby "Sparkle/sign_update.rb" ~/Desktop/${APP_ZIP_NAME} "Sparkle/dsa_priv.pem"

# Show archive sizes
echo "Archive Sizes:"
du -hs ${FINAL_APP_ARCHIVE_PATH}
du -hs ${FINAL_SRC_ARCHIVE_PATH}

