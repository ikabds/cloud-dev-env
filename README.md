# Cloud9 Terraform and Ansible configuration via SSM
Sometimes working on local PC can produce inconsistency for deployment. Moreover it is good practice to run some configuration scripts from centralized place.  
`Cloud9` from AWS is good IDE for sharing access, especially when integrated with `VS Code Remote`. This repository contains IaaC for provisioning such an environment.

## Prerequisites
Install on you local machine following tools:
1) Terraform
2) Ansible
3) Some collections and libs:
```
pip3 install boto3
ansible-galaxy collection install community.aws
ansible-galaxy collection install ansible.posix
ansible-galaxy collection install kubernetes.core
```
4) Install session-manager plugin: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html

## Consideration
Please, consider using existing S3 bucket for SSM commands if you want to avoid bug with newly created buckets, described here: https://github.com/ansible-collections/community.aws/issues/637

Set "existing_s3_bucket_name" in terraform.tfvars.json

## Run with docker
You can build docker image and run installation from Docker container:
```
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
export AWS_SESSION_TOKEN=

docker build -t cloud-env-dev .
docker run -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_SESSION_TOKEN -it -v "$(pwd)":/terraform cloud-env-dev init
docker run -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_SESSION_TOKEN -it -v "$(pwd)":/terraform cloud-env-dev apply
```