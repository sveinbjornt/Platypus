#!/bin/sh
#
# make_man_html.sh
# Use cat2html from Carl Lindberg's ManOpen to convert man page to HTML
#

/usr/bin/man ./platypus.1 | ./cat2html > platypus.man.html
