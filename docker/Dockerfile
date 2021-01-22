FROM alpine:3.13
MAINTAINER Daniel Engfeldt <daniel@engfeldt.net>

ENV AWS_DEFAULT_REGION=eu-north-1
ENV KUBECTL_VERSION v1.19.0
ENV HELM_VERSION v2.13.1
ENV AWSCLI 1.18.160
ENV TERRAFORM_VERSION 0.13.5
ENV AWS_IAM_AUTH_VERSION=0.5.2
ENV SPIN_CLI_VERSION=1.19.0

RUN apk --update --no-cache add \
  bash \
  ca-certificates \
  curl \
  jq \
  git \
  openssh-client \
  python3 \
  cmd:pip3 \
  tar \
  wget

RUN pip3 install --upgrade pip
RUN pip3 install requests awscli==${AWSCLI}

# isntall aws-iam-authenticator
# TOFO, rewrite kubeconfig so that this is no longer necessary
# aws-iam-authenticator has been included into aws cli by default since version XXX
RUN curl -L https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v${AWS_IAM_AUTH_VERSION}/aws-iam-authenticator_${AWS_IAM_AUTH_VERSION}_linux_amd64 -o /usr/local/bin/aws-iam-authenticator && \
    chmod +x /usr/local/bin/aws-iam-authenticator

# Install Terraform
RUN cd /usr/local/bin && \
    curl https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Install kubectl
RUN curl -L https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl

# Install helm
RUN wget -q http://storage.googleapis.com/kubernetes-helm/helm-${HELM_VERSION}-linux-amd64.tar.gz -O - | tar -xzO linux-amd64/helm > /usr/local/bin/helm \
  && chmod +x /usr/local/bin/helm

# Install Spinnaker CLI
RUN curl -L https://storage.googleapis.com/spinnaker-artifacts/spin/${SPIN_CLI_VERSION}/linux/amd64/spin -o /usr/local/bin/spin \
  && chmod +x /usr/local/bin/spin

# Install envsubst
ENV BUILD_DEPS="gettext"  \
    RUNTIME_DEPS="libintl"

RUN set -x && \
    apk add --update $RUNTIME_DEPS && \
    apk add --virtual build_deps $BUILD_DEPS &&  \
    cp /usr/bin/envsubst /usr/local/bin/envsubst && \
    apk del build_deps

ADD docker/scripts/ /scripts/
WORKDIR /work

# add terraform user and make script executable
#RUN adduser -D -u 10000 terraform
#RUN chown terraform /entrypoint.sh && chmod u+x /entrypoint.sh
#USER terraform

ENTRYPOINT ["/scripts/help.sh"]