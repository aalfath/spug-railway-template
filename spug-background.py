#!/usr/bin/env python3
"""Run Spug's three background loops (worker, monitor, scheduler) as threads of ONE Python
process instead of three, which saves about 200 MB so Spug fits Railway's 0.5 GB plan.

Each loop is upstream's own class, unchanged (manage.py runworker / runmonitor / runscheduler).
If any loop raises, the whole process exits non-zero; supervisord restarts it, and if it keeps
failing the fatal-exit listener stops the container so Railway restarts it."""
import logging, os, sys, threading, traceback

os.chdir('/data/spug/spug_api')
sys.path.insert(0, '/data/spug/spug_api')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'spug.settings')
import django  # noqa: E402
django.setup()
logging.basicConfig(level=logging.WARNING, format='%(asctime)s %(message)s')

from apps.exec.management.commands.runworker import Worker  # noqa: E402
from apps.monitor.scheduler import Scheduler as MonitorScheduler  # noqa: E402
from apps.schedule.scheduler import Scheduler as TaskScheduler  # noqa: E402


def guard(name, factory):
    def run():
        try:
            factory().run()
            sys.stderr.write('[spug-background] %s returned unexpectedly\n' % name)
        except BaseException:
            sys.stderr.write('[spug-background] %s crashed:\n%s' % (name, traceback.format_exc()))
        sys.stderr.flush()
        os._exit(1)
    return threading.Thread(target=run, name=name, daemon=True)


threads = [guard('worker', Worker), guard('monitor', MonitorScheduler), guard('scheduler', TaskScheduler)]
for t in threads:
    t.start()
for t in threads:
    t.join()
os._exit(1)
