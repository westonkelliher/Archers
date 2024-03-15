import re
import sys

if len(sys.argv) < 2:
    print("Usage: python script.py filename")
    sys.exit(1)

filename = sys.argv[1]

with open(filename, 'r') as file:
    for line in file:
        match = re.search(r'd="M(.*?)Z', line)
        if match:
            result = match.group(1)
            result = re.sub(r'\.[^ ]+', '', result)
            print("M"+result+"Z")
