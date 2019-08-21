#!/bin/bash

# 关系运算符

# 检查两个数是否相等

echo "输入了 $1  $2 "

if [ $1 -eq $2 ]
then
echo "他们相等"
else 
echo "他们不等"
fi


# 检查两个数是否不等
if [ $1 -ne $2 ]
then
echo "他们不等"
else
echo "他们相等"
fi

# 比较大小
if [ $1 -gt $2 ]
then
echo "$1 比 $2 大"
else
echo "$1 比 $2 小"
fi
