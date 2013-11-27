#! /bin/sh

beg="$1"
end="$2"

account="$beg"
while [ "$account" -lt "$end" ]
do
    echo "INSERT INTO User VALUES ('$acount', '', $acount, '90', '0', 0, '', 'none', '1', '', '', 'NONE', '', '0', '0', '0', '0', '0', '', '3', NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, '0', '6', '0', '0', '0', '0', '0', 0, NULL, '0', '0', NULL, '0', '0', '0', '0', '0', NULL, '1', '0', NULL);"
    echo "DELETE FROM UserDial WHERE UserID = '$acount';"
    echo "INSERT INTO UserDial VALUES ('(null)', '$acount');"
    
    account=$((account+1))
done

