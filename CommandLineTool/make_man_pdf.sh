#!/bin/sh

groff -mandoc platypus.1 | pstopdf -i -o platypus.man.pdf
