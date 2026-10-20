#!/usr/bin/env python3
"""受け渡しフォルダに置かれたスキルを、デスクトップ版へ登録できる .skill にまとめるスクリプト。

使い方:
  python3 package_skills.py <受け渡しフォルダを置いた場所> --only 名前 [名前 ...] [--out <dir>]
                            [--installed-root <dir> ...] [--force]

  <受け渡しフォルダを置いた場所> の直下にある、SKILL.md を持つフォルダのうち、--only で指定したものを
  それぞれ1スキルとして扱う。--only は必須。取り込み先には同じセッションで前回取り込んだスキルが
  残っていることがあり、フォルダの中身だけで対象を決めると前回分が混ざるため、PC の受け渡しフォルダに
  今あるスキル名を必ず渡してもらう。
  スキルごとに、いま登録されている版(インストール済みのスキル)と比べて差分を出し、
  変わっているものだけ <out>/<name>.skill を作る。

出力(--out 既定: ./skill-sync-out):
  <out>/<name>.skill    デスクトップ版の「Save skill」で登録できるファイル(zip、先頭に <name>/ フォルダ)
  <out>/report.md       スキルごとの差分の報告(ユーザーに見せる要約の元)
  <out>/summary.json    スキルごとの状態(new / updated / unchanged / error)と .skill のパス
"""
import argparse
import difflib
import fnmatch
import json
import re
import sys
import zipfile
from pathlib import Path
from typing import Any

# 登録に含めないもの(skill-creator の作業用ファイルなど)
EXCLUDE_DIRS = {"__pycache__", "node_modules", ".git"}
EXCLUDE_GLOBS = {"*.pyc", "*.skill", "*-workspace"}
EXCLUDE_FILES = {".DS_Store", "Thumbs.db", "desktop.ini"}
ROOT_EXCLUDE_DIRS = {"evals"}  # スキル直下の evals/ だけ除く

# 1スキルあたりに表示する差分の最大行数(長すぎると会話で読めないため)
MAX_DIFF_LINES = 200


def default_installed_roots():
    """インストール済みスキルがありそうな場所を返す(環境によって置き場所が違うため複数見る)。"""
    roots = []
    # このスクリプト自身のスキル(skill-sync)が置かれている親フォルダ = 他のスキルの兄弟フォルダ
    roots.append(Path(__file__).resolve().parents[2])
    for d in ["user", "private", "organization", "plugins", "public", "examples"]:
        roots.append(Path("/mnt/skills") / d)
    roots.extend(sorted(Path("/root/.claude/skills/synced").glob("*")))
    return [r for r in roots if r.is_dir()]


def excluded(rel: Path) -> bool:
    parts = rel.parts
    if any(p in EXCLUDE_DIRS for p in parts):
        return True
    if parts and parts[0] in ROOT_EXCLUDE_DIRS:
        return True
    if any(fnmatch.fnmatch(p, g) for p in parts for g in EXCLUDE_GLOBS):
        return True
    return rel.name in EXCLUDE_FILES


def collect(skill_dir: Path) -> dict:
    """スキルフォルダ内のファイルを {相対パス: bytes} で返す。"""
    files = {}
    for p in sorted(skill_dir.rglob("*")):
        if p.is_file():
            rel = p.relative_to(skill_dir)
            if not excluded(rel):
                files[rel.as_posix()] = p.read_bytes()
    return files


def frontmatter(text: str) -> dict:
    """SKILL.md の YAML フロントマターから name と description を簡易的に取り出す。"""
    m = re.match(r"^---\r?\n(.*?)\r?\n---", text, re.S)
    if not m:
        return {}
    meta = {}
    for line in m.group(1).splitlines():
        km = re.match(r"^(name|description)\s*:\s*(.*)$", line)
        if km:
            meta[km.group(1)] = km.group(2).strip().strip('"').strip("'")
    return meta


def find_installed(name: str, roots):
    for r in roots:
        cand = r / name
        if (cand / "SKILL.md").is_file():
            return cand
    return None


def as_text(b: bytes):
    try:
        return b.decode("utf-8")
    except UnicodeDecodeError:
        return None


def normalized(rel: str, data: bytes) -> bytes:
    """比較用に正規化する。登録済みの SKILL.md はフロントマターの値が引用符付きに
    書き換えられていることがあるため、その違いだけなら差分とみなさない。"""
    if rel != "SKILL.md":
        return data
    text = as_text(data)
    if text is None:
        return data
    text = text.replace("\r\n", "\n")
    return re.sub(r'^(name|description)\s*:\s*["\']?(.*?)["\']?\s*$',
                  r"\1: \2", text, flags=re.M).encode("utf-8")


