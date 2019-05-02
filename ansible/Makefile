CONTAINER_NAME := ansible-test01

.PHONY: build
build:
	# docker build ./ -t ubuntu18_ansible:latest
	docker build ./ -t elementary_juno_ansible:stable

.PHONY: run
run:
	docker run -itd --rm \
		--net=user_defined_nw \
		--ip=192.168.10.100 \
		-p 30000:22 \
		--name $(CONTAINER_NAME) \
		--cap-add NET_ADMIN \
		elementary_juno_ansible:stable
		# ubuntu18_ansible:latest

.PHONY: login
login:
	docker exec -it $(CONTAINER_NAME) /bin/bash

.PHONY: stop
stop:
	docker stop $(CONTAINER_NAME)

.PHONY: restart
restart: stop run

.PHONY: ansiblecheck
ansiblecheck:
	ansible-playbook -i inventory --extra-vars='@config.yml' playbook.yml --check --diff

.PHONY: ansiblerun
ansiblerun:
	ansible-playbook -i inventory --extra-vars='@config.yml' playbook.yml --diff
