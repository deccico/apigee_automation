FROM ubuntu:18.04

RUN apt update && \
    apt-get install -y \
    git \
    curl \
    htop \
    npm \
    python \
    unzip \ 
    vim \
    zip && \
    rm -rf /var/lib/apt/lists/* && \
    npm install -g openapi2apigee

WORKDIR /code/apigee_automation

COPY *.template ./
COPY *.py ./ 
COPY *.sh ./
COPY Jenkinsfile ./
COPY *.md ./
COPY templates ./

