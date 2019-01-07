# BSD 3-Clause License
#
# Copyright (c) 2017, Juliano Petronetto
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

FROM openjdk:8-jdk-alpine

ARG user=jenkins
ARG group=jenkins
ARG uid=10000
ARG gid=10000
ARG VERSION=3.23
ARG AGENT_WORKDIR=/var/${user}_home/agent
ENV HOME /var/${user}_home
RUN addgroup -g ${gid} ${group}
RUN adduser -h $HOME -u ${uid} -G ${group} -D ${user}

ENV TESSDATA https://raw.githubusercontent.com/tesseract-ocr/tessdata/master/eng.traineddata
ENV OPENCV https://github.com/opencv/opencv/archive/3.3.0.tar.gz
ENV OPENCV_VER 3.3.0
ENV CC /usr/bin/clang
ENV CXX /usr/bin/clang++

RUN apk add -U --no-cache --virtual=build-dependencies \
    linux-headers musl libxml2-dev libxslt-dev libffi-dev g++ \
    musl-dev libgcc openssl-dev jpeg-dev zlib-dev freetype-dev build-base \
    lcms2-dev openjpeg-dev python3-dev make cmake clang clang-dev ninja \

    && apk add --no-cache gcc tesseract-ocr zlib jpeg libjpeg freetype openjpeg curl python3 vim bash openssh-client \
    && curl https://bootstrap.pypa.io/get-pip.py | python3 \
    && curl --create-dirs -sSLo /usr/share/jenkins/slave.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${VERSION}/remoting-${VERSION}.jar \
    && chmod 755 /usr/share/jenkins \
    && chmod 644 /usr/share/jenkins/slave.jar  
RUN  ln -s /usr/bin/python3 /usr/bin/python \
    && curl $TESSDATA -o /usr/share/tessdata/eng.traineddata \
    && ln -s /usr/include/locale.h /usr/include/xlocale.h \
    && pip install -U --no-cache-dir Pillow pytesseract numpy

RUN mkdir /opt && cd /opt && \
    curl -L $OPENCV | tar zx && \
    cd opencv-$OPENCV_VER && \
    mkdir build && cd build && \
    cmake -G Ninja \
          -D CMAKE_BUILD_TYPE=RELEASE \
          -D CMAKE_INSTALL_PREFIX=/usr/local \
          -D WITH_FFMPEG=NO \
          -D WITH_IPP=NO \
          -D PYTHON_EXECUTABLE=/usr/bin/python \
          -D WITH_OPENEXR=NO .. && \
    ninja && ninja install
ADD https://dl.bintray.com/qameta/generic/io/qameta/allure/allure/2.7.0/allure-2.7.0.tgz /opt/
RUN tar -xvzf /opt/allure-2.7.0.tgz --directory /opt/ \
    && rm /opt/allure-2.7.0.tgz
 
RUN  ln -s /usr/local/lib/python3.6/site-packages/cv2.cpython-36m-x86_64-linux-gnu.so \
          /usr/lib/python3.6/site-packages/cv2.so && \
    apk del build-dependencies && \
    rm -rf /var/cache/apk/*
ENV PATH="/opt/allure-2.7.0/bin:${PATH}"
WORKDIR /work
