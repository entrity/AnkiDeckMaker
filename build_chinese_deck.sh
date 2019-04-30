#!/bin/bash

# To go back and forth between unicode character and codepoint:
#	printf "\xE5\x90\x83"
# 	printf "吃" | xxd
# 	(or formatted for URL query string:)
# 	printf "吃" | xxd -u -g 1 -i | sed -e 's/  //g' -e 's/\W0X/%/g' -e 's/^0X/%/' | tr -d '\n,'


DIR=Chinese
FILE="$DIR.apkg"
export DECK=Chinese-English-by-Markham
TSVFILE=${1:-"$DIR.tsv"}
MDIR=ChineseMedia

# Source the function files
. functions.sh
. google-translate-functions.sh


if [[ -f "$DIR.apkg" ]]; then # Unzip the current deck's db if it exists
	unzip "$DIR.apkg" $FNAME -d "$DIR"
elif ! [[ -d "$DIR/$FNAME" ]]; then # Create the directory if it doesn't exist
	create_db "$DIR"
	create_deck "$DIR" "$DECK"
fi

function mp3src()
{
	echo -n "${MDIR}/${@}.mp3"
}

lastid=0
lineno=0
while IFS=$'\b' read -r lesson chinall engall cmp3 emp3 noteid cardid || [[ -n "$chin" ]]; do
	lineno=$(( $lineno + 1 )) # Used with 'sed' to update the TSV for the current line only
	if [[ -z "$chinall$engall$cmp3$emp3" ]]; then # This is a skippable (blank) line
		echo "Breaking at blank line${chinall}${engall}${cmp3}${emp3}..."
		break
	elif [[ -n "$noteid" ]] && [[ -n "$cardid" ]]; then # This line already is in the database
		continue
	fi
	[[ -n "$eng" ]] && [[ -n "$cmp3" ]] && [[ -n "$emp3" ]]; updateline=$?
	chin=$(sed -e 's/<br>.*//' <<< "$chinall") # Section of the card's front that will be sent to Google Translate
	if [[ -z "$chin" ]]; then
		>&2 echo "No Chinese given in TSV entry: $chin ($chinall)"
		exit 1
	fi
	eng=$(sed -e 's/<br>.*//' -e 's/(.*)//g' <<< "$engall") # Section of the card's back that will be sent to Google Translate
	if [[ -z "$eng" ]]; then
		eng=$(get_translation zh-TW en "$chin" | sed -e 's/^"//' -e 's/"$//')
		echo "got translation $eng"
	fi
	# Get Chinese MP3
	if [[ -z "$cmp3" ]]; then
		cmp3="$(mp3src $chin)"
	fi
	if ! [[ $cmp3 =~ .mp3$ ]]; then
		cmp3=$cmp3.mp3
	fi
		echo chin $chin
		echo cmp3 $cmp3
	if ! [[ -s "$cmp3" ]]; then
		echo "Downloading Chinese to $cmp3 --->"
		echo "get_mp3 \"$cmp3\" zh-CN \"$chin\""
		get_mp3 "$cmp3" zh-CN "$chin"
		if (($?)); then
			>&2 echo "Error getting Chinese mp3 for $chin"
			exit 1
		fi
	fi
	# Get English MP3
	if [[ -z "$emp3" ]]; then
		emp3="$(mp3src $eng)"
	fi
	if ! [[ -s "$emp3" ]]; then
		echo "Downloading English to $emp3"
		echo get_mp3 "$emp3" en "$eng"
		get_mp3 "$emp3" en "$eng"
		if (($?)); then
			>&2 echo "Error getting English mp3 for $eng"
			exit 1
		fi
	fi
	# Update sqlite db
	cmp3base="$(basename "$cmp3")"
	emp3base="$(basename "$emp3")"
	IFS=$'\t' read -r noteid cardid < <(add_card "$DIR" "$chinall<br>[sound:$cmp3base]" "$engall<br>[sound:$emp3base]" "Lesson $lesson")
	if [[ -z $noteid ]]; then
		continue
	fi
	if [[ $lastid -ge $noteid ]]; then
		>&2 echo "ERR in db. lastid $lastid noteid $noteid"
		exit
	else
		echo note $noteid
		lastid=$noteid
	fi
	# Update TSV file
	tsv="${chinall:-$chin}\t${engall:-$eng}\t${cmp3}\t${emp3}\t${noteid}\t${cardid}"
	sed -i -e "${lineno}s/.*/${tsv//\//\\/}/" "$TSVFILE"
done < <(cat "$TSVFILE" | tr $'\t' $'\b') # This is a kludge because read will squeeze sequences of whitespaces (tabs) and treat them as one, which ruins my line if I have a blank value followed by a non-blank value

# Update media file, create media file of appropriate name in the source directory
count=0
while read -r f; do
	count=$(( $count + 1 ))
	# Create numerically-named hard link
	ln -f "$f" "$DIR/$count"
	# Compute new content for 'media' file
	TJQ=$(jq ".[\"$count\"]=\"$(basename "$f")\"" "$DIR/media")
	if (($?)); then >&2 echo FAIL JQ; exit 44; fi
	# Overwrite 'media' file with new content, containing the latest link
	echo "$TJQ" > "$DIR/media"
done < <(find "$MDIR" -type f)

zip_db "$DIR"
