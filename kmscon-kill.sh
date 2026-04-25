#!/bin/sh
while loginctl show-session $(loginctl list-sessions | awk -v vt="$1" '$5 == "tty"vt {print $1}') -p Type --value 2>/dev/null | grep -q "wayland\|x11"; do
	sleep 0.5
done
kill -TERM $(pgrep -f "/usr/lib/kmscon/kmscon.*--vt=tty${1}")
