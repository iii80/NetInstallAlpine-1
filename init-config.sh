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
apk update && apk add procps bash bash-completion vim curl wget net-tools docker docker-compose vnstat zram-init


# 配置
sed -i "s#/bin/ash#/bin/bash#g" /etc/passwd
cat >~/.bash_profile<<EOF
alias update='apk update && apk upgrade'
export HISTTIMEFORMAT="%d/%m/%y %T "
export PS1='\u@\h:\W \$ '
alias l='ls -CF'
alias la='ls -A'
alias ll='ls -alF'
alias ls='ls --color=auto'
source /etc/profile.d/bash_completion.sh
EOF
cat>/etc/conf.d/zram-init<<EOF
load_on_start=yes
unload_on_stop=yes

num_devices=1

type0=swap
flag0=
size0=`LC_ALL=C free -m | awk '/^Mem:/{print int($2/1)}'`
mlim0=`LC_ALL=C cat /proc/cpuinfo | grep "processor" | wc -l`
back0=
icmp0=
idle0=
wlim0=
notr0=
maxs0=1
algo0=zstd
labl0=zram_swap
uuid0=
args0=

EOF

# 服务自动
rc-service docker start
rc-service vnstatd start

# 添加开机自启
rc-update add docker
rc-update add vnstatd





