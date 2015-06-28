#!/bin/bash
#
# Release build script for Platypus
# Must be run from src root
#
# Created by Sveinbjorn Thordarson 28/06/2015
#

SRC_DIR=$PWD
BUILD_DIR="/tmp/"

VERSION=`perl -e 'use Shell;@lines=cat("Common.h");foreach(@lines){if($_=~m/PROGRAM_VERSION.+(\d\.\d.+)\"/){print $1;}}'`
APP_NAME=`perl -e 'use Shell;@lines=cat("Common.h");foreach(@lines){if($_=~m/PROGRAM_NAME.+\"(.+)\"/){print $1;}}'`
APP_NAME_LC=`echo -n "${APP_NAME}" | perl -ne 'print lc'` # lowercase name

APP_FOLDER_NAME="${APP_NAME}-${VERSION}"
APP_BUNDLE_NAME="${APP_NAME}.app"

APP_ZIP_NAME="${APP_NAME_LC}${VERSION}.zip"
APP_SRC_ZIP_NAME="${APP_NAME_LC}${VERSION}.src.zip"

echo "Building ${APP_NAME_LC} version ${VERSION}"

xcodebuild  -parallelizeTargets\
            -scheme "Platypus App" \
            -configuration Deployment \
            CONFIGURATION_BUILD_DIR="${BUILD_DIR}" \
            clean \
            build

# Remove previous app folder
rm -r "${BUILD_DIR}/${APP_FOLDER_NAME}" &> /dev/null

# Create folder and copy app into it
mkdir "${BUILD_DIR}/${APP_FOLDER_NAME}"
mv "${BUILD_DIR}/${APP_BUNDLE_NAME}" "${BUILD_DIR}${APP_FOLDER_NAME}/"

# Create symlink to Readme file
cd "${BUILD_DIR}/${APP_FOLDER_NAME}"
ln -s "${APP_BUNDLE_NAME}/Contents/Resources/Readme.html" "Readme.html"

# Create zip archive and move to desktop
echo "Creating application archive..."
cd "${BUILD_DIR}"
zip --symlinks "${APP_ZIP_NAME}" -r "${APP_FOLDER_NAME}"
mv "${APP_ZIP_NAME}" ~/Desktop/

# Create source archive
echo "Creating source archive..."
cd "${SRC_DIR}"
zip --symlinks -r "${APP_SRC_ZIP_NAME}" "." -x *.git* -x *.zip* -x *.tgz* -x *.gz* -x *.DS_Store* -x *dsa_priv.pem* -x *Sparkle/dsa_priv.pem*
mv "${APP_SRC_ZIP_NAME}" ~/Desktop/