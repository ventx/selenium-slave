FROM python:3.7.2

ARG user=jenkins
ARG group=jenkins
ARG uid=10000
ARG gid=10000
ARG VERSION=3.23
ARG AGENT_WORKDIR=/home/${user}/agent
ENV HOME /home/${user}
RUN addgroup -gid ${gid} ${group}
RUN adduser --home $HOME --uid ${uid} --ingroup ${group} ${user} --disabled-password --gecos ""
RUN apt-get update && apt-get install -y openjdk-8-jdk
RUN curl --create-dirs -sSLo /usr/share/jenkins/slave.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${VERSION}/remoting-${VERSION}.jar \
    && chmod 755 /usr/share/jenkins \
    && chmod 644 /usr/share/jenkins/slave.jar  

ADD https://dl.bintray.com/qameta/generic/io/qameta/allure/allure/2.7.0/allure-2.7.0.tgz /opt/
RUN tar -xvzf /opt/allure-2.7.0.tgz --directory /opt/ \
    && rm /opt/allure-2.7.0.tgz
 
ENV PATH="/opt/allure-2.7.0/bin:${PATH}"

RUN mkdir /home/${user}/.jenkins && mkdir -p ${AGENT_WORKDIR}
VOLUME /home/${user}/.jenkins
VOLUME ${AGENT_WORKDIR}
WORKDIR /home/${user}

COPY jenkins-slave /usr/local/bin/jenkins-slave
USER jenkins
ENTRYPOINT ["jenkins-slave"]
