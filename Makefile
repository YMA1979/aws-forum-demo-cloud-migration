# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help
.PHONY: plan_infra deploy_infra destroy_infra reset_infra
.PHONY: do_license do_unlicense as3_deploy as3_remove ts_cloudwatch  
.PHONY: inventory install_galaxy_modules clean_output generate_load terraform_validate terraform_update

help: ## This help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help


## Input variables ##
SETUP_FILE=${CURDIR}/setup.yml
TERRAFORM_FOLDER=${CURDIR}/terraform
ANSIBLE_FOLDER=${CURDIR}/ansible

## Output variables ##
OUTPUT_FOLDER=${CURDIR}/output
TERRAFORM_PLAN=${OUTPUT_FOLDER}/aws_tfplan.tf
ANSIBLE_DYNAMIC_AWS_INVENTORY=${OUTPUT_FOLDER}/aws_inventory.yml
ANSIBLE_DYNAMIC_AWS_INVENTORY_CONFIG=${OUTPUT_FOLDER}/aws_ec2.yml
GENERATE_LOAD_SCRIPT=${OUTPUT_FOLDER}/generate_load.sh

## Exec arguments ##
TERRAFORM_EXTRA_ARGS=-var "setupfile=${SETUP_FILE}" -var "awsinventoryconfig=${ANSIBLE_DYNAMIC_AWS_INVENTORY_CONFIG}" -var "generateloadscript=${GENERATE_LOAD_SCRIPT}"
# ANSIBLE_EXTRA_ARGS=-vvv --extra-vars "setupfile=${SETUP_FILE} outputfolder=${OUTPUT_FOLDER}"
ANSIBLE_EXTRA_ARGS=--extra-vars "setupfile=${SETUP_FILE} outputfolder=${OUTPUT_FOLDER}"

#####################
# Terraform Targets #
#####################

plan_infra: ## Plan infrastructure changes using terraform
	cd ${TERRAFORM_FOLDER} && terraform init -input=false ;
	cd ${TERRAFORM_FOLDER} && terraform plan -out=${TERRAFORM_PLAN} -input=false ${TERRAFORM_EXTRA_ARGS} ;

deploy_infra: plan_infra ## Deploy infrastructure using terraform
	cd ${TERRAFORM_FOLDER} && terraform apply -input=false -auto-approve ${TERRAFORM_PLAN} ;


destroy_infra: clean_output ## Cleanup infrastructure managed by terraform
	cd ${TERRAFORM_FOLDER} && terraform destroy -auto-approve ${TERRAFORM_EXTRA_ARGS} ;

reset_infra: destroy_infra clean_output deploy_infra inventory ## Cleanup existing and create new infrastructure using terraform

###################
# Ansible Targets #
###################

### DO Targets ###
do_onboard: ## Declarative onbording using ansible
	cd ${ANSIBLE_FOLDER} && ansible-playbook do.yml ${ANSIBLE_EXTRA_ARGS} --skip-tags "unlicense" ;

do_unlicense: ## Unlicense BIG-IP device using declarative onboarding in ansible
	cd ${ANSIBLE_FOLDER} && ansible-playbook do.yml ${ANSIBLE_EXTRA_ARGS} --skip-tags "onboard" ; 

### AS3 Targets ###

# no logging #
as3_http_auto: ## Application service 3 deployment of http + auto-discovery using ansible (no log profile)
	cd ${ANSIBLE_FOLDER} && ansible-playbook as3_auto.yml ${ANSIBLE_EXTRA_ARGS} --extra-vars "scenario=http" --skip-tags "undeploy" ;

as3_ssl_manual: as3_undeploy ## Application service 3 deployment of ssl + no-auto-discovery using ansible (no log profile)
	cd ${ANSIBLE_FOLDER} && ansible-playbook as3_manual.yml ${ANSIBLE_EXTRA_ARGS} --extra-vars "scenario=ssl" --skip-tags "undeploy" ;

as3_waf_manual: ## Application service 3 deployment of ssl + waf + no-auto-discovery using ansible (no log profile)
	cd ${ANSIBLE_FOLDER} && ansible-playbook as3_manual.yml ${ANSIBLE_EXTRA_ARGS} --extra-vars "scenario=waf" --skip-tags "undeploy" ;

