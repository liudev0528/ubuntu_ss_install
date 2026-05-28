#!/bin/bash

# ==========================================
# Shadowsocks-libev 一键安装脚本（Ubuntu）
# ==========================================

set -e

# 颜色输出
GREEN='\033[0;32m'
NC='\033[0m'
info() { echo -e "${GREEN}[INFO]${NC} $1"; }

# ---------- 读取用户输入 ----------
read -rp "请输入 Shadowsocks 端口（建议 10000-65535）: " SERVER_PORT
read -rsp "请输入 Shadowsocks 密码: " PASSWORD
echo ""

if [[ -z "$SERVER_PORT" || -z "$PASSWORD" ]]; then
    echo " 端口和密码不能为空，脚本退出。"
    exit 1
fi

info "开始安装 Shadowsocks-libev..."

# ---------- 更新系统 ----------
info "更新软件包..."
sudo apt update -y
sudo apt upgrade -y

# ---------- 安装 shadowsocks-libev ----------
info "安装 shadowsocks-libev..."
sudo apt install shadowsocks-libev -y

# ---------- 创建配置目录 ----------
sudo mkdir -p /etc/shadowsocks-libev

# ---------- 写入配置文件 ----------
info "写入配置文件..."
sudo tee /etc/shadowsocks-libev/config.json > /dev/null <<EOL
{
    "server": "0.0.0.0",
    "mode": "tcp_and_udp",
    "server_port": ${SERVER_PORT},
    "local_port": 1080,
    "password": "${PASSWORD}",
    "timeout": 86400,
    "method": "aes-256-gcm"
}
EOL
sed -i 's|^ExecStart=.*|ExecStart=/usr/bin/ss-server -c /etc/shadowsocks-libev/config.json|' \
/lib/systemd/system/shadowsocks-libev.service

# ---------- 开启bbr加速 ----------
echo "net.core.default_qdisc = fq" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control = bbr" | sudo tee -a /etc/sysctl.conf
sysctl -p

# ---------- 启动并设置开机自启 ----------
info "启动 Shadowsocks 服务..."
sudo systemctl daemon-reload
sudo systemctl enable shadowsocks-libev
sudo systemctl restart shadowsocks-libev

# ---------- 检查运行状态 ----------
sleep 2
if sudo systemctl is-active --quiet shadowsocks-libev; then
    info " Shadowsocks-libev 安装成功并已启动！"
else
    echo " Shadowsocks-libev 启动失败，请检查配置或端口是否被占用。"
    exit 1
fi

# ---------- 输出信息 ----------
echo ""
echo "=========================================="
echo " Shadowsocks-libev 安装完成"
echo "=========================================="
echo " 服务器地址: $(curl -s ifconfig.me)"
echo " 端口:        ${SERVER_PORT}"
echo " 密码:        ${PASSWORD}"
echo " 加密方式:    aes-256-gcm"
echo " 协议模式:    TCP + UDP"
echo " bbr:    已开启"
echo " 配置文件:    /etc/shadowsocks-libev/config.json"
echo "=========================================="