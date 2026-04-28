#!/usr/bin/env bash

socat UNIX-LISTEN:/tmp/test.sock,fork STDIO
