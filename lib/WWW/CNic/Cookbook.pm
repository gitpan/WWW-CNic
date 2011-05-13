# Copyright (c) 2011 CentralNic Ltd. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
# $Id: Cookbook.pm,v 1.53 2011/05/13 13:31:49 gavin Exp $

package WWW::CNic::Cookbook;
use vars qw($VERSION);

=pod

=head1 Name

WWW::CNic::Cookbook - The WWW::CNic Cookbook

=head1 Description

This document provides a fairly complete explanation of how to implement basic Registrar-Registry functions with CentralNic using C<WWW::CNic>.

This document is a work in progress, if you want to see something in it that isn't, or find an error, please let us know by e-mailing L<toolkit@centralnic.com>.

=head1 Test Mode

The Toolkit can be told to run in I<test mode>, that is, to use a non-live copy of the database so that any changes made don't affect the live domains.

To enable test mode, simply set the C<test> argument on the constructor, like so:

	my $query = WWW::CNic->new(test => 1, ... );

You will also need to supply B<test account> credentials rather than production account credentials. These can be obtained from the Registrar Console.

=head1 Getting Information about Domains

=head2 Getting a Suffix List

CentralNic's range of available domain names changes occasionally and you may want to periodically update the list of domains we support. You can use the C<suffixes> command to retrieve an array containing all the domain suffixes CentralNic supports.

	use WWW::CNic;

	# create a request object:
	my $query = WWW::CNic->new(
		command	=> 'suffixes',
	);

	# execute the query to return a response object:
	my $response = $query->execute;

	# use the suffixes() method to get a list of suffixes:
	my @suffixes = $response->suffixes;

This can be shortened to:

	use WWW::CNic;

	my @suffixes = WWW::CNic->new(command=>'suffixes')->execute->suffixes;

=head2 Doing a Domain Availability Search

The traditional method for checking the availability of a domain name is to query the registry's whois server, and do a pattern match against the response looking for indications that the domain is registered. This is not an optimal approach for several reasons - firstly, the whois protocol was never designed for it. Secondly, the lack of a whois record does not signify availablity. It also can't handle multiple lookups very well.

The C<search> function is a very powerful way to check on the availability of a domain name. It allows you to check the availability of a domain name across one, several or all of CentralNic's suffixes.

Here's how you might do a check against a particular domain name:

	use WWW::CNic;

	my $domain = 'example';
	my $suffix = 'uk.com'; 

	my $query = WWW::CNic->new(
		command	=> 'search',
		domain	=> $domain,
	);

	$query->set(suffixlist => [$suffix]);

	my $response = $query->execute;

	if ($response->is_registered($suffix)) {
		printf("domain is registered to %s\n", $response->registrant($suffix));

	} else {
		print "domain is available.\n";

	}

Notice the extra step (using the C<set()> method), where we set the 'suffixlist' parameter to be an anonymous array containing the single suffix we want to check. Omitting this step would make the query check against all CentralNic suffixes.

The response object returned has a method C<is_registered()> which returns true if the domain is already registered. Additionally, you can use the C<registrant($suffix)> and C<expiry($suffix)> methods to get the registrant name and a UNIX timestamp of the expiry date respectively.

=head2 Getting Detailed Information About a Domain

Prior to submitting a modification, you may wish to get detailed information about a domain name to present to your users. The C<whois> command allows the lookup of the same detailed information that a whois server provides.

For example:

	use WWW::CNic;

	my $domain = 'example.uk.com';

	my $query = WWW::CNic->new(
		command	=> 'whois',
		domain	=> $domain,
	);

	my $response = $query->execute;

	print "Domain: $domain\n";

	my %tech_handle = %{$response->response('thandle')};
	printf("Tech Handle: %s (%s)\n", $tech_handle{userid}, $tech_handle{name});

	my $dns = $response->response('dns');
	foreach my $server(@{$dns}) {
		if (ref($server) eq 'ARRAY') {
			my ($name, $ipv4) = @{$server};
			print "Server: $name ($ipv4)\n";

		} else {
			print "Server: $server\n";

		}
	}

The response object contains values for the following keys:

	registrant			the domain's registrant
	created				registration date
	expires				expiry date
	status				status (e.g. Live, On Hold, Pending Deletion etc)
	chandle				Client Handle
	bhandle				Technical Handle
	thandle				Billing Handle
	dns				DNS Servers

