# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

JAVA_PKG_IUSE=""

inherit java-pkg-2 user git-r3

MY_PN="${PN%%-bin}"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="Web services for SciGraph, A Neo4j backed ontology store."
HOMEPAGE="https://github.com/SciGraph/SciGraph/"
EGIT_REPO_URI="https://github.com/SciGraph/SciGraph.git"

LICENSE="Apache-2.0"
SLOT="9999"
KEYWORDS="~amd64 ~x86"
IUSE="+core"

COMMON_DEP=""

RDEPEND=">=virtual/jre-1.8"
DEPEND=">=virtual/jdk-1.8
		>=dev-java/maven-bin-3.3
		app-arch/unzip"

SCIGRAPH="${PN}-${SLOT}"
SCIGRAPH_SHARE="/usr/share/${SCIGRAPH}"
SERVICES_FOLDER="/usr/share/scigraph-services"

EXECUTABLE="/usr/bin/${MY_PN}"

CORE_PN="scigraph-core"
CORE="scigraph-core-bin-${SLOT}"
CORE_SHARE="/usr/share/${CORE}"
CORE_FOLDER="/usr/share/scigraph-core"
GRAPHLOAD_EXECUTABLE="/usr/bin/scigraph-graphload"

SCIGRAPH_HOME="/var/lib/scigraph"
pkg_setup() {
	ebegin "Creating scigraph user and group"
	enewgroup scigraph
	enewuser scigraph -1 -1 "${SCIGRAPH_HOME}" scigraph
	eend $?
}

src_prepare() {
	export HASH=$(git rev-parse --short HEAD)
	sed -i "/<name>SciGraph<\/name>/{N;s/<version>.\+<\/version>/<version>${HASH}<\/version>/}" pom.xml
	sed -i "/<artifactId>scigraph<\/artifactId>/{N;s/<version>.\+<\/version>/<version>${HASH}<\/version>/}" SciGraph-analysis/pom.xml
	sed -i "/<groupId>io.scigraph<\/groupId>/{N;s/<version>.\+<\/version>/<version>${HASH}<\/version>/}" SciGraph-core/pom.xml
	sed -i "/<artifactId>scigraph<\/artifactId>/{N;s/<version>.\+<\/version>/<version>${HASH}<\/version>/}" SciGraph-entity/pom.xml
	sed -i "/<groupId>io.scigraph<\/groupId>/{N;s/<version>.\+<\/version>/<version>${HASH}<\/version>/}" SciGraph-services/pom.xml
	eapply_user
}

src_compile() {
	mvn clean -DskipTests -DskipITs install
	pushd SciGraph-services
	mvn -DskipTests -DskipITs install
}

src_install() {
	keepdir "${SCIGRAPH_HOME}"
	fowners scigraph:scigraph "${SCIGRAPH_HOME}"
	keepdir "/var/log/${MY_PN}"
	fowners scigraph:scigraph "/var/log/${MY_PN}"

	dodir ${SCIGRAPH_SHARE}
	dodir ${SERVICES_FOLDER}
	dodir "/usr/bin"

	cp -Rp "${S}/SciGraph-services/target/dependency" "${ED}${SCIGRAPH_SHARE}/lib" || die "failed to copy"
	cp "${S}/SciGraph-services/target/${MY_PN}-${HASH}.jar" "${ED}${SCIGRAPH_SHARE}/${MY_P}.jar"
	java-pkg_regjar "${ED}${SCIGRAPH_SHARE}"/lib/*.jar
	java-pkg_regjar "${ED}${SCIGRAPH_SHARE}/${MY_P}.jar"

	dosym "${SCIGRAPH_SHARE}/${MY_P}.jar" "${SERVICES_FOLDER}/${MY_PN}.jar"

	echo '#!/usr/bin/env sh' > "${ED}${EXECUTABLE}"
	echo '/usr/bin/java $@ &' >> "${ED}${EXECUTABLE}"
	echo 'echo $! > '"/var/run/${MY_PN}/${MY_PN}.pid" >> "${ED}${EXECUTABLE}"

	chmod 0755 "${ED}${EXECUTABLE}"

	if use core; then
		CORE_P="${CORE_PN}-${HASH}"

		dodir ${CORE_SHARE}
		dodir ${CORE_FOLDER}

		cp "${S}/SciGraph-core/target/${CORE_PN}-${HASH}-jar-with-dependencies.jar" "${ED}${CORE_SHARE}/${CORE_P}.jar"
		java-pkg_regjar "${ED}${CORE_SHARE}/${CORE_P}.jar"

		dosym "${CORE_SHARE}/${CORE_P}.jar" "${CORE_FOLDER}/${CORE_PN}.jar"

		echo '#!/usr/bin/env sh' > "${ED}${GRAPHLOAD_EXECUTABLE}"
		echo "/usr/bin/java -cp \"${CORE_FOLDER}/${CORE_PN}.jar\" io.scigraph.owlapi.loader.BatchOwlLoader"' $@' >> "${ED}${GRAPHLOAD_EXECUTABLE}"
		chmod 0755 "${ED}${GRAPHLOAD_EXECUTABLE}"
	fi


	newinitd "${FILESDIR}/${MY_PN}.rc" scigraph-services
	newconfd "${FILESDIR}/${MY_PN}.confd" scigraph-services
}
