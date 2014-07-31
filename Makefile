AWK?=   /usr/bin/awk
SYSCTL?=    /sbin/sysctl
ENV?=	/usr/bin/env
SHUTDOWN?=	/sbin/shutdown
RM?=	/bin/rm
ECHO?=	/bin/echo
PKG?=	/usr/sbin/pkg
TOUCH?=	/usr/bin/touch
INSTALL?=	/usr/bin/install
PW?=	/usr/sbin/pw
GREP?=	/usr/bin/grep
SED?=	/usr/bin/sed
DIRNAME?=	/usr/bin/dirname

FIRSTBOOT_SENTINEL?=	/firstboot

PKG_CACHE_DIR?=	/var/cache/pkg
PKG_DB_DIR?=	/var/db/pkg
FREEBSD_UPDATE_DIR?=	/var/db/freebsd-update
SRC_BASE?=  /usr/src
HOME_DIR?=	/usr/home
INITIAL_USER?=	cs-user
INITIAL_USER_HOME_DIR?=	${HOME_DIR}/${INITIAL_USER}
INITIAL_USER_PASSWORD?=	password

FILES_DIR?=	files
# FILES				files to install under ${FILES_DIR}
FILES+=	/etc/ssh/sshd_config \
		/usr/local/etc/rc.d/cs_fetchkey \
		/usr/local/etc/pkg/repos/FreeBSD.conf \
		/usr/local/sbin/cs_configinit \
		/usr/local/etc/rc.d/cs_configinit

# FILES_TO_CLEAN	files to remove before reboot
FILES_TO_CLEAN= /root/.ssh/authorized_keys \
	/root/.history \
	${INITIAL_USER_HOME_DIR}/.history \
	/etc/ssh/ssh_host_*	\
	${PKG_DB_DIR}/repo-*.sqlite \
	${FREEBSD_UPDATE_DIR}/*
# DIRS_TO_CLEAN		directories to remove before reboot
DIRS_TO_CLEAN= ${PKG_CACHE_DIR}/* \
	/root/.ssh \
	${INITIAL_USER_HOME_DIR}/.ssh

# PACKAGES			packages to install
PACKAGES=	firstboot-freebsd-update

SERVICES?=	sshd \
			ntpdate \
			firstboot_freebsd_update \
			cs_fetchkey \
			cs_configinit

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
.else
.if ${OSVERSION} < 1000000
IGNORE=	requires FreeBSD 10.0 or above
.endif
.endif

all:	init ${FILES} ${INITIAL_USER} ${PACKAGES} ${FIRSTBOOT_SENTINEL} clean

init:
.if defined(IGNORE)
	@${ECHO} ">>> ${IGNORE}" && exit 1
.endif

# create an initial user. give him UID 0 so that "knife cloudstack server
# create" can succeed. ${INITIAL_USER} may be removed after bootstrap but root
# itself may not.
${INITIAL_USER}:
	if ! ${GREP} -q "^${INITIAL_USER}:" /etc/passwd; then \
		${PW} useradd ${INITIAL_USER} -d ${INITIAL_USER_HOME_DIR} -u 0 -G wheel -o -m; \
	else \
		${PW} usermod ${INITIAL_USER} -d ${INITIAL_USER_HOME_DIR} -u 0 -G wheel -m; \
	fi
	${ECHO} '${INITIAL_USER_PASSWORD}' | ${PW} usermod ${INITIAL_USER} -h 0

${FILES}:	${FILES_DIR}/${.TARGET}
	${INSTALL} -o root -g wheel -d `${DIRNAME} ${.TARGET}`
	${INSTALL} -o root -g wheel ${FILES_DIR}${.TARGET} ${.TARGET}

bootstrap-pkg:
	if ! ${PKG} -N 2>/dev/null; then \
		${ENV} ASSUME_ALWAYS_YES=1 ${PKG} bootstrap ;\
	fi

${PACKAGES}:	bootstrap-pkg
	${ENV} ASSUME_ALWAYS_YES=1 ${PKG} install ${.TARGET} </dev/null

enable-services:
.for S in ${SERVICES}
	if ! ${GREP} -q -E '^${S}_enable=\"[Yy][Ee][Ss]\"' /etc/rc.conf; then \
		${ECHO} '${S}_enable="YES"' >> /etc/rc.conf; \
	fi
.endfor

${FIRSTBOOT_SENTINEL}:	enable-services
	${TOUCH} ${.TARGET}

remove-hostname:
	if ${GREP} -q '^hostname=' /etc/rc.conf; then \
		${SED} -I '' -e 's/^hostname=.*//' /etc/rc.conf; \
	fi

clean: remove-hostname
.for F in ${FILES_TO_CLEAN}
	${RM} -f ${F}
.endfor
.for D in ${DIRS_TO_CLEAN}
	${RM} -rf ${D}
.endfor

shutdown:
	${SHUTDOWN} -p now
