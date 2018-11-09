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
    os.remove('msgfile.txt')

def pos(l, n, esc):
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

def main():
    subprocess.run(["git add ."], shell=True)
    subprocess.run(["git status"], shell=True)

    l = ['show issues','','add','update','fix','move','clean', 'None']
    i, s = pos(l, 0, '')

    sys.stderr.write(s)
    sys.stderr.flush()

    while(True):
        c = readchar.readchar()
        if c == 'j':
            i = i+1
            i,s = pos(l, i, ('\033[2K\033[F'*(len(l)-1)))
            sys.stderr.write(s)
            sys.stderr.flush()
        elif c == 'k':
            i = i-1
            i,s = pos(l, i, ('\033[2K\033[F'*(len(l)-1)))
            sys.stderr.write(s)
            sys.stderr.flush()

        elif c == 'q':
            print()
            exit()
        elif c == '\r':
            if i == 0:
                issues = getMyIssues()
                sys.stderr.write('\033[2K\033[F'*(len(l)-1))
                sys.stderr.flush()
                for _issue in issues:
                    print(_issue, end='')

                i,s = pos(l, i, '')
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



