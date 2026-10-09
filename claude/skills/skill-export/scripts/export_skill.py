#!/usr/bin/env python3
"""スキルを1つ、ローカルへ書き出せる形にまとめるスクリプト。

使い方:
  python3 export_skill.py <スキルフォルダのパス | スキル名> [--out <dir>]

  - パスを渡した場合: そのフォルダ(SKILL.md があるもの)をそのまま使う。
    skill-creator で今作成・更新した、まだインストールされていないスキルはこちら。
  - スキル名を渡した場合: /mnt/skills 配下のインストール済みスキルから探す。

出力(--out 既定: ./skill-export-out):
  <out>/<name>/...      スキルフォルダのコピー(SKILL.md, scripts/ など)
  <out>/<name>.zip      同じ内容のzip(PCへ一括で書き出す・展開する用)
  <out>/files.json      ファイル一覧(相対パス・サイズ・sha256・実行権限)
"""
import argparse
import hashlib
import json
import shutil
import sys
import zipfile
from pathlib import Path

SKILLS_ROOT = Path("/mnt/skills")
SEARCH_DIRS = ["user", "private", "organization", "plugins", "examples", "public"]
# 書き出しに含めないもの(skill-creator の作業用ファイルなど)
IGNORE = shutil.ignore_patterns("__pycache__", "*.pyc", ".DS_Store", "evals",
                                "*-workspace", "*.skill")


def resolve(target):
    p = Path(target).expanduser()
    if (p / "SKILL.md").is_file():
        return p.resolve()
    if p.name == "SKILL.md" and p.is_file():
        return p.parent.resolve()
    short = target.split(":")[-1]  # "anthropic-skills:lgtm" のような接頭辞を外す
    for d in SEARCH_DIRS:
        cand = SKILLS_ROOT / d / short
        if (cand / "SKILL.md").is_file():
            return cand
    return None


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("target", help="スキルフォルダのパス、またはスキル名")
    ap.add_argument("--out", default="skill-export-out")
    args = ap.parse_args()

    src = resolve(args.target)
    if src is None:
        print(f"エラー: '{args.target}' に SKILL.md のあるスキルが見つかりません", file=sys.stderr)
        return 1

    out = Path(args.out).resolve()
    dest = out / src.name
    if dest.exists():
        shutil.rmtree(dest)
    out.mkdir(parents=True, exist_ok=True)
    shutil.copytree(src, dest, ignore=IGNORE)

    files = []
    zip_path = out / f"{src.name}.zip"
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
        for p in sorted(dest.rglob("*")):
            if p.is_file():
                rel = p.relative_to(dest).as_posix()  # スキルフォルダ内の相対パス
                zf.write(p, rel)
                files.append({"path": rel, "size": p.stat().st_size,
                              "sha256": sha256(p),
                              "executable": bool(p.stat().st_mode & 0o111)})

    info = {"name": src.name, "source_dir": str(src), "export_dir": str(dest),
            "zip": str(zip_path), "files": files}
    (out / "files.json").write_text(json.dumps(info, ensure_ascii=False, indent=2),
                                    encoding="utf-8")

    print(f"[{src.name}] {src} -> {dest}")
    for f in files:
        mark = " (実行権限あり)" if f["executable"] else ""
        print(f"  {f['path']}  {f['size']}B{mark}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
