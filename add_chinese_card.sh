#!/bin/bash

# To go back and forth between unicode character and codepoint:
#	printf "\xE5\x90\x83"
# 	printf "吃" | xxd
# 	(or formatted for URL query string:)
# 	printf "吃" | xxd -u -g 1 -i | sed -e 's/  //g' -e 's/\W0X/%/g' -e 's/^0X/%/' | tr -d '\n,'


DIR=Chinese
FILE="$DIR.apkg"
export DECK=Chinese-English-by-Markham
TSVFILE="$DIR.tsv"
MDIR=ChineseMedia

# Source the function files
. functions.sh
. google-translate-functions.sh

# Create the directory if it doesn't exist
# if ! [[ -d "$DIR" ]]; then
# 	if [[ -f "$FILE" ]]; then
# 		unzip "$FILE"
# 	else
		create_db "$DIR"
		create_deck "$DIR" "$DECK"
	# fi
# fi
function mp3src()
{
	echo -n "${MDIR}/${@}.mp3"
}

lineno=0
while IFS=$'\t' read -r chinall engall cmp3 emp3 || [[ -n "$chin" ]]; do
	if [[ -z "$chinall$engall$cmp3$emp3" ]]; then
		echo "Breaking at blank line${chinall}${engall}${cmp3}${emp3}..."
		break
	fi
	lineno=$(( $lineno + 1 ))
	[[ -n "$eng" ]] && [[ -n "$cmp3" ]] && [[ -n "$emp3" ]]; updateline=$?
	chin=$(sed -e 's/<br>.*//' <<< "$chinall")
	if [[ -z "$chin" ]]; then
		>&2 echo "No Chinese given in TSV entry: $chin ($chinall)"
		exit 1
	fi
	eng=$(sed -e 's/<br>.*//' -e 's/(.*)//g' <<< "$engall")
	if [[ -z "$eng" ]]; then
		eng=$(get_translation zh-TW en "$chin" | sed -e 's/^"//' -e 's/"$//')
		echo "got translation $eng"
	fi
	# Get Chinese MP3
	if [[ -z "$cmp3" ]]; then
		cmp3="$(mp3src $chin)"
	fi
	if ! [[ -s "$cmp3" ]]; then
		echo Downloading to $cmp3
		get_mp3 "$cmp3" zh-TW "$chin"
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
		echo Downloading to $emp3
		get_mp3 "$emp3" en "$eng"
		if (($?)); then
			>&2 echo "Error getting English mp3 for $eng"
			exit 1
		fi
	fi
	if (($updateline)); then
		tsv="${chinall}\t${engall}\t${cmp3}\t${emp3}"
		sed -i -e "${lineno}s/.*/${tsv//\//\\/}/" "$TSVFILE"
	fi
	# Update sqlite db
	cmp3base="$(basename "$cmp3")"
	emp3base="$(basename "$emp3")"
	add_card "$DIR" "$chinall[sound:$cmp3base]" "$engall[sound:$emp3base]"
	# Update media file
	ln -f "$cmp3" "$DIR/$(( $lineno * 2 - 1))"
	ln -f "$emp3" "$DIR/$(( $lineno * 2 ))"
	TJQ=$(jq ".[\"$(( $lineno * 2 - 1 ))\"]=\"$cmp3base\"" "$DIR/media")
	if (($?)); then >&2 echo FAIL JQ; exit 44; fi
	TJQ=$(jq ".[\"$(( $lineno * 2 ))\"]=\"$emp3base\"" <<< "$TJQ")
	if (($?)); then >&2 echo FAIL JQ; exit 45; fi
	echo "$TJQ" > "$DIR/media"
done < "$TSVFILE"

zip_db "$DIR"
