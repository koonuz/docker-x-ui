#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

GET_ARCH='amd64'

#consts for log check and clear,unit:M
declare -r DEFAULT_LOG_FILE_DELETE_TRIGGER=35

PATH_FOR_GEO_IP='/usr/local/x-ui/bin/geoip.dat'
PATH_FOR_GEO_SITE='/usr/local/x-ui/bin/geosite.dat'
URL_FOR_GEO_IP='https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat'
URL_FOR_GEO_SITE='https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat'

confirm() {
    if [[ $# > 1 ]]; then
        echo && read -p "$1 [默认$2]: " temp
        if [[ x"${temp}" == x"" ]]; then
            temp=$2
        fi
    else
        read -p "$1 [y/n]: " temp
    fi
    if [[ x"${temp}" == x"y" || x"${temp}" == x"Y" ]]; then
        return 0
    else
        return 1
    fi
}

confirm_restart() {
    confirm "是否重启 x-ui 进程？重启 x-ui 进程也会一并重启 xray 服务" "y"
    if [[ $? == 0 ]]; then
        restart
    else
        show_menu
    fi
}

before_show_menu() {
    echo && echo -n -e "${yellow}按回车返回主菜单: ${plain}" && read temp
    show_menu
}

reset_user() {
    confirm "确定要将用户名和密码重置为 admin 吗？" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    /usr/local/x-ui/x-ui setting -username admin -password admin
    echo -e "用户名和密码已重置为${green}admin${plain}，现在请${yello}重启 x-ui 进程${plain}"
    confirm_restart
}

reset_config() {
    confirm "确定要重置所有关于 x-ui 面板的设置吗？账号数据不会丢失，用户名和密码不会改变" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    /usr/local/x-ui/x-ui setting -reset
    echo -e "所有关于 x-ui 面板的设置已重置为默认值，现在请${yello}重启 x-ui 进程${plain}，并使用默认的${green}54321${plain}端口进行访问"
    confirm_restart
}

check_config() {
    info=$(/usr/local/x-ui/x-ui setting -show true)
    if [[ $? != 0 ]]; then
        echo -e "${red}无法获取当前关于 x-ui 面板的设置${plain}，请检查日志..."
        show_menu
    fi
    echo -e "${info}"
}

start() {
    check_status
    if [[ $? == 0 ]]; then
        echo ""
        echo -e "${yellow}x-ui 进程${plain} 与 ${yellow}xray 服务${plain}已运行，无需再次启动!如需${green}重启x-ui进程${plain}，请${green}选择重启${plain}!"
    else
        sv start x-ui
        sleep 2
        check_status
        if [[ $? == 0 ]]; then
            echo -e "${green}x-ui 进程 与 xray 服务启动成功!${plain}"
        else
            echo -e "${red}启动失败，可能是因为启动时间超过了两秒，稍后请查看日志信息...${plain}"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

stop() {
    check_status
    if [[ $? == 1 ]]; then
        echo ""
        echo -e "${yellow}x-ui 进程${plain} 与 ${yellow}xray 服务${plain}已停止运行，无需再次停止!"
    else
        sv stop x-ui
        sleep 2
        check_status
        if [[ $? == 1 ]]; then
            echo -e "${green}x-ui 进程 与 xray 服务停止成功!${plain}"
        else
            echo -e "${red}停止失败，可能是因为停止时间超过了两秒，稍后请查看日志信息...${plain}"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

restart() {
    sv restart x-ui
    sleep 2
    check_status
    if [[ $? == 0 ]]; then
        echo -e "${green}x-ui 进程 与 xray 服务重启成功!${plain}"
    else
        echo -e "${red}重启失败，可能是因为启动时间超过了两秒，稍后请查看日志信息...${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

check_status() {
    temp=$(sv status x-ui | awk '{print $1}' | cut -d ":" -f1)
    if [[ x"${temp}" == x"run" ]]; then
        return 0
    else
        return 1
    fi
}

check_bbr() {
    count=$(lsmod | grep bbr | wc -l)
    if [[ count -ne 0 ]]; then
        return 0
    else
        return 1
    fi
}

show_bbr() {
    check_bbr
    if [[ $? == 0 ]]; then
        echo -e " BBR  加速算法: ${green}已开启${plain}"
    else
        echo -e " BBR  加速算法: ${red}未开启${plain}"
    fi
}

check_version() {
    version=$(/usr/local/x-ui/x-ui setting -show | grep 'version' | awk '{print $2}' | cut -d ":" -f1)
    echo -e " x-ui 当前版本: ${green}$version${plain}"
}

check_xray_version() {
    xray_version=$(/usr/local/x-ui/bin/xray-linux-${GET_ARCH} version | grep 'Xray' | awk '{print $2}' | cut -d "(" -f1)
    echo -e " Xray 运行版本: ${green}$xray_version${plain}"
}

check_update() {
    last_version=$(curl -Ls "https://api.github.com/repos/FranzKafkaYu/x-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    if [[ "$last_version" == "$version" ]]; then
      echo -e " 当前 x-ui 已是${yellow}最新版本${plain}，无需进行更新..."
    else
      echo -e " 当前 x-ui 版本为: ${green}${version}${plain}，检测到最新版本为: ${yellow}${last_version}${plain}，请手动进行更新..."
    fi
    before_show_menu
}

show_status() {
    check_xray_version
    check_version
    check_status
    case $? in
    0)
        echo -e " x-ui 进程状态: ${green}已运行${plain}"
        ;;
    1)
        echo -e " x-ui 进程状态: ${red}未运行${plain}"
        ;;
    esac
    show_bbr
}

set_port() {
    echo && echo -n -e "输入端口号[1-65535]: " && read port
    if [[ -z "${port}" ]]; then
        echo -e "${yellow}已取消${plain}"
        before_show_menu
    else
        /usr/local/x-ui/x-ui setting -port ${port}
        echo -e "端口已设置完毕，现在请${yellow}重启面板${plain}，并使用新设置的${green}${port}${plain}端口访问面板"
        confirm_restart
    fi
}

migrate_v2_ui() {
    /usr/local/x-ui/x-ui v2-ui
    before_show_menu
}

#add for cron jobs,including sync geo data,check logs and restart x-ui
cron_jobs() {
    clear
    echo -e "
  ${green}x-ui 定时任务管理${plain}
————————————————
  ${green}0.${plain}  返回主菜单
————————————————
  ${green}1.${plain}  开启自动更新geo数据
  ${green}2.${plain}  关闭自动更新geo数据
  ${green}3.${plain}  开启自动清除xray日志
  ${green}4.${plain}  关闭自动清除xray日志
  "
    echo && read -p "请输入选择 [0-4]: " num
    case "${num}" in
    0) show_menu
    ;;
    1) enable_auto_update_geo
    ;;
    2) disable_auto_update_geo
    ;;
    3) enable_auto_clear_log
    ;;
    4) disable_auto_clear_log
    ;;
    *) echo -e "${red}请输入正确的数字 [0-4]${plain}"
    ;;
    esac
}

