import subprocess
import os
import sys
import readchar
import time
import shutil
import colorama
from getMyIssues import *

class gitcommit():
    def __init__(self):
        self.position = 0
        self.items = ['show issues','','add','update','fix','move','clean','delete','None']
        self.commands = ['j', 'k', 'q', 'g', 'G']

    def setPos(self):
        if self.position < 0:
            self.position = 0
        if self.position >= len(self.items):
            self.position = len(self.items) - 1

    def writeItem(self, esc):
        self.setPos()
        s = esc
        for i, t in zip(range(len(self.items)), self.items):
            if i == self.position:
                s += '->'
                s += colorama.Fore.GREEN + t + colorama.Fore.RESET
            else:
                s += '  '
                s += t
            if i != len(self.items) - 1:
                s += '\n'

        sys.stderr.write(s)
        sys.stderr.flush()

    def runVim(self):
        print()
        prefix = '[' + self.items[self.position] + ']'
        if prefix == '[None]':
            subprocess.run([f'vim msgfile.txt'], shell=True)
        else:
            subprocess.run([f'vim msgfile.txt -c "InputPrefix {prefix}"'], shell=True)

        subprocess.run(["git commit --file='./msgfile.txt'"], shell=True)
        if input('push? [y/n]') == 'y':
            subprocess.run(["git push origin master"], shell=True)

        if os.path.exists('msgfile.txt'):
            os.remove('msgfile.txt')


    def execute(self, cmd):
        if cmd == 'j':
            self.position += 1

        elif cmd == 'k':
            self.position -= 1

        elif cmd == 'g':
            c = readchar.readchar()
            if c == 'g':
                self.position = 0

        elif cmd == 'G':
            self.position = len(self.items) - 1

        elif cmd == 'q':
            print()
            exit()

        self.writeItem('\033[2K\033[F'*(len(self.items) - 1))

    def showIssues(self):
        issues, numbers = getMyIssues()
        sys.stderr.write('\033[2K\033[F'*(len(self.items)-1))
        sys.stderr.flush()
        for _issue in issues:
            print(_issue, end='')

        print(numbers)

        self.items.remove(self.items[0])
        self.items.remove(self.items[0])
        self.writeItem('')


def main():
    subprocess.run(["git add ."], shell=True)
    subprocess.run(["git status"], shell=True)

    gc = gitcommit()
    gc.writeItem('')

    while(True):
        c = readchar.readchar()
        if c in gc.commands:
            gc.execute(c)

        elif c == '\r':
            if gc.items[gc.position] == 'show issues':
                gc.showIssues()

            elif gc.items[gc.position] == '':
                pass

            else:
                gc.runVim()
                exit()

if __name__ == '__init__':
    colorama.init()

if __name__ == '__main__':
    main()


