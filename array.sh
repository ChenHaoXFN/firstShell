#!/bin/bash


# 定义一个数组
arr_name=(jack chenhao zzk xiaoke dake)
arr_age=(12 22 18 20 21 20)

# 单独给数组中的某个变量赋值
arr_name[2]=zhaozongkui

# 获取数组的值
var=${arr_name[2]}
echo "arr_name的第三位是：${var}"

# 获取数组的长度
arr_name_len=${#arr_name[*]}
echo "arr_name数组的长度是 : $arr_name_len"

# 获取单个数组元素的长度
arr_var_len=${#arr_name[2]}
echo "单个元素长度为 ${arr_var_len}"
