#!/bin/sh
#
# Print total lines of code for project
#
echo "Lines of code in Platypus codebase"

echo "LOC Total:"
find . -name \*.\[m\|h\] -exec cat {} \; | wc -l

echo "LOC Total implementation files"
find . -name \*.\[m\] -exec cat {} \; | wc -l

echo "LOC Total header files"
find . -name \*.\[h\] -exec cat {} \; | wc -l

echo "LOC Platypus App"
APP_TOTAL=`find Application -name \*.\[m\|h\] -exec cat {} \; | wc -l`
APP_HEAD=`find Application -name \*.\[h\] -exec cat {} \; | wc -l`
APP_IMPL=`find Application -name \*.\[m\] -exec cat {} \; | wc -l`
echo "${APP_TOTAL} (${APP_HEAD}/${APP_IMPL})"

echo "LOC ScriptExec"
SCRIPTEXEC_TOTAL=`find ScriptExec -name \*.\[m\|h\] -exec cat {} \; | wc -l`
SCRIPTEXEC_HEAD=`find ScriptExec -name \*.\[h\] -exec cat {} \; | wc -l`
SCRIPTEXEC_IMPL=`find ScriptExec -name \*.\[m\] -exec cat {} \; | wc -l`
echo "${SCRIPTEXEC_TOTAL} (${SCRIPTEXEC_HEAD}/${SCRIPTEXEC_IMPL})"

echo "LOC Command Line Tool"
CMDLINETOOL_TOTAL=`find CommandLineTool -name \*.\[m\|h\] -exec cat {} \; | wc -l`
CMDLINETOOL_HEAD=`find CommandLineTool -name \*.\[h\] -exec cat {} \; | wc -l`
CMDLINETOOL_IMPL=`find CommandLineTool -name \*.\[m\] -exec cat {} \; | wc -l`
echo "${CMDLINETOOL_TOTAL} (${CMDLINETOOL_HEAD}/${CMDLINETOOL_IMPL})"

echo "LOC Shared"
SHARED_TOTAL=`find Shared -name \*.\[m\|h\] -exec cat {} \; | wc -l`
SHARED_HEAD=`find Shared -name \*.\[h\] -exec cat {} \; | wc -l`
SHARED_IMPL=`find Shared -name \*.\[m\] -exec cat {} \; | wc -l`
echo "${SHARED_TOTAL} (${SHARED_HEAD}/${SHARED_IMPL})"

echo "LOC Shared (Others)"
find Shared/Others -name \*.\[m\|h\] -exec cat {} \; | wc -l