#update geo data
update_geo() {
    #back up first
    mv ${PATH_FOR_GEO_IP} ${PATH_FOR_GEO_IP}.bak
    #update data
    echo -e "${yello}正在下载geoip最新数据并进行更新...${plain}"
    curl -s -L -o ${PATH_FOR_GEO_IP} ${URL_FOR_GEO_IP}
    if [[ $? -ne 0 ]]; then
        echo -e "geoip.dat ${red}更新失败${plain}"
        mv ${PATH_FOR_GEO_IP}.bak ${PATH_FOR_GEO_IP}
    else
        echo -e "geoip.dat ${green}更新成功${plain}"
        rm -f ${PATH_FOR_GEO_IP}.bak
    fi
    mv ${PATH_FOR_GEO_SITE} ${PATH_FOR_GEO_SITE}.bak
    echo -e "${yello}正在下载geosite最新数据并进行更新...${plain}"
    curl -s -L -o ${PATH_FOR_GEO_SITE} ${URL_FOR_GEO_SITE}
    if [[ $? -ne 0 ]]; then
        echo -e "geosite.dat ${red}更新失败${plain}"
        mv ${PATH_FOR_GEO_SITE}.bak ${PATH_FOR_GEO_SITE}
    else
        echo "geosite.dat ${green}更新成功${plain}"
        rm -f ${PATH_FOR_GEO_SITE}.bak
    fi
    #restart x-ui
    echo -e "${yello}即将重启 x-ui 进程...${plain}"
    restart
}

enable_auto_update_geo() {
    echo -e "${yellow}正在开启geo数据自动更新...${plain}"
    crontab -l >/tmp/crontabTask.tmp
    echo "00 4 */2 * * x-ui geo > /dev/null" >>/tmp/crontabTask.tmp
    crontab /tmp/crontabTask.tmp
    rm /tmp/crontabTask.tmp
    echo -e "${green}开启geo数据自动更新成功${plain}"
}

disable_auto_update_geo() {
    crontab -l | grep -v "x-ui geo" | crontab -
    if [[ $? -ne 0 ]]; then
        echo -e "${red}关闭geo数据自动更新失败${plain}"
    else
        echo -e "${green}关闭geo数据自动更新成功${plain}"
    fi
}

