#!/bin/bash

CWD=$(dirname "$(realpath "$0")")
. "$CWD/functions.sh"

while getopts d:o: opt; do
	case $opt in
		d)	DIR="$OPTARG";;
		c)	DIR="$OPTARG";;
		*)	>&2 echo "Illegal option $opt"
			exit 8
	esac
done
