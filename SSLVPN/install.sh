#!/bin/bash

# ==================================================
#   项目: Scu SSLVPN 一键部署脚本
#   作者: shangkouyou Duang Scu
#   微信: shangkouyou
#   邮箱: shangkouyou@gmail.com
#   版本: v1.5 (Dual-Stack & Smart Reinstall)
# ==================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# 变量定义
PROJECT_NAME="scu-sslvpn"
INSTALL_PATH="/etc/SSLVPN"
DOWNLOAD_URL="https://github.com/Scu9277/CIcso/releases/download/1.1/SSLVPN.zip"
ZIP_FILE="/tmp/SSLVPN.zip"

# --- GitHub 代理列表 ---
GITHUB_PROXIES=(
    "直接连接 (国外/专线)"
    "https://ghfast.top/"
    "https://gh-proxy.org/"
    "https://hk.gh-proxy.org/"
    "https://cdn.gh-proxy.org/"
    "https://edgeone.gh-proxy.org/"
)

# 展示 Logo
show_logo() {
    echo -e "${CYAN}"
    echo " ▗▄▄▖▗▖ ▗▖ ▗▄▖ ▗▖  ▗▖ ▗▄▄▖▗▖ ▗▖ ▗▄▖ ▗▖ ▗▖▗▖  ▗▖▗▄▖ ▗▖ ▗▖";
    echo "▐▌   ▐▌ ▐▌▐▌ ▐▌▐▛▚▖▐▌▐▌   ▐▌▗▞▘▐▌ ▐▌▐▌ ▐▌ ▝▚▞▘▐▌ ▐▌▐▌ ▐▌";
    echo " ▝▀▚▖▐▛▀▜▌▐▛▀▜▌▐▌ ▝▜▌▐▌▝▜▌▐▛▚▖ ▐▌ ▐▌▐▌ ▐▌  ▐▌ ▐▌ ▐▌▐▌ ▐▌";
    echo "▗▄▄▞▘▐▌ ▐▌▐▌ ▐▌▐▌  ▐▌▝▚▄▞▘▐▌ ▐▌▝▚▄▞▘▝▚▄▞▘  ▐▌ ▝▚▄▞▘▝▚▄▞▘";
    echo -e "${NC}"
    echo "=================================================="
    echo -e "     项目: ${BLUE}${PROJECT_NAME}${NC}"
    echo -e "     作者: ${GREEN}shangkouyou Duang Scu${NC}"
    echo -e "     微信: ${GREEN}shangkouyou${NC} | 邮箱: ${GREEN}shangkouyou@gmail.com${NC}"
    echo -e "     服务器 AFF 推荐 (Scu 导航站): ${YELLOW}https://dh.21i.icu/${NC}"
    echo "=================================================="
}

# 权限检查
check_root() {
    [[ $EUID -ne 0 ]] && echo -e "${RED}错误: 必须使用 root 权限运行此脚本!${NC}" && exit 1
}

# 选择 GitHub 代理
select_github_proxy() {
    # 如果文件已经存在，可能不需要重新选择代理下载
    if [ -f "$INSTALL_PATH/scu-sslvpn-linux-amd64" ] && [ -f "$INSTALL_PATH/config.yaml" ]; then
        return
    fi

    echo -e "${YELLOW}请选择 GitHub 下载代理 (国内环境建议选择):${NC}"
    for i in "${!GITHUB_PROXIES[@]}"; do
        echo -e "  $i. ${GITHUB_PROXIES[$i]}"
    done
    read -p "请输入序号 [0-5]: " proxy_idx
    
    if [[ "$proxy_idx" == "0" || -z "$proxy_idx" ]]; then
        FINAL_URL="${DOWNLOAD_URL}"
    else
        FINAL_URL="${GITHUB_PROXIES[$proxy_idx]}${DOWNLOAD_URL}"
    fi
}

# 安装依赖
install_deps() {
    echo -e "[${BLUE}1/7${NC}] ${CYAN}正在检查并安装基础依赖...${NC}"
    apt update -y
    apt install -y wget unzip iptables kmod curl grep
}

