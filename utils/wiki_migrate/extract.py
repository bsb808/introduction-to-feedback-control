#!/usr/bin/env python3
"""
One-time helper for moving the ME2801 Confluence wiki export into the Quarto site.

The HTML export is large (~6 GB, almost all attachments), so this script turns
each page into two small files that can be read and reviewed instead of the raw
HTML:

  tmp/wiki/extract/<slug>.md          compact Markdown of the page body
  tmp/wiki/extract/<slug>.links.tsv   one row per link/image with its resolved attachment

Links in the Markdown are written as [text](att:<filename>) for attachments,
[text](wiki:<page title>) for links to other wiki pages, and plain URLs otherwise.

Usage:
  ./extract.py index                     # one line per page: id, title, size
  ./extract.py extract PAGE [PAGE ...]   # PAGE = numeric page id (e.g. 1321402476)
  ./extract.py extract --all
  ./extract.py copy MANIFEST.tsv         # copy approved attachments into the repo

MANIFEST.tsv columns (header required): local_path, dest
  local_path  path from the links TSV (relative to the repo root)
  dest        destination path relative to the repo root (e.g. site/assets/w01/lec_w1_intro.pdf)

See specs/spec_wiki_transition.md.
"""

import argparse
import csv
import re
import shutil
import sys
from html import unescape
from pathlib import Path
from urllib.parse import unquote

from bs4 import BeautifulSoup, NavigableString, Tag

REPO = Path(__file__).resolve().parents[2]
EXPORT = REPO / 'tmp' / 'wiki' / 'html' / 'ME2801'
OUT = REPO / 'tmp' / 'wiki' / 'extract'

# Names worth a second look for copyrighted material (the Nise solutions manual chapters are restricted).
# A safety net for review only; homework solutions and the Nise handout are public.
RESTRICTED = re.compile(r'nise|^ch\d+\.pdf$', re.IGNORECASE)
WIKI_PAGE_HREF = re.compile(r'^(?:[\w\-]+_)?(\d+)\.html(#.*)?$|^index\.html$')

BLOCK_TAGS = {'p', 'div', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'ul', 'ol', 'li',
              'table', 'pre', 'blockquote', 'hr', 'section'}


def page_files():
    return sorted(p for p in EXPORT.glob('*.html'))


def page_id(path):
    if path.stem == 'index':
        return 'index'
    return path.stem.rsplit('_', 1)[-1]


def page_title(soup):
    t = soup.find(id='title-text')
    text = t.get_text(' ', strip=True) if t else (soup.title.get_text(strip=True) if soup.title else '')
    return re.sub(r'^ME2801\s*:\s*', '', text)


def slugify(title):
    return re.sub(r'[^a-z0-9]+', '_', title.lower()).strip('_')


def build_maps():
    """Map page id -> title, and (container id, filename) -> local attachment href.

    The second map resolves absolute wiki.nps.edu/download/attachments/<page>/<name>
    links to files in the export, which are stored by attachment id, not name.
    """
    titles, aliases = {}, {}
    alias_re = re.compile(r'data-linked-resource-default-alias="([^"]+)"[^>]*?href="(attachments/(\d+)/[^"]+)"'
                          r'|href="(attachments/(\d+)/[^"]+)"[^>]*?data-linked-resource-default-alias="([^"]+)"')
    for p in page_files():
        html = p.read_text(errors='replace')
        m = re.search(r'<title>(.*?)</title>', html[:4000], re.S)
        titles[page_id(p)] = re.sub(r'^ME2801\s*:\s*', '', m.group(1).strip()) if m else p.stem
        for a in alias_re.finditer(html):
            name, href, cid = (a.group(1), a.group(2), a.group(3)) if a.group(1) else (a.group(6), a.group(4), a.group(5))
            aliases[(cid, unescape(name))] = href
    return titles, aliases


def short_url(href):
    """Drop SharePoint's long, redundant nav= tracking parameter (the e= share token is kept)."""
    return re.sub(r'([?&])nav=[^&]*&?', r'\1', href).rstrip('?&')


