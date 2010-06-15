# Copyright (c) 2010 CentralNic Ltd. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
# $Id: CNic.pm,v 1.65 2010/06/15 10:47:31 gavin Exp $
package WWW::CNic;
use LWP;
use LWP::ConnCache;
use HTTP::Request::Common;
use URI::Escape;
use Digest::MD5 qw(md5_hex);
use vars qw($VERSION $CONNECTION_CACHE);
use strict;

our $VERSION = '0.35';

=pod

=head1 NAME

WWW::CNic - a web-based API for the CentralNic domain registry system.

=head1 SYNOPSIS

	use WWW::CNic;

	my @suffixlist = qw(uk.com us.com de.com eu.com);

	my $query = WWW::CNic->new(command => 'search', 'domain' => 'example');

	$query->set(suffixlist => \@suffixlist);

	my $response = $query->execute;

	if ($response->is_error) {
		printf("Error: %s\n", $response->error);

	} else {
		foreach my $suffix(@suffixlist) {
			if ($response->is_registered) {
				printf("Domain %s.%s is registered to %s\n", $domain, $suffix, $response->registrant($suffix));

			} else {
				printf("Domain %s.%s is available for registration\n", $domain, $suffix);

			}
		}
	}

=head1 DESCRIPTION

C<WWW::CNic> provides a powerful object-oriented Perl interface to the CentralNic Toolkit system.

The design of C<WWW::CNic> is inspired greatly by C<LWP>, which is a prerequisite. Essentially, making a transaction requires building a I<request> object, which is then executed and returns a I<response> object. While each transaction type (search, registration, modification...) requires a different set of data to be sent by the client, all the response objects have common properties, inherited from the C<WWW::CNic::Response> base class, with just a few extra methods for accessing specific information.

=head1 INSTALLATION

Installing C<WWW::CNic> is as simple as:

	cd /usr/src
	wget http://toolkit.centralnic.com/dist/WWW-CNic-x.xx.tar.gz
	tar zxvf WWW-CNic-x.xx.tar.gz
	cd WWW-CNic-x.xx
	perl Makefile.PL
	make
	make install

=head1 PREREQUISITES

=over

=item 1

C<LWP> - the WWW Library for Perl. This in turn requires C<libnet>, C<URI> and C<HTML::Parser>.

=item 2

An SSL toolkit (C<Crypt::SSLeay>, C<IO::Socket::SSL>) for doing HTTPS transactions.

=item 4

C<Digest::MD5> is needed for hashing passwords.

=back

=head1 USAGE

Consult L<WWW::CNic::Cookbook> for detailed information on using WWW::CNic.

=head1 CONSTRUCTOR

	my $query = WWW::CNic->new( [OPTIONS] );

The constructor for this class accepts the following options:

=over

=item 1

C<username> - only needed for doing domain registrations and modifications. This is the User ID of your Registrar Handle.

=item 1

C<password> - the password for your Registrar Handle.

=item 3

C<command> - required for every transaction. This is a scalar containing the command name. The list of allowed commands is always growing, you should consult the Toolkit website for a complete list.

=item 4

C<domain> - only needed for domain registrations, modifications and other commands that act upon domains.

=item 5

C<host> - allows you to use to a non-standard host. This is mainly useful for client debugging purposes.

=item 6

C<test> - when set to C<1>, this causes any domain registration and modification transactions to use the test database. Again, this is useful for testing and debugging.

=item 7

C<keep_alive> - by default, WWW::CNic will use C<LWP::ConnCache> to cache server connections. Setting C<keep_alive> to C<0> or C<undef> will turn this off.

=back

=head1 METHODS

	$query->set( NAME => VALUE );

This method allows you to set any number of parameters prior to executing the query. The specifics of what parameters are required for what type of transaction is explained in L<WWW::CNic::Cookbook>.

	my $response = $query->execute();

This method makes the transaction and returns an instance of a C<WWW::CNic::Response> child class.

=head1 COPYRIGHT

This module is (c) 2010 CentralNic Ltd. All rights reserved. This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

=over

=item *

http://toolkit.centralnic.com/

=item *

L<WWW::CNic::Cookbook>

=item *

L<WWW::CNic::Simple>

=back

=cut

BEGIN {
	our $CONNECTION_CACHE = LWP::ConnCache->new;
}

sub new {
	# shift off the package name:
	my $package = shift;
	# convert to a hash:
	my %args = @_;
	# initialise the object:
	my $self = {
		_test	=> 0,
	};
	foreach my $key(keys %args) {
		$self->{"_$key"} = $args{$key};
	}
	# create an LWP useragent:
	$self->{_agent} = LWP::UserAgent->new();
	$self->{_agent}->timeout($self->{_timeout} || 10);
	$self->{_agent}->agent(sprintf('%s/%s (LWP %s, Perl %vd, %s)', $package, $VERSION, $LWP::VERSION, $^V, ucfirst($^O)));
	$self->{_agent}->conn_cache($CONNECTION_CACHE) unless (!$self->{_keep_alive});
	$self->{_base} = 'http://' . (defined($self->{_host}) ? $self->{_host} : 'toolkit.centralnic.com').'/srv';
	# bless into this package:
	bless($self, $package);
	return $self;
}

