#!/usr/bin/env bash

strace -x -s 2048 -e trace=write,sendmsg dbus-send --session --type=method_call --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Pause
