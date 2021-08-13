package Htmltopdf::Plack::Middleware::PostOnly;

use strict;
use warnings;
use Plack::Response;
use parent qw/Plack::Middleware/;


sub call {
	my ($self, $env) = @_;
	
	if ( $env->{REQUEST_METHOD} ne 'POST' ) {
		my $res = Plack::Response->new(405);
		$res->content_type('text/plain');
		$res->header('Allow' => 'POST');
		$res->body("Method Not Allowed\n");
		return $res->finalize;
	}
	
	$self->app->($env);
}


1;
