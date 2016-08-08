PACKAGE = inetutils
ORG = amylum

BUILD_DIR = /tmp/$(PACKAGE)-build
RELEASE_DIR = /tmp/$(PACKAGE)-release
RELEASE_FILE = /tmp/$(PACKAGE).tar.gz
PATH_FLAGS = --prefix=/usr --libexec=/usr/bin --localstatedir=/var --sysconfdir=/etc
CONF_FLAGS = --without-wrap --enable-telnet --enable-hostname --enable-dnsdomainname --disable-rexec --disable-rexecd --disable-tftp --disable-tftpd --disable-ping --disable-ping6 --disable-logger --disable-syslogd --disable-inetd --disable-whois --disable-uucpd --disable-ifconfig --disable-traceroute --disable-rlogin --disable-rcp

PACKAGE_VERSION = $$(git --git-dir=upstream/.git describe --tags | sed 's/inetutils-//;s/_/./g')
PATCH_VERSION = $$(cat version)
VERSION = $(PACKAGE_VERSION)-$(PATCH_VERSION)

.PHONY : default build_container submodule deps manual container deps build version push local

default: submodule container

build_container:
	docker build -t inetutils-pkg meta

submodule:
	git submodule update --init

manual: build_container submodule
	./meta/launch /bin/bash || true

container: build_container
	./meta/launch

build: submodule
	rm -rf $(BUILD_DIR)
	cp -R upstream $(BUILD_DIR)
	cd $(BUILD_DIR) && ./bootstrap
	cd $(BUILD_DIR) && CC=musl-gcc ./configure $(PATH_FLAGS) $(CONF_FLAGS)
	cd $(BUILD_DIR) && make DESTDIR=$(RELEASE_DIR) install
	mkdir -p $(RELEASE_DIR)/usr/share/licenses/$(PACKAGE)
	cp $(BUILD_DIR)/COPYING $(RELEASE_DIR)/usr/share/licenses/$(PACKAGE)/
	cd $(RELEASE_DIR) && tar -czvf $(RELEASE_FILE) *

version:
	@echo $$(($(PATCH_VERSION) + 1)) > version

push: version
	git commit -am "$(VERSION)"
	ssh -oStrictHostKeyChecking=no git@github.com &>/dev/null || true
	git tag -f "$(VERSION)"
	git push --tags origin master
	@sleep 3
	targit -a .github -c -f $(ORG)/$(PACKAGE) $(VERSION) $(RELEASE_FILE)
	@sha512sum $(RELEASE_FILE) | cut -d' ' -f1

local: build push