The C<registrant> and C<status> keys are just strings. The C<created> and C<expires> keys are UNIX timestamps. The C<chandle>, C<thandle> and C<bhandle> keys are all references to hashes with the following keys:

	userid
	name				
	company
	addr
	street1
	street2
	street3
	city
	sp
	postcode
	country
	phone
	fax
	email

These values can be accessed in the following way:

	# get the tech handle:
	my $tech_handle = $response->response('thandle');

	print $tech_handle->{addr};

	# and so on for the other keys

The C<dns> key is an array. Elements in the array may be either a plain scalar containing the DNS hostname of the server, or an anonymous array containing the DNS hostname and IPV4 address in that order. Use the C<ref()> function to work out which.

B<Address data:> handles in the CentralNic database follow one of two "styles": old-style handles have flat address data (stored in the C<address> property), but new-style handles have separate properties for street, city and state/province. All handles will have at least a non-empty C<address> property (for new-style handles this is created by flattening the C<street1>, C<street2>... properties). All new-style handles will have a non-empty C<street1> property.

=head2 Retrieving the Transfer Code For a Domain Name

	use WWW::CNic;

	my $query = WWW::CNic->new(
		command		=> 'auth_info',
		domain		=> 'example.uk.com',
		username	=> $handle,
		password	=> $passwd,
	);

	my $response = $query->execute;

	if ($response->is_error) {
		printf("Error: %s\n", $response->error);

	} else {
		printf("Transfer code: %s\n", $response->auth_code);

	}

This command is used to retrieve the transfer code for a domain name. Those registrars who use our EPP system are required to provide a security code when they initiate a transfer request, which they get from the registrant, who in turn gets it from the losing registrar. Registrars are required to provide this code to registrants upon request.

=head2 Getting Detailed Information About a Handle

This command can be used to retrieve information about a handle I<for which you are the sponsor>. You are the sponsor of a handle if you created it as part of a domain registration or modification process, or it is associated with a domain name for which you are Billing Handle.

	use WWW::CNic;

	my $query = WWW::CNic->new(
		command		=> 'handle_info',
		username	=> $handle,
		password	=> $passwd,
	);

	$query->set(handle => 'H12345');

	my $response = $query->execute;

	if ($response->is_error) {
		printf("Error: %s\n", $response->error);

	} else {
		foreach my $key (qw(name company address street1 street2 street3 city sp postcode country tel fax email visible)) {
			printf("%s: %s\n", $key, $response->response($key));
		}

	}

The C<visible> value is a binary value (1 or 0) that indicates whether this handle's details are show in WHOIS records for domains with which it is associated.

B<Address data:> handles in the CentralNic database follow one of two "styles": old-style handles have flat address data (stored in the C<address> property), but new-style handles have separate properties for street, city and state/province. All handles will have at least a non-empty C<address> property (for new-style handles this is created by flattening the C<street1>, C<street2>... properties). All new-style handles will have a non-empty C<street1> property.

=head1 Creating New Domains and Handles

=head2 Creating a Handle

If you are going to be registering multiple domains, you should create a new handle and use that to register the domains using its ID, rather than supply new contact details for each registration, which will result in a new client handle being created each time.

To do so, use the C<create_handle> command:

	use WWW::CNic;

	my $query = WWW::CNic->new(
		command		=> 'create_handle',
		username	=> $handle,
		password	=> $passwd,
	);

	$query->set(handle => {
		name	=> 'John Doe',
		company	=> 'Example, Inc',
		street1	=> 'Example House',
		street2	=> 'Example Street',
		city	=> 'London',
		sp	=> 'England',
		postcode=> 'EC1 123',
		country	=> 'UK',
		phone	=> '+44.8700170900',
		fax	=> '+44.8700170901',
		email	=> 'jd@example.com',
	});

	# make the handle hidden on whois records:
	$query->set(visible => 0);

	my $response = $query->execute;

	if ($response->is_success) {
		printf("New handle created with ID %s\n", $response->handle);

	} else {
		printf("Error: %s\n", $response->error);

	}

The C<handle> parameter must be a reference to a hash containing the following keys:

	name
	company
	street1
	street2
	street3
	city
	sp
	postcode
	country
	phone
	fax
	email

Only C<name>, C<country> and C<email> are mandatory. The C<phone> and C<fax> fields can be in any format, but we request that you use the e164a format:

	+AA.BBB(xCC)

