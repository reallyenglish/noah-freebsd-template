AWK?=   /usr/bin/awk
SYSCTL?=    /sbin/sysctl
ENV=?	/usr/bin/env
SHUTDOWN?=	/sbin/shutdown
RM?=	/bin/rm
ECHO?=	/bin/echo
PKG?=	/usr/sbin/pkg
TOUCH?=	/usr/bin/touch
INSTALL?=	/usr/bin/install

FIRSTBOOT_SENTINEL?=	/firstboot

PKG_CACHE_DIR?=	/var/cache/pkg
PKG_DB_DIR?=	/var/db/pkg
FREEBSD_UPDATE_DIR?=	/var/db/freebsd-update
SRC_BASE?=  /usr/src

FILES_DIR?=	files
FILES=	/etc/ssh/sshd_config \
		/usr/local/etc/rc.d/cloudstack_fetchkey

PACKAGES=	firstboot-freebsd-update

# Get __FreeBSD_version (obtained from bsd.port.mk)
.if !defined(OSVERSION)
.if exists(/usr/include/sys/param.h)
OSVERSION!= ${AWK} '/^\#define[[:blank:]]__FreeBSD_version/ {print $$3}' < /usr/include/sys/param.h
.elif exists(${SRC_BASE}/sys/sys/param.h)
OSVERSION!= ${AWK} '/^\#define[[:blank:]]__FreeBSD_version/ {print $$3}' < ${SRC_BASE}/sys/sys/param.h
.else
OSVERSION!= ${SYSCTL} -n kern.osreldate
.endif
.endif

.if empty(OSVERSION)
IGNORE=	cannot determine OSVERSION
.endif
.if ${OSVERSION} < 1000000
IGNORE=	requires FreeBSD 10.0 or above
.endif

all:	init ${FILES} ${PACKAGES} ${FIRSTBOOT_SENTINEL} clean shutdown

init:
.if defined(IGNORE)
	@${ECHO} ">>> ${IGNORE}" && exit 1
.endif

${FILES}:	${FILES_DIR}/${.TARGET}
	${INSTALL} -o root -g wheel ${FILES_DIR}${.TARGET} ${.TARGET}

bootstrap-pkg:
	if ! ${PKG} -N 2>/dev/null; then \
		${ENV} ASSUME_ALWAYS_YES=1 ${PKG} bootstrap ;\
	fi

${PACKAGES}:	bootstrap-pkg
	${ENV} ASSUME_ALWAYS_YES=1 ${PKG} install ${.TARGET} </dev/null

${FIRSTBOOT_SENTINEL}:
	${TOUCH} ${.TARGET}

clean:
	${RM} -f /root/.ssh/authorized_keys
	${RM} -f /root/.history
	${RM} -f /home/cs-user/.ssh/authorized_keys
	${RM} -f /home/cs-user/.history
	${RM} -f /etc/ssh/ssh_host_*
	${RM} -rf ${PKG_CACHE_DIR}/*
	${RM} -f ${PKG_DB_DIR}/repo-*.sqlite
	${RM} -rf ${FREEBSD_UPDATE_DIR}

shutdown:
	${SHUTDOWN} -p now
