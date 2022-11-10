image_name := self-signed-client-auth
http_port := 8080
https_port := 4443
https_port2 := 4444

.PHONY: default
default:
	@echo "Plese specify a target"

.PHONY: run
serve: image
	docker run -p $(http_port):80 -p $(https_port):443 -p $(https_port2):444 $(image_name)

.PHONY: shell
shell:
	docker run -it $(image_name) /bin/bash

.PHONY: test
# test: certs/client.crt certs/client2.crt
test:
	@echo
	curl --cacert certs/ca.crt https://localhost:$(https_port)
	@echo
	curl --cacert certs/ca.crt https://localhost:$(https_port2)
	@echo
	curl --cacert certs/ca.crt --key certs/client.key --cert certs/client.crt https://localhost:$(https_port2)
	@echo
	curl --cacert certs/ca.crt --key certs/client2.key --cert certs/client2.crt https://localhost:$(https_port2)

.PHONY: image
image: certs/server.crt certs/server.crt
	docker build -t $(image_name) .

certs:
	mkdir -p certs

certs/ca.crt: certs
	openssl req \
	  -newkey rsa:4096 \
	  -keyout certs/ca.key \
	  -x509 \
	  -out certs/ca.crt \
	  -days 36500 \
	  -nodes \
	  -subj "/CN=ssca-ca"

certs/server.key: certs
	openssl req \
	  -newkey rsa:4096 \
	  -keyout certs/server.key \
	  -x509 \
	  -out certs/server-ca.crt \
	  -days 36500 \
	  -nodes \
	  -subj "/CN=ssca-server-ca"

certs/server.csr: certs/server.key
	openssl req -new -key certs/server.key -out certs/server.csr -config server-csr.conf

certs/server.crt: certs/ca.crt certs/server.csr
	openssl x509 -req \
	  -in certs/server.csr \
	  -out certs/server.crt \
	  -CA certs/ca.crt \
	  -CAkey certs/ca.key \
	  -CAcreateserial \
	  -days 365

certs/client.key: certs
	openssl genrsa -out certs/client.key 4096

certs/client.csr: certs/client.key
	openssl req -new -key certs/client.key -out certs/client.csr -config client-csr.conf

certs/client.crt: certs/server.key certs/client.csr
	openssl x509 -req \
	  -in certs/client.csr \
	  -out certs/client.crt \
	  -CA certs/server-ca.crt \
	  -CAkey certs/server.key \
	  -CAcreateserial \
	  -days 365

certs/client2.crt:
	openssl req -newkey rsa:4096 -nodes\
	 -keyout certs/client2.key\
	 -x509 -days 365 -out certs/client2.crt\
	 -config client2-csr.conf
