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


# можно включить этот метод, если версия Net::Server::PSGI > 2.007
#sub process_request {
#	my $self = shift;
#	
#	# по умолчанию Net::Server::PSGI не создает SERVER_NAME
#	# строку взял из Starman (https://metacpan.org/source/MIYAGAWA/Starman-0.4014/lib/Starman/Server.pm#)
#	# если ее не будет, то Plack::Middleware::Lint будет ругатся и приложение не будет работать
#	$ENV{'SERVER_NAME'} = $self->{server}->{sockaddr} || 0; # XXX: needs to be resolved?
#	
#	$self->SUPER::process_request;
#}


# этот метод полностью скопирован из Net::Server::PSGI версии 2.008
# добавлено определение двух переменных окружения SERVER_NAME и SERVER_PROTOCOL
sub process_request {
	my $self = shift;
	
	# for debug
	#use Data::Dumper;
	#print Dumper $self;
	
	local $SIG{'ALRM'} = sub { die "Server Timeout\n" };
	my $ok = eval {
		alarm($self->timeout_header);
		$self->process_headers;
		
		
		# по умолчанию Net::Server::PSGI не создает SERVER_NAME
		# строку взял из Starman (https://metacpan.org/source/MIYAGAWA/Starman-0.4014/lib/Starman/Server.pm#)
		# если ее не будет, то Plack::Middleware::Lint будет ругатся и приложение не будет работать
		unless ( defined $ENV{'SERVER_NAME'} ) {
			$ENV{'SERVER_NAME'} = $self->{server}->{sockaddr} || 0; # XXX: needs to be resolved?
		}
		
		
		# Net::Server::PSGI до версии 2.008 не создает SERVER_PROTOCOL
		unless ( defined $ENV{'SERVER_PROTOCOL'} ) {
			$ENV{'SERVER_PROTOCOL'} = 'UNKNOWN';
			if ( defined $self->http_request_info->{request} ) {
				if ( $self->http_request_info->{request} =~ m{ ^\s*(GET|POST|PUT|DELETE|PUSH|HEAD|OPTIONS)\s+(.+)\s+(HTTP/1\.[01])\s*$ }ix ) {
					$ENV{'SERVER_PROTOCOL'} = $3;
				}
			}
		}
		
		
		alarm($self->timeout_idle);
		my $env = \%ENV;
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



# Net::Server::PSGI использует функцию blessed при этом он забыл ее подгрузить из модуля Scalar::Util
# если тело ответа не массив (а например дескриптор файла), то валится с ошибкой
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
