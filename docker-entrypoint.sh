#!/bin/bash

set -e

if [ "$1" = 'standalone.sh' ]; then

	if [ -f setenv.sh ]; then
		. setenv.sh
	fi

	chown -c wildfly:wildfly $JBOSS_HOME/standalone
	for d in $WILDFLY_STANDALONE_PURGE; do
		rm -rfv $JBOSS_HOME/standalone/$d/*
	done
	for d in $WILDFLY_STANDALONE; do
		if [ "$d" = 'deployments' ]; then
			for ear in /opt/wildfly/standalone/deployments/*.ear; do
				if [ ! -f /docker-entrypoint.d/deployments/$(basename $ear) ]; then
					rm -fv ${ear} ${ear}.deployed
				fi
			done
			for war in /opt/wildfly/standalone/deployments/*.war; do
				if [ ! -f /docker-entrypoint.d/deployments/$(basename $war) ]; then
					rm -fv ${war} ${war}.deployed
				fi
			done
		fi
		if grep -q $d <<<"$WILDFLY_STANDALONE_PRESERVE"
			then cp -rnpv /docker-entrypoint.d/$d $JBOSS_HOME/standalone
			else cp -rupv /docker-entrypoint.d/$d $JBOSS_HOME/standalone
		fi
		if [ "$d" = 'configuration' ]; then
			if [ -n "$WILDFLY_ADMIN_USER" -a -n "$WILDFLY_ADMIN_PASSWORD" ] \
				&& tail -n1 $JBOSS_HOME/standalone/configuration/mgmt-users.properties | grep -q '^#'; then
				$JBOSS_HOME/bin/add-user.sh $WILDFLY_ADMIN_USER $WILDFLY_ADMIN_PASSWORD --silent
			fi
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
