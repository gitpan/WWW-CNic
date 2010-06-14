# Copyright (c) 2010 CentralNic Ltd. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
# $Id: IssueRenewals.pm,v 1.8 2010/03/31 11:58:31 gavin Exp $

package WWW::CNic::Response::IssueRenewals;
use vars qw($VERSION);

=pod

=head1 NAME

WWW::CNic::Response::IssueRenewals - a WWW::CNic response object for issuing renewals.

=head1 SYNOPSIS

	use WWW::CNic;

	my $query = WWW::CNic->new( OPTIONS );

	my $response = $query->execute();

=head1 DESCRIPTION

Response module for renewals via the CentralNic Toolkit (I<http://toolkit.centralnic.com/>). This module inherits most of its methods from the base class, I<WWW::CNic::Response>.

=head1 METHODS

	$response->invoice();

Returns the invoice number, if applicable.

	$response->proforma();

Returns the pro forma number, if applicable.

	$response->amount();

Returns the value of the invoice/pro forma, in sterling, excluding VAT.

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

sub invoice { return $_[0]->response('invoice') }

sub proforma { return $_[0]->response('proforma') }

sub amount { return $_[0]->response('amount') }

1;