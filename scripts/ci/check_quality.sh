#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

python3 - <<'PY'
import os,re,sys
root='.'
pat=re.compile(r'\[[^\]]+\]\(([^)]+)\)')
missing=[]
def skip_dir(dp: str) -> bool:
    norm=dp.replace('\\','/')
    if '/.git' in norm:
        return True
    parts=[p for p in norm.split('/') if p]
    return any(p.startswith('.venv') for p in parts)
for dp,_,fs in os.walk(root):
    if skip_dir(dp):
        continue
    for fn in fs:
        if not fn.endswith('.md'):
            continue
        path=os.path.join(dp,fn)
        txt=open(path,'r',encoding='utf-8',errors='ignore').read()
        for m in pat.finditer(txt):
            p=m.group(1).strip()
            if p.startswith(('http://','https://','mailto:','#')):
                continue
            p=p.split('#',1)[0]
            tgt=os.path.normpath(os.path.join(dp,p))
            if not os.path.exists(tgt):
                missing.append((path,p,tgt))
if missing:
    for row in missing:
        print(f"MISSING_LINK {row[0]} -> {row[1]} ({row[2]})")
    sys.exit(1)

# unique doc_id check for markdown files with frontmatter
ids={}
for dp,_,fs in os.walk(root):
    if skip_dir(dp):
        continue
    for fn in fs:
        if not fn.endswith('.md'):
            continue
        p=os.path.join(dp,fn)
        lines=open(p,'r',encoding='utf-8',errors='ignore').read().splitlines()
        if len(lines) >= 3 and lines[0].strip() == '---':
            for i in range(1,min(len(lines),40)):
                if lines[i].strip() == '---':
                    break
                if lines[i].strip().startswith('doc_id:'):
                    doc_id=lines[i].split(':',1)[1].strip().strip('"')
                    ids.setdefault(doc_id,[]).append(p)
                    break

dup=[(k,v) for k,v in ids.items() if len(v)>1]
if dup:
    for k,v in dup:
        print(f"DUPLICATE_DOC_ID {k} -> {v}")
    sys.exit(1)

print('quality-links: PASS')
PY

bash scripts/ci/check_phase_f8_weekly_governance.sh

echo "quality-check: PASS"
