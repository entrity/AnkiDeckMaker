#!/usr/bin/python3

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
	if api_token is None:
		api_token = get_token(term)
	term = urllib.parse.quote(term)
	url = url_lambda(term, api_token)
	print(url)
	req  = urllib.request.Request(url, headers=HEADERS)
	res  = urllib.request.urlopen(req)
	data = res.read()
	return data

def getmp3(term, lang, api_token=None):
	urlfmt = "https://translate.google.com/translate_tts?ie=UTF-8&q=%s&tl=%s&total=1&idx=0&textlen=%d&tk=%s&client=t"
	url_lambda = lambda term, api_token : urlfmt % (term, lang, len(term), api_token)
	data = _req(term, url_lambda, api_token)
	with open('%s.mp3' % term, 'wb') as fout:
		fout.write(data)
	print("Wrote to '%s.mp3'" % term)
	
def translate(term, srclang, dstlang, api_token=None, is_multi=False):
	if is_multi:
		urlfmt = \
		"https://translate.google.com/translate_a/single?client=webapp&sl=%s&tl=%s&hl=%s&dt=at&dt=bd&dt=ex&dt=ld&dt=md&dt=qca&dt=rw&dt=rm&dt=ss&dt=t&pc=1&otf=1&ssel=3&tsel=6&kc=1&tk=%s&q=%s"
	else:
		urlfmt = \
		"https://translate.google.com/translate_a/t?client=t&sl=%s&tl=%s&hl=%s&v=1.0&source=is&tk=%s&q=%s&ie=UTF-8"
	url_lambda = lambda term, api_token : urlfmt % (srclang, dstlang, USRLANG, api_token, term)
	data = _req(term, url_lambda, api_token)
	return data.decode('utf-8')[1:-1]

def get_pinyin(cn_term, api_token=None):
	res = translate(cn_term, CN, EN, api_token, True)
	return json.loads('['+res+']')[0][1][-1]

if __name__ == '__main__':
	sys.stdout = codecs.getwriter("utf-8")(sys.stdout.detach())
	import argparse
	parser = argparse.ArgumentParser(description='Process some integers.')
	parser.add_argument('-s','--srclang', default=EN)
	parser.add_argument('-d','--dstlang', default=CN)
	parser.add_argument('-t','--term', default='light')
	parser.add_argument('-k','--api_token')
	parser.add_argument('-m','--is_multi', action='store_true')
	parser.add_argument('--tok', action='store_true')
	parser.add_argument('--mp3', action='store_true')
	parser.add_argument('--cnmp3', action='store_true')
	parser.add_argument('-b','--double', action='store_true')
	parser.add_argument('-p','--pinyin', action='store_true')
	args = parser.parse_args()
	token = None
	if args.mp3:
		getmp3(args.term, args.srclang)
	elif args.tok:
		print(get_token(args.term))
	elif args.pinyin:
		cn_term = translate(args.term, EN, CN, None, False)
		res = get_pinyin(cn_term, None)
		print(res)
	elif args.double:
		res = translate(args.term, args.srclang, args.dstlang, None, False)
		print(res)
		re2 = translate(res,       args.dstlang, args.srclang, None, True)
		print(re2)
	elif args.cnmp3:
		cn = translate(args.term, args.srclang, args.dstlang, token, False)
		print(cn)
		getmp3(cn, args.dstlang)
	else:
		res = translate(args.term, args.srclang, args.dstlang, token, args.is_multi)
		print(res)

