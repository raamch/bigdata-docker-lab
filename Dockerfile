FROM rockylinux:8

LABEL maintainer="Ram CH" \
      version="2.7.5" \
      description="Apache Ambari 2.7.5, Bigtop 3.2.1, Rocky Linux 8 | BigData Lab Educational Image" \
      keywords="ambari,hadoop,bigdata,rockylinux,education,bigtop,cluster" \
      org.opencontainers.image.title="ambari" \
      org.opencontainers.image.description="Ambari 2.7.5 node for educational Hadoop cluster" \
      org.opencontainers.image.vendor="Ram CH" \
      org.opencontainers.image.version="2.7.5-rl8" \
      org.opencontainers.image.created="2026-02-24"

# 1. Enable PowerTools, Devel and EPEL repos
RUN dnf install -y dnf-plugins-core epel-release && \
    dnf config-manager --set-enabled powertools && \
    dnf config-manager --set-enabled devel 2>/dev/null || true && \
    dnf clean all

# 2. Core OS packages
RUN dnf install -y --allowerasing \
        sudo \
        openssh-server \
        openssh-clients \
        which \
        iproute \
        net-tools \
        hostname \
        less \
        vim-enhanced \
        initscripts \
        wget \
        curl \
        tar \
        unzip \
        git \
        chrony \
        python3 \
        python3-distro \
        rsync \
        lsof \
        procps-ng \
        htop \
        tree \
        telnet \
        nc \
        diffutils \
        glibc-langpack-en \
        glibc-locale-source \
    && dnf clean all

# 3. Java
RUN dnf install -y java-1.8.0-openjdk-devel && \
    dnf clean all

ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
ENV PATH=$JAVA_HOME/bin:$PATH

# 4. Set locale
RUN localedef -i en_GB -f UTF-8 en_GB.UTF-8
ENV LANG=en_GB.UTF-8
ENV LC_ALL=en_GB.UTF-8

# 5. Set default timezone to India
RUN ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime && \
    echo "Asia/Kolkata" > /etc/timezone
ENV TZ=Asia/Kolkata

# 6. Bigtop 3.2.1 repo
COPY conf/bigtop.repo /etc/yum.repos.d/bigtop.repo

# 7. Install Ambari Agent, Server and Bigtop mpack
RUN dnf install -y ambari-agent ambari-server bigtop-ambari-mpack && \
    systemctl enable ambari-agent && \
    dnf clean all

# 7a. Fix ambari_commons mismatch issue
RUN cp -r /usr/lib/ambari-server/lib/ambari_commons \
          /usr/lib/ambari-agent/lib/ 2>/dev/null || true && \
    cp -r /usr/lib/ambari-server/lib/ambari_commons \
          /var/lib/ambari-agent/bin/ 2>/dev/null || true

# 7b. Fix OS family mapping for Rocky Linux 8 / CentOS 8
COPY conf/os_family.json /usr/lib/ambari-server/lib/ambari_commons/resources/os_family.json
COPY conf/os_family.json /usr/lib/ambari-agent/lib/ambari_commons/resources/os_family.json
COPY conf/os_family.json /var/lib/ambari-agent/bin/ambari_commons/resources/os_family.json

# 8. OS hardening
RUN mkdir -p /etc/selinux && \
    echo 'SELINUX=disabled' > /etc/selinux/config && \
    echo '* soft nofile 65536' >> /etc/security/limits.conf && \
    echo '* hard nofile 65536' >> /etc/security/limits.conf && \
    echo 'vm.swappiness=10'    >> /etc/sysctl.conf

# 8a. Fix OS identification for Ambari compatibility
RUN echo 'CentOS Linux release 7.9.1908 (Core)' > /etc/redhat-release

# 9. SSH setup
RUN ssh-keygen -A && \
    ssh-keygen -t rsa -b 4096 -N "" -f /root/.ssh/id_rsa && \
    chmod 700 /root/.ssh && \
    sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/'               /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication.*/PubkeyAuthentication yes/'     /etc/ssh/sshd_config && \
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    systemctl enable sshd

# 10. Create ambari user with full sudo, set passwords
RUN useradd -m -s /bin/bash ambari && \
    echo "ambari:bigdatalab"  | chpasswd && \
    echo "root:ambariroot"    | chpasswd && \
    usermod -aG wheel ambari && \
    echo "ambari ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    sed -i 's/.*requiretty/# requiretty/' /etc/sudoers

# 11. PS1 prompt
RUN echo 'export PS1="[\u@\h \W]\$ "' >> /etc/bashrc && \
    echo 'export PS1="[\u@\h \W]\$ "' >> /root/.bashrc && \
    echo 'export PS1="[\u@\h \W]\$ "' >> /home/ambari/.bashrc

# 12. Enable chrony, disable firewall
RUN systemctl enable chronyd && \
    systemctl disable firewalld 2>/dev/null || true

# 13. Copy all scripts
COPY scripts/motd.sh              	/etc/profile.d/motd.sh
COPY scripts/entrypoint-slave.sh  	/usr/local/bin/entrypoint-slave.sh
COPY scripts/entrypoint-server.sh 	/usr/local/bin/entrypoint-server.sh
COPY conf/blueprint.json        	/var/lib/ambari-server/resources/blueprint.json
COPY conf/clustertemplate.json  	/var/lib/ambari-server/resources/clustertemplate.json
COPY scripts/setup-cluster.sh   	/usr/local/bin/setup-cluster.sh
RUN chmod +x /etc/profile.d/motd.sh && \
    chmod +x /usr/local/bin/entrypoint-slave.sh && \
    chmod +x /usr/local/bin/entrypoint-server.sh && \
	chmod +x /usr/local/bin/setup-cluster.sh

EXPOSE 22 8080 8440 8441

ENV container=docker
CMD ["/usr/local/bin/entrypoint-slave.sh"]