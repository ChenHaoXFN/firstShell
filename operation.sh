#!/bin/bash

# 运算练习

# 计算 和

val=`expr 2 + 2`
echo "两数之和为  $val"


# 计算 差
val=`expr 3 - 2`
echo "两数之差为  $val"

# 计算 积
val=`expr 3 \* 3`
echo "两数之积为  $val"


# 计算商
val=`expr 6 / 2`
echo "两数之商为  $val"

# 计算余数
val=`expr 5 % 4`
echo "余数为  $val "
