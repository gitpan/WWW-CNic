#!/usr/bin/perl
# Makefile.PL for WWW::CNic
# $Id: Makefile.PL,v 1.9 2011/05/13 13:31:49 gavin Exp $
use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'			=> 'WWW::CNic',
	'VERSION_FROM'		=> 'lib/WWW/CNic.pm',
	'PREREQ_PM'		=> {
		LWP		=> 0,
		Digest::MD5	=> 0,
		Crypt::SSLeay	=> 0,
	},
	'AUTHOR'		=> 'CentralNic Ltd <toolkit@centralnic.com>',
	'ABSTRACT_FROM'		=> 'lib/WWW/CNic.pm',
);
