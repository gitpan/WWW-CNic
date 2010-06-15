# $Id: NG.pm,v 1.6 2010/06/15 10:47:31 gavin Exp $
# Copyright (c) 2010 CentralNic Ltd. This program is Free Software; you
# can use it and/or modify it under the same terms as Perl itself.
package WWW::CNic::NG;
use WWW::CNic;
use strict;

our $AUTOLOAD;

sub new {
	my $package = shift(@_);
	my $self = bless({'package' => $package}, $package);
	foreach my $name (keys(%_)) {
		$self->{$name} = $_{$name};
	}
	return $self;
}

sub AUTOLOAD {
	my ($self, %params) = @_;
	$AUTOLOAD =~ s/^$self->{'package'}:://g;
	next if ($AUTOLOAD eq 'DESTROY');

	my $query = WWW::CNic->new(
		'command'	=> $AUTOLOAD,
		'test'		=> $self->{'test'},
		'username'	=> $self->{'username'},
		'password'	=> $self->{'password'},
		'domain'	=> $params{'domain'},
	);
	$query->set(%params);
	return $query->execute;
};

=pod

=head1 NAME

WWW::CNIC::NG - a next generation interface to C<WWW:CNic>.

=head1 USAGE

	#!/usr/bin/perl
	use WWW::CNic::NG;
	use strict;

	my $cnic = WWW::CNic::NG->new(
		'username'	=> 'H12345',
		'password'	=> 'password',
		'test'		=> 1, # run against the test database
	);

	# $response is a WWW::CNic::Response submodule:
	my $response = $cnic->whois('domain' => 'example.uk.com');

=head1 SYNOPSIS

C<WWW::CNIC::NG> provides a simpler and more consistent interface to the
C<WWW::CNIC> module. It allows you to reuse the same object for multiple
API calls, and provides Toolkit commands as methods of the object.

=head1 Executing Toolkit Commands

If you have used C<WWW:CNic> you will be familiar with using it like so:

	my $query = WWW::CNic->new(
		'command'	=> 'whois',
		'username'	=> 'H12345',
		'password'	=> 'password',
		'domain'	=> 'example.uk.com',
	);

	$query->set(%more_params);

	# $response is a WWW::CNic::Response submodule:
	my $response = $query->execute;

This is somewhat cumbersome compared to the earlier example.
C<WWW::CNIC::NG> serves to tidy up some of this mess.

Instead of specifying the desired command as a parameter supplied to the
constructor, you simply call the method you want to use on the
C<WWW::CNIC::NG> object. The method's parameters are then used to
prepare a query, and the response from the server is returned from the
method.

=head1 COPYRIGHT

This module is (c) 2010 CentralNic Ltd. All rights reserved. This module
is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=head1 SEE ALSO

=over

=item *

http://toolkit.centralnic.com/

=item *

L<WWW::CNic::Cookbook>

=item *

L<WWW::CNic::Simple>

=backAUTOLOAD

=cut

1;

