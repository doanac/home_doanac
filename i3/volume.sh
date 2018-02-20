#!/bin/sh

card=$(cat /proc/asound/cards | grep PCH | head -n1 | cut -d\  -f2)

if [ "$1" = "+" ] ; then
	amixer -c $card set Master 2%+ && volnoti-show $(amixer -c $card get Master | grep -Po '[0-9]+(?=%)' | head -1)
fi
if [ "$1" = "-" ] ; then
	amixer -c $card set Master 2%- && volnoti-show $(amixer -c $card get Master | grep -Po '[0-9]+(?=%)' | head -1)
fi
if [ "$1" = "mute" ] ; then
	amixer -c $card set Master toggle && if amixer -c $card get Master | grep -Fq '[off]'; then volnoti-show -m; else volnoti-show $(amixer -c get Master | grep -Po '[0-9]+(?=%)' | head -1); fi
fi
