const std = @import("std");

// ============================================================================
// Sorting Algorithms for Benchmarking
// ============================================================================

/// Bubble Sort: O(n²) - Intentionally slow baseline
/// This is a simple but inefficient sorting algorithm
/// Good for demonstrating performance differences
pub fn bubbleSort(data: []i32) void {
    if (data.len <= 1) return;

    var i: usize = 0;
    while (i < data.len - 1) : (i += 1) {
        var j: usize = 0;
        while (j < data.len - 1 - i) : (j += 1) {
            if (data[j] > data[j + 1]) {
                const temp = data[j];
                data[j] = data[j + 1];
                data[j + 1] = temp;
            }
        }
    }
}

/// Insertion Sort: O(n²) worst case, O(n) best case
/// More efficient than bubble sort for small arrays
/// Performs well on partially sorted data
pub fn insertionSort(data: []i32) void {
    if (data.len <= 1) return;

    var i: usize = 1;
    while (i < data.len) : (i += 1) {
        const key = data[i];
        var j: usize = i;

        while (j > 0 and data[j - 1] > key) : (j -= 1) {
            data[j] = data[j - 1];
        }

        data[j] = key;
    }
}

/// Insertion Sort with binary search for insertion point
/// Slightly optimized version that uses binary search
pub fn insertionSortBinary(data: []i32) void {
    if (data.len <= 1) return;

    var i: usize = 1;
    while (i < data.len) : (i += 1) {
        const key = data[i];

        // Binary search for insertion point
        var left: usize = 0;
        var right: usize = i;

        while (left < right) {
            const mid = left + (right - left) / 2;
            if (data[mid] > key) {
                right = mid;
            } else {
                left = mid + 1;
            }
        }

        // Shift elements and insert
        var j: usize = i;
        while (j > left) : (j -= 1) {
            data[j] = data[j - 1];
        }
        data[left] = key;
    }
}

/// Quick Sort: O(n log n) average, O(n²) worst case
/// Generally the fastest general-purpose sorting algorithm
/// Uses median-of-three pivot selection to avoid worst case
pub fn quickSort(data: []i32) void {
    if (data.len <= 1) return;
    quickSortImpl(data, 0, data.len - 1);
}

fn quickSortImpl(data: []i32, low: usize, high: usize) void {
    if (low >= high) return;

    // Use insertion sort for small subarrays (optimization)
    if (high - low < 10) {
        insertionSortRange(data, low, high + 1);
        return;
    }

    const pivot_idx = partition(data, low, high);

    if (pivot_idx > 0) {
        quickSortImpl(data, low, pivot_idx - 1);
    }
    if (pivot_idx < high) {
        quickSortImpl(data, pivot_idx + 1, high);
    }
}

fn partition(data: []i32, low: usize, high: usize) usize {
    // Median-of-three pivot selection
    const mid = low + (high - low) / 2;

    // Sort low, mid, high
    if (data[mid] < data[low]) swap(data, low, mid);
    if (data[high] < data[low]) swap(data, low, high);
    if (data[high] < data[mid]) swap(data, mid, high);

    // Use middle value as pivot
    const pivot = data[mid];
    swap(data, mid, high - 1);

    var i: usize = low;
    var j: usize = high - 1;

    while (true) {
        i += 1;
        while (data[i] < pivot) : (i += 1) {}

        j -= 1;
        while (data[j] > pivot) : (j -= 1) {}

        if (i >= j) break;

        swap(data, i, j);
    }

    swap(data, i, high - 1);
    return i;
}

fn swap(data: []i32, i: usize, j: usize) void {
    const temp = data[i];
    data[i] = data[j];
    data[j] = temp;
}

fn insertionSortRange(data: []i32, start: usize, end: usize) void {
    var i: usize = start + 1;
    while (i < end) : (i += 1) {
        const key = data[i];
        var j: usize = i;

        while (j > start and data[j - 1] > key) : (j -= 1) {
            data[j] = data[j - 1];
        }

        data[j] = key;
    }
}

/// Merge Sort: O(n log n) worst case, guaranteed
/// More consistent than quicksort, but requires extra memory
/// Good for linked lists and external sorting
pub fn mergeSort(allocator: std.mem.Allocator, data: []i32) !void {
    if (data.len <= 1) return;

    const temp = try allocator.alloc(i32, data.len);
    defer allocator.free(temp);

    mergeSortImpl(data, temp, 0, data.len - 1);
}

fn mergeSortImpl(data: []i32, temp: []i32, left: usize, right: usize) void {
    if (left >= right) return;

    const mid = left + (right - left) / 2;

    mergeSortImpl(data, temp, left, mid);
    mergeSortImpl(data, temp, mid + 1, right);

    merge(data, temp, left, mid, right);
}

