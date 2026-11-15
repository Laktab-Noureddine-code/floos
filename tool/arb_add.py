#!/usr/bin/env python3
"""Merges French strings into lib/core/l10n/app_fr.arb.

Usage: python3 tool/arb_add.py < strings.json
Input JSON: {"key": "value"} or {"key": ["value", {"placeholders": {...}}]}.
"""
import json, sys, collections

path = 'lib/core/l10n/app_fr.arb'
try:
    arb = json.load(open(path), object_pairs_hook=collections.OrderedDict)
except FileNotFoundError:
    arb = collections.OrderedDict([('@@locale', 'fr')])
new = json.load(sys.stdin, object_pairs_hook=collections.OrderedDict)
for k, v in new.items():
    if isinstance(v, list):
        arb[k] = v[0]
        arb['@' + k] = v[1]
    else:
        arb[k] = v
json.dump(arb, open(path, 'w'), ensure_ascii=False, indent=2)
open(path, 'a').write('\n')
print(f'{len(new)} keys merged, {sum(1 for k in arb if not k.startswith("@"))} total')
