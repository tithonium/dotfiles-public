#!/bin/bash

if (which -s brew); then
  export HOMEBREW_BAT=1                     # Enable Bat colorization.
  export HOMEBREW_CURL_RETRIES=3            # Retry connection three times before giving up.
  export HOMEBREW_FORCE_BREWED_CURL=1       # Default to using Homebrew managed `curl`.
  export HOMEBREW_FORCE_BREWED_GIT=1        # Default to using Homebrew managed `git`.
  # export HOMEBREW_NO_ANALYTICS=1            # Disable any kind of analytics tracking.
  # export HOMEBREW_NO_AUTO_UPDATE=1          # Disable auto-update so you can control manually.
  export HOMEBREW_NO_INSECURE_REDIRECT=1    # Disable any kind of insecure redirect.
  # export HOMEBREW_NO_INSTALL_CLEANUP=1      # Disable auto-cleanup so you can control manually.
  export HOMEBREW_PREFIX="$(brew --prefix)" # Enhance alias/function performance by defining your own prefix.
fi

if [ -e ~/.paths ]; then
  . ~/.paths
fi

export EDITOR="nano -pw"
export LESS=-RiM

if [ -e ~/.functions ]; then
  . ~/.functions
fi

if [ -e ~/.local_bashrc ]; then
  . ~/.local_bashrc
fi


# If not running interactively, don't do anything else
if [[ -n "$PS1" ]] ; then

  if [ "$TERM" == "xterm-256color" ] ; then
    if [ -d /lib/terminfo ] ; then
      if [ -e /lib/terminfox/xterm-256color ] ; then
        export TERM=xterm-256color
      elif [ -e /lib/terminfox/xterm-debian ] ; then
        export TERM=xterm-debian
      else
        export TERM=xterm-color
      fi
    elif [ -d /usr/share/terminfo ] ; then
      if [ -e /usr/share/terminfo/78/xterm-256color ] ; then
        export TERM=xterm-256color
      else
        export TERM=xterm-color
      fi
    fi
  fi

  # don't put duplicate lines in the history. See bash(1) for more options
  export HISTCONTROL=ignoredups

  # set the history file size to more than the default 500 lines
  export HISTFILESIZE=50000
  export HISTSIZE=50000

  shopt -s checkwinsize
  shopt -s cmdhist
  # shopt -s failglob
  # shopt -u nocaseglob
  shopt -s histappend
  shopt -s lithist
  shopt -s no_empty_cmd_completion
  set -b
  unset histexpand


  # make less more friendly for non-text input files, see lesspipe(1)
  if [ -x /usr/bin/lesspipe ]; then
    eval "$(SHELL=/bin/sh lesspipe)"
  elif [ -x /usr/local/bin/lesspipe.sh ]; then
    eval "$(SHELL=/bin/sh lesspipe.sh)"
  fi

  # set variable identifying the chroot you work in (used in the prompt below)
  if [ -z "$debian_chroot" -a -r /etc/debian_chroot ]; then
      debian_chroot=$(cat /etc/debian_chroot)
  fi

  if [ "$command" != "gnome-session" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
      # We have color support; assume it's compliant with Ecma-48
      # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
      # a case would tend to support setf rather than setaf.)
      color_prompt=yes
    else
      color_prompt=
    fi
  fi

  # set a fancy prompt (non-color, unless we know we "want" color)
  case "$TERM" in
      xterm-color) color_prompt=yes;;
  esac

  if [ "$color_prompt" = yes ]; then
    usercolor='01;32'
    usermark='\u@\h'
    if [ $EUID = 0 ]; then
      usercolor='01;31'
      # usermark="‼️  $usermark ‼️ "
      usermark="$usermark"
    fi
    PROMPT_BASE='${debian_chroot:+($debian_chroot)}\[\033['"$usercolor"'m\]'"$usermark"'\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]'
    PROMPT_TAIL=' \[\033[01;38m\]\$\[\033[00m\] '
  else
    PROMPT_BASE='${debian_chroot:+($debian_chroot)}\u@\h:\w'
    PROMPT_TAIL=' \$ '
  fi
  PS1="$PROMPT_BASE$PROMPT_TAIL"
  unset color_prompt force_color_prompt

  if which githud >/dev/null 2>&1; then
    export PS1="${PROMPT_BASE}\$(githud bash)${PROMPT_TAIL}"
  elif which git-radar >/dev/null 2>&1; then
    export PS1="${PROMPT_BASE}\$(git-radar --bash)${PROMPT_TAIL}"
  fi


  # If this is an xterm set the title to user@host:dir
  case "$TERM" in
  xterm*|rxvt*)
      export SHORT_HOSTNAME=`hostname -s`
      PROMPT_COMMAND='echo -ne "\033]0;${USER}@${SHORT_HOSTNAME}: ${PWD/$HOME/~}\007"'
      ;;
  esac

  # enable color support of ls and also add handy aliases
  if [ "$TERM" != "dumb" -a -x /usr/bin/dircolors ]; then
    if [ -e ~/.dircolors ]; then
      eval "`dircolors -b ~/.dircolors`"
    elif [ -e /etc/DIR_COLORS ]; then
      eval "`dircolors -b /etc/DIR_COLORS`"
    else
      eval "`dircolors -b`"
    fi
  fi

  UN=`uname`
  if [ "$UN" == "Darwin" ]; then
    export BASH_SILENCE_DEPRECATION_WARNING=1

  #   # export PS1="\$(~/bin/battery-status)|$PS1"
  #   # export CLICOLOR=1
  #   # export LSCOLORS=ExFxCxDxBxegedabagacad

  fi

  # Add an "alert" alias for long running commands.  Use like so:
  #   sleep 10; alert
  alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

  # Alias definitions.
  if [ -e ~/.aliases ]; then
    . ~/.aliases
  fi

  # enable programmable completion features
  if (which brew >/dev/null 2>&1) && [ -f "$(brew --prefix)/etc/bash_completion" ]; then
    . "$(brew --prefix)/etc/bash_completion"
  else
    . ~/.bash_completion
  fi
  if [ "$command" != "gnome-session" ]; then
    if [ -e /etc/bash_completion ]; then
      . /etc/bash_completion
    fi
  fi

  if [ -e ~/.local_completion ]; then
    . ~/.local_completion
  fi


  if [ -f ~/.bundler-exec.sh ]; then
    . ~/.bundler-exec.sh
  fi

