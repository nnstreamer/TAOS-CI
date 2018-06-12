Name:		taos-ci
Summary:	TAOS CI Suite
Version:	0.0.1
Release:	1
Group:		Development
Packager:	MyungJoo Ham <myungjoo.ham@samsung.com>
License:	Apache-2.0
Source0:	taos-ci-%{version}.tar.gz
Source1001:	taos-ci.manifest

%description
TAOS-CI, The Per-PR CI System for TAOS Packages.

%package unittest-coverage-assessment
Summary:	Publishes lcov page
Requires:	lcov
Requires:	coreutils
Requires:	python

%description unittest-coverage-assessment
Provides lcov published pages.

%prep
%setup -q
cp %{SOURCE1001} .

%build

%install
mkdir -p %{buildroot}%{_bindir}
install -m 0755 ci/gcov/unittestcoverage.py %{buildroot}%{_bindir}/

%files unittest-coverage-assessment
%manifest taos-ci.manifest
%{_bindir}/unittestcoverage.py

%changelog
* Fri Jun 04 2018 MyungJoo Ham <myungjoo.ham@samsung.com>
- Added Unittest Coverage Assessment Tool.
