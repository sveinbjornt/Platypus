#!/bin/sh
#
# UninstallCommandLineTool.sh
# Platypus
#
# Created by Sveinbjorn Thordarson on 6/17/08.
# Variables defined in Common.h

echo "Uninstalling command line tool"

if [ -e "%%CMDLINE_SHARE_PATH%%" ]; then
    echo "Deleting '%%CMDLINE_SHARE_PATH%%' directory"
    rm -R "%%CMDLINE_SHARE_PATH%%" &> /dev/null
fi

if [ -e "%%CMDLINE_TOOL_PATH%%" ]; then
    echo "Deleting %%CMDLINE_PROGNAME%% command line tool in %%CMDLINE_TOOL_PATH%%"
    rm "%%CMDLINE_TOOL_PATH%%" &> /dev/null
fi

if [ -e "%%CMDLINE_MANPAGE_PATH%%" ]; then
    echo "Deleting %%CMDLINE_PROGNAME%% man page"
    rm "%%CMDLINE_MANPAGE_PATH%%" &> /dev/null
fi

if [ -e "%%CMDLINE_MANPAGE_PATH%%.gz" ]; then
    echo "Deleting gzipped %%CMDLINE_PROGNAME%% man page"
    rm "%%CMDLINE_MANPAGE_PATH%%.gz" &> /dev/null
fi