where C<AA> is the dialling code for the country in question, C<BBB> is the phone number without a local dialling prefix (eg, for the UK, emit the leading zero), and C<CC> is an optional extension.

C<street1>, C<street2> and C<street3> are street address lines, C<city> is the postal city/town and C<sp> is the state, province or county.

The C<country> field must be a valid ISO3166 2-character country code.

The C<visible> parameter controls whether the handle's contact details are shown on whois records for domain names to which it is associated. By default, the value of C<visible> is C<1>. A value of C<0> hides the handle from whois records.

You can use the C<handle()> method to return the ID of the created handle, for use when registering.

=head2 Registering a Domain Name

We require that you use SSL when making registration and modification requests. WWW::CNic supports SSL communications transparently, since it uses C<LWP> to do all HTTP communication. C<LWP> will handle SSL if the C<Crypt::SSLeay> or C<IO::Socket::SSL> modules have been installed.

	use WWW::CNic;

	my $query =	WWW::CNic->new(
		command		=> 'register',
		domain		=> 'example.uk.com',
		username	=> $handle,
		password	=> $passwd,
	);

	$query->set(
		registrant	=> 'Example, Inc',
		chandle		=> $chandle,
		thandle		=> $thandle,
		period		=> 2,
	);

	# Set DNS servers

	$query->set(dns => ['ns0.example.com', 'ns1.example.com']);

	# OR

	$query->set(url => 'http://www.example.com/');

	my $response = $query->execute;

	if ($response->is_success) {
		printf("Domain registered at price %01.2f\n", $response->amount);

	} else {
		printf("Error: %s\n", $response->error);

	}

IMPORTANT NOTE: the details you enter for the Client Handle (C<chandle>) should be the contact details of your customer.

In order to make a registration transaction, you need to supply the C<username> and C<password> parameters - these correspond to your Registrar Handle's ID and password. Your password is C<crypt()>ed before it is sent.

You need to set a range of extra parameters to register a domain. These are explained below.

=over

=item 1

C<registrant> - the name of the domain's registrant. This is a text string corresponding to your customer's name and/or organisation. It should B<not> be a handle ID.

=item 2

C<chandle> - the Client Handle. The Client Handle should correspond to your customer's contact details.

=item 3

C<thandle> - the Technical Handle. This may take two values. It can be a scalar containing the Handle ID of an existing handle, or "C<chandle>" to set it to be whatever C<chandle> is.

=item 4

C<dns> - the DNS servers for the domain. This can either be an anonymous array of DNS hostnames, or a reference to hash such as that below:

	my $dns = {
		'ns0.example.com' => '192.168.1.1',
		'ns1.example.com' => '192.168.1.2',
	};

If you have specified default DNS servers using the Registrar Console you can set C<$dns> to be 'C<defaults>' and the system will use these.

=item 5

C<url> - if this parameter is provided and is not empty, it will be used to set a simple web forwarding for the domain I<instead of any DNS servers provided>.

=item 6

C<period> - the registration period for the domain name. This is an integer number of years and must be between 2 and 10, or 100. If this field is omitted the domain will be registered for 2 years.

=back

The response object for this command has all the usual methods (as documented in L<WWW::CNic::Response>), plus the C<amount()> method, which returns the price in Sterling for the domain.

B<NB>: In addition to specifying a handle ID or "C<chandle>" in the C<chandle> and C<thandle> fields, it is also possible to use an anonymous hash to supply the details of a new handle. However this is a legacy feature for compatibility with older versions of WWW::CNic and its use is not recommended.

=head1 Modifying Domain Names and Handles

=head2 Modifying a Domain Name

You can use C<WWW::CNic> to do real-time modification of a domain. The procedure is somewhat similar to that of registration.

	use WWW::CNic;

	my $query =	WWW::CNic->new(
		command		=> 'modify',
		domain		=> 'example.uk.com',
		username	=> $handle,
		password	=> $passwd,
	);

	$query->set(
		thandle	=> $handle,
		dns	=> {
			drop	=> 'all',
			add	=> ['ns0.example.com',   'ns1.example.com'],
		}
		url	=> 'drop',
	);

	my $response = $query->execute;

	if ($response->is_success) {
		print "Domain modified OK.\n";

	} else {
		printf("Error, could not modify domain: %s\n", $response->error);

	}

