.PHONY: plan_infra deploy_infra destroy_infra reset_infra
.PHONY: do_license do_unlicense as3_deploy as3_remove ts_cloudwatch  
.PHONY: inventory install_galaxy_modules clean_output generate_load terraform_validate terraform_update

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

plan_infra: 
	cd ${TERRAFORM_FOLDER} && terraform init -input=false ;
	cd ${TERRAFORM_FOLDER} && terraform plan -out=${TERRAFORM_PLAN} -input=false ${TERRAFORM_EXTRA_ARGS} ;

deploy_infra: plan_infra
	cd ${TERRAFORM_FOLDER} && terraform apply -input=false -auto-approve ${TERRAFORM_PLAN} ;


destroy_infra: clean_output
	cd ${TERRAFORM_FOLDER} && terraform destroy -auto-approve ${TERRAFORM_EXTRA_ARGS} ;

reset_infra: destroy_infra clean_output deploy_infra inventory

###################
# Ansible Targets #
###################

### DO Targets ###
do_onboard:
	cd ${ANSIBLE_FOLDER} && ansible-playbook do.yml ${ANSIBLE_EXTRA_ARGS} --skip-tags "unlicense" ;

do_unlicense:
	cd ${ANSIBLE_FOLDER} && ansible-playbook do.yml ${ANSIBLE_EXTRA_ARGS} --skip-tags "onboard" ; 

### AS3 Targets ###
as3_http_auto:
	cd ${ANSIBLE_FOLDER} && ansible-playbook as3_auto.yml ${ANSIBLE_EXTRA_ARGS} --extra-vars "scenario=http" --skip-tags "undeploy" ;

as3_ssl_manual: as3_undeploy
	cd ${ANSIBLE_FOLDER} && ansible-playbook as3_manual.yml ${ANSIBLE_EXTRA_ARGS} --extra-vars "scenario=ssl" --skip-tags "undeploy" ;

as3_waf_manual:
	cd ${ANSIBLE_FOLDER} && ansible-playbook as3_manual.yml ${ANSIBLE_EXTRA_ARGS} --extra-vars "scenario=waf" --skip-tags "undeploy" ;

as3_gslb:
	cd ${ANSIBLE_FOLDER} && ansible-playbook as3_gslb.yml ${ANSIBLE_EXTRA_ARGS} --skip-tags "undeploy" ;

as3_undeploy:
	cd ${ANSIBLE_FOLDER} && ansible-playbook as3_manual.yml ${ANSIBLE_EXTRA_ARGS} --extra-vars "scenario=http" --skip-tags "deploy" ;

### TS Targets ###
ts_cloudwatch:
	cd ${ANSIBLE_FOLDER} && ansible-playbook ts.yml ${ANSIBLE_EXTRA_ARGS} --skip-tags "graphite_grafana,statsd_grafana,elk,beacon" ;

ts_graphite_grafana:
	cd ${ANSIBLE_FOLDER} && ansible-playbook ts.yml ${ANSIBLE_EXTRA_ARGS} --skip-tags "cloudwatch,statsd_grafana,elk,beacon" ;

ts_statsd_grafana:
	cd ${ANSIBLE_FOLDER} && ansible-playbook ts.yml ${ANSIBLE_EXTRA_ARGS} --skip-tags "cloudwatch,graphite_grafana,elk,beacon" ;

ts_elk:
	cd ${ANSIBLE_FOLDER} && ansible-playbook ts.yml ${ANSIBLE_EXTRA_ARGS} --skip-tags "cloudwatch,graphite_grafana,statsd_grafana,beacon" ;

ts_beacon:
	cd ${ANSIBLE_FOLDER} && ansible-playbook ts.yml ${ANSIBLE_EXTRA_ARGS} --skip-tags "cloudwatch,graphite_grafana,statsd_grafana,elk" ;

##################
# Helper Targets #
##################

install_galaxy_modules:
	ansible-galaxy install f5devcentral.atc_deploy ; \
	ansible-galaxy collection install f5networks.f5_modules

inventory:
	cd ${ANSIBLE_FOLDER} && ansible-inventory --yaml --list > ${ANSIBLE_DYNAMIC_AWS_INVENTORY} ;

clean_output:
	rm -f ${OUTPUT_FOLDER}/*.yml ${OUTPUT_FOLDER}/*.json ${OUTPUT_FOLDER}/*.tf ${OUTPUT_FOLDER}/*.sh ${OUTPUT_FOLDER}/*.pem ;

generate_load_http:
	${OUTPUT_FOLDER}/generate_load.sh ;

terraform_validate: 
	cd ${TERRAFORM_FOLDER} && terraform validate ;
	cd ${TERRAFORM_FOLDER} && terraform fmt -recursive ;

terraform_update: 
	cd ${TERRAFORM_FOLDER} && terraform get -update=true ;

test:
	cd ${ANSIBLE_FOLDER} && ansible-playbook show_inv.yml ${ANSIBLE_EXTRA_ARGS}