sub set {
	my $self = shift;
	my %params = @_;
	foreach my $name(keys %params) {
		$self->{_params}->{$name} = $params{$name};
	}
	return;
}

sub execute {
	my $self = shift;
	SWITCH: {
		# No SSL/authentication required
		$self->{_command} eq 'whois'			&& return $self->_whois();
		$self->{_command} eq 'search'			&& return $self->_search();
		$self->{_command} eq 'suffixes'			&& return $self->_suffixes();
		# SSL/authentication required
		$self->{_command} eq 'create_handle'		&& return $self->_create_handle();
		$self->{_command} eq 'handle_info'		&& return $self->_handle_info();
		$self->{_command} eq 'register'			&& return $self->_register();
		$self->{_command} eq 'register_idn'		&& return $self->_register(idn => 1);
		$self->{_command} eq 'register_atgb'		&& return $self->_register_atgb();
		$self->{_command} eq 'modify'			&& return $self->_modify();
		$self->{_command} eq 'modify_handle'		&& return $self->_modify_handle();
		$self->{_command} eq 'renewals'			&& return $self->_upcoming_renewals();
		$self->{_command} eq 'list_domains'		&& return $self->_list_domains();
		$self->{_command} eq 'issue_renewals'		&& return $self->_issue_renewals();
		$self->{_command} eq 'get_pricing'		&& return $self->_get_pricing();
		$self->{_command} eq 'delete'			&& return $self->_delete_domain();
		$self->{_command} eq 'decline'			&& return $self->_decline_domain();
		$self->{_command} eq 'undecline'		&& return $self->_undecline_domain();
		$self->{_command} eq 'start_transfer'		&& return $self->_start_transfer();
		$self->{_command} eq 'check_transfer'		&& return $self->_check_transfer();
		$self->{_command} eq 'cancel_transfer'		&& return $self->_cancel_transfer();
		$self->{_command} eq 'reactivate'		&& return $self->_reactivate_domain();
		$self->{_command} eq 'push_domain'		&& return $self->_push_domain();
		$self->{_command} eq 'auth_info'		&& return $self->_auth_info();
		$self->{_command} eq 'poll_transfers'		&& return $self->_poll_transfers();
		$self->{_command} eq 'approve_transfer'		&& return $self->_approve_transfer();
		$self->{_command} eq 'reject_transfer'		&& return $self->_reject_transfer();
		$self->{_command} eq 'list_outstanding_domains'	&& return $self->_list_outstanding_domains();
		$self->{_command} eq 'submit_payment_batch'	&& return $self->_submit_payment_batch();
		$self->{_command} eq 'registrant_transfer'	&& return $self->_registrant_transfer();
		$self->{_command} eq 'lock_domain'		&& return $self->_lock_domain();
		$self->{_command} eq 'unlock_domain'		&& return $self->_unlock_domain();
		die("Invalid command '$self->{_command}'");
	}
}

#
# No SSL/authentication required
#

sub _whois {
	my $self = shift;
	$self->{_base} =~ s/^https:/http:/g;	# No SSL required
	die("Missing domain name") if $self->{_domain} eq '';
	$self->{_response}->{_raw} = $self->_get(GET("$self->{_base}/wwwhois?domain=$self->{_domain}&test=$self->{_test}"));
	use WWW::CNic::Response::Whois;
	return WWW::CNic::Response::Whois->new($self->{_response}->{_raw});
}

sub _search {
	my $self = shift;
	$self->{_base} =~ s/^https:/http:/g;	# No SSL required
	die("Missing domain name") if $self->{_domain} eq '';
	my $url = "$self->{_base}/search?domain=$self->{_domain}";
	if (defined(@{$self->{_params}->{suffixlist}})) {
		$url .= '&suffixlist='.join(',', @{$self->{_params}->{suffixlist}}).'&test='.$self->{_test};
	}
	$self->{_response}->{_raw} = $self->_get(GET($url));
	use WWW::CNic::Response::Search;
	return WWW::CNic::Response::Search->new($self->{_response}->{_raw});
}

sub _suffixes {
	my $self = shift;
	$self->{_base} =~ s/^https:/http:/g;	# No SSL required
	$self->{_response}->{_raw} = $self->_get(GET("$self->{_base}/suffixes?test=$self->{_test}"));
	use WWW::CNic::Response::Suffixes;
	return WWW::CNic::Response::Suffixes->new($self->{_response}->{_raw});
}

#
# SSL/authentication required
#

