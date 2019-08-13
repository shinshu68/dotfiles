from github import Github
import git
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


def main():
    if not is_inside_git_dir():
        return

    Token = os.getenv('GitHubToken')
    g = Github(Token)

    local_repo = git.Repo(get_status().stdout.decode('utf-8').strip())

    host = 'git@github.com:'
    ext = '.git'

    origin_url = local_repo.remotes.origin.url
    remote_user_repo = origin_url[len(host):-len(ext)]

    remote_repo = g.get_repo(remote_user_repo)
    for issue in remote_repo.get_issues():
        print(f'{issue.number:>3}', issue.title)


if __name__ == '__main__':
    main()

