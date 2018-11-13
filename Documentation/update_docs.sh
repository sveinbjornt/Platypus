#!/bin/sh
# Copies Platypus documentation files to public web server

# Convert Markdown to HTML
gfm2html Documentation.md Documentation.html

scp Documentation.html root@sveinbjorn.org:/www/sveinbjorn/html/files/manpages/Documentation.html
scp License.html root@sveinbjorn.org:/www/sveinbjorn/html/files/manpages/License.html
scp -r images root@sveinbjorn.org:/www/sveinbjorn/html/files/manpages/
