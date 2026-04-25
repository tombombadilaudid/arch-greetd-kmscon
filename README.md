# arch-greetd-tuigreet-kmscon

How to get kmscon working with greetd+tuigreet on Arch Linux


## installation
Make sure to follow these steps exactly if installing manually or you'll probably have a real bad time
### the lazy way:

* dump all the files from the greetd directory into '/etc/greetd/' and then make all the scripts executable with 'chmod +x filename.sh' 
* place greetd@.service in '/etc/systemd/system/'
* follow steps 1, 2, 9, 10, 11, and 13
\ alternatively just wait for me to make an interactive install/uninstall script

### manually:

**1)** install kmscon.
```bash
sudo pacman -S kmscon
```
\
**2)** install greetd-tuigreet - it will pull greetd as a dependency automatically
```bash
sudo pacman -S greetd-tuigreet
```
\
**3)** create **`/etc/greetd/greetd-vt.sh`**
```sh
#!/bin/sh
VT="${1#tty}"
exec greetd --config /etc/greetd/config.toml --vt $VT
```
and make it executable
```bash
sudo chmod +x /etc/greetd/greetd-vt.sh
```
\
**4)** Edit **`/etc/greetd/config.toml`**
```toml
[terminal]
vt = 1

[default_session]
command = "tuigreet --your --style --or --feature --flags --here --cmd /etc/greetd/kmscon-session.sh"
```
\
**5)** create **`/etc/greetd/kmscon-session.sh`**
```sh
#!/bin/sh
ACTIVE_TTY=$(cat /sys/class/tty/tty/active)
exec sudo kmscon --vt=$ACTIVE_TTY --seats=seat0 --no-switchvt --login -- /etc/greetd/kmscon-login.sh $(whoami)
```
and make it executable
```bash
sudo chmod +x /etc/greetd/kmscon-session.sh
```
\
**6)** create **`/etc/greetd/kmscon-login.sh`**
```sh
#!/bin/sh
exec /bin/login -p -f $1
```
and make it executable
```bash
sudo chmod +x /etc/greetd/kmscon-login.sh
```
\
**7)** create **`/etc/greetd/kmscon-kill.sh`**
```sh
#!/bin/sh
while loginctl show-session $(loginctl list-sessions | awk -v vt="$1" '$5 == "tty"vt {print $1}') -p Type --value 2>/dev/null | grep -q "wayland\|x11"; do
        sleep 0.5
done
kill -TERM $(pgrep -f "/usr/lib/kmscon/kmscon.*--vt=tty${1}")
```
and make it executable
```bash
sudo chmod +x /etc/greetd/kmscon-kill.sh
```
\
**8)** create **'/etc/greetd/session-wrapper.sh'**
```bash
#!/bin/sh
. /etc/profile
[ -f "$HOME/.bash_profile" ] && . "$HOME/.bash_profile"
exec "$@"
```
and make it executable
```bash
sudo chmod +x /etc/greetd/session-wrapper.sh
```
\
**9)** edit your **`~/.bash_profile`** to include these lines
```bash
export XDG_RUNTIME_DIR=/run/usr/$(id -u)
export DBUS_SESSION_BUS_ADDRESS=unix:path=$XDG_RUNTIME_DIR/bus
export PATH="$HOME/.local/bin:$PATH"

[[ -f ~/.bashrc ]] && . ~/.bashrc
```
\
**10)** **optional(ish)** - add a logout function to your **`~/.bashrc`** or you won't be able to log out to tuigreet, kmscon will just instantly log back i>

* *the example function below checks if you are currently running a display server on the session and if so it checks if it is uwsm managed before killing >
* ***if it is uwsm managed*** it gracefully exits with **`uwsm stop`** before sending a kill signal to kmscon via **`/etc/greetd/kmscon-kill.sh`**
* ***if it is not uwsm managed***  it checks if it is Hyprland and if so exits gracefully with **`hyprctl dispatch exit`** before sending a kill signal to >
* ***if it is not uwsm managed and NOT Hyprland*** it will terminate the session with loginctl and then kill kmscon via **`/etc/greetd/kmscon-kill.sh`**
```bash
logout() {
    if [ -n "$XDG_VTNR" ] && pgrep -f "/usr/lib/kmscon/kmscon.*--vt=tty${XDG_VTNR}" > >
        SESSION_TYPE=$(loginctl show-session $XDG_SESSION_ID -p Type --value)
        if [ "$SESSION_TYPE" = "wayland" ] || [ "$SESSION_TYPE" = "x11" ]; then
            sudo /etc/greetd/kmscon-kill.sh $XDG_VTNR &
            if uwsm check is-active 2>/dev/null; then
                uwsm stop
            elif [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
                hyprctl dispatch exit
            elif [ -n "$WAYLAND_DISPLAY" ] || [ -n "$DISPLAY" ]; then
                loginctl terminate-session $XDG_SESSION_ID
            fi
        else
            sudo /etc/greetd/kmscon-kill.sh $XDG_VTNR
        fi
    else
        builtin logout
    fi
}
```
\
**11)** create a new sudoers file just for use with this setup
```bash
sudo visudo -f /etc/sudoers.d/kmscon
```
\
now add some rules; replace username with your username
```bash
username ALL=(ALL) NOPASSWD: /usr/bin/kmscon
username ALL=(ALL) NOPASSWD: /etc/greetd/kmscon-kill.sh
```
\
**12)** create **`/etc/systemd/system/greetd@.service`**
```bash
[Unit]
Description=Greeter daemon on %I
After=systemd-user-sessions.service plymouth-quit-wait.service getty@%i.service kmsconvt@%i.service
OnFailure=kmsconvt@%i.service
Conflicts=getty@%i.service kmsconvt@%i.service

[Service]
Type=simple
ExecStart=/etc/greetd/greetd-vt.sh %i
IgnoreSIGPIPE=no
SendSIGHUP=yes
TimeoutStopSec=30s
KeyringMode=shared
Restart=on-success
RestartSec=1
StartLimitBurst=5
StartLimitInterval=30

[Install]
WantedBy=getty.target
```
\
**13)** systemd setup
* if you want this setup on all ttys create this symlink
```bash
sudo ln -sf '/etc/systemd/system/greetd@.service' '/etc/systemd/system/autovt@.service'
```
* now disable getty (and/or kmscon depending on whether or not you set it up prior to this)
```bash
sudo systemctl disable kmsconvt@tty1.service getty@tty1.service
```
* you must manually enable it on tty1 even if you did the symlink above; you can enable on specific ttys this way as well
```bash
sudo systemctl enable greetd@tty1.service
```
* now just reload and reboot
```bash
sudo systemctl daemon-reload
sudo systemctl reboot
```
