#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = ["markdown", "pygments"]
# ///
"""Build the Zig: Zero to Hero book as static HTML."""

import re
import shutil
from pathlib import Path
from string import Template

import markdown
from markdown.extensions.codehilite import CodeHiliteExtension
from markdown.extensions.fenced_code import FencedCodeExtension
from markdown.extensions.footnotes import FootnoteExtension
from markdown.extensions.tables import TableExtension
from markdown.extensions.toc import TocExtension

ROOT = Path(__file__).resolve().parent.parent
BOOK_DIR = ROOT / "book"
STATIC_DIR = ROOT / "static"
OUT_DIR = ROOT / "_book"

PARTS = [
    ("Getting Started", range(1, 4)),
    ("Core Concepts", range(4, 9)),
    ("Build & Ecosystem", range(9, 13)),
    ("Quality & Operations", range(13, 15)),
]


def discover_chapters():
    """Find and sort all markdown files in book/."""
    files = list(BOOK_DIR.glob("*.md"))
    index = []
    numbered = []
    appendices = []
    for f in files:
        if f.name == "index.md":
            index.append(f)
        elif f.name[0].isdigit():
            numbered.append(f)
        else:
            appendices.append(f)
    numbered.sort(key=lambda f: f.name)
    appendices.sort(key=lambda f: f.name)
    return index + numbered + appendices


def extract_title(md_text, filename=""):
    """Extract title from first # heading, or derive from filename."""
    m = re.search(r"^#\s+(.+)$", md_text, re.MULTILINE)
    if m:
        return m.group(1).strip()
    if filename == "index.md":
        return "Introduction"
    # Derive from filename: 01-quick-start.md -> Quick Start
    stem = Path(filename).stem
    stem = re.sub(r"^\d+-", "", stem)  # strip leading number
    return stem.replace("-", " ").title()


def slug_from_path(path):
    """Generate HTML filename from markdown path."""
    return path.stem + ".html"


def preprocess_callouts(md_text):
    """Convert ::: {.callout-TYPE} blocks to HTML divs.

    Renders the callout body as markdown separately, then wraps in HTML.
    """
    def replace_callout(m):
        ctype = m.group(1)
        title = m.group(2)
        body = m.group(3).strip()
        # Convert body markdown to HTML
        body_html = markdown.markdown(body, extensions=[
            TableExtension(),
            FencedCodeExtension(),
            CodeHiliteExtension(guess_lang=False, css_class="codehilite"),
        ])
        return (
            f'<div class="callout callout-{ctype}">\n'
            f'<div class="callout-title">{title}</div>\n'
            f'{body_html}\n'
            f'</div>\n'
        )
    return re.sub(
        r'^:::\s*\{\.callout-(\w+)\}\s*\n##\s*([^\n]+)\n(.*?)^:::',
        replace_callout, md_text, flags=re.MULTILINE | re.DOTALL,
    )


def footnotes_to_sidenotes(html):
    """Relocate footnotes from bottom to inline sidenotes."""
    # Extract footnote definitions
    footnotes = {}
    for m in re.finditer(
        r'<li id="fn:([^"]+)">(.*?)</li>',
        html, re.DOTALL,
    ):
        fn_id = m.group(1)
        content = m.group(2).strip()
        # Strip wrapping <p> and back-reference link
        content = re.sub(r'<a [^>]*class="footnote-backref"[^>]*>.*?</a>', '', content)
        content = re.sub(r'^<p>(.*)</p>$', r'\1', content, flags=re.DOTALL).strip()
        footnotes[fn_id] = content

    # Replace each reference with inline sidenote
    def insert_sidenote(m):
        fn_id = m.group(1)
        num = m.group(2)
        content = footnotes.get(fn_id, "")
        return (
            f'<sup>{num}</sup>'
            f'<span class="sidenote"><sup>{num}</sup> {content}</span>'
        )
    html = re.sub(
        r'<sup id="fnref:([^"]+)"><a[^>]*>(\d+)</a></sup>',
        insert_sidenote, html,
    )

    # Remove bottom footnote section
    html = re.sub(
        r'<div class="footnote">.*?</div>\s*$',
        '', html, flags=re.DOTALL,
    )
    return html


