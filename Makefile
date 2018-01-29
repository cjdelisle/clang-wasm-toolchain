UNAME_S := $(shell uname -s)
MAKE_PID := $(shell echo $$PPID)
JOB_FLAG := $(filter -j%, $(subst -j ,-j,$(shell ps T | grep "^\s*$(MAKE_PID).*$(MAKE)")))

PWD := $(shell pwd)

GLOBAL_ARGS+="-DCMAKE_BUILD_TYPE=Debug"

LLVM_ARGS+="-DLLVM_INSTALL_UTILS=ON"
LLVM_ARGS+="-DLLVM_ENABLE_FFI=ON"
LLVM_ARGS+="-DLLVM_ENABLE_RTTI=ON"
LLVM_ARGS+="-DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=WebAssembly"
LLVM_ARGS+="-DLLVM_TARGETS_TO_BUILD=WebAssembly"
LLVM_ARGS+="-DLLVM_LINK_LLVM_DYLIB=ON"
ifeq ($(UNAME_S),Darwin)
	LLVM_ARGS+="-DLLVM_ENABLE_LIBCXX=ON"
	LLVM_ARGS+="-DCAN_TARGET_i386=false"
endif

CLANG_ARGS+="-DLLVM_CONFIG=../../build/llvm/bin/llvm-config"
CLANG_ARGS+="-DLLVM_TABLEGEN_EXE=../../build/llvm/bin/llvm-tblgen"

LLD_ARGS+="-DLLVM_CONFIG_PATH=../../build/llvm/bin/llvm-config"

MUSL_ARGS+="--disable-shared"
MUSL_ARGS+="--prefix=$(PWD)/build/musl"
MUSL_CFLAGS+="-Wno-shift-op-parentheses"
MUSL_CFLAGS+="-Wno-string-plus-int"
MUSL_CFLAGS+="-Wno-pointer-sign" # suppresses a werror failure
MUSL_CFLAGS+="-Wno-ignored-attributes"
MUSL_CFLAGS+="-Wno-bitwise-op-parentheses"
MUSL_CFLAGS+="-Wno-logical-op-parentheses"
MUSL_CFLAGS+="-Wno-dangling-else"
MUSL_CFLAGS+="-Wno-unknown-pragmas"
MUSL_CFLAGS+="-Wno-parentheses"


COMPILERRT_ARGS+=-DLLVM_CONFIG_PATH=../../build/llvm/bin/llvm-config
COMPILERRT_ARGS+=-DCMAKE_SYSTEM_NAME=Generic
COMPILERRT_ARGS+=-DCOMPILER_RT_DEFAULT_TARGET_TRIPLE=wasm32-unknown-unknown-wasm
COMPILERRT_ARGS+=--target ../lib/builtins
COMPILERRT_ARGS+=-DCOMPILER_RT_BAREMETAL_BUILD=TRUE
COMPILERRT_ARGS+=-DCOMPILER_RT_EXCLUDE_ATOMIC_BUILTIN=TRUE
COMPILERRT_ARGS+=-DCAN_TARGET_wasm32=ON


GIT_PFX=https://github.com/llvm-mirror/
PROJECTS=clang libcxxabi llvm libcxx lldb clang-tools-extra libunwind compiler-rt lld

all: compiler-rt
	echo "\n\n\nSet your PATH to include $(PWD)/build/bin/ and use wasm32-unknown-unknown-wasm-clang\n"

projects/musl/README:
	mkdir -p projects
	(cd projects && \
		$(foreach proj,$(PROJECTS),git clone $(GIT_PFX)$(proj);) \
		git clone https://github.com/jfbastien/musl \
	);
clone: projects/musl/README

update:
	truncate -s 0 ./versions.txt
	ls ./projects/ | while read x; do (\
	  echo "project $$x" && \
      cd projects/$$x && \
	  git checkout `[ "$$x" = "musl" ] && echo wasm-prototype-1 || echo master` && \
	  git pull && \
	  echo "$$x `git log -1 | grep '^commit' | cut -d ' ' -f 2`" >> ../../versions.txt \
	) done

checkout:
	awk '{print "( cd projects/"$$1" && git reset --hard && git clean -dxf && git checkout "$$2" )" }' ./versions.txt | bash

