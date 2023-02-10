apt update
apt install ssh

# 打开端口
ufw allow 443/tcp
ufw allow 443/udp

# 自动脚本构建
bash <(curl -L -s https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)


# 配置文件

# 清空文件
echo "" > /usr/local/etc/v2ray/config.json

# need have log, otherwise, /var/log/v2ray/access.log 不会有信息
echo -n '{
  "log": {
    "loglevel": "warning",
    "access": "/var/log/v2ray/access.log", 
    "error": "/var/log/v2ray/error.log"
  },
  "inbounds": [
    {
      "port": 443, // Vmess 协议服务器监听端口
      "protocol": "vmess",
      "listen": "' >> /usr/local/etc/v2ray/config.json

# 需要有 listen，否则，监听的端口会是 ipv6, 可以使用 netstat 查看

#  获取 IP 地址，用于 listen
#   -n 去掉 换行符
ifconfig enp1s0 | awk 'NR==2{print $2}' | xargs echo -n >> /usr/local/etc/v2ray/config.json

echo -n '",
      "settings": {
        "clients": [
          {
            "id": "8e99faac-3c17-4fd8-a3b3-7a20dc913f9d", // id(UUID) 需要修改
            "alterId": 0 // 此处的值也应当与服务器相同
          }
        ]
      },
      "streamSettings": {
        "network": "mkcp", //此处的 mkcp 也可写成 kcp，两种写法是起同样的效果
        "kcpSettings": {
          "uplinkCapacity": 5,
          "downlinkCapacity": 100,
          "congestion": true,
          "header": {
            "type": "wechat-video"
          }
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}' >> /usr/local/etc/v2ray/config.json


# 强制 兼容 MD5，否则 proxy server 只能收到请求，无法 响应
echo '[Unit]
Description=V2Ray Service
Documentation=https://www.v2fly.org/
After=network.target nss-lookup.target

[Service]
User=nobody
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/bin/env v2ray_vmess_aead_forced=false /usr/local/bin/v2ray run -config /usr/local/etc/v2ray/config.json
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/v2ray.service

# 运行服务
systemctl start v2ray
# 开机启动
systemctl enable v2ray 
