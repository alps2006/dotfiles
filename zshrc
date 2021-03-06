[ -e $HOME/.zsh/exports       ] && source $HOME/.zsh/exports
[ -e $HOME/.zsh/options       ] && source $HOME/.zsh/options
[ -e $HOME/.zsh/aliases       ] && source $HOME/.zsh/aliases
[ -e $HOME/.zsh/colour        ] && source $HOME/.zsh/colour
[ -e $HOME/.zsh/prompt        ] && source $HOME/.zsh/prompt
[ -e $HOME/.zsh/bindings      ] && source $HOME/.zsh/bindings
[ -e $HOME/.zsh/completion    ] && source $HOME/.zsh/completion

if ! hostname | grep "^verns-\|li380-170\|^G08FNST\|^BITD" > /dev/null 2>&1; then
    return # 不是我的机器
fi

export HOME="/sun"
export DEBEMAIL="s5unty@gmail.com"
export DEBFULLNAME="Vern Sun"
export TZ='Asia/Shanghai'

if [ `tty | grep -c pts` -eq 1 ]; then
    stty -ixon -ixoff # 关闭 C-Q, C-S 流控制
    export TERM="rxvt-256color"
    export LANG="zh_CN.UTF-8"
fi

if [[ -f $HOME/.zsh/dircolors ]] ; then   #自定义颜色
    eval $(dircolors -b $HOME/.zsh/dircolors)
fi

# Flexible Zsh plugin manager with clean fpath, reports, completion management, turbo mode, services
### Added by Zplugin's installer {{{1
source '/sun/.zplugin/bin/zplugin.zsh'
autoload -Uz _zplugin
(( ${+_comps} )) && _comps[zplugin]=_zplugin
### End of Zplugin's installer chunk }}}

# Multi-word, syntax highlighted history searching for Zsh {{{1
# https://github.com/zdharma/history-search-multi-word
zplugin load zdharma/history-search-multi-word
zstyle ":history-search-multi-word" highlight-color "bg=yellow,bold"

# Fish-like autosuggestions for zsh {{{1
# https://github.com/zsh-users/zsh-autosuggestions
zplugin light zsh-users/zsh-autosuggestions

# Fish shell like syntax highlighting for Zsh. {{{1
# https://github.com/zsh-users/zsh-syntax-highlighting
zplugin load zsh-users/zsh-syntax-highlighting
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor)

# A cd command that learns - easily navigate directories from the command line {{{1
# https://github.com/wting/autojump
zplugin ice as"program" make"PREFIX=$ZPFX" src"bin/autojump.sh"
zplugin light wting/autojump

# zsh-complete-words-from-urxvt-scrollback-buffer {{{1
# https://gist.github.com/s5unty/2486566
zplugin snippet https://gist.github.com/s5unty/2486566/raw
bindkey -M viins "\e\t" urxvt-scrollback-buffer-words-prefix    # Alt-Tab
bindkey -M viins "^[[Z" urxvt-scrollback-buffer-words-anywhere  # Shift-Tab
