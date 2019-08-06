FROM ubuntu:20.04

LABEL version="1.0.0"
LABEL description="Ubuntu Repository Mirror Server"
LABEL maintainer="hyfly233@outlook.com"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai
ENV APP_VERSION=1.0.0

# 先使用默认源安装 CA 证书
RUN apt-get update && apt-get install -y ca-certificates && apt-get clean

# 复制新的源配置文件
COPY config/sources.list /etc/apt/sources.list

# 安装必要软件
RUN apt-get update && apt-get install -y \
    apt-mirror \
    apache2 \
    cron \
    wget \
    curl \
    gnupg \
    rsync

RUN dpkg -l | grep apt-mirror && which apt-mirror

# 创建用户和目录
RUN useradd -m -s /bin/bash repouser \
    && mkdir -p /repo/mirror \
    && mkdir -p /repo/config \
    && mkdir -p /repo/logs \
    && chown -R repouser:repouser /repo

# 配置 Apache
RUN a2enmod rewrite ssl headers autoindex expires
COPY config/apache-repo.conf /etc/apache2/sites-available/repo.conf
RUN a2ensite repo.conf && a2dissite 000-default

# 复制脚本
COPY scripts/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

EXPOSE 80 443

CMD ["/usr/local/bin/start.sh"]
