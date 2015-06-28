#!/bin/sh
#
# Print total lines of code data for Platypus project
#

echo "LOC Total:"
find . -name \*.\[m\|h\] -exec cat {} \; | wc -l
echo "LOC Total implementation files"
find . -name \*.\[m\] -exec cat {} \; | wc -l
echo "LOC Total header files"
find . -name \*.\[h\] -exec cat {} \; | wc -l
echo "LOC Platypus App"
find Application -name \*.\[m\|h\] -exec cat {} \; | wc -l
echo "LOC ScriptExec"
find ScriptExec -name \*.\[m\|h\] -exec cat {} \; | wc -l
echo "LOC Command Line Tool"
find CommandLineTool -name \*.\[m\|h\] -exec cat {} \; | wc -l
echo "LOC Shared"
find Shared -name \*.\[m\|h\] -exec cat {} \; | wc -l
