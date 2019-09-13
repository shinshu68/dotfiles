import json
import sys
import os


def main(c):
    home = os.getenv('HOME')
    color_data = None
    with open(f'{home}/dotfiles/bin/color.json') as f:
        color_data = json.load(f)

    r = int(c[0:2], 16)
    g = int(c[2:4], 16)
    b = int(c[4:6], 16)
    print(r, g, b)

    min_tmp = 10000
    color_tmp = None
    for color in color_data:
        rgb = color['rgb']
        tmp = 0
        tmp += abs(int(rgb['r']) - r)
        tmp += abs(int(rgb['g']) - g)
        tmp += abs(int(rgb['b']) - b)
        if min_tmp > tmp:
            min_tmp = tmp
            color_tmp = color['colorId']

    print(color_tmp)


if __name__ == '__main__':
    args = sys.argv
    if len(args) != 2:
        exit()
    else:
        main(args[1])

