# Clang WebAssembly Toolchain

This is a simple toolchain for building WebAssembly code from C.

Install the dependencies

    apt-get install build-essential cmake

Build the toolchain:

    make clone
    make checkout
    make patch
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

## What's missing

* fork()
  * Needs support in the wasm VM (need to clone the shadow stack)
* threads
  * A partial implementation is likely possible without VM support using SharedArrayBuffer
  * Thread Local Storage will be impossible without VM support
* dynamic linking
  * Possibly can be implemented without VM support, see [This Experiment](https://github.com/jfbastien/musl).
* libc++

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