sub _create_handle {
	my $self = shift;
	$self->{_base} =~ s/^http:/https:/g;	# Requires SSL
	die("Invalid type for handle") unless (ref($self->{_params}->{handle}) eq 'HASH');
	my %params =  (
		user		=> $self->{_username},
		password	=> $self->_crypt_md5($self->{_password}),
		test		=> $self->{_test},
		visible		=> ($self->{_params}->{visible} == 0 ? 0 : 1),
	);
	if (defined($self->{_params}->{handle}->{street1})) {
		$params{name}		= $self->{_params}->{handle}->{name};
		$params{company}	= $self->{_params}->{handle}->{company};
		$params{street1}	= $self->{_params}->{handle}->{street1};
		$params{street2}	= $self->{_params}->{handle}->{street2};
		$params{street3}	= $self->{_params}->{handle}->{street3};
		$params{city}		= $self->{_params}->{handle}->{city};
		$params{sp}		= $self->{_params}->{handle}->{sp};
		$params{postcode}	= $self->{_params}->{handle}->{postcode};
		$params{country}	= $self->{_params}->{handle}->{country};
		$params{phone}		= $self->{_params}->{handle}->{phone};
		$params{fax}		= $self->{_params}->{handle}->{fax};
		$params{email}		= $self->{_params}->{handle}->{email};

	} else {
		$params{handle} = $self->_build_handle_string($self->{_params}->{handle});

	}

	my $req = HTTP::Request->new(POST => "$self->{_base}/create_handle");
	$req->content_type('application/x-www-form-urlencoded');
	my @content;
	foreach my $name(keys %params) {
		my $pair;
		if ($name eq 'dns[]') {
			$pair = "$name=$params{$name}";
		} else {
			$pair = uri_escape($name).'='.uri_escape($params{$name});
		}
		push(@content, $pair);
	}
	$req->content(join('&', @content));
	$self->{_response}->{_raw} = $self->_get($req);
	use WWW::CNic::Response::CreateHandle;
	return WWW::CNic::Response::CreateHandle->new($self->{_response}->{_raw});
}

sub _handle_info {
	my $self = shift;
	$self->{_base} =~ s/^http:/https:/g;	# Requires SSL
	my %params =  (
		user		=> $self->{_username},
		password	=> $self->_crypt_md5($self->{_password}),
		test		=> $self->{_test},
		handle		=> $self->{_params}->{handle},
	);
	my $req = POST("$self->{_base}/handle_info", \%params);
	$self->{_response}->{_raw} = $self->_get($req);
	use WWW::CNic::Response::HandleInfo;
	return WWW::CNic::Response::HandleInfo->new($self->{_response}->{_raw});
}

sub _register {
	my $self = shift;
	$self->{_base} =~ s/^http:/https:/g;	# Requires SSL
	my %args = @_;
	die("Missing domain name") if $self->{_domain} eq '';
	die("Missing username") if $self->{_username} eq '';
	die("Missing password") if $self->{_password} eq '';
	my ($domain, $suffix) = split(/\./, $self->{_domain}, 2);
	my $chandle = (ref($self->{_params}->{chandle}) eq 'HASH' ? $self->_build_handle_string($self->{_params}->{chandle}) : $self->{_params}->{chandle});
	my $thandle = (ref($self->{_params}->{thandle}) eq 'HASH' ? $self->_build_handle_string($self->{_params}->{thandle}) : $self->{_params}->{thandle});
	my $dns;
	my $dns_param = 'dns[]';
	if (ref($self->{_params}->{dns}) eq 'ARRAY') {
		$dns = join('&dns[]=', @{$self->{_params}->{dns}});
	} elsif (ref($self->{_params}->{dns}) eq 'HASH') {
		my @entries;
		foreach my $name(keys %{$self->{_params}->{dns}}) {
			push(@entries, $name.'::'.${$self->{_params}->{dns}}->{$name});
		}
		$dns = join('&dns[]=', @entries);
	} elsif ($dns == 'defaults') {
		$dns = 'defaults';
		$dns_param = 'dns'
	}
	my %params = (
		user		=> $self->{_username},
		password	=> $self->_crypt_md5($self->{_password}),
		test		=> $self->{_test},
		domain		=> $domain,
		suffix		=> $suffix,
		registrant	=> $self->{_params}->{registrant},
		chandle		=> $chandle,
		thandle		=> $thandle,
		period		=> $self->{_params}->{period},
		$dns_param	=> $dns,
	);

	$params{ahandle} = $self->{_params}->{ahandle} if (defined($self->{_params}->{ahandle}));
	$params{bhandle} = $self->{_params}->{bhandle} if (defined($self->{_params}->{bhandle}));

	$params{url} = $self->{_params}->{url} if ($self->{_params}->{url} ne '');

	my $POST_URL = $self->{_base}.'/'.($args{idn} == 1 ? 'register_idn' : 'register');
	my $req = HTTP::Request->new(POST => $POST_URL);
	$req->content_type('application/x-www-form-urlencoded');
	my @content;
	foreach my $name(keys %params) {
		my $pair;
		if ($name eq 'dns[]') {
			$pair = "$name=$params{$name}";
		} else {
			$pair = uri_escape($name).'='.uri_escape($params{$name});
		}
		push(@content, $pair);
	}
	$req->content(join('&', @content));
	$self->{_response}->{_raw} = $self->_get($req);
	use WWW::CNic::Response::Register;
	return WWW::CNic::Response::Register->new($self->{_response}->{_raw});
}

