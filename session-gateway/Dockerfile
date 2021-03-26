FROM centos:7

RUN set -ex \
    && yum makecache fast \
    && yum -y update \
    && yum -y install \
      initscripts \
      krb5-workstation compat-db compat-libstdc++-33 krb5-libs pam_krb5 authconfig \
      sssd nss-pam-ldapd \
      openssh-server openssh-clients \
      tcsh bash \
      python-setuptools \
      strace \
    && easy_install supervisor \
    && yum clean all \
    && rm -rf /var/cache/yum

RUN /usr/sbin/authconfig --enablekrb5 --update

ARG TINI_VERSION v0.19.0
RUN curl https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini -o /tini \
  && chmod +x /tini

ARG KUBECTL_VERSION=v1.17.14
RUN curl https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl \
  -o /usr/local/bin/kubectl \
  && chmod +x /usr/local/bin/kubectl

# ssh
RUN mkdir -p /var/run/sshd && chmod 700 /var/run/sshd

# setup accounts
COPY sssd/nsswitch.conf /etc/
RUN chmod 644 /etc/nsswitch.conf
COPY sssd/system-auth-ac /etc/pam.d/system-auth-ac
COPY sssd/system-auth-ac /etc/pam.d/password-auth-ac
RUN chmod 644 /etc/pam.d/system-auth-ac /etc/pam.d/password-auth-ac
COPY sssd/access.netgroup.conf /etc/security/access.netgroup.conf
RUN chmod 644 /etc/security/access.netgroup.conf
COPY nslcd-monitor.sh /usr/sbin/nslcd-monitor.sh

# setup supervisord
COPY supervisord-eventlistener.sh /supervisord-eventlistener.sh
COPY supervisord.conf /etc/
COPY entrypoint.sh /entrypoint.sh

# scripts
COPY session-spawner.sh /session-spawner.sh

ENTRYPOINT [ "/tini", "--", "/entrypoint.sh" ]
