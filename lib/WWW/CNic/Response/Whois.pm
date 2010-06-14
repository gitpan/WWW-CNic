# Copyright (c) 2010 CentralNic Ltd. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
# $Id: Whois.pm,v 1.13 2010/03/31 11:58:31 gavin Exp $

package WWW::CNic::Response::Whois;
use vars qw($VERSION);

sub response {
	my ($self, $key) = @_;
	if (lc($key) =~ /^(c|t|b)handle$/) {
		my $response = $self->SUPER::response($key);
		if (ref($response) eq '') {
			my ($name, $value) = split(/=/, $response, 2);
			$value =~ s/^\"//g;
			$value =~ s/\"$//g;
			return { $name => $value };
		} else {
			return $response;
		}
	} else {
		return $self->SUPER::response($key);

	}
}

=pod

=head1 NAME

WWW::CNic::Response::Whois - a WWW::CNic response object for whois lookups.

=head1 SYNOPSIS

	use WWW::CNic;

	my $query = WWW::CNic->new( OPTIONS );

	my $response = $query->execute();

=head1 DESCRIPTION

Response module for whois lookups via the CentralNic Toolkit (I<http://toolkit.centralnic.com/>). This module inherits all of its methods from the base class, I<WWW::CNic::Response>.

=head1 METHODS

This class has no additional methods than those it inherits from I<WWW::CNic::Response>. Check L<WWW::CNic::Response> for information about available methods.

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

1;
