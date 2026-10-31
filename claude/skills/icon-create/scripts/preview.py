"""アイコン候補の SVG を並べた比較用 HTML を作る。

使い方:
    python3 preview.py <出力する HTML> <SVG> [<SVG> ...]

各候補について、各サイズでの表示、Android のマスクで切り取った表示、
単色 (テーマアイコン) 表示、暗い背景での表示を1ページに並べる。
SVG は data URI で埋め込むので、HTML 1ファイルで完結する。
"""

import base64
import html
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

SVG_NS = "http://www.w3.org/2000/svg"
VIEWPORT = 108
VISIBLE = 72
SAFE_RADIUS = 33

PLAIN_SIZES = [192, 96, 48, 32, 16]
MASK_SIZE = 96
MASKS = [("円", "50%"), ("スクワークル", "36%"), ("角丸", "22%")]

ET.register_namespace("", SVG_NS)
ET.register_namespace("xlink", "http://www.w3.org/1999/xlink")


def to_data_uri(svg_text: str) -> str:
    encoded = base64.b64encode(svg_text.encode("utf-8")).decode("ascii")
    return f"data:image/svg+xml;base64,{encoded}"


def find_layer(root: ET.Element, layer_id: str):
    for parent in root.iter():
        for child in list(parent):
            if child.get("id") == layer_id:
                return parent, child
    return None, None


