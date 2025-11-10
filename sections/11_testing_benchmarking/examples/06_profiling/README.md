# Example 6: Profiling Integration

This example demonstrates how to integrate profiling tools with Zig applications to identify performance bottlenecks, analyze CPU usage, and track memory allocations.

## Learning Objectives

After working through this example, you will understand:

- How to configure Zig builds for profiling with debug symbols
- Using Callgrind for deterministic CPU profiling
- Using Linux perf for low-overhead sampling profiling
- Using Massif for heap memory profiling
- Generating and interpreting flame graphs
- Identifying performance bottlenecks in code
- Understanding profiler output and metrics
- Best practices for profiling workflow
- When to use different profiling tools
- How to validate optimizations with profiling data

## Key Concepts

### 1. Debug Symbols

Debug symbols are metadata embedded in binaries that map machine code back to source code:

- **Function names**: Human-readable names instead of addresses
- **Source locations**: File paths and line numbers
- **Variable information**: Names and types of variables
- **Inlining info**: Which functions were inlined where

**Critical for profiling**: Without debug symbols, profilers show addresses instead of meaningful information.

**In Zig**:
```zig
exe.root_module.strip = false;  // Keep debug symbols
```

### 2. Optimization Modes

Different optimization modes affect profiling results:

| Mode | Speed | Debug Info | Safety Checks | Use for Profiling |
|------|-------|------------|---------------|-------------------|
| Debug | Slowest | Maximum | All enabled | Debugging only |
| ReleaseSafe | Fast | Good | Enabled | **Recommended** |
| ReleaseFast | Fastest | Partial | Disabled | Final optimization |
| ReleaseSmall | Variable | Partial | Disabled | Size profiling |

**Best practice**: Profile in ReleaseSafe mode for a good balance of performance and debuggability.

### 3. Callgrind (Deterministic CPU Profiling)

**What it is**: A Valgrind tool that simulates CPU execution and counts instructions.

**Characteristics**:
- **Deterministic**: Same input → same output
- **Accurate**: Exact instruction counts
- **Comprehensive**: Shows call graphs and cache behavior
- **Slow**: 10-50x overhead
- **No permissions required**: Runs in user space

**When to use**:
- When you need exact, reproducible results
- For detailed call graph analysis
- When comparing optimizations precisely
- For understanding cache behavior

**Not suitable for**:
- Long-running applications (too slow)
- Real-time applications
- I/O-heavy workloads (distorted results)

### 4. Perf (Sampling Profiler)

**What it is**: Linux performance analysis tool using hardware performance counters.

**Characteristics**:
- **Sampling-based**: Periodically interrupts execution
- **Low overhead**: 1-5% performance impact
- **Statistical**: Results vary slightly between runs
- **Requires permissions**: May need kernel settings or sudo
- **Hardware support**: Uses CPU performance counters

**When to use**:
- For production-like performance analysis
- Long-running applications
- When overhead matters
- For real-world workload profiling

**Not suitable for**:
- Short-running programs (insufficient samples)
- Precise micro-benchmarking
- Non-Linux systems (use platform alternatives)

### 5. Massif (Heap Profiler)

**What it is**: A Valgrind tool that tracks heap memory usage over time.

**Characteristics**:
- **Heap tracking**: Monitors malloc/free patterns
- **Time-based**: Shows memory usage evolution
- **Stack traces**: Identifies allocation sites
- **Snapshots**: Captures memory state at intervals
- **Moderate overhead**: 2-20x slowdown

**When to use**:
- Finding memory leaks
- Identifying allocation hotspots
- Understanding heap growth patterns
- Analyzing peak memory usage

**Not suitable for**:
- Stack allocations (only tracks heap)
- Very short programs
- Programs that use custom allocators (may not track correctly)

### 6. Flame Graphs

**What they are**: Visual representation of profiling data showing call stacks.

**Characteristics**:
- **X-axis**: Alphabetical order (NOT time!)
- **Y-axis**: Stack depth (caller → callee)
- **Width**: Time spent (proportion of samples)
- **Interactive**: Click to zoom, search functions
- **Intuitive**: Visual patterns easy to spot

**Benefits**:
- Quick identification of hot paths
- Understanding call hierarchies
- Comparing different profiles
- Sharing results (SVG format)

### 7. Profiling Overhead

All profilers add overhead that affects execution:

| Tool | Overhead | Impact |
|------|----------|--------|
| Callgrind | 10-50x | Very slow, only for analysis |
| Perf | 1-5% | Minimal, production-like |
| Massif | 2-20x | Moderate, short runs only |
| Tracy | 1-10% | Low with proper setup |

**Important**: Always account for overhead when interpreting results.

### 8. Sampling vs Instrumentation

**Sampling** (perf):
- Periodically checks what code is running
- Low overhead
- Statistical (approximate)
- Good for overall picture

**Instrumentation** (Callgrind):
- Tracks every instruction
- High overhead
- Deterministic (exact)
- Good for detailed analysis

**Hybrid** (Tracy):
- Manual instrumentation points
- Controlled overhead
- Focused analysis

## Profiling Tools Comparison

### Overview Table

| Feature | Callgrind | Perf | Massif | Tracy |
|---------|-----------|------|--------|-------|
| **Type** | Instrumentation | Sampling | Instrumentation | Hybrid |
| **Overhead** | 10-50x | 1-5% | 2-20x | 1-10% |
| **Platform** | Linux, macOS* | Linux only | Linux, macOS* | Cross-platform |
| **Permissions** | User | May need root | User | User |
| **Metrics** | CPU, cache | CPU, hardware | Heap memory | Custom |
| **Output** | Call graph | Samples | Heap timeline | Visual timeline |
| **Setup** | Easy | Moderate | Easy | Requires instrumentation |
| **Best for** | Detailed analysis | Production profiling | Memory issues | Real-time apps |

*macOS support may be limited or require workarounds

### Callgrind Details

**Strengths**:
- Exact instruction counts
- Reproducible results
- Detailed cache simulation
- No permissions needed
- Great for before/after comparisons

**Weaknesses**:
- Very slow execution
- Not suitable for I/O operations
- May distort timing-sensitive code
- Large output files

**Metrics**:
- `Ir`: Instruction reads (total instructions executed)
- `Dr`: Data reads (memory reads)
- `Dw`: Data writes (memory writes)
- `I1mr`: L1 instruction cache misses
- `D1mr`: L1 data cache read misses
- `D1mw`: L1 data cache write misses
- `ILmr`: Last-level instruction cache misses
- `DLmr`: Last-level data cache read misses
- `DLmw`: Last-level data cache write misses

**Self vs Inclusive**:
- **Self**: Time spent in the function itself
- **Inclusive**: Time spent in function + all callees
- **Focus on high Self cost for optimization targets**

### Perf Details

**Strengths**:
- Low overhead
- Production-representative
- Hardware counter access
- Statistical precision
- Rich ecosystem (flame graphs, etc.)

**Weaknesses**:
- Linux-only
- May require permissions
- Statistical variance
- Shorter runs may lack samples

