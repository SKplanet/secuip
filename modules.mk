mod_secuip.la: mod_secuip.slo
	$(SH_LINK) -rpath $(libexecdir) -module -avoid-version  mod_secuip.lo
DISTCLEAN_TARGETS = modules.mk
shared =  mod_secuip.la
