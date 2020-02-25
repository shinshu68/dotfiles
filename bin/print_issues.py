from modules.issues import get_remote_repo_name
import json
import os
import sys


def print_issue_titles(data):
    for num, value in data.items():
        print(f'{num:>3}', value['title'])


def show_detail(data, num):
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


if __name__ == '__main__':
    home = os.getenv('HOME')
    repo_name = get_remote_repo_name()

    if not os.path.exists(f'{home}/dotfiles/bin/.issue_data'):
        exit()

    with open(f'{home}/dotfiles/bin/.issue_data') as f:
        issue_data = json.load(f)
        if repo_name not in issue_data:
            exit()

        repo_issues = issue_data[repo_name]

    if len(sys.argv) == 1:
        print_issue_titles(repo_issues)
    else:
        show_detail(repo_issues, sys.argv[1])
