#!/usr/bin/env bash

aplay -l | grep "$1" | cut -d " " -f 2 | cut -d ":" -f 1
