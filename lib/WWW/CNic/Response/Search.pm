# Copyright (c) 2010 CentralNic Ltd. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
# $Id: Search.pm,v 1.12 2010/03/31 11:58:31 gavin Exp $

package WWW::CNic::Response::Search;
use vars qw($VERSION);

=pod

=head1 NAME

WWW::CNic::Response::Register - a WWW::CNic response object for domain searching.

=head1 SYNOPSIS

	use WWW::CNic;

	my $query = WWW::CNic->new( OPTIONS );

	my $response = $query->execute();

=head1 DESCRIPTION

Response module for domain searching via the CentralNic Toolkit (I<http://toolkit.centralnic.com/>). This module inherits most of its methods from the base class, I<WWW::CNic::Response>.

=head1 METHODS

	$response->is_registered($suffix);

This methods returns true if the domain with the suffix C<$suffix> is registered.

	$response->registrant($suffix);

Returns the registrant string for a registered domain.

	$response->expiry($suffix);

Returns a UNIX timestamp corresponding to the expiry date of the domain name.

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

sub is_registered {
	my ($self, $suffix) = @_;
	my $domain = (grep { /$suffix$/i } keys %{$self->{_response}})[0];
	my $r = $self->response($domain);
	return ($r == 0 ? undef : (@{$r}[0] == 1));	
}

sub registrant {
	my ($self, $suffix) = @_;
	my $domain = (grep { /$suffix$/i } keys %{$self->{_response}})[0];
	return @{$self->response($domain)}[1];
}


sub expiry {
	my ($self, $suffix) = @_;
	my $domain = (grep { /$suffix$/i } keys %{$self->{_response}})[0];
	return @{$self->response($domain)}[2];
}

1;
