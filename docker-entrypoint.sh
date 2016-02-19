#!/bin/bash

set -e

if [ "$1" = 'standalone.sh' ]; then
	if [ -d /tmp/standalone ]; then
		cp -r /tmp/standalone/* $JBOSS_HOME/standalone
		rm -r /tmp/standalone
		chown -R wildfly:wildfly $JBOSS_HOME/standalone
	fi

	set -- gosu wildfly "$@"
elif [ "$1" = 'domain.sh' ]; then
	if [ -d /tmp/domain ]; then
		cp -r /tmp/domain/* $JBOSS_HOME/domain
		rm -r /tmp/domain
		chown -R wildfly:wildfly $JBOSS_HOME/domain
	fi

	set -- gosu wildfly "$@"
fi

exec "$@"
