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
    jq \
    zip && \
    rm -rf /var/lib/apt/lists/* && \
    npm install -g openapi2apigee

WORKDIR /code/apigee_automation

COPY *.template ./
COPY Jenkinsfile ./
COPY templates ./templates
COPY *.md ./
COPY *.py ./ 
COPY *.sh ./

WORKDIR /home/ubuntu
