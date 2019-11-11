#!/bin/bash
echo_info() {

    CO='\033[0;36m'
    NC='\033[0m' # No Color

    echo -e "${CO}   INFO: ${@}${NC}"

}
echo_error() {
    CO='\033[0;31m'
    NC='\033[0m' # No Color

    echo -e "${CO}  ERROR: ${@}${NC}"
}

echo_success() {
    CO='\033[0;32m'
    NC='\033[0m' # No Color

    echo -e "${CO}SUCCESS: ${@}${NC}"
}

# 1、检查当前是啥系统
system_name=$(uname)
if [ $system_name = "Linux" ]
then
echo_info "当前系统为 Linux"
echo_info "详细版本为 $(cat /proc/version)"
elif [ $system_name = "Darwin" ]
then
echo_info "当前版本为 Mac"
echo_info "详细版本为$(uname -a)"
fi
# 2、检查 硬盘  cup 内存的多大，使用了多少，剩余多少

# 检查内存情况
system_mem_total=$(free -m | awk -F "[ ]+" 'NR==2{print $2}')
system_mem_use=$(free -m | awk -F "[ ]+" 'NR==2{print $3}')
system_mem_free=$(free -m | awk -F "[ ]+" 'NR==2{print $4}')
echo_info " 内存: total ${system_mem_total}M, use ${system_mem_use}M , free ${system_mem_free}M"

