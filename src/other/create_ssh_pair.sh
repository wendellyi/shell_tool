#! /bin/sh

# 这个脚本用于在对端服务器上生成和本端配套的公钥
# 以便登录和执行对端服务器上命令时免去输入密码

function usage()
{
    echo "$0 ip port user"
}

if [ 3 -gt $# ]; then
    echo "wrong parameter number"
    usage
    exit
fi

HOST_ADDR=$1
SSH_PORT=$2
USER=$3

echo "生成本地公钥和私钥，敲三次回车"
yes | ssh-keygen -t rsa

echo "到对端服务器${USER}用户的目录中创建.ssh目录，需要输入密码"
ssh -p $SSH_PORT ${USER}@${HOST_ADDR} "mkdir .ssh"

echo "将本地公钥拷贝到对方目录下，需要输入密码"
scp -P $SSH_PORT ~/.ssh/id_rsa.pub ${USER}@${HOST_ADDR}:.ssh/id_rsa.pub

echo "在对端机器上执行“touch ${USER}/.ssh/authorized_keys”，需要输入密码"
ssh -p $SSH_PORT ${USER}@${HOST_ADDR} "touch ~/.ssh/authorized_keys"

echo "将公钥导入对方的认证列表中，需要输入密码"
ssh -p $SSH_PORT ${USER}@${HOST_ADDR} "cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys"
