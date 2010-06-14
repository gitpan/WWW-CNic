#!/usr/bin/perl
# Makefile.PL for WWW::CNic
# $Id: Makefile.PL,v 1.7 2005/06/30 11:47:11 gavin Exp $
use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'			=> 'WWW::CNic',
	'VERSION_FROM'		=> 'lib/WWW/CNic.pm',
	'PREREQ_PM'		=> {
		LWP		=> 0,
		Digest::MD5	=> 0,
	},
	'AUTHOR'		=> 'CentralNic Ltd <toolkit@centralnic.com>',
	'ABSTRACT_FROM'		=> 'lib/WWW/CNic.pm',
);
