FROM amazonlinux:2.0.20210126.0

RUN yum -y update && \
    amazon-linux-extras install -y epel && \
    yum install -y ansible systemd-sysv

WORKDIR /ansible

CMD ["/sbin/init"]
