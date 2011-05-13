# Copyright (c) 2011 CentralNic Ltd. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
# $Id: AuthInfo.pm,v 1.5 2011/05/13 13:31:49 gavin Exp $

package WWW::CNic::Response::AuthInfo;
use vars qw($VERSION);

=pod

=head1 NAME

WWW::CNic::Response::AuthInfo - a WWW::CNic response object for retrieving domain transfer auth codes.

=head1 SYNOPSIS

	use WWW::CNic;

	my $query = WWW::CNic->new( OPTIONS );
	$query->set( PARAMETERS );

	my $response = $query->execute();

=head1 DESCRIPTION

Response module for retrieving domain transfer auth codes via the CentralNic Toolkit (http://toolkit.centralnic.com/). This module inherits most of its methods from the base class, I<WWW::CNic::Response>.

=head1 METHODS

	$code = $response->auth_code;

This returns the auth code.

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

sub auth_code { $_[0]->response('authcode') }

1;
