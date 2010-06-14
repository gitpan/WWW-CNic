# Copyright (c) 2010 CentralNic Ltd. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
# $Id: CheckTransfer.pm,v 1.4 2010/03/31 11:58:31 gavin Exp $

package WWW::CNic::Response::CheckTransfer;
use vars qw($VERSION);

=pod

=head1 NAME

WWW::CNic::Response::CheckTransfer - a WWW::CNic response object for checking the status of domain transfer requests.

=head1 SYNOPSIS

	use WWW::CNic;

	my $query = WWW::CNic->new( OPTIONS );
	$query->set( PARAMETERS );

	my $response = $query->execute();

=head1 DESCRIPTION

Response module for checking the status of a domain transfer via the CentralNic Toolkit (http://toolkit.centralnic.com/). This module inherits all its methods from the base class, I<WWW::CNic::Response>.

=head1 METHODS

	my $status = $response->status;

This returns a string representing the status of a transfer. This may be one of: C<pending>, C<cancelled>, C<approved>, C<rejected>.

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

sub status { return $_[0]->response('transfer-status') }

1;
