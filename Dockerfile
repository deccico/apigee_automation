FROM ubuntu:18.04

RUN apt update && apt-get install -y curl htop python vim unzip zip

WORKDIR /code
COPY . ./ 
