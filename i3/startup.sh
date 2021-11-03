#!/bin/sh

HERE=$(dirname $(readlink -f $0))

exec >/tmp/i3-startup.log 2>&1

echo "Setting up better mouse mappings"
synclient TapButton1=1
synclient TapButton2=3
synclient TapButton3=2

LAPTOP="eDP1"
MONITOR="DP[0-9]\(-[0-9]\)\?"
#MIRROR="2560x1440"
#MIRROR="1920x1080"

xrandr

if [ -n "$MIRROR" ] ; then
	# single monitor
	echo Single monitor with panning at $MIRROR
	xrandr --output $LAPTOP --panning $MIRROR --output $MONITOR --same-as $LAPTOP
	i3-msg "workspace 2; append_layout $HERE/workspace-2.json"
	i3-msg "workspace 1; append_layout $HERE/workspace-1.json"
else
	if xrandr | grep "^$MONITOR con" >/dev/null ; then
		# multi-monitor
		echo "MULTI MONITOR FOUND"
		mon=$(xrandr | grep -o "^$MONITOR con" | sed 's/ con//')
		echo "Using monitor: $mon"
		xrandr --output $mon --mode 2560x1440

		xrandr --output $LAPTOP --output $mon --right-of $LAPTOP
		sleep 2s
		i3-msg "workspace 1; append_layout $HERE/workspace-1left.json"
		i3-msg "workspace 2; append_layout $HERE/workspace-1.json"
		i3-msg "workspace 3; append_layout $HERE/workspace-2.json"
	else
		# single monitor
		echo "SINGLE MONITOR"
		i3-msg "workspace 2; append_layout $HERE/workspace-2.json"
		i3-msg "workspace 1; append_layout $HERE/workspace-1.json"
	fi
fi
nm-applet &
# enable volume buttons
#xfce4-volumed
# enable a volume applet
#/home/doanac/.i3/pasystray.sh &
#/home/doanac/.i3/lockscreen.sh &

# restore layouts
terminator &
terminator &
terminator &
firefox &
gvim
