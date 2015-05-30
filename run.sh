#!/bin/bash
set -e

# Start Supervisor processes.
exec supervisord -n -c /etc/supervisor/conf.d/supervisord.conf

exec "$@"

