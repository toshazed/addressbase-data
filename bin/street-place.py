#!/usr/bin/env python3

#
#  generate an explicit map from street localities and towns to places
#

import re
import os
import sys
import csv


def n7e(s):
    s = s.lower()
    s = re.sub('[\'\"]', '', s)
    s = re.sub('[/\-]', ' ', s)
    words = s.split() 
    s = ' '.join(words)
    return s


def row_key(row):
    return "%s:%s:%s:%s" % (
        n7e(row['street-custodian']),
        n7e(row['administrative-area']),
        n7e(row['town']),
        n7e(row['locality']))


#
#  load places from custodian map
#
place_map_file = sys.argv[1]
places = {}

log = os.fdopen(3, "w")

try:
    for row in csv.DictReader(open(place_map_file), delimiter='\t'):
        places[row_key(row)] = row['place']
except FileNotFoundError:
    print("missing %s" % (place_map_file), file=sys.stderr)

#
#  map places from text descriptions
#
fields = ["street", "name", "name-cy", "street-custodian", "place", "end-date"]
print("\t".join(fields))

for row in csv.DictReader(sys.stdin, delimiter='\t', quoting=csv.QUOTE_NONE):

    key =  row_key(row)
    if key not in places:
        print("unknown place\t%s" % (key), file=log)
        places[key] = ''
    else:
        row['place'] = places[key]

    print("\t".join([row.get(field, '') for field in fields]))
