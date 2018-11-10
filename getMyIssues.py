'''
    issueをwslから確認したくなったので
'''
import os
import sys
import itertools
from github import Github

class pycolor:
    BLACK = '\033[30m'
    RED = '\033[31m'
    GREEN = '\033[32m'
    YELLOW = '\033[33m'
    BLUE = '\033[34m'
    PURPLE = '\033[35m'
    CYAN = '\033[36m'
    WHITE = '\033[37m'
    END = '\033[0m'
    BOLD = '\038[1m'
    UNDERLINE = '\033[4m'
    INVISIBLE = '\033[08m'
    REVERCE = '\033[07m'

    def setcolor(state):
        if state == 'open':
            return pycolor.GREEN + state + pycolor.END

def getMyIssues():
    token = os.environ.get('GitHub_TOKEN')
    # or using an access token
    g = Github(token)

    repo_name = os.path.basename(os.getcwd())

    now_repo = None

    result = []
    issueNumbers = []

    for repo in g.get_user().get_repos():
        if repo.name == repo_name:
            now_repo = repo
            break

    result.append(str(now_repo) + '\n')

    for _issue in now_repo.get_issues():
        result.append('  #{:<4} {}'.format(_issue.number, _issue.title))
        result.append(f'[{pycolor.setcolor(_issue.state)}]\n')
        issueNumbers.append('#' + str(_issue.number))

        for line in _issue.body.split('\n'):
            if _issue.body == '':
                break

            result.append('        ' + line + '\n')

        comments = _issue.get_comments()
        if _issue.body != '' and len(list(comments)) != 0:
            result.append('\n')

        for i, _comment in zip(itertools.count(1), comments):
            result.append('    {:<4}'.format(i))
            line = _comment.body.split('\n')
            result.append(line[0] + '\n')
            spaces = ' ' * 4
            for l in line[1:]:
                result.append('    ' + spaces + l + '\n')

        result.append('\n')

    return result , issueNumbers

if __name__ == '__main__':
    res, num = getMyIssues()
    for i in res:
        print(i, end='')
