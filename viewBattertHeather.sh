#!/bin/bash
# 获取当前电脑的出厂电容量
a=$(ioreg -brc AppleSmartBattery | grep DesignCapacity | awk '{if( NR == 1 )  print $3} ')

# 获取当前电脑的当前电容量
max=$(ioreg -brc AppleSmartBattery | grep MaxCapacity | awk '{if( NR == 1 )  print $3} ')

# 计算赋值（保留两位小数，并取出小数部分）
val=`echo "scale=2; $max*100 / $a" | bc -l`

# 输出结果
echo "当前电池健康  $val%"
