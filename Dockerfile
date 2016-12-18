
# NOTE: THIS DOCKERFILE IS GENERATED VIA "update.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#
FROM buildpack-deps:jessie-scm

#FROM sonnt/eclipse
#MAINTAINER sonnt

# A few problems with compiling Java from source:
#  1. Oracle.  Licensing prevents us from redistributing the official JDK.
#  2. Compiling OpenJDK also requires the JDK to be installed, and it gets
#       really hairy.
RUN echo 'deb http://deb.debian.org/debian jessie-backports main' > /etc/apt/sources.list.d/jessie-backports.list
RUN apt-get -y update && apt-get install -y --no-install-recommends \
		apt-utils \
		apt-get -y install lib32z1 lib32ncurses5 \
		bzip2 \
		unzip \
		xz-utils \
                sudo \
		arduino \
		git \
		gcc-arm-none-eabi \
	&& rm -rf /var/lib/apt/lists/*


# Default to UTF-8 file.encoding
ENV LANG C.UTF-8

# add a simple script that can auto-detect the appropriate JAVA_HOME value
# based on whether the JDK or only the JRE is installed
RUN     { \
		echo '#!/bin/sh'; \
		echo 'set -e'; \
		echo; \
		echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; \
	} > /usr/local/bin/docker-java-home \
	&& chmod +x /usr/local/bin/docker-java-home

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

ENV JAVA_VERSION 8u111
ENV JAVA_DEBIAN_VERSION 8u111-b14-2~bpo8+1

# see https://bugs.debian.org/775775
# and https://github.com/docker-library/java/issues/19#issuecomment-70546872
ENV CA_CERTIFICATES_JAVA_VERSION 20140324
#default DISPLAY
ENV DISPLAY :0

RUN set -x \
	&& apt-get update \
	&& apt-get install -y \
		openjdk-8-jdk="$JAVA_DEBIAN_VERSION" \
		ca-certificates-java="$CA_CERTIFICATES_JAVA_VERSION" \
	&& rm -rf /var/lib/apt/lists/* \
	&& [ "$JAVA_HOME" = "$(docker-java-home)" ]

# see CA_CERTIFICATES_JAVA_VERSION notes above
RUN /var/lib/dpkg/info/ca-certificates-java.postinst configure
RUN [ -f /opt/eclipse/eclipse ] || \
    { wget http://archive.eclipse.org/technology/epp/downloads/release/helios/SR2/eclipse-cpp-helios-SR2-linux-gtk-x86_64.tar.gz\
      -O /tmp/eclipsecpp64helios.tar.gz &&\
      tar -xf /tmp/eclipsecpp64helios.tar.gz -C /opt && \
      chmod 555 opt/eclipse/eclipse && \
      rm /tmp/eclipsecpp64helios.tar.gz; \
    }
ENV GA_VERSION  4_9-2015q3-20150921 
#5_4-2016q3-20160926
RUN wget https://launchpadlibrarian.net/287101520/gcc-arm-none-eabi-$GA_VERSION-linux.tar.bz2 -O /tmp/gcc-arm-none-eabi-$GA_VERSION-linux.tar.bz2\
    && tar xjf /tmp/gcc-arm-none-eabi-$GA_VERSION-linux.tar.bz2 -C /usr/local && \
    rm /tmp/gcc-arm-none-eabi-$GA_VERSION-linux.tar.bz2
#share X11 from host
VOLUME ["/tmp/.X11-unix"]

#create user with sudo perm
#RUN adduser --disabled-password --gecos sonnt sonnt
RUN mkdir -p /home/sonnt/workspace && \
    echo "sonnt:x:1000:1000:sonnt,,,:/home/sonnt:/bin/bash" >> /etc/passwd && \
    echo "sonnt:x:1000:" >> /etc/group && \
    echo "sonnt ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/sonnt && \
    chmod 0440 /etc/sudoers.d/sonnt && \
    chown sonnt:sonnt -R /home/sonnt
USER sonnt
ENV HOME /home/sonnt
WORKDIR /home/sonnt/workspace

CMD sleep 10; nohub /opt/eclipse/eclipse &>/dev/null&; while((1)); do sleep 10; done

