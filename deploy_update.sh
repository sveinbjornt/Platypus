#!/bin/sh

xcodebuild -project Platypus.xcodeproj \
           -target "Platypus" \
           -configuration Deployment \
           -sdk macosx10.9 \
           CODE_SIGN_IDENTITY='' \
           ARCHS="i386 x86_64" \
           ONLY_ACTIVE_ARCH=NO \
           clean build