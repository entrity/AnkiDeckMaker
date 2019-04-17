#!/usr/bin/env python3

import get, pdb
import sys, json
import sqlite3

DBNAME = sys.argv[2] if len(sys.argv) > 2 else 'Chinese.sqlite3'
print('DBNAME ',DBNAME)
conn = sqlite3.connect(DBNAME)

def get_pinyin(cn_term, api_token=None):
        res = get.translate(cn_term, get.CN, get.EN, api_token, True)
        return json.loads('['+res+']')[0][1][-1]

def add(en, cn):
	pinyin = get_pinyin(cn)
	cursor = conn.cursor()
	cursor.execute('''insert into terms (en, cn, pinyin) VALUES ('%s','%s','%s')''' % (en, cn, pinyin))
	conn.commit()

sel = ''
while True:
	if 0==len(sel) or sel.isnumeric():
		en = input('en : ')
	if en == 'q': break
	response = get.translate(en, get.EN, get.CN, None, True)
	data = json.loads('['+response+']')
	cns = data[1][0][2] # Chinese terms that match the English query
	for i, cn in enumerate(cns):
		print('%2d %3s - %s' % (i, cn[0], ', '.join(cn[1])))
	sel = input('sel : ')
	if sel == 'q': break
	if sel == '': continue
	if not sel.isnumeric(): continue
	cn = cns[int(sel)][0]
	add(en, cn)

conn.close()
