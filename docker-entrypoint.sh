#!/bin/bash

set -e

if [ "$1" = 'standalone.sh' ]; then

	if [ -f $LDAP_ROOTPASS_FILE ]; then
		LDAP_ROOTPASS=`cat $LDAP_ROOTPASS_FILE`
	else
		echo $LDAP_ROOTPASS > $LDAP_ROOTPASS_FILE
	fi

	if [ -f $POSTGRES_PASSWORD_FILE ]; then
		POSTGRES_PASSWORD=`cat $POSTGRES_PASSWORD_FILE`
	else
		echo $POSTGRES_PASSWORD > $POSTGRES_PASSWORD_FILE
	fi

	if [ -f $KEYSTORE_PASSWORD_FILE ]; then
		KEYSTORE_PASSWORD=`cat $KEYSTORE_PASSWORD_FILE`
	else
		echo $KEYSTORE_PASSWORD > $KEYSTORE_PASSWORD_FILE
	fi

	if [ -f $KEY_PASSWORD_FILE ]; then
		KEY_PASSWORD=`cat $KEY_PASSWORD_FILE`
	else
		echo $KEY_PASSWORD > $KEY_PASSWORD_FILE
	fi

	if [ -f $TRUSTSTORE_PASSWORD_FILE ]; then
		TRUSTSTORE_PASSWORD=`cat $TRUSTSTORE_PASSWORD_FILE`
	else
		echo $TRUSTSTORE_PASSWORD > $TRUSTSTORE_PASSWORD_FILE
	fi

	for f in $WILDFLY_STANDALONE; do
		if [ ! -d $JBOSS_HOME/standalone/$f ]; then
			echo "cp -r /docker-entrypoint.d/$f $JBOSS_HOME/standalone"
			cp -r /docker-entrypoint.d/$f $JBOSS_HOME/standalone
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
		keytool -importkeystore \
			-srckeystore $JBOSS_HOME/standalone/configuration/$TRUSTSTORE -srcstorepass $TRUSTSTORE_PASSWORD \
			-destkeystore $JAVA_HOME/lib/security/cacerts -deststorepass changeit
	fi
	if [ ! -f $JBOSS_HOME/standalone/chown.done ]; then
		touch $JBOSS_HOME/standalone/chown.done
		for f in $WILDFLY_CHOWN; do
			echo "chown -R wildfly:wildfly $f"
			chown -R wildfly:wildfly $f
		done
	fi
	for c in $WILDFLY_WAIT_FOR; do
		echo -n "Waiting for $c ... "
		while ! nc -w 1 -z ${c/:/ }; do sleep 0.1; done
		echo "done"
	done
	set -- gosu wildfly "$@"
	echo "Starting Wildfly $WILDFLY_VERSION"
fi

exec "$@"
