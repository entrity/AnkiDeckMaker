DBNAME=${1:-Chinese.sqlite3}
sqlite3 "$DBNAME" <<< "create table terms (en text, cn text, pinyin text, mp3en text, mp3cn text);"

