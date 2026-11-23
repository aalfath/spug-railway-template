#!/usr/bin/env python3
"""supervisord event listener: when any program reaches FATAL (it crashed and gave up
restarting), record it and stop supervisord, so the Railway wrapper exits non-zero."""
import os, signal, sys

def main():
    while True:
        sys.stdout.write('READY\n'); sys.stdout.flush()
        header = dict(x.split(':', 1) for x in sys.stdin.readline().split())
        payload = sys.stdin.read(int(header.get('len', 0)))
        fields = dict(x.split(':', 1) for x in payload.split() if ':' in x)
        name = fields.get('processname', '?')
        sys.stderr.write('[railway] supervisord: %s entered FATAL\n' % name); sys.stderr.flush()
        with open('/run/spug-fatal', 'w') as f:
            f.write(name)
        sys.stdout.write('RESULT 2\nOK'); sys.stdout.flush()
        os.kill(os.getppid(), signal.SIGTERM)

if __name__ == '__main__':
    main()
