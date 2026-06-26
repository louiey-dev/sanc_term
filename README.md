# sanc_term

terminal app which supports xtem/uart/udp support

## Features

- 🚀 Cross platform: mobile, desktop, browser
- 📚 Terminal support: xterm, uart, udp support
- 🗄️ Log support: save terminal log to file
  - in Windows, save to Desktop by default
  - other OS, save to DOC directory
- 🔥 popular packages
  - riverpod for state management, go_router for routing
  - hive/window manager support
  - hive for data storage, window manager for window
  - xterm for terminal support
    - xterm package is inside of local due to bug patch
- 🪟 multiple window support
  - serial, pty support
  - short key support, move between windows via `ALT + 1/2/3/4...`
  - log file is logging all of open windows (only one log file available)
- 🌗 dark/light theme support

## History

- 2026.06.25
  - Preparing based on flutter_terminal app for more better architect and performance
  - implemented basic features at `sanc_term_design.md`
  - multiple uart/pty window open support
  - log file dir is desktop by default
- 2026.06.26
  - short key added at terminal to move between windows (`ALT + 1/2/3...`)

## Info

- Author : <louiey.dev@gmail.com>
- Version : 0.1.0
