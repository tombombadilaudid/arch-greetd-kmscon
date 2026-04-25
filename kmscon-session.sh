#!/bin/sh
ACTIVE_TTY=$(cat /sys/class/tty/tty0/active)
exec sudo kmscon --vt=$ACTIVE_TTY --seats=seat0 --no-switchvt --login -- /etc/greetd/kmscon-login.sh $(whoami)
