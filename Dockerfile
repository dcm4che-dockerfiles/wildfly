FROM java:8-jre

# explicitly set user/group IDs
RUN groupadd -r wildfly --gid=1023 && useradd -r -g wildfly --uid=1023 -d /opt/wildfly wildfly

# grab gosu for easy step-down from root
RUN gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
RUN arch="$(dpkg --print-architecture)" \
    && set -x \
    && curl -o /usr/local/bin/gosu -fSL "https://github.com/tianon/gosu/releases/download/1.3/gosu-$arch" \
    && curl -o /usr/local/bin/gosu.asc -fSL "https://github.com/tianon/gosu/releases/download/1.3/gosu-$arch.asc" \
    && gpg --verify /usr/local/bin/gosu.asc \
    && rm /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu

ENV WILDFLY_VERSION=9.0.2.Final \
    KEYCLOAK_VERSION=1.7.0.Final \
    LOGSTASH_GELF_VERSION=1.8.0 \
    JBOSS_HOME=/opt/wildfly \
    ADMIN_USER=admin \
    ADMIN_PASSWORD=admin

ENV JBOSS_LOGMANAGER_JAR=jboss-logmanager-ext-${JBOSS_LOGMANAGER_EXT_VERSION}.jar
RUN cd $HOME \
    && curl https://download.jboss.org/wildfly/$WILDFLY_VERSION/wildfly-$WILDFLY_VERSION.tar.gz | tar xz \
    && mv $HOME/wildfly-$WILDFLY_VERSION $JBOSS_HOME \
    && curl http://downloads.jboss.org/keycloak/$KEYCLOAK_VERSION/keycloak-overlay-$KEYCLOAK_VERSION.tar.gz | tar xz -C $JBOSS_HOME \
    && curl http://downloads.jboss.org/keycloak/$KEYCLOAK_VERSION/adapters/keycloak-oidc/keycloak-wildfly-adapter-dist-$KEYCLOAK_VERSION.tar.gz | tar xz -C $JBOSS_HOME \
    && curl http://central.maven.org/maven2/biz/paluch/logging/logstash-gelf/$LOGSTASH_GELF_VERSION/logstash-gelf-$LOGSTASH_GELF_VERSION-logging-module.zip -O \
    && unzip logstash-gelf-$LOGSTASH_GELF_VERSION-logging-module.zip \
    && mv $HOME/logstash-gelf-$LOGSTASH_GELF_VERSION/biz $JBOSS_HOME/modules/biz \
    && rmdir $HOME/logstash-gelf-$LOGSTASH_GELF_VERSION \
    && rm logstash-gelf-$LOGSTASH_GELF_VERSION-logging-module.zip \
    && $JBOSS_HOME/bin/add-user.sh $ADMIN_USER $ADMIN_PASSWORD --silent \
    && mkdir /docker-entrypoint.d  && mv $JBOSS_HOME/standalone/* /docker-entrypoint.d \
    && chown wildfly $JBOSS_HOME

# Default configuration: can be overridden at the docker command line
ENV JAVA_OPTS -Xms64m -Xmx512m -Djava.net.preferIPv4Stack=true -Djboss.modules.system.pkgs=org.jboss.byteman -Djava.awt.headless=true
ENV WILDFLY_STANDALONE configuration deployments
ENV WILDFLY_INIT=
ENV WILDFLY_CHOWN $JBOSS_HOME/standalone

# Ensure signals are forwarded to the JVM process correctly for graceful shutdown
ENV LAUNCH_JBOSS_IN_BACKGROUND true

ENV PATH $JBOSS_HOME/bin:$PATH

VOLUME /opt/wildfly/standalone

# Expose the ports we're interested in
EXPOSE 8080 9990

COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["standalone.sh", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0"]
