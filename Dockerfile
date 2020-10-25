FROM slok/kahoy:v2.0.0

RUN apk --no-cache add \
    git \
    curl \
    bash

# Download external dependencies.
ARG HELM_VERSION="v3.3.4"
ARG KUBEDOG_VERSION="v0.4.0"
ARG JQ_VERSION="1.6"

RUN wget -O- https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz | \
    tar xvz -C /tmp && \
    mv /tmp/linux-amd64/helm /usr/bin && \
    \
    wget -O /usr/bin/kubedog https://dl.bintray.com/flant/kubedog/${KUBEDOG_VERSION}/kubedog-linux-amd64-${KUBEDOG_VERSION} && \
    chmod +x /usr/bin/kubedog && \
    \
    wget -O /usr/bin/jq https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64 && \
    chmod +x /usr/bin/jq

# Create user
ARG UID=1000
ARG GID=1000
RUN addgroup -g $GID app && \
    adduser -D -u $UID -G app app
USER app

WORKDIR /src

ENTRYPOINT []