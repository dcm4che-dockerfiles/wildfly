#!/bin/bash

set -e

if [ "$1" = 'standalone.sh' ]; then

	if [ -f setenv.sh ]; then
		. setenv.sh
	fi

	chown -c wildfly:wildfly $JBOSS_HOME/standalone
	for f in $JBOSS_HOME/standalone/deployments/*.{ear,war}; do
		if [ -f $f -a ! -f /docker-entrypoint.d/deployments/$(basename $f) ]; then
			rm -fv ${f} ${f}.deployed
			OVERWRITE_CONFIGURATION=1
		fi
	done
	if [ -n "$OVERWRITE_CONFIGURATION" -a -d $JBOSS_HOME/standalone/configuration ] \
		&& (! grep -q configuration <<<"$WILDFLY_STANDALONE_PRESERVE"); then
		cp -bpv /docker-entrypoint.d/configuration/*.xml $JBOSS_HOME/standalone/configuration
	fi
	for d in $WILDFLY_STANDALONE; do
		if grep -q $d <<<"$WILDFLY_STANDALONE_PRESERVE"
			then cp -rnpv /docker-entrypoint.d/$d $JBOSS_HOME/standalone
			else cp -rupv /docker-entrypoint.d/$d $JBOSS_HOME/standalone
		fi
	done
	if [ -n "$WILDFLY_ADMIN_USER" -a -n "$WILDFLY_ADMIN_PASSWORD" ] \
		&& tail -n1 $JBOSS_HOME/standalone/configuration/mgmt-users.properties | grep -q '^#'; then
		$JBOSS_HOME/bin/add-user.sh $WILDFLY_ADMIN_USER $WILDFLY_ADMIN_PASSWORD --silent
	fi
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
	for f in $WILDFLY_CHOWN; do
		if [ ! -f $f/chown.done ]; then
			touch $f/chown.done
			echo "chown -R wildfly:wildfly $f"
			chown -R wildfly:wildfly $f
		fi
	done
	[ "${WILDFLY_CRON_ENABLED-false}" != "false" ] && service cron start
	for c in $WILDFLY_WAIT_FOR; do
		echo "Waiting for $c ..."
		while ! nc -w 1 -z ${c/:/ }; do sleep 1; done
		echo "done"
	done
	set -- gosu wildfly "$@" $SYS_PROPS
	echo "Starting Wildfly $WILDFLY_VERSION"
fi

exec "$@"
