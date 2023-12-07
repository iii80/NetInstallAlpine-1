#!/bin/sh
# 清空 motd
echo ''>/etc/motd

# 换源
cat >/etc/apk/repositories <<EOF
http://dl-cdn.alpinelinux.org/alpine/latest-stable/main
http://dl-cdn.alpinelinux.org/alpine/latest-stable/community
http://dl-cdn.alpinelinux.org/alpine/edge/testing
EOF

# 开启BBR
rm -rf /etc/sysctl.d/*
cat <<EOF >/etc/sysctl.conf
fs.file-max = 1000000
fs.inotify.max_user_instances = 131072
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmall = 4294967296
kernel.shmmax = 68719476736
net.core.default_qdisc = fq
net.core.netdev_max_backlog = 4194304
net.core.rmem_max = 33554432
net.core.rps_sock_flow_entries = 65536
net.core.somaxconn = 65536
net.core.wmem_max = 33554432
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.forwarding = 1
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.all.route_localnet = 1
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.ip_forward = 1
net.ipv4.tcp_autocorking = 0
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_ecn = 0
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_fack = 1
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_frto = 0
net.ipv4.tcp_keepalive_intvl = 60
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_max_syn_backlog = 4194304
net.ipv4.tcp_max_tw_buckets = 262144
net.ipv4.tcp_mem = 786432 1048576 3145728
net.ipv4.tcp_moderate_rcvbuf = 1
net.ipv4.tcp_mtu_probing = 0
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_notsent_lowat = 16384
net.ipv4.tcp_orphan_retries = 1
net.ipv4.tcp_rmem = 16384 131072 67108864
net.ipv4.tcp_sack = 1
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_syn_retries = 3
net.ipv4.tcp_synack_retries = 3
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_wmem = 4096 16384 33554432
net.ipv4.ping_group_range = 0 2147483647
net.ipv4.ip_local_port_range = 50000 65535
net.ipv6.conf.all.accept_ra=2
net.ipv6.conf.all.autoconf=1
net.netfilter.nf_conntrack_max = 65535
net.netfilter.nf_conntrack_buckets = 16384
net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 30
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 30
net.netfilter.nf_conntrack_tcp_timeout_close_wait = 15
net.netfilter.nf_conntrack_tcp_timeout_established = 300
vm.dirty_background_bytes = 52428800
vm.dirty_background_ratio = 0
vm.dirty_bytes = 52428800
vm.dirty_ratio = 40
vm.swappiness = 20
EOF

total_memory=$(grep MemTotal /proc/meminfo | awk '{print $2}')
total_memory_bytes=$((total_memory * 1024))
total_memory_gb=$(awk "BEGIN {printf \"%.2f\", $total_memory / 1024 / 1024}")
nf_conntrack_max=$((total_memory_bytes / 16384 ))
nf_conntrack_buckets=$((nf_conntrack_max / 4))
sed -i "s#.*net.netfilter.nf_conntrack_max = .*#net.netfilter.nf_conntrack_max = ${nf_conntrack_max}#g" /etc/sysctl.conf
sed -i "s#.*net.netfilter.nf_conntrack_buckets = .*#net.netfilter.nf_conntrack_buckets = ${nf_conntrack_buckets}#g" /etc/sysctl.conf
#<4GB 1G_3G_8G
if [[ ${total_memory_gb//.*/} -lt 4 ]]; then    
    sed -i "s#.*net.ipv4.tcp_mem =.*#net.ipv4.tcp_mem =262144 786432 2097152#g" /etc/sysctl.conf
#6GB 2G_4G_8G
elif [[ ${total_memory_gb//.*/} -ge 4 && ${total_memory_gb//.*/} -lt 7 ]]; then
    sed -i "s#.*net.ipv4.tcp_mem =.*#net.ipv4.tcp_mem =524288 1048576 2097152#g" /etc/sysctl.conf
#8GB 3G_4G_12G
elif [[ ${total_memory_gb//.*/} -ge 7 && ${total_memory_gb//.*/} -lt 11 ]]; then    
    sed -i "s#.*net.ipv4.tcp_mem =.*#net.ipv4.tcp_mem =786432 1048576 3145728#g" /etc/sysctl.conf
#12GB 4G_6G_12G
elif [[ ${total_memory_gb//.*/} -ge 11 && ${total_memory_gb//.*/} -lt 15 ]]; then    
    sed -i "s#.*net.ipv4.tcp_mem =.*#net.ipv4.tcp_mem =1048576 1572864 3145728#g" /etc/sysctl.conf
#>16GB 4G_8G_12G
elif [[ ${total_memory_gb//.*/} -ge 15 ]]; then
    sed -i "s#.*net.ipv4.tcp_mem =.*#net.ipv4.tcp_mem =1048576 2097152 3145728#g" /etc/sysctl.conf
fi
sysctl -p &> /dev/null


# sed -i "s#.*net.netfilter.nf_conntrack_max=.*#net.netfilter.nf_conntrack_max=$nf_conntrack_max#g" /etc/sysctl.conf
# sed -i "s#.*net.netfilter.nf_conntrack_buckets=.*#net.netfilter.nf_conntrack_buckets=$nf_conntrack_buckets#g" /etc/sysctl.conf


# 软件安装
apk update && apk add coreutils iproute2 tzdata procps bash bash-completion vim curl wget net-tools docker docker-compose vnstat zram-init


# 配置

mkdir -p /var/lib/containerd/opt && sed "s#/opt/containerd#/var/lib/containerd/opt#g"  -i /etc/containerd/config.toml

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

sleep 5
while [ -d /opt/containerd ]
do
  rm -rf /opt/containerd/
done




