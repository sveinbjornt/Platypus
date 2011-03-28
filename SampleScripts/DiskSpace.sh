#!/bin/sh
#
# A simple script which prints out the disk space available on all of the 
# system's volumes.
#
# Open this script with Platypus, select Output Type: Text Window and check
# the checkbox "Remain running after completion", then press Create.
# You should then have a little tool which prints out the status of your volumes.
#

df -h