#clear xray log,need enable log in config template
#here we need input an absolute path for log
clear_log() {
    echo -e "${yello}设置清除xray日志...${plain}"
    local filePath=''
    read -p "请输入日志文件路径": filePath
    if [[ $# -gt 0 ]]; then
        filePath=$1
    else
        echo -e "${red}输入的日志文件路径无效,脚本将自动退出...${plain}"
        exit 1
    fi
    echo -e "你输入的日志路径为:${yello}${filePath}${plain}"
    if [[ ! -f ${filePath} ]]; then
        echo -e "${red}清除xray日志文件失败${plain},日志路径${yello}${filePath}${plain}${red}不存在${plain},请重新确认正确的日志路径..."
        exit 1
    fi
    fileSize=$(ls -la ${filePath} --block-size=M | awk '{print $5}' | awk -F 'M' '{print$1}')
    if [[ ${fileSize} -gt ${DEFAULT_LOG_FILE_DELETE_TRIGGER} ]]; then
        rm $1
        if [[ $? -ne 0 ]]; then
            echo -e "${red}清除xray日志文件：${filePath}失败${plain}"
        else
            echo -e "${green}清除xray日志文件：${filePath}成功${plain}"
            sv restart x-ui
        fi
    else
        echo -e "当前日志大小为${yello}${fileSize}${plain}M，小于${red}${DEFAULT_LOG_FILE_DELETE_TRIGGER}${plain}M，日志将不会被清除..."
    fi
}

#enable auto delete log,need file path as
enable_auto_clear_log() {
    echo -e "${yello}设置定时清除xray日志...${plain}"
    local filePath=''
    read -p "请输入日志文件路径": filePath
    if [[ ! -n ${filePath} ]]; then
        echo -e "${red}输入的日志文件路径无效，脚本将自动退出...${plain}"
        exit 1
    fi
    if [[ ! -f ${filePath} ]]; then
        echo -e "日志路径${yello}${filePath}${plain}${red}不存在${plain}，${red}开启自动清除xray日志失败${plain}"
        exit 1
    fi
    crontab -l >/tmp/crontabTask.tmp
    echo "30 4 */2 * * x-ui clear ${filePath} > /dev/null" >>/tmp/crontabTask.tmp
    crontab /tmp/crontabTask.tmp
    rm /tmp/crontabTask.tmp
    echo -e "${green}开启自动清除xray日志成功${plain}"
}

#disable auto dlete log
disable_auto_clear_log() {
    crontab -l | grep -v "x-ui clear" | crontab -
    if [[ $? -ne 0 ]]; then
        echo -e "${red}关闭自动清除xray日志失败${plain}"
    else
        echo -e "${green}关闭自动清除xray日志成功${plain}"
    fi
}

show_usage() {
    echo "x-ui 管理脚本使用方法: "
    echo "------------------------------------------"
    echo "x-ui              - 显示管理菜单 (功能更多)"
    echo "x-ui start        - 启动 x-ui 面板"
    echo "x-ui stop         - 停止 x-ui 面板"
    echo "x-ui restart      - 重启 x-ui 面板"
    echo "x-ui status       - 查看 x-ui 状态"
    echo "x-ui config       - 查看 x-ui 配置"
    echo "x-ui v2-ui        - 迁移 v2-ui 数据至 x-ui"
    echo "x-ui clear        - 清除 x-ui 日志"
    echo "x-ui geo          - 更新 x-ui geo数据"
    echo "x-ui cron         - 管理 x-ui 定时任务"
    echo "------------------------------------------"
}

show_menu() {
    echo -e "
  ${green}x-ui 面板管理脚本${plain}
--- 该版本为 FranzKafkaYu 增强版 ---  
- https://github.com/FranzKafkaYu/x-ui -
  ${green}0.${plain} 退出脚本
————————————————
  ${green}1.${plain} 重置 x-ui 面板的用户名和密码
  ${green}2.${plain} 重置 x-ui 面板的所有设置
  ${green}3.${plain} 设置 x-ui 面板的访问端口
  ${green}4.${plain} 查看 x-ui 面板的所有设置
————————————————
  ${green}5.${plain} 启动 x-ui 进程
  ${green}6.${plain} 停止 x-ui 进程
  ${green}7.${plain} 重启 x-ui 进程
————————————————
  ${green}8.${plain} 更新 x-ui geo数据
  ${green}9.${plain} 管理 x-ui 定时任务
  ${green}10.${plain} 检查 x-ui 版本更新
  ${green}11.${plain} 迁移 v2-ui 数据至 x-ui
———————————————— "
    show_status
    echo && read -p "请输入选择 [0-11]: " num

    case "${num}" in
        0) exit 0
        ;;
        1) reset_user
        ;;
        2) reset_config
        ;;
        3) set_port
        ;;
        4) check_config
        ;;
        5) start
        ;;
        6) stop
        ;;
        7) restart
        ;;
        8) update_geo
        ;;
        9) cron_jobs
        ;;
        10) check_update
        ;;
        11) migrate_v2_ui
        ;;
        *) echo -e "${red}请输入正确的数字【0-11】${plain}"
        ;;
    esac
}

if [[ $# > 0 ]]; then
    case $1 in
    "start")
        start 0
        ;;
    "stop")
        stop 0
        ;;
    "restart")
        restart 0
        ;;
    "status")
        show_status 0
        ;;
    "config")
        check_config 0
        ;;
    "v2-ui")
        migrate_v2_ui 0
        ;;
    "geo")
        update_geo
        ;;
    "clear")
        clear_log $2
        ;;
    "cron")
        cron_jobs
        ;;
    *) show_usage 
        ;;
    esac
else
    show_menu
fi