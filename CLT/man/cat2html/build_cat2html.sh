#!/bin/sh

lex cat2html.l
gcc -O2 -arch 'x86_64' -arch 'arm64' lex.cat2html.c -o cat2html
rm lex.cat2html.c
strip -x cat2html
chmod +x cat2html