# with logging #
as3_http_auto_log: ## Application service 3 deployment of http + auto-discovery using ansible (with log profile)
	cd ${ANSIBLE_FOLDER} && ansible-playbook as3_auto_log.yml ${ANSIBLE_EXTRA_ARGS} --extra-vars "scenario=http" --skip-tags "undeploy" ;

as3_ssl_manual_log: as3_undeploy ## Application service 3 deployment of ssl + no-auto-discovery using ansible (with log profile)
	cd ${ANSIBLE_FOLDER} && ansible-playbook as3_manual_log.yml ${ANSIBLE_EXTRA_ARGS} --extra-vars "scenario=ssl" --skip-tags "undeploy" ;

as3_waf_manual_log: ## Application service 3 deployment of ssl + waf + no-auto-discovery using ansible (with log profile)
	cd ${ANSIBLE_FOLDER} && ansible-playbook as3_manual_log.yml ${ANSIBLE_EXTRA_ARGS} --extra-vars "scenario=waf" --skip-tags "undeploy" ;

# GSLB #
as3_gslb: ## Application service 3 deployment of GSLB services using ansible
	cd ${ANSIBLE_FOLDER} && ansible-playbook as3_gslb.yml ${ANSIBLE_EXTRA_ARGS} --skip-tags "undeploy" ;

# Undeploy #
as3_undeploy: ## Application service 3 undeployment/removal using ansible
	cd ${ANSIBLE_FOLDER} && ansible-playbook as3_manual.yml ${ANSIBLE_EXTRA_ARGS} --extra-vars "scenario=http" --skip-tags "deploy" ;

### TS Targets ###
ts_cloudwatch: ## Telemetry streaming for cloudwatch using ansible
	cd ${ANSIBLE_FOLDER} && ansible-playbook ts.yml ${ANSIBLE_EXTRA_ARGS} --skip-tags "graphite_grafana,statsd_grafana,elk,beacon" ;

ts_graphite_grafana: ## Telemetry streaming for graphite using ansible
	cd ${ANSIBLE_FOLDER} && ansible-playbook ts.yml ${ANSIBLE_EXTRA_ARGS} --skip-tags "cloudwatch,statsd_grafana,elk,beacon" ;

ts_statsd_grafana: ## Telemetry streaming for statsd using ansible
	cd ${ANSIBLE_FOLDER} && ansible-playbook ts.yml ${ANSIBLE_EXTRA_ARGS} --skip-tags "cloudwatch,graphite_grafana,elk,beacon" ;

ts_elk: ## Telemetry streaming for ELK using ansible
	cd ${ANSIBLE_FOLDER} && ansible-playbook ts.yml ${ANSIBLE_EXTRA_ARGS} --skip-tags "cloudwatch,graphite_grafana,statsd_grafana,beacon" ;

ts_beacon: ## Telemetry streaming for beacon using ansible
	cd ${ANSIBLE_FOLDER} && ansible-playbook ts.yml ${ANSIBLE_EXTRA_ARGS} --skip-tags "cloudwatch,graphite_grafana,statsd_grafana,elk" ;

##################
# Helper Targets #
##################

install_galaxy_modules: ## Install ansible galaxy dependencies
	ansible-galaxy install f5devcentral.atc_deploy ; \
	ansible-galaxy collection install f5networks.f5_modules

inventory: ## Generate AWS dynamic inventory for ansible debugging
	cd ${ANSIBLE_FOLDER} && ansible-inventory --yaml --list > ${ANSIBLE_DYNAMIC_AWS_INVENTORY} ;

clean_output: ## Remove all temorary output/build artifacts
	rm -f ${OUTPUT_FOLDER}/*.yml ${OUTPUT_FOLDER}/*.json ${OUTPUT_FOLDER}/*.tf ${OUTPUT_FOLDER}/*.sh ${OUTPUT_FOLDER}/*.pem ;

generate_load_http: ## Generate traffic load
	${OUTPUT_FOLDER}/generate_load.sh ;

terraform_validate: ## Validate terraform syntax and linting
	cd ${TERRAFORM_FOLDER} && terraform validate ;
	cd ${TERRAFORM_FOLDER} && terraform fmt -recursive ;

terraform_update: ## Perform terraform module update
	cd ${TERRAFORM_FOLDER} && terraform get -update=true ;

test: ## Dummy test target for ansible exploration of the dynamic inventory variables
	cd ${ANSIBLE_FOLDER} && ansible-playbook show_inv.yml ${ANSIBLE_EXTRA_ARGS}
