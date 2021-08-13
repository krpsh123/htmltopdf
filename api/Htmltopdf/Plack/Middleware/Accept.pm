package Htmltopdf::Plack::Middleware::Accept;

use strict;
use warnings;
use parent qw/Plack::Middleware/;

#use Plack::Request;


sub call {
	my ($self, $env) = @_;
	
	# default no jpg format
	$env->{'htmltopdf.jpg'} = 0;
	
	
	if ( exists $env->{HTTP_ACCEPT} and defined $env->{HTTP_ACCEPT} ) {
		
		my $accept_pattern = qr!^(\*|(\w+))(/([-+.*\w]+))?(;\s*.*)?$!;
		
		# обрабатываем только первый из списка
		# например пришел такой Accept: text/html, application/xhtml+xml, application/xml;q=0.9, */*;q=0.8
		# мы обработаем только text/html, остальные отбросим
		for my $token ( split /,\s*/, $env->{HTTP_ACCEPT} ) {
			#print "token: $token\n";
			
			if ( $token =~ m!$accept_pattern! ) {
				my $type = $1;
				my $subtype = defined($4) ? $4 : undef;
				#print "type: $type; subtype: $subtype\n";
				if ( defined $type and $type eq 'image' and defined $subtype and $subtype eq 'jpeg' ) {
					$env->{'htmltopdf.jpg'} = 1;
				}
			} else {
				$env->{'htmltopdf.logger'}->info( "HTTP header Accept invalid: $token (full Accept: $env->{HTTP_ACCEPT})" );
			}
			last;
		}
	}
	
	
	return $self->app->($env);
}


1;
