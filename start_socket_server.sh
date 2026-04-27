#!/usr/bin/env bash

socat -u UNIX-LISTEN:/tmp/test.sock,fork STDOUT