sub _register_atgb {
	my $self = shift;
	$self->{_base} =~ s/^http:/https:/g;	# Requires SSL
	die("Missing domain name") if $self->{_domain} eq '';
	die("Missing username") if $self->{_username} eq '';
	die("Missing password") if $self->{_password} eq '';
	my ($fname, $sname, $suffix) = split(/\./, $self->{_domain}, 3);
	my %params = 	(
				user		=> $self->{_username},
				password	=> $self->_crypt_md5($self->{_password}),
				test		=> $self->{_test},
				fname		=> $fname,
				sname		=> $sname,
				suffix		=> $suffix,
				registrant	=> $self->{_params}->{registrant},
				handle		=> $self->_build_handle_string($self->{_params}->{handle}),
				user_password	=> $self->{_params}->{user_password},
				send_email	=> $self->{_params}->{send_email}
			);
	my $req = HTTP::Request->new(POST => "$self->{_base}/register_atgb");
	$req->content_type('application/x-www-form-urlencoded');
	my @content;
	foreach my $name(keys %params) {
		my $pair = uri_escape($name).'='.uri_escape($params{$name});
		push(@content, $pair);
	}
	$req->content(join('&', @content));
	$self->{_response}->{_raw} = $self->_get($req);
	use WWW::CNic::Response::Register::AtGB;
	return WWW::CNic::Response::Register::AtGB->new($self->{_response}->{_raw});
}

sub _modify {
	my $self = shift;
	$self->{_base} =~ s/^http:/https:/g;	# Requires SSL
	die("Missing domain name") if $self->{_domain} eq '';
	die("Missing username") if $self->{_username} eq '';
	die("Missing password") if $self->{_password} eq '';
	my %params = (
		user		=> $self->{_username},
		password	=> $self->_crypt_md5($self->{_password}),
		test		=> $self->{_test},
		domain		=> $self->{_domain},
	);

	$params{url} = $self->{_params}->{url} if ($self->{_params}->{url} ne '');

	if (defined($self->{_params}->{chandle})) {
		$params{chandle} = (ref($self->{_params}->{chandle}) eq 'HASH' ? $self->_build_handle_string($self->{_params}->{chandle}) : $self->{_params}->{chandle});
	}
	if (defined($self->{_params}->{ahandle})) {
		$params{ahandle} = $self->{_params}->{ahandle};
	}
	if (defined($self->{_params}->{thandle})) {
		$params{thandle} = (ref($self->{_params}->{thandle}) eq 'HASH' ? $self->_build_handle_string($self->{_params}->{thandle}) : $self->{_params}->{thandle});
	}
	if (defined($self->{_params}->{bhandle})) {
		$params{bhandle} = $self->{_params}->{bhandle};
	}
	$params{ttl} = int($self->{_params}->{ttl}) if (defined($self->{_params}->{ttl}));

	if (defined($self->{_params}->{dns})) {
		my @dns;
		if ($self->{_params}->{dns}->{drop} eq 'all') {
			push(@dns, "drop:all");

		} elsif (defined(@{$self->{_params}->{dns}->{drop}})) {
			foreach my $name(@{$self->{_params}->{dns}->{drop}}) {
				push(@dns, "drop:$name");
			}
		}
		if (defined(@{$self->{_params}->{dns}->{add}})) {
			foreach my $name(@{$self->{_params}->{dns}->{add}}) {
				push(@dns, "add:$name");
			}
		}
		$params{'dns[]'} = join('&dns[]=', @dns);
	}
	my $req = HTTP::Request->new( POST => "$self->{_base}/modify");
	$req->content_type('application/x-www-form-urlencoded');
	my @content;
	foreach my $name(keys %params) {
		my $pair;
		if ($name eq 'dns[]') {
			$pair = "$name=$params{$name}";
		} else {
			$pair = uri_escape($name).'='.uri_escape($params{$name});
		}
		push(@content, $pair);
	}
	$req->content(join('&', @content));
	$self->{_response}->{_raw} = $self->_get($req);
	use WWW::CNic::Response::Modify;
	return WWW::CNic::Response::Modify->new($self->{_response}->{_raw});
}

