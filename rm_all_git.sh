#!/bin/sh

if [ ! -d $1 ];then
	echo "directory \"$1\" does not exist."
	exit
fi

list_files=`ls $1`
if [[ $list_files == "" ]];then
	exit 0
fi

if [ ! -d $1/.git ];then
	echo "directory \"$1/.git\" does not exist."
	exit
fi


if [ ! -d ./mv_git_tmp_dir ];then
	mkdir ./mv_git_tmp_dir
fi

mv $1/.git  ./mv_git_tmp_dir/
rm -rf $1
mv ./mv_git_tmp_dir $1

echo "deleting all files in the directory \"$1\" succeeded."