# 自动识别网卡
detect_interface() {
    echo -e "[${BLUE}2/7${NC}] ${CYAN}正在识别系统网卡...${NC}"
    INTERFACE=$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'dev \K\S+')
    [ -z "$INTERFACE" ] && INTERFACE=$(ip -o link show | grep -v "lo\|virbr\|docker\|tun" | head -n1 | cut -d":" -f2 | xargs)
    [ -z "$INTERFACE" ] && INTERFACE="eth0"
    echo -e "${GREEN}自动识别出口网卡: $INTERFACE${NC}"
}

# 下载并解压
setup_files() {
    REAL_BIN="$INSTALL_PATH/scu-sslvpn-linux-amd64"
    CONFIG_FILE="$INSTALL_PATH/config.yaml"

    if [ -f "$REAL_BIN" ] && [ -f "$CONFIG_FILE" ]; then
        echo -e "[${BLUE}3/7${NC}] ${YELLOW}检测到资源文件已存在，跳过下载。正在尝试重启服务...${NC}"
        chmod +x "$REAL_BIN"
        return
    fi

    echo -e "[${BLUE}3/7${NC}] ${CYAN}正在从 GitHub 下载 ${PROJECT_NAME} 资源包...${NC}"
    wget -q --show-progress -O "$ZIP_FILE" "$FINAL_URL" || { echo -e "${RED}下载失败!${NC}"; exit 1; }
    
    echo -e "${CYAN}正在解压并部署文件到 $INSTALL_PATH ...${NC}"
    mkdir -p "$INSTALL_PATH"
    unzip -o "$ZIP_FILE" -d "$INSTALL_PATH"
    
    [ -d "$INSTALL_PATH/SSLVPN" ] && { cp -r "$INSTALL_PATH/SSLVPN/"* "$INSTALL_PATH/"; rm -rf "$INSTALL_PATH/SSLVPN"; }
    
    # 再次检查确认二进制文件名字并赋予执行权限
    if [ -f "$REAL_BIN" ]; then
        chmod +x "$REAL_BIN"
    else
        # 兜底：如果没找到，再尝试模糊匹配
        REAL_BIN=$(find "$INSTALL_PATH" -maxdepth 1 -type f -name "sslvpn*" -o -name "SSLVPN*" -o -name "*scu-sslvpn*" | head -n 1)
        [ -n "$REAL_BIN" ] && chmod +x "$REAL_BIN" || { echo -e "${RED}未发现二进制执行文件 scu-sslvpn-linux-amd64 !${NC}"; exit 1; }
    fi
}

# 修改配置
configure_app() {
    echo -e "[${BLUE}4/7${NC}] ${CYAN}正在根据当前环境修正配置文件...${NC}"
    CONFIG_FILE="$INSTALL_PATH/config.yaml"
    if [ -f "$CONFIG_FILE" ]; then
        sed -i "s/ebpfinterfacename: .*/ebpfinterfacename: \"$INTERFACE\"/g" "$CONFIG_FILE"
        sed -i "s|dsn: \"./|dsn: \"$INSTALL_PATH/|g" "$CONFIG_FILE"
    fi
}

# 内核优化配置
optimize_kernel() {
    echo -e "[${BLUE}5/7${NC}] ${CYAN}正在优化内核网络转发参数...${NC}"
    modprobe nf_conntrack 2>/dev/null
    echo "nf_conntrack" > /etc/modules-load.d/sslvpn.conf 2>/dev/null
    cat > /etc/sysctl.d/99-sslvpn.conf <<EOF
net.ipv4.ip_forward = 1
net.netfilter.nf_conntrack_max = 65536
EOF
    sysctl -p /etc/sysctl.d/99-sslvpn.conf >/dev/null 2>&1
    echo 1 > /proc/sys/net/ipv4/ip_forward
}

# 配置 iptables
setup_iptables() {
    echo -e "[${BLUE}6/7${NC}] ${CYAN}正在配置 iptables NAT 转发规则...${NC}"
    VPN_SUBNET=$(grep "network:" "$INSTALL_PATH/config.yaml" | awk '{print $2}' | tr -d '"' | tr -d "'")
    [ -z "$VPN_SUBNET" ] && VPN_SUBNET="10.8.0.0/24"
    
    iptables -t nat -C POSTROUTING -s "$VPN_SUBNET" ! -d "$VPN_SUBNET" -o "$INTERFACE" -j MASQUERADE 2>/dev/null
    if [ $? -ne 0 ]; then
        iptables -t nat -A POSTROUTING -s "$VPN_SUBNET" ! -d "$VPN_SUBNET" -o "$INTERFACE" -j MASQUERADE
    fi
    
    export DEBIAN_FRONTEND=noninteractive
    apt install -y iptables-persistent &>/dev/null
    netfilter-persistent save &>/dev/null
}

