# Copyright (c) 2010 CentralNic Ltd. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
# $Id: Simple.pm,v 1.11 2010/03/31 11:58:31 gavin Exp $

package WWW::CNic::Simple;
@ISA = qw(Exporter);
@EXPORT = qw(&suffixes &check &whois);

use WWW::CNic;
use strict;

=pod

=head1 NAME

WWW::CNic::Simple - a procedural interface to WWW::CNic

=head1 SYNOPSIS

	#!/usr/bin/perl
	use WWW::CNic::Simple;

	my @suffixes = suffixes();

	my %results = check('test-domain', 'uk.com', 'uk.net');
	print "test-domain.uk.com is registered.\n" if ($results{'uk.com'} == 1);

	my %whois = whois('test-domain.uk.com');
	print "domain status: $whois{status}\n";

=head1 DESCRIPTION

This interface is intended for those who want a simplified view of the WWW::CNic library. It provides simple functions for querying the CentralNic system, making it ideal for one-liners and other tasks.

Please note that it is not possible to make domain registrations or modifications using C<WWW::CNic::Simple>.

=head1 FUNCTIONS

	my @suffixes = suffixes();

This function returns an array containing the currently live CentralNic suffixes.

	my %result = check($domain, @suffixes);

This function does an availability check on C<$domain> against the suffixes contained in C<@suffixes>. Note that if C<@suffixes> is omitted the check will run against all CentralNic domains.

The function returns a hash of the form:

	my %result = (	'uk.com'	=> 1,
			'uk.net'	=> 0,
			'eu.com'	=> 0);

where C<1> indicates that the domain is already registered.

	my %whois = whois($domain);

This function returns a hash containing whois data for the given C<$domain> This hash is of the form:

	my %whois =	{	chandle		=> {	postcode	=> 'SW6 4SN',
							country		=> 'UK',
							userid		=> 'C11480',
							fax		=> 'N/A',
							addr		=> "163 New King's Road, Fulham, London",
							name		=> 'Hostmaster',
							email		=> 'webservices@centralnic.com',
							phone		=> '020 7751 9000',
							company		=> 'CentralNic Ltd' },
				expires		=> '1001458800',
				status		=> 'Live',
				thandle		=> # as chandle above
				bhandle		=> # as chandle above
				registrant	=> 'CentralNic Ltd',
				domain		=> 'toolkit-test.uk.com',
				created		=> '1001458800'
			 };

=head1 COPYRIGHT

This module is (c) 2010 CentralNic Ltd. All rights reserved. This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

=over

=item *

http://toolkit.centralnic.com/

=item *

L<WWW::CNic>

=item *

L<WWW::CNic::Cookbook>

=back

=cut

our $HOSTNAME = 'toolkit.centralnic.com';
our $USE_SSL = 0;

sub suffixes { return WWW::CNic->new(host=>$HOSTNAME,command=>'suffixes')->execute()->suffixes() }

sub check {
	my $domain = shift;
	my @suffixes = @_;
	my $query = WWW::CNic->new(	command	=> 'search',
					domain	=> $domain,
					host	=> $HOSTNAME);
	$query->set(suffixlist => @suffixes) if (scalar @suffixes > 0);
	my $response = $query->execute();
	my %results;
	foreach my $suffix(@suffixes) {
		$results{$suffix} = ($response->is_registered($suffix) ? 1 : 0);
	}
	return %results;
}

sub whois {
	my $domain = shift;
	my %return;
	my $query = WWW::CNic->new(	command	=> 'whois',
					domain	=> $domain,
					host	=> $HOSTNAME);
	my $response = $query->execute();
	foreach my $key($response->keys()) {
		$return{$key} = $response->response($key);
	}
	return %return;
}

1;
