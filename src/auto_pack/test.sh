#! /bin/sh

while read line
do
    if [ -z "$line" ]; then
        echo "ok"
    elif ! echo "$line" | grep "http" > /dev/null; then
        echo "ok"
    fi
done < UC-SYS_V1.05.csv