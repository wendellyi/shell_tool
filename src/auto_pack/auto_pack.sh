#! /bin/sh

CSV_FILE=$1     # csv文件名
VERSION=$2      # 版本号
CURR_DIR=$(pwd)
CSV_CONTENT=$(cat $CSV_FILE)
STATE=""
CHECKOUT_LOG=${CURR_DIR}/$VERSION/checkout.log

mkdir -p .temp
cd .temp

# 名称：svn_checkout
# 功能：从指定的svn路径下下载源文件
# 返回值：使用echo返回checkout结果和版本号，通过:分割，
# 0代表工程文件没有更新，1代表有更新，2代表checkout失败
function svn_checkout()
{
    local app_name=$1               # 程序的名称
    local app_svn_path=$2           # 源代码的svn路径
    local app_svn_version=$3        # 源代码的svn版本
    
    mkdir -p "$app_name"
    cd $app_name
    local svn_output=""
    
    # 如果是文件而非目录，此处的输出是有问题的
    # 但是不会显现出来
    if [ 0 -eq "$app_svn_version" ]; then
        svn_output=$(svn co "$app_svn_path" 2>&1)                           # 下载最新版本
    else
        svn_output=$(svn co "$app_svn_path" -r "$app_svn_version" 2>&1)     # 下载指定版本
    fi    

    if echo "$svn_output" | grep "failed"; then
        echo "2:0"
        return
    fi
    
    local version=""
    if [ 0 -eq "$app_svn_version" ]; then
        version=$(svn info $app_svn_path | grep "Last Changed Rev" | awk -F ':' '{print $2}')
        version=$(echo $version)
    else
        version=$(echo "$svn_output" | grep "Checked out revision" | awk '{print $4}' | cut -d'.' -f1)
    fi

    local updated_count=$(echo "$svn_output" | grep -E "Makefile|configure" | wc -l)
    if [ 0 -eq $updated_count ]; then
        echo "0:$version"
    else
        echo "1:$version"
    fi
    
    if [ "$STATE" = "App" -o "$STATE" = "Config" ]; then
        echo "$(date +"%H:%M:%S") $app_name = $version" >> $CHECKOUT_LOG
    fi
    
    return
}

# 名称：make_app
# 功能：构建程序
# 调用build.sh或者make构建程序
# 返回值：0代表成功，1代表失败

# make_app "$app_name" "$app_makedir" "$app_target_subdir" "$app_target_srcname" "$app_target_dstname" "app_target_dstdir" "$checkout_rv"
function make_app()
{
    local app_name=$1               # 程序名称
    local app_makedir=$2            # 程序编译路径
    local app_target_subdir=$3      # 程序目标路径
    local app_target_srcname=$4     # 程序编译得到目标名称
    local app_target_dstname=$5     # 程序最终名称
    local app_target_dstdir=$6      # 程序的目的目录
    local checkout_rv=$7            # 使用make还是build.sh
    local curr_dir=$(pwd)
    
    cd "$app_name"
    cd "$app_makedir"
    if [ 0 -eq "$checkout_rv" ]; then       # 为0调用make，速度快
        if ! make > /dev/null 2>&1; then
            echo "1"
            cd $curr_dir
            return
        fi
    else                                    # 为1调用用build.sh，速度慢
        chmod +x build.sh
        dos2unix build.sh > /dev/null 2>&1
        ./build.sh > /dev/null 2>&1
    fi
# set -x    
    if ! cp ${app_target_subdir}/$app_target_srcname ${app_target_dstdir}/$app_target_dstname; then
        echo "1"
        cd $curr_dir
        return
    fi
# set +x
    
    cd $curr_dir    
    echo "0"
    return
}

