# $Id:
%define VERSION {{VERSION}}

Name:			cnic-WWW-CNic
Summary:		The CentralNic WWW::CNic Perl Module
Version:		%{VERSION}
Release:		1%{dist}
Epoch:			0
Group:			Libraries
License:		GPLv2
Source:			%{name}-%{version}.tar.gz
Packager:		Achim Regendoerp <achim@centralnic.com>
Vendor:			http://www.centralnic.com/
BuildRoot:		%{_tmppath}/%(whoami)-%{name}-%{VERSION}
AutoReq:		no
BuildArch:		noarch
Requires:		perl-Date-Manip

%description
The CentralNic WWW:CNic Perl Module

%prep

%setup

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/export/cnic/WWW-CNic
cp -Rp * %{buildroot}/export/cnic/WWW-CNic
rm -f %{buildroot}/export/cnic/WWW-CNic/%{name}.spec
mkdir -p %{buildroot}/etc/cron.daily
cat > %{buildroot}/etc/cron.daily/%{name} << EBD
#!/bin/sh
cd /export/cnic/WWW-CNic
perl Makefile.pl
END

%post
if [ "$1" = "1" ] ; then
	cd /export/cnic/WWW-CNic
	perl Makefile.PL
fi

%clean
rm -rf %{buildroot}

%files
%attr(0755, root, root) /etc/cron.daily/%{name}
%attr(0755, root, root) %dir /export/cnic/WWW-CNic
%attr(0644, root, root) /export/cnic/WWW-CNic/*

%changelog
*Tue Aug 17 2010 Achim Regendoerp <achim@centralnic.com> - 20100817
- Added dist to the Release field
*Tue Jun 29 2010 Achim Regendoerp <achim@centralnic.com> - 20100629
- Replaced END with fi in the post routine
- Replaced .pl with .PL in the post routine
*Tue Jun 22 2010 Achim Regendoerp <achim@centralnic.com> - 20100622
- Initial spec file
- Adjusted name capitalization
- Added imssing /* in the attributes