fn merge(data: []i32, temp: []i32, left: usize, mid: usize, right: usize) void {
    // Copy to temp
    var i: usize = left;
    while (i <= right) : (i += 1) {
        temp[i] = data[i];
    }

    var left_idx = left;
    var right_idx = mid + 1;
    var current = left;

    // Merge back to data
    while (left_idx <= mid and right_idx <= right) {
        if (temp[left_idx] <= temp[right_idx]) {
            data[current] = temp[left_idx];
            left_idx += 1;
        } else {
            data[current] = temp[right_idx];
            right_idx += 1;
        }
        current += 1;
    }

    // Copy remaining left elements
    while (left_idx <= mid) : (left_idx += 1) {
        data[current] = temp[left_idx];
        current += 1;
    }

    // Right elements are already in place
}

/// Heap Sort: O(n log n) worst case, in-place
/// Good when consistent O(n log n) is needed without extra memory
pub fn heapSort(data: []i32) void {
    if (data.len <= 1) return;

    // Build max heap
    var i: usize = data.len / 2;
    while (i > 0) : (i -= 1) {
        heapify(data, i - 1, data.len);
    }

    // Extract elements from heap
    i = data.len;
    while (i > 1) : (i -= 1) {
        swap(data, 0, i - 1);
        heapify(data, 0, i - 1);
    }
}

fn heapify(data: []i32, root: usize, size: usize) void {
    var largest = root;
    const left = 2 * root + 1;
    const right = 2 * root + 2;

    if (left < size and data[left] > data[largest]) {
        largest = left;
    }

    if (right < size and data[right] > data[largest]) {
        largest = right;
    }

    if (largest != root) {
        swap(data, root, largest);
        heapify(data, largest, size);
    }
}

// ============================================================================
// Test Data Generation
// ============================================================================

/// Generate random data for benchmarking
pub fn generateRandomData(allocator: std.mem.Allocator, size: usize, seed: u64) ![]i32 {
    const data = try allocator.alloc(i32, size);
    var prng = std.Random.DefaultPrng.init(seed);
    const random = prng.random();

    for (data) |*value| {
        value.* = random.int(i32);
    }

    return data;
}

/// Generate sorted data for benchmarking
pub fn generateSortedData(allocator: std.mem.Allocator, size: usize) ![]i32 {
    const data = try allocator.alloc(i32, size);

    for (data, 0..) |*value, i| {
        value.* = @intCast(i);
    }

    return data;
}

/// Generate reverse-sorted data for benchmarking
pub fn generateReverseSortedData(allocator: std.mem.Allocator, size: usize) ![]i32 {
    const data = try allocator.alloc(i32, size);

    for (data, 0..) |*value, i| {
        value.* = @intCast(size - i - 1);
    }

    return data;
}

/// Generate partially sorted data (90% sorted)
pub fn generatePartiallySortedData(allocator: std.mem.Allocator, size: usize, seed: u64) ![]i32 {
    const data = try allocator.alloc(i32, size);
    var prng = std.Random.DefaultPrng.init(seed);
    const random = prng.random();

    // Start with sorted data
    for (data, 0..) |*value, i| {
        value.* = @intCast(i);
    }

    // Shuffle 10% of elements
    const shuffle_count = size / 10;
    var i: usize = 0;
    while (i < shuffle_count) : (i += 1) {
        const idx1 = random.uintLessThan(usize, size);
        const idx2 = random.uintLessThan(usize, size);
        swap(data, idx1, idx2);
    }

    return data;
}

// ============================================================================
// Benchmark Helpers
// ============================================================================

/// Create a copy of data for each sort (so we don't sort already sorted data)
pub fn benchmarkSort(
    allocator: std.mem.Allocator,
    comptime sortFn: fn ([]i32) void,
    original_data: []const i32,
) !u64 {
    // Copy data
    const data = try allocator.alloc(i32, original_data.len);
    defer allocator.free(data);
    @memcpy(data, original_data);

    // Time the sort
    var timer = try std.time.Timer.start();
    sortFn(data);
    const elapsed = timer.read();

    // Prevent optimization
    std.mem.doNotOptimizeAway(&data);

    return elapsed;
}

/// Benchmark merge sort (requires allocator)
pub fn benchmarkMergeSort(
    allocator: std.mem.Allocator,
    original_data: []const i32,
) !u64 {
    const data = try allocator.alloc(i32, original_data.len);
    defer allocator.free(data);
    @memcpy(data, original_data);

    var timer = try std.time.Timer.start();
    try mergeSort(allocator, data);
    const elapsed = timer.read();

    std.mem.doNotOptimizeAway(&data);

    return elapsed;
}

/// Verify that data is sorted
pub fn isSorted(data: []const i32) bool {
    if (data.len <= 1) return true;

    var i: usize = 1;
    while (i < data.len) : (i += 1) {
        if (data[i] < data[i - 1]) {
            return false;
        }
    }

    return true;
}
