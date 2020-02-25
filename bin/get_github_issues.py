from github import Github
import click
import json
import os
from modules.issues import is_inside_git_dir, get_remote_repo_name


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

