# sanc_term

terminal app which supports xtem/uart/udp and so on.

## Features

- 🚀 Cross platform: mobile, desktop, browser
- terminal support
- uart/udp support
- log to file
  - in Windows, save to Desktop by default
  - other OS, save to DOC directory
- riverpod for state management, go_router for routing
- hive/window manager support
- used xterm package inside of local due to bug patch
- multiple window support
  - serial, pty support
  - move between windows via 'ALT + 1/2/3/4...'
  - log file logging all of open windows (only one log file available)

## History

- 2026.06.25
  - Preparing based on flutter_terminal app for more better architect and performance
  - implemented basic features at `sanc_term_design.md`
  - multiple uart/pty window open support
  - log file dir is desktop by default

## Info

- Author : <louiey.dev@gmail.com>
- Version : 0.1.0
