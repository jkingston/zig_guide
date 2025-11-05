# Example Fix: Chapter 5 Citation Standardization

**Issue:** Chapter 5 (I/O, Streams & Formatting) uses inline citations instead of footnotes, inconsistent with other chapters and the style guide.

**Current Format (Inline):**
```markdown
TigerBeetle's metrics formatting ([src/trace/statsd.zig:59-85](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/trace/statsd.zig#L59-L85))
```

**Target Format (Footnotes):**
```markdown
TigerBeetle's metrics formatting uses fixed buffer patterns.[^4]

[^4]: [TigerBeetle - Fixed buffer metrics formatting](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/trace/statsd.zig#L59-L85)
```

---

## Step-by-Step Fix Process

### 1. Identify All Citations in Chapter 5

From sections/05_io_streams/content.md, current References section lists:

1. Zig Standard Library – Io.zig ([0.15.2](https://github.com/ziglang/zig/blob/0.15.2/lib/std/Io.zig))
2. Zig Standard Library – fmt.zig ([0.15.2](https://github.com/ziglang/zig/blob/0.15.2/lib/std/fmt.zig))
3. Zig Standard Library – fs/File.zig ([0.15.2](https://github.com/ziglang/zig/blob/0.15.2/lib/std/fs/File.zig))
4. TigerBeetle – Fixed buffer metrics formatting ([src/trace/statsd.zig:59-85](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/trace/statsd.zig#L59-L85))
5. TigerBeetle – Direct I/O implementation ([src/io/linux.zig:1433-1570](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/io/linux.zig#L1433-L1570))
6. TigerBeetle – LSE error recovery ([src/storage.zig:279-384](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/storage.zig#L279-L384))
7. Ghostty – Event loop stream management ([src/termio/Exec.zig](https://github.com/ghostty-org/ghostty/blob/main/src/termio/Exec.zig))
8. Ghostty – Config file patterns ([src/config/file_load.zig:136-166](https://github.com/ghostty-org/ghostty/blob/main/src/config/file_load.zig#L136-L166))
9. Bun – Buffered I/O with reference counting ([src/shell/IOReader.zig](https://github.com/oven-sh/bun/blob/main/src/shell/IOReader.zig))
10. ZLS – Fixed buffer logging ([src/main.zig:50-100](https://github.com/zigtools/zls/blob/master/src/main.zig#L50-L100))
11. zig.guide – Readers and Writers ([standard-library/readers-and-writers](https://zig.guide/standard-library/readers-and-writers))

### 2. Search for Inline Citations in Text

Search patterns to find:
- `([text](url))`
- Direct GitHub links in prose
- Source code references without footnotes

### 3. Convert Each Citation

**Example 1: Simple factual claim**

Before:
```markdown
The standard library provides buffering through `std.io.bufferedWriter()` 
(see [std/io.zig](https://github.com/ziglang/zig/blob/0.15.2/lib/std/io.zig))
```

After:
```markdown
The standard library provides buffering through `std.io.bufferedWriter()`.[^1]

[^1]: [Zig Standard Library - io.zig](https://github.com/ziglang/zig/blob/0.15.2/lib/std/io.zig)
```

**Example 2: Code pattern reference**

Before:
```markdown
TigerBeetle uses fixed buffers for metrics formatting 
([source](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/trace/statsd.zig#L59-L85))
```

After:
```markdown
TigerBeetle uses fixed buffers for metrics formatting, avoiding heap allocation 
during high-frequency operations.[^4]

[^4]: [TigerBeetle - Fixed buffer metrics formatting](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/trace/statsd.zig#L59-L85)
```

### 4. Place Footnote Definitions

Add all footnote definitions just before the References section:

```markdown
## Summary

[Summary text...]

---

## References

[^1]: [Zig Standard Library - Io.zig](https://github.com/ziglang/zig/blob/0.15.2/lib/std/Io.zig)
[^2]: [Zig Standard Library - fmt.zig](https://github.com/ziglang/zig/blob/0.15.2/lib/std/fmt.zig)
[^3]: [Zig Standard Library - fs/File.zig](https://github.com/ziglang/zig/blob/0.15.2/lib/std/fs/File.zig)
[^4]: [TigerBeetle - Fixed buffer metrics](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/trace/statsd.zig#L59-L85)
[^5]: [TigerBeetle - Direct I/O implementation](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/io/linux.zig#L1433-L1570)
[^6]: [TigerBeetle - LSE error recovery](https://github.com/tigerbeetle/tigerbeetle/blob/main/src/storage.zig#L279-L384)
[^7]: [Ghostty - Event loop stream management](https://github.com/ghostty-org/ghostty/blob/main/src/termio/Exec.zig)
[^8]: [Ghostty - Config file patterns](https://github.com/ghostty-org/ghostty/blob/main/src/config/file_load.zig#L136-L166)
[^9]: [Bun - Buffered I/O with reference counting](https://github.com/oven-sh/bun/blob/main/src/shell/IOReader.zig)
[^10]: [ZLS - Fixed buffer logging](https://github.com/zigtools/zls/blob/master/src/main.zig#L50-L100)
[^11]: [zig.guide - Readers and Writers](https://zig.guide/standard-library/readers-and-writers)

### References

1. [Zig Standard Library - Io.zig](https://github.com/ziglang/zig/blob/0.15.2/lib/std/Io.zig)
2. [Zig Standard Library - fmt.zig](https://github.com/ziglang/zig/blob/0.15.2/lib/std/fmt.zig)
...
```

### 5. Verify Consistency

After conversion:
- [ ] All citations in text use `[^N]` format
- [ ] All footnote numbers are sequential (1, 2, 3...)
- [ ] Each footnote reference has a matching definition
- [ ] Footnote definitions appear before References section
- [ ] References section remains for human readability
- [ ] Run: `grep -o '\[^[0-9]\+\]' sections/05_io_streams/content.md | wc -l` should show 11
- [ ] Run: `grep -c '^\[^[0-9]\+\]:' sections/05_io_streams/content.md` should show 11

### 6. Re-run Build

```bash
./scripts/prepare-mdbook.sh
mdbook build
# Verify footnotes render correctly
```

---

## Automation Script (Optional)

For chapters with many inline citations, consider this helper script:

```bash
#!/bin/bash
# extract_inline_citations.sh - Find inline citations to convert

file="$1"
echo "=== Inline Citations in $file ==="
grep -n '(\[.*\](http' "$file" || echo "None found"
echo ""
echo "=== GitHub URLs not in footnotes ==="
grep -n 'github.com' "$file" | grep -v '^\[^' || echo "None found"
```

Usage:
```bash
./extract_inline_citations.sh sections/05_io_streams/content.md
```

---

## Testing the Fix

1. **Before fixing:**
   ```bash
   grep -c '^\[^[0-9]\+\]:' sections/05_io_streams/content.md
   # Expected: 0
   ```

2. **After fixing:**
   ```bash
   # Should show 11 definitions
   grep -c '^\[^[0-9]\+\]:' sections/05_io_streams/content.md
   
   # Should show 11 references (or more if cited multiple times)
   grep -o '\[^[0-9]\+\]' sections/05_io_streams/content.md | wc -l
   ```

3. **Verify in built book:**
   ```bash
   ./scripts/prepare-mdbook.sh
   mdbook serve
   # Visit http://localhost:3000/ch05_io_streams.html
   # Click footnote numbers - should link to definitions
   # Click footnote definitions - should link back
   ```

---

## Similar Fixes Needed

Apply the same process to:
- **Chapter 3**: 26 refs vs 8 defs (missing 18 definitions)
- Any chapter where ref count != def count

---

## Time Estimate

- **Chapter 5 conversion:** 2-3 hours
  - Find all inline citations: 30 min
  - Convert to footnotes: 1 hour
  - Add definitions: 30 min
  - Test and verify: 30 min
  - Re-run build: 15 min

- **All chapters audit:** 4-6 hours total

---

**Last Updated:** 2025-11-05  
**Status:** Example/Template - Ready to implement
