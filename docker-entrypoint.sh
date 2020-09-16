#!/bin/bash

set -e

if [ "$1" = 'standalone.sh' ]; then

	if [ -f setenv.sh ]; then
		. setenv.sh
	fi

	for f in $WILDFLY_STANDALONE; do
		if [ ! -d $JBOSS_HOME/standalone/$f ]; then
			echo "cp -r /docker-entrypoint.d/$f $JBOSS_HOME/standalone"
			cp -r /docker-entrypoint.d/$f $JBOSS_HOME/standalone
			if [ "$f" = 'configuration' ]; then
				if [ -n "$WILDFLY_ADMIN_USER" -a -n "$WILDFLY_ADMIN_PASSWORD" ]; then
					$JBOSS_HOME/bin/add-user.sh $WILDFLY_ADMIN_USER $WILDFLY_ADMIN_PASSWORD --silent
				fi
			fi
			chown -R wildfly:wildfly $JBOSS_HOME/standalone/$f
		fi
	done
	for f in $WILDFLY_INIT; do
		if [ -f $f ]; then
			echo ". $f"
			. $f
			mv $f ${f}.done
		fi
	done
	if [ ! -f $JAVA_HOME/lib/security/cacerts.done ]; then
		touch $JAVA_HOME/lib/security/cacerts.done
		if [ "$EXTRA_CACERTS" ]; then
			keytool -importkeystore \
				-srckeystore $EXTRA_CACERTS -srcstorepass $EXTRA_CACERTS_PASSWORD \
				-destkeystore $JAVA_HOME/lib/security/cacerts -deststorepass changeit
		fi
	fi
	if [ ! -f $JBOSS_HOME/standalone/chown.done ]; then
		touch $JBOSS_HOME/standalone/chown.done
		for f in $WILDFLY_CHOWN; do
			echo "chown -R wildfly:wildfly $f"
			chown -R wildfly:wildfly $f
		done
	fi
	for c in $WILDFLY_WAIT_FOR; do
		echo "Waiting for $c ..."
		while ! nc -w 1 -z ${c/:/ }; do sleep 1; done
		echo "done"
	done
	set -- gosu wildfly "$@" $SYS_PROPS
	echo "Starting Wildfly $WILDFLY_VERSION"
fi

exec "$@"
