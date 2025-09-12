FROM rockylinux:9.3

RUN set -ex \
    && yum -y update \
    && yum -y install \
      openssh-clients \
      rsync \
      environment-modules \
      sudo \
    && yum clean all \
    && rm -rf /var/cache/yum

