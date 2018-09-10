Name:		taos-ci
Summary:	TAOS CI Suite
Version:	1.0
Release:	1
License:	Apache-2.0
Group:		Development
BuildArch:	noarch
Distribution:	whatever
Vendor:		Samsung Electronics
Packager:	MyungJoo Ham <myungjoo.ham@samsung.com>
Source0:	%{name}-%{version}.tar.gz
Source1001:	%{name}.manifest

%description
TAOS-CI, The Per-PR CI System for TAOS Packages.
TAOS-CI is an automated project coordinator to accelerate software development
based on the GitHub webhook API. It is aimed at preventing unexpected regressions
and potential bugs due to incorrect PRs while maintaining a GitHub repository. 

%package unittest-coverage-assessment
Summary:	A unit test for a code coverage statistics
Requires:	lcov
Requires:	coreutils
Requires:	python

%description unittest-coverage-assessment
It is a python script that executes functions of source code to test a code
coverage statistics using GCOV and LCOV. LCOV is a graphical front-end
for GCC's coverage testing tool gcov. It collects gcov data for multiple source
files and creates HTML pages containing the source code annotated with coverage
information.

%prep
%setup -q
cp %{SOURCE1001} .

%build

%install
mkdir -p %{buildroot}%{_bindir}
install -m 0755 ci/gcov/unittestcoverage.py %{buildroot}%{_bindir}/

mkdir -p %{buildroot}/var/www/html/TAOS-CI
cp -arfp ./* %{buildroot}/var/www/html/TAOS-CI

%files
%manifest %{name}.manifest
/var/www/html/TAOS-CI

%files unittest-coverage-assessment
%manifest %{name}.manifest
%{_bindir}/unittestcoverage.py

%changelog
* Sat Sep 08 2018 Geunsik Lim <geunsik.lim@samsung.com>
- Added a RPM package for a server administrator that run TAOS-CI
  in RPM-based Linux distributions.
- Added the 'noarch' architecture because TAOS-CI is implemented by Script languages.

* Fri Jun 04 2018 MyungJoo Ham <myungjoo.ham@samsung.com>
- Added Unittest Coverage Assessment Tool.
