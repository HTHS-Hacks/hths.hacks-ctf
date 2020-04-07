#!/usr/bin/python2
import os, sys

sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)
print "You got it! As a reward, here's your flag: {{flag}}"