def diff_files(old: dict, new: dict):
    added = sorted(set(new) - set(old))
    removed = sorted(set(old) - set(new))
    changed = sorted(k for k in set(old) & set(new)
                     if normalized(k, old[k]) != normalized(k, new[k]))
    lines = []
    for k in changed + added:
        o = as_text(old.get(k, b"")) if k in old else ""
        n = as_text(new[k])
        if o is None or n is None:
            lines.append(f"(バイナリ: {k} が変更されています)")
            continue
        lines.extend(difflib.unified_diff(
            o.splitlines(), n.splitlines(),
            fromfile=f"登録済み/{k}" if k in old else "/dev/null",
            tofile=f"dotfiles/{k}", lineterm=""))
    return added, removed, changed, lines


def package(name: str, files: dict, out: Path) -> Path:
    path = out / f"{name}.skill"
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as zf:
        for rel, data in files.items():
            zf.writestr(f"{name}/{rel}", data)
    return path


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src", help="スキルフォルダが並んでいる受け渡しフォルダ")
    ap.add_argument("--only", nargs="+", required=True,
                    help="対象のスキル名(PC の受け渡しフォルダに今あるもの。前回の取り込み分を混ぜないため必須)")
    ap.add_argument("--out", default="skill-sync-out")
    ap.add_argument("--installed-root", action="append", default=None,
                    help="インストール済みスキルの置き場所(省略時は自動で探す)")
    ap.add_argument("--force", action="store_true", help="差分が無くても .skill を作る")
    args = ap.parse_args()

    src = Path(args.src)
    out = Path(args.out).resolve()
    out.mkdir(parents=True, exist_ok=True)
    for old in out.glob("*.skill"):  # 前回の結果を残さない
        old.unlink()
    roots = [Path(r) for r in args.installed_root] if args.installed_root else default_installed_roots()

    skill_dirs = sorted(d for d in src.iterdir() if d.is_dir() and (d / "SKILL.md").is_file())
    wanted = {w.split(":")[-1] for w in args.only}
    missing = wanted - {d.name for d in skill_dirs}
    skill_dirs = [d for d in skill_dirs if d.name in wanted]

    summary, report = [], []
    for d in skill_dirs:
        name = d.name
        new = collect(d)
        meta = frontmatter(as_text(new["SKILL.md"]) or "")
        entry: dict[str, Any] = {"name": name}
        if not meta.get("name") or not meta.get("description"):
            entry.update(status="error", message="SKILL.md のフロントマターに name / description がありません")
        elif meta["name"] != name:
            entry.update(status="error",
                         message=f"フォルダ名 '{name}' と SKILL.md の name '{meta['name']}' が一致しません")
        if entry.get("status") == "error":
            summary.append(entry)
            report += [f"## {name}: エラー", entry["message"], ""]
            continue

        inst = find_installed(name, roots)
        old = collect(inst) if inst else {}
        added, removed, changed, lines = diff_files(old, new)
        if inst is None:
            status = "new"
        elif not (added or removed or changed):
            status = "unchanged"
        else:
            status = "updated"
        entry.update(status=status, added=added, removed=removed, changed=changed,
                     installed_path=str(inst) if inst else None)
        if status != "unchanged" or args.force:
            entry["skill_file"] = str(package(name, new, out))
        summary.append(entry)

        label = {"new": "新規(未登録)", "updated": "更新あり", "unchanged": "変更なし"}[status]
        report.append(f"## {name}: {label}")
        if status != "new":
            for title, items in (("変更", changed), ("追加", added), ("削除", removed)):
                if items:
                    report.append(f"- {title}: " + ", ".join(items))
        else:
            report.append("- ファイル: " + ", ".join(new))
        if lines and status == "updated":
            shown = lines[:MAX_DIFF_LINES]
            report += ["", "```diff", *shown, "```"]
            if len(lines) > MAX_DIFF_LINES:
                report.append(f"(差分が長いため先頭 {MAX_DIFF_LINES} 行のみ表示。全 {len(lines)} 行)")
        report.append("")

    for m in sorted(missing):
        summary.append({"name": m, "status": "error", "message": "受け渡しフォルダに見つかりません"})
        report += [f"## {m}: エラー", "受け渡しフォルダに見つかりません", ""]

    (out / "summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
    (out / "report.md").write_text("\n".join(report), encoding="utf-8")
    print("\n".join(report))
    if not skill_dirs and not missing:
        print("受け渡しフォルダに SKILL.md のあるスキルフォルダがありません", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
