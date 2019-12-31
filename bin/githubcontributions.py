#!/usr/bin/env python

from html.parser import HTMLParser
import click
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
                d = {
                    'data-count': attrs['data-count'],
                    'fill': attrs['fill'],
                    'data-date': attrs['data-date']
                }
                self.data.append(d)

    def handle_endtag(self, tag):
        pass


@click.command()
@click.option('--halloween', is_flag=True, help="Halloween Mode")
def cmd(halloween):
    subprocess.run('tput civis', shell=True)

    column, _ = os.get_terminal_size()
    block = '  '

    user = subprocess.run('git config --get user.name', shell=True, stdout=subprocess.PIPE).stdout
    username = user.decode('utf-8').strip()

    url = f'https://github.com/users/{username}/contributions'
    res = requests.get(url)

    parser = Parser()
    parser.feed(res.text)

    arr = [[0 for i in range(53)] for j in range(7)]

    # trueTo256 で計算した
    dic = {
        '#ebedf0': 255,
        '#c6e48b': 186,  # これだけ昔のよくわからん計算方法で算出した
        '#7bc96f': 114,
        '#239a3b': 35,
        '#196127': 22,
        '#ffee4a': 227,
        '#ffc501': 220,
        '#fe9600': 208,
        '#03001c': 0
    }

    # ハロウィン用の変換辞書
    normalToHalloween = {
        '#ebedf0': '#ebedf0',
        '#c6e48b': '#ffee4a',
        '#7bc96f': '#ffc501',
        '#239a3b': '#fe9600',
        '#196127': '#03001c'
    }

    for i in range(7):
        for j in range(i, len(parser.data), 7):
            txt = ""
            color_data = parser.data[j]['fill']

            if halloween:
                color_data = normalToHalloween[color_data]

            try:
                red, green, blue = truecolor.hex_to_rgb(color_data)
                txt += f'\x1b[38;2;{red};{green};{blue}m'
                txt += f'\x1b[48;2;{red};{green};{blue}m'
            except NameError:
                c = dic[color_data]
                txt += f'\x1b[38;05;{c}m'
                txt += f'\x1b[48;05;{c}m'
            txt += block
            txt += '\x1b[0m'
            arr[i][j // 7] = txt

    for i in range(7):
        f = False
        for j in range(max(0, 53 - column // 2), 53):
            if arr[i][j] != 0:
                print(rf'{arr[i][j]}', end='')
                f = True
        if f:
            print()

    print()
    print(f"{last_contribution} contributions on Today")

    if os.getenv('TMUX') is not None:
        res = subprocess.run('tmux list-panes',
                             shell=True,
                             stdout=subprocess.PIPE).stdout.decode('utf-8').split('\n')
        if len(res) <= 2:
            exit()

        while True:
            c = readchar.readchar()
            if (c == readchar.key.CTRL_C or c == readchar.key.ESC or c == 'q' or c == readchar.key.ENTER):
                subprocess.run('tmux kill-pane', shell=True)

    subprocess.run('tput cnorm', shell=True)


def main():
    cmd()


if __name__ == '__main__':
    main()
