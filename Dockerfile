FROM openjdk:8-jdk

MAINTAINER Dylan <bbcheng@ikuai8.com>

###########################################################
# locale, timezone
ENV OS_LOCALE="en_US.UTF-8" \
	OS_TZ="Asia/Shanghai"
RUN apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
	locales tzdata \
	&& sed -i -e "s/# ${OS_LOCALE} UTF-8/${OS_LOCALE} UTF-8/" /etc/locale.gen \
	&& locale-gen \
	&& ln -fs /usr/share/zoneinfo/${OS_TZ} /etc/localtime \
	&& dpkg-reconfigure -f noninteractive tzdata
ENV LANG=${OS_LOCALE} \
	LC_ALL=${OS_LOCALE} \
	LANGUAGE=en_US:en

###########################################################
# ssh login

# disable SSH host key checking
COPY /conf/.ssh/config /root/.ssh/config

RUN DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
	openssh-server openssh-client \
	&& mkdir /var/run/sshd \
	########## SSH login fix. Otherwise user is kicked off after login
	&& sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd \
	########## passwordless ssh login for root
	&& rm -f /etc/ssh/ssh_host_dsa_key /etc/ssh/ssh_host_rsa_key /root/.ssh/id_rsa \
	&& ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key \
	&& ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key \
	&& ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa \
	&& cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys \
	&& chmod 600 /root/.ssh/config \
	&& chown root:root /root/.ssh/config

###########################################################
# hadoop

# Install dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
	netcat libssl1.0-dev libsnappy* \
	### clean
	&& apt-get autoremove -y \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# Version
ENV HADOOP_VERSION=2.8.3

# Home
ENV HADOOP_HOME=/usr/local/hadoop-$HADOOP_VERSION

# Install Hadoop
RUN mkdir -p "${HADOOP_HOME}" \
	&& export ARCHIVE=hadoop-$HADOOP_VERSION.tar.gz \
	&& export DOWNLOAD_PATH=hadoop/common/hadoop-$HADOOP_VERSION/$ARCHIVE \
	&& curl -sSL http://apache.mirrors.pair.com/$DOWNLOAD_PATH | tar -xz -C $HADOOP_HOME --strip-components 1 \
	&& rm -rf $ARCHIVE

# Set paths
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop \
	HADOOP_LIBEXEC_DIR=$HADOOP_HOME/libexec \
	PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

# Copy and fix configuration files
COPY etc/hadoop/*.xml $HADOOP_CONF_DIR/
RUN sed -i "s/hadoop-daemons.sh/hadoop-daemon.sh/g" $HADOOP_HOME/sbin/start-dfs.sh \
	&& sed -i "s/hadoop-daemons.sh/hadoop-daemon.sh/g" $HADOOP_HOME/sbin/stop-dfs.sh \
	&& sed -i "s|# Attempt to set JAVA_HOME if it is not set|export JAVA_HOME=/docker-java-home\n# Attempt to set JAVA_HOME if it is not set|g" $HADOOP_LIBEXEC_DIR/hadoop-config.sh

# Copy start scripts
COPY bin/* /opt/util/bin/
ENV PATH=$PATH:/opt/util/bin

# Fix environment for other users
RUN chmod +x /opt/util/bin/start-hadoop* \
	&& echo "export HADOOP_HOME=$HADOOP_HOME" > /etc/bash.bashrc.tmp \
	&& echo "export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:/opt/util/bin" >> /etc/bash.bashrc.tmp \
	&& cat /etc/bash.bashrc >> /etc/bash.bashrc.tmp \
	&& mv -f /etc/bash.bashrc.tmp /etc/bash.bashrc

# HDFS volume
VOLUME /opt/hdfs

# HDFS
EXPOSE 8020 14000 50070 50470

# MapReduce
EXPOSE 10020 13562 19888

#Yarn ports
EXPOSE 8030 8031 8032 8040 8042 8046 8047 8088 8090 8188 8190 8788 10200

#Other ports
EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]