# 名称：file_copy
# 功能：复制文件
# file_copy "$app_name" "$app_makedir" "$app_target_dstdir"
function file_copy()
{
    local app_name=$1
    local app_makedir=$2
    local app_target_dstdir=$3
    
    \cp ${app_name}/${app_makedir}/* "$app_target_dstdir" -f
}

# config_copy "$app_name" "$app_makedir" "$app_target_dstdir"
function config_copy()
{
    local app_name=$1
    local app_makedir=$2
    local app_target_dstdir=$3
    
    \cp ${app_name}/${app_makedir} "$app_target_dstdir" -Rf
}

function log_ok()
{
    local app_name=$1
    local curr_time=$(date)
    echo "$curr_time $app_name"
}

rm -fr ${CURR_DIR}/${VERSION}
mkdir -p "${CURR_DIR}/${VERSION}/updatefw"
mkdir -p "${CURR_DIR}/${VERSION}/exe"
mkdir -p "${CURR_DIR}/${VERSION}/doc"

clear
echo "##########################################################################"
echo "#                                                                        #"
echo "#                             auto packing ...                           #"
echo "#                                                                        #"
echo "##########################################################################"
printf "%-16s%-16s%-30s%-16s\n" "time" "status" "name" "subversion"
echo "--------------------------------------------------------------------------"
while read csv_line
do
    if [ -z "$csv_line" ]; then
        continue
    elif ! echo "$csv_line" | grep "http" > /dev/null; then
        continue
    fi
    
    # 调整编译脚本的全局状态
    first_field=$(echo "$csv_line" | awk -F ',' '{print $1}')
    case "$first_field" in
        "App" )
        STATE="App"
        ;;
        
        "Config" )
        STATE="Config"
        ;;
        
        "DependLib" )
        STATE="DependLib"
        ;;
        
        * )
        ;;
    esac
    
    app_name=$(echo "$csv_line" | awk -F ',' '{print $2}')              # 程序的名称
    app_enable=$(echo "$csv_line" | awk -F ',' '{print $3}')            # 程序是否编译
    app_svn_path=$(echo "$csv_line" | awk -F ',' '{print $4}')          # 源代码的svn路径
    app_makedir=$(basename "$app_svn_path")                             # 代码的编译路径
    app_version=$(echo "$csv_line" | awk -F ',' '{print $5}')           # 程序的svn版本号，可能是0
    app_target_subdir=$(echo "$csv_line" | awk -F ',' '{print $6}')     # 代码的目录
    app_target_srcname=$(echo "$csv_line" | awk -F ',' '{print $7}')    # 编译得到的文件名
    ntx_version=$(echo "$csv_line" | awk -F ',' '{print $8}')
    app_target_dstname=""                                               # 最终文件的名称，有程序名_V版本号_系统大版本号
    app_target_dstdir="${CURR_DIR}/${VERSION}/updatefw"                 # 目标目录
    
    # 检测app是否需要参与构建
    if [ 0 -eq "$app_enable" ]; then
        continue
    fi
    
    rv=$(svn_checkout "$app_name" "$app_svn_path" "$app_version")
    checkout_rv=$(echo "$rv" | cut -d':' -f1)
    checkout_version=$(echo "$rv" | cut -d':' -f2)
    if [ 2 -eq "$checkout_rv" ]; then
        echo "$app_name checkout failed"
        exit
    fi
    
    if [ "$STATE" = "App" ]; then        
        if [ 2 -eq "$app_enable" ]; then
            file_copy "$app_name" "$app_makedir" "$app_target_dstdir"
        else
            app_version=$(echo "$rv" | awk -F ":" '{print $2}')
            app_target_dstname="${app_name}_V${app_version}$ntx_version"
            rv=$(make_app "$app_name" "$app_makedir" "$app_target_subdir" "$app_target_srcname" "$app_target_dstname" "$app_target_dstdir" "$checkout_rv")
            if [ 0 -ne "$rv" ]; then
                echo "$app_name make failed"
                exit
            fi
        fi

        printf "%-16s%-16s%-30s%-16s\n" "$(date +"%H:%M:%S")" "OK" "$app_name" "$checkout_version"
    elif [ "$STATE" = "Config" ]; then
        app_target_dstdir="${CURR_DIR}/${VERSION}/updatefw"
        if [ "update.sh" = "$app_name" ]; then
            svn cat $app_svn_path > "$CURR_DIR/$VERSION/update.sh"
        else
            config_copy "$app_name" "$app_makedir" "$app_target_dstdir"
        fi

        printf "%-16s%-16s%-30s%-16s\n" "$(date +"%H:%M:%S")" "OK" "$app_name" "$checkout_version"
    elif [ "$STATE" = "DependLib" ]; then
        continue
    fi
done < $CURR_DIR/$CSV_FILE

find $app_target_dstdir -name ".svn" | xargs rm -fr

echo "[version]" > "${CURR_DIR}/${VERSION}/updatefw/version.ini"
echo version = $VERSION >> "${CURR_DIR}/${VERSION}/updatefw/version.ini"
echo "" >> "${CURR_DIR}/${VERSION}/updatefw/version.ini"
echo ": $CUR_TIME" >> "${CURR_DIR}/${VERSION}/updatefw/version.ini"
cd $CURR_DIR/$VERSION
echo "--------------------------------------------------------------------------"
printf "%-16s%-16s\n" "$(date +"%H:%M:%S")" "正在封包，请稍候 ..."
tar czf updatefw.tar.gz updatefw
rm -fr updatefw
mv update* exe

${CURR_DIR}/fill_svn_ver.sh "$CURR_DIR/$CSV_FILE" "$CHECKOUT_LOG" "${CURR_DIR}/$VERSION/doc/${VERSION}.csv"
rm -f $CHECKOUT_LOG