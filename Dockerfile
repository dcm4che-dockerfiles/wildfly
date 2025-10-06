FROM amazoncorretto:21.0.8-al2023

RUN set -eux \
    && yum install -y findutils shadow-utils nmap-ncat tar gzip unzip xz \
    && yum clean all \
    && groupadd -r wildfly --gid=1023 \
    && useradd -r -g wildfly --uid=1023 -d /opt/wildfly wildfly

ENV WILDFLY_VERSION=37.0.1.Final \
    LOGSTASH_GELF_VERSION=1.15.1 \
    JBOSS_HOME=/opt/wildfly

RUN cd $HOME \
    && curl -L https://github.com/wildfly/wildfly/releases/download/$WILDFLY_VERSION/wildfly-$WILDFLY_VERSION.tar.gz | tar xz  \
    && mv wildfly-$WILDFLY_VERSION $JBOSS_HOME \
    && curl https://repo1.maven.org/maven2/biz/paluch/logging/logstash-gelf/${LOGSTASH_GELF_VERSION}/logstash-gelf-${LOGSTASH_GELF_VERSION}-logging-module.zip -O \
    && unzip logstash-gelf-${LOGSTASH_GELF_VERSION}-logging-module.zip \
    && mv logstash-gelf-${LOGSTASH_GELF_VERSION}/biz $JBOSS_HOME/modules/biz \
    && rmdir logstash-gelf-${LOGSTASH_GELF_VERSION} \
    && rm logstash-gelf-${LOGSTASH_GELF_VERSION}-logging-module.zip \
    && chown -R wildfly:wildfly $JBOSS_HOME \
    && mkdir /docker-entrypoint.d  && mv $JBOSS_HOME/standalone/* /docker-entrypoint.d

ENV WILDFLY_STANDALONE="configuration deployments"

# Ensure signals are forwarded to the JVM process correctly for graceful shutdown
ENV LAUNCH_JBOSS_IN_BACKGROUND=1

ENV PATH="$JBOSS_HOME/bin:$PATH"

VOLUME /opt/wildfly/standalone

COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["standalone.sh", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0"]
