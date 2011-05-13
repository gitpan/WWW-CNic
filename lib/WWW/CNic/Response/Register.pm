# Copyright (c) 2011 CentralNic Ltd. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
# $Id: Register.pm,v 1.12 2011/05/13 13:31:49 gavin Exp $

package WWW::CNic::Response::Register;
use vars qw($VERSION);

=pod

=head1 NAME

WWW::CNic::Response::Register - a WWW::CNic response object for domain registration.

=head1 SYNOPSIS

	use WWW::CNic;

	my $query = WWW::CNic->new( OPTIONS );
	$query->set( PARAMETERS );

	my $response = $query->execute();

=head1 DESCRIPTION

Response module for domain registrations requests via the CentralNic Toolkit (I<http://toolkit.centralnic.com/>). This module inherits most of its methods from the base class, I<WWW::CNic::Response>.

=head1 METHODS

Check L<WWW::CNic::Response> for information about methods available from the base class.

	$response->amount();

This method returns the amount (in Sterling) that will be invoiced for the domain name.

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

sub amount { return $_[0]->_expand($_[0]->response('amount')) }

1;