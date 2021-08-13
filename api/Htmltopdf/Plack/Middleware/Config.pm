package Htmltopdf::Plack::Middleware::Config;

use strict;
use warnings;
use parent qw/Plack::Middleware/;


sub prepare_app {
	my $self = shift;
	
	unless ( -e $self->{general_var}->{wkhtmltopdf} ) {
		die "[ERROR]: Cannot find $self->{general_var}->{wkhtmltopdf}";
	}
}


sub call {
	my ($self, $env) = @_;
	
	# подсчет времени выполнения
	$env->{'htmltopdf.req_start'} = time;
	
	$env->{'htmltopdf.config'} = $self->{config};
	$env->{'htmltopdf.gen_var'} = $self->{general_var};
	$env->{'htmltopdf.jpg_resolution'} = $self->{config}->{cnf}->{_}->{jpg_resolution};
	
	
	$env->{'htmltopdf.logger'} = $self->{log};
	$env->{'htmltopdf.logger'}->{psgi_env} = { REMOTE_ADDR => $env->{REMOTE_ADDR}, REMOTE_PORT => $env->{REMOTE_PORT} };
	
	
	my $res = $self->app->($env);
	
	
	# запишем в лог удачное подключение
	if ( $res->[0] == 200 ) {
		my $delay = time - $env->{'htmltopdf.req_start'};
		$env->{'htmltopdf.logger'}->info( "OK; delay=$delay" );
	}
	
	
	return $res;
}


1;
