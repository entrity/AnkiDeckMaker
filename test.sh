#!/bin/bash

. functions.sh

rm Test.apkg
rm -rf Test

export DBDIR=Test
DECK=MydEck
if ! [[ -e "$DBDIR/$FNAME" ]]; then
	create_db "$DBDIR"
	create_deck "$DBDIR" "$DECK"
fi

add_card "$DBDIR" 'Peruvian food' 'alpacas'
add_card "$DBDIR" 'Chinese food' 'dim sum'
add_card "$DBDIR" 'Korean food' 'bulgogi'

zip_db "$DBDIR"