# Copyright (c) 2011 CentralNic Ltd. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
# $Id: Response.pm,v 1.15 2011/05/13 13:31:49 gavin Exp $

package WWW::CNic::Response;
use vars qw($VERSION);

=pod

=head1 NAME

WWW::CNic::Response - base class for WWW::CNic response objects.

=head1 SYNOPSIS

	use WWW::CNic;

	my $query = WWW::CNic->new( OPTIONS );

	my $response = $query->execute();

=head1 DESCRIPTION

This is the base class for all response objects returned by WWW::CNic. Each query type returns a different object, all of which inherit their basic functionality from this module.

This module should never be accessed directly, only through its children.

=head1 METHODS

All the child classes of WWW::CNic::Response inherit the following methods:

	$response->is_success();

This returns true if the transaction was completed successfully. If there was a server-side error due to invalid data or a system error, or there was an HTTP error this method will return undef.

	$response->is_error();

This is the converse of C<is_success>. It returns true if there was an error.

	$response->error();

This returns the error message generated, if any. This can be either a server-side error message or an HTTP error.

	$response->message();

This returns the message returned when the transaction was successful.

	$response->keys();

This returns an array containing all the keys returned by the server.

	$response->response($key);

This returns the value corresponding to C<$key> as returned by the server. This may be a scalar, or a reference to an array or hash, depending on the context.

	$response->dump();

This prints a human-readable dump of the data stored in the object to C<STDOUT>. Mainly useful in debugging.

=head1 COPYRIGHT

This module is (c) 2011 CentralNic Ltd. All rights reserved. This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

=over

=item *

http://toolkit.centralnic.com/

=item *

L<WWW::CNic>

=back

=cut

sub new {
	my $self = {};
	(my $package, $self->{_raw}) = @_;
	foreach my $line(split(/\n/, $self->{_raw})) {
		chomp($line);
		my ($name, $value) = split(/:\s?/, $line, 2);
		if ($value =~ /::/) {
			if ($value =~ /=/) {
				my %values;
				foreach my $value(split(/::/, $value)) {
					my ($n, $v) = split(/=/, $value, 2);
					$v =~ s/^\"?//;
					$v =~ s/\"?$//;
					$values{$n} = $v;
				}
				push(@{$self->{_response}{lc($name)}}, \%values);
			} else {
				my @values = split(/::/, $value);
				push(@{$self->{_response}{lc($name)}}, \@values);
			}
		} else {
			push(@{$self->{_response}{lc($name)}}, $value);
		}
	}
	bless($self, $package);
	return $self;
}

sub is_success {
	my $self = shift;
	return 1 if (($self->{_response}{'query-status'}[0] ? $self->{_response}{'query-status'}[0] : $self->{_response}{'status'}[0]) == 0);
	return undef;
}

sub is_error {
	my $self = shift;
	return undef if ($self->is_success());
	return 1;
}

sub error {
	my $self = shift;
	return $self->{_response}{message}[0];
}

sub message {
	my $self = shift;
	return $self->response('message');
}

sub keys {
	my $self = shift;
	return CORE::keys(%{$self->{_response}});
}

sub response {
	my ($self, $key) = @_;
	my $value = $self->{_response}{$key};
	if (ref($value) eq 'ARRAY' && scalar(@{$value}) == 1) {
		return ${$value}[0];
	} else {
		return $value;
	}
}

sub dump {
	my $self = shift;
	foreach my $key($self->keys()) {
		print $key . (' ' x (19 - length($key))) . ': ' . $self->_expand($self->response($key)) . "\n";
	}
	return;
}

sub _expand {
	my ($self, $ref) = @_;
	if (ref($ref) eq 'ARRAY') {
		my @values;
		foreach my $el(@{$ref}) {
			push (@values, $self->_expand($el));
		}
		return join(', ', @values);
	} elsif (ref($ref) eq 'HASH') {
		my @values;
		foreach my $key(CORE::keys(%{$ref})) {
			push(@values, $key.'='.$self->_expand(${$ref}{$key}));
		}
		return join(', ', @values);
	} else {
		return $ref;
	}
}

1;
