# AWS Forum Demo 2020

## Introduction

The repository contains the **Terraform** and **Ansible** scripts to showcase the **F5 Automation Toolchain** (ATC).

It uses Terraform to spin-up the infrastructure containing :
 - one or more BIG-IP's
 - one or more Nginx based demo servers

It will then use Ansible and the F5 ATC to do :
 - Declarative Onboarding (**DO**) using BIG-IQ as license server
 - Application Service (**AS3**) deployment
 - The decision based on which AS3 blobs to deploy is based on AWS tags

## Prerequisites

The following things are needed to run the demo
 - make installed on host to run the target
 - terraform installed on host to run the infrastructure part
 - ansible installed on host to run the ATC part
 - local **aws credentials should be available** using the aws cli

    ```
    $ cat ~/.aws/credentials
        [default]
        aws_access_key_id = BLABLABLA
        aws_secret_access_key = BLABLABLA
        aws_session_token = BLABLABLA
    ```


You will also need to copy setup.change.yml to setup.yml and adjust the file accordingly. Variables that are absolutely necessary are :
 - owner
 - aws.ec2_key_name
 - bigip.admin_password
 - bigiq.admin_password


## Usage

In order to spinup the demo, a Makefile with several make targets is available. The makefile contains the following targets :

| Makefile target | Explanation | Mandatory |
|-----------------|-------------|-----------|
| make plan_infra | Prepare terraform for infrastructure spin-up | Only the first time |
| make deploy_infra | Deploy or update the infrastructure using terraform | When creating new infra from scratch or updating existing one |
| make destroy_infra | Destroy the infrastructure | Only when demo finished |
| make reset_infra | Destroy existing infra and create a new one from scratch | Optional |
| make do_onboard | Use Ansible and ATS DO module to onboard BIG-IP using BIG-IQ | Mandatory |
| make do_unlicense | Use Ansible and ATS DO module to unlicense BIG-IP to release license pool entry from BIG-IQ  | Optional |
| make as3_http_auto | Deploy the AS3 blobs for scenario HTTP with autodiscovery | Mandatory |
| make as3_ssl_manual | Deploy the AS3 blobs for scenario SSL without autodiscovery | Mandatory |
| make as3_waf_manual | Deploy the AS3 blobs for scenario SSL+WAF without autodiscovery | Mandatory |
| make as3_gslb | Deploy the AS3 blobs for scenario GSLB | Mandatory |
| make as3_undeploy | Deploy the AS3 blobs to remove ADC configuration for the application | Optional |
| make ts_cloudwatch | Enable AWS Cloudwatch monitoring using ATS TS module | Optional |
| make ts_graphite | Enable Graphite monitoring using ATS TS module | Optional |
| make ts_beacon | TODO | Optional |
| make install_galaxy_modules | Install necessary F5 Ansible Galaxy modules | Only once |
| make inventory | Generate and store the dynamic inventory file for Ansible based on AWS infrastructure | Optional |
| make clean_output | Remove the build artifacts from Ansible (dynamic inventory and stored ATC JSON blobs) | Optional |
| make generate_load | Create HTTP load on the webservers | Optional |
| make terraform_validate | Validate the terraform scripts | Optional |
| make terraform_update | Update the terraform module dependencies to the latest upstream version | Optional |

## Output:

The output folder will contain :
 - The terraform plan used for infrastructure spin-up
 - The JSON outputs of the ATC actions (both the requests and reply bodies)
 - The generated config file for dynamic inventory generation using *ansible-inventory*
 - (Optional) The result of the dynamic inventory generation using *ansible-inventory*
