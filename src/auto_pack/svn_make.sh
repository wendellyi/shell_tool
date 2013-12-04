#!/bin/sh

#****************************************全局变量***************************************
m_CurrentPath=`pwd`"/"					#获取当前目录
m_UpdatePath="updatefw/"				#需要打包的目录名称
m_PcakName="updatefw.tar.gz"			#需要打包的压缩包名称
m_LogFile="pack.log"					#写日志的文件名
m_LogSVN="svn.log"                      #写SVN版本号
m_NTXVersionFile="version.ini"			#NTX升级包的版本说明文件
m_SVNUser="cc-zhou" 					#SVN的帐号
m_SVNPassword="3612288"				#SVN的密码
m_SVNVersion=""							#SVN版本号，用于保存在checkout下载时获取的最新版本号
m_BuildScript="build.sh"				#App程序build的.sh文件名
m_SVNLastPath=""						#SVN源码的最后一个路径 指的是下面的中 gsoap/
										#svn://192.168.0.59/repos/edu/test/gsoap
m_CSVDir=""								#CSV文件的路径，不含文件名，如/home/
m_CSVFile="$1"							#CSV文件的名称，如sysconfig.csv
m_CSVRowsCount=0						#CSV文件的行数
m_CSVColumnsCount=10					#CSV文件的列数 此值是固定的
m_CSVLineArr[m_CSVColumnsCount]=""		#CSV文件一行的内容 保存为一个数组
m_CSVLastFunction=""					#读取CSV文件时 上一次的功能名称 
										#值只能是App Config DependLib
m_CSVCurrentLineStr=""					#CSV文件当前行的内容
m_CSVCurrentLineID=1					#CSV文件当前行的序号
m_ErrInfo=""							#错误信息
#***************************************************************************************

#****************************************************************************************
#Funtion	：打印日志（void）
#parameter	：$1	需要写的字符串
#Return		：NONE
#Date		：2012-12-14
#Auth		：LiJun
#****************************************************************************************
function WriteLog()
{
	local Str="$1"
	local sTime=`date |awk '{print $4}'`
	echo "$sTime"  "$Str"
	echo "$sTime"  "$Str" >> "$m_CurrentPath""$m_LogFile"
}

#****************************************************************************************
#Funtion	：打印SVN日志（void）
#parameter	：$1	需要写的字符串
#Return		：NONE
#Date		：2013-06-07
#Auth		：LiJun
#****************************************************************************************
function WriteSVN()
{
	local Str="$1"
	local sTime=`date |awk '{print $4}'`
	echo "$sTime"  "$Str" >> "$m_CurrentPath""$m_LogSVN"
}