class Converter:
    def __init__(self, pid, titles, aliases):
        self.pid = pid
        self.titles = titles
        self.aliases = aliases
        self.links = []

    # ---- links -------------------------------------------------------------
    def ref(self, el, href, text):
        kind, name, local, size = 'external', '', '', ''
        m = re.search(r'^(?:https?://wiki\.nps\.edu)?/download/attachments/(\d+)/([^?]+)', href)
        if m and (m.group(1), unquote(m.group(2))) in self.aliases:
            name = unquote(m.group(2))
            href = self.aliases[(m.group(1), name)]
        if href.startswith('attachments/'):
            kind = 'image' if el.name == 'img' else 'attachment'
            name = name or el.get('data-linked-resource-default-alias') or Path(href.split('?')[0]).name
            lp = EXPORT / href.split('?')[0]
            local = str(lp.relative_to(REPO))
            size = f'{lp.stat().st_size / 1024:.0f}' if lp.exists() else 'MISSING'
            out = f'att:{name}'
        elif WIKI_PAGE_HREF.match(href):
            kind = 'wiki-page'
            m = WIKI_PAGE_HREF.match(href)
            target = m.group(1) or 'index'
            name = self.titles.get(target, href)
            out = f'wiki:{name}'
        else:
            if 'wiki.nps.edu' in href:
                kind = 'wiki-url'
            elif 'vimeo.com' in href:
                kind = 'vimeo'
            elif 'sharepoint.com' in href or 'onedrive' in href:
                kind = 'sharepoint'
            elif href.startswith('mailto:'):
                kind = 'mailto'
            out = short_url(href)
        restricted = 'yes' if name and RESTRICTED.search(name) else ''
        self.links.append([self.pid, text, kind, name, href, local, size, restricted])
        return out

    # ---- inline ------------------------------------------------------------
    def inline(self, el):
        if isinstance(el, NavigableString):
            return re.sub(r'\s+', ' ', str(el))
        if not isinstance(el, Tag):
            return ''
        if el.name in ('script', 'style'):
            return ''
        if el.name == 'br':
            return ' / '
        if el.name == 'img':
            src = el.get('src', '')
            if 'attachments/' not in src:
                return ''  # emoticons, icons
            return f'![{el.get("alt", "")}]({self.ref(el, src, el.get("alt", ""))})'
        inner = ''.join(self.inline(c) for c in el.children)
        if el.name == 'a' and el.get('href'):
            text = inner.strip() or el.get('href')
            return f'[{text}]({self.ref(el, el["href"], text)})'
        if el.name in ('strong', 'b') and inner.strip():
            return f'**{inner.strip()}** '
        if el.name in ('em', 'i') and inner.strip():
            return f'_{inner.strip()}_ '
        if el.name == 'code':
            return f'`{inner.strip()}`'
        return inner

    # ---- blocks ------------------------------------------------------------
    def blocks(self, el, indent=''):
        """Return a list of Markdown lines for el's children."""
        lines, buf = [], []

        def flush():
            text = re.sub(r'\s+', ' ', ''.join(buf)).strip()
            text = re.sub(r'^(?:/\s*)+|(?:\s*/)+$', '', text).strip()
            if text:
                lines.append(indent + text)
            buf.clear()

        for c in el.children:
            if isinstance(c, Tag) and (c.name in BLOCK_TAGS or c.find(BLOCK_TAGS)) and c.name not in ('a', 'span', 'strong', 'b', 'em'):
                flush()
                lines.extend(self.block(c, indent))
            elif isinstance(c, Tag) and c.name in ('span', 'strong', 'b', 'em') and c.find(BLOCK_TAGS):
                flush()
                lines.extend(self.blocks(c, indent))
            else:
                buf.append(self.inline(c))
        flush()
        return lines

    def block(self, el, indent):
        name = el.name
        if name in ('h1', 'h2', 'h3', 'h4', 'h5', 'h6'):
            return ['', '#' * (int(name[1]) + 1) + ' ' + self.inline(el).strip(), '']
        if name in ('ul', 'ol'):
            out = []
            for i, li in enumerate(el.find_all('li', recursive=False), 1):
                marker = '- ' if name == 'ul' else f'{i}. '
                sub = self.blocks(li, indent + '  ')
                if sub:
                    sub[0] = indent + marker + sub[0].lstrip()
                out.extend(sub)
            return out
        if name == 'table':
            return self.table(el, indent)
        if name == 'pre':
            return ['```', el.get_text().rstrip(), '```']
        if name == 'hr':
            return ['---']
        if name == 'p':
            return self.blocks(el, indent)
        return self.blocks(el, indent)

    def table(self, el, indent):
        """Flatten a table: each row becomes a heading, each cell a labeled block."""
        rows = [r for r in el.find_all('tr') if r.find_parent('table') is el]
        if not rows:
            return []
        header = []
        if rows[0].find('th') and not rows[0].find('td'):
            header = [self.inline(c).strip() for c in rows[0].find_all(['th', 'td'], recursive=False)]
            rows = rows[1:]
        out = ['']
        for r in rows:
            cells = r.find_all(['th', 'td'], recursive=False)
            if not cells:
                continue
            first = ' '.join(self.blocks(cells[0])).strip()
            out.append(f'{indent}#### {first}' if first else f'{indent}#### (row)')
            for j, c in enumerate(cells[1:], 1):
                label = header[j] if j < len(header) else f'col {j + 1}'
                body = self.blocks(c, indent + '  ')
                if not body:
                    continue
                out.append(f'{indent}- _{label}_:')
                out.extend(body)
            out.append('')
        return out


