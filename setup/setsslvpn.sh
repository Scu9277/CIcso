#!/bin/bash

# ScuSSLVPN 一键安装/卸载脚本
# 此脚本用于下载、安装、配置和卸载 ScuSSLVPN 服务
#
# 作者: Duang x shangkouyou
# 邮箱: shangkouyou@gmail.com
# 微信: shangkouyou
#

set -e  # 遇到错误时退出

# 颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# ========== 配置区域 ==========
# GitHub 代理设置（中国大陆用户可修改此处）
GITHUB_PROXY="https://ghfast.top/"  # 留空则不使用代理
# 原始 GitHub 下载地址
GITHUB_RELEASE_URL="https://github.com/Scu9277/CIcso/releases/download/1.0/ScuSSLVPN.zip"
# ==============================

TEMP_DIR="/tmp/scusslvpn-install"
INSTALL_DIR="/etc/ScuSSLVPN"
CONF_DIR="/etc/ScuSSLVPN/conf"
LOG_DIR="/var/log/ScuSSLVPN"
SERVICE_NAME="ScuSSLVPN"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

# 打印函数
print_info() {
    echo -e "${GREEN}[信息]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[警告]${NC} $1"
}

print_error() {
    echo -e "${RED}[错误]${NC} $1"
}

# 检测是否为中国大陆 IP
detect_china_ip() {
    print_info "正在检测网络环境..."
    
    # 尝试通过多个服务检测 IP 地理位置
    local is_china=0
    
    # 方法1: 使用 cip.cc (支持中文)
    if command -v curl &> /dev/null; then
        local country=$(curl -s --connect-timeout 5 https://cip.cc 2>/dev/null | grep -i "地址" | awk '{print $3}')
        if [[ "$country" == *"中国"* ]]; then
            is_china=1
        fi
    fi
    
    # 方法2: 如果方法1失败，使用 ip-api.com
    if [ $is_china -eq 0 ]; then
        if command -v curl &> /dev/null; then
            local country_code=$(curl -s --connect-timeout 5 "http://ip-api.com/line/?fields=countryCode" 2>/dev/null)
            if [ "$country_code" == "CN" ]; then
                is_china=1
            fi
        fi
    fi
    
    # 方法3: 测试直连 GitHub 的速度
    if [ $is_china -eq 0 ]; then
        if ! curl -s --connect-timeout 3 https://github.com &> /dev/null; then
            print_warn "检测到 GitHub 连接困难，可能位于中国大陆"
            is_china=1
        fi
    fi
    
    if [ $is_china -eq 1 ]; then
        print_warn "检测到您可能位于中国大陆，将使用 GitHub 代理加速下载"
        if [ -n "$GITHUB_PROXY" ]; then
            GITHUB_RELEASE_URL="${GITHUB_PROXY}${GITHUB_RELEASE_URL}"
            print_info "使用代理地址: $GITHUB_PROXY"
        fi
    else
        print_info "检测到海外网络环境，将直连 GitHub 下载"
    fi
}

# 检查是否以 root 权限运行
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "请使用 root 权限或 sudo 运行此脚本"
        exit 1
    fi
}

# 检测操作系统类型
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    elif [ -f /etc/redhat-release ]; then
        OS="centos"
    elif [ -f /etc/debian_version ]; then
        OS="debian"
    else
        OS="unknown"
    fi
    
    print_info "检测到操作系统: $OS"
}

