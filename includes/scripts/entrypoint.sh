#!/bin/sh

# start supervisor
echo "Starting Supervisor"
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf