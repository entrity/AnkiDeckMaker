#!/bin/bash

# Usage
# 	

if which nodejs; then
	NODE_EXEC=nodejs
elif which node; then
	NODE_EXEC=node
else
	>&2 echo Nodejs is not installed but is a dependency. Please install.
	return 4
fi
LANGUAGES=(en ja zh-TW zh-CN)
# zh-TW is Chinese (Traditional)

function check_args()
{
	if [[ $1 -ne $2 ]]; then
		>&2 echo "Bad arg ct. Need $2. Got $1"
		return 1
	fi
}

function verify_lang()
{
	printf '%s\n' "${LANGUAGES[@]}" | grep -q -P "^$1$"
	if (($?)); then
		>&2 echo "Bad language $1"
		return 1
	fi
}

function get_api_token()
{
	$NODE_EXEC -e "require('google-translate-token').get('${1//\'/\\\'}').then(function(obj){console.log(obj.value)})" || return 5
}

function urlencode()
{
	python3 -c "import urllib.parse;print(urllib.parse.quote('${1//\'/\\\'}'))"
}

# get_translation <srclang> <dstlang> <term>
function get_translation()
{
	check_args $# 3 || return 1
	srclang=$1
	verify_lang $srclang || return 1
	dstlang=$2
	verify_lang $dstlang || return 1
	term="$3"
	length=${#term}
	tk=${4-$(get_api_token "$term")} || return 5
	term=$(urlencode "$term")
	url="https://translate.google.com/translate_a/t?client=t&sl=${srclang}&tl=${dstlang}&hl=ja&v=1.0&source=is&tk=${tk}&q=${term}&ie=UTF-8"
	curl "$url" -H 'accept-language: en-US,en;q=0.9,en-GB;q=0.8,ja;q=0.7' -H 'user-agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.94 Safari/537.36' -H 'x-chrome-uma-enabled: 1' -H 'accept: */*' -H 'referer: https://translate.google.com/' -H 'authority: translate.google.com'
}

# get_mp3 <outfile> <lang> <term> [api-token]
function get_mp3()
{
	check_args $# 3 || return 1
	outfile="$1"
	if ! [[ $outfile =~ \.mp3$ ]] && ! [[ $outfile =~ ^[0-9]+$ ]]; then
		>&2 echo "outfile needs to have mp3 extension: $outfile"
		return 4
	fi
	lang=$2
	verify_lang "$lang" || return 4
	if [[ "$lang" == "zh-TW" ]]; then
		lang=zh-CN
	fi
	term="$3"
	tk=${4-$(get_api_token "$term")} || return 5
	textlen=${#term}
	term="$(urlencode "$term")"
	# E.g. https://translate.google.com/translate_tts?ie=UTF-8&q=%E5%90%83&tl=zh-CN&total=1&idx=0&textlen=1&tk=165961.321045&client=t&prev=input
	curl "https://translate.google.com/translate_tts?ie=UTF-8&q=${term}&tl=${lang}&total=1&idx=0&textlen=${textlen}&tk=${tk}&client=t" -H 'Accept-Encoding: identity;q=1, *;q=0' -H 'User-Agent: Mozilla/5.0 (X11; CrOS x86_64 9901.77.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.97 Safari/537.36' -H 'Range: bytes=0-' -H 'chrome-proxy: frfr' -o "$outfile"
}
