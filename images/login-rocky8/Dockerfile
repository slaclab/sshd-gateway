FROM rockylinux:8

RUN set -ex \
    && yum -y update \
    && yum -y install \
      openssh-clients \
      rsync \
      environment-modules \
      sudo \
    && yum clean all \
    && rm -rf /var/cache/yum