sub _modify_handle {
	my $self = shift;
	$self->{_base} =~ s/^http:/https:/g;	# Requires SSL
	die("Missing username") if $self->{_username} eq '';
	die("Missing password") if $self->{_password} eq '';
	die("Missing handle ID") if ($self->{_params}->{handle} eq '');

	my %params = (
		user		=> $self->{_username},
		password	=> $self->_crypt_md5($self->{_password}),
		test		=> $self->{_test},
	);
	foreach my $key (keys(%{$self->{_params}})) {
		$params{$key} = $self->{_params}->{$key};
	}

	my $req = HTTP::Request->new( POST => "$self->{_base}/modify_handle");
	$req->content_type('application/x-www-form-urlencoded');
	my @content;

	foreach my $name(keys %params) {
		push(@content, uri_escape($name).'='.uri_escape($params{$name}));
	}
	$req->content(join('&', @content));

	$self->{_response}->{_raw} = $self->_get($req);
	use WWW::CNic::Response::ModifyHandle;
	return WWW::CNic::Response::ModifyHandle->new($self->{_response}->{_raw});
}

sub _upcoming_renewals {
	my $self = shift;
	$self->{_base} =~ s/^http:/https:/g;	# Requires SSL
	die("Missing username") if $self->{_username} eq '';
	die("Missing password") if $self->{_password} eq '';

	my %params = (
		user		=> $self->{_username},
		password	=> $self->_crypt_md5($self->{_password}),
		test		=> $self->{_test},
		months		=> $self->{_months},
	);

	foreach my $key (keys(%{$self->{_params}})) {
		$params{$key} = $self->{_params}->{$key};
	}

	my $req = POST("$self->{_base}/upcoming_renewals", \%params);
	$self->{_response}->{_raw} = $self->_get($req);
	use WWW::CNic::Response::Renewals;
	return WWW::CNic::Response::Renewals->new($self->{_response}->{_raw});
}

sub _list_domains {
	my $self = shift;
	$self->{_base} =~ s/^http:/https:/g;	# Requires SSL
	die("Missing username") if $self->{_username} eq '';
	die("Missing password") if $self->{_password} eq '';
	my %params = 	(
				user		=> $self->{_username},
				password	=> $self->_crypt_md5($self->{_password}),
				test		=> $self->{_test},
				offset		=> $self->{_params}->{offset},
				length		=> $self->{_params}->{length},
				orderby		=> $self->{_params}->{orderby},
			);
	my $req = POST("$self->{_base}/list_domains", \%params);
	$self->{_response}->{_raw} = $self->_get($req);
	use WWW::CNic::Response::DomainList;
	return WWW::CNic::Response::DomainList->new($self->{_response}->{_raw});
}

sub _issue_renewals {
	my $self = shift;
	$self->{_base} =~ s/^http:/https:/g;	# Requires SSL
	die("Missing username") if $self->{_username} eq '';
	die("Missing password") if $self->{_password} eq '';
	die("Missing domains") if scalar(@{$self->{_params}->{domains}}) < 1;
	my %params = 	(
				user		=> $self->{_username},
				password	=> $self->_crypt_md5($self->{_password}),
				test		=> $self->{_test},
				period		=> $self->{_params}->{period},
				immediate	=> $self->{_params}->{immediate},
			);
	my $i = 0;
	foreach my $domain(@{$self->{_params}->{domains}}) {
		$params{"domains[$i]"} = $domain;
		$i++;
	}
	my $req = POST("$self->{_base}/issue_renewals", \%params);
	$self->{_response}->{_raw} = $self->_get($req);
	use WWW::CNic::Response::IssueRenewals;
	return WWW::CNic::Response::IssueRenewals->new($self->{_response}->{_raw});
}

sub _get_pricing {
	my $self = shift;
	$self->{_base} =~ s/^http:/https:/g;	# Requires SSL
	die("Missing username") if $self->{_username} eq '';
	die("Missing password") if $self->{_password} eq '';
	my %params = (
				user		=> $self->{_username},
				password	=> $self->_crypt_md5($self->{_password}),
				test		=> $self->{_test},
				type		=> $self->{_type},
	);
	my $url = "$self->{_base}/get_pricing";
	my $req = POST($url, \%params);
	$self->{_response}->{_raw} = $self->_get($req);
	use WWW::CNic::Response::GetPricing;
	return WWW::CNic::Response::GetPricing->new($self->{_response}->{_raw});
}

sub _delete_domain {
	my $self = shift;
	$self->{_base} =~ s/^http:/https:/g;	# Requires SSL
	die("Missing username") if $self->{_username} eq '';
	die("Missing password") if $self->{_password} eq '';
	die("Missing domain")	if $self->{_domain}   eq '';
	my %params = (
				user		=> $self->{_username},
				password	=> $self->_crypt_md5($self->{_password}),
				test		=> $self->{_test},
				domain		=> $self->{_domain},
				reason		=> $self->{_reason} || $self->{_params}->{reason},
				immediate	=> $self->{_immediate},
	);
	die("Missing reason") if ($params{reason}  eq '');
	$params{immediate} = 1 if ($self->{_params}->{immediate});
	my $url = "$self->{_base}/delete_domain";
	my $req = POST($url, \%params);
	$self->{_response}->{_raw} = $self->_get($req);
	use WWW::CNic::Response::DeleteDomain;
	return WWW::CNic::Response::DeleteDomain->new($self->{_response}->{_raw});
}

