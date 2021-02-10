# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

# User specific environment and startup programs

PATH=$PATH:$HOME/bin

export PATH

export DB_HOST={{ db_host }}
export DB_NAME={{ db_name }}
export DB_USER={{ db_user }}
export DB_PASSWORD={{ db_password }}
export RUBYOPT=-EUTF-8
