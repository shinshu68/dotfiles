import json
import math
import os
import sys


def rgb2Lab(r, g, b):
    r = r / 255
    g = g / 255
    b = b / 255

    r = pow(((r + 0.055) / 1.055), 2.4) if r > 0.04045 else r / 12.92
    g = pow(((g + 0.055) / 1.055), 2.4) if g > 0.04045 else g / 12.92
    b = pow(((b + 0.055) / 1.055), 2.4) if b > 0.04045 else b / 12.92

    x = (r * 0.4124) + (g * 0.3576) + (b * 0.1805)
    y = (r * 0.2126) + (g * 0.7152) + (b * 0.0722)
    z = (r * 0.0193) + (g * 0.1192) + (b * 0.9505)

    x = x * 100
    y = y * 100
    z = z * 100

    x = x / 95.047
    y = y / 100
    z = z / 108.883

    x = pow(x, 1 / 3) if x > 0.008856 else (7.787 * x) + (4 / 29)
    y = pow(y, 1 / 3) if y > 0.008856 else (7.787 * y) + (4 / 29)
    z = pow(z, 1 / 3) if z > 0.008856 else (7.787 * z) + (4 / 29)

    L = (116 * y) - 16
    a = 500 * (x - y)
    b = 200 * (y - z)

    return L, a, b


def main(c):
    home = os.getenv('HOME')
    color_data = None
    with open(f'{home}/dotfiles/bin/color.json') as f:
        color_data = json.load(f)

    # rgb(hex)を整数に変換
    r = int(c[0:2], 16)
    g = int(c[2:4], 16)
    b = int(c[4:6], 16)
    print(r, g, b)

    L1, a1, b1 = rgb2Lab(r, g, b)

    min_dist = 10000
    min_dist_color = None
    for color in color_data:
        rgb = color['rgb']
        r2 = int(rgb['r'])
        g2 = int(rgb['g'])
        b2 = int(rgb['b'])
        L2, a2, b2 = rgb2Lab(r2, g2, b2)
        dist = math.sqrt(pow(L2 - L1, 2) + pow(a2 - a1, 2) + pow(b2 - b1, 2))
        if min_dist > dist:
            min_dist = dist
            min_dist_color = color['colorId']

    print(min_dist_color)


if __name__ == '__main__':
    args = sys.argv
    if len(args) != 2:
        exit()
    else:
        main(args[1])