**Common Commands**:
```bash
perf record -g ./program          # Record with call graph
perf report                        # View interactive report
perf annotate function_name        # Show annotated assembly
perf diff old.data new.data        # Compare profiles
```

**Understanding Output**:
- **Overhead %**: Percentage of samples in this function
- **Self**: Samples directly in this function
- **Children**: Samples in functions called by this one
- **Symbol**: Function name

### Massif Details

**Strengths**:
- Tracks heap over time
- Identifies allocation sites
- Shows memory growth patterns
- Finds memory leaks
- Detailed snapshots

**Weaknesses**:
- Heap only (no stack)
- Moderate overhead
- May miss custom allocators
- Not real-time

**Output Format**:
```
    MB
6.472^                                               :#
     |                                               :#
     |                                               :#
     |                                               :#
     |                                         ::::::#
     |                                   ::::::     :#
     |                             :::::::    :     :#
     |                       :::::::        :       :#
     |                 :::::::           :          :#
     |           :::::::              :             :#
   0 +----------------------------------------------------------------------->Ms
     0                                                                   1000
```

**Snapshots**:
- Regular snapshots show memory usage
- Detailed snapshots (`@`) show allocation stack traces
- Peak snapshot shows maximum memory usage

### Tracy Details

**Strengths**:
- Real-time visualization
- Game engine focused
- Frame-level granularity
- GPU profiling support
- Beautiful UI

**Weaknesses**:
- Requires code instrumentation
- Additional dependency
- Learning curve
- Primarily for interactive applications

**Use case**: Best for game development and real-time applications.

## Build Configuration for Profiling

### Critical Settings

```zig
const exe = b.addExecutable(.{
    .name = "my_program",
    .root_source_file = b.path("src/main.zig"),
    .target = target,
    .optimize = optimize,
});

// CRITICAL: Keep debug symbols
exe.root_module.strip = false;

// RECOMMENDED: Keep frame pointers for better stack traces
exe.root_module.omit_frame_pointer = false;
```

### Why These Settings Matter

**`strip = false`**:
- Keeps function names in the binary
- Preserves source file and line information
- Enables meaningful profiler output
- Slightly increases binary size
- **No runtime performance cost**

Without debug symbols:
```
?? [0x7f4a2b3c1000]
?? [0x7f4a2b3c2450]
?? [0x7f4a2b3c3120]
```

With debug symbols:
```
main (main.zig:42)
computeResult (compute.zig:156)
fibonacci (compute.zig:23)
```

**`omit_frame_pointer = false`**:
- Enables frame pointer register
- Faster stack unwinding
- More reliable backtraces
- Small performance cost (~1-3%)
- Worth it for profiling accuracy

### Optimization Mode Selection

**For profiling, choose**:
```bash
# Recommended: Good balance
zig build -Doptimize=ReleaseSafe

# Alternative: Profile optimized code
zig build -Doptimize=ReleaseFast

# Debug mode: Only for debugging issues
zig build -Doptimize=Debug
```

**Why ReleaseSafe**:
- Realistic performance (with optimizations)
- Safety checks enabled (catches bugs)
- Good debug information
- Balance of speed and debuggability

**Why NOT Debug**:
- Too slow (not representative)
- No inlining (distorts results)
- Different code paths
- Only use for debugging specific issues

## Callgrind Guide

### Running Callgrind

**Basic usage**:
```bash
./scripts/profile_callgrind.sh
```

**Manual usage**:
```bash
zig build -Doptimize=ReleaseSafe

valgrind --tool=callgrind \
    --callgrind-out-file=callgrind.out \
    ./zig-out/bin/profiling_demo
```

**Advanced options**:
```bash
valgrind --tool=callgrind \
    --callgrind-out-file=callgrind.out \
    --collect-jumps=yes \           # Track jumps/branches
    --collect-systime=yes \         # Include system time
    --separate-threads=yes \        # Separate output per thread
    --cache-sim=yes \               # Simulate cache behavior
    --branch-sim=yes \              # Simulate branch prediction
    ./zig-out/bin/profiling_demo
```

### Viewing Results

**GUI (recommended)**:
```bash
kcachegrind callgrind.out
```

KCachegrind features:
- Interactive call graph
- Source code annotation
- Multiple views (flat, call graph, caller/callee)
- Filter and search functions
- Compare multiple profiles

**Text output**:
```bash
# Summary
callgrind_annotate callgrind.out

# With source annotation
callgrind_annotate --auto=yes callgrind.out

# Specific threshold (only show functions with >1% cost)
callgrind_annotate --threshold=1 callgrind.out
```

### Interpreting Output

**Example output**:
```
--------------------------------------------------------------------------------
Ir                      file:function
--------------------------------------------------------------------------------
4,245,123,456 (42.3%)   compute.zig:fibonacci
2,123,456,789 (21.2%)   compute.zig:multiplyMatrices
1,234,567,890 (12.3%)   memory.zig:allocateManySmall
  987,654,321  (9.8%)   compute.zig:isPrime
  ...
```

**What this means**:
- `fibonacci`: Executed 4.2 billion instructions (42.3% of total)
- This is a **hot function** and optimization target
- Focus on functions with highest percentage

**Self vs Inclusive costs**:
- **Self**: Instructions in this function only
- **Inclusive**: Instructions in this function + all it calls
- **High self cost** = direct optimization opportunity
- **High inclusive, low self** = optimize callees instead

### Finding Hotspots

1. **Sort by self cost** to find direct bottlenecks
2. **Check call graph** to understand context
3. **Look for**:
   - Functions called many times (high count)
   - Functions with high instruction count per call
   - Unexpected function calls
   - Excessive allocations

4. **Common patterns**:
   - Recursive functions show deep call trees
   - Tight loops show high instruction counts
   - Allocation-heavy code shows many malloc/free calls

### KCachegrind Navigation

**Views**:
- **Flat Profile**: List of all functions by cost
- **Call Graph**: Visual function relationships
- **Caller/Callee**: Who calls and is called by each function
- **Source Code**: Annotated source with costs
- **Assembly**: Annotated assembly code

**Workflow**:
1. Start with Flat Profile (sorted by Self cost)
2. Click on expensive function
3. Check Call Graph to see context
4. View Source Code to understand what it does
5. Analyze why it's expensive
6. Plan optimization

### Example Analysis

**Before optimization**:
```
45.2%  fibonacci (recursive)
```

**After adding memoization**:
```
 5.1%  fibonacci (with cache)
```

**Validation**: Callgrind shows 10x improvement in instruction count.

## Perf Guide

### Prerequisites

**Installation**:
```bash
# Ubuntu/Debian
sudo apt-get install linux-tools-common linux-tools-generic

# Fedora
sudo dnf install perf

# Arch
sudo pacman -S perf
```

**Permissions**:

Perf may require elevated permissions. Check current setting:
```bash
cat /proc/sys/kernel/perf_event_paranoid
```

Values:
- `-1`: No restrictions
- `0`: Allow raw tracepoint access (recommended)
- `1`: Allow kernel profiling (restrictive)
- `2`: CPU events only (very restrictive)

**Temporary fix**:
```bash
sudo sysctl kernel.perf_event_paranoid=1
```

