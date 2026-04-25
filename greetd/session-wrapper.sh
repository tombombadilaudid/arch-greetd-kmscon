#!/bin/sh
. /etc/profile
[ -f "$HOME/.bash_profile" ] && . "$HOME/.bash_profile"
exec "$@"
