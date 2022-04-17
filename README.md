![Logo](./logo.png)

# rach lunx
The most Arch Linux installer

## Disclaimer
please don't be mad at me if this script deletes something important

## How
1. Boot into the Arch installer image
2. `mkcd /tmp/rach`
3. `curl overli.st/rach | tar -xz && ./rach.sh <disk>`
4. Install your microcode and configure the timezone, locales and the hostname
5. Ctrl + D
6. `reboot`
7. Log in as root with the password `1`
8. `/usr/share/rach/rachuser.sh <username>`

## Why
h
