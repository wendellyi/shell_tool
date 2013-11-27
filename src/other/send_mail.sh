#! /bin/sh

# n: add user
# d: delete user
# m: modify conf
# i: conf id
# s: subject
# p: password
# t: time string
# l: conf duration
# c: chairman
# u: user list
# a: email address list

CONF_ID=
SUBJECT=
PASSWD="��"
TIME=
DURATION=
CHAIRMAN=
USER_LIST=
ADDR_LIST=
TYPE=
MAILQ_NUM=$(mailq | wc -l)

# Clean the mail queue if it's too long
if [ $MAILQ_NUM -ge 120 ]
then
    postsuper -d ALL
fi

# Time
echo $(date)

while getopts ndmi:s:p:t:l:c:u:a: option
do
    case "$option"
    in
    n ) TYPE=n ;;
    d ) TYPE=d ;;
    m ) TYPE=m ;;
    i ) CONF_ID="$OPTARG" ;;
    s ) SUBJECT="$OPTARG" ;;
    p ) PASSWD="$OPTARG" ;;
    t ) TIME="$OPTARG" ;;
    l ) DURATION=$OPTARG ;;
    c ) CHAIRMAN="$OPTARG" ;;
    u ) USER_LIST="$OPTARG" ;;
    a ) ADDR_LIST="$OPTARG" ;;
    * ) echo "Usage: send_mail.sh -n -i id -s subject [-p password] -t time -l duration -c chairman -u userlist -a addresslist"
        echo "usage: send_mail.sh -d -i id -s subject -a addresslist"
        echo "Usage: send_mail.sh -m -i id -s subject [-p password] -t time -l duration -c chairman -u userlist -a addresslist"
        echo "n: add user"
        echo "d: delete user"
        echo "m: modify conf"
        echo "i: conf id"
        echo "s: subject"
        echo "p: password"
        echo "t: time string"
        echo "l: conf duration"
        echo "c: chairman"
        echo "u: user list"
        echo "a: email address list"
        exit 1 ;;
    esac
done

# convert utf8 encoding to gbk
CONF_ID=$(echo -n $CONF_ID | iconv -f utf8 -t gbk)
SUBJECT=$(echo -n $SUBJECT | iconv -f utf8 -t gbk)
TIME=$(echo -n $TIME | iconv -f utf8 -t gbk)
CHAIRMAN=$(echo -n $CHAIRMAN | iconv -f utf8 -t gbk)
USER_LIST=$(echo -n $USER_LIST | iconv -f utf8 -t gbk)


if [ "n" = $TYPE ]
then
export LANG=zh_CN.gbk
mail -v -s "����֪ͨ" $ADDR_LIST << FINIS
[����֪ͨ]
ID: $CONF_ID
����: $SUBJECT
����: $PASSWD
ʱ��: $TIME
ʱ��: ${DURATION}����
������: $CHAIRMAN
�����: $USER_LIST
FINIS
fi

if [ "m" = $TYPE ]
then
export LANG=zh_CN.gbk
mail -v -s "����֪ͨ" $ADDR_LIST << FINIS
[�������֪ͨ]
ID: $CONF_ID
����: $SUBJECT
����: $PASSWD
ʱ��: $TIME
ʱ��: ${DURATION}����
������: $CHAIRMAN
�����: $USER_LIST
FINIS
fi

if [ "d" = $TYPE ]
then
export LANG=zh_CN.gbk
mail -v -s "����֪ͨ" $ADDR_LIST << FINIS
[�������֪ͨ]
    ���ã�����ԭ���ƻ��б䣬������������ϯ����Ϊ: $SUBJECT��ID: $CONF_ID���Ļ��飬
��֪ͨ������μӴ˴δ˴λ��顣����֪Ϥ��
    лл��
FINIS
fi
