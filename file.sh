#!/bin/bash

# 对文件的一些操作

file="/Users/chenhao/workspace/myself/shell/test.txt"

# 文件是否可读
if [ -r $file ]
then
   echo "文件可读"
else
   echo "文件不可读"
fi


# 文件是否可写
if [ -w $file ]
then
   echo "文件可写"
else
   echo "文件不可写"
fi

# 文件是否可执行
if [ -x $file ]
then
   echo "文件可执行"
else
   echo "文件不可执行"
fi

# 文件是否为普通文件
if [ -f $file ]
then
   echo "文件为普通文件"
else
   echo "文件为特殊文件"
fi

# 是否是个目录
if [ -d $file ]
then
   echo "文件是个目录"
else
   echo "文件不是个目录"
fi

# 文件是否为空
if [ -s $file ]
then
   echo "文件不为空"
else
   echo "文件为空"
fi

# 文件是否存在
if [ -e $file ]
then
   echo "文件存在"
else
   echo "文件不存在"
fi