# 创建服务
create_service() {
    echo -e "[${BLUE}7/7${NC}] ${CYAN}正在配置 Systemd 系统服务并启动...${NC}"
    cat > /etc/systemd/system/sslvpn.service <<EOF
[Unit]
Description=Scu SSLVPN Service
After=network.target

[Service]
Type=simple
WorkingDirectory=$INSTALL_PATH
ExecStart=$REAL_BIN
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable sslvpn --now
    systemctl restart sslvpn
}

# 最终输出
final_info() {
    # 获取本机 IP
    IPV4=$(curl -s4 https://api.ipify.org || curl -s4 ifconfig.me || hostname -I | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | head -n 1)
    IPV6=$(curl -s6 https://api.ipify.org || curl -s6 ifconfig.co || hostname -I | grep -oE '([a-fA-F0-9:]+:+)+[a-fA-F0-9]+' | head -n 1)
    
    # 获取配置端口
    MGMT_PORT=$(grep "port:" "$INSTALL_PATH/config.yaml" | head -n 1 | awk '{print $2}' | tr -d '"' | tr -d "'")
    VPN_PORT=$(grep "openconnectport:" "$INSTALL_PATH/config.yaml" | head -n 1 | awk '{print $2}' | tr -d '"' | tr -d "'")
    [ -z "$MGMT_PORT" ] && MGMT_PORT="1024"
    [ -z "$VPN_PORT" ] && VPN_PORT="1443"

    echo -e "\n${GREEN}==================================================${NC}"
    echo -e "${GREEN}🎉 ${PROJECT_NAME} 安装/更新成功!${NC}"
    echo -e "=================================================="
    echo -e "${BLUE}服务状态: ${NC}"
    systemctl is-active --quiet sslvpn && echo -e "  - 运行状态: ${GREEN}● Running${NC}" || echo -e "  - 运行状态: ${RED}○ Stopped${NC}"
    
    echo -e "\n${BLUE}访问地址:${NC}"
    if [ -n "$IPV4" ]; then
        echo -e "  - 管理界面 (IPv4): ${YELLOW}http://${IPV4}:${MGMT_PORT}${NC}"
        echo -e "  - VPN 连接 (IPv4): ${YELLOW}https://${IPV4}:${VPN_PORT}${NC}"
    fi
    if [ -n "$IPV6" ]; then
        echo -e "  - 管理界面 (IPv6): ${YELLOW}http://[${IPV6}]:${MGMT_PORT}${NC}"
        echo -e "  - VPN 连接 (IPv6): ${YELLOW}https://[${IPV6}]:${VPN_PORT}${NC}"
    fi
    
    echo -e "\n${BLUE}端口说明:${NC}"
    echo -e "  - ${MGMT_PORT} (TCP): 管理 API 和 Web 界面"
    echo -e "  - ${VPN_PORT} (TCP): OpenConnect/AnyConnect SSL VPN 连接"
    echo -e "  - ${VPN_PORT} (UDP): DTLS 加速连接（可选，提升性能）"
    
    echo -e "\n${BLUE}安装客户端:${NC}"
    echo -e "  ${WHITE}OpenConnect 客户端:${NC}"
    echo -e "    - Linux:   sudo apt install openconnect"
    echo -e "    - macOS:   brew install openconnect"
    echo -e "    - Windows: 请下载 OpenConnect GUI"
    
    echo -e "\n  ${WHITE}Cisco AnyConnect / Secure Client:${NC}"
    echo -e "    - 支持 Windows/macOS/iOS/Android"
    
    echo -e "\n${RED}⚠️  重要提示:${NC}"
    echo -e "  - Cisco Secure Client 需要有效的 CA 签发证书，不支持自签名证书"
    echo -e "  - 自签名证书仅适用于 OpenConnect 客户端"
    echo -e "  - 生产环境建议使用 Let's Encrypt 证书并替换 /etc/SSLVPN/certs/ 下的文件"
    echo -e "${GREEN}==================================================${NC}"
}

main() {
    show_logo
    check_root
    select_github_proxy
    install_deps
    detect_interface
    setup_files
    configure_app
    optimize_kernel
    setup_iptables
    create_service
    final_info
}

main
