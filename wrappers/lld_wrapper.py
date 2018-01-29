#!/usr/bin/env python
import os
import sys
fullFileName = os.path.realpath(__file__)
path = os.path.realpath(os.path.dirname(fullFileName) + '/../../') + '/'
fileName = fullFileName[fullFileName.rfind('/')+1:]
args = sys.argv[1:]
args.insert(0, fileName)

PAIR_ARGS = [ '-Map' ]
SINGLE_ARGS = [
    '',
    '--start-group',
    '--end-group',
    '--warn-common',
    '-L/lib',
    '--gc-sections',
    '--sort-common'
]
ARG_PREFIXES = [
    '--sort-section,'
]

for i in range(0,len(args)):
    if args[i] in PAIR_ARGS:
        args[i] = ''
        args[i+1] = ''
        continue
    for j in range(0,len(ARG_PREFIXES)):
        if args[i].startswith(ARG_PREFIXES[j]):
            args[i] = ''
args = filter(lambda (arg): arg not in SINGLE_ARGS, args)

TOOL = "build/lld/bin/lld"
POSTARGS = [
    '-z', 'relro',
    '-z', 'now'
]

args.extend(POSTARGS)
if 'WASM_DEBUG' in os.environ:
    line = [path + TOOL]
    line.extend(args[1:])
    print >> sys.stderr, ' '.join(line)
os.execv(path + TOOL, args)
