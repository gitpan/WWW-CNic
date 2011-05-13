# Copyright (c) 2011 CentralNic Ltd. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
# $Id: CreateHandle.pm,v 1.9 2011/05/13 13:31:49 gavin Exp $

package WWW::CNic::Response::CreateHandle;
use vars qw($VERSION);

=pod

=head1 NAME

WWW::CNic::Response::CreateHandle - a WWW::CNic response object for creating new handles.

=head1 SYNOPSIS

	use WWW::CNic;

	my $query = WWW::CNic->new( OPTIONS );
	$query->set( PARAMETERS );

	my $response = $query->execute();

=head1 DESCRIPTION

Response module for handle creation requests via the CentralNic Toolkit (http://toolkit.centralnic.com/). This module inherits all its methods from the base class, I<WWW::CNic::Response>.

=head1 METHODS

Check L<WWW::CNic::Response> for information about methods available from the base class.

	$response->handle();

Returns the ID of the handle created. This will be the letter 'H' followed by digits, eg H12345.

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

sub handle { return $_[0]->_expand($_[0]->response('handle')) }

1;
