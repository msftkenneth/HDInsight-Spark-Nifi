#!/bin/bash

NIFI_VERSION=nifi-1.6.0
HDP_HOME="/usr/hdp/current"
NIFI_HOME="/usr/hdp/current/nifi"
HADOOP_CORE_CONF="/etc/hadoop/conf/core-site.xml"
HOSTNAME=`hostname`

checkNifi() {
if [ -e /usr/hdp/current/nifi ]; then
    echo "NIFI is already installed, exiting ..."
    exit 0
fi
}

installJava() {
    sudo add-apt-repository -y ppa:openjdk-r/ppa
    sudo apt-get update
    sudo apt-get install -y --allow-unauthenticated openjdk-8-jdk
}

installNiFi() {
    cd $HDP_HOME
    sudo wget http://apache.communilink.net/nifi/1.6.0/$NIFI_VERSION-bin.zip
    sudo unzip $NIFI_VERSION-bin.zip &> /dev/null
    sudo rm $NIFI_VERSION-bin.zip
    sudo mv $NIFI_VERSION nifi

    cd /usr/hdp/current/nifi/conf

    ZOOKEEPER_HOSTS=`sudo grep -R zookeeper /etc/hadoop/conf/yarn-site.xml | grep 2181 | grep -oPm1 "(?<=<value>)[^<]+"`
    if [ -z "$ZOOKEEPER_HOSTS" ]; then
        ZOOKEEPER_HOSTS=`sudo grep -R zk /etc/hadoop/conf/yarn-site.xml | grep 2181 | grep -oPm1 "(?<=<value>)[^<]+"`
    fi

    sed -i "s/nifi.web.http.host=/nifi.web.http.host=${HOSTNAME}/g" nifi.properties
    sed -i 's/nifi.web.http.port=8080/nifi.web.http.port=8060/g' nifi.properties
    sed -i 's/nifi.cluster.is.node=false/nifi.cluster.is.node=true/g' nifi.properties
    sed -i "s/nifi.cluster.node.address=/nifi.cluster.node.address=${HOSTNAME}/g" nifi.properties
    sed -i 's/nifi.cluster.node.protocol.port=/nifi.cluster.node.protocol.port=9999/g' nifi.properties
    sed -i "s/nifi.zookeeper.connect.string=/nifi.zookeeper.connect.string=${ZOOKEEPER_HOSTS}/g" nifi.properties
    sed -i "s/<property name=\"Connect String\"><\/property>/<property name=\"Connect String\">${ZOOKEEPER_HOSTS}<\/property>/g" state-management.xml
}

startNifi() {
    cd /usr/hdp/current/nifi/bin
    sudo ./nifi.sh start
    exit 0
}

checkNifi
installJava
installNiFi
startNifi
