from github import Github
import git
import json
import os
import subprocess
import sys


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


def get_remote_repo():
    if not is_inside_git_dir():
        exit()

    Token = os.getenv('GitHubToken')
    g = Github(Token)

    local_repo = git.Repo(get_status().stdout.decode('utf-8').strip())

    host = 'git@github.com:'
    ext = '.git'

    origin_url = local_repo.remotes.origin.url

    if origin_url[:5] == 'https':
        exit()

    remote_user_repo = origin_url[len(host):-len(ext)]
    return g.get_repo(remote_user_repo)


def main():
    remote_repo = get_remote_repo()
    data = {}
    for issue in remote_repo.get_issues():
        print(f'{issue.number:>3}', issue.title)
        data[issue.number] = {
            'title': issue.title,
            'body': issue.body if issue.body != '' else 'No description proveded.',
            'comments': list(map(lambda x: x.body, issue.get_comments()))
        }

    home = os.getenv('HOME')
    with open(f'{home}/dotfiles/bin/.issue_data', 'w') as f:
        json.dump(data, f, ensure_ascii=False, indent=4, separators=(',', ': '))


def show_detail(num):
    home = os.getenv('HOME')
    issue = None
    with open(f'{home}/dotfiles/bin/.issue_data') as f:
        issue = json.load(f)[f'{num}']

    print(issue['title'], f'#{num}')
    print(issue['body'])

    if len(issue['comments']) != 0:
        print()

    for comment in issue['comments']:
        print(comment)


if __name__ == '__main__':
    args = sys.argv
    if len(args) > 1:
        show_detail(int(args[1]))
    else:
        main()