sub _decline_domain {
	my $self = shift;
	$self->{_base} =~ s/^http:/https:/g;	# Requires SSL
	die("Missing username") if $self->{_username} eq '';
	die("Missing password") if $self->{_password} eq '';
	die("Missing domain")	if $self->{_domain}   eq '';
	my %params = (
				user		=> $self->{_username},
				password	=> $self->_crypt_md5($self->{_password}),
				test		=> $self->{_test},
				domain		=> $self->{_domain},
	);
	my $url = "$self->{_base}/decline_domain";
	my $req = POST($url, \%params);
	$self->{_response}->{_raw} = $self->_get($req);
	use WWW::CNic::Response::DeclineDomain;
	return WWW::CNic::Response::DeclineDomain->new($self->{_response}->{_raw});
}

sub _undecline_domain {
	my $self = shift;
	$self->{_base} =~ s/^http:/https:/g;	# Requires SSL
	die("Missing username") if $self->{_username} eq '';
	die("Missing password") if $self->{_password} eq '';
	die("Missing domain")	if $self->{_domain}   eq '';
	my %params = (
				user		=> $self->{_username},
				password	=> $self->_crypt_md5($self->{_password}),
				test		=> $self->{_test},
				domain		=> $self->{_domain},
	);
	my $url = "$self->{_base}/undecline_domain";
	my $req = POST($url, \%params);
	$self->{_response}->{_raw} = $self->_get($req);
	use WWW::CNic::Response::UnDeclineDomain;
	return WWW::CNic::Response::UnDeclineDomain->new($self->{_response}->{_raw});
}

sub _start_transfer {
	my $self = shift;
	$self->{_base} =~ s/^http:/https:/g;	# Requires SSL
	die("Missing username") if $self->{_username} eq '';
	die("Missing password") if $self->{_password} eq '';
	die("Missing domains") if scalar(@{$self->{_params}->{domains}}) < 1;
	my %params = (
				user		=> $self->{_username},
				password	=> $self->_crypt_md5($self->{_password}),
				test		=> $self->{_test},
	);
	my $i = 0;
	foreach my $domain(@{$self->{_params}->{domains}}) {
		$params{"domains[$i]"} = $domain;
		$i++;
	}
	$i = 0;
	foreach my $info(@{$self->{_params}->{authinfo}}) {
		$params{"authinfo[$i]"} = $info;
		$i++;
	}
	my $url = "$self->{_base}/start_transfer";
	my $req = POST($url, \%params);
	$self->{_response}->{_raw} = $self->_get($req);
	use WWW::CNic::Response::StartTransfer;
	return WWW::CNic::Response::StartTransfer->new($self->{_response}->{_raw});
}

sub _check_transfer {
	my $self = shift;
	$self->{_base} =~ s/^http:/https:/g;	# Requires SSL
	die("Missing username") if $self->{_username} eq '';
	die("Missing password") if $self->{_password} eq '';
	die("Missing domain")	if $self->{_domain}   eq '';
	my %params = (
				user		=> $self->{_username},
				password	=> $self->_crypt_md5($self->{_password}),
				test		=> $self->{_test},
				domain		=> $self->{_domain},
	);
	my $url = "$self->{_base}/check_transfer";
	my $req = POST($url, \%params);
	$self->{_response}->{_raw} = $self->_get($req);
	use WWW::CNic::Response::CheckTransfer;
	return WWW::CNic::Response::CheckTransfer->new($self->{_response}->{_raw});
}

sub _cancel_transfer {
	my $self = shift;
	$self->{_base} =~ s/^http:/https:/g;	# Requires SSL
	die("Missing username") if $self->{_username} eq '';
	die("Missing password") if $self->{_password} eq '';
	die("Missing domain")	if $self->{_domain}   eq '';
	my %params = (
				user		=> $self->{_username},
				password	=> $self->_crypt_md5($self->{_password}),
				test		=> $self->{_test},
				domain		=> $self->{_domain},
	);
	my $url = "$self->{_base}/cancel_transfer";
	my $req = POST($url, \%params);
	$self->{_response}->{_raw} = $self->_get($req);
	use WWW::CNic::Response::CancelTransfer;
	return WWW::CNic::Response::CancelTransfer->new($self->{_response}->{_raw});
}

