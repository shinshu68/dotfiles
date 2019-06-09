#!/home/shinshu/.anyenv/envs/pyenv/shims/python

import sys
import os
import subprocess
import inquirer
from inquirer import themes
from inquirer.render.console import ConsoleRender, List
from readchar import key


class ExtendedConsoleRender(ConsoleRender):
    def render_factory(self, question_type):
        if question_type == "list":
            return ExtendedList
        return super().render_factory(question_type)


class ExtendedList(List):
    def process_input(self, pressed):
        if pressed == 'j':
            pressed = key.DOWN
        elif pressed == 'k':
            pressed = key.UP
        elif pressed == 'q':
            pressed = key.CTRL_C
        elif pressed == 'g':
            self.current = 0
        elif pressed == 'G':
            self.current = len(self.question.choices) - 1

        super().process_input(pressed)


def runVimAndCommit(word):
    prefix = word + ':'
    cmd = 'vim msgfile.txt'
    if prefix == 'None:':
        subprocess.run([cmd], shell=True)
    else:
        subprocess.run([f'{cmd} -c "InputPrefix {prefix}"'], shell=True)

    subprocess.run(['git commit --file="./msgfile.txt"'], shell=True)
    if os.path.exists('msgfile.txt'):
        os.remove('msgfile.txt')


def main(files):
    pwd = os.getcwd()
    reporoot = subprocess.run('git rev-parse --show-toplevel', stdout=subprocess.PIPE, shell=True)
    if reporoot.returncode != 0:
        exit()
    else:
        os.chdir(reporoot.stdout.decode("utf8").strip())

    subprocess.run([f'git add {files}'], shell=True)
    subprocess.run([f'git status'], shell=True)
    question = [
        inquirer.List('word',
                      message="choice prefix word",
                      choices=['Add', 'Update', 'Fix', 'Move', 'Clean', 'Delete', 'None'],
                      ),
    ]
    result = inquirer.prompt(question, render=ExtendedConsoleRender(theme=themes.Default()))
    if result is None:
        os.chdir(pwd)
        exit()

    runVimAndCommit(result['word'])
    os.chdir(pwd)


if __name__ == '__main__':
    args = sys.argv
    gitaddFiles = '.'
    if len(args) > 1:
        gitaddFiles = ' '.join(args[1:])

    main(gitaddFiles)
