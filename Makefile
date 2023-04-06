export CGO_ENABLED:=0

VERSION=$(shell git describe --tags --match=v* --always --dirty)
SEMVER=$(shell git describe --tags --match=v* --always --dirty | cut -c 2-)

.PHONY: all
all: build test vet fmt

.PHONY: build
build: clean bin/terraform-provider-ignore

bin/terraform-provider-ignore:
	@go build -o $@ github.com/poseidon/terraform-provider-ignore

.PHONY: test
test:
	@go test ./... -cover

.PHONY: vet
vet:
	@go vet -all ./...

.PHONY: fmt
fmt:
	@test -z $$(go fmt ./...)

.PHONY: clean
clean:
	@rm -rf bin
	@rm -rf _output

.PHONY: release
release: \
	clean \
	_output/plugin-linux-amd64.zip \
	_output/plugin-linux-arm64.zip \
	_output/plugin-darwin-amd64.zip \
	_output/plugin-darwin-arm64.zip \
	_output/plugin-windows-amd64.zip

_output/plugin-%.zip: NAME=terraform-provider-ignore_$(SEMVER)_$(subst -,_,$*)
_output/plugin-%.zip: DEST=_output/$(NAME)
_output/plugin-%.zip: _output/%/terraform-provider-ignore
	@mkdir -p $(DEST)
	@cp _output/$*/terraform-provider-ignore $(DEST)/terraform-provider-ignore_$(VERSION)
	@zip -j $(DEST).zip $(DEST)/terraform-provider-ignore_$(VERSION)

_output/linux-amd64/terraform-provider-ignore: GOARGS = GOOS=linux GOARCH=amd64
_output/linux-arm64/terraform-provider-ignore: GOARGS = GOOS=linux GOARCH=arm64
_output/darwin-amd64/terraform-provider-ignore: GOARGS = GOOS=darwin GOARCH=amd64
_output/darwin-arm64/terraform-provider-ignore: GOARGS = GOOS=darwin GOARCH=arm64
_output/windows-amd64/terraform-provider-ignore: GOARGS = GOOS=windows GOARCH=amd64
_output/%/terraform-provider-ignore:
	$(GOARGS) go build -o $@ github.com/poseidon/terraform-provider-ignore

release-sign:
	cd _output; sha256sum *.zip > terraform-provider-ignore_$(SEMVER)_SHA256SUMS
	gpg2 --detach-sign _output/terraform-provider-ignore_$(SEMVER)_SHA256SUMS

release-verify: NAME=_output/terraform-provider-ignore
release-verify:
	gpg2 --verify $(NAME)_$(SEMVER)_SHA256SUMS.sig $(NAME)_$(SEMVER)_SHA256SUMS