**Permanent fix** (add to `/etc/sysctl.conf`):
```
kernel.perf_event_paranoid=1
```

### Running Perf

**Basic usage**:
```bash
./scripts/profile_perf.sh
```

**Manual usage**:
```bash
zig build -Doptimize=ReleaseSafe

perf record -g --call-graph=dwarf \
    ./zig-out/bin/profiling_demo

perf report
```

**Advanced options**:
```bash
perf record \
    -g \                              # Record call graph
    --call-graph=dwarf \              # Use DWARF for unwinding
    -F 999 \                          # Sample frequency (Hz)
    -e cycles \                       # Event to sample
    ./zig-out/bin/profiling_demo
```

**Common events**:
- `cycles`: CPU cycles (default)
- `instructions`: Retired instructions
- `cache-misses`: Cache miss events
- `branch-misses`: Branch mispredictions
- `cpu-clock`: CPU clock time

**List available events**:
```bash
perf list
```

### Viewing Results

**Interactive TUI** (recommended):
```bash
perf report
```

**Navigation**:
- `Enter`: Zoom into function
- `Esc`: Zoom out
- `a`: Annotate (show assembly)
- `h`: Help
- `q`: Quit
- `/`: Search

**Text output**:
```bash
perf report --stdio
```

**With call chains**:
```bash
perf report -g 'graph,0.5,caller' --stdio
```

### Interpreting Output

**Example output**:
```
# Overhead  Command          Shared Object       Symbol
# ........  ...............  ..................  .............................
#
    42.53%  profiling_demo   profiling_demo      [.] fibonacci
    21.34%  profiling_demo   profiling_demo      [.] multiplyMatrices
    12.45%  profiling_demo   profiling_demo      [.] isPrime
     9.87%  profiling_demo   profiling_demo      [.] allocateManySmall
    ...
```

**What this means**:
- **Overhead**: Percentage of samples in this function
- `42.53%`: 42.53% of samples were in `fibonacci`
- This indicates a **hot function**

**Children vs Self**:
- **Children**: Samples in callees
- **Self**: Samples in this function only
- **Total = Children + Self**

**Example with call chain**:
```
    42.53%  fibonacci
            |
            |--30.12%-- fibonacci (recursive)
            |          |
            |          |--20.45%-- fibonacci
            |          |
            |          --9.67%-- fibonacci
            |
            --12.41%-- main
```

### Understanding Overhead Percentages

**Overhead** = Proportion of samples

- `40%` overhead = 40% of execution time
- Focus on functions with `>5%` overhead
- Small percentages (`<1%`) usually not worth optimizing

**Statistical variance**:
- Perf uses sampling, results vary slightly
- Run multiple times for confidence
- Longer runs = more samples = less variance
- Look for consistent patterns

### Annotated Assembly

**View assembly for a function**:
```bash
perf annotate fibonacci
```

**Example output**:
```
       │    fibonacci():
  0.00 │      push   %rbp
  0.00 │      mov    %rsp,%rbp
  5.23 │      cmp    $0x1,%edi        ← 5.23% of samples here
  0.00 │      ja     0x1234
 42.15 │      movzx  %edi,%eax        ← 42.15% of samples here (hot spot!)
  0.00 │      pop    %rbp
  0.00 │      ret
```

**Hot spots** shown with high percentages indicate:
- CPU-intensive instructions
- Cache misses
- Branch mispredictions
- Optimization opportunities

### Advanced: Comparing Profiles

**Record baseline**:
```bash
perf record -o perf.data.old ./program
```

**Record after optimization**:
```bash
perf record -o perf.data.new ./program
```

**Compare**:
```bash
perf diff perf.data.old perf.data.new
```

**Output shows deltas**:
```
# Baseline  Delta  Symbol
# ........  .....  ..........
    42.3%   -30%   fibonacci    # 30% reduction - good!
    21.2%   +5%    main         # Slight increase
```

## Massif Guide

### Running Massif

**Basic usage**:
```bash
./scripts/profile_massif.sh
```

**Manual usage**:
```bash
zig build -Doptimize=ReleaseSafe

valgrind --tool=massif \
    --massif-out-file=massif.out \
    ./zig-out/bin/profiling_demo
```

**Advanced options**:
```bash
valgrind --tool=massif \
    --massif-out-file=massif.out \
    --time-unit=ms \              # Time in milliseconds
    --detailed-freq=10 \          # Detailed snapshot every 10 snapshots
    --max-snapshots=200 \         # Maximum snapshots to take
    --stacks=yes \                # Include stack allocations
    --pages-as-heap=yes \         # Track mmap allocations
    ./zig-out/bin/profiling_demo
```

### Viewing Results

**Text output** (recommended):
```bash
ms_print massif.out
```

**GUI viewer**:
```bash
massif-visualizer massif.out
```

### Understanding the Graph

**Example output**:
```
    MB
6.472^                                               :#
     |                                               :#
     |                                               :#
     |                                               :#
     |                                         ::::::#
     |                                   ::::::     :#
     |                             :::::::    :     :#
     |                       :::::::        :       :#
     |                 :::::::           :          :#
     |           :::::::              :             :#
   0 +----------------------------------------------------------------------->Ms
     0                                                                   1000
```

**Reading the graph**:
- **Y-axis**: Heap memory usage (MB)
- **X-axis**: Time (milliseconds)
- **`:`**: Regular snapshot
- **`#`**: Detailed snapshot
- **`@`**: Peak snapshot (maximum usage)

**Common patterns**:

**Sawtooth pattern**:
```
   ^
   |  /\  /\  /\
   | /  \/  \/  \
```
- Allocate → use → free cycles
- Healthy pattern for temporary allocations

**Ramp pattern**:
```
   ^
   |        /
   |      /
   |    /
   |  /
```
- Growing data structure
- Normal during startup
- Concerning if continuous

**Plateau pattern**:
```
   ^
   |  ________
   | |
   | |
```
- Constant working set
- Healthy for long-running apps

**Leak pattern**:
```
   ^
   |         /
   |       /
   |     /
   |   /
   | /
```
- Continuous growth
- Likely memory leak
- Never frees memory

### Reading Snapshots

**Detailed snapshot example**:
```
--------------------------------------------------------------------------------
  n        time(ms)         total(B)   useful-heap(B) extra-heap(B)    stacks(B)
--------------------------------------------------------------------------------
 50      1000.123       10,485,760       10,485,760             0            0
99.99% (10,485,760B) (heap allocation functions) malloc/new/new[], --alloc-fns, etc.
->99.99% (10,485,760B) 0x4012F3: allocateLargeBuffer (memory.zig:42)
  ->99.99% (10,485,760B) 0x401234: main (main.zig:123)
```

**Interpretation**:
- **total**: Total heap allocation (10 MB)
- **useful-heap**: Actually used (10 MB)
- **extra-heap**: Allocator overhead (0)
- **Stack trace**: Where allocation occurred
- **99.99%**: This allocation is almost all heap usage

