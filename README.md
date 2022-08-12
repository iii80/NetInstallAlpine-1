### 原版: https://github.com/52fancy/NetInstallAlpine

### 添加了对静态IP的支持。

## 使用方法

```
sh <(curl -k 'https://raw.githubusercontent.com/unknwon0054/NetInstallAlpine/main/alpine.sh')
```

## 重启后用密钥连接SSH 进行安装

```
sed -i "s/#PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config
passwd
setup-interfaces
setup-keymap us us
setup-hostname -n us
setup-dns -d -n 8.8.8.8 -n 8.8.4.4
/etc/init.d/hostname --quiet restart
rc-update add networking boot
rc-update add urandom boot
rc-update add acpid
rc-update add crond
setup-ntp chrony
setup-sshd -c openssh
setup-disk -s 512 -m sys /dev/vda
```
