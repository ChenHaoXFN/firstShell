#!/bin/bash

IGN_CMT="^[[:blank:]]*[^[:blank:]#;]"

_os_is_mac() {
    [ $(uname) = "Darwin" ]
}

_os_is_linux() {
    [ $(uname) = "Linux" ]
}


_echo() {

    _ec="echo"
    if [ $(uname) = "Darwin" ]
    then
        _ec="echo"
    elif [ $(uname) = "Linux" ]
    then
        _ec="echo -e"
    fi

    ${_ec} "${@}"

}

echo_info() {

    CO='\033[0;36m'
    NC='\033[0m' # No Color

    _echo "${CO}   INFO: ${@}${NC}"

}

echo_warn() {

    CO='\033[0;90m\033[43m'
    NC='\033[0m' # No Color

    _echo "${CO}WARNING: ${@}${NC}"

}

echo_error() {
    CO='\033[0;31m'
    NC='\033[0m' # No Color

    _echo "${CO}  ERROR: ${@}${NC}"
    exit -1
}

echo_success() {
    CO='\033[0;32m'
    NC='\033[0m' # No Color

    _echo "${CO}SUCCESS: ${@}${NC}"
}

_array_contains() {
    local seeking=$1
    shift
    local array=("$@")
    for element in "${array[@]}"; do
        if [[ $element == $seeking ]]; then
            return 0
        fi
    done
    return 1
}

_input_exists_file() {

    read -p "${1}" path
    if [ -f ${path} ]
    then
        echo "${path}"
    elif [ -d ${path}  ]
    then
        _input_exists_dir "路径是文件夹，请重新输入: "
    else
        _input_exists_dir "路径不存在，请重新输入: "
    fi
}

_input_exists_dir() {

    read -p "${1}" path
    if [ -f ${path} ]
    then
        _input_exists_dir "路径不是文件夹，请重新输入: "
    elif [ -d ${path}  ]
    then
        echo "${path}"
    else
        _input_exists_dir "路径不存在，请重新输入: "
    fi
}

_input_number() {

    local num
    num=0

    max=${2}
    min=${3}

    msg="${1} [${min}-${max}] "

    read -p "${msg}" num
    if  $(echo ${num} | egrep -q '^[0-9]+$') 
    then

        if [ $(echo "$max > ${num}" | bc -l) -eq 0 ]
        then
            _input_number "最大不得超过${max}，请重新输入: " ${max} ${min}

        elif [ $(echo "$min < $num" | bc -l) -eq 0 ]
        then
            _input_number "最小不得小于${min}，请重新输入: " ${max} ${min}
        else
            echo "${num}"
        fi
    else
        _input_number "仅可以输入数字，请重新输入: " ${max} ${min}
    fi

}

_get_free_mem_in_m() {
    if _os_is_mac
    then
        mem=$(sysctl hw.memsize | awk '{print $2}')
        mem=$(echo "scale=0;${mem}/(1024*1024)/1" | bc -l)
    elif _os_is_linux
    then
        mem=$(free -m | grep "Mem:" | awk '{print $2}')
    fi

    echo ${mem}
}

_set_env() {

    cnt="${1}"

    [ -f ~/.profile ] && [ $(grep -c "${1}" ~/.profile ) -le 0  ] && echo "${1}" >> ~/.profile
    [ -f ~/.zshrc ] && [ $(grep -c "${1}" ~/.zshrc ) -le 0  ] && echo "${1}" >> ~/.zshrc
    [ -f ~/.bashrc ] && [ $(grep -c "${1}" ~/.bashrc ) -le 0  ] && echo "${1}" >> ~/.bashrc
    [ -f ~/.bash_profile ] && [ $(grep -c "${1}" ~/.bash_profile ) -le 0  ] && echo "${1}" >> ~/.bash_profile

    eval "${1}"
}

# 0. check parameter
ctx="${1}"
if [ -z "${ctx}" ] || [ ! -d "${ctx}" ]
then
    echo_error "请先指定应用路径安装根目录,如 ./deploy.sh /tomcat"
fi

# 1. system check
if _os_is_linux
then
    # 1、检查当前是啥系统
    system_name=$(uname)
    if _os_is_linux
    then
        echo_info "当前系统为 Linux"
        echo_info "详细版本为 $(uname -a)"
    elif _os_is_mac
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

# 判断内存剩余大小 当前设置内存剩余不得少于1个G
if [ $system_mem_free -gt 500 ]
then
    echo_info "当前内存剩余充足，剩余 $system_mem_free M"