# 安装依赖包
install_dependencies() {
    print_info "正在检查并安装依赖包..."
    
    local packages_to_install=()
    
    # 检查 unzip
    if ! command -v unzip &> /dev/null; then
        print_warn "未找到 unzip，将进行安装"
        packages_to_install+=("unzip")
    fi
    
    # 检查 iptables
    if ! command -v iptables &> /dev/null; then
        print_warn "未找到 iptables，将进行安装"
        packages_to_install+=("iptables")
    fi
    
    # 检查 ip 命令（iproute/iproute2）
    if ! command -v ip &> /dev/null; then
        print_warn "未找到 ip 命令，将进行安装 iproute"
        if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
            packages_to_install+=("iproute2")
        else
            packages_to_install+=("iproute")
        fi
    fi
    
    # 如果有需要安装的包
    if [ ${#packages_to_install[@]} -gt 0 ]; then
        print_info "需要安装以下依赖: ${packages_to_install[*]}"
        
        if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
            print_info "使用 apt-get 安装依赖..."
            apt-get update -qq
            apt-get install -y ${packages_to_install[@]}
        elif [[ "$OS" == "centos" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "fedora" ]]; then
            print_info "使用 yum 安装依赖..."
            yum install -y ${packages_to_install[@]}
        else
            print_error "不支持的操作系统: $OS"
            print_info "请手动安装以下依赖: ${packages_to_install[*]}"
            exit 1
        fi
        
        print_info "依赖安装完成"
    else
        print_info "所有依赖已安装"
    fi
}

# 检查系统要求
check_requirements() {
    print_info "正在检查系统要求..."
    
    # 检查 systemd 是否可用
    if ! command -v systemctl &> /dev/null; then
        print_error "需要 systemd 但未找到"
        exit 1
    fi
    
    # 检查 wget 或 curl 是否可用
    if ! command -v wget &> /dev/null && ! command -v curl &> /dev/null; then
        print_error "需要 wget 或 curl 但未找到"
        exit 1
    fi
    
    print_info "系统要求检查通过"
}

# 停止现有服务（如果正在运行）
stop_existing_service() {
    if systemctl is-active --quiet ${SERVICE_NAME}; then
        print_warn "正在停止现有的 ${SERVICE_NAME} 服务..."
        systemctl stop ${SERVICE_NAME}
    fi
    
    if systemctl is-enabled --quiet ${SERVICE_NAME} 2>/dev/null; then
        print_warn "正在禁用现有的 ${SERVICE_NAME} 服务..."
        systemctl disable ${SERVICE_NAME}
    fi
}

# 创建必要的目录
create_directories() {
    print_info "正在创建安装目录..."
    
    mkdir -p ${INSTALL_DIR}
    mkdir -p ${CONF_DIR}
    mkdir -p ${LOG_DIR}
    mkdir -p ${TEMP_DIR}
    
    print_info "目录创建成功"
}

# 下载并解压文件
download_and_extract() {
    print_info "正在从 GitHub 下载 ScuSSLVPN..."
    
    cd ${TEMP_DIR}
    
    # 使用 wget 或 curl 下载
    if command -v wget &> /dev/null; then
        wget -O ScuSSLVPN.zip ${GITHUB_RELEASE_URL}
    else
        curl -L -o ScuSSLVPN.zip ${GITHUB_RELEASE_URL}
    fi
    
    if [ ! -f "ScuSSLVPN.zip" ]; then
        print_error "下载 ScuSSLVPN.zip 失败"
        exit 1
    fi
    
    print_info "正在解压文件..."
    unzip -o ScuSSLVPN.zip
    
    print_info "下载和解压完成"
}

# 安装文件
install_files() {
    print_info "正在安装 ScuSSLVPN 文件..."
    
    cd ${TEMP_DIR}
    
    # 安装二进制文件
    if [ -f "scu-sslvpn" ]; then
        cp scu-sslvpn ${INSTALL_DIR}/
        chmod +x ${INSTALL_DIR}/scu-sslvpn
        print_info "二进制文件已安装到 ${INSTALL_DIR}/scu-sslvpn"
    else
        print_error "在压缩包中未找到二进制文件 'scu-sslvpn'"
        exit 1
    fi
    
    # 安装配置文件
    if [ -d "conf" ]; then
        cp -r conf/* ${CONF_DIR}/
        print_info "配置文件已安装到 ${CONF_DIR}/"
    else
        print_warn "在压缩包中未找到配置目录 'conf'"
    fi
    
    # 设置适当的权限
    chown -R root:root ${INSTALL_DIR}
    chown -R root:root ${LOG_DIR}
    chmod -R 755 ${INSTALL_DIR}
    chmod -R 755 ${CONF_DIR}
    chmod -R 755 ${LOG_DIR}
    
    print_info "文件安装成功"
}

# 配置 IP 转发
setup_ip_forwarding() {
    print_info "正在配置 IP 转发..."
    
    # 检查当前 IP 转发状态
    local current_forward=$(cat /proc/sys/net/ipv4/ip_forward)
    
    if [ "$current_forward" == "1" ]; then
        print_info "IP 转发已启用"
    else
        print_warn "IP 转发未启用，正在配置..."
        
        # 临时启用 IP 转发
        sysctl -w net.ipv4.ip_forward=1
        
        # 永久启用 IP 转发
        if ! grep -q "^net.ipv4.ip_forward" /etc/sysctl.conf; then
            echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
            print_info "已将 IP 转发配置写入 /etc/sysctl.conf"
        else
            sed -i 's/^net.ipv4.ip_forward.*/net.ipv4.ip_forward = 1/' /etc/sysctl.conf
            print_info "已更新 /etc/sysctl.conf 中的 IP 转发配置"
        fi
        
        # 应用配置
        sysctl -p > /dev/null 2>&1
        
        # 验证配置
        local new_forward=$(cat /proc/sys/net/ipv4/ip_forward)
        if [ "$new_forward" == "1" ]; then
            print_info "IP 转发配置成功"
        else
            print_error "IP 转发配置失败"
            exit 1
        fi
    fi
}

# 配置 NAT 转发
setup_nat_forwarding() {
    print_info "正在配置 NAT 转发..."
    
    # 关闭 firewalld（如果存在）
    if command -v firewalld &> /dev/null || systemctl list-unit-files | grep -q firewalld; then
        if systemctl is-active --quiet firewalld 2>/dev/null; then
            print_warn "正在停止 firewalld 服务..."
            systemctl stop firewalld.service
        fi
        
        if systemctl is-enabled --quiet firewalld 2>/dev/null; then
            print_warn "正在禁用 firewalld 服务..."
            systemctl disable firewalld.service
        fi
        print_info "firewalld 已停止并禁用"
    fi
    
    # 获取默认网络接口
    local default_interface=$(ip route | grep default | awk '{print $5}' | head -n1)
    
    if [ -z "$default_interface" ]; then
        print_warn "无法自动检测网络接口，使用 eth0 作为默认值"
        default_interface="eth0"
    else
        print_info "检测到默认网络接口: $default_interface"
    fi
    
    # 尝试从配置文件中读取 VPN 网段
    local vpn_subnet=""
    if [ -f "${CONF_DIR}/server.toml" ]; then
        vpn_subnet=$(grep "^ipv4_cidr" "${CONF_DIR}/server.toml" 2>/dev/null | awk -F'"' '{print $2}' | head -n1)
    fi
    
    # 如果无法从配置文件读取，使用常见的私有网段
    if [ -z "$vpn_subnet" ]; then
        print_warn "无法从配置文件读取 VPN 网段，将配置常见私有网段的 NAT 转发"
    else
        print_info "检测到 VPN 网段: $vpn_subnet"
    fi
    
    # 定义要配置的网段列表（包括常见的私有网段）
    local subnets_to_configure=()
    
    if [ -n "$vpn_subnet" ]; then
        # 如果检测到配置文件中的网段，优先使用
        subnets_to_configure+=("$vpn_subnet")
    else
        # 否则配置所有常见私有网段以确保兼容性
        subnets_to_configure+=(
            "10.0.0.0/8"        # Class A 私有网段
            "172.16.0.0/12"     # Class B 私有网段
            "192.168.0.0/16"    # Class C 私有网段
        )
    fi
    
    print_info "将为以下网段配置 NAT 转发: ${subnets_to_configure[*]}"
    
    # 为每个网段配置 NAT 规则
    for subnet in "${subnets_to_configure[@]}"; do
        # 检查 iptables NAT 规则是否已存在
        if ! iptables -t nat -C POSTROUTING -s $subnet -o $default_interface -j MASQUERADE 2>/dev/null; then
            print_info "正在为 $subnet 添加 NAT MASQUERADE 规则..."
            iptables -t nat -A POSTROUTING -s $subnet -o $default_interface -j MASQUERADE
        else
            print_info "$subnet 的 NAT MASQUERADE 规则已存在"
        fi
        
        # 添加 FORWARD 规则（如果不存在）
        if ! iptables -C FORWARD -s $subnet -j ACCEPT 2>/dev/null; then
            iptables -A FORWARD -s $subnet -j ACCEPT
            print_info "$subnet 的 FORWARD 规则已添加"
        else
            print_info "$subnet 的 FORWARD 规则已存在"
        fi
    done
    
    # 保存 iptables 规则
    if command -v iptables-save &> /dev/null; then
        if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
            # Debian/Ubuntu 系统
            if command -v netfilter-persistent &> /dev/null; then
                netfilter-persistent save
                print_info "iptables 规则已保存（netfilter-persistent）"
            elif [ -f /etc/init.d/iptables-persistent ]; then
                /etc/init.d/iptables-persistent save
                print_info "iptables 规则已保存（iptables-persistent）"
            else
                print_warn "未找到 iptables 规则持久化工具，规则可能在重启后丢失"
                print_info "建议安装: apt-get install iptables-persistent"
            fi
        elif [[ "$OS" == "centos" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "fedora" ]]; then
            # CentOS/RHEL 系统
            if command -v service &> /dev/null; then
                service iptables save 2>/dev/null || iptables-save > /etc/sysconfig/iptables 2>/dev/null
                print_info "iptables 规则已保存"
            else
                iptables-save > /etc/sysconfig/iptables 2>/dev/null
                print_info "iptables 规则已保存到 /etc/sysconfig/iptables"
            fi
        fi
    fi
    
    # 显示当前 NAT 规则
    echo ""
    print_info "当前 NAT 转发规则："
    iptables -t nat -L POSTROUTING -n -v --line-numbers | grep "MASQUERADE" || echo "  无 MASQUERADE 规则"
    echo ""
    
    print_info "NAT 转发配置完成"
}

# 创建 systemd 服务
create_service() {
    print_info "正在创建 systemd 服务..."
    
    cat > ${SERVICE_FILE} << 'EOF'
[Unit]
Description=ScuSSLVPN Server Service
After=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/ScuSSLVPN/
Restart=on-failure
RestartSec=5s
ExecStart=/etc/ScuSSLVPN/scu-sslvpn --conf=/etc/ScuSSLVPN/conf/server.toml

# systemctl --version

# systemd older than v236
# ExecStart=/bin/bash -c 'exec /etc/ScuSSLVPN/scu-sslvpn --conf=/etc/ScuSSLVPN/conf/server.toml >> /var/log/ScuSSLVPN/ScuSSLVPN.log 2>&1'

# systemd new than v236
# StandardOutput=file:/var/log/ScuSSLVPN/ScuSSLVPN-systemd.log
# StandardError=file:/var/log/ScuSSLVPN/ScuSSLVPN-systemd.log

[Install]
WantedBy=multi-user.target
EOF
    
    print_info "Systemd 服务文件已创建: ${SERVICE_FILE}"
}

# 启用并启动服务
start_service() {
    print_info "正在重新加载 systemd 守护进程..."
    systemctl daemon-reload
    
    print_info "正在启用 ${SERVICE_NAME} 服务..."
    systemctl enable ${SERVICE_NAME}
    
    print_info "正在启动 ${SERVICE_NAME} 服务..."
    systemctl start ${SERVICE_NAME}
    
    # 等待服务启动
    sleep 2
    
    # 检查服务状态
    if systemctl is-active --quiet ${SERVICE_NAME}; then
        print_info "${SERVICE_NAME} 服务已成功运行！"
    else
        print_error "${SERVICE_NAME} 服务启动失败"
        print_info "查看日志: journalctl -u ${SERVICE_NAME} -n 50"
        exit 1
    fi
}

# 清理临时文件
cleanup() {
    print_info "正在清理临时文件..."
    rm -rf ${TEMP_DIR}
    print_info "清理完成"
}

# 获取服务器IP地址
get_server_ips() {
    local public_ip=""
    local private_ip=""
    
    # 获取公网IP
    if command -v curl &> /dev/null; then
        public_ip=$(curl -s --connect-timeout 3 https://api.ipify.org 2>/dev/null || curl -s --connect-timeout 3 http://ifconfig.me 2>/dev/null || echo "")
    fi
    
    # 如果获取公网IP失败
    if [ -z "$public_ip" ]; then
        public_ip="无法获取"
    fi
    
    # 获取内网IP
    private_ip=$(ip route get 1 2>/dev/null | awk '{print $7; exit}' || hostname -I 2>/dev/null | awk '{print $1}')
    
    # 如果获取内网IP失败
    if [ -z "$private_ip" ]; then
        private_ip="无法获取"
    fi
    
    echo "${public_ip}|${private_ip}"
}

# 显示服务信息
display_info() {
    local ips=$(get_server_ips)
    local public_ip=$(echo "$ips" | cut -d'|' -f1)
    local private_ip=$(echo "$ips" | cut -d'|' -f2)
    
    echo ""
    echo "=========================================="
    print_info "ScuSSLVPN 安装完成！"
    echo "=========================================="
    echo ""
    echo "安装目录："
    echo "  二进制文件: ${INSTALL_DIR}/scu-sslvpn"
    echo "  配置文件:   ${CONF_DIR}/"
    echo "  日志文件:   ${LOG_DIR}/"
    echo ""
    echo "=========================================="
    echo -e "${GREEN}访问信息：${NC}"
    echo "=========================================="
    echo -e "${YELLOW}服务器IP地址:${NC}"
    echo "  公网IP: ${public_ip}"
    echo "  内网IP: ${private_ip}"
    echo ""
    echo -e "${YELLOW}后台管理页面:${NC}"
    echo "  公网访问: https://${public_ip}:1024"
    echo "  内网访问: https://${private_ip}:1024"
    echo ""
    echo -e "${YELLOW}Cisco 连接端口:${NC}"
    echo "  TCP: 443"
    echo "  UDP: 443"
    echo ""
    echo -e "${YELLOW}管理员账户信息:${NC}"
    echo "  请联系作者获取默认管理员账户"
    echo "  邮箱: shangkouyou@gmail.com"
    echo "  微信: shangkouyou"
    echo "=========================================="
    echo ""
    echo "服务管理命令："
    echo "  启动服务:   systemctl start ${SERVICE_NAME}"
    echo "  停止服务:   systemctl stop ${SERVICE_NAME}"
    echo "  重启服务:   systemctl restart ${SERVICE_NAME}"
    echo "  查看状态:   systemctl status ${SERVICE_NAME}"
    echo "  查看日志:   journalctl -u ${SERVICE_NAME} -f"
    echo "  重载配置:   systemctl daemon-reload"
    echo ""
    echo "当前服务状态："
    systemctl status ${SERVICE_NAME} --no-pager -l
    echo ""
}

# 卸载 ScuSSLVPN
uninstall_scusslvpn() {
    print_warn "开始卸载 ScuSSLVPN..."
    echo ""
    
    # 确认卸载
    read -p "$(echo -e "${RED}确定要卸载 ScuSSLVPN 吗？此操作将删除所有文件和配置！(yes/no): ${NC}")" confirm
    if [ "$confirm" != "yes" ]; then
        print_info "取消卸载"
        exit 0
    fi
    
    # 停止并禁用服务
    if systemctl is-active --quiet ${SERVICE_NAME}; then
        print_info "正在停止 ${SERVICE_NAME} 服务..."
        systemctl stop ${SERVICE_NAME}
    fi
    
    if systemctl is-enabled --quiet ${SERVICE_NAME} 2>/dev/null; then
        print_info "正在禁用 ${SERVICE_NAME} 服务..."
        systemctl disable ${SERVICE_NAME}
    fi
    
    # 删除 systemd 服务文件
    if [ -f "${SERVICE_FILE}" ]; then
        print_info "正在删除服务文件..."
        rm -f ${SERVICE_FILE}
        systemctl daemon-reload
    fi
    
    # 删除安装目录
    if [ -d "${INSTALL_DIR}" ]; then
        print_info "正在删除安装目录: ${INSTALL_DIR}"
        rm -rf ${INSTALL_DIR}
    fi
    
    # 删除日志目录
    if [ -d "${LOG_DIR}" ]; then
        print_info "正在删除日志目录: ${LOG_DIR}"
        rm -rf ${LOG_DIR}
    fi
    
    # 清理 IP 转发配置（可选）
    read -p "$(echo -e "${YELLOW}是否要禁用 IP 转发配置？(yes/no): ${NC}")" disable_forward
    if [ "$disable_forward" == "yes" ]; then
        print_info "正在禁用 IP 转发..."
        sysctl -w net.ipv4.ip_forward=0
        sed -i 's/^net.ipv4.ip_forward.*/net.ipv4.ip_forward = 0/' /etc/sysctl.conf 2>/dev/null || true
        sysctl -p > /dev/null 2>&1
        print_info "IP 转发已禁用"
    fi
    
    # 清理 NAT 转发规则（可选）
    read -p "$(echo -e "${YELLOW}是否要清理 NAT 转发规则？(yes/no): ${NC}")" clean_nat
    if [ "$clean_nat" == "yes" ]; then
        print_info "正在清理 NAT 转发规则..."
        
        # 尝试从配置文件读取 VPN 网段
        local vpn_subnet=""
        if [ -f "${CONF_DIR}/server.toml" ]; then
            vpn_subnet=$(grep "^ipv4_cidr" "${CONF_DIR}/server.toml" 2>/dev/null | awk -F'"' '{print $2}' | head -n1)
        fi
        
        # 定义要清理的网段列表
        local subnets_to_clean=()
        if [ -n "$vpn_subnet" ]; then
            subnets_to_clean+=("$vpn_subnet")
        else
            # 清理所有常见私有网段
            subnets_to_clean+=(
                "10.0.0.0/8"
                "172.16.0.0/12"
                "192.168.0.0/16"
            )
        fi
        
        local default_interface=$(ip route | grep default | awk '{print $5}' | head -n1)
        
        if [ -n "$default_interface" ]; then
            for subnet in "${subnets_to_clean[@]}"; do
                # 删除 NAT 规则
                iptables -t nat -D POSTROUTING -s $subnet -o $default_interface -j MASQUERADE 2>/dev/null && \
                    print_info "已删除 $subnet 的 NAT 规则" || true
                # 删除 FORWARD 规则
                iptables -D FORWARD -s $subnet -j ACCEPT 2>/dev/null && \
                    print_info "已删除 $subnet 的 FORWARD 规则" || true
            done
            
            print_info "NAT 转发规则已清理"
            
            # 保存 iptables 规则
            if command -v iptables-save &> /dev/null; then
                if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
                    if command -v netfilter-persistent &> /dev/null; then
                        netfilter-persistent save
                    fi
                elif [[ "$OS" == "centos" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "fedora" ]]; then
                    service iptables save 2>/dev/null || iptables-save > /etc/sysconfig/iptables 2>/dev/null
                fi
            fi
        fi
    fi
    
    echo ""
    echo "=========================================="
    print_info "ScuSSLVPN 卸载完成！"
    echo "=========================================="
    echo ""
}

# 主安装流程
install_scusslvpn() {
    print_info "开始安装 ScuSSLVPN..."
    echo ""
    
    check_root
    detect_os
    check_requirements
    install_dependencies
    detect_china_ip
    stop_existing_service
    create_directories
    download_and_extract
    install_files
    setup_ip_forwarding
    setup_nat_forwarding
    create_service
    start_service
    cleanup
    display_info
    
    print_info "安装成功完成！"
}

# 显示菜单
show_menu() {
    echo ""
    echo "=========================================="
    echo -e "${BLUE}    ScuSSLVPN 管理脚本${NC}"
    echo "=========================================="
    echo "1. 安装 ScuSSLVPN"
    echo "2. 卸载 ScuSSLVPN"
    echo "3. 退出"
    echo "=========================================="
    echo -e "${GREEN}作者: Duang x shangkouyou${NC}"
    echo -e "邮箱: shangkouyou@gmail.com"
    echo -e "微信: shangkouyou"
    echo "=========================================="
    echo ""
}

# 主函数
main() {
    check_root
    
    # 如果提供了命令行参数
    if [ $# -gt 0 ]; then
        case "$1" in
            install)
                install_scusslvpn
                ;;
            uninstall)
                uninstall_scusslvpn
                ;;
            *)
                echo "用法: $0 {install|uninstall}"
                echo "或直接运行脚本使用交互式菜单"
                exit 1
                ;;
        esac
    else
        # 交互式菜单
        while true; do
            show_menu
            read -p "请选择操作 [1-3]: " choice
            
            case $choice in
                1)
                    install_scusslvpn
                    break
                    ;;
                2)
                    uninstall_scusslvpn
                    break
                    ;;
                3)
                    print_info "退出脚本"
                    exit 0
                    ;;
                *)
                    print_error "无效的选择，请输入 1-3"
                    sleep 1
                    ;;
            esac
        done
    fi
}

# 运行主函数
main
