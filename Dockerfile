FROM alpine:3.13 as build
LABEL maintainer="Konkerlabs, Andre Rocha <andre@konkerlabs.com>"

# Define environment variable
ENV HELM_VERSION v3.6.3

RUN apk add --update --no-cache ca-certificates git bash openssl

#ENV VERSION=v3.2.1
#ENV FILENAME=helm-${VERSION}-linux-amd64.tar.gz
#ENV SHA256SUM=10e1fdcca263062b1d7b2cb93a924be1ef3dd6c381263d8151dd1a20a3d8c0dc

WORKDIR /

RUN apk add --update -t deps curl tar gzip

RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
RUN chmod 700 get_helm.sh
# RUN cat ./get_helm.sh
RUN ./get_helm.sh \
    && rm -rf get_helm.sh

#RUN curl -L https://get.helm.sh/${FILENAME} > ${FILENAME} && \
#    echo "${SHA256SUM}  ${FILENAME}" > helm_${VERSION}_SHA256SUMS && \
#    sha256sum -cs helm_${VERSION}_SHA256SUMS && \
#    tar zxv -C /tmp -f ${FILENAME} && \
#    rm -f ${FILENAME}

RUN helm version --client

FROM alpine:3.18

#ARG KUBERNETES_VERSION=1.27.3
#$(curl -LS https://dl.k8s.io/release/stable.txt)
ARG AWS_IAM_AUTHENTICATOR_VERSION=0.3.0

RUN apk add --update --no-cache git ca-certificates bash

#COPY --from=build /tmp/linux-amd64/helm /bin/helm
COPY --from=build /usr/local/bin/helm /bin/helm

RUN apk update
RUN apk add ca-certificates
RUN update-ca-certificates
RUN apk add --update --upgrade --no-cache jq bash curl
RUN  apk -v --update add \
            python3 \
            py3-pip \
            groff \
            less \
            mailcap

# RUN pip install --upgrade awscli==1.16.93 s3cmd==2.3.0 python-magic
RUN pip install --upgrade awscli s3cmd python-magic

RUN apk -v --purge del py3-pip
RUN rm /var/cache/apk/*
RUN curl -L -o /usr/local/bin/aws-iam-authenticator https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v${AWS_IAM_AUTHENTICATOR_VERSION}/heptio-authenticator-aws_${AWS_IAM_AUTHENTICATOR_VERSION}_linux_amd64
RUN chmod +x /usr/local/bin/aws-iam-authenticator
#RUN curl -k -LS https://dl.k8s.io/release/stable.txt
RUN curl -k -L -o /usr/local/bin/kubectl https://dl.k8s.io/release/$(curl -k -LS https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl; \
    chmod +x /usr/local/bin/kubectl

ADD assets /opt/resource
RUN chmod +x /opt/resource/*

RUN helm plugin install https://github.com/databus23/helm-diff

ENTRYPOINT ["/bin/helm"]
