ARG LOG4J_VERSION=2.11.0

FROM alpine AS build_base
RUN apk add --no-cache gnupg wget zip unzip

ARG LOG4J_VERSION

WORKDIR /temp/solr

# Load log4j libs and verify its signature
RUN wget https://downloads.apache.org/logging/KEYS
RUN gpg --import KEYS
RUN wget https://archive.apache.org/dist/logging/log4j/$LOG4J_VERSION/apache-log4j-$LOG4J_VERSION-bin.zip
RUN wget https://archive.apache.org/dist/logging/log4j/2.11.0/apache-log4j-$LOG4J_VERSION-bin.zip.asc
RUN gpg --verify apache-log4j-$LOG4J_VERSION-bin.zip.asc apache-log4j-$LOG4J_VERSION-bin.zip

# Unzip log4j-core and patch it
# Remedy for https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-44228
RUN unzip -d . apache-log4j-$LOG4J_VERSION-bin.zip apache-log4j-$LOG4J_VERSION-bin/log4j-core-$LOG4J_VERSION.jar
RUN zip -q -d apache-log4j-$LOG4J_VERSION-bin/log4j-core-$LOG4J_VERSION.jar org/apache/logging/log4j/core/lookup/JndiLookup.class

# Build solr image with patched log4j-core
FROM solr:7.7

ARG LOG4J_VERSION

RUN rm /opt/solr/server/lib/ext/log4j-core-$LOG4J_VERSION.jar
COPY --from=build_base /temp/solr/apache-log4j-$LOG4J_VERSION-bin/log4j-core-$LOG4J_VERSION.jar /opt/solr/server/lib/ext/log4j-core-$LOG4J_VERSION.jar