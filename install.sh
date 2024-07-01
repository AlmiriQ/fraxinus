cat > /etc/systemd/system/fraxinus.service << EOF
[Unit]
Description=Fraxinus
After=network.target

[Service]
Type=simple
ExecStart=/fraxinus/fraxinus.sh

[Install]
WantedBy=multi-user.target
EOF

mkdir -p /fraxinus

cp -fv ./fraxinus.sh /fraxinus/

cp -fv ./fraxinus.lua /fraxinus/
cp -fv ./path.lua /fraxinus/
cp -fv ./default.lua /fraxinus/