The C<modify> command allows you to add and remove DNS servers and to change the Technical Handle. You can set two parameters for the transaction:

=over

=item 1

C<thandle> corresponds to a new Technical Handle.

=item 2

C<dns> must be an anonymous hash (or a reference to a hash) with two keys: C<add> and C<drop>. Their values are anonymous arrays of DNS hostnames. When dropping DNS servers, you can use the string C<'all'> to indicate that you want to delete all the previously delegated DNS servers (this doesn't affect any servers you might add during the same transaction).

B<NB>: In addition to specifying a handle ID in the C<thandle> field, it is also possible to use an anonymous hash to supply the details of a new handle. However this usage is not recommended.

=item 3

C<url> is an optional element containing a new URL to which to forward the domain. If this parameter is set, then the C<dns> parameter is ignored, and any existing DNS servers are removed from the domain.

If this parameter contains the special keyword C<'drop'> then the web forwarding will be removed, and the domain will be 'parked'.

=back

=head2 Modifying a Handle

When a handle is created by the C<create_handle> or C<register> commands, or via other interfaces such as the Registrar Console, it is associated with your account. This allows you to update the contact details for that handle.

B<IMPORTANT>: this command B<must not> be used to completely change the contact details for a handle for a domain name. Instead you should use the C<modify> function to change the ID of the handle on the domain name (see above). This function is only for incremental changes to contact details.

	use WWW::CNic;

	my $query = WWW::CNic->new(
		command		=> 'modify_handle',
		username	=> $handle,
		password	=> $passwd,
	);

	$query->set(
		handle		=> 'H12345',
		name		=> 'John Doe',
		company		=> 'Example, Inc',
		street1		=> 'Example House',
		street2		=> 'Example Street',
		city		=> 'London',
		sp		=> 'England',
		postcode	=> 'EC1 123',
		country		=> 'UK',
		phone		=> '+44.8700170900',
		fax		=> '+44.8700170901',
		email		=> 'jd@example.com',
		visible		=> 0,
	);

	my $response = $query->execute;

	if ($response->is_success) {
		print "Handle modified OK.\n";

	} else {
		printf("Error, could not modify handle: %s\n", $response->error);

	}

You can change the following values:

	name
	company
	street1
	street2
	street3
	city
	sp
	postcode
	country
	phone
	fax
	email
	visible

The meaning of these fields is identical to those described in the "Creating a Handle" section. Note that C<name>, C<country> and C<email> are all mandatory and cannot be blank.

=head2 Renewing a Domain Name

	use WWW::CNic;
	use strict;

	my $query = WWW::CNic->new(
		command		=> 'issue_renewals',
		username	=> $handle,
		password	=> $passwd
	);

	$query->set(
		domains => ['example1.uk.com', 'example2.uk.com'],
		period	=> 2, # 2 years
	);

	my $response = $query->execute;

	if ($response->is_success) {
		print "Domain(s) renewed.\n";

	} else {
		printf("Error: %s\n", $response->error);

	}

You can issue advance renewals for domains using this command. You simply set a C<domains> parameter to be an anonymous array of domain names, or a reference to an array (eg C<\@domains>).

Under normal circumstances, a renewal invoice or proforma is not issued right away, but is queued until the end of the day. If you want to generate a renewal invoice immediately, set the C<immediate> parameter, like so:

	$query->set(immediate => 1);

	my $response = $query->execute;

	if ($response->is_success) {
		printf(	"%s #%d issued at a value of %01.2f.\n",
			($response->invoice > 0 ? 'Invoice' : 'Pro forma'),
			($response->invoice > 0 ? $response->invoice : $response->proforma),
			$response->amount
		);

	} else {
		printf("Error: %s\n", $response->error);

	}

=head2 Deleting a Domain Name

	my $query = WWW::CNic->new(
		command		=> 'delete',
		domain		=> $domain,
		username	=> $handle,
		password	=> $password,
	);

	my $response = $query->execute;

	if ($response->is_success) {
		print "Domain has been deleted.\n";

	} else {
		printf("Error: %s\n", $response->error);

	}

Using this service, you can delete an unwanted domain name. However, you must supply a reason code in order for the deletion to take place. The currently available codes are listed below:

	Code 	Meaning
	R1 	Payment not received
	R2 	Fraudulent Registration
	R3 	Domain no longer required by registrant
	R4 	Domain registered in error

In accordance with our policy, an e-mail will be sent to the domain's Client Handle informing them that the domain has been deleted.

=head2 Requesting Reactivation of a Domain Name

Domains that are on the "Pending Deletion" status may be reactivated upon
request. This function provides a way to automatically submit a reactivation
request. When we receive your request, it will be processed by a member of our
Domain Administration team. The domain will then be placed back on the "Live"
status, and a registration or renewal invoice will be re-issed.

	my $query = WWW::CNic->new(
		command		=> 'reactivate',
		domain		=> $domain,
		username	=> $handle,
		password	=> $password,
	);

	$query->set('email', 'yourname@example.com');
	$query->set('period', 1); # renewal period in years

	my $response = $query->execute;

	if ($response->is_success) {
		print "Reactivation request accepted.\n";

	} else {
		printf("Error: %s\n", $response->error);

	}

If you specify an C<email> parameter, our administrators will send a notification
to that address. C<period> may be any integer between 1 and 10.

=head2 Pushing a Domain Name To Another Registrar

You may request that a domain name on your account be "pushed" to another
registrar account. A domain name may only be pushed if:

=over

=item the domain name is on your account

=item the domain name's status is "Live"

=item the "gaining" registrar has not opted-out of the "push" system

=item there are no unpaid registration or renewal fees against it

=back

	my $query = WWW::CNic->new(
		command		=> 'push_domain',
		username	=> $handle,
		password	=> $password,
		domain		=> $domain,
		handle		=> $gaining_handle_id,
	);

	my $response = $query->execute;

	if ($response->is_success) {
		print "Domain transferred OK.\n";

	} else {
		printf("Error: %s\n", $response->error);

	}

If the transaction is successful, the domain name will be immediately removed
from your account.

If you are also listed as Technical Contact for the domain name, then this
handle will also be changed to the gaining registrar account.

This command will also transfer sponsorship of the client and/or technical
handles for the domain name, but only if these handles are not associated with
any other domains on your account. Where a handle is associated with domains on
multiple registrar accounts, the handle becomes "unsponsored".

We will send an e-mail to the gaining registrar notifying them of the domain
transfer.

=head1 Transferring Domain Names

=head2 Starting a Domain Transfer

You can B<start> a transfer process for one or more domain names using the C<start_transfer> command. However, there are "out-of-band" authorisations that must take place before a transfer is completed. The procedure for domain transfers is as follows:

1. The B<gaining> registrar submits a transfer request. At this point, the transfer status is C<new>.

2. Our system sees the new request and sends an authorisation message to the B<losing> registrar. The status of the transfer is now C<pending>.

3. The B<losing> registrar may then explicitly I<approve> or I<reject> the transfer request within 5 days. The status of the transfer is now either C<approved> or C<rejected>.

4. If the transfer was B<rejected>, the B<gaining> registrar is notified.

5. If the transfer was B<approved>, the object is transferred to the B<gaining> registrar. If the Technical Contact for the domain name matches the B<losing> registrar, then this is also changed to the B<gaining> registrar.

6. If the transfer B<was not> submitted with the C<authinfo> parameter, and is not explicitly I<approved> or I<rejected> by the B<losing> registrar B<within five calendar days>, then the transfer is automatically marked as C<rejected>. The transfer may still be actioned if the B<gaining> registrar can acquire written authorisation (ideally on company letterhead) from the Registrant.

7. If the transfer B<was> submitted with the C<authinfo> parameter, and is not explicitly I<approved> or I<rejected> by the B<losing> registrar B<within five calendar days>, then the transfer is approved as per 5 above.

	my $query = WWW::CNic->new(
		command		=> 'start_transfer',
		username	=> $handle,
		password	=> $password,
	);

	$query->set(domains => ['example.uk.com']);
	$query->set(authinfo => ['abc123xyz']); # optional

	my $response = $query->execute;

	if ($response->is_success) {
		print "Transfer request has been accepted.";

	} else {
		printf("Error: %s\n", $response->error);

	}

=head2 Getting a List of Pending Transfers

	my $query = WWW::CNic->new(
		use_ssl		=> 1,
		command		=> 'poll_transfers',
		username	=> $handle,
		password	=> $password,
	);

	my $response = $query->execute;

	if ($response->is_error) {
		printf("Error: %s\n", $response->error);
	}

	foreach my $transfer ($response->transfers) {
		printf("Domain: %s\n", $transfer->{domain});

		if ($transfer->{type} eq 'in') {
			printf("\tLosing handle: %s (email %s)\n", $transfer->{losing_id}, $transfer->{losing_email});

		} elsif ($transfer->{type} eq 'out') {
			printf("\tGaining handle: %s (email %s)\n", $transfer->{gaining_id}, $transfer->{gaining_email});

		}

		printf(
			"\tTransfer initiated on %s\n",
			scalar(localtime($transfer->{initiated}))
		);

		printf(
			"\tTransfer expires on on %s\n",
			scalar(localtime($transfer->{actiondate}))
		);

	}

The C<transfers()> method returns an array of hashrefs containing transfer information. If there are no transfers, then the array will be empty.

=head2 Cancelling a Domain Transfer

	my $query = WWW::CNic->new(
		use_ssl		=> 1,
		command		=> 'cancel_transfer',
		username	=> $handle,
		password	=> $password,
		domain		=> 'example.uk.com',
	);

	my $response = $query->execute;

	if ($response->is_success) {
		print "Transfer cancelled.\n";

	} else {
		printf("Error: %s\n", $response->error);

	}

If you are the gaining registrar for a domain transfer, you can cancel the request before it is approved or rejected by the losing registrar. If the transfer has already been approved or rejected, then the server will return an error.

=head2 Checking the Status of a Domain Transfer

	my $query = WWW::CNic->new(
		use_ssl		=> 1,
		command		=> 'check_transfer',
		username	=> $handle,
		password	=> $password,
		domain		=> 'example.uk.com',
	);

	my $response = $query->execute;

	if ($response->is_success) {
		printf("The transfer status of example.uk.com is '%s'\n", $response->status);

	} else {
		printf("Error: %s\n", $response->error);

	}

This lets you query the status of a domain name transfer. The returned status is a string and is one of: C<pending>, C<cancelled>, C<approved>, C<rejected>. If there have been other transfer requests in the past, the server will return the status of the most recent one.

If there are no transfers for the domain name, or you are not the gaining handle, the server will return an error.

=head2 Approving a Domain Transfer

	my $query = WWW::CNic->new(
		use_ssl		=> 1,
		command		=> 'approve_transfer',
		username	=> $handle,
		password	=> $password,
		domain		=> 'example.uk.com',
	);

	my $response = $query->execute;

	if ($response->is_success) {
		print "Transfer approved.\n";

	} else {
		printf("Error: %s\n", $response->error);

	}

If there are no transfers for the domain name, or you are not the losing handle, the server will return an error.

=head2 Rejecting a Domain Transfer

	my $query = WWW::CNic->new(
		use_ssl		=> 1,
		command		=> 'reject_transfer',
		username	=> $handle,
		password	=> $password,
		domain		=> 'example.uk.com',
	);

	my $response = $query->execute;

	if ($response->is_success) {
		print "Transfer rejected.\n";

	} else {
		printf("Error: %s\n", $response->error);

	}

If there are no transfers for the domain name, or you are not the losing handle, the server will return an error.

=head1 Account Management

=head2 Getting a List of Upcoming Renewals

	use WWW::CNic;
	use POSIX qw(strftime);

	my $months = 3;

	my $query = WWW::CNic->new(
		use_ssl		=> 1,
		command		=> 'renewals',
		username	=> $handle,
		password	=> $passwd,
		months		=> $months
	);

	my $response = $query->execute;

	if ($response->is_success) {
		foreach my $domain ($response->domains) {
			printf(	"Domain %s expires on %s and will cost %01.2f",
				$domain,
				strftime('%d/%m/%Y', localtime($response->expiry($domain))),
				$response->amount($domain)
			);
		}

	} else {
		printf("Error, couldn't get list of upcoming renewals: %s\n", $response->error);

	}

This command lets you retrieve a list of domain names due for renewal in the last C<$months> months. You can use the C<amount> and C<expiry> methods to retrieve the renewal price and expiry date for each domain.

=head2 Getting a Domain List

	use WWW::CNic;
	use POSIX qw(strftime);

	my $query = WWW::CNic->new(
		use_ssl		=> 1,
		command		=> 'list_domains',
		username	=> $handle,
		password	=> $passwd,
	);

	$query->set(
		offset	=> 5,
		length	=> 10,
		orderby	=> 'name'
	);

	my $response = $query->execute;

	if ($response->is_success) {
		foreach my $domain ($response->domains) {
			printf(	"%s: %s - %s (%s)\n",
				$domain,
				strftime('%d/%m/%Y', localtime($response->regdate($domain))),
				strftime('%d/%m/%Y', localtime($response->expirydate($domain))),
				$response->status($domain),
			);
		}

	} else {
		printf("Error: %s\n", $response->error);

	}

You can use this command to retrieve a list of domains against your handle. The response object returned has methods allowing the retrieval of the registration date and expiry date and status. The C<offset> and C<length> parameters work in the SQL-ish way you'd expect. The C<orderby> parameter can be C<name>, C<regdate> or C<expirydate>.

=head2 Getting Pricing Information

	use WWW::CNic;
	use strict;
	
	my $query = WWW::CNic->new(
		use_ssl		=> 1,
		command		=> 'get_pricing',
		username	=> $handle,
		password	=> $password,
	);
	
	$query->set(type => 'renewal');
	
	my $response = $query->execute;
	
	if ($response->is_success) {
		printf("the price we pay for renewals of uk.com domains is %.2f\n", $response->response('uk.com'));

	} else {
		printf("Error: %s\n", $response->error);

	}

This command allows you to retrieve pricing information for your registrar account. You must specify a C<type> parameter, which can be either 'C<registration>' (the default) or 'C<renewal>'.

=head2 Listing Outstanding Domains

	use WWW::CNic;
	use strict;

	my $query = WWW::CNic->new(
		use_ssl		=> 1,
		command		=> 'list_outstanding_domains',
		username	=> $handle,
		password	=> $password,
	);

	my $response = $query->execute;

	if ($response->is_error) {
		printf("Error: %s\n", $response->error);
	}

	foreach my $domain ($response->domains) {
		printf(
			"Domain: %s\n".
			"\tExpired: %s\n".
			"\tDocument: %s #%d\n".
			"\tIssued on: %s\n".
			"\tAmount: %s%01.2f\n".
			"\tType: %s\n".
			"\tYears: %s\n".
			"\tBatch: %d\n\n",
			$domain->{domain},
			$domain->{expiry},
			($domain->{invoice} > 0 ? 'Invoice' : 'Pro forma'),
			($domain->{invoice} > 0 ? $domain->{invoice} : $domain->{proforma}),
			$domain->{date},
			$domain->{currency},
			$domain->{amount},
			$domain->{type},
			$domain->{years},
			$domain->{batch},
		);
	}

This command retrieves a list of all unpaid invoice items for domain names on your account. Each registration or renewal causes on item to be added to an invoice (or pro forma invoice for VAT-paying registrars).

You can combine this function with the one below to automatically submit payment advice for invoices (you still need to send us the actual money!).

=head2 Submitting Payment Advice

	use WWW::CNic;
	use strict;

	my $query = WWW::CNic->new(
		use_ssl		=> 1,
		command		=> 'submit_payment_batch',
		username	=> $handle,
		password	=> $password,
	);

	$query->set('method', 'CH'); # CH for a cheque, BA for a bank transfer
	$query->set('domains', \@domains);

	my $response = $query->execute;

	if ($response->is_error) {
		printf("Error: %s\n", $response->error);
	}

	printf(
		"Payment Batch #%d created for %d items at %s%01.2f (plus %s%01.2f VAT)\n",
		$response->response('batch'),
		$response->response('items'),
		$response->response('currency'),
		$response->response('amount'),
		$response->response('currency'),
		$response->response('vat'),
	);

You can use this function to submit advice about a payment for outstanding domain registrations and renewals. Combining this function with the function above allows you to retrieve a list of outstanding domain names, filter them based on whether or not you've received payment or a deletion request from your customer, and generate a payment batch that can be associated with a cheque or wire transfer issued by your company.

Please note that you will need to factor in the amount of VAT (if applicable) - this amount is available in the response object.

=head1 Feedback

We're always keen to find out about how people are using our Toolkit system, and we're happy to accept any comments, suggestions or problems you might have. If you want to get in touch, please e-mail L<toolkit@centralnic.com>.

=head1 Copyright

This module is (c) 2011 CentralNic Ltd. All rights reserved. This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 See Also

=over

=item *

L<http://toolkit.centralnic.com/>

=item *

L<WWW::CNic>

=item *

L<WWW::CNic::Simple>

=back

=cut
