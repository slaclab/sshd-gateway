#!/bin/sh

printenv | grep KUBERNETES > /etc/security/pam_env.conf
echo "PATH=$PATH" >> /etc/security/pam_env.conf

SUPERVISORD_CONFIG=${SUPERVISORD_CONFIG:-/etc/supervisord.conf}
echo "Starting with supervisord" $(/usr/bin/supervisord --version) "with $SUPERVISORD_CONFIG..."
exec /usr/bin/supervisord --configuration $SUPERVISORD_CONFIG

