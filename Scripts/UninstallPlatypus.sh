#!/bin/sh
#
# UninstallPlatypus.sh
# Platypus
#
# Created by Sveinbjorn Thordarson 2012.
#

cd "$1"

if [ -e "%%APP_SUPPORT_FOLDER%%" ]
then
    echo "Deleting application support folder..."
    mv "%%APP_SUPPORT_FOLDER%%" "~/.Trash/%%PROGRAM_NAME%%ApplicationSupport-TRASHED-$RANDOM"
fi

if [ -e "~/Library/Preferences/%%PROGRAM_BUNDLE_IDENTIFIER%%.plist" ]
then
    echo "Deleting %%PROGRAM_NAME%% preferences..."
    mv "~/Library/Preferences/%%PROGRAM_BUNDLE_IDENTIFIER%%.plist" "~/.Trash/%%PROGRAM_BUNDLE_IDENTIFIER%%-TRASHED-$RANDOM.plist"
fi

if [ -e "$1/../../../%%PROGRAM_NAME%%.app" ]
then
    echo "Moving %%PROGRAM_NAME%%.app to Trash"
    mv "$1/../../../%%PROGRAM_NAME%%.app" "~/.Trash/%%PROGRAM_NAME%%-TRASHED-$RANDOM.app"
fi
