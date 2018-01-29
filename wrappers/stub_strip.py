#!/usr/bin/env python
import os
import sys
from shutil import copyfile
line = sys.argv
args = line[1:]
PAIR_ARGS = [ '-F', '-I', '-O', '-R', '-K', '-N', '-o' ]
SINGLE_ARGS = [
    '--help',
    '--info',
    '-s',
    '--strip-all',
    '-g',
    '-S',
    '-d',
    '--strip-debug',
    '--strip-unneeded',
    '-p',
    '--preserve-dates',
    '-w',
    '--wildcard',
    '-x',
    '--discard-all',
    '-X',
    '--discard-locals',
    '--keep-file-symbols',
    '--only-keep-debug',
    '-V',
    '--version',
    '-v',
    '--verbose',
    '' ## This is what we convert all of the more complex stuff to
]
ARG_PREFIXES = [
    '--target=',
    '--input-target=',
    '--output-target=',
    '--remove-section=',
    '--keep-symbol=',
    '--strip-symbol='
]
outfile = None
for i in range(0,len(args)):
    if args[i] in PAIR_ARGS:
        if args[i] == '-o':
            outfile = args[i+1]
        args[i] = ''
        args[i+1] = ''
        continue
    for j in range(0,len(ARG_PREFIXES)):
        if args[i].startswith(ARG_PREFIXES[j]):
            args[i] = ''
args = filter(lambda (arg): arg not in SINGLE_ARGS, args)
infile = None
for i in range(0,len(args)):
    if not infile or (infile.startswith('-') and not args[i].startswith('-')):
        infile = args[i]

if 'WASM_DEBUG' in os.environ:
    print >> sys.stderr, ' '.join(line)

if infile and outfile:
    print >> sys.stderr, '### STRIP IS UNSUPPORTED ### copying %s to %s' % (infile, outfile)
    copyfile(infile, outfile)
else:
    print >> sys.stderr, '### STRIP IS UNSUPPORTED ### doing nothing to %s' % (infile)