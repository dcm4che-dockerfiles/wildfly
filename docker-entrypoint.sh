#!/bin/bash

set -e

if [ "$1" = 'standalone.sh' ]; then
	if [ ! -d $JBOSS_HOME/standalone/deployments ]; then
		cp -r /docker-entrypoint.d/standalone/* $JBOSS_HOME/standalone
		if [ -f $JBOSS_HOME/bin/configure ]; then
			. $JBOSS_HOME/bin/configure
		fi
		if [ -n "$CHOWN_WILDFLY" ]; then
			for f in $CHOWN_WILDFLY; do
				chown -R wildfly:wildfly $f
			done
		fi
		chown -R wildfly:wildfly $JBOSS_HOME
	fi

	set -- gosu wildfly "$@"
fi

exec "$@"
