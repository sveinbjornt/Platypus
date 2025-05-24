#!/bin/sh
#
# InstallCommandLineTool.sh
# Platypus
#
# Created by Sveinbjorn Thordarson on 6/17/08.
# Variables defined in Common.h

REAL_USER_ID=`/usr/bin/id -r -u`

echo "Installing command line tool"

# Create directories if they don't exist
echo "Creating directory structures"
mkdir -p "%%CMDLINE_BIN_PATH%%"
mkdir -p "%%CMDLINE_SHARE_PATH%%"
mkdir -p "%%CMDLINE_MANDIR_PATH%%"

# Change to Resources directory of Platypus application, which is first argument
echo "Changing to directory '$1'"
cd "$1"

echo "Copying resources to share directory"
# ScriptExec binary
gunzip -c "%%CMDLINE_SCRIPTEXEC_GZIP_NAME%%" > "%%CMDLINE_SCRIPT_EXEC_PATH%%"
# Nib
cp -r "%%CMDLINE_NIB_NAME%%" "%%CMDLINE_SHARE_PATH%%"
# Set permissions
chown -R ${REAL_USER_ID} "%%CMDLINE_SHARE_PATH%%"
chmod -R 755 "%%CMDLINE_SHARE_PATH%%"

# Command line tool binary
echo "Installing command line tool"
cp "%%CMDLINE_PROGNAME_BUNDLE%%" "%%CMDLINE_TOOL_PATH%%"
chown ${REAL_USER_ID} "%%CMDLINE_TOOL_PATH%%"
chmod +x "%%CMDLINE_TOOL_PATH%%"

# Man page
echo "Installing man page"
rm "%%CMDLINE_MANPAGE_PATH%%" &> /dev/null
rm "%%CMDLINE_MANPAGE_PATH%%.gz" &> /dev/null
cp "%%CMDLINE_MANPAGE_NAME%%" "%%CMDLINE_MANPAGE_PATH%%"
chmod 644 "%%CMDLINE_MANPAGE_PATH%%"
chown ${REAL_USER_ID} "%%CMDLINE_MANPAGE_PATH%%"

exit 0
