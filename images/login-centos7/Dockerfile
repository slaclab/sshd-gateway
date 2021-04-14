FROM centos:7

RUN set -ex \
    && yum makecache fast \
    && yum -y update \
    && yum -y install \
      openssh-clients \
      rsync \
      environment-modules \
    && yum clean all \
    && rm -rf /var/cache/yum

