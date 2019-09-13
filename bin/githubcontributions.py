#!/usr/bin/env python

from html.parser import HTMLParser
import os
import readchar
import requests
import subprocess
try:
    import truecolor
except RuntimeError:
    pass

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
            if 'data-count' in attrs and 'fill' in attrs and 'data-date' in attrs:
                self.data.append((attrs['data-count'], attrs['fill'], attrs['data-date']))

    def handle_endtag(self, tag):
        pass


column, _ = os.get_terminal_size()
block = '  '

user = subprocess.run('git config --get user.name', shell=True, stdout=subprocess.PIPE).stdout
username = user.decode('utf-8').strip()

url = f'https://github.com/users/{username}/contributions'
res = requests.get(url)

parser = Parser()

line = res.text.split('\n')
parser.feed(res.text)

arr = [[0 for i in range(53)] for j in range(7)]

for i in range(7):
    for j in range(i, len(parser.data), 7):
        txt = ""
        data = parser.data[j]
        try:
            red, green, blue = truecolor.hex_to_rgb(data[1])
            txt += f'\x1b[38;2;{red};{green};{blue}m'
            txt += f'\x1b[48;2;{red};{green};{blue}m'
            txt += block
            txt += '\x1b[0m'
            arr[i][j // 7] = txt
        except NameError:
            dic = {
                '#ebedf0': 255,
                '#c6e48b': 186,
                '#7bc96f': 113,
                '#239a3b': 29,
                '#196127': 22
            }
            c = dic[data[1]]
            txt += f'\x1b[38;05;{c}m'
            txt += f'\x1b[48;05;{c}m'
            txt += block
            txt += '\x1b[0m'
            arr[i][j // 7] = txt

f = False
f2 = False
for i in range(7):
    for j in range(max(0, 53 - column // 2), 53):
        if arr[i][j] != 0:
            print(rf'{arr[i][j]}', end='')
            f = True
            f2 = True
    if f:
        print()

if f2:
    print()
print(f"{last_contribution} contributions on Today")

if os.getenv('TMUX') is not None:
    res = subprocess.run('tmux list-panes',
                         shell=True,
                         stdout=subprocess.PIPE).stdout.decode('utf-8').split('\n')
    if len(res) <= 2:
        exit()

    print('\x1b[0;0H')
    while True:
        c = readchar.readchar()
        if (c == readchar.key.CTRL_C or c == readchar.key.ESC or c == 'q'):
            subprocess.run('tmux kill-pane', shell=True)

