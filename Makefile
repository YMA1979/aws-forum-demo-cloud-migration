.PHONY: plan_infra deploy_infra destroy_infra reset_infra
.PHONY: do_license do_unlicense as3_deploy as3_remove ts_cloudwatch  
.PHONY: inventory install_galaxy_modules clean_output generate_load terraform_validate terraform_update

SETUP_FILE=../setup.yml
TERRAFORM_PLAN=../output/aws_tfplan.tf
ANSIBLE_DYNAMIC_AWS_INVENTORY=../output/aws_inventory

#####################
# Terraform Targets #
#####################

plan_infra:
	cd terraform ; \
	terraform init -input=false ; \
	terraform plan -out=${TERRAFORM_PLAN} -input=false -var 'setup_file=${SETUP_FILE}' ; \
	cd ..

deploy_infra: plan_infra
	cd terraform ; \
	terraform apply -input=false -auto-approve ${TERRAFORM_PLAN} ;
	cd ansible ; \
	ansible-inventory --yaml --list > ${ANSIBLE_DYNAMIC_AWS_INVENTORY}.yml ; \
	ansible-inventory  --list > ${ANSIBLE_DYNAMIC_AWS_INVENTORY}.json ; \
	cd ..

destroy_infra: clean_output
	cd terraform ; \
	terraform destroy -var 'setup_file=${SETUP_FILE}' -auto-approve ; \
	cd ..

reset_infra: destroy_infra clean_output deploy_infra inventory

###################
# Ansible Targets #
###################

### DO Targets ###
do_license:
	cd ansible ; \
	ansible-playbook do.yml --extra-vars "scenario=do_license" ; \
	cd .. 

do_unlicense:
	cd ansible ; \
	ansible-playbook do.yml --extra-vars "scenario=do_unlicense" ; \
	cd ..

### AS3 Targets ###
as3_deploy:
	cd ansible ; \
	ansible-playbook as3.yml --extra-vars "scenario=as3_deploy tenant=Team_A application=NginxWebServer" ; \
	cd ..

as3_remove:
	cd ansible ; \
	ansible-playbook as3.yml --extra-vars "scenario=as3_remove tenant=Team_A application=NginxWebServer" ; \
	cd ..

### TS Targets ###
ts_cloudwatch:
	cd ansible ; \
	ansible-playbook ts.yml --extra-vars "telemetry=cloudwatch" ; \
	cd ..

##################
# Helper Targets #
##################

install_galaxy_modules:
	ansible-galaxy install f5devcentral.atc_deploy ; \
	ansible-galaxy collection install f5networks.f5_modules

inventory:
	cd ansible ; \
	ansible-inventory --yaml --list > ${ANSIBLE_DYNAMIC_AWS_INVENTORY}.yml ; \
	ansible-inventory --list > ${ANSIBLE_DYNAMIC_AWS_INVENTORY}.json ; \
	cd ..

clean_output:
	rm -f ./output/*.yml ./output/*.json ./output/*.tf

generate_load:
	siege -c20 ec2-18-132-75-167.eu-west-2.compute.amazonaws.com  -b -t300s


terraform_validate:
	cd terraform ; \
	terraform validate ; \
	terraform fmt -recursive -diff ; \
	cd ..

terraform_update:
	cd terraform ; \
	terraform get -update=true ; \
	cd ..