**Multiple allocations**:
```
99.99% (10,485,760B) (heap allocation functions)
->50.00% (5,242,880B) 0x4012F3: allocateLargeBuffer
  ->50.00% (5,242,880B) 0x401234: main
->30.00% (3,145,728B) 0x4015A2: buildDataStructure
  ->30.00% (3,145,728B) 0x401234: main
->19.99% (2,097,152B) 0x401678: allocateManySmall
  ->19.99% (2,097,152B) 0x401234: main
```

**This shows**:
- 50% of heap in large buffers
- 30% in data structures
- 20% in many small allocations
- Clear allocation hotspots identified

### Finding Allocation Hotspots

1. **Find peak snapshot** (marked with `@`)
2. **Look for largest percentages** in stack traces
3. **Identify unexpected allocations**
4. **Check allocation site** in source code

**Questions to ask**:
- Is this allocation necessary?
- Can we reuse this memory?
- Can we allocate less frequently?
- Is the size appropriate?

### Memory Leak Detection

**Symptoms**:
- Continuous growth in heap graph
- No corresponding deallocation
- Peak usage at program end

**Finding leaks**:
1. Run with Massif
2. Look for ramp/leak pattern
3. Check final snapshot
4. Identify allocation sites still in use
5. Verify those allocations are intentional

**Example leak**:
```
Memory at end: 10 MB

90.00% (9,000,000B) 0x4012F3: demonstrateMemoryLeak
  ->90.00% (9,000,000B) 0x401234: main
```

**This shows**: 9 MB allocated but never freed.

## Flame Graph Guide

### Generating Flame Graphs

**Prerequisites**:
```bash
# Clone FlameGraph repository
git clone https://github.com/brendangregg/FlameGraph
export PATH=$PATH:$(pwd)/FlameGraph
```

**Generate**:
```bash
# First, run perf
./scripts/profile_perf.sh

# Then generate flame graph
./scripts/generate_flamegraph.sh
```

**Manual steps**:
```bash
# Convert perf data to folded format
perf script | stackcollapse-perf.pl > out.folded

# Generate SVG
flamegraph.pl out.folded > flamegraph.svg

# Open in browser
xdg-open flamegraph.svg
```

### Reading Flame Graphs

**Anatomy**:
```
[main]                                              ← Bottom: root function
 ├─[computeStuff]
 │  ├─[fibonacci]                                   ← Very wide: HOT
 │  ├─[multiplyMatrices]
 │  └─[isPrime]
 └─[allocateStuff]                                  ← Narrow: less time
```

**Visual elements**:

**Width** (most important):
- **Wide boxes** = More samples = More time spent
- **Narrow boxes** = Fewer samples = Less time spent
- Width is proportional to % of total time

**Height**:
- **Tall stacks** = Deep call chains
- Each level = function call
- Bottom up (root at bottom)

**Color**:
- Random coloring (helps distinguish)
- No semantic meaning
- Some generators use color for modules

**X-axis** (often misunderstood):
- **NOT time order**
- Alphabetical ordering
- Left/right position has no meaning
- Only width matters

### What to Look For

**Hot functions** (wide bars):
```
[════════════ fibonacci ══════════════]  ← 60% width = 60% of time (HOT!)
```

**Optimization target**: This function is spending most time.

**Deep call stacks** (tall towers):
```
[D]
[C]
[B]
[A]
```

**Indicates**: Deeply nested calls, potential for:
- Inlining opportunities
- Recursion optimization
- Call overhead reduction

**Plateau pattern** (wide at top):
```
[══════ same function ══════]
[══════ same function ══════]
[══════ same function ══════]
[═══════════ caller ═════════]
```

**Indicates**: Hot loop or repeated calls.

**Multiple paths** (branching):
```
    [D]  [E]  [F]
     |    |    |
     └────┴────┘
    [   caller  ]
```

**Indicates**: Function called from multiple places.

### Interactive Features

**Clicking**:
- Click box to zoom into that subtree
- Click "Reset Zoom" to zoom out
- Makes analyzing deep stacks easier

**Search**:
- Ctrl+F (or search box)
- Highlights all instances of function
- Shows total time across all calls

**Hover**:
- Shows function name
- Shows sample count
- Shows percentage

**Example workflow**:
1. Open flame graph
2. Look for widest boxes at top
3. Click to zoom into interesting area
4. Search for specific functions
5. Identify optimization targets

### Patterns and Anti-patterns

**Good patterns**:

**Flat profile** (most time in one function):
```
[════════════════ hotFunction ════════════════]
[═══════════════════ main ═══════════════════]
```
- Clear bottleneck
- Easy to optimize

**Bad patterns**:

**"Lasagna" stack** (many thin layers):
```
[tiny]
[tiny]
[tiny]
[tiny]
[tiny]
```
- Call overhead dominates
- Consider inlining

**Wide base, narrow top**:
```
      [narrow]
[═════ wide base ═════]
```
- Time spread across many functions
- No clear bottleneck
- May need algorithmic change

### Comparing Flame Graphs

**Side-by-side comparison**:
1. Generate baseline: `flamegraph.pl old.folded > old.svg`
2. Generate new: `flamegraph.pl new.folded > new.svg`
3. Open both in browser tabs
4. Compare visually

**Differential flame graph**:
```bash
difffolded.pl old.folded new.folded | flamegraph.pl > diff.svg
```

**Colors in diff**:
- **Red**: Increased (regression)
- **Blue**: Decreased (improvement)
- **Purple**: Unchanged

**Good diff** (mostly blue):
```
[blue: fibonacci]    ← Reduced time (good!)
[blue: isPrime]      ← Reduced time (good!)
[red: main]          ← Slight increase in overhead (ok)
```

### Advanced: Custom Flame Graphs

**Filter specific functions**:
```bash
perf script | stackcollapse-perf.pl | \
    grep -v 'malloc\|free' | \
    flamegraph.pl > filtered.svg
```

**Reverse flame graph** (top-down):
```bash
flamegraph.pl --reverse out.folded > reverse.svg
```

**Minimal flame graph** (remove insignificant):
```bash
flamegraph.pl --minwidth 1 out.folded > minimal.svg
```

## Common Pitfalls

### ❌ Profiling Stripped Binaries

**Problem**:
```zig
exe.root_module.strip = true;  // ❌ BAD for profiling
```

**Result**:
```
45.3%  0x7f4a2b3c1000
21.2%  0x7f4a2b3c2450
12.4%  0x7f4a2b3c3120
```

**Solution**:
```zig
exe.root_module.strip = false;  // ✅ GOOD
```

**Result**:
```
45.3%  fibonacci (compute.zig:23)
21.2%  multiplyMatrices (compute.zig:156)
12.4%  isPrime (compute.zig:78)
```

### ❌ Profiling Debug Builds

**Problem**:
```bash
zig build -Doptimize=Debug  # ❌ Too slow, not representative
```

**Issues**:
- No inlining (distorted call graph)
- No optimizations (unrealistic performance)
- Different code paths (safety checks in wrong places)

**Solution**:
```bash
zig build -Doptimize=ReleaseSafe  # ✅ Good balance
```

### ❌ Running Short Workloads

**Problem**:
```zig
const workload_size = 5;  // ❌ Too small
```

**Result**:
- Insufficient samples in perf
- Startup overhead dominates
- No clear patterns

