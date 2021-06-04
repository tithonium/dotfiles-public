if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi

if [ -e ~/.local_profile ]; then
  . ~/.local_profile
fi

if [ "$SSH_AUTH_SOCK" != "" ]; then
  # ssh-add ~/.ssh/id_[dr]sa ~/.ssh/*.pem ~/.ssh/*keypair ~/.ssh/*key 2> /dev/null
  ssh-add ~/.ssh/id_[dr]sa 2> /dev/null
fi

find ~/.ssh -type d -exec chmod 0700 {} \;
find ~/.ssh -type f -exec chmod 0600 {} \;
chmod 0644 ~/.ssh/config

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

if [ "`which rbenv`" != "" ]; then
  eval "$(rbenv init -)"
fi

[[ -x "$HOME/.ondir" ]] && source "$HOME/.ondir"

if [ ! -d ~/Dropbox/Dotfiles/ -a "`uname`" != "Darwin" ]; then
  selflink=`readlink -f $BASH_SOURCE`
  if [ -n "$selflink" ]; then
    selfdir=`dirname $selflink`
    selfdir=`dirname $selfdir`
    gitdir="${selfdir}/.git"
    lastupdate=`stat -c'%Y' ${gitdir}`
    lastupdate=`date '+%G%V' -d "@${lastupdate}"`
    now=`date '+%G%V'`
    if [ "$lastupdate" != "$now" ]; then
      echo -n "Updating dotfiles. Please wait..."
      ( cd ${selfdir} && ./home/bin/hack && perl install.pl && git tidy ) >/dev/null 2>&1
      touch $gitdir
      echo "done."
    fi
  fi
fi

if [ -d ~/.perl5 ]; then
  eval "$(perl -I$HOME/.perl5/lib/perl5 -Mlocal::lib=$HOME/.perl5)"
fi
