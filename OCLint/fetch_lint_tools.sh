#!/bin/sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR

# Remove pre-existing tool directories
rm -r oclint &> /dev/null
rm -r xctool &> /dev/null

echo "Fetching OCLint"
rm oclint-0.10.2-x86_64-darwin-15.2.0.tar.gz &> /dev/null
curl -LO https://github.com/oclint/oclint/releases/download/v0.10.2/oclint-0.10.2-x86_64-darwin-15.2.0.tar.gz
tar xfz oclint-0.10.2-x86_64-darwin-15.2.0.tar.gz
rm oclint-0.10.2-x86_64-darwin-15.2.0.tar.gz &> /dev/null
mv oclint-0.10.2 oclint

echo "Fetching xctool"
rm xctool-v0.2.8.zip &> /dev/null
curl -LO https://github.com/facebook/xctool/releases/download/0.2.8/xctool-v0.2.8.zip
mkdir xctool
unzip xctool-v0.2.8.zip -d ./xctool/
rm xctool-v0.2.8.zip &> /dev/null

