import git
import json
import os
import subprocess


def get_status():
    return subprocess.run('git rev-parse --show-toplevel',
                          shell=True,
                          stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE)


def is_inside_git_dir():
    if get_status().returncode == 0:
        return True
    else:
        return False


def get_remote_repo_name():
    if not is_inside_git_dir():
        exit()

    local_repo = git.Repo(get_status().stdout.decode('utf-8').strip())

    host = 'git@github.com:'
    ext = '.git'

    origin_url = local_repo.remotes.origin.url

    if origin_url[:5] == 'https':
        host = 'https://github.com/'

    return origin_url[len(host):-len(ext)]


def print_issue_titles(data):
    for num, value in data.items():
        print(f'{num:>3}', value['title'])


def show_detail(num):
    home = os.getenv('HOME')
    repo_name = get_remote_repo_name()
    issue = None
    with open(f'{home}/dotfiles/bin/.issue_data') as f:
        issue = json.load(f)[repo_name][f'{num}']

    print(issue['title'], f'#{num}')
    print(issue['body'].strip())

    if len(issue['comments']) != 0:
        print()

    for comment in issue['comments']:
        print(comment)


