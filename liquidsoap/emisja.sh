#!/bin/bash

su liquidsoap -c "python3 /home/liquidsoap/rals.py"
sleep 1
python3 /home/liquidsoap/utworzfolderaudycji.py
sleep 1
service liquidsoap start

/usr/sbin/cron -f

