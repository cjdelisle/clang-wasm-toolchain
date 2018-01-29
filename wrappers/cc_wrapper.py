#!/usr/bin/env python
import os
import sys
fullFileName = os.path.realpath(__file__)
path = os.path.realpath(os.path.dirname(fullFileName) + '/../../') + '/'
fileName = fullFileName[fullFileName.rfind('/')+1:]
args = sys.argv[1:]

toolPath = False
notLinking = False
isCpp = False
noCppInclude = False
nonFlagArgs = False
for i in range(0,len(args)):
    if args[i] in ['-c', '-S', '-E', '-M', '-MM']: notLinking = True
    if args[i] in ['-nostdinc', 'nostdinc++']: noCppInclude = True
    if args[i] == '-x' and (i + 1) < len(args):
        if args[i+1].index('c++') == 0: isCpp = True
        if args[i+1].endswith('-header'): notLinking = True
    if not args[i].startswith('-'): nonFlagArgs = True

args.insert(0, fileName)
tool = fileName.split('-')[-1]
TOOL_MAP = {
    'gcc': 'clang',
    'cc': 'clang',
    'c++': 'clang++',
    'g++': 'clang++'
}
if tool in TOOL_MAP: tool = TOOL_MAP[tool]
if toolPath == False: toolPath = "build/clang/bin/" + tool
LDFLAGS = []
if 'WASM_CFLAGS' in os.environ: args.extend(os.environ['WASM_CFLAGS'].split(' '))
if 'WASM_LDFLAGS' in os.environ: LDFLAGS.extend(os.environ['WASM_LDFLAGS'].split(' '))

ARG_MAP = {
    # This should map to -static-compiler-rt but that's not complete yet and anyway everything's static
    '-static-libgcc': ''
}
POSTARGS = [
    '-target', 'wasm32-unknown-unknown-wasm',
    '-mthread-model', 'single',
    '-B' + path + 'build/bin/',
    '-idirafter', path + 'projects/kernel-headers/generic/include',
    '-I', path + 'include_asm',
    '-D__linux=1', '-D__linux__=1', '-D__gnu_linux__=1', '-Dlinux=1'
]
LDFLAGS.extend([
    '-Wl,--allow-undefined-file=' + path + 'wasm.syms'
])
if isCpp: POSTARGS.extend(['-nostdlib++'])
if '-nostdlib' not in args and '-nostdlib' not in LDFLAGS:
    POSTARGS.extend([
        '--sysroot', path + 'build/musl',
        '-idirafter', path + 'build/musl/include'
    ])
if '-nodefaultlibs' not in args and '-nodefaultlibs' not in LDFLAGS:
    LDFLAGS.extend([
        '-rtlib=compiler-rt',
        '-resource-dir', path + 'build/compiler-rt'
    ])

if not notLinking:
    POSTARGS.extend(LDFLAGS)
    if '-o' not in args: POSTARGS.extend(['-o', 'a.out.wasm'])

def argMap(x):
    if x in ARG_MAP: return ARG_MAP[x]
    return x
args = filter(lambda x: x != '', map(argMap, args))
args.extend(POSTARGS)
if 'WASM_DEBUG' in os.environ:
    moreData = ('notLinking = ' + str(notLinking) +
        ' isCpp = ' + str(isCpp) +
        ' noCppInclude = ' + str(noCppInclude) +
        ' nonFlagArgs = ' + str(nonFlagArgs))
    #print >> sts.stderr, moreData
    line = [path + toolPath]
    line.extend(args[1:])
    print >> sys.stderr, ' '.join(line)
os.execv(path + toolPath, args)
