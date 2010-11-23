if [ -f ~/.bashrc ]; then
  source ~/.bashrc
fi

# MacPorts Installer addition on 2010-11-19_at_10:35:44: adding an appropriate PATH variable for use with MacPorts.
export PATH=/opt/local/bin:/opt/local/sbin:$PATH

# MacPorts Installer addition on 2010-11-19_at_10:35:44: adding an appropriate MANPATH variable for use with MacPorts.
export MANPATH=/opt/local/share/man:$MANPATH
