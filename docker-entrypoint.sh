#!/bin/bash

set -e

if [ "$1" = 'standalone.sh' ]; then
	for f in $WILDFLY_STANDALONE; do
		if [ ! -d $JBOSS_HOME/standalone/$f ]; then
			cp -r /docker-entrypoint.d/$f $JBOSS_HOME/standalone
			chown -R wildfly:wildfly $JBOSS_HOME/standalone/$f
		fi
	done
	for f in $WILDFLY_INIT; do
		if [ -f $f ]; then
			. $f
			mv $f ${f}.done
		fi
	done
	if [ ! -f $JBOSS_HOME/standalone/chown.done ]; then
		for f in $WILDFLY_CHOWN; do
			chown -R wildfly:wildfly $f
		done
		touch $JBOSS_HOME/standalone/chown.done
		chown wildfly:wildfly $JBOSS_HOME/standalone/chown.done
	fi

	set -- gosu wildfly "$@"
fi

exec "$@"
