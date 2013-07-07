#!/bin/sh
# Copies Platypus documentation files to public web server

scp PlatypusDocumentation.html root@sveinbjorn.org:/www/sveinbjorn/html/files/manpages/PlatypusDocumentation.html
scp Readme.html root@sveinbjorn.org:/www/sveinbjorn/html/files/manpages/Readme.html
scp -r images root@sveinbjorn.org:/www/sveinbjorn/html/files/manpages/
