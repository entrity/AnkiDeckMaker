#!/usr/bin/env python3

import get
import csv
import sys

CSV = sys.argv[1]
COL = 1

with open(CSV) as csv:
	data = [ line.split('\t') for line in csv.read().split('\n') ]

with open('w-pinyin'+CSV, 'w') as fout:
	for i in range(len(data)):
		try:
			pinyin = get.get_pinyin(data[i][COL])
		except:
			import IPython; IPython.embed()
		data[i][COL] +='<br>%s' % pinyin
		fout.write('%s\n' % '\t'.join(data[i]))

