#!/bin/bash

# ScuSSLVPN 一键安装脚本
# 此脚本用于下载、安装和配置 ScuSSLVPN 服务

set -e  # 遇到错误时退出

# 颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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
    
    # 检查 unzip 是否可用
    if ! command -v unzip &> /dev/null; then
        print_error "需要 unzip 但未找到，请先安装"
        print_info "Ubuntu/Debian 系统: apt-get install unzip"
        print_info "CentOS/RHEL 系统: yum install unzip"
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

# 显示服务信息
display_info() {
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

# 主安装流程
main() {
    print_info "开始安装 ScuSSLVPN..."
    echo ""
    
    check_root
    check_requirements
    detect_china_ip
    stop_existing_service
    create_directories
    download_and_extract
    install_files
    create_service
    start_service
    cleanup
    display_info
    
    print_info "安装成功完成！"
}

# 运行主函数
main
