# The targets cannot be run in parallel
.NOTPARALLEL:

VERSION       := $(shell git describe --tags --always --match "[0-9][0-9][0-9][0-9]\.*\.*")

VERSION_FLAGS := -X "main.buildVersion=$(VERSION)"


BINARY_NAME := goenvtemplator

LINK_FLAGS :=
LDFLAGS := -ldflags='-w -s $(VERSION_FLAGS) $(LINK_FLAGS)'
ifneq ($(GO_BUILD_TAGS),)
	GO_BUILD_TAGS := -tags "$(GO_BUILD_TAGS)"
endif

ifeq ($(debug), 1)
	GO_BUILD_TAGS += -gcflags="all=-N -l"
endif

IMPORT_PATH    := github.com/seznam/goenvtemplator
FJ_GO_PATH     := /tmp/go
PATH           := $(FJ_GO_PATH)/bin:$(PATH)

LOCAL_ARCH ?= $(shell uname -m)
ifneq ($(GOARCH),)
    TARGET_ARCH ?= $(GOARCH)
else ifeq ($(LOCAL_ARCH),x86_64)
    TARGET_ARCH ?= amd64
else ifeq ($(LOCAL_ARCH),amd64)
    TARGET_ARCH ?= amd64
else ifeq ($(LOCAL_ARCH),i686)
    TARGET_ARCH ?= amd64
else ifeq ($(shell echo $(LOCAL_ARCH) | head -c 5),armv8)
    TARGET_ARCH ?= arm64
else ifeq ($(LOCAL_ARCH),aarch64)
    TARGET_ARCH ?= arm64
else ifeq ($(LOCAL_ARCH),arm64)
    TARGET_ARCH ?= arm64
else ifeq ($(shell echo $(LOCAL_ARCH) | head -c 4),armv)
    TARGET_ARCH ?= arm
else ifeq ($(LOCAL_ARCH),s390x)
    TARGET_ARCH ?= s390x
else
    $(error This system's architecture $(LOCAL_ARCH) isn't supported)
endif

LOCAL_OS ?= $(shell go env GOOS)
ifeq ($(LOCAL_OS),linux)
    TARGET_OS ?= linux
else ifeq ($(LOCAL_OS),darwin)
    TARGET_OS ?= darwin
else ifeq ($(LOCAL_OS),windows)
    TARGET_OS ?= windows
else ifeq ($(LOCAL_OS),freebsd)
    TARGET_OS ?= freebsd
else ifeq ($(LOCAL_OS),openbsd)
    TARGET_OS ?= openbsd
else
    $(error This system's OS $(LOCAL_OS) isn't supported)
endif

ifneq ($(TARGET_ARM), )
	ARM_COMMAND := GOARM=$(TARGET_ARM)
endif

.PHONY: all
all: goenvtemplator

.PHONY: clean
clean:
	go clean

.PHONY: goenvtemplator
goenvtemplator:
	cd goenvtemplator && GOOS=$(TARGET_OS) GOARCH=$(TARGET_ARCH) $(ARM_COMMAND) go build -mod=vendor $(GO_BUILD_TAGS) $(LDFLAGS) $(IMPORT_PATH)

.PHONY: container
container:
	docker build --build-arg TARGET_ARCH=$(TARGET_ARCH) --build-arg TARGET_OS=$(TARGET_OS) -t framjet/goenvtemplator-$(TARGET_OS)-$(TARGET_ARCH):"$(VERSION)" .

.PHONY: generate-docker-version
generate-docker-version:
	echo latest $(VERSION) > versions


