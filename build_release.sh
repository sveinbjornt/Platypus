#!/bin/bash
#
# Release build script for Platypus
# Must be run from src root
#
# Created by Sveinbjorn Thordarson 28/06/2015
#

SRC_DIR=$PWD
BUILD_DIR="/tmp/"
REMOTE_DIR="root@sveinbjorn.org:/www/sveinbjorn/html/files/software/platypus/"

VERSION=`perl -e 'open(FH,"< Common.h") or die($!);@lines=<FH>;close(FH);foreach(@lines){if($_=~m/PROGRAM_VERSION.+@.+(\d\.\d+)\"/){print $1;exit;}}'`
APP_NAME=`perl -e 'open(FH,"< Common.h") or die($!);@lines=<FH>;close(FH);foreach(@lines){if($_=~m/PROGRAM_NAME.+\"(.+)\"/){print $1;exit;}}'`
APP_NAME_LC=`echo "${APP_NAME}" | perl -ne 'print lc'` # lowercase name

APP_FOLDER_NAME="${APP_NAME}-${VERSION}"
APP_BUNDLE_NAME="${APP_NAME}.app"

APP_ZIP_NAME="${APP_NAME_LC}${VERSION}.zip"
APP_SRC_ZIP_NAME="${APP_NAME_LC}${VERSION}.src.zip"

#echo $VERSION
#echo $APP_NAME
#echo $APP_NAME_LC
#
#echo $APP_FOLDER_NAME
#echo $APP_BUNDLE_NAME
#
#echo $APP_ZIP_NAME
#echo $APP_SRC_ZIP_NAME

echo "Building ${APP_NAME} version ${VERSION}"

xcodebuild  -parallelizeTargets\
            -scheme "Platypus" \
            -configuration Deployment \
            CONFIGURATION_BUILD_DIR="${BUILD_DIR}" \
            clean \
build 
#1> /dev/null

# Check if build succeeded
if test $? -eq 0
then
    echo "Build successful"
else
    echo "Build failed"
    exit
fi

# Remove previous app folder
rm -r "${BUILD_DIR}/${APP_FOLDER_NAME}" &> /dev/null

# Create folder and copy app into it
echo "Creating app folder ${BUILD_DIR}/${APP_FOLDER_NAME}"
mkdir "${BUILD_DIR}/${APP_FOLDER_NAME}"
mv "${BUILD_DIR}/${APP_BUNDLE_NAME}" "${BUILD_DIR}${APP_FOLDER_NAME}/"

# Create symlink to Readme file
echo "Creating symlink to Readme file"
cd "${BUILD_DIR}/${APP_FOLDER_NAME}"
ln -s "${APP_BUNDLE_NAME}/Contents/Resources/Readme.html" "Readme.html"

# Create zip archive and move to desktop
echo "Creating application archive ${APP_ZIP_NAME}..."
cd "${BUILD_DIR}"
zip -q --symlinks "${APP_ZIP_NAME}" -r "${APP_FOLDER_NAME}"

if [ $1 ]
then
    echo "Uploading application archive ..."
    scp "${APP_ZIP_NAME}" "${REMOTE_DIR}"
fi

echo "Moving application archive to Desktop"
mv "${APP_ZIP_NAME}" ~/Desktop/

# Create source archive
echo "Creating source archive ${APP_SRC_ZIP_NAME}..."
cd "${SRC_DIR}"
zip -q --symlinks -r "${APP_SRC_ZIP_NAME}" "." -x *.git* -x *.zip* -x *.tgz* -x *.gz* -x *.DS_Store* -x *dsa_priv.pem* -x *Sparkle/dsa_priv.pem*

if [ $1 ]
then
    echo "Uploading source archive ..."
    scp "${APP_SRC_ZIP_NAME}" "${REMOTE_DIR}"
fi

if [ $1 ]
then
    echo "Updating documentation on server ..."
    sh "Documentation/update_docs.sh"
fi

echo "Moving source archive to Desktop"
mv "${APP_SRC_ZIP_NAME}" ~/Desktop/









