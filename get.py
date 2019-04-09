#!python3

EN = 'en'
CN = 'zh-CN'
USRLANG = EN
NODE_EXEC = 'node'

import urllib.parse, urllib.request, sys
import subprocess, codecs, json
from subprocess import PIPE


HEADERS = {
	'Accept-Encoding': 'identity;q=1, *;q=0',
	'User-Agent': 'Mozilla/5.0 (X11; CrOS x86_64 9901.77.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.97 Safari/537.36',
	'Range': 'bytes=0-',
	'chrome-proxy': 'frfr' ,
}


def get_token(term):
	args = [NODE_EXEC, "-e", "require('google-translate-token').get('%s').then(function(obj){console.log(obj.value)})" % (term)]
	cp = subprocess.run(args, stdout=PIPE, stderr=PIPE)
	token = cp.stdout.decode('utf-8').rstrip()
	return token

def _req(term, url_lambda, api_token=None):
	term = urllib.parse.quote(term)
	if api_token is None:
		api_token = get_token(term)
	url = url_lambda(term, api_token)
	req  = urllib.request.Request(url, headers=HEADERS)
	res  = urllib.request.urlopen(req)
	data = res.read()
	return data

def getmp3(term, lang, api_token=None):
	urlfmt = "https://translate.google.com/translate_tts?ie=UTF-8&q=${term}&tl=${lang}&total=1&idx=0&textlen=${textlen}&tk=${tk}&client=t"
	url_lambda = lambda term, api_token : urlfmt % (term, lang, len(term), api_token)
	data = _req(term, url_lambda, api_token)
	
def translate(term, srclang, dstlang, api_token=None, is_multi=False):
	if is_multi:
		urlfmt = \
		"https://translate.google.com/translate_a/single?client=webapp&sl=%s&tl=%s&hl=%s&dt=at&dt=bd&dt=ex&dt=ld&dt=md&dt=qca&dt=rw&dt=rm&dt=ss&dt=t&pc=1&otf=1&ssel=3&tsel=6&kc=1&tk=%s&q=%s"
	else:
		urlfmt = \
		"https://translate.google.com/translate_a/t?client=t&sl=%s&tl=%s&hl=%s&v=1.0&source=is&tk=%s&q=%s&ie=UTF-8"
	url_lambda = lambda term, api_token : urlfmt % (srclang, dstlang, USRLANG, api_token, term)
	data = _req(term, url_lambda, api_token)
	return data.decode('utf-8')

if __name__ == '__main__':
	sys.stdout = codecs.getwriter("utf-8")(sys.stdout.detach())
	import argparse
	parser = argparse.ArgumentParser(description='Process some integers.')
	parser.add_argument('-s','--srclang', default=EN)
	parser.add_argument('-d','--dstlang', default=CN)
	parser.add_argument('-t','--term', default='light')
	parser.add_argument('-k','--api_token')
	parser.add_argument('-m','--is_multi', action='store_true')
	args = parser.parse_args()
	token = get_token(args.term)
	res = translate(args.term, args.srclang, args.dstlang, token, args.is_multi)
	print(res)