fi

if [ -d "$HOME/perl5" ]; then
  export PERL_LOCAL_LIB_ROOT="$PERL_LOCAL_LIB_ROOT:$HOME/perl5";
  export PERL_MB_OPT="--install_base $HOME/perl5";
  export PERL_MM_OPT="INSTALL_BASE=$HOME/perl5";
  export PERL5LIB="$HOME/perl5/lib/perl5:$PERL5LIB";
  export PATH="$HOME/perl5/bin:$PATH";
fi

if [ -x /usr/libexec/java_home ]; then
  export JAVA_HOME=$(/usr/libexec/java_home 2>/dev/null)
  export _JAVA_OPTIONS="-Xmx6g"
fi

if [ -x /usr/local/bin/go -a -d ~/.go ]; then
  export GOPATH=~/.go
fi

if [ -s ~/bin/h.sh ] && ((which ack >/dev/null 2>&1) || (which ack-grep >/dev/null 2>&1)); then
  source ~/bin/h.sh
fi

if [ -f ~/.fzf.bash ]; then
  source ~/.fzf.bash
  bind '"\C-g": " \C-e\C-u`__fzf_cd__`\e\C-e\er\C-m"'
  export FZF_ALT_C_COMMAND="command find -L . \( -path '*/\.*' -o -path '*/Library/*' -o -path '*/Applications/*' -o -path '*/bundle/*' -o -path '*.framework' -o -path '*.app' -o -fstype 'dev' -o -fstype 'proc' \) -prune -o -type d -print 2> /dev/null | sed 1d | cut -b3-"
  export FZF_DEFAULT_OPTS="--exact"
fi


if [ -f ~/.backblaze-key-id ]; then
  export B2_ACCOUNT_ID=`cat ~/.backblaze-key-id`
fi

if [ -f ~/.backblaze-key ]; then
  export B2_ACCOUNT_KEY=`cat ~/.backblaze-key`
fi

if [ -f ~/.restic-common-pw ]; then
  export RESTIC_PASSWORD_FILE=~/.restic-common-pw
  export RESTIC_REPOSITORY=b2:restic-common
fi

export DISABLE_SPRING=meh

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
if [ -d ~/.rvm ]; then
  export PATH="$PATH:$HOME/.rvm/bin"
fi

if [ -e /usr/local/opt/nvm/nvm.sh ]; then
  export NVM_DIR="$HOME/.nvm"
  . "/usr/local/opt/nvm/nvm.sh"
fi

export VOLTA_HOME="$HOME/.volta"
