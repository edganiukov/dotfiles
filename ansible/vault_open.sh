#!/bin/sh

set -e

gpg --batch --use-agent --decrypt vault_pass.gpg