**Solution**:
```zig
const workload_size = 30;  // ✅ Enough work to profile
```

**Rules of thumb**:
- Callgrind: At least 1 second runtime
- Perf: At least 5-10 seconds
- Massif: Long enough to see patterns

### ❌ Not Understanding Overhead

**Problem**: Profiling I/O-heavy code with Callgrind

```bash
valgrind --tool=callgrind ./io_heavy_app  # ❌ Distorted results
```

**Result**: I/O operations show inflated costs due to profiling overhead.

**Solution**: Use perf for I/O-heavy workloads.

### ❌ Optimizing Cold Paths

**Problem**: Optimizing functions that run rarely.

**Bad prioritization**:
```
0.1%  coldFunction     ← Optimizing this (❌ low impact)
45.3% hotFunction      ← Ignoring this (❌ missing real bottleneck)
```

**Solution**: **80/20 rule** - Focus on functions that account for most time.

**Good prioritization**:
```
45.3% hotFunction      ← Optimize this first (✅ high impact)
21.2% mediumFunction   ← Then this (✅ medium impact)
 0.1% coldFunction     ← Don't waste time here (✅ low priority)
```

### ❌ Ignoring Call Context

**Problem**: Optimizing function without understanding callers.

**Example**:
```
isPrime() shows 15% overhead
```

**Without context**: Optimize isPrime implementation.

**With context**:
```
main()
  └─ generatePrimes()
      └─ isPrime() (called 1,000,000 times)  ← Called too much!
```

**Better solution**: Reduce calls to isPrime (e.g., sieve algorithm) instead of optimizing isPrime itself.

### ❌ Not Comparing Before/After

**Problem**: Optimizing without baseline.

**Bad workflow**:
```
1. Make optimization
2. Hope it's faster
```

**Good workflow**:
```
1. Profile baseline
2. Make optimization
3. Profile again
4. Compare results
5. Validate with benchmarks
```

### ❌ Profiling at Wrong Optimization Level

**Problem**: Profiling ReleaseFast, optimizing, testing in Debug.

**Issue**: Different code paths, different bottlenecks.

**Solution**: Profile and test at the same optimization level you'll deploy.

## Best Practices

### 1. Profile Before Optimizing

**Don't guess** - measure:

❌ **Bad**:
```
"I think this function is slow, let me optimize it"
```

✅ **Good**:
```
1. Profile to identify actual bottlenecks
2. Confirm hotspot is worth optimizing
3. Optimize
4. Profile again to validate
```

**Why**: Programmer intuition about performance is often wrong. Profile to find real bottlenecks.

### 2. Keep Debug Symbols

**Always**:
```zig
exe.root_module.strip = false;  // ✅ Essential
```

**Benefits**:
- Meaningful profiler output
- Easier debugging
- Better crash reports
- No runtime cost

**Cost**:
- Slightly larger binary (~10-30% typically)
- Worth it for debuggability

### 3. Run Representative Workloads

**Bad**: Profiling with toy data
```zig
const test_size = 10;  // ❌ Not realistic
```

**Good**: Profiling with production-like data
```zig
const test_size = 10_000;  // ✅ Representative
```

**Considerations**:
- Use realistic data sizes
- Include typical use patterns
- Run long enough for patterns to emerge
- Consider different scenarios (best/worst/average case)

### 4. Use Multiple Profiling Tools

**Each tool shows different aspects**:

```bash
# CPU profiling
./scripts/profile_callgrind.sh  # Detailed, deterministic
./scripts/profile_perf.sh       # Fast, production-like

# Memory profiling
./scripts/profile_massif.sh     # Heap analysis

# Visualization
./scripts/generate_flamegraph.sh  # Big picture view
```

**Why**:
- Callgrind for detailed analysis
- Perf for production-like profiling
- Massif for memory issues
- Flame graphs for communication

### 5. Focus on Hot Paths (80/20 Rule)

**Pareto principle**: 80% of time spent in 20% of code.

**Prioritize**:
1. Functions with >10% overhead (critical)
2. Functions with 5-10% overhead (important)
3. Functions with 1-5% overhead (nice to have)
4. Functions with <1% overhead (ignore)

**Example**:
```
65%  fibonacci          ← OPTIMIZE THIS FIRST
18%  multiplyMatrices   ← THEN THIS
 8%  isPrime            ← THEN THIS
 5%  other functions    ← Maybe
 4%  tiny functions     ← Don't bother
```

### 6. Profile, Then Benchmark

**Workflow**:

1. **Profile** to find bottlenecks
```bash
./scripts/profile_perf.sh
# Identifies: fibonacci is 65% of time
```

2. **Optimize** the identified hotspot
```zig
// Add memoization to fibonacci
```

3. **Benchmark** to measure improvement
```zig
// Before: 1000ms
// After: 200ms
// Improvement: 5x faster ✅
```

4. **Profile again** to validate
```bash
./scripts/profile_perf.sh
# fibonacci now 15% of time ✅
```

**Why both**:
- Profiling finds WHERE to optimize
- Benchmarking measures IF optimization worked
- Together they guide optimization

### 7. Compare Before/After

**Always measure impact**:

```bash
# Baseline
zig build -Doptimize=ReleaseSafe
./scripts/profile_perf.sh
mv perf.data perf.data.old

# Make changes
# ...edit code...

# After optimization
zig build -Doptimize=ReleaseSafe
./scripts/profile_perf.sh
mv perf.data perf.data.new

# Compare
perf diff perf.data.old perf.data.new
```

**Document results**:
```
Optimization: Added memoization to fibonacci

Before:
  fibonacci: 65% of samples
  Total time: 5.2s

After:
  fibonacci: 8% of samples
  Total time: 1.1s

Improvement: 4.7x faster overall
```

### 8. Version Control Your Profiles

**Keep history**:
```bash
mkdir -p profiles/baseline
mkdir -p profiles/optimized

# Save baseline
cp callgrind.out profiles/baseline/
cp flamegraph.svg profiles/baseline/

# Save optimized
cp callgrind.out profiles/optimized/
cp flamegraph.svg profiles/optimized/
```

**Benefits**:
- Compare against baseline
- Track optimization progress
- Share with team
- Document in code review

### 9. Understand Your Allocator

**General Purpose Allocator** (GPA):
```zig
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
```
- Safe, tracks leaks
- Shows in profiler clearly
- Good for development

**Arena Allocator**:
```zig
var arena = std.heap.ArenaAllocator.init(backing);
```
- Bulk deallocation
- Profiler shows one allocation
- Good for request/response patterns

**Profiling implications**:
- Different allocators show different patterns
- Understand which allocator for meaningful interpretation
- Consider allocator overhead in measurements

### 10. Profile Incrementally

**Don't optimize everything at once**:

❌ **Bad**:
```
1. Change 10 things
2. Profile
3. Not sure what helped
```

✅ **Good**:
```
1. Profile baseline
2. Change ONE thing
3. Profile again
4. Compare
5. Keep if better, revert if worse
6. Repeat
```

**Benefits**:
- Know what works
- Build understanding
- Avoid regressions
- Document changes

## Interpreting Profiler Output

### Understanding Call Graphs

