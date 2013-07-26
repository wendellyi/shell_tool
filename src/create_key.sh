#! /bin/sh

HOST=$1
USER=$2

DOMAIN=${USER}@$HOST

function usage() {
    echo "$S0 host user"
}

if [ $# -ne 2 ]; then
    usage
    exit
fi

# 连续三次回车,即在本地生成了公钥和私钥,不设置密码
ssh-keygen -t rsa 

# 需要输入密码
ssh -p 30000 $DOMAIN "mkdir .ssh"

# 需要输入密码
scp -P 30000 ~/.ssh/id_rsa.pub ${DOMAIN}:.ssh/id_rsa.pub

# 在远程主机上
ssh -p 30000 $DOMAIN "cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys"