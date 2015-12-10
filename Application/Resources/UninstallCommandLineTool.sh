#!/bin/sh
#
# UninstallCommandLineTool.sh
# Platypus
#
# Created by Sveinbjorn Thordarson on 6/17/08.
#
# Variables herein defined in Common.h
#

echo "Uninstalling command line tool"

# Delete resources
if [ -e "%%CMDLINE_SHARE_PATH%%" ]
then
    echo "Deleting '%%CMDLINE_SHARE_PATH%%' directory"
    rm -R "%%CMDLINE_SHARE_PATH%%"
fi

if [ -e "%%CMDLINE_TOOL_PATH%%" ]
then
    echo "Deleting %%CMDLINE_PROGNAME%% command line tool in %%CMDLINE_TOOL_PATH%%"
    rm "%%CMDLINE_TOOL_PATH%%"
fi

if [ -e "%%CMDLINE_MANPAGE_PATH%%" ]
then
    echo "Deleting %%CMDLINE_PROGNAME%% man page"
    rm "%%CMDLINE_MANPAGE_PATH%%"
fi

