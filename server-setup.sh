#!/bin/bash
#
# Description: Auto config you server script
#
# Copyright (C) 2017 Jae Liu <jae.liu11@gmail.com>
#




OSVersion=("Ubuntu" "Debian" "CentOS");

curUser=`who am i | awk '{print $1}'`
echo "Info: Current User: "$curUser

if [ `whoami` != "root" ]; then
    echo "Error: This script must run with Administrator!"
    exit
fi

curOSVersion=`cat /etc/issue | grep -o -E "^\b\w+\b"`

echo "Info: Update Applications"
if [[ $curOSVersion = ${OSVersion[0]} || $curOSVersion = ${OSVersion[1]} ]]; then
    #apt-get update
    echo
elif [ $curOSVersion = ${OSVersion[2]} ]; then
    yum update
fi

echo "Info: Config Vim"
which vim
if [ $? -ne 0 ]; then
    echo "Info: Vim is not installed, install it first!" 
    if [[ $curOSVersion = ${OSVersion[0]} || $curOSVersion = ${OSVersion[1]} ]]; then
        apt-get install vim 
    elif [ $curOSVersion = ${OSVersion[2]} ]; then
        yum -y install vim 
    fi
fi

path=$(cd `dirname $0`; pwd)
echo 'Path: '$path
echo "$(pwd)"

vimrcFilePath=$(cd `dirname $0`; pwd)"/.vimrc"
if [ -f $vimrcFilePath ]; then
    cp $vimrcFilePath ~/
    chown ${curUser}:${curUser} ~/.vimrc
fi

if [ ! -d ~/.vim ]; then
    echo "Info: .vim folder is not there, create it"
    mkdir ~/.vim
    chown $curUser:$curUser ~/.vim
fi


# Install Vim color scheme
if [ ! -d ~/.vim/colors ]; then
    mkdir ~/.vim/colors
    chown ${curUser}:${curUser}  ~/.vim/colors
fi
if [ ! -f ~/.vim/colors/solarized.vim ]; then
    echo "Tomorrow.vim is not there"
    git clone https://github.com/altercation/vim-colors-solarized.git /tmp/vim-colors-solarized
    mv /tmp/vim-colors-solarized/colors/*.vim ~/.vim/colors/
fi
rm -rf /tmp/vim-colors-solarized

if [ ! -f ~/.vim/colors/Tomorrow.vim ]; then
    echo "Tomorrow.vim is not there"
    git clone https://github.com/chriskempson/tomorrow-theme.git /tmp/tomorrow-theme
    mv /tmp/tomorrow-theme/vim/colors/*.vim ~/.vim/colors/
fi
rm -rf /tmp/tomorrow-theme

# copy screen configuration
screenFilePath=$(cd `dirname $0`; pwd)"/.screenrc"
if [ -f $screenFilePath ]; then 
    cp $screenFilePath ~/
    chown $curUser:$curUser ~/.screenrc
fi

# Install Vim Vundle
if [ -d ~/.vim/bundle/Vundle.vim ]; then
    cd ~/.vim/bundle/Vundle.vim
    git pull
else
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
fi


# Install Git
which git
if [ $? -ne 0 ]; then
    echo "Info: Git is not installed, install it first!" 
    if [[ $curOSVersion = ${OSVersion[0]} || $curOSVersion = ${OSVersion[1]} ]]; then
        apt-get install git 
    elif [ $curOSVersion = ${OSVersion[2]} ]; then
        yum -y install git
    fi

fi

if [ 1 ]; then
    echo "Config Git"
    git config --global user.name "Jae Liu"
    #git config --global user.email ling32945@sina.com
    git config --global core.editor vim
    git config --global merge.tool vimdiff

    git config --global color.status auto
    git config --global color.diff auto
    git config --global color.branch auto
    git config --global color.interactive auto
fi


echo "Info: Add User Group Web"
#grep -E ":600:" /etc/group >& /dev/null
#if [ $? -ne 0 ]; then
    #echo "Group ID 600 not found"
    
    grep -E "^web" /etc/group >& /dev/null
    if [ $? -ne 0 ]; then
        echo "Info: Group web not found, add user group web"
        groupadd web
    fi
#fi

gidOfWeb=`awk 'BEGIN{FS=":"} $1=="web" {print $3}' /etc/group`
#echo "Gid of web: "$gidOfWeb

id $curUser | grep $gidOfWeb
if [ $? -ne 0 ]; then
    gpasswd -a $curUser web
fi

if [[ $curOSVersion = ${OSVersion[0]} || $curOSVersion = ${OSVersion[1]} ]]; then
    id www-data 
    if [ $? -eq 0 ]; then
        echo "Info: Add user www-data to user group web"
        gpasswd -a www-data web
    fi
elif [ $curOSVersion = ${OSVersion[2]} ]; then
    id apache 
    if [ $? -eq 0 ]; then
        echo "Info: Add user apache to user group web"
        gpasswd -a www-data web
    fi
fi

grep -E "^app" /etc/group >& /dev/null
if [ $? -ne 0 ]; then
    echo "Group app not fount"
    groupadd app
fi

gidOfApp=`awk 'BEGIN{FS=":"} $1=="app" {print $3}' /etc/group`
#echo "Gid of app: "$gidOfApp

id $curUser | grep $gidOfApp
if [ $? -ne 0 ]; then
    gpasswd -a $curUser app
fi


# config history
grep "history config" /etc/profile
if [ $? -ne 0 ]; then
    cat << EOF >> /etc/profile

# history config
HISTTIMEFORMAT='%F %T '
HISTSIZE="5000"
HISTFILESIZE=5000
#HISTCONTROL=ignoredups
#HISTCONTROL=ignorespace
HISTCONTROL=ignorespace:erasedups
shopt -s histappend
PROMPT_COMMAND="history -a"
EOF
fi

# config PS1
grep "PS1 config" /etc/profile
if [ $? -ne 0 ]; then
    cat << EOF >> /etc/profile

# PS1 config
PS1='\[\e[37;1m[\]\[\e[31;1m\]\u\[\e[39;1m\]@\[\e[33;1m\]\H \[\e[34;1m\]\w\[\e[37;1m\]]\n\[\e[32;1m\]\\$ \[\e[0m\]'
EOF
fi


exit;

