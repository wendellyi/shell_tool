#! /bin/sh

ADD_SIPT_CONTENT=$(cat sipt_add.txt)

echo "USE IPS_3000;"
echo "$ADD_SIPT_CONTENT" | while read line; do
    account="$(echo $line | awk -F \n '{ print $1 }')"
    echo "INSERT INTO SipTAccount(Name,User,Pass,Host,Port,NTX,Type,iface,Regist,BindExtend,OutboundProxy,AuthName,Encrypt,AuthDigest) VALUES ('$account','$account','$account','imstest.jiahehecommunication.com',5061,0,'IMS','WAN',1,'','imstest.jiahehecommunication.com:5061','$account',0,0);"
done