else
    echo_error "当前内存严重不足，剩余 $system_mem_free M"
fi

# cpu 使用率
system_cpu_use=$(top -bn 1 -i -c | awk -F "[ ]+" 'NR==3{print $2}')
echo_info " cpu 使用率 $system_cpu_use "
fi

# 2. jvm settings

echo_info "刷新当前环境变量"

[ -f ~/.profile ] && source ~/.profile

if [ -n "$ZSH_VERSION" ] && [ -f ~/.zshrc ]
then
    source ~/.zshrc
elif [ -n "$BASH_VERSION" ] 
then
    [ -f ~/.bashrc ] && source ~/.bashrc
    [ -f ~/.bash_profile ] && source ~/.bash_profile 
fi


echo_info "检查JVM参数设置"
if [ ${#JAVA_HOME} -eq 0 ]
then
    echo_warn "JAVA_HOME未设置,正在自动设置JAVA_HOME"
    if type java > /dev/null
    then
        java_dir=$(dirname $(which java))
        if [ -L "${java_dir}" ]
        then
            java_dir=$(readlink -f $(java_dir))
        fi
        java_home=$(perl -MCwd -e 'print Cwd::realpath($ARGV[0])' ${java_dir}/../)
        if [ -d ${java_home}/bin ] && [ -d ${java_home}/jre ]
        then
            echo_info "自动设置JAVA_HOME为 ${java_home}"
            _set_env "export JAVA_HOME=${java_home}"
        else
            echo_error "找不到Java，请先手动设置JAVA_HOME"
        fi
    fi
fi


if [ -n ${JAVA_HOME} ]
then
    echo_success "JAVA_HOME: ${JAVA_HOME}"

    _java=${JAVA_HOME}/bin/java

    if type ${_java} > /dev/null
    then
        version=$(${_java} -version 2>&1 | awk -F '"' '/version/ {print $2}')
        major_version=${version:0:1}
        minor_version=${version:1}
        minor_version=$(echo $minor_version | sed -e 's/[\._]//g')

        s_version=${major_version}.${minor_version}

        if [ $(echo "${s_version} >= 1.8 && ${s_version} < 1.9" | bc -l) -eq 0 ]
        then
            echo_error "Java 版本要求1.8, 当前版本: ${version}"
        else
            echo_success "已找到JAVA版本: ${version}"
        fi
    else
        echo_error "找不到java命令"
    fi
fi

echo_info "检查Tomcat参数设置"
if [ ${#CATALINA_HOME} -eq 0 ]
then

    tomcat_candidates=()

    for f in $(find ${ctx} -name "apache-tomcat*" -maxdepth 1 -type d)
    do 
        tomcat_candidates+=("${f}")
    done

    if [ ${#tomcat_candidates[@]} -le 0 ]
    then
        echo_warn  "CATALINA_HOME环境变量未设置，请指定tomcat安装位置"
        tomcat_path=$(_input_exists_dir "Tomcat路径: ")
    elif [ ${#tomcat_candidates[@]} -gt 1 ]
    then
        echo_info "找到多个tomcat路径，请选择正确的tomcat路径"
        select tc in ${tomcat_candidates[@]}
        do
            if _array_contains "${tc}" "${tomcat_candidates[@]}"
            then
                tomcat_path=${tc}
                break
            else
                echo_warn "选择不正确，请重新选择"
            fi
        done
    elif [ ${#tomcat_candidates[@]} -eq 1 ]
    then
        tomcat_path=${tomcat_candidates[0]}
    fi
    export CATALINA_HOME=${tomcat_path}
fi

if [ ${#CATALINA_HOME} -gt 0 ]
then

    echo_success "CATALINA_HOME: ${CATALINA_HOME}"

    if [ ! -f "$CATALINA_HOME/bin/catalina.sh" ]
    then
        echo_error "找不到catalina.sh, 请重新指定正确的tomcat路径"
    fi

    chmod +x "${CATALINA_HOME}/bin/catalina.sh"

    version=$("$CATALINA_HOME/bin/catalina.sh" version | grep "Server number:" | awk '{print $3}')
    s_version=${version:0:1}
    if [ $(echo "${s_version} >= 8 && ${s_version} <=9" | bc -l )  -eq 0 ]
    then
        echo_error "支持的Tomcat版本为8.x ~ 9.x，当前的版本为 ${version}"
    else
        echo_success "已找到Tomcat ${version}, 路径: ${CATALINA_HOME}"
    fi

    _set_env "export CATALINA_HOME=${CATALINA_HOME}" 


    if [ ! -f "$CATALINA_HOME/bin/setenv.sh" ]
    then
        touch "$CATALINA_HOME/bin/setenv.sh"
    fi


    if [ -f "$CATALINA_HOME/bin/setenv.sh" ]
    then
        chmod +x "$CATALINA_HOME/bin/setenv.sh" 
    fi


    #grep "${IGN_CMT}" "$CATALINA_HOME/bin/setenv.sh" | grep "Xms" | grep -P '(?<=Xms)\d+(?=m)' -o
    echo_info "检查Tomcat内存参数设置"
    if [ $(grep "${IGN_CMT}" "$CATALINA_HOME/bin/catalina.sh" | grep -c "Xmx" ) -le 0 ]  && [ $(grep "${IGN_CMT}" "$CATALINA_HOME/bin/setenv.sh" | grep -c "Xmx" ) -le 0 ] 
    then
        echo_warn "未设置JVM Xmx参数"

        max_mem=$(_get_free_mem_in_m)

        jvm_xmx=$(_input_number "请输入JVM最大内存(单位M): " ${max_mem} 512)
        echo_info "设置JVM最大内存为: ${jvm_xmx}M"
        echo "JAVA_OPTS=\"\$JAVA_OPTS -Xmx${jvm_xmx}m\"" >> "$CATALINA_HOME/bin/setenv.sh"

    else

        if [ $(grep "${IGN_CMT}" "$CATALINA_HOME/bin/catalina.sh" | grep -c "Xmx" ) -gt 0 ]  
        then
            jvm_xmx=$(grep "${IGN_CMT}" "$CATALINA_HOME/bin/catalina.sh" | grep "Xmx" | grep -P '(?<=Xmx)\d+(?=m)' -o)

            echo_error "请删除catalina.sh中的JVM参数设置 位于 $(grep "${IGN_CMT}" "$CATALINA_HOME/bin/catalina.sh" | grep -n "Xmx" )"
            echo_info "Tomcat JVM最大内存为[catalina.sh]: ${jvm_xmx}m"
            if [ ${jvm_xmx} -lt 512 ] 
            then
                echo_error "JVM最大内存要求 >= 512m, 当前为${jvm_xmx}m"

            fi
        fi

        if [ $(grep "${IGN_CMT}" "$CATALINA_HOME/bin/setenv.sh" | grep -c "Xmx" ) -gt 0 ]  
        then
            jvm_xmx=$(grep "${IGN_CMT}" "$CATALINA_HOME/bin/setenv.sh" | grep "Xmx" | grep -P '(?<=Xmx)\d+(?=m)' -o)
            if [ ${jvm_xmx} -lt 512 ] 
            then
                echo_error "JVM最大内存要求 >= 512m, 当前为${jvm_xmx}m"
            fi
            echo_success "Tomcat JVM最大内存为: ${jvm_xmx}m"
        fi

    fi

    if [ $(grep "${IGN_CMT}" "$CATALINA_HOME/bin/catalina.sh" | grep -c "Xms" ) -le 0 ]  && [ $(grep "${IGN_CMT}" "$CATALINA_HOME/bin/setenv.sh" | grep -c "Xms" ) -le 0 ] 
    then
        echo_warn "未设置JVM Xms参数"
        jvm_xms=$(_input_number "请输入JVM最小内存(单位M): " ${jvm_xmx}  0)
        echo_info "设置JVM最小内存为: ${jvm_xms}M"
        echo "JAVA_OPTS=\"\$JAVA_OPTS -Xms${jvm_xms}m\"" >> "$CATALINA_HOME/bin/setenv.sh"
    else

        if [ $(grep "${IGN_CMT}" "$CATALINA_HOME/bin/catalina.sh" | grep -c "Xms" ) -gt 0 ]  
        then
            jvm_xms=$(grep "${IGN_CMT}" "$CATALINA_HOME/bin/catalina.sh" | grep "Xms" | grep -P '(?<=Xms)\d+(?=m)' -o)
            echo_error "请删除catalina.sh中的JVM参数设置 位于 $(grep "${IGN_CMT}" "$CATALINA_HOME/bin/catalina.sh" | grep -n "Xms" )"
            echo_info "Tomcat JVM最小内存为[catalina.sh]: ${jvm_xms}m"
        fi

        if [ $(grep "${IGN_CMT}" "$CATALINA_HOME/bin/setenv.sh" | grep -c "Xms" ) -gt 0 ]  
        then
            jvm_xms=$(grep "${IGN_CMT}" "$CATALINA_HOME/bin/setenv.sh" | grep "Xms" | grep -P '(?<=Xms)\d+(?=m)' -o)
            echo_success "Tomcat JVM最小内存为: ${jvm_xms}m"
        fi
    fi

fi

echo_info "停止Tomcat应用服务器"
$CATALINA_HOME/bin/catalina.sh stop > /dev/null 2>&1

echo_info "正在停止tomcat...."

sleep 5
if _os_is_mac
then
    t_pid=$(ps | grep java | grep tomcat | awk '{print $1}')
else
    t_pid=$(ps -ef | grep java | grep tomcat | awk '$8 != "grep" {print $2}')
fi

if [ ${#t_pid} -gt 0 ]
then
    echo_error "停止tomcat失败，请手动停止"
else
    echo_success "停止tomcat成功"
fi

echo_info "开始发布前备份"
backup_dir="${ctx}/backup/$(date '+%Y%m%d%H%M%S')"
mkdir -p "${backup_dir}"

echo_info "备份配置文件"
cp -rf "${ctx}/etc/" "${backup_dir}"

echo_info "备份数据文件"
cp -rf "${ctx}/storage/" "${backup_dir}"

echo_info "备份应用程序"
cp -rf "${CATALINA_HOME}/webapps/" "${backup_dir}"

echo_info "备份日志"
mkdir -p "${backup_dir}/log"
if [ -f "${CATALINA_HOME}/logs/catalina.out"  ]
then
    cp -rf "$CATALINA_HOME/logs/catalina.out" "${backup_dir}/log"
fi

echo_success "备份完毕"

echo_info "开始准备发布应用"

echo_info "检查应用参数设置"
extds_m="\-Dbond.externalDataSource\=" 
if [ $(grep "${IGN_CMT}" "$CATALINA_HOME/bin/catalina.sh" | grep -c "${extds_m}" ) -gt 0 ]
then
    grep "${IGN_CMT}" "$CATALINA_HOME/bin/catalina.sh" | grep -n "${extds_m}"
    echo_error "请删除在catalina.sh中的应用参数设置"
fi

if  [ $(grep "${IGN_CMT}" "$CATALINA_HOME/bin/setenv.sh" | grep -c "${extds_m}") -le 0 ] 
then

    config_candidates=()
    for f in $(find "${ctx}/etc" -name "*.properties" -maxdepth 1 -type f)
    do 
        config_candidates+=("${f}")
    done

    if [ ${#config_candidates[@]} -le 0 ]
    then
        echo_warn "未找到配置文件路径，请输入配置文件路径"
        config_path=$(_input_exists_file "配置文件路径 [prod.datasource.properties] :")
        echo "JAVA_OPTS=\"\$JAVA_OPTS -Dbond.externalDataSource=${config_path}\"" >> "$CATALINA_HOME/bin/setenv.sh"
    else
        if [ ${#config_candidates[@]} -gt 1 ]
        then
            echo_info "找到多个配置文件，请选择你需要的配置文件"
            select cf in ${config_candidates[@]}
            do
                if  _array_contains ${cf} "${config_candidates[@]}" 
                then
                    config_path=${cf}
                    echo "JAVA_OPTS=\"\$JAVA_OPTS -Dbond.externalDataSource=${cf}\"" >> "$CATALINA_HOME/bin/setenv.sh"
                    break
                else
                    echo ${cf}
                    echo_warn "所选文件不存在"
                fi
            done
        elif [ ${#config_candidates[@]} -eq 1 ]
        then
            config_path=${config_candidates[0]}
            echo "JAVA_OPTS=\"\$JAVA_OPTS -Dbond.externalDataSource=${config_candidates[0]}\"" >> "$CATALINA_HOME/bin/setenv.sh"
        else
            echo_warn "未找到配置文件路径，请输入配置文件路径"
            config_path=$(_input_exists_file "配置文件路径 [prod.datasource.properties] :")
            echo "JAVA_OPTS=\"\$JAVA_OPTS -Dbond.externalDataSource=${config_path}\"" >> "$CATALINA_HOME/bin/setenv.sh"
        fi
    fi

fi

if  [ $(grep "${IGN_CMT}" "$CATALINA_HOME/bin/setenv.sh" | grep -c "${extds_m}") -gt 0 ] 
then
    config_path=$(grep "${IGN_CMT}" "$CATALINA_HOME/bin/setenv.sh" | grep "${extds_m}"|  tr '\"' '|' | tr ' ' '|' | tr "'" '|' |  grep -Po '(?<=bond.externalDataSource=).+?(?=\|.*)')
    echo_success "找到应用参数配置文件：${config_path}"
fi

if [ $(grep "${IGN_CMT}" "${config_path}" | grep -c "ftp_url") -le 0 ]
then
    echo_info "备份配置文件"
    cp ${config_path} "${config_path}.bk_$(date '+%Y%m%d%H%M%S')"
    echo_info "追加新的配置项"
    echo "ftp_url=ftp://23.1.161.18/data/jhpt/source/FAS/FDS/SLR" >> ${config_path}
    echo "ftp_name=fas" >> ${config_path}
    echo "ftp_password=fas" >> ${config_path}
    echo_info "更新配置文件成功"
fi

ticup_dbp="\-DTICUP_GATEWAY_DB_FILE_PATH\=" 
if [ $(grep "${IGN_CMT}" "$CATALINA_HOME/bin/setenv.sh" | grep -c "${ticup_dbp}") -le 0 ] 
then
    if [ -d "${ctx}/storage" ] 
    then
        db_path="${ctx}/storage"
    else
        echo_warn "未找到配置文件路径，请输入数据文件存放路径"
        db_path=$(_input_exists_dir "数据文件路径 [/tomcat/storage] :")
    fi
    echo_success "设置数据存放路径为 ${db_path}"
    echo "JAVA_OPTS=\"\$JAVA_OPTS -DTICUP_GATEWAY_DB_FILE_PATH=${db_path}\"" >> "$CATALINA_HOME/bin/setenv.sh"
else
    db_path=$(grep "${IGN_CMT}" "$CATALINA_HOME/bin/setenv.sh" | grep "${ticup_dbp}"|  tr '\"' '|' | tr ' ' '|' | tr "'" '|' |  grep -Po '(?<=DTICUP_GATEWAY_DB_FILE_PATH=).+?(?=\|.*)')
    echo_success "数据存放路径：${db_path}"
fi


_check_tomcat_starter(){
    while true
    do
        if [ $(grep -c "org.apache.catalina.startup.Catalina.start Server startup in" "${CATALINA_HOME}/logs/catalina.out" ) -gt 0 ] 
        then
            echo_success "应用启动成功"
            break
        fi
        sleep 5
    done
}

echo_info "更新部署应用"
if [ -f "$(pwd)/bond.war" ]
then
    rm -rf $CATALINA_HOME/webapps/bond
    rm -rf $CATALINA_HOME/webapps/bond.war
    cp "$(pwd)/bond.war" $CATALINA_HOME/webapps/
    echo_success "成功替换应用包"
    echo_info "清空日志"

    echo "" > "${CATALINA_HOME}/logs/catalina.out"

    echo_info "启动tomcat"
    $CATALINA_HOME/bin/catalina.sh start > /dev/null 2>&1
    sleep 2

    if _os_is_mac
    then
        t_pid=$(ps | grep java | grep tomcat | awk '{print $1}')
    else
        t_pid=$(ps -ef | grep java | grep tomcat | awk '$8 != "grep" {print $2}')
    fi

    if [ ${#t_pid} -gt 0 ]
    then
        echo_success "启动tomcat成功"
        echo_info "等待应用启动"
        _check_tomcat_starter

        if [ -f "$(pwd)/test.xml" ]
        then
            test_post_date=$(cat $(pwd)/test.xml)
            test_out="$(pwd)/test_result_$(date '+%Y%m%d%H%M%S').out"
            echo_info "开始测试..."
            res=$(curl --data "${test_post_date}" --write-out %{http_code} --silent --output "${test_out}" http://localhost:8080/bond/gateway)
            if [ ${res} -eq 200 ]
            then
                echo_success "应用测试成功,响应文件路径：${test_out}"
            else
                echo_error "应用测试失败,响应文件路径: ${test_out}"
            fi

        else
            echo_warn "找不到待测试的报文，跳过测试"
        fi

    else
        echo_error "启动tomcat失败，请手动启动"
    fi

else 
    echo_error "找不到要部署的应用"
fi

