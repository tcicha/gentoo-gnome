# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="4"
GCONF_DEBUG="no"
GNOME2_LA_PUNT="yes"

inherit gnome2
if [[ ${PV} = 9999 ]]; then
	inherit gnome2-live
fi

DESCRIPTION="The GNOME panel"
HOMEPAGE="http://www.gnome.org/"

LICENSE="GPL-2+ FDL-1.1+ LGPL-2+"
SLOT="0"
IUSE="eds +introspection networkmanager"
if [[ ${PV} = 9999 ]]; then
	IUSE="${IUSE} doc"
	KEYWORDS=""
else
	# Odd behaviour w.r.t. panels: https://bugzilla.gnome.org/show_bug.cgi?id=631553
	KEYWORDS="~alpha ~amd64 ~arm ~ia64 ~ppc ~ppc64 ~sh ~sparc ~x86 ~x86-fbsd ~x86-interix ~amd64-linux ~x86-linux ~x86-solaris"
fi

RDEPEND=">=dev-libs/glib-2.31.14:2
	>=dev-libs/libgweather-3.5.1:2
	dev-libs/libxml2:2
	>=gnome-base/dconf-0.13.4
	>=gnome-base/gconf-2.6.1:2[introspection?]
	>=gnome-base/gnome-desktop-2.91:3
	>=gnome-base/gnome-menus-3.1.4:3
	gnome-base/gsettings-desktop-schemas
	gnome-base/librsvg:2
	>=net-libs/telepathy-glib-0.14.0
	sys-auth/polkit
	>=x11-libs/cairo-1[X]
	>=x11-libs/gdk-pixbuf-2.25.2:2
	>=x11-libs/gtk+-3.3.8:3[introspection?]
	x11-libs/libXau
	x11-libs/libICE
	x11-libs/libSM
	>=x11-libs/libXrandr-1.2
	>=x11-libs/libwnck-2.91:3
	>=x11-libs/pango-1.15.4[introspection?]

	eds? ( >=gnome-extra/evolution-data-server-3.5.3 )
	introspection? ( >=dev-libs/gobject-introspection-0.9.5 )
	networkmanager? ( >=net-misc/networkmanager-0.6.7 )"
DEPEND="${RDEPEND}
	app-text/docbook-xml-dtd:4.1.2
	>=dev-lang/perl-5
	dev-util/gtk-doc-am
	>=dev-util/intltool-0.40
	virtual/pkgconfig"
# eautoreconf needs
#	gnome-base/gnome-common

if [[ ${PV} = 9999 ]]; then
	DEPEND="${DEPEND}
		app-text/yelp-tools
		doc? ( >=dev-util/gtk-doc-1 )"
fi

pkg_setup() {
	# XXX: Make presence/telepathy-glib support optional?
	#      We can do that if we intend to support fallback-only as a setup
	G2CONF="${G2CONF}
		--disable-deprecation-flags
		--disable-static
		--disable-schemas-install
		--disable-schemas-compile
		--with-in-process-applets=clock,notification-area,wncklet
		--enable-telepathy-glib
		$(use_enable networkmanager network-manager)
		$(use_enable introspection)
		$(use_enable eds)"
	[[ ${PV} != 9999 ]] && G2CONF="${G2CONF} ITSTOOL=$(type -P true)"
	DOCS="AUTHORS ChangeLog HACKING NEWS README"
}

pkg_postinst() {
	local entries="${EROOT}etc/gconf/schemas/panel-default-setup.entries"
	local gconftool="${EROOT}usr/bin/gconftool-2"

	if [ -e "$entries" ]; then
		einfo "Setting panel gconf defaults..."

		GCONF_CONFIG_SOURCE="$("${gconftool}" --get-default-source | sed "s;:/;:${ROOT};")"

		"${gconftool}" --direct --config-source \
			"${GCONF_CONFIG_SOURCE}" --load="${entries}"
	fi

	# Calling this late so it doesn't process the GConf schemas file we already
	# took care of.
	gnome2_pkg_postinst
}