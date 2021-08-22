package Net::Server::PSGI::Hook;

# https://metacpan.org/pod/PSGI
#
# SERVER_NAME, SERVER_PORT: When combined with SCRIPT_NAME and PATH_INFO,
# these keys can be used to complete the URL. Note, however, that HTTP_HOST,
# if present, should be used in preference to SERVER_NAME for reconstructing the request URL.
# SERVER_NAME and SERVER_PORT MUST NOT be empty strings, and are always required.
#
# SERVER_PROTOCOL: The version of the protocol the client used to send the request.
# Typically this will be something like "HTTP/1.0" or "HTTP/1.1"
# and may be used by the application to determine how to treat any HTTP request headers.


use strict;
use warnings;
use base qw/Net::Server::PSGI/;
#use Scalar::Util qw/blessed/;


# this method is copied from Net::Server::PSGI v2.008
sub process_request {
	my $self = shift;
	
	local $SIG{'ALRM'} = sub { die "Server Timeout\n" };
	my $ok = eval {
		alarm($self->timeout_header);
		$self->process_headers;
		
		
		# by default, Net:: Server:: PSGI does not create SERVER_NAME
		# from Starman (https://metacpan.org/source/MIYAGAWA/Starman-0.4014/lib/Starman/Server.pm#)
		# if there is no SERVER_NAME, then Plack::Middleware:: Lint will swear and the application will not work
		unless ( defined $ENV{'SERVER_NAME'} ) {
			$ENV{'SERVER_NAME'} = $self->{server}->{sockaddr} || 0; # XXX: needs to be resolved?
		}
		
		
		# Net:: Server:: PSGI before version 2.008 does not create SERVER_PROTOCOL
		unless ( defined $ENV{'SERVER_PROTOCOL'} ) {
			$ENV{'SERVER_PROTOCOL'} = 'UNKNOWN';
			if ( defined $self->http_request_info->{request} ) {
				if ( $self->http_request_info->{request} =~ m{ ^\s*(GET|POST|PUT|DELETE|PUSH|HEAD|OPTIONS)\s+(.+)\s+(HTTP/1\.[01])\s*$ }ix ) {
					$ENV{'SERVER_PROTOCOL'} = $3;
				}
			}
		}
		
		
		alarm($self->timeout_idle);
		#my $env = \%ENV; https://perldoc.perl.org/perl5180delta#Defined-values-stored-in-environment-are-forced-to-byte-strings
		my $env = {}; $env->{$_} = $ENV{$_} for keys %ENV;
		$env->{'psgi.version'}      = [1, 0];
		$env->{'psgi.url_scheme'}   = ($ENV{'HTTPS'} && $ENV{'HTTPS'} eq 'on') ? 'https' : 'http';
		$env->{'psgi.input'}        = $self->{'server'}->{'client'};
		$env->{'psgi.errors'}       = $self->{'server'}->{'log_handle'};
		$env->{'psgi.multithread'}  = 1;
		$env->{'psgi.multiprocess'} = 1;
		$env->{'psgi.nonblocking'}  = 1; # need to make this false if we aren't of a forking type server
		$env->{'psgi.streaming'}    = 1;
		local %ENV;
		$self->process_psgi_request($env);
		alarm(0);
		1;
	};
	alarm(0);
	
	if (! $ok) {
		my $err = "$@" || "Something happened";
		$self->send_500($err);
		die $err;
	}
}



# Net:: Server::PSI uses the 'blessed' function while he forgot to load it from the Scalar::Util module
# if the response body is not an array (but, for example, a file descriptor), then it falls with an error
sub print_psgi_body {
	my ($self, $body) = @_;
	my $client = $self->{'server'}->{'client'};
	my $request_info = $self->{'request_info'};
	if (ref $body eq 'ARRAY') {
		for my $chunk (@$body) {
			$client->print($chunk);
			$request_info->{'response_size'} += length $chunk;
		}
	#} elsif (blessed($body) && $body->can('getline')) {
	#	while (defined(my $chunk = $body->getline)) {
	#		$client->print($chunk);
	#		$request_info->{'response_size'} += length $chunk;
	#	}
	} else {
		while (defined(my $chunk = <$body>)) {
			$client->print($chunk);
			$request_info->{'response_size'} += length $chunk;
		}
	}
}


1;
