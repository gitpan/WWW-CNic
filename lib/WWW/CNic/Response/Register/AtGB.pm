# Copyright (c) 2010 CentralNic Ltd. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
# $Id: AtGB.pm,v 1.12 2010/03/31 11:58:32 gavin Exp $

package WWW::CNic::Response::Register::AtGB;
use vars qw($VERSION);

=pod

=head1 NAME

WWW::CNic::Response::Register::AtGB - a WWW::CNic response object for @GB domain registration

=head1 SYNOPSIS

	use WWW::CNic;

	my $query = WWW::CNic->new( OPTIONS );
	$query->set( PARAMETERS );

	my $response = $query->execute();

=head1 DESCRIPTION

Response module for the registration of @GB domains via the CentralNic Toolkit (I<http://toolkit.centralnic.com/>). This module inherits most of its methods from the base class, I<WWW::CNic::Response>, and from I<WWW::CNic::Response::Register>.

=head1 METHODS

Check L<WWW::CNic::Response> for information about methods available from the base class.

	$response->amount();

This method returns the amount (in Sterling) that will be invoiced for the domain name.

	$response->password();

This method returns the password used for the registration, which may either be one previously supplied by the client or one generated on the server.

	$response->invoice();

This method returns the number of any invoice raised for this registration.

	$response->proforma();

This method returns the number of any pro forma invoice raised for this registration.

=head1 COPYRIGHT

This module is (c) 2010 CentralNic Ltd. All rights reserved. This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

=over

=item *

http://toolkit.centralnic.com/

=item *

http://www.gb.com/

=item *

L<WWW::CNic::Response::Register>

=item *

L<WWW::CNic::Response>

=item *

L<WWW::CNic>

=back

=cut

use WWW::CNic::Response::Register;
@ISA = qw(WWW::CNic::Response::Register);

sub password {
	my $self = shift;
	return $self->response('password');
}

sub invoice {
	my $self = shift;
	return $self->response('invoice');
}

sub proforma {
	my $self = shift;
	return $self->response('proforma');
}

1;