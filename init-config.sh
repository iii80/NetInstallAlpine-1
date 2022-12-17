#!/bin/sh
# 清空 motd
echo ''>/etc/motd

# 换源
cat >/etc/apk/repositories <<EOF
http://dl-cdn.alpinelinux.org/alpine/latest-stable/main
http://dl-cdn.alpinelinux.org/alpine/latest-stable/community
EOF

# 开启 BBR
cat >/etc/sysctl.conf<<EOF
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.ipv4.ip_local_port_range=60000 65535
EOF
sysctl -p

# 软件安装
apk update && apk add procps bash bash-completion vim curl wget net-tools docker docker-compose vnstatd
sed -i "s#/bin/ash#/bin/bash#g" /etc/passwd

# 服务自动
rc-service docker start

# 添加开机自启
rc-update add docker

# 配置

cat >~/.bash_profile<<EOF
alias update='apk update && apk upgrade'
export HISTTIMEFORMAT="%d/%m/%y %T "
export PS1='\u@\h:\W \$ '
alias l='ls -CF'
alias la='ls -A'
alias ll='ls -alF'
alias ls='ls --color=auto'
source /etc/profile.d/bash_completion.sh
export PS1="\[\e[31m\][\[\e[m\]\[\e[38;5;172m\]\u\[\e[m\]@\[\e[38;5;153m\]\h\[\e[m\] \[\e[38;5;214m\]\W\[\e[m\]\[\e[31m\]]\[\e[m\]\\$ "
EOF



