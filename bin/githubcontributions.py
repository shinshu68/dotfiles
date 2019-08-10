#!/usr/bin/env python

import requests
import truecolor
from html.parser import HTMLParser

last_contribution = None


class Parser(HTMLParser):
    def __init__(self):
        HTMLParser.__init__(self)
        self.data = []

    def handle_starttag(self, tag, attrs):
        global last_contribution
        if tag == "rect":
            attrs = dict(attrs)
            last_contribution = attrs['data-count']
            # print(attrs)
            if 'data-count' in attrs and 'fill' in attrs and 'data-date' in attrs:
                self.data.append((attrs['data-count'], attrs['fill'], attrs['data-date']))
                # print(attrs['data-count'], attrs['fill'], attrs['data-date'])

    def handle_endtag(self, tag):
        pass


url = 'https://github.com/users/shinshu68/contributions'
res = requests.get(url)

parser = Parser()

line = res.text.split('\n')
parser.feed(res.text)
for i in range(7):
    txt = ""
    for j in range(i, len(parser.data), 7):
        data = parser.data[j]
        red, green, blue = truecolor.hex_to_rgb(data[1])
        txt += f'\x1b[38;2;{red};{green};{blue}m'
        txt += f'\x1b[48;2;{red};{green};{blue}m'
        txt += '  '
        txt += '\x1b[0m'
    print(txt)

print(f"{last_contribution} contributions on Today")
