#! /bin/sh

# 用于一键编译，复制与重启调试服务器程序

HOST=192.168.33.121
USER=root
PORT=30000

DOMAIN=${USER}@$HOST

make

if [ $? -ne 0 ]; then
    echo "*******************************************"
    echo "************** make failed! ***************"
    echo "*******************************************"
    exit
fi

ssh -p $PORT $DOMAIN "rm -fr /home/ippbx/rtpproxy/rtpproxy"
scp -P $PORT src/rtpproxy ${DOMAIN}:/home/ippbx/rtpproxy/
ssh -p $PORT $DOMAIN "chmod +x /home/ippbx/rtpproxy/rtpproxy && killall rtpproxy"



