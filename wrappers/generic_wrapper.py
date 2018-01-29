#!/usr/bin/env python
import os
import sys
fullFileName = os.path.realpath(__file__)
path = os.path.realpath(os.path.dirname(fullFileName) + '/../') + '/'
fileName = fullFileName[fullFileName.rfind('/'):]
toolPath = "llvm/bin/llvm" + fileName[fileName.rfind('-'):]
POSTARGS = [ ]
args = sys.argv[1:]
args.insert(0, fileName)
args.extend(POSTARGS)
if 'WASM_DEBUG' in os.environ:
    line = [path + toolPath]
    line.extend(args[1:])
    print >> sys.stderr, ' '.join(line)
os.execv(path + toolPath, args)
