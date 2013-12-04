#! /bin/sh

# 此脚本实现的功能是将svn.log文件中的程序版本号提取出来放入csv文件的指定字段中
# 主要使用了cut、grep、sed和awk等工具，包括简单的正则表达式

ARGS=$#
SRC_CSV=$1          # 第一个参数为csv文件名
SVN_LOG=$2          # 第二个参数为svn日志名
TMP_CSV=$3          # 第三个参数为新生成的目标

function usage ()
{
    printf "\tUsage:\n"
    printf "\tfill_svn_ver.sh file.csv svn.log target.svn\n"
}

if [ 3 -ne $ARGS ]
then
    usage
    exit
fi

# 使用正则表达式过滤掉无用的行（包括空行和无意义的行）
svn_log=$(cat $SVN_LOG | cut -d' ' -f2-100 | grep -Ev "^$" | grep -E "[0-9]+\s*$")
svn_line_count=$(echo "${svn_log}" | wc -l)
arr_svn_log[$svn_line_count]=

csv_file=$(cat $SRC_CSV)
csv_line_count=$(cat $SRC_CSV | wc -l);

# 将svn_log转化成数组
svn_line_idx=0          # shell的数组行索引从0开始
sed_line_idx=1          # sed的行索引从1开始
while [ $svn_line_idx -lt $svn_line_count ]
do
    arr_svn[$svn_line_idx]=$(echo "${svn_log}" | sed -n "${sed_line_idx}p")
    svn_line_idx=$((svn_line_idx+1))
    sed_line_idx=$((sed_line_idx+1))
done

# 为保证与原来的csv文件差异最小，这里外循环为csv文件，内循环通过匹配svn.log
# 程序版本来替换相应的程序的版本号
csv_line_idx=0
sed_line_idx=1
while [ $csv_line_idx -lt $csv_line_count ]
do
    csv_one_line=$(echo "$csv_file" | sed -n "${sed_line_idx}p")
    csv_prog_name=$(echo "$csv_one_line" | cut -d',' -f2);
    if [ -n "$csv_prog_name" ]
    then
        svn_line_idx=0
        while [ $svn_line_idx -lt $svn_line_count ]
        do
            svn_prog_name=$(echo ${arr_svn[$svn_line_idx]} | cut -d'=' -f1)
            svn_prog_name=$(echo $svn_prog_name)
            svn_prog_version=$(echo ${arr_svn[$svn_line_idx]} | cut -d'=' -f2)
            csv_prog_name=$(echo $csv_prog_name)
            if [ "$csv_prog_name" = "$svn_prog_name" ]
            then
                # 将实际的版本号赋值到指定的字段上（第5个字段）
                echo "$csv_one_line" | awk -F "," -v ver=$(echo $svn_prog_version) \
                    '{$5=ver; OFS=","; print $0}' >> $TMP_CSV
                break
            fi
            
            svn_line_idx=$((svn_line_idx+1))
        done

        # 如果没有匹配到任何svn日志记录，将此行原样打印
        if [ $svn_line_idx -eq $svn_line_count ]
        then
            echo $csv_one_line >> $TMP_CSV
        fi
    # 模块名称列为空，那么此行不合法，按原样打印
    else
        echo $csv_one_line >> $TMP_CSV
    fi
    
    csv_line_idx=$((csv_line_idx+1))
    sed_line_idx=$((sed_line_idx+1))
done
