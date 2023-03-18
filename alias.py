#!/usr/bin/env python3
import argparse
import re
import sys

"""
Usage:
alias.py -t support@company.com -f alias@my.custom.domain

Output:
alias+support=company.com@my.custom.domain
"""

def main():
    parser = argparse.ArgumentParser(description='Parse email alias')
    parser.add_argument('-t', help='To: email address', required=True)
    parser.add_argument('-f', help='From: email address', required=True)
    parser.add_argument('-m', help='Generate a mailto: link', action='store_true', default=False)
    args = parser.parse_args()

    to = args.t
    frm = args.f

    if not re.match(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$', to):
        print('Invalid To: email address')
        sys.exit(1)

    if not re.match(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$', frm):
        print('Invalid From: email address')
        sys.exit(1)

    to = to.split('@')
    frm = frm.split('@')

    alias = f'{frm[0]}+{to[0]}={to[1]}@{frm[1]}'

    if args.m:
        print(f'mailto:{alias}')
    else:
      print(alias)

if __name__ == '__main__':
    main()
