#!/bin/bash

if [[ -f /install/.calibreweb.lock ]]; then
    if grep -q -- "cps.py -f" /etc/systemd/system/calibreweb.service; then
        echo_info "Updating Calibre Web service file"
        sed -i 's/cps.py -f/cps.py/g' /etc/systemd/system/calibreweb.service
        systemctl daemon-reload
    fi
    if ! /opt/.venv/calibreweb/bin/python3 -c "import pkg_resources; pkg_resources.require(open('/opt/calibreweb/requirements.txt',mode='r'))" &> /dev/null; then
        echo_progress_start "Updating Calibre Web requirements"
        /opt/.venv/calibreweb/bin/pip install -r /opt/calibreweb/requirements.txt
        if systemctl is-enabled calibreweb > /dev/null 2>&1 &&
            [[ "$(tail -n 1 /opt/calibreweb/calibre-web.log | grep -c 'webserver stop (restart=True)')" -eq 1 ]]; then
            systemctl restart calibreweb
        fi
        echo_progress_done
    fi
    if [[ -f /etc/nginx/apps/calibreweb.conf ]]; then
        proxy_buffer_size=$(grep -oP 'proxy_buffer_size\s+\K\d+' /etc/nginx/apps/calibreweb.conf)
        if [[ "$proxy_buffer_size" == "128k;" ]]; then
            echo_progress_start "Updating Calibre Web nginx config"
            bash /usr/local/bin/swizzin/nginx/calibreweb.sh
            systemctl reload nginx
            echo_progress_done
        fi
    fi
fi