sub _reactivate_domain {
	my $self = shift;
	$self->{_base} =~ s/^http:/https:/g;	# Requires SSL
	die("Missing username") if $self->{_username} eq '';
	die("Missing password") if $self->{_password} eq '';
	die("Missing domain")	if $self->{_domain}   eq '';
	my %params = (
				user		=> $self->{_username},
				password	=> $self->_crypt_md5($self->{_password}),
				test		=> $self->{_test},
				domain		=> $self->{_domain},
	);
	$params{email} = $self->{_email} if (defined($self->{_email}));
	$params{period} = $self->{_period} if (defined($self->{_period}));
	my $url = "$self->{_base}/reactivation_request";
	my $req = POST($url, \%params);
	$self->{_response}->{_raw} = $self->_get($req);
	use WWW::CNic::Response::ReactivateDomain;
	return WWW::CNic::Response::ReactivateDomain->new($self->{_response}->{_raw});
}

sub _push_domain {
	my $self = shift;
	$self->{_base} =~ s/^http:/https:/g;	# Requires SSL
	die("Missing username") if $self->{_username} eq '';
	die("Missing password") if $self->{_password} eq '';
	die("Missing domain")	if $self->{_domain}   eq '';
	die("Missing handle")	if $self->{_handle}   eq '';
	my %params = (
				user		=> $self->{_username},
				password	=> $self->_crypt_md5($self->{_password}),
				test		=> $self->{_test},
				domain		=> $self->{_domain},
				handle		=> $self->{_handle},
	);
	my $url = "$self->{_base}/push_domain";
	my $req = POST($url, \%params);
	$self->{_response}->{_raw} = $self->_get($req);
	use WWW::CNic::Response::PushDomain;
	return WWW::CNic::Response::PushDomain->new($self->{_response}->{_raw});
}

sub _auth_info {
	my $self = shift;
	$self->{_base} =~ s/^http:/https:/g;	# Requires SSL
	die("Missing username") if $self->{_username} eq '';
	die("Missing password") if $self->{_password} eq '';
	die("Missing domain")	if $self->{_domain}   eq '';
	my %params = (
				user		=> $self->{_username},
				password	=> $self->_crypt_md5($self->{_password}),
				test		=> $self->{_test},
				domain		=> $self->{_domain},
	);
	my $url = "$self->{_base}/auth_info";
	my $req = POST($url, \%params);
	$self->{_response}->{_raw} = $self->_get($req);
	use WWW::CNic::Response::AuthInfo;
	return WWW::CNic::Response::AuthInfo->new($self->{_response}->{_raw});
}

sub _poll_transfers {
	my $self = shift;
	$self->{_base} =~ s/^http:/https:/g;	# Requires SSL
	die("Missing username") if $self->{_username} eq '';
	die("Missing password") if $self->{_password} eq '';
	my %params = (
				user		=> $self->{_username},
				password	=> $self->_crypt_md5($self->{_password}),
				test		=> $self->{_test},
	);
	my $url = "$self->{_base}/poll_transfers";
	my $req = POST($url, \%params);
	$self->{_response}->{_raw} = $self->_get($req);
	use WWW::CNic::Response::PollTransfers;
	return WWW::CNic::Response::PollTransfers->new($self->{_response}->{_raw});
}

sub _approve_transfer {
	my $self = shift;
	$self->{_base} =~ s/^http:/https:/g;	# Requires SSL
	die("Missing username") if $self->{_username} eq '';
	die("Missing password") if $self->{_password} eq '';
	die("Missing domain")	if $self->{_domain}   eq '';
	my %params = (
				user		=> $self->{_username},
				password	=> $self->_crypt_md5($self->{_password}),
				test		=> $self->{_test},
				domain		=> $self->{_domain},
	);
	my $url = "$self->{_base}/approve_transfer";
	my $req = POST($url, \%params);
	$self->{_response}->{_raw} = $self->_get($req);
	use WWW::CNic::Response::ApproveTransfer;
	return WWW::CNic::Response::ApproveTransfer->new($self->{_response}->{_raw});
}

sub _reject_transfer {
	my $self = shift;
	$self->{_base} =~ s/^http:/https:/g;	# Requires SSL
	die("Missing username") if $self->{_username} eq '';
	die("Missing password") if $self->{_password} eq '';
	die("Missing domain")	if $self->{_domain}   eq '';
	my %params = (
				user		=> $self->{_username},
				password	=> $self->_crypt_md5($self->{_password}),
				test		=> $self->{_test},
				domain		=> $self->{_domain},
	);
	my $url = "$self->{_base}/reject_transfer";
	my $req = POST($url, \%params);
	$self->{_response}->{_raw} = $self->_get($req);
	use WWW::CNic::Response::RejectTransfer;
	return WWW::CNic::Response::RejectTransfer->new($self->{_response}->{_raw});
}

