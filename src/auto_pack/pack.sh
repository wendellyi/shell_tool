#!/bin/sh

CSV_FILE="UC-SYS_V1.05.csv"
VERSION=$1

TIMESTAMP_START=$(date +"%s")
./auto_pack.sh "$CSV_FILE" "$VERSION"
TIMESTAMP_END=$(date +"%s")

TIMESTAMP_DIFF=$(($TIMESTAMP_END-$TIMESTAMP_START))
MINUTES=$(($TIMESTAMP_DIFF/60))
SECONDS=$(($TIMESTAMP_DIFF%60))
printf "%-16s%-16s\n\n" "$(date +"%H:%M:%S")" "耗时 ${MINUTES}分${SECONDS}秒"
