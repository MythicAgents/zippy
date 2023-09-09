#!/bin/sh
echo -ne '\033c\033]0;zippy\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/zippy_linux_x86_64.elf" "$@"
