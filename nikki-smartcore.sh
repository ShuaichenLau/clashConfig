#!/bin/bash

LOG_FILE="/tmp/upgrade_mihomo.log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

get_latest_core_url() {
  curl -s https://api.github.com/repos/vernesong/mihomo/releases \
    | grep browser_download_url \
    | grep 'linux-amd64-alpha-smart-.*\.gz' \
    | head -n 1 \
    | cut -d '"' -f 4
}

log "开始执行 smart_upgrade 脚本..."

if ! pgrep -f nikki > /dev/null; then
  log "未检测到 nikki 正在运行，退出。"
  exit 0
fi

log "检测到 nikki 正在运行，准备更新 mihomo 核心..."

cd /tmp || exit 1
rm -f mihomo.gz mihomo

core_url=$(get_latest_core_url)

if [ -z "$core_url" ]; then
  log "获取 mihomo 下载地址失败，退出。"
  exit 1
fi

log "获取到最新 mihomo 核心地址：$core_url"
log "开始下载..."

wget "$core_url" -O mihomo.gz
if [ $? -ne 0 ]; then
  log "下载失败，退出。"
  exit 1
fi

log "解压核心文件..."
gunzip -f mihomo.gz

if [ ! -f "mihomo" ]; then
  log "解压失败，文件不存在，退出。"
  exit 1
fi

log "赋予执行权限并替换核心..."
chmod +x mihomo
mv -f mihomo /usr/bin/mihomo

log "更新 LightGBM 模型..."
wget https://github.com/vernesong/mihomo/releases/download/LightGBM-Model/Model-large.bin -O /etc/nikki/run/Model.bin
if [ $? -ne 0 ]; then
  log "模型文件下载失败，退出。"
  exit 1
fi

log "重启 nikki 服务..."
/etc/init.d/nikki restart

log "nikki 当前状态："
pgrep -a nikki | tee -a "$LOG_FILE"

log "smart_upgrade 自动升级完成。"
