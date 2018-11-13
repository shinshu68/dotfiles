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
        self.position = 2
        self.issuePos = 0
        self.items = ['show issues','','add','update','fix','move','clean','delete','None']
        self.commands = ['j', 'k', 'q', 'g', 'G']
        self.mode = 'normal'
        self.close = ''

    def setPos(self):
        if self.position < 0:
            self.position = 0
        if self.position >= len(self.items):
            self.position = len(self.items) - 1

    def setIssuePos(self):
        if self.issuePos < 0:
            self.issuePos = 0;
        if self.issuePos >= len(self.issueNumbers):
            self.issuePos = len(self.issueNumbers) - 1

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

    def writeIssueNumber(self, esc):
        self.setIssuePos()
        s = esc
        for i , t in zip(range(len(self.issueNumbers)), self.issueNumbers):
            if i == self.issuePos:
                s += '->'
                s += colorama.Fore.GREEN + t + colorama.Fore.RESET
            else:
                s += '  '
                s += t
            if i != len(self.issueNumbers) - 1:
                s += '  '

        sys.stderr.write(s)
        sys.stderr.flush()

    def runVim(self):
        print()
        prefix = '[' + self.items[self.position] + ']'
        cmd = 'vim msgfile.txt'
        if prefix == '[None]':
            subprocess.run([cmd], shell=True)
        else:
            if self.close == '':
                subprocess.run([cmd + f' -c "InputPrefix {prefix}"'], shell=True)
            else:
                subprocess.run([cmd + f' -c "InsertClose {self.close}" -c "InputPrefix {prefix}"'], shell=True)

        subprocess.run(["git commit --file='./msgfile.txt'"], shell=True)
        if input('push? [y/n]') == 'y':
            subprocess.run(["git push origin master"], shell=True)

        if os.path.exists('msgfile.txt'):
            os.remove('msgfile.txt')


    def execute(self, cmd):
        if cmd == 'j':
            self.position += 1
            if self.items[self.position] == '':
                self.position += 1
            self.writeItem('\033[2K\033[F\033[2K'*(len(self.items) - 1))

        elif cmd == 'k':
            self.position -= 1
            if self.items[self.position] == '':
                self.position -= 1
            self.writeItem('\033[2K\033[F\033[2K'*(len(self.items) - 1))

        elif cmd == 'h' and self.mode == 'issue':
            self.issuePos -= 1
            self.writeIssueNumber('\033[2K\033[G')

        elif cmd == 'l' and self.mode == 'issue':
            self.issuePos += 1
            self.writeIssueNumber('\033[2K\033[G')

        elif cmd == 'g':
            c = readchar.readchar()
            if c == 'g':
                self.position = 0
                self.writeItem('\033[2K\033[F'*(len(self.items) - 1))

        elif cmd == 'G':
            self.position = len(self.items) - 1
            self.writeItem('\033[2K\033[F'*(len(self.items) - 1))

        elif cmd == 'q':
            if self.mode == 'normal':
                print()
                exit()

            elif self.mode == 'issue':
                print()
                self.mode = 'normal'
                self.position = 2
                self.writeItem('\033[2K\033[F\033[2K'*3)

    def showIssues(self):
        issues, numbers = getMyIssues()
        sys.stderr.write('\033[2K\033[F'*(len(self.items)-1))
        sys.stderr.flush()
        for _issue in issues:
            print(_issue, end='')

        self.issueNumbers = numbers

        #self.items.remove(self.items[0])
        #self.items.remove(self.items[0])
        #self.items.insert(0, 'close issue')
        self.items[0] = 'close issue'
        self.writeItem('')

    def closeIssue(self):
        self.mode = 'issue'
        self.issuePos = 0
        #print('\n')
        self.writeIssueNumber('\033[2K\033[F\033[2K'*(len(self.items)-3))

        self.commands = ['h', 'l', 'q']

        while True:
            c = readchar.readchar()
            if c in self.commands:
                self.execute(c)
            elif c == '\r':
                self.mode = 'normal'
                self.close = self.issueNumbers[self.issuePos]
                print()
                self.position = 2
                self.writeItem('')

            if self.mode != 'issue':
                break

        self.commands = ['j', 'k', 'q', 'g', 'G']

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

            elif gc.items[gc.position] == 'close issue':
                gc.closeIssue()

            elif gc.items[gc.position] == '':
                pass

            else:
                gc.runVim()
                exit()

if __name__ == '__init__':
    colorama.init()

if __name__ == '__main__':
    main()


