#!/bin/sh
# 清空 motd
echo ''>/etc/motd

# 换源
cat >/etc/apk/repositories <<EOF
http://dl-cdn.alpinelinux.org/alpine/latest-stable/main
http://dl-cdn.alpinelinux.org/alpine/latest-stable/community
http://dl-cdn.alpinelinux.org/alpine/edge/testing
EOF

# 优化 TCP 窗口
cat > /etc/sysctl.conf << EOF
net.ipv4.ip_forward = 1
net.ipv4.tcp_no_metrics_save=1
net.ipv4.tcp_ecn=0
net.ipv4.tcp_frto=0
net.ipv4.tcp_mtu_probing=0
net.ipv4.tcp_rfc1337=0
net.ipv4.tcp_sack=1
net.ipv4.tcp_fack=1
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_adv_win_scale=1
net.ipv4.tcp_moderate_rcvbuf=1
net.core.rmem_max=33554432
net.core.wmem_max=33554432
net.ipv4.tcp_rmem=4096 87380 33554432
net.ipv4.tcp_wmem=4096 16384 33554432
net.ipv4.udp_rmem_min=8192
net.ipv4.udp_wmem_min=8192
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.ipv4.ip_local_port_range=60000 65535
EOF
sysctl -p


# 软件安装
apk update && apk add coreutils iproute2 tzdata procps bash bash-completion vim curl wget net-tools docker docker-compose vnstat zram-init 

# 配置

sed "s#/opt/containerd#/var/lib/containerd/opt#g"  -i /etc/containerd/config.toml

cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
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
rc-service zram-init start

# 添加开机自启
rc-update add docker
rc-update add vnstatd
rc-update add zram-init




