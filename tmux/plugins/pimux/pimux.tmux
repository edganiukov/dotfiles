#!/usr/bin/env sh

if ! command -v pimux >/dev/null 2>&1; then
  tmux display-message "pimux: not found on PATH; run make pimux and add Go's bin directory to PATH"
  exit 1
fi
exec pimux init
