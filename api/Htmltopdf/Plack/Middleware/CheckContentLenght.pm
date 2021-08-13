package Htmltopdf::Plack::Middleware::CheckContentLenght;

use strict;
use warnings;
use parent qw/Plack::Middleware/;


sub call {
	my ($self, $env) = @_;
	
	
	unless ( exists $env->{CONTENT_LENGTH} ) {
		$env->{'htmltopdf.logger'}->err("Undefined header 'Content-Length'");
		return $self->_send_411;
	}
	
	unless ( $env->{CONTENT_LENGTH} =~ m/^\d+$/) {
		$env->{'htmltopdf.logger'}->err("Header 'Content-Length' must be integer");
		return $env->{'htmltopdf.config'}->responce_400("Header 'Content-Length' must be integer");
	}
	
	if ( $env->{CONTENT_LENGTH} > $self->{max_size} ) {
		$env->{'htmltopdf.logger'}->err("Header 'Content-Length' > $self->{max_size}");
		return $env->{'htmltopdf.config'}->responce_400("Header 'Content-Length' > $self->{max_size}");
	}
	
	return $self->app->($env);
}


sub _send_411 {
	my $self = shift;
	my $body = shift || 'Length Required';
	
	return [ 411,
		[ 'Content-Type' => 'text/plain',
		'Content-Length' => length( $body ) ],
		[ $body ] ];
}


1;
