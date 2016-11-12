#!/usr/bin/env python3

import sys
import csv

custodians = {}
fields = ['street-custodian', 'bbox']
sep = '\t'


def decode(p):
    f = []
    for s in p.strip('[]').split(','):
        f.append(float(s))
    return f

def encode(bbox):
    return "[%.2f,%.2f,%.2f,%.2f]" % (bbox[0], bbox[1], bbox[2], bbox[3])

for row in csv.DictReader(sys.stdin, delimiter=sep):
    if 'point' not in row:
        continue

    p = decode(row['point'])

    if row['street-custodian'] not in custodians:
        bbox = [p[0], p[1], p[0], p[1]]
    else:
        bbox = decode(custodians[row['street-custodian']]['bbox'])

        if bbox[0] > p[0]:
            bbox[0] = p[0]
        elif bbox[2] < p[0]:
            bbox[2] = p[0]

        if bbox[1] > p[1]:
            bbox[1] = p[1]
        elif bbox[3] < p[1]:
            bbox[3] = p[1]

    custodians[row['street-custodian']] = {
        'street-custodian': row['street-custodian'],
        'bbox': encode(bbox)
    }


print(sep.join(fields))

for s in sorted(custodians, key=int):
    print(sep.join([custodians[s][field] for field in fields]))
