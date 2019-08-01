#!/usr/bin/python3

import requests
import truecolor
from html.parser import HTMLParser


class Parser(HTMLParser):
    def __init__(self):
        HTMLParser.__init__(self)
        self.data = []

    def handle_starttag(self, tag, attrs):
        if tag == "rect":
            attrs = dict(attrs)
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
        txt += truecolor.fore_text('■', truecolor.hex_to_rgb(data[1]))
    print(txt)
