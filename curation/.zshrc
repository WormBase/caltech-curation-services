
limit coredumpsize 0

bindkey -v
stty erase 

export EDITOR=/usr/bin/vim

# export PATH=/usr/local/j2sdk1.3.1/bin:$PATH
# export PATH=/usr/java/j2re1.4.2_04/bin:$PATH
export JAVA_HOME=/usr/java/jdk1.6.0_03
export PATH=/usr/java/default/bin:$PATH
export PATH=/usr/X11R6/bin/:$PATH
export PATH=/home/azurebrd/installs/apache-ant-1.7.0/bin/:$PATH
export PATH=/usr/bin/mh/:$PATH
export CLASSPATH=/usr/share/java/postgresql-8.2-504.jdbc4.jar:$CLASSPATH

export PAGER=/bin/more
export HISTSIZE=1000

echo -e "\e[2 q"	# disable blinking cursor in windows terminal
alias noblink='echo -e "\e[2 q"'	# disable blinking cursor in windows terminal

# swap capslock and backspace with this script
alias caps='/usr/bin/xmodmap ~/.caps_back'


alias cp='cp -i'
alias mv='mv -i'
alias less='less -E'
alias d='rmm;n'
alias a='rf +spam;n'
alias mc='mailcheck'
alias lo='logout'
alias z='zwrite'
# alias t='telnet'
alias c='clear'
alias ls='ls -F'
alias la='ls -a'
alias lg='ls -g'
alias ll='ls -l'
alias lt='ls -lrt'
alias lal='ls -al'
alias lag='ls -ag'
alias lagm='ls -ag | less'
alias sz='source ~/.zshrc'


alias ds='du -h --max-depth=1'

alias sx='startx'

alias less='less -m'
alias mroe='more'
alias h='history'
alias gerp='grep -A10'

# PROMPT="%m-%15<..<%/-%!</home/azurebrd/www/cgi/counter.bin; can counterfile<: "
PROMPT="dtaz-%15<..<%/-%!: "
# RRPROMPT="(%m) ugcs %B%T%b%(0?,, [exit %?])"
RRPROMPT="%([cat counter]?)"
# (0?,, [exit %?])"

# setenv RPS1 "%w %* "
export RPS1="%w %* "
