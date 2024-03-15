#!/bin/bash


cat $1 | grep 'd="M'| sed 's/.*\(M.*Z\).*/\1/'| sed 's/\.[^ ]\+//g'