def extract(path, titles, aliases):
    soup = BeautifulSoup(path.read_text(errors='replace'), 'html.parser')
    title = page_title(soup)
    main = soup.find(id='main-content')
    pid = page_id(path)
    conv = Converter(pid, titles, aliases)
    lines = [f'# {title}', '', f'<!-- wiki page {pid} ({path.name}) -->', '']
    if main:
        lines += conv.blocks(main)
    text = re.sub(r'\n{3,}', '\n\n', '\n'.join(lines)).strip() + '\n'

    OUT.mkdir(parents=True, exist_ok=True)
    slug = slugify(title)
    (OUT / f'{slug}.md').write_text(text)
    with open(OUT / f'{slug}.links.tsv', 'w', newline='') as f:
        w = csv.writer(f, delimiter='\t', lineterminator='\n')
        w.writerow(['page_id', 'text', 'kind', 'name', 'href', 'local_path', 'size_kb', 'restricted'])
        w.writerows(conv.links)
    kinds = {}
    for row in conv.links:
        kinds[row[2]] = kinds.get(row[2], 0) + 1
    print(f'{pid}\t{slug}\t{len(text) // 1024} KB md\t' + ', '.join(f'{k}={v}' for k, v in sorted(kinds.items())))


def cmd_index(_args):
    titles, _ = build_maps()
    for p in page_files():
        print(f'{page_id(p)}\t{p.stat().st_size // 1024:>4} KB\t{titles[page_id(p)]}')


def cmd_extract(args):
    titles, aliases = build_maps()
    files = page_files()
    if args.all:
        targets = files
    else:
        by_id = {page_id(p): p for p in files}
        missing = [a for a in args.pages if a not in by_id]
        if missing:
            sys.exit(f'unknown page id(s): {", ".join(missing)} (run "index")')
        targets = [by_id[a] for a in args.pages]
    for p in targets:
        extract(p, titles, aliases)


def cmd_copy(args):
    with open(args.manifest, newline='') as f:
        rows = list(csv.DictReader(f, delimiter='\t'))
    for row in rows:
        src, dest = REPO / row['local_path'], REPO / row['dest']
        if not src.exists():
            print(f'MISSING\t{row["local_path"]}')
            continue
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dest)
        print(f'copied\t{row["dest"]}')


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest='cmd', required=True)
    sub.add_parser('index').set_defaults(func=cmd_index)
    e = sub.add_parser('extract')
    e.add_argument('pages', nargs='*')
    e.add_argument('--all', action='store_true')
    e.set_defaults(func=cmd_extract)
    c = sub.add_parser('copy')
    c.add_argument('manifest')
    c.set_defaults(func=cmd_copy)
    args = ap.parse_args()
    args.func(args)


if __name__ == '__main__':
    main()