def wrap_tables(html):
    """Wrap tables in scrollable container for mobile."""
    return re.sub(r'(<table>)', r'<div class="table-wrap">\1', html).replace('</table>', '</table></div>')


def convert_markdown(md_text):
    """Convert markdown to HTML with all extensions."""
    md = markdown.Markdown(extensions=[
        FootnoteExtension(),
        TableExtension(),
        FencedCodeExtension(),
        CodeHiliteExtension(guess_lang=False, css_class="codehilite"),
        TocExtension(permalink=False, toc_depth=3),
    ])
    return md.convert(md_text)


def build_sidebar(chapters, current_slug):
    """Build sidebar navigation HTML."""
    lines = ['<ul>']
    part_ranges = {ch: name for name, r in PARTS for ch in r}
    last_part = None

    for ch_path, title, slug in chapters:
        name = ch_path.name
        if name == "index.md":
            continue

        # Check if this starts a new part
        if name[0].isdigit():
            ch_num = int(name.split("-")[0])
            part = part_ranges.get(ch_num)
            if part and part != last_part:
                if last_part is not None:
                    lines.append("</ul></li>")
                lines.append(f'<li class="part">{part}</li>')
                lines.append('<li><ul>')
                last_part = part
        elif name[0].isalpha() and last_part != "Appendices":
            if last_part is not None:
                lines.append("</ul></li>")
            lines.append('<li class="part">Appendices</li>')
            lines.append('<li><ul>')
            last_part = "Appendices"

        active = ' class="active"' if slug == current_slug else ""
        lines.append(f'<li><a href="{slug}"{active}>{title}</a></li>')

    if last_part is not None:
        lines.append("</ul></li>")
    lines.append("</ul>")
    return "\n".join(lines)


def build():
    """Build all pages."""
    # Clean output
    if OUT_DIR.exists():
        shutil.rmtree(OUT_DIR)
    OUT_DIR.mkdir()
    (OUT_DIR / "static").mkdir()

    # Copy static assets
    shutil.copy2(STATIC_DIR / "style.css", OUT_DIR / "static" / "style.css")

    # Read template
    template = Template((STATIC_DIR / "page.html").read_text())

    # Discover and process chapters
    chapter_files = discover_chapters()
    chapters = []
    rendered = []

    for ch_path in chapter_files:
        md_text = ch_path.read_text()
        title = extract_title(md_text, ch_path.name)
        slug = slug_from_path(ch_path)

        processed = preprocess_callouts(md_text)
        html = convert_markdown(processed)
        html = footnotes_to_sidenotes(html)
        html = wrap_tables(html)

        chapters.append((ch_path, title, slug))
        rendered.append(html)

    # Write pages
    for i, (ch_path, title, slug) in enumerate(chapters):
        sidebar = build_sidebar(chapters, slug)

        prev_link = ""
        next_link = ""
        if i > 0:
            prev_title = chapters[i - 1][1]
            prev_slug = chapters[i - 1][2]
            prev_link = f'<a class="prev" href="{prev_slug}">&larr; {prev_title}</a>'
        if i < len(chapters) - 1:
            next_title = chapters[i + 1][1]
            next_slug = chapters[i + 1][2]
            next_link = f'<a class="next" href="{next_slug}">{next_title} &rarr;</a>'

        page_title = title if slug == "index.html" else f"{title} — Zig: Zero to Hero"
        page_html = template.safe_substitute(
            title=title,
            page_title=page_title,
            sidebar=sidebar,
            content=rendered[i],
            prev_link=prev_link,
            next_link=next_link,
        )
        (OUT_DIR / slug).write_text(page_html)

    print(f"Built {len(chapters)} pages in {OUT_DIR}/")
    for _, title, slug in chapters:
        print(f"  {slug:40s} {title}")


if __name__ == "__main__":
    build()
