from github import Github, GithubException
import click
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


def get_remote_repo(repo_name):
    if not is_inside_git_dir():
        exit()

    Token = os.getenv('GitHubToken')
    g = Github(Token)

    return g.get_repo(repo_name)


def get_issues(repo):
    data = {}
    for issue in repo.get_issues():
        # print(f'{issue.number:>3}', issue.title)
        data[issue.number] = {
            'title': issue.title,
            'body': issue.body if issue.body != '' else 'No description provided.',
            'comments': list(map(lambda x: x.body, issue.get_comments()))
        }

    return data


@click.command()
@click.option('-f', '--force', is_flag=True)
def main(force):
    data = {}
    home = os.getenv('HOME')
    data_path = f'{home}/dotfiles/bin/.issue_data'

    if os.path.exists(data_path):
        with open(data_path, 'r') as f:
            data = json.load(f)

    if force or not os.path.exists(data_path):
        repo_name = get_remote_repo_name()
        remote_repo = get_remote_repo(repo_name)

        try:
            issues = get_issues(remote_repo)
        except Exception:
            exit()

        data[repo_name] = issues

    with open(data_path, 'w') as f:
        json.dump(data, f, ensure_ascii=False, indent=4, separators=(',', ': '))


def cmd():
    main()


if __name__ == '__main__':
    cmd()

