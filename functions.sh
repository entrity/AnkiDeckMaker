#!/bin/bash

FNAME="collection.anki2"

function create_db()
{
	DBDIR="${1:-.}"
	mkdir -p "$DBDIR"
	echo DBDIR $DBDIR
	FILE="$DBDIR/$FNAME"
	sqlite3 "$FILE" < schema.sqlite
}

function create_deck()
{
	DBDIR="${1:-.}"
	DECK_NAME="$2"
	FILE="$DBDIR/$FNAME"
	## sqlite3 "$FILE" 'delete from col'
	conf="$(jq . -c conf.json)"
	models="$(jq . -c models.json)"
	decks="$(cat decks.json | jq ".[\"1\"].name=\"$DECK_NAME\"" | jq '{"1":.["1"]}' -c)"
	dconf="$(cat dconf.json | jq ".[\"1\"].name=\"$DECK_NAME\"" | jq '{"1":.["1"]}' -c)"
	# id, crt, mod, scm,
	# ver, dty, usn, ls,
	# conf, models, decks, dconf, tags
	sqlite3 "$FILE" "insert into col \
		(crt, mod, scm, ver, dty, usn, ls, conf, models, decks, dconf, tags) \
		values ( \
		1332961200,1398130163295,1398130163168,\
		11, 0, 0, 0, \
		'$conf','$models','$decks','$dconf','{}')"
	echo '{}' > "$DBDIR/media"
}

# 1. DBDIR
# 2. front
# 3. back
# 4. [tags]
function add_card()
{
	DBDIR="$1"
	FILE="$DBDIR/$FNAME"
	front="$2"
	back="$3"
	tags="$4"
	echo front $front
	echo back $back
	timestamp=$(date +%s)
	# === INSERT NOTE ===
	# id: 1398130088495 - The note id, generate it randomly.
	# guid: 'Ot0!xywPWG' - a GUID identifier, generate it randomly.
	# mid: 1342697561419 - Identifier of the model, use the one found in the models JSON section.
	# mod: 1398130110 - Replace with current time (seconds since 1970).
	# usn: -1 - We can leave it untouched.
	# tags: - Tags, visible to the user, which can be used to filter cards (e.g. "verb"). We can leave it untouched (empty string).
	# flds: 'Bonjour�Hello' - Card content, front and back, separated by \x1f char.
	# sfld: 'Bonjour' - Card front content without html (first part of flds, filtered).
	# csum: 4077833205 - A string SHA1 checksum of sfld, limited to 8 digits. PHP: (int)(hexdec(getFirstNchars(sha1($sfld), 8)));
	# flags: 0 - We can leave it untouched.
	# data: - We can leave it untouched.
    mid=$(sqlite3 "$FILE" 'select models from col' | jq '.[].id')
    mod=$timestamp
    usn=-1
    tags="$tags"
    flds="${front}$(printf '\x1f')${back}"
    sfld=$(echo "$front" | perl -pe 's|<.*?>||g')
    hex_csum=$(printf "$sfld" | sha1sum | head -c 8)
    csum=$(printf %d 0x$hex_csum)
    flags=0
    data=
    guid="$(echo -n "$flds" | md5sum)"
	noteid=$(sqlite3 "$FILE" "insert into notes (guid,mid,mod,usn,tags,flds,sfld,csum,flags,data) \
		values('$guid',$mid,$mod,$usn,'$tags','$flds','$sfld',$csum,$flags,'$data'); select last_insert_rowid();")
	# If we didn't get an id, assume that the card already exists
	if [[ -z $noteid ]]; then
		>&2 echo "NOTE ALREADY EXISTS $flds"
		return
	fi
	# === INSERT CARD ===
	# id: 1398130110964 - The card id, generate it randomly.
	# nid: 1398130088495 - The note id this card is associated with.
	# did: 1398130078204 - The deck id this card is associated with.
	# ord: 0 - We can leave it untouched.
	# mod: 1398130110 - Same as note's mod field
	# usn: -1 - We can leave it untouched.
	# type: 0 - We can leave it untouched.
	# queue: 0 - We can leave it untouched.
	# due: 484332854 - We can leave it untouched.
	# ivl: 0 - We can leave it untouched.
	# factor: 0 - We can leave it untouched.
	# reps: 0 - We can leave it untouched.
	# lapses: 0 - We can leave it untouched.
	# left: 0 - We can leave it untouched.
	# odue: 0 - We can leave it untouched.
	# odid: 0 - We can leave it untouched.
	# flags: 0 - We can leave it untouched.
	# data: - We can leave it untouched.
	nid=$noteid
	did=$(sqlite3 "$FILE" "select id from col;" | head)
	ord=0
	type=0
	queue=0
	due=$noteid
	ivl=0
	factor=0
	reps=0
	lapses=0
	left=0
	odue=0
	odid=0
	sqlite3 "$FILE" "insert into cards \
		(nid, did, ord, mod, usn, type, queue, due, ivl, factor, reps, lapses, left, odue, odid, flags, data) \
		values \
		($nid, $did, $ord, $mod, $usn, $type, $queue, $due, $ivl, $factor, $reps, $lapses, $left, $odue, $odid, $flags, '$data');"
}

function zip_db()
{
	local cwd=$(pwd)
	DBDIR="${1:-.}"
	cd "$DBDIR"
	zip -r "$cwd/$DBDIR.apkg" *
	cd "$cwd"
}