**Call graph structure**:
```
main()
  ├─ setupData()        (5% self, 10% inclusive)
  │   └─ allocate()     (5% self)
  ├─ processData()      (2% self, 60% inclusive)
  │   ├─ compute()      (40% self)
  │   └─ filter()       (18% self)
  └─ cleanup()          (3% self)
```

**Key concepts**:

**Self time**: Time in function itself
- `compute()`: 40% self = 40% of total time executing this function's code

**Inclusive time**: Time in function + all callees
- `processData()`: 60% inclusive = 60% of total time in this function and everything it calls

**Finding optimization targets**:
- **High self time** = optimize this function directly
- **High inclusive, low self** = optimize callees instead

**Example decision**:
```
processData():
  Self: 2%
  Inclusive: 60%

Decision: Don't optimize processData itself (only 2%).
          Optimize compute() (40% self) instead.
```

### Identifying Hotspots

**Hotspot characteristics**:

1. **High sample count**
```
fibonacci: 10,000 samples (40% of total)  ← HOTSPOT
```

2. **High instruction count** (Callgrind)
```
fibonacci: 4,245,123,456 Ir (42% of total)  ← HOTSPOT
```

3. **Called frequently**
```
isPrime: called 1,000,000 times  ← HOTSPOT
```

4. **High self cost**
```
multiplyMatrices: 35% self time  ← HOTSPOT
```

**Prioritization**:
- Hot functions (>20% overhead): Critical
- Warm functions (10-20%): Important
- Lukewarm (5-10%): Consider
- Cold (<5%): Usually ignore

### Self Time vs Inclusive Time

**Example**:
```
Function A:
  Self: 5%
  Inclusive: 80%

  Calls:
    Function B: 40% self
    Function C: 35% self
```

**Interpretation**:
- **A does little work itself** (5% self)
- **A's callees do most work** (75% in B+C)
- **Don't optimize A** - optimize B and C

**Another example**:
```
Function D:
  Self: 60%
  Inclusive: 60%

  Calls: nothing expensive
```

**Interpretation**:
- **D does all the work** (60% self)
- **Optimize D directly** - it's the bottleneck

### Cache Effects in Profiles

**Cache misses** (Callgrind with `--cache-sim=yes`):
```
Function          I1mr (L1 instruction)  D1mr (L1 data)
multiplyMatrices  1,234 (low)            1,234,567 (HIGH)
```

**Interpretation**:
- Low instruction cache misses (code fits in cache)
- **High data cache misses** (poor memory access pattern)

**Optimization opportunity**: Improve data locality
```zig
// Before: poor locality (column-major in row-major layout)
for (0..size) |j| {
    for (0..size) |i| {
        matrix[i][j] = ...;  // ❌ Cache unfriendly
    }
}

// After: better locality
for (0..size) |i| {
    for (0..size) |j| {
        matrix[i][j] = ...;  // ✅ Cache friendly
    }
}
```

### When to Optimize What

**Decision tree**:

```
Is function >5% overhead?
  ├─ No → Don't optimize (not worth it)
  └─ Yes → Continue

Is self time high?
  ├─ Yes → Optimize function implementation
  │   ├─ Reduce iterations
  │   ├─ Use better algorithm
  │   ├─ Cache results
  │   └─ Optimize hot inner loop
  └─ No → Is inclusive time high?
      ├─ Yes → Optimize callees
      │   ├─ Reduce calls
      │   ├─ Optimize callee functions
      │   └─ Consider inlining
      └─ No → Already optimized
```

**Example application**:
```
fibonacci:
  Self: 60%
  Inclusive: 60%
  Called: 10,000,000 times

Optimizations to consider:
  1. Reduce calls (memoization)      ← BEST
  2. Optimize implementation         ← Good
  3. Use iterative instead of recursive ← Consider
```

### False Positives and Artifacts

**Be aware of profiling artifacts**:

**1. Profiler overhead**:
```
With Callgrind:
  allocator: 20% overhead  ← May be inflated due to Callgrind overhead
```
- Callgrind slows allocations disproportionately
- Validate with perf (lower overhead)

**2. System noise**:
```
Run 1: fibonacci 45%
Run 2: fibonacci 43%
Run 3: fibonacci 46%
```
- Small variations normal
- Look for consistent patterns
- Run multiple times

**3. Startup overhead**:
```
Short run:
  startup: 30%    ← Dominates
  actual work: 70%

Long run:
  startup: 2%     ← Amortized
  actual work: 98% ← Representative
```
- Run long enough to amortize startup
- Profile steady-state behavior

**4. Compiler optimizations**:
```
Debug:
  functionA calls functionB calls functionC

ReleaseFast:
  functionA calls functionC (B inlined)
```
- Different optimization levels show different call graphs
- Profile at deployment optimization level

## Code Examples

### Example Hotspot Patterns

**Pattern 1: Recursive hotspot**
```zig
// Profiler shows:
// fibonacci: 60% of time, 10M calls

// Before optimization
pub fn fibonacci(n: u32) u64 {
    if (n <= 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);  // ❌ Exponential calls
}

// After optimization: Memoization
var memo = std.AutoHashMap(u32, u64).init(allocator);

pub fn fibonacci(n: u32) u64 {
    if (n <= 1) return n;

    if (memo.get(n)) |cached| {
        return cached;  // ✅ O(1) lookup
    }

    const result = fibonacci(n - 1) + fibonacci(n - 2);
    memo.put(n, result) catch unreachable;
    return result;
}

// Profiler after:
// fibonacci: 5% of time, 60 calls
// Improvement: 12x faster
```

**Pattern 2: Loop hotspot**
```zig
// Profiler shows:
// isPrime: 25% of time, high instruction count in loop

// Before optimization
fn isPrime(n: u32) bool {
    if (n < 2) return false;
    var i: u32 = 2;
    while (i < n) : (i += 1) {  // ❌ Checks all numbers
        if (n % i == 0) return false;
    }
    return true;
}

// After optimization: Better bound
fn isPrime(n: u32) bool {
    if (n < 2) return false;
    if (n == 2) return true;
    if (n % 2 == 0) return false;

    var i: u32 = 3;
    const limit = @as(u32, @intFromFloat(@sqrt(@as(f64, @floatFromInt(n)))));
    while (i <= limit) : (i += 2) {  // ✅ Only check to sqrt(n), skip evens
        if (n % i == 0) return false;
    }
    return true;
}

// Profiler after:
// isPrime: 3% of time
// Improvement: 8x faster
```

**Pattern 3: Allocation hotspot**
```zig
// Massif shows:
// Peak heap: 500 MB
// Allocation site: processItems (many small allocations)

// Before optimization
fn processItems(items: []Item) !void {
    for (items) |item| {
        const buffer = try allocator.alloc(u8, 1024);  // ❌ Allocate every iteration
        defer allocator.free(buffer);

        // Process with buffer
        processWithBuffer(item, buffer);
    }
}

// After optimization: Reuse buffer
fn processItems(items: []Item) !void {
    var buffer = try allocator.alloc(u8, 1024);  // ✅ Allocate once
    defer allocator.free(buffer);

    for (items) |item| {
        // Reuse same buffer
        processWithBuffer(item, buffer);
    }
}

// Massif after:
// Peak heap: 1 MB
// Improvement: 500x less allocation
```

