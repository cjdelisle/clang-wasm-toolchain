# Clang WebAssembly Toolchain

Status: out of date, unmaintained, wasm ecosystem moves *fast*, check out [wasi](https://wasi.dev/)

This is a simple toolchain for building WebAssembly code from C.

# WARNING: This is EXPERIMENTAL, you can't use it to build complex software, see "what's missing/broken"

Install the dependencies

    apt-get install build-essential cmake

Build the toolchain:

    make -j8

Have a cup of coffee, building a compiler just cannot be quick.

Use it:

    ./build/bin/wasm32-unknown-unknown-wasm-clang ./hello.c

## What it contains

* LLVM, clang & clang++
* lld linker
* musl libc for WebAssembly
* compiler-rt
* compiler-wrappers

## What's missing/broken

* **missing args** due to a bug in the linker, main(argc, argv) called as main(argc, argv, env) will
replace argc w/ argv and argv w/ env. see: https://bugs.llvm.org/show_bug.cgi?id=36145
* **argc/argv not implemented** mostly due to frustration because of the missing args bug
* **longjmp** is not supported passing -mllvm -enable-emscripten-sjlj makes it work but creates symbols
(invoke_*) that cannot be predicted in advance so they cannot be added to wasm.syms and thus the linker
finds them unresolved. see: https://bugs.llvm.org/show_bug.cgi?id=36147
* **Position Independent Executable** wasm expects to be loaded with base 0 which means any syscalls
will have pointers that the kernel will not recognize, therefore without PIE or LTL wasm it will be
impossible to make complex syscalls which pass unpredictable structures to the kernel (like ioctl).
* **fork()**
  * Needs support in the wasm VM (need to clone the shadow stack)
* **threads**
  * A partial implementation is likely possible without VM support using SharedArrayBuffer
  * Thread Local Storage will be impossible without VM support
* **dynamic linking**
  * Possibly can be implemented without VM support, see [This Experiment](https://github.com/jfbastien/musl).
* **libc++**
  * Apparently this is just not completed but nothing specific is blocking it

The code which is emitted by this toolchain will require functions 

    (import "env" (func $__syscall (param i32 i32) (result i32)))
    (import "env" (func $__syscall0 (param i32) (result i32)))
    (import "env" (func $__syscall1 (param i32 i32) (result i32)))
    (import "env" (func $__syscall2 (param i32 i32 i32) (result i32)))
    (import "env" (func $__syscall3 (param i32 i32 i32 i32) (result i32)))
    (import "env" (func $__syscall4 (param i32 i32 i32 i32 i32) (result i32)))
    (import "env" (func $__syscall5 (param i32 i32 i32 i32 i32 i32) (result i32)))
    (import "env" (func $__syscall6 (param i32 i32 i32 i32 i32 i32 i32) (result i32)))
    (import "env" (func $__syscall_cp (param i32 i32 i32 i32 i32 i32 i32) (result i32))) Cancelable syscalls which are not implemented

