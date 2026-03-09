export FZF_DEFAULT_COMMAND='fd -LH --exclude .git'
export FZF_THEME="
  --ansi \
  --border=rounded \
  --highlight-line \
  --info=inline-right \
  --color=bg:-1,bg+:0 \
  --color=fg:-1,fg+:-1 \
  --color=gutter:-1 \
  --color=border:4,scrollbar:4 \
  --color=hl:4,hl+:4 \
  --color=header:3,separator:3 \
  --color=info:5 \
  --color=marker:5,pointer:5,spinner:5 \
  --color=prompt:4 \
   --color=query:7:regular
   "

FZF_PREVIEW_OPTS=""
if [[ "${ZSH_MOBILE:-0}" != "1" ]]; then
  if command -v lesspipe.sh >/dev/null 2>&1; then
    FZF_PREVIEW_OPTS="--preview 'lesspipe.sh {}' --bind '?:toggle-preview'"
  elif command -v bat >/dev/null 2>&1; then
    FZF_PREVIEW_OPTS="--preview 'bat --color=always --style=plain --line-range=:200 {}' --bind '?:toggle-preview'"
  fi
fi

export FZF_DEFAULT_OPTS="--bind=tab:accept \
  --layout=reverse \
  --height=~75% \
  --style=full \
  $FZF_PREVIEW_OPTS \
  --tiebreak=index \
  $FZF_THEME
  "
# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
# NOTE: don't use escape sequences (like '%F{red}%d%f') here, fzf-tab will ignore them
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
zstyle ':completion:*' menu no
# custom fzf flags
# NOTE: fzf-tab does not follow FZF_DEFAULT_OPTS by default
# zstyle ':fzf-tab:*' fzf-flags '--color=fg:1,fg+:2 --style=full --inline-info --bind=tab:accept --height=-20% --ansi --color=16 --border'

# To make fzf-tab follow FZF_DEFAULT_OPTS.
# zstyle ':fzf-tab:*' use-fzf-default-opts yes
# switch group using `<` and `>`
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:*' continuous-trigger 'right'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-flags '--tiebreak=index'
zstyle ':fzf-tab:complete:z:*' fzf-flags '--tiebreak=index'
zstyle ':fzf-tab:complete:cd:*' fzf-flags '--tiebreak=index'

function fzf-force-height() {
    # You can also force layout/border here if needed
   fzf "$@" \
    --min-height=10+ \
    --height=40% \
    --layout=reverse \
    --style=minimal \
    --preview-window=right:60% \
    ${=FZF_THEME}
    
}

# 2. Tell fzf-tab to use this wrapper
zstyle ':fzf-tab:*' fzf-command fzf-force-height

fzf-zoxide-insert-widget() {
  local selected_dir=$(
    zoxide query -l | fzf \
    --height=80% \
    --prompt="Path >" \
    --tiebreak=index
  )

  if [[ -n "$selected_dir" ]]; then
    # Check if we need to add a leading space
    # (If buffer is not empty and doesn't end with a space)
    if [[ -n "$LBUFFER" && "$LBUFFER" != *" " ]]; then
      LBUFFER+=" "
    fi
    
    # Append the directory
    LBUFFER+="${selected_dir}"
  fi

  zle redisplay
}

zle -N fzf-zoxide-insert-widget

bindkey -M viins '^f' fzf-zoxide-insert-widget
bindkey -M vicmd '^f' fzf-zoxide-insert-widget

function zvm_after_init() {
  # 1. Bind your Custom Zoxide Widget (Insert Mode)
  zvm_bindkey viins '^e' fzf-zoxide-insert-widget
  
  # 2. Restore Standard FZF bindings (Files & History)
  # These often get killed by vi-mode. We explicitly bring them back.
  
  # Ctrl+T = FZF File Search (Insert Mode)
  if zle -l fzf-file-widget; then
    zvm_bindkey viins '^t' fzf-file-widget
  fi

  # Ctrl+R = FZF History Search (Insert Mode)
  if zle -l fzf-history-widget; then
    zvm_bindkey viins '^r' fzf-history-widget
  fi
  
  # 3. Optional: Fix Autosuggestions (Accept with Ctrl+Space or Ctrl+f)
  # if type autosuggest-accept > /dev/null; then
  #   zvm_bindkey viins '^f' autosuggest-accept
  # fi
}
