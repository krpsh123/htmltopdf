package Htmltopdf::Plack::Middleware::URLparams;

use strict;
use warnings;
use parent qw/Plack::Middleware/;

use Plack::Request;


sub prepare_app {
	my $self = shift;
	
	
	$self->{default_param} = { 'orientation' => 'Portrait', 'filename' => 'output' };
}


sub call {
	my ($self, $env) = @_;
	my $urlparam = {};
	
	my $req = Plack::Request->new($env);
	my $param = $req->query_parameters;
	
	
	# orientation
	$urlparam->{'orientation'} = $self->{default_param}->{'orientation'};
	if ( defined $param->get('orientation') && $param->get('orientation') =~ m/^Landscape$/ ) {
		$urlparam->{'orientation'} = 'Landscape';
	}
	
	
	# filename
	$urlparam->{'filename'} = $self->{default_param}->{'filename'};
	if ( defined $param->get('filename') && $param->get('filename') =~ m/^\s*(\w+)\s*$/ ) {
		$urlparam->{'filename'} = $1;
	}
	
	
	$env->{'htmltopdf.urlparam'} = $urlparam;
	
	
	return $self->app->($env);
}


1;