### Before/After Optimization Comparisons

**Case Study: Matrix Multiplication**

**Before**:
```zig
// Naive implementation
pub fn multiplyMatrices(a: [][]f64, b: [][]f64, size: usize) ![][]f64 {
    var result = try allocateMatrix(size);

    for (0..size) |i| {
        for (0..size) |j| {
            var sum: f64 = 0.0;
            for (0..size) |k| {
                sum += a[i][k] * b[k][j];  // ❌ Poor cache locality on b
            }
            result[i][j] = sum;
        }
    }

    return result;
}
```

**Profiler results (Callgrind)**:
```
multiplyMatrices: 4,500,000,000 Ir (45% of time)
Cache misses: 5,000,000 D1mr (high)
```

**After** (blocked/tiled multiplication):
```zig
// Cache-friendly blocked implementation
pub fn multiplyMatrices(a: [][]f64, b: [][]f64, size: usize) ![][]f64 {
    var result = try allocateMatrix(size);
    @memset(result, 0);

    const block_size = 64;  // Tune to L1 cache size

    var ii: usize = 0;
    while (ii < size) : (ii += block_size) {
        var jj: usize = 0;
        while (jj < size) : (jj += block_size) {
            var kk: usize = 0;
            while (kk < size) : (kk += block_size) {
                // Process block
                const i_end = @min(ii + block_size, size);
                const j_end = @min(jj + block_size, size);
                const k_end = @min(kk + block_size, size);

                for (ii..i_end) |i| {
                    for (kk..k_end) |k| {
                        const a_ik = a[i][k];
                        for (jj..j_end) |j| {
                            result[i][j] += a_ik * b[k][j];  // ✅ Better locality
                        }
                    }
                }
            }
        }
    }

    return result;
}
```

**Profiler results (Callgrind)**:
```
multiplyMatrices: 2,100,000,000 Ir (21% of time)
Cache misses: 500,000 D1mr (10x improvement)
```

**Improvement**: 2.1x faster overall, 10x fewer cache misses

### Reading Profiler Output Examples

**Callgrind annotated output**:
```
--------------------------------------------------------------------------------
Ir                      file:function
--------------------------------------------------------------------------------
4,245,123,456 (42.3%)   src/compute.zig:fibonacci
  2,834,082,304 (66.8%)  src/compute.zig:fibonacci [recursive]
  1,411,041,152 (33.2%)  src/main.zig:main

2,123,456,789 (21.2%)   src/compute.zig:multiplyMatrices
  2,123,456,789 (100%)   src/main.zig:main

987,654,321 (9.8%)      src/compute.zig:isPrime
  987,654,321 (100%)     src/compute.zig:generatePrimes

654,321,098 (6.5%)      src/memory.zig:allocateManySmall
  654,321,098 (100%)     src/main.zig:main
```

**Interpretation**:
1. **fibonacci** (42.3%): Biggest hotspot
   - 66.8% from recursive calls (exponential overhead)
   - 33.2% from main (initial calls)
   - **Action**: Add memoization

2. **multiplyMatrices** (21.2%): Second priority
   - All called from main
   - **Action**: Optimize algorithm or cache access

3. **isPrime** (9.8%): Third priority
   - Called from generatePrimes
   - **Action**: Better algorithm or call less often

4. **allocateManySmall** (6.5%): Consider optimizing
   - **Action**: Reduce allocation frequency

**Perf report output**:
```
# Overhead  Command          Symbol
# ........  ...............  .................................
#
    42.53%  profiling_demo   [.] compute.fibonacci
            |
            |--66.82%--compute.fibonacci
            |          |
            |          |--44.55%--compute.fibonacci
            |          |          |
            |          |          |--29.70%--compute.fibonacci
            |          |          |
            |          |          --14.85%--compute.fibonacci
            |          |
            |          --22.27%--compute.fibonacci
            |
            --33.18%--main

    21.34%  profiling_demo   [.] compute.multiplyMatrices
            |
            ---100.00%--main
```

**Interpretation**: Same pattern as Callgrind but with call chain visualization showing recursive depth.

## Running Instructions

### Setup

**1. Clone or navigate to example**:
```bash
cd /path/to/zig_guide/sections/12_testing_benchmarking/examples/06_profiling
```

**2. Make scripts executable**:
```bash
chmod +x scripts/*.sh
```

**3. Build**:
```bash
zig build -Doptimize=ReleaseSafe
```

**4. Run tests** (optional):
```bash
zig build test
```

### Profiling Workflows

**Workflow 1: Quick CPU profiling**
```bash
./scripts/profile_perf.sh
perf report
```

**Workflow 2: Detailed CPU profiling**
```bash
./scripts/profile_callgrind.sh
kcachegrind callgrind.out  # or callgrind_annotate callgrind.out
```

**Workflow 3: Memory profiling**
```bash
./scripts/profile_massif.sh
ms_print massif.out
```

**Workflow 4: Visual analysis**
```bash
./scripts/profile_perf.sh
./scripts/generate_flamegraph.sh
xdg-open flamegraph.svg
```

### Expected Output Examples

**Program output**:
```
=== Profiling Demo: CPU & Memory Intensive Operations ===

1. Computing Fibonacci...
   fib(30) = 832040
   fib(30) = 832040
   ...

2. Generating prime numbers...
   Generated 1229 primes
   Generated 1229 primes
   ...

3. Matrix multiplication...
   Iteration 1: 200x200 matrix multiplication complete
   ...

=== Profiling Demo Complete ===
```

**Callgrind output** (excerpt):
```
==12345== Callgrind, a call-graph generating cache profiler
==12345== Command: ./zig-out/bin/profiling_demo
==12345==
--12345-- warning: L3 cache found, using its data for the LL simulation.

[Program runs]

==12345==
==12345== I refs:        10,034,567,890
==12345== I1 misses:         1,234,567
==12345== LLi misses:           12,345
==12345== I1 miss rate:           0.01%
==12345== LLi miss rate:          0.00%
==12345==
==12345== D refs:         4,012,345,678
==12345== D1 misses:        123,456,789
==12345== LLd misses:         1,234,567
==12345== D1 miss rate:            3.1%
==12345== LLd miss rate:           0.03%
```

**Perf report** (excerpt):
```
# Samples: 10K of event 'cycles'
# Event count (approx.): 8455432103
#
# Overhead  Command          Shared Object       Symbol
# ........  ...............  ..................  ..........................
#
    42.53%  profiling_demo   profiling_demo      [.] compute.fibonacci
    21.34%  profiling_demo   profiling_demo      [.] compute.multiplyMatrices
    12.45%  profiling_demo   profiling_demo      [.] compute.isPrime
```

### Troubleshooting Common Issues

**Issue 1: Perf permission denied**
```
Error: perf_event_open(...) failed: Permission denied
```

**Solution**:
```bash
sudo sysctl kernel.perf_event_paranoid=1
# or
sudo ./scripts/profile_perf.sh
```

**Issue 2: FlameGraph not found**
```
Error: stackcollapse-perf.pl: command not found
```

