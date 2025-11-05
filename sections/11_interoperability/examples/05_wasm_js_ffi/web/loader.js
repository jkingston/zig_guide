// Global WASM instance
let wasmInstance = null;
let wasmMemory = null;

// Helper function to convert JavaScript string to WASM memory
function stringToWasm(str) {
    const encoder = new TextEncoder();
    const bytes = encoder.encode(str);
    return { ptr: bytes, len: bytes.length };
}

// Helper function to read string from WASM memory
function readWasmString(ptr, len) {
    const bytes = new Uint8Array(wasmMemory.buffer, ptr, len);
    const decoder = new TextDecoder();
    return decoder.decode(bytes);
}

// Output logging function
function log(message) {
    const output = document.getElementById('output');
    output.textContent += message + '\n';
    console.log(message);
}

function clearOutput() {
    document.getElementById('output').textContent = '';
}

// Host functions that WASM can call
const importObject = {
    env: {
        consoleLog: (ptr, len) => {
            const str = readWasmString(ptr, len);
            log(str);
        },
        alertMessage: (ptr, len) => {
            const str = readWasmString(ptr, len);
            alert(str);
        }
    }
};

// Test functions
function testArithmetic() {
    clearOutput();
    const result = wasmInstance.exports.add(5, 7);
    log(`add(5, 7) = ${result}`);
}

function testMultiply() {
    clearOutput();
    const result = wasmInstance.exports.multiply(6, 8);
    log(`multiply(6, 8) = ${result}`);
}

function testFibonacci() {
    clearOutput();
    const n = parseInt(document.getElementById('fibInput').value);
    const result = wasmInstance.exports.fibonacci(n);
    log(`fibonacci(${n}) = ${result}`);
}

function testGreet() {
    clearOutput();
    const name = document.getElementById('nameInput').value;
    const { ptr, len } = stringToWasm(name);

    // Allocate memory in WASM
    const wasmPtr = new Uint8Array(wasmMemory.buffer, 0, ptr.length);
    wasmPtr.set(ptr);

    wasmInstance.exports.greet(0, len);
}

function testVowelCount() {
    clearOutput();
    const text = document.getElementById('vowelInput').value;
    const { ptr, len } = stringToWasm(text);

    // Allocate memory in WASM
    const wasmPtr = new Uint8Array(wasmMemory.buffer, 0, ptr.length);
    wasmPtr.set(ptr);

    const count = wasmInstance.exports.processString(0, len);
    log(`Text: "${text}"`);
    log(`Vowel count: ${count}`);
}

function testMemoryAllocation() {
    clearOutput();
    const count = 10;

    log(`Allocating array of ${count} integers in WASM...`);
    const ptr = wasmInstance.exports.allocateAndSum(count);

    // Read the sum from first position
    const view = new Int32Array(wasmMemory.buffer, ptr, count);
    const sum = view[0];

    log(`Sum of 1..${count} = ${sum}`);
    log(`Expected: ${(count * (count + 1)) / 2}`);

    // Free the memory
    wasmInstance.exports.freeMemory(ptr, count);
    log('Memory freed');
}

function testCallback() {
    clearOutput();
    log('Calling WASM function that calls back to JavaScript:');
    wasmInstance.exports.demonstrateCallback(42);
}

function testMemoryInfo() {
    clearOutput();
    const pages = wasmInstance.exports.getMemoryInfo();
    const kb = pages * 64;
    log(`WASM Memory: ${pages} pages (${kb} KB)`);
}

// Load and instantiate WASM module
async function loadWasm() {
    try {
        // Load the WASM file
        const response = await fetch('../zig-out/bin/wasm_js_ffi.wasm');
        const wasmBytes = await response.arrayBuffer();

        // Instantiate with imports
        const result = await WebAssembly.instantiate(wasmBytes, importObject);

        wasmInstance = result.instance;
        wasmMemory = wasmInstance.exports.memory;

        log('WASM module loaded successfully!');
        log('Try the buttons above to test different features.\n');

    } catch (error) {
        log('Error loading WASM: ' + error.message);
        log('Make sure you built the WASM file with: zig build');
    }
}

// Load WASM when page loads
window.addEventListener('load', loadWasm);
