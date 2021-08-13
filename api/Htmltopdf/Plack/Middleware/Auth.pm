package Htmltopdf::Plack::Middleware::Auth;

use strict;
use warnings;
use parent qw/Plack::Middleware/;


sub prepare_app {
	my $self = shift;
	
	
	open(FILE, "<", $self->{acl_file} ) or die "Cannot open acl file='$self->{acl_file}' ($!)";
	
	$self->{tokens} = {};
	while (<FILE>) {
		chomp;
		s/#.*//;
		s/^\s+//;
		s/\s+$//;
		next unless length;
		$self->{tokens}->{$_} = 1;
	}
	
	close FILE;
}


sub call {
	my ($self, $env) = @_;
	
	
	unless ( exists $env->{HTTP_AUTHORIZATION} ) {
		$env->{'htmltopdf.logger'}->err("Undefined header 'Authorization'");
		return $self->_unauthorized;
	}
	
	
	my ($token_type, $token_key) = split(/\s+/, $env->{HTTP_AUTHORIZATION}, 2);
	unless ( defined $token_key ) {
		$env->{'htmltopdf.logger'}->err("Invalid header 'Authorization' (current_val='$env->{HTTP_AUTHORIZATION}')");
		return $self->_unauthorized;
	}
	
	
	if ( exists $self->{tokens}->{$token_key} ) {
		return $self->app->($env);
	} else {
		$env->{'htmltopdf.logger'}->err("token='$token_key' not found in acl file='$self->{acl_file}'");
		return $self->_unauthorized;
	}
}



sub _unauthorized {
	my $self = shift;
	my $body = shift || 'Authorization required';
	
	return [ 401,
		[ 'Content-Type' => 'text/plain',
		'Content-Length' => length( $body ) ],
		[ $body ] ];
}


1;
