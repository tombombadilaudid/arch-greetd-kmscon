#!/bin/sh
VT="${1#tty}"
CONFIG=$(mktemp /tmp/greetd-XXXXXX.toml)
cat > $CONFIG << EOF
[terminal]
vt = $VT

[default_session]
command = "tuigreet --time --asterisks --greeting '$1' --session-wrapper '/etc/greetd/session-wrapper.sh' --cmd /etc/greetd/kmscon-session.sh"
user = "greeter"
EOF
exec greetd --config $CONFIG
