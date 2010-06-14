#!/usr/bin/perl
# an example of how to use WWW::CNic in a web environment.
# a comparable script using the whois server works substantially slower.
# $Id: search.cgi,v 1.1 2002/08/13 13:46:48 gavin Exp $
use WWW::CNic;
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
use Date::Manip;
use strict;

my $doc_title = 'Domain Search';
my @suffixes = qw(uk.com uk.net us.com eu.com de.com);

print	header() .
	start_html($doc_title),
	h1($doc_title) .
	start_form() .
	p('Enter domain: '.textfield('domain')) .
	scrolling_list(	-name		=> 'suffixes',
			-values		=> \@suffixes,
			-size		=> 5,
			-multiple	=> 'true') .
	br() .
	submit() .
	end_form();

my @suffixlist = param('suffixes');

if (param('domain') ne '' && scalar(@suffixlist) > 0) {
	print	hr() .
		h2('Results');
	my $query =	WWW::CNic->new(	command	=> 'search',
					use_ssl	=> 0,
					domain	=> param('domain'),
			);
	$query->set(suffixlist => \@suffixlist);

	my $response = $query->execute();

	if ($response->is_error) {
		print h2('Error') .
		p($response->error());
	} else {
		my @results;
		foreach my $suffix(@suffixlist) {
			if ($response->is_registered($suffix)) {
				push(@results,	li(sprintf(	"Domain %s.%s is registered to %s and expires on %s.",
								param('domain'),
								$suffix,
								$response->registrant($suffix),
								UnixDate('epoch '.$response->expiry($suffix), "%b %e %Y")
						))
				);
			} else {
				push(@results, li(sprintf("Domain %s.%s is available for registration.", param('domain'), $suffix)));
			}
		}
		print ul(\@results);
	}
}

print end_html();

exit;
