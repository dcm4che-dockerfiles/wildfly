FROM java:openjdk-8

# Set the WILDFLY_VERSION env variable
ENV WILDFLY_VERSION=9.0.2.Final \
    KEYCLOAK_VERSION=1.7.0.Final \
    JBOSS_HOME=/opt/wildfly \
    ADMIN_USER=admin \
    ADMIN_PASSWORD=admin

# Add the WildFly distribution to /opt, and make wildfly the owner of the extracted tar content
# Make sure the distribution is available from a well-known place
RUN cd $HOME \
    && curl https://download.jboss.org/wildfly/$WILDFLY_VERSION/wildfly-$WILDFLY_VERSION.tar.gz | tar xz \
    && mv $HOME/wildfly-$WILDFLY_VERSION $JBOSS_HOME \
    && curl http://downloads.jboss.org/keycloak/$KEYCLOAK_VERSION/keycloak-overlay-$KEYCLOAK_VERSION.tar.gz | tar xz -C $JBOSS_HOME \
    && curl http://downloads.jboss.org/keycloak/$KEYCLOAK_VERSION/adapters/keycloak-oidc/keycloak-wildfly-adapter-dist-$KEYCLOAK_VERSION.tar.gz | tar xz -C $JBOSS_HOME \
    && $JBOSS_HOME/bin/add-user.sh $ADMIN_USER $ADMIN_PASSWORD --silent

# Ensure signals are forwarded to the JVM process correctly for graceful shutdown
ENV LAUNCH_JBOSS_IN_BACKGROUND true

 # Expose the ports we're interested in
EXPOSE 8080 9990

 # Set the default command to run on boot
 # This will boot WildFly in the standalone mode and bind to all interface
CMD ["/opt/wildfly/bin/standalone.sh", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0"]
