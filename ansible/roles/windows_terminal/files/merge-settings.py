"""Windows Terminal の settings.json に、足りないアクションとキーの割り当てだけを足す

標準入力から {"path": <settings.json のパス>, "actions": [{"id", "command", "keys"}, ...], "check": bool} を受け取り、
結果を {"changed": bool, "warnings": [...]} として標準出力に出す。check が true のときは書き込まない。
- id のアクションがなければ actions に足す
- keys がどこにも割り当てられていなければ、その id に割り当てる
- keys が別の操作に割り当て済みなら上書きせず、warnings に入れる
"""

import json
import os
import sys


def to_key_list(keys):
    """keys は文字列と配列のどちらでも書けるので、小文字の配列にそろえる"""
    if isinstance(keys, str):
        keys = [keys]
    return [k.lower() for k in keys]


def bound_to(settings, key):
    """key を割り当てている操作を返す。割り当てがなければ None"""
    for binding in settings.get('keybindings', []):
        if key in to_key_list(binding.get('keys', [])):
            return binding.get('id')
    # 古い形式では actions の中に keys と command を直接書く
    for action in settings.get('actions', []):
        if key in to_key_list(action.get('keys', [])):
            return action.get('id') or json.dumps(action.get('command'), ensure_ascii=False)
    return None


def main():
    params = json.load(sys.stdin)
    path = params['path']

    # コメント入りの JSON は読めないので、そのときはファイルを変更せずに失敗させる
    with open(path, encoding='utf-8-sig') as f:
        settings = json.load(f)

    changed = False
    warnings = []
    for item in params['actions']:
        actions = settings.setdefault('actions', [])
        if not any(action.get('id') == item['id'] for action in actions):
            actions.append({'command': item['command'], 'id': item['id']})
            changed = True

        key = item['keys'].lower()
        owner = bound_to(settings, key)
        if owner is None:
            settings.setdefault('keybindings', []).append({'id': item['id'], 'keys': item['keys']})
            changed = True
        elif owner != item['id']:
            warnings.append(f'{item["keys"]} は {owner} に割り当て済みのため、{item["id"]} を割り当てませんでした')

    if changed and not params.get('check'):
        # 途中で失敗しても元のファイルが壊れないよう、別名で書いてから置き換える
        # Windows Terminal と同じく、日本語はそのまま・末尾の改行なしで書く
        tmp = path + '.tmp'
        with open(tmp, 'w', encoding='utf-8') as f:
            json.dump(settings, f, ensure_ascii=False, indent=4)
        os.replace(tmp, path)

    json.dump({'changed': changed, 'warnings': warnings}, sys.stdout, ensure_ascii=False)


if __name__ == '__main__':
    main()
