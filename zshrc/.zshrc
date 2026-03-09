# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH_AUTOSUGGEST_STRATEGY=(history completion) # check history first (fastest)
export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=30            # Don't suggest if I've typed a paragraph
export ZSH_AUTOSUGGEST_USE_ASYNC=1                   # Force async

for zlib in "${ZDOTDIR:-$HOME}"/conf.d/*.zsh; do
  source "$zlib"
done
unset zlib

if [[ -n "${ANTIDOTE_ZSH:-}" && -f "${ANTIDOTE_ZSH}" ]]; then
  source "${ANTIDOTE_ZSH}"
fi

if ! typeset -f antidote >/dev/null 2>&1; then
  echo "antidote not found; skipping plugin load" >&2
else
  plugins_file="$ZDOTDIR/.zsh_plugins.txt"
  if [[ "${ZSH_MOBILE:-0}" == "1" && -f "$ZDOTDIR/.zsh_plugins.mobile.txt" ]]; then
    plugins_file="$ZDOTDIR/.zsh_plugins.mobile.txt"
  fi
  staticfile="${XDG_CACHE_HOME:-$HOME/.cache}/antidote/plugins-${ZSH_MOBILE:-0}.zsh"
  mkdir -p "${staticfile:h}"
  antidote load "$plugins_file" "$staticfile"
fi

if [[ -f "$HOME/.local/bin/env" ]]; then
  . "$HOME/.local/bin/env"
fi

fpath=($ZDOTDIR/completions $fpath)
setopt globdots
setopt interactivecomments

if [[ -t 0 ]]; then
  stty -ixon
fi

export EDITOR=nvim
export LESS='-R --use-color'
export BAT_THEME="matugen-bat-colors"
if [[ -d "$HOME/.dotnet" ]]; then
  export DOTNET_ROOT="$HOME/.dotnet"
fi

if command -v pay-respects >/dev/null 2>&1; then
  eval "$(pay-respects zsh)"
fi

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

zstyle ':bracketed-paste-magic' active-widgets '.self-*'

# To customize prompt, run `p10k configure` or edit ~/.config/zshrc/.p10k.zsh.
[[ -f "$ZDOTDIR/.p10k.zsh" ]] && source "$ZDOTDIR/.p10k.zsh"