patch:
	ls ./projects/ | while read x; do (\
	  echo "project $$x" && \
      cd projects/$$x && \
	  git reset --hard && \
	  git clean -dxf && \
	  ls $(PWD)/patches/$$x-* 2>/dev/null | while read y; do \
	  	echo "applying $$y" && \
	  	git apply < $$y ; \
	  done \
	) done

clean:
	$(RM) ./build -rf

build/lld/bin/lld: build/llvm/bin/opt
	mkdir -p build/lld;
	(cd ./build/lld/ && \
		cmake $(GLOBAL_ARGS) $(LLD_ARGS) ../../projects/lld && \
		make $(JOB_FLAG) \
	);
lld: build/lld/bin/lld

build/llvm/bin/opt:
	mkdir -p build/llvm-build
	(cd ./build/llvm-build/ && \
		cmake $(GLOBAL_ARGS) $(LLVM_ARGS) --build ../../projects/llvm && \
		make $(JOB_FLAG) && \
		cmake -DCMAKE_INSTALL_PREFIX=$(PWD)/build/llvm -P cmake_install.cmake \
	);
	rm -rf $(PWD)/build/llvm-build/
	
llvm: build/llvm/bin/opt

build/clang/bin/clang: build/llvm/bin/opt
	mkdir -p build/clang-build;
	(cd ./build/clang-build/ && \
		cmake $(GLOBAL_ARGS) $(CLANG_ARGS) ../../projects/clang && \
		make $(JOB_FLAG) && \
		cmake -DCMAKE_INSTALL_PREFIX=$(PWD)/build/clang -P cmake_install.cmake \
	);
	rm -rf $(PWD)/build/clang-build/
clang: build/clang/bin/clang

build/bin/wasm32-unknown-unknown-wasm-clang: build/clang/bin/clang ./wrappers/*
	mkdir -p build/bin
	rm -f ./build/bin/*
	for x in cc c++ gcc g++ clang clang++; do \
		cp ./wrappers/cc_wrapper.py ./build/bin/wasm32-unknown-unknown-wasm-$$x ; \
	done
	for x in ar as nm objcopy objdump ranlib readelf readobj size strings; do \
		cp ./wrappers/generic_wrapper.py ./build/bin/wasm32-unknown-unknown-wasm-$$x ; \
	done
	for x in lld; do \
		cp ./wrappers/lld_wrapper.py ./build/bin/wasm32-unknown-unknown-wasm-$$x ; \
	done
	cp ./wrappers/stub_strip.py ./build/bin/wasm32-unknown-unknown-wasm-strip
wrappers: build/bin/wasm32-unknown-unknown-wasm-clang

build/musl/lib/libc.a: build/bin/wasm32-unknown-unknown-wasm-clang
	mkdir -p build/musl-build
	(cd ./build/musl-build/ && \
		export CROSS_COMPILE="$(PWD)/build/bin/wasm32-unknown-unknown-wasm-" && \
		export WASM_CFLAGS="$(MUSL_CFLAGS)" && \
		$(PWD)/projects/musl/configure $(MUSL_ARGS) && \
		make all install $(JOB_FLAG) \
	)
	rm -rf ./build/musl-build
musl: build/musl/lib/libc.a

build/compiler-rt/lib/libclang_rt.builtins-wasm32.a: build/clang/bin/clang build/musl/lib/libc.a build/lld/bin/lld build/bin/wasm32-unknown-unknown-wasm-clang
	mkdir -p build/compiler-rt;
	(cd ./build/compiler-rt/ && \
		export CC=$(PWD)/build/bin/wasm32-unknown-unknown-wasm-clang && \
		export CXX=$(PWD)/build/bin/wasm32-unknown-unknown-wasm-clang++ && \
		export WASM_LDFLAGS="-lc -nodefaultlibs" && \
		cmake $(GLOBAL_ARGS) $(COMPILERRT_ARGS) ../../projects/compiler-rt && \
		make all $(JOB_FLAG) && \
		ls $(PWD)/build/musl/lib/*.a | while read x; do $(PWD)/build/llvm/bin/llvm-ranlib $$x; done \
	);
	mv $(PWD)/build/compiler-rt/lib/generic/*.a $(PWD)/build/compiler-rt/lib/
compiler-rt: build/compiler-rt/lib/libclang_rt.builtins-wasm32.a

a.out.wasm:
	$(PWD)/build/bin/wasm32-unknown-unknown-wasm-clang ./test/hello.c
test: a.out.wasm