#****************************************************************************************
#Funtion	：获取字符串的长度（int）
#parameter	：$1	字符串
#Return		：$?	>0（成功）  0（失败）
#Date		：2012-12-08
#Auth		：LiJun
#****************************************************************************************
function Str_Length()
{
	local Str=$1			#源字符串
	local nStrLength=0		#字符串长度
	
	#获取字符串的长度
	nStrLength=${#Str}
	if [ $? -eq 0 ] ; then
		return $nStrLength
	else
		nStrLength=0
		return $nStrLength
	fi
}

#****************************************************************************************
#Funtion	：判断字符串是否为空（int）
#parameter	：$1	字符串
#Return		：$?	0（成功）  1（失败）
#Date		：2012-12-08
#Auth		：LiJun
#****************************************************************************************
function Str_IsNull()
{
	local Str=$1			#源字符串
	local nStrLength=1		#字符串的长度
	
	#如果字符串为空则退出
	if [ "$Str" = "" ] ; then
		nStrLength=1
		return $nStrLength
	else
		nStrLength=0
		return $nStrLength
	fi
}

#****************************************************************************************
#Funtion	：获取指字符串出现的位置，位置是从1算起的（int）
#parameter	：$1	源字符串
#			  $2	需要查找的字符串
#Return		：$?	>0（成功）  0（失败）
#Date		：2012-12-08
#Auth		：LiJun
#****************************************************************************************
function Str_IndexOf()
{
	local SourceStr="$1"		#源字符串
	local SearchStr="$2"		#需要查找的字符串
	local nStrIndex=0			#返回字符串的位置
	
	#echo "$SourceStr"
	#echo "$SearchStr"
	
	#如果字符串为空则退出
	if [ "$SourceStr" = "" ] ; then
		return $nStrIndex
	fi
	
	if [ "$SearchStr" = "" ] ; then
		return $nStrIndex
	fi
	
	#查找字符串
	nStrIndex=`expr index  "$SourceStr" "$SearchStr" 2> /dev/null`
	if [ $? -ne 0 ] ; then
		nStrIndex=0

		return $nStrIndex
	fi
	
	return $nStrIndex
}

#****************************************************************************************
#Funtion	：从字符串指定位置开始截取指定长度的字符串并返回（string）
#parameter	：$1	源字符串
#			  $2	开始截取位置，从1开始
#			  $3	截取长度
#Return		：不为空（成功）  为空（失败）
#			  调试方法：
#						1）打印返回值 echo `Str_SubString "ab cd" 2 3` 返回b c
#						2）设置一个全局变量，将返回结果赋值给全局变量
#						3）调用该语句并返回结果 str=`Str_SubString "ab cd" 2 3`
#												echo $str
#Date		：2012-12-09
#Auth		：LiJun
#****************************************************************************************
function Str_SubString()
{
	local SourceStr="$1"			#源字符串
	local StrIndex=$2			#开始截取位置
	local StrLength=$3			#截取字符串的长度
	local StrTotalLenght=0		#字符串的总长度 用于非法验证
	local StrSubString=""		#返回结果

	#如果字符串为空则退出
	if [ "$SourceStr" = "" ] ; then
		#echo "1001"
		echo $StrSubString
		return
	fi
	
	if [ "$StrIndex" = "" ] ; then
		#echo "1002"
		echo $StrSubString
		return
	fi
	
	if [ "$StrLength" = "" ] ; then
		#echo "1003"
		echo $StrSubString
		return
	fi
	
	#判断 StrIndex和StrLength是否超过Str的总长度
	Str_Length "$SourceStr"
	StrTotalLenght=$?
	
	if [ $((StrIndex)) -lt 1 ] ; then
		#echo "1004"
		echo $StrSubString
		return
	fi
	
	if [ $((StrLength)) -lt 1 ] ; then
		#echo "1005"
		echo $StrSubString
		return
	fi
	
	#如果总长度小于开始字符位置则出错
	if [ $((StrTotalLenght)) -lt $((StrIndex)) ] ; then
		#echo "1006"
		echo $StrSubString
		return
	fi
	
	#如果总长度小于开始位置加截取长度
	if [ $(($StrTotalLenght)) -lt $(($StrIndex+$StrLength-1)) ] ; then
		#echo "1007"
		echo $StrSubString
		return
	fi
	
	# echo "源字符串：$SourceStr"
	# echo "开始位置：$StrIndex"
	# echo "截取长度：$StrLength"
	# echo "字符长度：$StrTotalLenght"

	#取出指定位置指定长度的子字符串
	StrSubString=`expr substr "$SourceStr" $StrIndex $StrLength`
	
	echo $StrSubString
	return
}

#****************************************************************************************
#Funtion	：替换字符串（string）
#parameter	：$1	源字符串
#			  $2	旧字符串
#			  $3	新字符串 用于替换
#Return		：不为空（成功）  为空（失败）
#			  调试方法：
#						1）打印返回值 echo `Str_Replace "c:/windows/boot.ini" '/' '\\'` 返回 c:\windows\boot.ini
#						2）设置一个全局变量，将返回结果赋值给全局变量
#						3）调用该语句并返回结果 str=`Str_Replace "c:/windows/boot.ini" '/' '\\'`
#												echo $str
#Date		：2012-12-13
#Auth		：LiJun
#****************************************************************************************
function Str_Replace()
{
	local SourceStr=$1			#源字符串
	local StrOld=$2				#旧字符串
	local StrNew=$3				#新字符串 用于替换
	local StrSubString=""		#返回结果
	
	#如果字符串为空则退出
	if [ "$SourceStr" = "" ] ; then
		#echo "1001"
		echo $StrSubString
		return
	fi
	
	if [ "$StrOld" = "" ] ; then
		#echo "1002"
		echo $StrSubString
		return
	fi
	
	#查找是否存在此字符串 并验证返回结果是否为空
	Str_IndexOf "$SourceStr" "$StrOld"
	
	if [ $? -eq 0 ] ; then
		#echo "1003"
		echo $StrSubString
		return
	fi
	StrSubString=${SourceStr//$StrOld/$StrNew}
	echo $StrSubString
	return
}

#****************************************************************************************
#Funtion	：获取文件的总行数(int)
#			  注：如果文件最后一行为空可能获取不到
#parameter	：$1	文件路径
#Return		：$?	>0（文件行数）  0（文件行数为空或不存在）
#Date		：2012-12-13
#Auth		：LiJun
#****************************************************************************************
function GetFileRowsCount()
{
	local FilePath=$1			#文件路径
	local RowsCount=0			#文件行数
	
	if [ ! -f $FilePath ] ; then
		return $RowsCount
	fi
	
	RowsCount=`awk '{print NR}' "$FilePath" | tail -n1`
	return $RowsCount
}

#***************************************************************************************
#Funtion	：创建目录，支持多级(int)
#parameter	：$1	在什么目录下进行创建  /home/
#			  $2	创建的目录，例 aa/bb/cc/dd    
#				    注意：如果是/aa/bb/cc/dd则在根目录下创建了
#Return		：$?	0（成功）  1（参数1目录不能为空）  2（参数2目录不能为空）  3（创建的目录不存在）
#Date		：2012-12-08
#Auth		：LiJun
#***************************************************************************************
function CreatePath()
{
	local SourcePath=$1
	local DestPath=$2
	local nResult=1
	
	if [ -z "$SourcePath" ] ; then
		nResult=1
		return $nResult
	fi
	
	if [ -z "$DestPath" ] ; then
		nResult=2
		return $nResult
	fi
	
	cd $SourcePath
	mkdir -p $DestPath
	
	#判断目录是否存在
	if [ ! -d $DestPath ] ; then
		cd $m_CurrentPath
		nResult=3
		return $nResult
	fi
	
	cd $m_CurrentPath
	nResult=0
	
	return $nResult
}

#****************************************************************************************
#Funtion	：判断是否SVN是否登录成功 以是否能取到指定目录的日志为依据 如果取不到则没有登
#			  录(int)
#parameter	：NONE
#Return		：$?	成功返回0 失败返回1
#Date		：2012-12-08
#Auth		：LiJun
#****************************************************************************************
function SVN_IsLogin()
{
	local SVNLogPath="test"		#SVN取日志的目录
	local CmdEcho=`svn log $SVNLogPath 2> /dev/null`
	local nResult=1
	
	if [ "$CmdEcho" = "" ] ; then
		nResult=1
	else
		nResult=0
	fi
	
	return $nResult
}

#****************************************************************************************
#Funtion	：从SVN服务器上下载指定目录文件到指定目录中(int)
#parameter	：$1	SVN源代码路径 如 svn://192.168.0.59/repos/edu/test/ippbx/lib/include/
#			  $2	下载到本地哪个目录中
#			  $3	更新至哪个版本
#			  $4	Enable值 只能是1或2 当为2时需要进行复制到updatefw目录下
#Return		：$?	0（成功）  1（参数1SVN目录不能为空）  2（参数2保存目录不能为空）  
#				    3（创建的目录不存在）  4（从SVN上下载出错）  5（更新SVN指定版本出错）
#					6（Enable为2时复制文件出错）	
#Date		：2012-12-14
#Auth		：LiJun
#****************************************************************************************
function SVN_Checkout()
{
	local SVNSourcePath=$1	#SVN源代码路径
	local SavePath=$2		#保存到本地哪个目录下
	local SVNVersion=$3		#SVN版本
	local nEnable=$4		#Enable的值
	local SVNLastPath=""	#SVN最后一个目录名
	local TempStr=""		#临时变量
	local nResult=1			#返回结果
	local nDownType=0		#下载类型 0从SVN上下载 1从本地下载
    local nSVNCheckoutResult=1  #从SVN Checkout结果 0成功 1失败
	local nIndex=0          #获取字符串出现的位置
	
	#WriteLog "SVN_Checkout Par"
	#WriteLog $SVNSourcePath
	#WriteLog $SavePath
	#WriteLog $SVNVersion
    #WriteLog $m_SVNUser
    #WriteLog $m_SVNPassword
	
	#将版本号保存给全局变量
	m_SVNVersion=$SVNVersion
	
	if [ -z "$SVNSourcePath" ] ; then
		WriteLog "Error SVN源代码路径不能为空"
		nResult=1
		return $nResult
	else
		#如果最后一位不是“/”则加上“/”
		TempStr=`echo $SVNSourcePath | awk '{print substr($0,length($0),1)}'`
		if [ $TempStr != "/" ] ; then
			SVNSourcePath=${SVNSourcePath}"/"
		fi
	fi

	if [ -z "$SavePath" ] ; then
		m_ErrInfo="Error [SVN_Checkout]保存目录不能为空"
		nResult=2
		return $nResult
	fi

	if [ ! -d $SavePath ] ; then
		mkdir -p $SavePath
	fi
	
	chmod +x $SavePath

	#判断目录是否存在
	if [ ! -d $SavePath ] ; then
		m_ErrInfo="Error [SVN_Checkout]保存目录创建不成功"
		nResult=3
		return $nResult
	fi

	#进入到保存目录再进行下载
	cd $SavePath

	#判断是从SVN还是从本地下载
	TempStr=`Str_SubString "$SVNSourcePath" 1 1`
	if [ "$TempStr" = "/" ] ; then
		nDownType=1
	else
		nDownType=0
	fi

	#去掉SVN源码路径的最后一位，即“/”
	SVNLastPath=`expr substr "$SVNSourcePath" 1 $((${#SVNSourcePath}-1))`

	#获取最后一个目录名，在目录名后面加上“/”
	SVNLastPath=${SVNLastPath##*/}"/"
	m_SVNLastPath=$SVNLastPath
	
	#从SVN上下载目录
	if [ $nDownType -eq 0 ] ; then
		#=0
		#下载之前先删除原来的目录 防止出错
        #WriteLog "$SavePath$m_SVNLastPath"
		rm -rf $SavePath$m_SVNLastPath
		#从SVN上下载最新版本源代码
		TempStr=`svn checkout --username=$m_SVNUser --password=$m_SVNPassword $SVNSourcePath 2> /dev/null`
        nSVNCheckoutResult=$?
		#TempStr=`svn export --username="$m_SVNUser" --password="$m_SVNPassword" $SVNSourcePath 2> /dev/null`
		
		#判断下载结果
		Str_IndexOf "$TempStr" "Checked out revision "
		
        if [ "$TempStr" = "" ] ; then
            if [ $nSVNCheckoutResult -ne 0 ] ; then
                m_ErrInfo="Error [SVN_Checkout]从SVN上下载出错"
                nResult=4
                return $nResult
            fi
        else
            if [ $? -eq 0 ] ; then
                m_ErrInfo="Error [SVN_Checkout]从本地目录下载出错"
                nResult=4
                return $nResult
            fi
        fi
		
		#如果SVN版本号大于0则下
		if [ $SVNVersion -gt 0 ] ; then
			#如果SVN版本大于0则更新到指定SVN版本
			TempStr=`svn update --username="$m_SVNUser" --password="$m_SVNPassword" -r $SVNVersion $SVNLastPath  2> /dev/null`
			#验证字符串第2个字符串是否存在 不为0则存在
			Str_IndexOf "$TempStr" "revision"
			
			#如果返回值小于2则更新失败
			if [ $(($?)) -lt 2 ] ; then
				m_ErrInfo="Error [SVN_Checkout]更新SVN版本出错"
				nResult=5
				return $nResult
			fi
		 else
		    #如果SVN版本等于0则取下载的版本号，并取得版本号，
			#svn log后打印出第2行即最新版本号
			TempStr=`svn log --username="$m_SVNUser" --password="$m_SVNPassword" $SVNLastPath 2> /dev/null | awk 'NR==2{print}'`
			#过滤出空格的位置
			Str_IndexOf "$TempStr" " "
			nIndex=$?-1
			#从版本号字符串中截取第2个到nIndex（即空格位置）之间的字符即为版本号
			TempStr=`Str_SubString "$TempStr" 2 $((nIndex))`
			m_SVNVersion=$TempStr
		fi
	else
		#=1
		#判断目录是否存在
		if [ ! -d $SVNSourcePath ] ; then
			m_ErrInfo="Error [SVN_Checkout]SVNPath目录不存在"
			nResult=4
			return $nResult
		fi
		TempStr=`cp -r "$SVNSourcePath" $SavePath`
	fi
    
	# TempStr=`svn checkout --username="$m_SVNUser" --password="$m_SVNPassword" "$SVNSourcePath"`
	# WriteLog `pwd`
	# WriteLog "svn checkout --username="$m_SVNUser" --password="$m_SVNPassword" "$SVNSourcePath""
	# WriteLog $TempStr
	# ShowEndLog
	# exit 1

	#如果Eanble为2时需要复制SVN下载的所有文件目录
	if [ $(($nEnable)) -eq 2 ] ; then
		TempStr=`cp $SavePath$m_SVNLastPath*.* $m_CurrentPath$m_UpdatePath`	
		#判断是否复制成功
		if [ $(($?)) -ne 0 ] ; then
			m_ErrInfo="Error [SVN_Checkout]Enable为2时复制文件出错";
			nResult=6
			return $nResult
		else
			rm -rf $SavePath$m_SVNLastPath
		fi
	fi
	
	nResult=0
	return $nResult
}

#****************************************************************************************
#Funtion	：编译程序生成二进制文件（int）
#parameter	：$1	应用名称 如b2bua callserver
#			  $2	SVN版本 如 101 98 可以没有
#			  $3	生成可执行程序目录，此目录在源代码下 如 src
#			  $4	应用程序的版本号
#Return		：$?	0（成功）  1（生成文件失败）  2（目录不存在）  3（SVN最后路径不能为空）
#				    4（configure文件不存在）  5（configure执行出错）
#Date		：2012-12-14
#Auth		：LiJun
#****************************************************************************************
function SVN_Make()
{
	local AppName="$1"				#应用名称 如b2bua callserver
	local SVNVersion="$2"			#SVN版本
	local AppPath="$3"				#生成可执行程序目录
	local AppVersion="$4"			#应用程序的版本号
	local TempStr=""				#临时变量
	local nResult=1					#返回结果
	
	#进入上次SVN的下载路径
	if [ "$m_SVNLastPath" = "" ] ; then
		m_ErrInfo="Error [SVN_Make]SVN最后路径不能为空"
		nResult=3
		return $nResult
	fi

	if [ ! -d "$m_CurrentPath""$m_UpdatePath""$m_SVNLastPath" ] ; then
		m_ErrInfo="Error [SVN_Make]目录不存在 $m_CurrentPath""$m_UpdatePath""$m_SVNLastPath"
		nResult=2
		return $nResult
	fi

	cd "$m_CurrentPath""$m_UpdatePath""$m_SVNLastPath"
	
	#设置build.sh文件权限
	if [ ! -f  $m_BuildScript ] ; then
		m_ErrInfo="Error [SVN_Make]m_BuildScript文件不存在"
		nResult=4
		return $nResult
	fi
	
	chmod 775 $m_BuildScript
	
	#如果保存可执行的目录不为空
	if [ ${#AppPath} -gt 0 ] ; then
	
		#保存路径第1位是否为“/” 是的话去掉
		TempStr=`Str_SubString $AppPath 1 1`
		if [ $TempStr = "/" ] ; then
			AppPath=`Str_SubString $AppPath 2 $((${#AppPath}-1))`
		fi
		
		#保存路径最后一位是否为“/” 不是的话加上
		TempStr=`Str_SubString $AppPath ${#AppPath} 1`
		if [ ! $TempStr = "/" ] ; then
			AppPath=${AppPath}"/"
		fi

		#删除掉可执行程序
		rm -rf "$AppPath""$AppName"
	fi

	#转到源代码路径
	if [ ! -d "$m_CurrentPath""$m_UpdatePath""$m_SVNLastPath""$AppPath" ] ; then
		m_ErrInfo="Error [SVN_Make]目录不存在 $m_CurrentPath""$m_UpdatePath""$m_SVNLastPath""$AppPath"
		nResult=2
		return $nResult
	fi
	
	#调用build.sh文件生成可执行文件
	TempStr=`./$m_BuildScript 2> /dev/null`

	cd "$m_CurrentPath""$m_UpdatePath""$m_SVNLastPath""$AppPath"

	#判断生成的程序是否存在
	if [ ! -f "$m_CurrentPath""$m_UpdatePath""$m_SVNLastPath""$AppPath""$AppName" ] ; then
		m_ErrInfo="Error [SVN_Make]Make失败找不到文件 $m_CurrentPath""$m_UpdatePath""$m_SVNLastPath""$AppPath""$AppName"
		nResult=1
		return $nResult
	fi
	
	#重命名文件
	mv "$m_CurrentPath""$m_UpdatePath""$m_SVNLastPath""$AppPath""$AppName"/"$AppName" "$m_CurrentPath""$m_UpdatePath""$m_SVNLastPath""$AppPath""$AppName"/"$AppName""$AppVersion""$SVNVersion"
	
	#移动文件至updatefw目录下
	mv "$m_CurrentPath""$m_UpdatePath""$m_SVNLastPath""$AppPath""$AppName""$AppVersion""$SVNVersion" "$m_CurrentPath""$m_UpdatePath"
	
	#删除下载的SVN目录
	rm -rf "$m_CurrentPath""$m_UpdatePath""$m_SVNLastPath"

	nResult=0
	return $nResult
}

#****************************************************************************************
#Funtion	：打成tar.gz包（void）
#parameter	：NONE
#Return		：NONE
#Date		：2012-12-14
#Auth		：LiJun
#****************************************************************************************
function Pack()
{
	local TempStr=""				#临时变量
	local CSVPath=""				#CSV文件的路径
	local CSVFlag=0					#如果为0 表示保存在pack.sh当前目录 1表示保存到CSVPath目录
	
	#删除updatefw目录下从SVN上下载多出来的“.svn”目录
	find "$m_CurrentPath$m_UpdatePath" -type d -name ".svn"|xargs rm -rf
	
	#复制版本说明
	cp "$m_CSVDir""$m_NTXVersionFile" "$m_CurrentPath""$m_UpdatePath"
	
	#转到脚本当前目录
	cd "$m_CurrentPath"
	
	#获取CSV文件中是否包含“/” 不包含表示是当前路径
	Str_IndexOf "$m_CSVFile" "/"
	
	#如果包含“/”（返回值应大于0）则截取路径为最后一个“/”之前的字符（包含“/”）
	if [ $? -gt 0 ] ; then
		CSVPath=`GetCSVPath`
		CSVFlag=1
	fi
	
	#保存路径最后一位是否为“/” 不是的话加上
	TempStr=`Str_SubString $m_CSVFile ${#m_CSVFile} 1`
	if [ ! $TempStr = "/" ] ; then
		AppPath=${AppPath}"/"
	fi
	
	#进行打包
	# WriteLog "$m_PcakName"
	# WriteLog "$CSVPath"
	# WriteLog "$m_UpdatePath"
	
	if [ $CSVFlag -eq 0 ] ; then
		tar -czvf "$m_PcakName" "$m_UpdatePath" > /dev/null				
	else
		tar -czvf "$CSVPath$m_PcakName" "$m_UpdatePath" > /dev/null		
	fi
}


#****************************************************************************************
#Funtion	：删除旧的updatefw.tar.gz包（void）
#parameter	：NONE
#Return		：NONE
#Date		：2012-12-22
#Auth		：LiJun
#****************************************************************************************
function DelOldPcakName
{
	local TempStr=""				#临时变量
	local CSVPath=""				#CSV文件的路径
	local CSVFlag=0					#如果为0 表示保存在pack.sh当前目录 1表示保存到CSVPath目录
	
	#获取CSV文件中是否包含“/” 不包含表示是当前路径
	Str_IndexOf "$m_CSVFile" "/"
	
	#如果包含“/”（返回值应大于0）则截取路径为最后一个“/”之前的字符（包含“/”）
	if [ $? -gt 0 ] ; then
		CSVPath=`GetCSVPath`
		CSVFlag=1
	fi

	#删除旧的updatefw.tar.gz包
	if [ $CSVFlag -eq 0 ] ; then
		rm -rf "$m_CurrentPath$m_PcakName"				
	else
		rm -rf "$CSVPath$m_PcakName"	
	fi
}

#****************************************************************************************
#Funtion	：获取CSV文件的路径，含“/”（string）
#parameter	：NONE
#Return		：不为空（成功）  为空（失败）
#			  调试方法：
#						1）打印返回值 echo `GetCSVPath` 返回 /home/ippbx/
#						2）设置一个全局变量，将返回结果赋值给全局变量
#						3）调用该语句并返回结果 str=`GetCSVPath`
#												echo $str
#Date		：2012-12-21
#Auth		：LiJun
#****************************************************************************************
function GetCSVPath
{
	local TempStr=""				#临时变量
	local ResultStr=""				#返回结果
	local nLastID=-1				#出现的次数

	for((i=0;i<${#m_CSVFile};i++))
	do
		TempStr=`Str_SubString "$m_CSVFile" $((i+1)) 1`
		if [ "$TempStr" = "/" ] ; then
			nLastID=$((i+1))
		fi
	done
	
	TempStr=`Str_SubString "$m_CSVFile" 1 $((nLastID))`
	echo $TempStr
	return
	
}

#****************************************************************************************
#Funtion	：打印结束日志（void）
#parameter	：NONE
#Return		：NONE
#Date		：2012-12-14
#Auth		：LiJun
#****************************************************************************************
function ShowEndLog()
{
	WriteLog ""
	WriteLog "结束"
	WriteLog "*****************************************************************"
	WriteLog ""
	kill -9 $$ > /dev/null		
}

#****************************************************************************************
#Funtion	：清除数组各个元素的值（void）
#parameter	：NONE
#Return		：NONE
#Date		：2012-12-14
#Auth		：LiJun
#****************************************************************************************
function Arr_Clear()
{
	for((i=0;i<$m_CSVColumnsCount;i++))
	do
		m_CSVLineArr[$i]=""
	done
}

#****************************************************************************************
#Funtion	：解析当前行的内容至数组（void）
#parameter	：NONE
#Return		：NONE
#Date		：2012-12-14
#Auth		：LiJun
#****************************************************************************************
function Arr_SplitLine()
{
	local TempStr=""				#临时变量
	local Flag=0					#循环标志
	local StrIndex=0				#查找字符出现位置
	local i=0						#数组下标
	
	Arr_Clear
	TempStr="$m_CSVCurrentLineStr"
	
	for((i=0;i<$m_CSVColumnsCount;i++))
	do
		#查找逗号出现位置
		Str_IndexOf "$TempStr" ","
		StrIndex=$?
		
		if [ $StrIndex -eq 0 ] ; then
			m_CSVLineArr[$i]=$TempStr
		elif [ $StrIndex -eq 1 ] ; then
			m_CSVLineArr[$i]=""
			TempStr=`Str_SubString "$TempStr" 2 $((${#TempStr}-1))`
		else
			m_CSVLineArr[$i]=`Str_SubString "$TempStr" 1 $((StrIndex-1))`
			TempStr=`Str_SubString "$TempStr" $((StrIndex+1)) $((${#TempStr}-$StrIndex))`
		fi
		#echo "m_CSVLineArr["$i"]="${m_CSVLineArr[$i]}
	done
}

#****************************************************************************************
#Funtion	：判断当前Shell脚本是否重复运行（int）
#parameter	：NONE
#Return		：$?	未运行0 已运行1
#Date		：2012-12-17
#Auth		：LiJun
#****************************************************************************************
function IsRun()
{
	local ProcessPid=$$			#获取当前脚本运行的PID
	local ProcessName=$0		#获取当前脚本的文件名
	local MatchProcessCount=0	#匹配进程总数
	local nResult=1

	let MatchProcessCount=`ps -A --format='%p%P%C%x%a' --width 2048 -w --sort pid|grep "$ProcessName"|grep -v grep|grep -v " -c sh "|grep -v "$ProcessPid" | grep -c sh|awk '{printf("%d",$1)}'`
	if [ ${MatchProcessCount} -gt 0 ] ; then
		nResult=1
		return $nResult
	fi
	
	nResult=0
	return $nResult
}

clear


#先删除updatefw目录、日志、SVN日志、压缩包等

rm -rf "$m_UpdatePath"
rm -rf "$m_LogFile"
rm -rf "$m_LogSVN"
DelOldPcakName

WriteLog ""
WriteLog "**********************Linux自动打包******************************"
WriteLog "                         V1008"
WriteLog "                       2013-06-07"
WriteLog ""
WriteLog "开始"
WriteLog ""

#判断是否重复运行
IsRun

#获取CSV文件中是否包含“/” 不包含表示是当前路径
Str_IndexOf "$m_CSVFile" "/"
	
#如果包含“/”（返回值应大于0）则截取路径为最后一个“/”之前的字符（包含“/”）
if [ $? -gt 0 ] ; then
	m_CSVDir=`GetCSVPath`
else
	m_CSVDir=$m_CurrentPath
fi

if [ ! -f "$m_CSVFile" ] ; then
	WriteLog "Error CSV文件不存在 $m_CSVFile"
	ShowEndLog
	exit 1
fi

if [ ! -f "$m_CSVDir$m_NTXVersionFile" ] ; then
	WriteLog "Error NTX版本说明文件不存在 ""$m_CSVDir$m_NTXVersionFile"
	ShowEndLog
	exit 1
fi

#创建updatefw目录
mkdir -p "$m_UpdatePath"

if [ $((`awk 'END{print NR}' $m_CSVFile`)) -lt 5 ] ; then
	WriteLog "Error CSV文件行数小于5行"
fi

#下载 DependLib
WriteSVN "SVNVersion DependLib"
WriteSVN ""
m_CSVLastFunction=""
m_CSVCurrentLineID=1
cat $m_CSVFile |
while read m_CSVCurrentLineStr ; do
	#如果当前行字符长度小于8说明是空行
	if [ ${#m_CSVCurrentLineStr} -lt 8 ] ; then
		m_CSVCurrentLineID=$((m_CSVCurrentLineID+1))
	else
		#如果当前行是第1行则跳过
		if [ $m_CSVCurrentLineID -eq 1 ] ; then
			m_CSVCurrentLineID=$((m_CSVCurrentLineID+1))
			continue
		fi
		
		#解析当前行内容到数组
		Arr_SplitLine
		
		#如果第1行是DepenedLib则将全局变量改为此值
		if [ "${m_CSVLineArr[0]}" = "DependLib" ] ; then
			WriteLog "                       DependLib"
			m_CSVLastFunction="DependLib"
		fi
		
		#如果全局变量不是DepenedLib则跳过
		if [ ! "$m_CSVLastFunction" = "DependLib" ] ; then
			m_CSVCurrentLineID=$((m_CSVCurrentLineID+1))
			continue
		fi
		
		#如果Enable值为1则执行

		if [ "${m_CSVLineArr[2]}" = "1" ] ; then 		
			if [ ${#m_CSVLineArr[3]} -lt 2 ] ; then
				WriteLog "Error 第 "$m_CSVCurrentLineID" 行 DependLib [SVNPath]参数内容过短"
				ShowEndLog
				exit 1
			fi
			
			if [ ${#m_CSVLineArr[4]} -lt 1  ] ; then
				WriteLog "Error 第 "$m_CSVCurrentLineID" 行 App [SVNVersion]参数内容过短"
				ShowEndLog
				exit 1
			fi

			if [ ${#m_CSVLineArr[8]} -lt 1 ] ; then
				WriteLog "Error 第 "$m_CSVCurrentLineID" 行 DependLib [DestPath]参数内容过短"
				ShowEndLog
				exit 1
			else
				if [ ! `Str_SubString ${m_CSVLineArr[8]} 1 1` = "/" ] ; then
					 m_CSVLineArr[9]="/"${m_CSVLineArr[8]}
				fi
				
				if [ ! `Str_SubString ${m_CSVLineArr[9]} ${#m_CSVLineArr[8]} 1` = "/" ] ; then
					WriteLog ""
					 m_CSVLineArr[9]=${m_CSVLineArr[8]}"/"
				fi
			fi
			
			mkdir -p ${m_CSVLineArr[8]}
			
			if [ ! -d  ${m_CSVLineArr[8]} ] ; then
				WriteLog "Error 第 "$m_CSVCurrentLineID" 行 DependLib [DestPath]目录创建不成功 "${#m_CSVLineArr[8]} 
				ShowEndLog
				exit 1
			fi
			
			m_ErrInfo=""
			#WriteLog "SVNPath=${m_CSVLineArr[3]} DestPath=${m_CSVLineArr[8]} SVNVersion=${m_CSVLineArr[4]} Enable=${m_CSVLineArr[2]}"
			SVN_Checkout "${m_CSVLineArr[3]}" "${m_CSVLineArr[8]}" "${m_CSVLineArr[4]}" "${m_CSVLineArr[2]}"
			if [ $? -eq 0 ] ; then
			    WriteSVN "${m_CSVLineArr[1]}  =  $m_SVNVersion"
				WriteLog "OK    ${m_CSVLineArr[1]}"
			else
				WriteLog "Fail  ${m_CSVLineArr[1]}"
				WriteLog "$m_ErrInfo"
				ShowEndLog
				exit 1
			fi
		fi
		m_CSVCurrentLineID=$((m_CSVCurrentLineID+1))
	fi
	
done

#下载 App
WriteSVN ""
WriteSVN "SVNVersion App"
WriteSVN ""
m_CSVLastFunction=""
m_CSVCurrentLineID=1
wait_arr[100]=""
app_arr[100]=""
wait_idx=0
while read m_CSVCurrentLineStr
do
	#如果当前行字符长度小于9说明是空行
	if [ ${#m_CSVCurrentLineStr} -lt 9 ] ; then
		m_CSVCurrentLineID=$((m_CSVCurrentLineID+1))
	else
		#如果当前行是第1行则跳过
		if [ $m_CSVCurrentLineID -eq 1 ] ; then
			m_CSVCurrentLineID=$((m_CSVCurrentLineID+1))
			continue
		fi
		#解析当前行内容到数组
		Arr_SplitLine
		#如果第1行是App则将全局变量改为此值
		if [ "${m_CSVLineArr[0]}" = "App" ] ; then
			WriteLog ""
			WriteLog "                           App"
			m_CSVLastFunction="App"
		#如果是Config则跳出
		elif [ "${m_CSVLineArr[0]}" = "Config" ] ; then
			m_CSVLastFunction=""
			break;
		fi
        
		#如果全局变量不是App则跳过
		if [ ! "$m_CSVLastFunction" = "App" ] ; then
			m_CSVCurrentLineID=$((m_CSVCurrentLineID+1))
			continue
		fi
        
		#如果Enable值为1或2则执行
		if [[ "${m_CSVLineArr[2]}" = "1" ]] || [[ "${m_CSVLineArr[2]}" = "2" ]] ; then 
		
			if [ ${#m_CSVLineArr[2]} -lt 1 ] ; then
				WriteLog "Error 第 "$m_CSVCurrentLineID" 行 App [Name]参数内容过短"
				ShowEndLog
				exit 1
			fi
		
			if [ ${#m_CSVLineArr[3]} -lt 2 ] ; then
				WriteLog "Error 第 "$m_CSVCurrentLineID" 行 App [SVNPath]参数内容过短"
				ShowEndLog
				exit 1
			fi

			if [ ${#m_CSVLineArr[4]} -lt 1  ] ; then
				WriteLog "Error 第 "$m_CSVCurrentLineID" 行 App [SVNVersion]参数内容过短"
				ShowEndLog
				exit 1
			fi
			
			#当Enable为1时，才需要判断和创建目标目录
			if [ "${m_CSVLineArr[2]}" = "1" ] ; then
			
				if [ ${#m_CSVLineArr[6]} -lt 2  ] ; then
					WriteLog "Error 第 "$m_CSVCurrentLineID" 行 App [AppName]参数内容过短"
					ShowEndLog
					exit 1
				fi
				
				if [ ${#m_CSVLineArr[7]} -lt 1 ] ; then
					WriteLog "Error 第 "$m_CSVCurrentLineID" 行 App [AppVersion]参数内容过短"
					ShowEndLog
					exit 1
				fi
				
				if [ ${#m_CSVLineArr[8]} -gt 1 ] ; then
					if [ ! `Str_SubString ${m_CSVLineArr[8]} 1 1` = "/" ] ; then
						 ${m_CSVLineArr[8]}="/"${m_CSVLineArr[8]}
					fi
					
					if [ ! `Str_SubString ${m_CSVLineArr[8]} ${#m_CSVLineArr[8]} 1` = "/" ] ; then
						 ${m_CSVLineArr[8]}=${m_CSVLineArr[8]}"/"
					fi
					
					mkdir -p ${m_CSVLineArr[8]}
					
					if [ ! -d  ${m_CSVLineArr[8]} ] ; then
						WriteLog "Error 第 "$m_CSVCurrentLineID" 行 App [DestPath]目录创建不成功 "${#m_CSVLineArr[8]} 
						ShowEndLog
						exit 1
					fi
				else
					m_CSVLineArr[8]="$m_CurrentPath""$m_UpdatePath"
				fi
			else
				#当Enable为2时，修改{m_CSVLineArr[8]的值为upodatefw的值
				m_CSVLineArr[8]="$m_CurrentPath""$m_UpdatePath"
			fi
            
            ./make.sh "$m_CSVCurrentLineStr" &
            wait_arr[$wait_idx]=$!
            app_arr[$wait_idx]=${m_CSVLineArr[1]}
            wait_idx=$(($wait_idx+1))
		fi
		
		m_CSVCurrentLineID=$((m_CSVCurrentLineID+1))
	fi
done < $m_CSVFile

i=0
while [ $i -lt $wait_idx ]
do
    wait ${wait_arr[i]}
    WriteLog "OK    ${app_arr[i]}"
    i=$(($i+1))
done

#下载 Config
WriteSVN ""
WriteSVN "SVNVersion Config"
WriteSVN ""
m_CSVLastFunction=""
m_CSVCurrentLineID=1
cat $m_CSVFile |
while read m_CSVCurrentLineStr ; do

	#如果当前行字符长度小于9说明是空行
	if [ ${#m_CSVCurrentLineStr} -lt 9 ] ; then
		m_CSVCurrentLineID=$((m_CSVCurrentLineID+1))
	else
		#如果当前行是第1行则跳过
		if [ $m_CSVCurrentLineID -eq 1 ] ; then
			m_CSVCurrentLineID=$((m_CSVCurrentLineID+1))
			continue
		fi
		
		#解析当前行内容到数组
		Arr_SplitLine
		
		#如果第1行是App则将全局变量改为此值
		if [ "${m_CSVLineArr[0]}" = "Config" ] ; then
			WriteLog ""
			WriteLog "                         Config"
			m_CSVLastFunction="Config"
		#如果是DependLib则跳出
		elif [ "${m_CSVLineArr[0]}" = "DependLib" ] ; then
			m_CSVLastFunction=""
			break;
		fi
		
		#如果全局变量不是Config则跳过
		if [ ! "$m_CSVLastFunction" = "Config" ] ; then
			m_CSVCurrentLineID=$((m_CSVCurrentLineID+1))
			continue
		fi
		
		#如果Enable值为1则执行
		if [ "${m_CSVLineArr[2]}" = "1" ] ; then 	
			if [ ${#m_CSVLineArr[3]} -lt 2 ] ; then
				WriteLog "Error 第 "$m_CSVCurrentLineID" 行 Config [SVNPath]参数内容过短"
				ShowEndLog
				exit 1
			fi
			
			m_CSVLineArr[9]="$m_CurrentPath""$m_UpdatePath"
			
			m_ErrInfo=""
			
			SVN_Checkout "${m_CSVLineArr[3]}" "${m_CSVLineArr[9]}" "${m_CSVLineArr[4]}" "${m_CSVLineArr[2]}"
			
			if [ $? -eq 0 ] ; then
			    WriteSVN "${m_CSVLineArr[1]}  =  $m_SVNVersion"
				WriteLog "OK    ${m_CSVLineArr[1]}"
			else
				WriteLog "Fail  ${m_CSVLineArr[1]}"
				WriteLog "$m_ErrInfo"
				ShowEndLog
				exit 1
			fi
		fi
		
		m_CSVCurrentLineID=$((m_CSVCurrentLineID+1))
	fi
done

#打成最终的tar.gz压缩包
WriteLog ""
WriteLog "Pack"
Pack

if [ -f "$m_CSVDir""$m_PcakName" ] ; then
	cd "$m_CurrentPath"
	rm -rf "$m_CurrentPath""$m_UpdatePath"
	WriteLog "OK    $m_PcakName"
else
	
	WriteLog "Fail  生成打包文件出错"
	WriteLog "$m_ErrInfo"
	ShowEndLog
	exit 1
fi


#打印结束日志
ShowEndLog
exit 0

#********************************************************************************
#注：在Fedora系统下IsRun返回值不正确，在RedHat下正确（2012-12-22）
#
####版本：V1008（在V1007基础上修改）
#时间：2013-06-07
#说明：1、去掉CSV文件中的SVNVersion，自动下载最新版本
#      2、svn checkout后将svn的版本号编写到"svn.log"
#
###版本：V1007（在V1006基础上修改）
#时间：2013-01-07
#说明：1、App中enable为2时，从svn上下载目录后，将目录中的所有文件复制到updatefw目录
#
##版本：V1006（在V1005基础上修改）
#时间：2013-01-05
#说明：1、修改了SVN_Checkout成功时结果为空导致判断出错，增加了变量判断返回结果为
#         空时再判断获取最后一次$?为0时才成功 否则就是失败
#
#版本：V1005（在V1004基础上修改）
#时间：2013-01-05
#说明：1、修改了version.txt为version.ini

#版本：V1004（在V1003基础上修改）
#时间：2012-12-28
#说明：1、CSV配置文件中去掉[Configure]项
#	   2、增加了全局变量[m_BuildScript] 用于到每个[App]类型应用程序根目录下执行
#		  该脚本要求能够自动设置configure权限，自动执行configure和make
#	   3、Checkout之前 先删除本地的目录 防止出错
#
#版本：V1003（在V1002基础上修改）
#时间：2012-12-22
#说明：1、Config、DependLib支持从本地路径，原来只支持从SVN上下载
#	   2、生成的包 updatefw.tar.gz 在csv文件同一目录，原来在pack.sh目录
#
#版本：V1002（在V1001基础上修改）
#时间：2012-12-18
#说明：1、运行脚本时需指定csv文件名，如：./test.sh sysconfig.csv
#	   2、脚本发现已重复运行时会自动退出，原来运行的不受影响
#	   3、子程序的名称如何重命名，未完成
#
#版本：V1001
#时间：2012-12-14
#说明：1、初始版本
#********************************************************************************
