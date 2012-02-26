#!/bin/sh

cd "$1"

sh UninstallCommandLineTool.sh

if [ -e ~/Library/Application\ Support/Platypus ]
then
    echo "Deleting application support folder..." > /dev/stderr
    mv ~/Library/Application\ Support/Platypus ~/.Trash/PlatypusApplicationSupport-TRASHED
fi

if [ -e ~/Library/Preferences/org.sveinbjorn.platypus.plist ]
then
    echo "Deleting Platypus preferences..." > /dev/stderr
    mv ~/Library/Preferences/org.sveinbjorn.platypus.plist ~/.Trash/org.sveinbjorn.platypus-TRASHED.plist
fi

if [ -e $1/../../../Platypus.app ]
then
    echo "Moving Platypus.app to Trash" > /dev/stderr
    mv $1/../../../Platypus.app ~/.Trash/Platypus-TRASHED.app
fi
