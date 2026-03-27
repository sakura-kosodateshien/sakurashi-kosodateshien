#!/bin/bash
# ============================================================
# check_html_js.sh  ─  HTML + JS 二重チェック
# ① HTML構文チェック（Python）
# ② JS宣言前参照チェック（ESLint no-use-before-define）
# ============================================================
FILE=$1
if [ -z "$FILE" ]; then echo "Usage: $0 <file>"; exit 1; fi

PASS=true

# ── ① HTML構文チェック ──────────────────────────────────────
python3 - "$FILE" << 'PYEOF'
import sys
from html.parser import HTMLParser
class Check(HTMLParser):
    def handle_error(self, msg): print(f"HTML ERROR: {msg}"); sys.exit(1)
c = Check()
c.feed(open(sys.argv[1], encoding='utf-8').read())
print("✅ HTML OK")
PYEOF
[ $? -ne 0 ] && PASS=false

# ── ② ESLint：no-use-before-define チェック ─────────────────
python3 - "$FILE" << 'PYEOF'
import sys, re, subprocess, tempfile, os

src = open(sys.argv[1], encoding='utf-8').read()
# srcなしのscriptタグのみ抽出
blocks = re.findall(r'<script(?![^>]*\bsrc\b)[^>]*>([\s\S]*?)</script>', src, re.IGNORECASE)

errors = []
for i, block in enumerate(blocks):
    stripped = block.strip()
    if not stripped: continue
    # URL import文はコメント化（ESLintが解釈できないため）
    safe = re.sub(r'^\s*import\s+.*?from\s+["\']https?://[^\'"]+["\'];?\s*$', '// import removed', stripped, flags=re.MULTILINE)
    with tempfile.NamedTemporaryFile(suffix='.js', mode='w', encoding='utf-8', delete=False) as f:
        f.write(safe)
        fname = f.name
    result = subprocess.run(
        ['/home/claude/node_modules/.bin/eslint',
         '--config', '/home/claude/eslint.config.mjs', fname],
        capture_output=True, text=True
    )
    os.unlink(fname)
    if result.returncode != 0:
        out = result.stdout
        tdz = [l for l in out.split('\n') if 'no-use-before-define' in l]
        if tdz:
            errors.append(f"Script block {i+1}:\n" + "\n".join(f"  {l.strip()}" for l in tdz[:5]))

if errors:
    print("❌ JS ERROR（宣言前参照）:")
    for e in errors: print(e)
    sys.exit(1)
else:
    print("✅ JS OK（宣言前参照なし）")
PYEOF
[ $? -ne 0 ] && PASS=false

# ── 結果サマリー ────────────────────────────────────────────
if [ "$PASS" = true ]; then
  echo "🟢 ALL CHECKS PASSED: $FILE"
  exit 0
else
  echo "🔴 CHECK FAILED: $FILE — GitHubへのpushを中止してください"
  exit 1
fi