def load_candidate(path: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    warnings = []
    root = ET.fromstring(text)

    view_box = (root.get("viewBox") or "").split()
    if view_box != ["0", "0", str(VIEWPORT), str(VIEWPORT)]:
        warnings.append(f"viewBox が 0 0 {VIEWPORT} {VIEWPORT} ではありません")

    if find_layer(root, "foreground")[1] is None:
        warnings.append("#foreground のグループがありません")

    parent, background = find_layer(root, "background")
    if background is None:
        warnings.append("#background のグループがありません (単色表示は全体で代用)")
        mono_text = text
    else:
        parent.remove(background)
        mono_text = ET.tostring(root, encoding="unicode")

    return {
        "name": path.stem,
        "full": to_data_uri(text),
        "mono": to_data_uri(mono_text),
        "warnings": warnings,
    }


def safe_zone(diameter_px: float) -> str:
    return (
        f'<span class="safe" style="width:{diameter_px:.1f}px;'
        f'height:{diameter_px:.1f}px"></span>'
    )


def render_plain(uri: str) -> str:
    cells = []
    for size in PLAIN_SIZES:
        overlay = safe_zone(size * 2 * SAFE_RADIUS / VIEWPORT)
        cells.append(
            f'<figure><div class="box" style="width:{size}px;height:{size}px">'
            f'<img src="{uri}" width="{size}" height="{size}" alt="">{overlay}</div>'
            f"<figcaption>{size}px</figcaption></figure>"
        )
    return "".join(cells)


def render_masked(uri: str, radius: str) -> str:
    inner = MASK_SIZE * VIEWPORT / VISIBLE
    offset = (inner - MASK_SIZE) / 2
    overlay = safe_zone(MASK_SIZE * 2 * SAFE_RADIUS / VISIBLE)
    return (
        f'<div class="box mask" style="width:{MASK_SIZE}px;height:{MASK_SIZE}px;'
        f'border-radius:{radius}">'
        f'<img src="{uri}" width="{inner:.0f}" height="{inner:.0f}" '
        f'style="left:-{offset:.0f}px;top:-{offset:.0f}px" alt="">{overlay}</div>'
    )


def render_candidate(candidate: dict) -> str:
    name = html.escape(candidate["name"])
    warnings = "".join(
        f'<p class="warn">⚠ {html.escape(w)}</p>' for w in candidate["warnings"]
    )
    masks = "".join(
        f"<figure>{render_masked(candidate['full'], radius)}"
        f"<figcaption>{label}</figcaption></figure>"
        for label, radius in MASKS
    )
    mono = (
        f'<figure><div class="mono">{render_masked(candidate["mono"], "50%")}</div>'
        f"<figcaption>単色</figcaption></figure>"
    )
    return f"""
<section class="candidate">
  <h2>{name}</h2>
  {warnings}
  <h3>そのまま</h3>
  <div class="row light">{render_plain(candidate['full'])}</div>
  <div class="row dark">{render_plain(candidate['full'])}</div>
  <h3>Android (マスクで切り取り)</h3>
  <div class="row light">{masks}{mono}</div>
  <div class="row dark">{masks}</div>
</section>"""


PAGE = """<!doctype html>
<html lang="ja">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>アイコン候補の比較</title>
<style>
  :root {{ --bg: #f4f4f2; --card: #ffffff; --text: #222; --sub: #666; }}
  body {{ margin: 0; padding: 16px 24px 48px; background: var(--bg); color: var(--text);
         font-family: system-ui, "Segoe UI", "Hiragino Sans", "Noto Sans JP", sans-serif; }}
  header {{ display: flex; align-items: center; gap: 16px; flex-wrap: wrap; }}
  h1 {{ font-size: 20px; margin: 8px 0; }}
  button {{ padding: 6px 12px; border-radius: 6px; border: 1px solid #bbb; background: #fff; cursor: pointer; }}
  .note {{ color: var(--sub); font-size: 13px; margin: 4px 0 16px; }}
  .candidate {{ background: var(--card); border-radius: 12px; padding: 12px 20px 16px; margin-bottom: 20px; }}
  h2 {{ font-size: 18px; margin: 4px 0 8px; }}
  h3 {{ font-size: 13px; color: var(--sub); font-weight: 600; margin: 12px 0 6px; }}
  .row {{ display: flex; align-items: flex-end; gap: 20px; flex-wrap: wrap; padding: 14px 16px; border-radius: 8px; }}
  .row.light {{ background: #e9ebee; }}
  .row.dark {{ background: #1e1f22; margin-top: 6px; }}
  .row.dark figcaption {{ color: #aaa; }}
  figure {{ margin: 0; display: flex; flex-direction: column; align-items: center; gap: 6px; }}
  figcaption {{ font-size: 11px; color: var(--sub); }}
  .box {{ position: relative; }}
  .box img {{ display: block; }}
  .mask {{ overflow: hidden; }}
  .mask img {{ position: absolute; }}
  .mono .mask {{ background: #dfe5f2; }}
  .mono img {{ filter: brightness(0); opacity: 0.72; }}
  .safe {{ display: none; position: absolute; left: 50%; top: 50%; transform: translate(-50%, -50%);
          border: 1px dashed #e0245e; border-radius: 50%; pointer-events: none; box-sizing: border-box; }}
  body.show-safe .safe {{ display: block; }}
  .warn {{ color: #b3261e; font-size: 13px; margin: 4px 0; }}
</style>
</head>
<body>
<header>
  <h1>アイコン候補の比較</h1>
  <button type="button" onclick="document.body.classList.toggle('show-safe')">安全領域の表示を切り替え</button>
</header>
<p class="note">赤い点線の円が安全領域 (端末のマスクで切り取られない範囲) です。単色は Android 13 以降のテーマアイコンでの見え方です。</p>
{sections}
</body>
</html>
"""


def main(argv: list[str]) -> int:
    if len(argv) < 3:
        print("使い方: python3 preview.py <出力する HTML> <SVG> [<SVG> ...]", file=sys.stderr)
        return 1

    output = Path(argv[1])
    candidates = []
    for arg in argv[2:]:
        path = Path(arg)
        try:
            candidate = load_candidate(path)
        except (OSError, ET.ParseError) as error:
            print(f"{path}: 読み込めません ({error})", file=sys.stderr)
            return 1
        for warning in candidate["warnings"]:
            print(f"{path}: {warning}", file=sys.stderr)
        candidates.append(candidate)

    sections = "".join(render_candidate(c) for c in candidates)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(PAGE.format(sections=sections), encoding="utf-8")
    print(f"作成しました: {output}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
