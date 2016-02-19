#!/bin/bash

set -e

if [ "$1" = 'standalone.sh' ]; then
	if [ -d /tmp/standalone ]; then
		cp -r /tmp/standalone/* $JBOSS_HOME/standalone
		rm -r /tmp/standalone
		chown -R wildfly:wildfly $JBOSS_HOME/standalone
	fi

	set -- gosu wildfly "$@"
fi

exec "$@"
