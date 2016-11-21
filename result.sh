#!/bin/sh

cat ../local-runner-ru/result.txt | grep '^1 ' | awk '{print $2}'
