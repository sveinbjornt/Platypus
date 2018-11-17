#!/bin/bash
#
# Print total lines of code for project
#
REMOTE_NAME=`git config --get remote.origin.url`
REPO=`basename -s .git ${REMOTE_NAME}`
echo "Lines of code in ${REPO} codebase"

echo "LOC Total:"
find . -name \*.\[m\|h\] -exec cat {} \; | wc -l

echo "LOC Total implementation files"
find . -name \*.\[m\] -exec cat {} \; | wc -l

echo "LOC Total header files"
find . -name \*.\[h\] -exec cat {} \; | wc -l

echo "LOC App"
APP_TOTAL=`find Application -name \*.\[m\|h\] -exec cat {} \; | wc -l`
APP_HEAD=`find Application -name \*.\[h\] -exec cat {} \; | wc -l | sed -e 's/^[ \t]*//'`
APP_IMPL=`find Application -name \*.\[m\] -exec cat {} \; | wc -l | sed -e 's/^[ \t]*//'`
echo "${APP_TOTAL} (${APP_HEAD}/${APP_IMPL})"

echo "LOC ScriptExec"
SCRIPTEXEC_TOTAL=`find ScriptExec -name \*.\[m\|h\] -exec cat {} \; | wc -l`
SCRIPTEXEC_HEAD=`find ScriptExec -name \*.\[h\] -exec cat {} \; | wc -l | sed -e 's/^[ \t]*//'`
SCRIPTEXEC_IMPL=`find ScriptExec -name \*.\[m\] -exec cat {} \; | wc -l | sed -e 's/^[ \t]*//'`
echo "${SCRIPTEXEC_TOTAL} (${SCRIPTEXEC_HEAD}/${SCRIPTEXEC_IMPL})"

echo "LOC CLT"
CMDLINETOOL_TOTAL=`find CLT -name \*.\[m\|h\] -exec cat {} \; | wc -l`
CMDLINETOOL_HEAD=`find CLT -name \*.\[h\] -exec cat {} \; | wc -l | sed -e 's/^[ \t]*//'`
CMDLINETOOL_IMPL=`find CLT -name \*.\[m\] -exec cat {} \; | wc -l | sed -e 's/^[ \t]*//'`
echo "${CMDLINETOOL_TOTAL} (${CMDLINETOOL_HEAD}/${CMDLINETOOL_IMPL})"

echo "LOC Shared"
SHARED_TOTAL=`find Shared -name \*.\[m\|h\] -exec cat {} \; | wc -l`
SHARED_HEAD=`find Shared -name \*.\[h\] -exec cat {} \; | wc -l | sed -e 's/^[ \t]*//'`
SHARED_IMPL=`find Shared -name \*.\[m\] -exec cat {} \; | wc -l | sed -e 's/^[ \t]*//'`
echo "${SHARED_TOTAL} (${SHARED_HEAD}/${SHARED_IMPL})"

echo "LOC Shared ($REPO)"
SHARED_US_TOTAL=`find Shared -not -path "Shared/Others*" -name \*.\[m\|h\] -exec cat {} \; | wc -l`
SHARED_US_HEAD=`find Shared -not -path "Shared/Others*" -name \*.\[h\] -exec cat {} \; | wc -l | sed -e 's/^[ \t]*//'`
SHARED_US_IMPL=`find Shared -not -path "Shared/Others*" -name \*.\[m\] -exec cat {} \; | wc -l | sed -e 's/^[ \t]*//'`
echo "${SHARED_US_TOTAL} (${SHARED_US_HEAD}/${SHARED_US_IMPL})"

echo "LOC Shared (Others)"
SHAREDOTHERS_TOTAL=`find Shared/Others -name \*.\[m\|h\] -exec cat {} \; | wc -l`
SHAREDOTHERS_HEAD=`find Shared/Others -name \*.\[h\] -exec cat {} \; | wc -l | sed -e 's/^[ \t]*//'`
SHAREDOTHERS_IMPL=`find Shared/Others -name \*.\[m\] -exec cat {} \; | wc -l | sed -e 's/^[ \t]*//'`
echo "${SHAREDOTHERS_TOTAL} (${SHAREDOTHERS_HEAD}/${SHAREDOTHERS_IMPL})"
