# Copyright (c) 2010 CentralNic Ltd. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
# $Id: PollTransfers.pm,v 1.3 2010/03/31 11:58:31 gavin Exp $

package WWW::CNic::Response::PollTransfers;
use vars qw($VERSION);

=pod

=head1 NAME

=head1 SYNOPSIS

	use WWW::CNic;

	my $query = WWW::CNic->new( OPTIONS );
	$query->set( PARAMETERS );

	my $response = $query->execute();

=head1 DESCRIPTION

Response module for listing all pending domain transfers via the CentralNic Toolkit (http://toolkit.centralnic.com/). This module inherits all but one of its methods from the base class, I<WWW::CNic::Response>.

=head1 METHODS

	my @transfers = $response->transfers;

This returns an array of hashrefs containing information about a transfer. The hashref has the following keys:

	domain
	initiated (timestamp)
	actiondate (timestamp)
	auto (integer)
	gaining_id (only present for outgoing transfers)
	gaining_email (only present for outgoing transfers)
	losing_id (only present for incoming transfers)
	losing_email (only present for incoming transfers)
	type (in or out)

=head1 COPYRIGHT

This module is (c) 2010 CentralNic Ltd. All rights reserved. This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

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

sub transfers {
	my $self = shift;
	my @transfers;
	foreach my $key (grep { /^domain=/ } $self->keys) {
		my $info = $self->response($key);
		$info->{type} = $info->{':type'};
		delete($info->{':type'});
		$key =~ s/^domain=//g;
		$info->{domain} = $key;
		push(@transfers, $info);
	}
	return @transfers;
}

1;
