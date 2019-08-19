#!/bin/bash
# shell 也是解释型语言，需要在行首加入制定解释器
# 定义变量
name="chenhao"

# 输出变量
echo $name
echo ${name}

# 修改变量
name="xiaoke"
echo ${name}

# 将变量定义为只读
# readonly name

# 删除变量
unset name
echo ${name}
