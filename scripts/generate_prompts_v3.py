# /// script
# dependencies = [
#   "pyyaml",
# ]
# ///
import sys, yaml
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SECTIONS_DIR = ROOT / "sections"
META_PATH = ROOT / "metadata" / "sections.yaml"
TEMPLATE_PATH = ROOT / "templates" / "section_prompt_v3.md"

REQUIRED_FIELDS = ["id", "title", "objective", "overview", "scope", "key_topics"]

def main():
    with open(META_PATH, "r", encoding="utf-8") as f:
        data = yaml.safe_load(f)

    tpl = TEMPLATE_PATH.read_text(encoding="utf-8")
    ok, fail = 0, 0

    for s in data.get("sections", []):
        missing = [k for k in REQUIRED_FIELDS if not s.get(k)]
        if missing:
            print(f"[WARN] Section {s.get('id','(unknown)')} missing fields: {missing}")
            fail += 1
            continue

        key_topics_md = "\n".join(f"- {t}" for t in s.get("key_topics", [])) or "- (none)"
        filled = (tpl
            .replace("{{title}}", s["title"])
            .replace("{{objective}}", s["objective"])
            .replace("{{overview}}", s["overview"])
            .replace("{{scope}}", s["scope"])
            .replace("{{key_topics_markdown}}", key_topics_md)
        )

        out_dir = SECTIONS_DIR / s["id"]
        out_dir.mkdir(parents=True, exist_ok=True)
        out_path = out_dir / "prompt.md"
        out_path.write_text(filled, encoding="utf-8")
        print(f"[OK]  {s['id']} -> {out_path.relative_to(ROOT)}")
        ok += 1

    print(f"Done. Generated {ok} prompt(s). {fail} skipped due to missing fields.")
    if fail:
        sys.exit(1)

if __name__ == "__main__":
    main()
