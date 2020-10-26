.PHONY: build
build:
	@docker build -t xackery/godev:1.12.17 .
.PHONY: push
push:
	@docker push xackery/godev:1.12.17