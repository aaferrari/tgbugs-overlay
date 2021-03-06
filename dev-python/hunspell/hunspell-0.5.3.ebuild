# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( pypy3 python3_{4,5,6} )
inherit distutils-r1

DESCRIPTION="Module for the Hunspell spellchecker engine"
HOMEPAGE="https://github.com/blatinier/pyhunspell"
SRC_URI="mirror://pypi/${P:0:1}/${PN}/${P}.tar.gz"

LICENSE="LGPLv3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND="app-text/hunspell"
RDEPEND="${DEPEND}"

RESTRICT="test"
