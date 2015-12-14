#!/bin/sh

lex cat2html.l
gcc -O3 lex.cat2html.c -o cat2html
rm lex.cat2html.c
strip -x cat2html
chmod 755 cat2html
