# Bulk Example Extraction Workflow

This guide explains how to use the automated scripts to extract and fix code examples from markdown chapters.

## Tools Created

### 1. `scripts/bulk_extract_examples.py`
Extracts runnable Zig code blocks from markdown files to standalone example files.

**Features:**
- Automatically detects runnable examples (with `main()` or `test`)
- Extracts titles from markdown headings
- Generates descriptive filenames
- Creates `build.zig` for the chapter
- Creates `README.md` with example table
- Supports dry-run mode

**Usage:**
```bash
# Dry run (shows what would be extracted)
python3 scripts/bulk_extract_examples.py sections/04_collections_containers/ examples/ch04_collections/ --dry-run

# Actually extract
python3 scripts/bulk_extract_examples.py sections/04_collections_containers/ examples/ch04_collections/

# Extract without generating build.zig/README
python3 scripts/bulk_extract_examples.py sections/05_io_streams/ --skip-build --skip-readme
```

### 2. `scripts/fix_015_compat.py`
Automatically fixes common Zig 0.15.2 API compatibility issues.

**Fixes applied:**
- `std.ArrayList(T).init(allocator)` → `std.ArrayList(T){}`
- `list.append(item)` → `list.append(allocator, item)`
- `list.appendSlice(slice)` → `list.appendSlice(allocator, slice)`
- `list.deinit()` → `list.deinit(allocator)`
- `HashMap.init()` → `HashMap{}`
- `map.put(k, v)` → `map.put(allocator, k, v)`
- `toOwnedSlice()` → `toOwnedSlice(allocator)`

**Usage:**
```bash
# Dry run
python3 scripts/fix_015_compat.py examples/ch04_collections/ --dry-run

# Apply fixes
python3 scripts/fix_015_compat.py examples/ch04_collections/

# Fix single file
python3 scripts/fix_015_compat.py examples/ch04_collections/01_example.zig
```

### 3. `scripts/extract_code_blocks.py`
Analyzes markdown files to identify runnable vs snippet code blocks.

**Usage:**
```bash
# Analyze single chapter
python3 scripts/extract_code_blocks.py sections/04_collections_containers/content.md

# Analyze all chapters
python3 scripts/extract_code_blocks.py sections/
```

## Complete Workflow

### Step 1: Analyze Chapter
```bash
python3 scripts/extract_code_blocks.py sections/XX_chapter_name/content.md
```

**Output:**
```
=== content.md ===
Total blocks: 41
Runnable examples: 6
Inline snippets: 35
```

### Step 2: Extract Examples (Dry Run)
```bash
python3 scripts/bulk_extract_examples.py sections/XX_chapter_name/ examples/chXX_name/ --dry-run
```

Review what would be extracted.

### Step 3: Extract Examples (Real)
```bash
python3 scripts/bulk_extract_examples.py sections/XX_chapter_name/ examples/chXX_name/
```

**Output:**
- `examples/chXX_name/01_example_name.zig` (6 files)
- `examples/chXX_name/build.zig`
- `examples/chXX_name/README.md`

### Step 4: Fix API Compatibility
```bash
python3 scripts/fix_015_compat.py examples/chXX_name/
```

### Step 5: Build & Test
```bash
cd examples/chXX_name
zig build --summary all
```

**If compilation fails:**
1. Check error messages
2. Manually fix remaining issues (see Common Issues below)
3. Rebuild

### Step 6: Test Individual Examples
```bash
zig build run-01_example_name
zig build run-02_another_example
```

### Step 7: Update Root Build
Edit `build.zig` in project root:
```zig
const example_chapters = [_][]const u8{
    "ch02_idioms",
    "ch03_memory",
    "ch04_collections",  // Add new chapter
};
```

### Step 8: Validate
```bash
# From project root
bash scripts/validate_sync.sh
```

## Common Issues After Extraction

### Issue 1: GPA deinit() Incorrectly Modified

**Problem:**
```zig
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
defer _ = gpa.deinit(allocator);  // ❌ WRONG - gpa.deinit doesn't take allocator
```

**Fix:**
```zig
defer _ = gpa.deinit();  // ✅ CORRECT
```

**Why:** The auto-fixer adds allocator to all `.deinit()` calls, but GPA's deinit doesn't need it.

### Issue 2: Arena deinit() Incorrectly Modified

**Problem:**
```zig
var arena = std.heap.ArenaAllocator.init(gpa.allocator());
defer arena.deinit(allocator);  // ❌ WRONG
```

**Fix:**
```zig
defer arena.deinit();  // ✅ CORRECT
```

### Issue 3: appendAssumeCapacity Not Fixed

**Problem:**
```zig
list.appendAssumeCapacity(item);  // Still needs no allocator
```

**Fix:** This is correct - `appendAssumeCapacity` doesn't take an allocator parameter.

### Issue 4: Loop Variables with Enumerateissues

**Problem:**
```zig
for (items, 0..) |item, i| {  // Syntax changed in 0.15
```

**Fix:** This is already correct for 0.15.2.

## Status of Chapters

| Chapter | Examples | Extracted | Fixed | Tested | Status |
|---------|----------|-----------|-------|--------|--------|
| Ch02 | 9 | ✅ Manual | ✅ | ✅ | Complete |
| Ch03 | 5 | ✅ Manual | ✅ | ✅ | Complete |
| Ch04 | 6 | ✅ Script | 🔧 | ❌ | Needs manual fixes |
| Ch01 | 4 | ❌ | ❌ | ❌ | Pending |
| Ch05-15 | ~45 | ❌ | ❌ | ❌ | Pending |

## Tips

### Verify Before Committing
```bash
# Build all chapters
zig build validate

# Run sync validation
bash scripts/validate_sync.sh

# Check for leaks with GPA
zig build test
```

### Handle Version-Specific Code

Mark version-specific examples in filenames or comments:
```zig
// ✅ 0.15+ - Uses unmanaged ArrayList
// 🕐 0.14.x - Would use managed ArrayList with stored allocator
```

### Batch Process Multiple Chapters

```bash
for chapter in sections/0{4..7}_*/; do
    chapter_name=$(basename "$chapter")
    output="examples/${chapter_name//_/-}"

    echo "Processing $chapter_name..."
    python3 scripts/bulk_extract_examples.py "$chapter" "$output"
    python3 scripts/fix_015_compat.py "$output"

    cd "$output"
    zig build --summary all || echo "❌ Failed: $chapter_name"
    cd -
done
```

## Limitations of Auto-Fixer

The `fix_015_compat.py` script handles common cases but **cannot fix:**

1. **Context-specific deinit:**
   - GPA/Arena allocators vs containers
   - Custom structs with allocator-less deinit

2. **Complex method chains:**
   - `list.items.len` style code
   - Nested container operations

3. **Custom allocator names:**
   - Script assumes variable is named `allocator`
   - Different names require manual fixing

4. **Build system changes:**
   - `.root_source_file` → `.root_module` (done separately)

## Next Steps

After all chapters are extracted and fixed:

1. **Update examples_mapping.json** for sync validation
2. **Create global examples/README.md**
3. **Test on both Zig versions** (0.15.2 and 0.14.1)
4. **Document API differences** in IMPLEMENTATION_STATUS.md
5. **Update main README** with new structure

## Performance Metrics

**Chapter 4 extraction:**
- Manual approach: ~30-45 minutes
- Script approach: ~2 minutes + 5-10 minutes manual fixes
- **Speedup: ~5-10x faster**

**For remaining 10 chapters:**
- Estimated manual: 6-8 hours
- Estimated with scripts: 1-2 hours extraction + 2-3 hours fixes
- **Total savings: ~3-5 hours**
