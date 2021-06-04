# Installation

## Linux

```
cd && if [ -d workspace/dotfiles ]; then
  cd workspace/dotfiles
  git fetch
  git pull origin master
else
 mkdir -p workspace
 cd workspace
 git clone git@github.com:tithonium/dotfiles.git
 cd dotfiles
fi && perl install.pl
```
## OSX

Set up Dropbox, then

```
cd ~/Dropbox/Dotfiles && perl install.pl
```

### OR

Use the Linux instructions above.

# Conflicts

Occasionally there are conflicts. The installer will not replace a file unless it contains identical content to the replacement.
If it is a new system, or one on which you have not done any customization, use

```
perl install.pl -f
```

Otherwise, diff the conflicts and figure out what needs to change.
