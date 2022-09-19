FROM python:3.9
ARG TARGETARCH=amd64
ARG TERRAFORM_VERSION=1.1.9

RUN pip3 install ansible boto3 && \
    ansible-galaxy collection install community.aws && \
    ansible-galaxy collection install ansible.posix && \
    ansible-galaxy collection install kubernetes.core && \
    curl -v https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${TARGETARCH}.zip -o /tmp/terraform.zip && \
    unzip /tmp/terraform.zip -d /usr/local/bin && \
    chmod 755 /usr/local/bin/terraform && \
    if [ "$TARGETARCH" = "amd64" ]; then \
    curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
    curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_arm64/session-manager-plugin.deb" -o "session-manager-plugin.deb"; \
    fi && dpkg -i session-manager-plugin.deb

WORKDIR /terraform

ENTRYPOINT ["terraform"]