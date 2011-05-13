# Copyright (c) 2011 CentralNic Ltd. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
# $Id: ListOutstandingDomains.pm,v 1.4 2011/05/13 13:31:49 gavin Exp $

package WWW::CNic::Response::ListOutstandingDomains;
use vars qw($VERSION);

=pod

=head1 NAME

WWW::CNic::Response::ListOutstandingDomains - a WWW::CNic response object for listing outstanding domains.

=head1 SYNOPSIS

	use WWW::CNic;

	my $query = WWW::CNic->new( OPTIONS );
	$query->set( PARAMETERS );

	my $response = $query->execute();

=head1 DESCRIPTION

Response module for listing all outstanding domains via the CentralNic Toolkit (http://toolkit.centralnic.com/). This module inherits all its methods from the base class, I<WWW::CNic::Response>.

=head1 METHODS

	my @domains = $response->domains;

This method returns an array of hashrefs detailing currently outstanding domains. The keys of the hashref are:

	domain
	expiry
	type
	years
	proforma or invoice
	date
	currency
	amount
	batch

=head1 COPYRIGHT

This module is (c) 2011 CentralNic Ltd. All rights reserved. This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

=over

=item *

http://toolkit.centralnic.com/

=item *

L<WWW::CNic::Response>

=item *

L<WWW::CNic>

=back

=cut

use WWW::CNic::Response;
@ISA = qw(WWW::CNic::Response);
use strict;

sub domains {
	my @domains;
	my $self = shift;
	foreach my $domain ($self->keys) {
		my $info = $self->response($domain);
		next unless (ref($info) eq 'HASH');
		$info->{domain} = $domain;
		push(@domains, $info);
	}
	return @domains;
}

1;
