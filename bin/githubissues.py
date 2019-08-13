from github import Github
import git
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
    remote_user_repo = origin_url[len(host):-len(ext)]
    return g.get_repo(remote_user_repo)


def main():
    remote_repo = get_remote_repo()
    for issue in remote_repo.get_issues():
        print(f'{issue.number:>3}', issue.title)


def show_detail(num):
    remote_repo = get_remote_repo()
    issue = remote_repo.get_issue(num)
    print(issue.title, f'#{issue.number}')
    print(issue.body) if issue.body != '' else print('No description proveded.')
    print()
    for comment in issue.get_comments():
        print(comment.body)


if __name__ == '__main__':
    args = sys.argv
    if len(args) > 1:
        show_detail(int(args[1]))
    else:
        main()

