# ZSH config

export PATH="$HOME/.local/bin:$PATH"

# enable colors
autoload -U colors && colors

zstyle ':completion:*' completer _complete _ignored
# Load Git completion
zstyle ':completion:*:*:git:*' script ~/.zsh/git-completion.bash

fpath=(~/.zsh $fpath)
zstyle :compinstall filename '/home/ggf/.zshrc'

autoload -Uz compinit && compinit

# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000
setopt autocd
bindkey -v

# oh-my-posh
eval "$(oh-my-posh init zsh)"
eval "$(oh-my-posh init zsh --config 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/catppuccin_mocha.omp.json')"

#autoload -Uz vcs_info
#precmd_vcs_info() { vcs_info }
#precmd_functions+=( precmd_vcs_info )
#setopt prompt_subst
#RPROMPT='${vcs_info_msg_0_}'
## PROMPT='${vcs_info_msg_0_}%# '
#zstyle ':vcs_info:git:*' formats '%b'

# source aliases
source ~/.aliasesrc

