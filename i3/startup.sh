#!/bin/sh

exec >/tmp/i3-startup.log 2>&1

echo "Setting up better mouse mappings"
synclient TapButton1=1
synclient TapButton2=3
synclient TapButton3=2
# Not yet ready for the rest of this
exit 0

MONITOR="eDP-1"
#MIRROR="2560x1440"

if [ -n "$MIRROR" ] ; then
	# single monitor
	echo Single monitor with panning at $MIRROR
	xrandr --output $MONITOR --panning $MIRROR --output DP-1 --same-as $MONITOR
	i3-msg 'workspace 2; append_layout /home/doanac/.i3/workspace-2.json'
	i3-msg 'workspace 1; append_layout /home/doanac/.i3/workspace-1.json'
else
	if xrandr | grep "^DP-1 con" >/dev/null ; then
		# multi-monitor
		echo "MULTI MONITOR FOUND"
		xrandr --output $MONITOR --output DP-1 --left-of $MONITOR
		i3-msg 'workspace 2; append_layout /home/doanac/.i3/workspace-1.json'
		i3-msg 'workspace 3; append_layout /home/doanac/.i3/workspace-2.json'
		i3-msg 'workspace 1; append_layout /home/doanac/.i3/workspace-1left.json'
	else
		# single monitor
		echo "SINGLE MONITOR"
		i3-msg 'workspace 2; append_layout /home/doanac/.i3/workspace-2.json'
		i3-msg 'workspace 1; append_layout /home/doanac/.i3/workspace-1.json'
	fi
fi

nm-applet &
# enable volume buttons
xfce4-volumed
# enable a volume applet
/home/doanac/.i3/pasystray.sh &
/home/doanac/.i3/lockscreen.sh &
/home/doanac/btsync-dirs/btsync

# restore layouts
xfce4-terminal &
xfce4-terminal &
xfce4-terminal &
firefox &
gvim
