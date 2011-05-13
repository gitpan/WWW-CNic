# Copyright (c) 2011 CentralNic Ltd. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
# $Id: UnDeclineDomain.pm,v 1.5 2011/05/13 13:31:49 gavin Exp $

package WWW::CNic::Response::UnDeclineDomain;
use vars qw($VERSION);

=pod

=head1 NAME

WWW::CNic::Response::UnDeclineDomain - a WWW::CNic response object for reversing a declined renewal.

=head1 SYNOPSIS

	use WWW::CNic;

	my $query = WWW::CNic->new( OPTIONS );
	$query->set( PARAMETERS );

	my $response = $query->execute();

=head1 DESCRIPTION

Response module for reversion a declined domain renewal via the CentralNic Toolkit (http://toolkit.centralnic.com/). This module inherits all its methods from the base class, I<WWW::CNic::Response>.

=head1 METHODS

This class has no additional methods than those it inherits from I<WWW::CNic::Response>. Check L<WWW::CNic::Response> for information about available methods.

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

1;
