#!/bin/bash

# git completion system
./scripts/git-completion.sh

# prompt
curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin
oh-my-posh font install

# execute stow
stow .

