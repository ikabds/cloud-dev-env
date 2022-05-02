FROM python:3.9
ARG TARGETARCH
ARG TERRAFORM_VERSION=1.1.9
ADD https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${TARGETARCH}.zip /usr/local/bin/terraform
RUN pip3 install ansible && \
    ansible-galaxy collection install community.aws && \
    ansible-galaxy collection install ansible.posix

ENTRYPOINT ["terraform"]