**Solution**:
```bash
git clone https://github.com/brendangregg/FlameGraph
export PATH=$PATH:$(pwd)/FlameGraph
./scripts/generate_flamegraph.sh
```

**Issue 3: No debug symbols in profiler**
```
??? [0x401234]
??? [0x401567]
```

**Solution**: Rebuild with debug symbols:
```bash
# Check build.zig has:
# exe.root_module.strip = false;

zig build -Doptimize=ReleaseSafe
```

**Issue 4: Program too fast to profile**
```
Perf: Not enough samples collected
```

**Solution**: Increase workload size in `src/main.zig`:
```zig
const workload_size = 35;  // Increase from 30
```

**Issue 5: Valgrind errors on macOS**
```
valgrind: command not found (or crashes)
```

**Solution**: Use platform-specific tools:
- **macOS**: Instruments (Xcode)
- **Windows**: Visual Studio Profiler
- **Linux**: Valgrind (works well)

## Tool Installation

### Valgrind (Callgrind & Massif)

**Ubuntu/Debian**:
```bash
sudo apt-get update
sudo apt-get install valgrind kcachegrind
```

**Fedora**:
```bash
sudo dnf install valgrind kcachegrind
```

**Arch Linux**:
```bash
sudo pacman -S valgrind kcachegrind
```

**macOS**:
```bash
# Valgrind support on macOS is limited/experimental
# Consider using Instruments instead
brew install valgrind  # May not work on newer macOS versions
```

### Perf

**Ubuntu/Debian**:
```bash
sudo apt-get install linux-tools-common linux-tools-generic linux-tools-$(uname -r)
```

**Fedora**:
```bash
sudo dnf install perf
```

**Arch Linux**:
```bash
sudo pacman -S perf
```

**macOS/Windows**: Not available (platform-specific)

### FlameGraph

**All platforms**:
```bash
git clone https://github.com/brendangregg/FlameGraph
cd FlameGraph

# Option 1: Add to PATH
export PATH=$PATH:$(pwd)

# Option 2: Install system-wide
sudo cp *.pl /usr/local/bin/
```

### GUI Viewers

**KCachegrind** (Callgrind viewer):
```bash
# Ubuntu/Debian
sudo apt-get install kcachegrind

# Fedora
sudo dnf install kcachegrind

# Arch
sudo pacman -S kcachegrind

# macOS
brew install qcachegrind  # Qt version
```

**Massif Visualizer**:
```bash
# Ubuntu/Debian
sudo apt-get install massif-visualizer

# Fedora
sudo dnf install massif-visualizer

# Arch
sudo pacman -S massif-visualizer

# macOS
brew install massif-visualizer
```

## Compatibility Notes

### Linux-Specific Tools

**Perf**: Only available on Linux
- Uses kernel performance counters
- Deep kernel integration
- No equivalent on other platforms

**Valgrind**: Best support on Linux
- Works well on Linux x86/x86_64
- Limited macOS support (older versions only)
- Not available on Windows

### macOS Alternatives

**Instead of Callgrind/Perf**:
- **Instruments** (Xcode)
  - Time Profiler (CPU)
  - Allocations (memory)
  - Leaks (memory leaks)
  - Built-in, GUI-based
  - Excellent visualization

**Using Instruments**:
```bash
# Profile CPU
instruments -t "Time Profiler" ./zig-out/bin/profiling_demo

# Profile memory
instruments -t "Allocations" ./zig-out/bin/profiling_demo
```

**Flame graphs on macOS**:
```bash
# Use DTrace instead of perf
sudo dtrace -x ustackframes=100 -n 'profile-997 /pid == $target/ { @[ustack()] = count(); } tick-60s { exit(0); }' -o out.stacks -c ./program

# Convert to flame graph
stackcollapse.pl out.stacks | flamegraph.pl > flamegraph.svg
```

### Windows Alternatives

**Instead of Callgrind/Perf**:
- **Visual Studio Profiler**
  - CPU Usage
  - Memory Usage
  - Performance Profiler
  - Integrated with VS

**Using VS Profiler**:
1. Open project in Visual Studio
2. Debug → Performance Profiler
3. Select profiling tools
4. Start profiling

**Windows Performance Recorder** (WPR):
- System-wide profiling
- ETW (Event Tracing for Windows)
- Analyzed with Windows Performance Analyzer (WPA)

### Cross-Platform Tools

**Tracy Profiler**:
- Works on Windows, Linux, macOS
- Requires code instrumentation
- Real-time visualization
- Great for games and interactive apps

**Setup**:
```zig
// Add Tracy to project
const tracy = @import("tracy");

pub fn hotFunction() void {
    const zone = tracy.ZoneN(@src(), "HotFunction");
    defer zone.End();

    // Your code here
}
```

**Run**:
```bash
# Run program with Tracy client
./program

# Open Tracy server GUI to view
./Tracy
```

## Summary

This example demonstrates comprehensive profiling integration:

**Tools covered**:
1. **Callgrind** - Deterministic CPU profiling
2. **Perf** - Sampling-based profiling
3. **Massif** - Heap memory profiling
4. **Flame graphs** - Visual profiling representation

**Key takeaways**:
- Always keep debug symbols for profiling
- Profile in ReleaseSafe mode for balance
- Use multiple tools for complete picture
- Focus on hot paths (80/20 rule)
- Compare before/after optimizations
- Validate with benchmarks

**Workflow summary**:
```
1. Build with debug symbols (strip = false)
2. Profile with appropriate tool
3. Identify bottlenecks
4. Optimize hot paths
5. Profile again to validate
6. Benchmark to measure improvement
7. Repeat until performance goals met
```

**When to use which tool**:
- **Callgrind**: Detailed analysis, exact measurements
- **Perf**: Production profiling, low overhead
- **Massif**: Memory issues, allocation patterns
- **Flame graphs**: Communication, big picture

## Next Steps

After mastering profiling:

1. **Practice with real projects**
   - Profile your own code
   - Find real bottlenecks
   - Measure improvements

2. **Learn advanced techniques**
   - Differential profiling
   - Hardware counter analysis
   - Cache optimization
   - Branch prediction optimization

3. **Integrate into workflow**
   - Profile before optimizing
   - Track performance over time
   - Use in code reviews
   - Document optimizations

4. **Explore platform-specific tools**
   - Instruments (macOS)
   - Visual Studio Profiler (Windows)
   - Advanced perf features (Linux)

5. **Study optimization patterns**
   - Algorithm improvements
   - Data structure choices
   - Cache-friendly code
   - Allocation reduction

## References

**Documentation**:
- [Valgrind Manual](https://valgrind.org/docs/manual/manual.html)
- [Linux perf Wiki](https://perf.wiki.kernel.org/)
- [Brendan Gregg's Blog](https://www.brendangregg.com/flamegraphs.html)
- [Tracy Profiler](https://github.com/wolfpld/tracy)

**Further Reading**:
- "Systems Performance" by Brendan Gregg
- "Computer Architecture: A Quantitative Approach" by Hennessy & Patterson
- Zig documentation on optimization modes

Happy profiling! 🔍
