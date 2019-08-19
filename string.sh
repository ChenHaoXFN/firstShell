#!/bin/bash
str='this is string'

name='Tom'
str_name="hello ${name}"
echo $str_name

# 字符串长度
echo "字符串长度为 ${#name}"

# 字符串截取
echo "截取 tom 的 第二位到最后一位 : ${name:1:2}"
