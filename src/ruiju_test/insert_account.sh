#! /bin/sh

PBX_HEAD=
ACCOUNT_RANGE=
DOD_RANGE=
IMS_ACCOUNT=
AA_ACCOUNT=
DATA_CONTENT=$(cat account.txt)
VIRTUAL_PBX_IDX=1
ROUTE_GROUP_NO=5
ROUTE_PLAN_NO=10

NAME_MAP=$(cat << EOF
100,109,ywj
110,119,chy
120,129,wky
130,139,wty
140,157,zcc
158,178,ywj
179,199,chy
200,220,wky
221,241,zcc
242,399,chy
EOF
)

function conv_range_to_name ()
{
    pbx_idx=$1
    echo "$NAME_MAP" | while read line; do
        beg_pbx=$(echo "$line" | cut -d',' -f 1)
        end_pbx=$(echo "$line" | cut -d',' -f 2)
        name=$(echo "$line" | cut -d',' -f 3)
        if [ $pbx_idx -ge $beg_pbx -a $pbx_idx -le $end_pbx ]
        then
            echo "$name"
        fi
    done
}

function produce_sql_dod ()
{
    pbx_head="$1"
    account_range="$2"
    dod_range="$3"

    beg_account=$(echo "$account_range" | cut -d'-' -f 1)
    end_account=$(echo "$account_range" | cut -d'-' -f 2)
    beg_dod=$(echo "$dod_range" | cut -d'-' -f 1)

    # 创建虚拟pbx帐号
    pbx_name=$(conv_range_to_name $pbx_head)
    echo "INSERT INTO VirtualPbx VALUES ($VIRTUAL_PBX_IDX, '$pbx_name$pbx_head', $pbx_head);"

    # 向此pbx帐号中插入路由组名称, group number全局唯一
    route_group_name="$pbx_name${pbx_head}"
    echo "INSERT INTO RouteGroupName VALUES ($ROUTE_GROUP_NO, '$route_group_name', $VIRTUAL_PBX_IDX);"
    echo "INSERT INTO RouteGroup VALUES ($ROUTE_GROUP_NO, 'VM',0,0,0,0,0,1,$VIRTUAL_PBX_IDX,0,0);"

    # 向此路由组中加入路由条目
    echo "INSERT INTO RouteGroup VALUES ($ROUTE_GROUP_NO, 'R0', 0, 0, 0, 0, 1, 1, $VIRTUAL_PBX_IDX, 0, 0);"

    # 加入路由计划，首先添加路由计划名称，然后增加条目
    route_plan_name="$pbx_name${pbx_head}"
    echo "INSERT INTO RoutePlanName VALUES ($ROUTE_PLAN_NO, '$route_plan_name', $VIRTUAL_PBX_IDX);"
    echo "INSERT INTO RoutePlan VALUES ('$ROUTE_PLAN_NO', '1', '0', '6', '00:00:00', '23:59:59', $ROUTE_GROUP_NO, '0', $VIRTUAL_PBX_IDX);"

    # 现在该是插入帐号的时候了
    while [ $beg_account -le $end_account ]
    do
        long_account="$pbx_head$beg_account"
        short_account="$beg_account"
        if [ -n "$dod_range" ]
        then
            echo "INSERT INTO User VALUES ('$long_account', '', '$short_account', '90', '0', '$ROUTE_PLAN_NO', '', ' none', '1', '', '', 'NONE', '', '0', '0', '0', '0', '0', '', '3', '$beg_dod', NULL, NULL, NULL, NULL, NULL, $ROUTE_PLAN_NO, NULL, '0', '6', '0', '0', '0', '0', '0', $VIRTUAL_PBX_IDX, '$short_account', '0', '0', NULL, '0', '0', '0', '0', '0', NULL, '1', '0', NULL);"
            echo "DELETE FROM UserDial WHERE UserID = '$long_account';"
            echo "INSERT INTO UserDial VALUES ('(null)', '$long_account');"
            beg_account=$((beg_account+1))
            beg_dod=$((beg_dod+1))
        else
            echo "INSERT INTO User VALUES ('$long_account', '', '$short_account', '90', '0', '$ROUTE_PLAN_NO', '', ' none', '1', '', '', 'NONE', '', '0', '0', '0', '0', '0', '', '3', NULL, NULL, NULL, NULL, NULL, NULL, $ROUTE_PLAN_NO, NULL, '0', '6', '0', '0', '0', '0', '0', $VIRTUAL_PBX_IDX, '$short_account', '0', '0', NULL, '0', '0', '0', '0', '0', NULL, '1', '0', NULL);"
            echo "DELETE FROM UserDial WHERE UserID = '$long_account';"
            echo "INSERT INTO UserDial VALUES ('(null)', '$long_account');"
            beg_account=$((beg_account+1))
        fi
    done

    # 下面的这些值都是全局唯一的
    VIRTUAL_PBX_IDX=$((VIRTUAL_PBX_IDX+1))
    ROUTE_GROUP_NO=$((ROUTE_GROUP_NO+1))
    ROUTE_PLAN_NO=$((ROUTE_PLAN_NO+1))
}

# function produce_sql_no_dod ()
# {
#     return 0
# }

PBX_IDX=1
echo "$DATA_CONTENT" | while read line; do    
    PBX_HEAD=$(echo $line | awk -F "," '{ print $1 }')
    ACCOUNT_RANGE=$(echo $line | awk -F "," '{ print $2 }')
    DOD_RANGE="$(echo $line | awk -F "," '{ print $3 }')"
    IMS_ACCOUNT="$(echo $line | awk -F "," '{ print $4 }')"
    AA_ACCOUNT="$(echo $line | awk -F "," '{ print $5 }')"

    echo "USE IPS_3000;"
    produce_sql_dod $PBX_HEAD $ACCOUNT_RANGE $DOD_RANGE
done


