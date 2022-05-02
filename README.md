# Prerequisites
1) Terraform
2) Ansible
3) ansible-galaxy collection install community.aws
4) Install https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html#install-plugin-macos
5) ansible-galaxy collection install ansible.posix
6) boto3
7) session-manager-plugin

# Alternatively Docker
`docker build -t cloud-env-dev .`
`docker run -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_SESSION_TOKEN -it -v "$(pwd)":/terraform cloud-env-dev init`
`docker run -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_SESSION_TOKEN -it -v "$(pwd)":/terraform cloud-env-dev apply`