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
BUILD_DIR="products/"

VERSION=`/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Application/Resources/Platypus-Info.plist`
APP_NAME=`/usr/libexec/PlistBuddy -c "Print :CFBundleName" Application/Resources/Platypus-Info.plist`

APP_NAME_LC=`echo "${APP_NAME}" | perl -ne 'print lc'` # lowercase name
APP_BUNDLE_NAME="${APP_NAME}.app"

APP_ZIP_NAME="${APP_NAME_LC}${VERSION}.zip"
APP_SRC_ZIP_NAME="${APP_NAME_LC}${VERSION}.src.zip"


# Remove any previous build products
echo "Removing previously built products"
rm -r "${BUILD_DIR}/" 2>&1 /dev/null
mkdir -p "${BUILD_DIR}" 2>&1 /dev/null


# Perform build using Xcode
echo "Building ${APP_NAME} version ${VERSION}"
xcodebuild  -parallelizeTargets \
            -project "${XCODE_PROJ}" \
            -target "${APP_NAME}" \
            -configuration "Deployment" \
            CONFIGURATION_BUILD_DIR="${BUILD_DIR}" \
            clean \
            build
#2>&1 /dev/null

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

FINAL_APP_ARCHIVE_PATH=${BUILD_DIR}/${APP_ZIP_NAME}

# Create source archive and move to desktop
echo "Creating source archive ${APP_SRC_ZIP_NAME}..."
cd "${SRC_DIR}"
zip -q --symlinks -r "${APP_SRC_ZIP_NAME}" "." -x "*.git*" -x "*.zip*" -x "*.tgz*" -x \
"*.gz*" -x "*.DS_Store*" -x "*dsa_priv.pem*" -x "*Assets*" -x "ExampleApps*" \
-x "Icons/old*" -x "*Sparkle/dsa_priv.pem*" -x "*build*" -x "*${BUILD_DIR}*"

FINAL_SRC_ARCHIVE_PATH=${BUILD_DIR}/${APP_SRC_ZIP_NAME}
mv "${APP_SRC_ZIP_NAME}" "${BUILD_DIR}"/

# Sparkle
echo "Generating Sparkle signature"
ruby "Sparkle/sign_update.rb" ~/Desktop/${APP_ZIP_NAME} "Sparkle/dsa_priv.pem"

# Show archive sizes
echo "App bundle size:"
du -hs "${BUILD_DIR}/${APP_BUNDLE_NAME}"
echo "Binary size:"
BIN_SIZE=`stat -f %z "${BUILD_DIR}/${APP_BUNDLE_NAME}"/Contents/MacOS/*`
echo "${BIN_SIZE} bytes"
echo "Archive Sizes:"
du -hs ${FINAL_APP_ARCHIVE_PATH}
du -hs ${FINAL_SRC_ARCHIVE_PATH}