sub _registrant_transfer {
	my $self = shift;
	$self->{_base} =~ s/^http:/https:/g;	# Requires SSL
	die ("Missing username") if $self->{_username} eq '';
	die ("Missing password") if $self->{_password} eq '';
	die ("Missing domain") if ($self->{_params}->{domain} eq '');
	die ("Missing registrant") if ($self->{_params}->{registrant} eq '');

	my %params = (
				user		=> $self->{_username},
				password	=> $self->_crypt_md5($self->{_password}),
				test		=> $self->{_test},
	);

    foreach my $key (keys(%{$self->{_params}})) {
		$params{$key} = $self->{_params}->{$key};
	}

	my $url = "$self->{_base}/registrant_transfer";
	my $req = POST($url, \%params);
	$self->{_response}->{_raw} = $self->_get($req);
	use WWW::CNic::Response::RegistrantTransfer;
	return WWW::CNic::Response::RegistrantTransfer->new($self->{_response}->{_raw});
}

sub _list_outstanding_domains {
	my $self = shift;
	$self->{_base} =~ s/^http:/https:/g;	# Requires SSL
	die("Missing username") if $self->{_username} eq '';
	die("Missing password") if $self->{_password} eq '';
	my %params = (
				user		=> $self->{_username},
				password	=> $self->_crypt_md5($self->{_password}),
				test		=> $self->{_test},
	);
	my $url = "$self->{_base}/list_outstanding_domains";
	my $req = POST($url, \%params);
	$self->{_response}->{_raw} = $self->_get($req);
	use WWW::CNic::Response::ListOutstandingDomains;
	return WWW::CNic::Response::ListOutstandingDomains->new($self->{_response}->{_raw});
}

sub _submit_payment_batch {
	my $self = shift;
	$self->{_base} =~ s/^http:/https:/g;	# Requires SSL
	die("Missing username") if $self->{_username} eq '';
	die("Missing password") if $self->{_password} eq '';
	die("Missing domains") if scalar(@{$self->{_params}->{domains}}) < 1;
	die("Missing method") if $self->{_params}->{method} eq '';
	my %params = 	(
				user		=> $self->{_username},
				password	=> $self->_crypt_md5($self->{_password}),
				test		=> $self->{_test},
				method		=> $self->{_params}->{method},
			);
	my $i = 0;
	foreach my $domain(@{$self->{_params}->{domains}}) {
		$params{"domains[$i]"} = $domain;
		$i++;
	}
	my $req = POST("$self->{_base}/submit_payment_batch", \%params);
	$self->{_response}->{_raw} = $self->_get($req);
	use WWW::CNic::Response::SubmitPaymentBatch;
	return WWW::CNic::Response::SubmitPaymentBatch->new($self->{_response}->{_raw});
}

sub _lock_domain {
	my $self = shift;
	$self->{_base} =~ s/^http:/https:/g;	# Requires SSL
	die("Missing username") if $self->{_username} eq '';
	die("Missing password") if $self->{_password} eq '';
	die("Missing domain")	if $self->{_domain}   eq '';
	my %params = (
				user		=> $self->{_username},
				password	=> $self->_crypt_md5($self->{_password}),
				test		=> $self->{_test},
				domain		=> $self->{_domain},
	);
	my $url = "$self->{_base}/lock_domain";
	my $req = POST($url, \%params);
	$self->{_response}->{_raw} = $self->_get($req);
	use WWW::CNic::Response::LockDomain;
	return WWW::CNic::Response::LockDomain->new($self->{_response}->{_raw});
}

sub _unlock_domain {
	my $self = shift;
	$self->{_base} =~ s/^http:/https:/g;	# Requires SSL
	die("Missing username") if $self->{_username} eq '';
	die("Missing password") if $self->{_password} eq '';
	die("Missing domain")	if $self->{_domain}   eq '';
	my %params = (
				user		=> $self->{_username},
				password	=> $self->_crypt_md5($self->{_password}),
				test		=> $self->{_test},
				domain		=> $self->{_domain},
	);
	my $url = "$self->{_base}/unlock_domain";
	my $req = POST($url, \%params);
	$self->{_response}->{_raw} = $self->_get($req);
	use WWW::CNic::Response::UnlockDomain;
	return WWW::CNic::Response::UnlockDomain->new($self->{_response}->{_raw});
}

sub _get {
	my ($self, $request) = @_;
	my $response = $self->{_agent}->request($request);
	if ($response->is_error()) {
		return "Status: 1\nMessage: ".$response->status_line();
	} else {
		return $response->content();
	}
}

sub _build_handle_string {
	my ($self, $data) = @_;
	my @str = ('new');
	foreach my $key (qw(name company address postcode country phone fax email)) {
		push(@str, $data->{$key});
	}
	return join("::", @str);
}

sub _salt {
	return join('', ('.', '/', 0..9, 'A'..'Z', 'a'..'z')[rand 64, rand 64]);
}

sub _crypt_md5 {
	my ($self, $str) = @_;
	### special hack: Mac OS X and Windows don't support MD5 in the crypt() function
	### so use plaintext passwords:
	if ($^O eq 'darwin' || $^O eq 'MSWin32') {
		return 'plain:'.$str;

	} else {
		return crypt($str, '$1$' . substr(md5_hex(rand()), 0, 8) . '$');

	}

}

1;
