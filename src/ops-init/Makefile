SBIN:=$(DESTDIR)/usr/sbin
TARBALL:=master.tar.gz
CONTENTS:=ops-build-master
YOCTO:=$(CONTENTS)/yocto

all: $(YOCTO)

$(TARBALL):
	wget https://github.com/open-switch/ops-build/archive/$@

$(YOCTO): $(TARBALL)
	tar -xzf $<

install:
	install -d $(SBIN)
	install -m 755 start-openswitch.sh $(SBIN)/start-openswitch
	install -m 755 $(YOCTO)/openswitch/meta-distro-openswitch/recipes-ops/platform/ops-init/ops-init.sh $(SBIN)/ops-init
