import subprocess
import os
import sys
import readchar
import time
import shutil
import colorama
from getMyIssues import *

def runVim(prefix):
    print()
    prefix = '[' + prefix + ']'
    if prefix == '[None]' or prefix == '[]':
        subprocess.run([f'vim msgfile.txt'], shell=True)
    else:
        subprocess.run([f'vim msgfile.txt -c "InputPrefix {prefix}"'], shell=True)

    subprocess.run(["git commit --file='./msgfile.txt'"], shell=True)
    if input('push? [y/n]') == 'y':
        subprocess.run(["git push origin master"], shell=True)

    if os.path.exists('msgfile.txt'):
        os.remove('msgfile.txt')

def posAndStr(l, n, esc):
    if n < 0:
        n = 0
    if n >= len(l):
        n = len(l)-1

    s = esc
    for i, t in zip(range(len(l)), l):
        if i == n:
            s += '->'
            s += colorama.Fore.GREEN + t + colorama.Fore.RESET
        else:
            s += '  '
            s += t
        if i != len(l)-1:
            s += '\n'

    return n, s

def reWrite(position, lines):
    i, s = posAndStr(lines, position, ('\033[2K\033[F'*(len(lines)-1)))
    sys.stderr.write(s)
    sys.stderr.flush()
    return i


def main():
    subprocess.run(["git add ."], shell=True)
    subprocess.run(["git status"], shell=True)

    l = ['show issues','','add','update','fix','move','clean','delete', 'None']
    i, s = posAndStr(l, 0, '')

    sys.stderr.write(s)
    sys.stderr.flush()

    while(True):
        c = readchar.readchar()
        if c == 'j':
            i = i+1
            i = reWrite(i,l)

        elif c == 'k':
            i = i-1
            i = reWrite(i,l)

        elif c == 'q':
            print()
            exit()

        elif c == 'g':
            c = readchar.readchar()
            if c == 'g':
                i = reWrite(0,l)

        elif c == 'G':
            i = len(l) -1
            i = reWrite(i,l)

        elif c == '\r':
            if l[i] == 'show issues':
                issues = getMyIssues()
                sys.stderr.write('\033[2K\033[F'*(len(l)-1))
                sys.stderr.flush()
                for _issue in issues:
                    print(_issue, end='')

                print()

                l.remove(l[0])
                l.remove(l[0])
                i,s = posAndStr(l, i, '')
                sys.stderr.write(s)
                sys.stderr.flush()

            else:
                runVim(l[i])
                exit()


        time.sleep(0.1)

if __name__ == '__init__':
    colorama.init()
    terminal_size = shutil.get_terminal_size()

if __name__ == '__main__':
    main()



