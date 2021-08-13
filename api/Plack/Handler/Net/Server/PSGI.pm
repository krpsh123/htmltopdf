package Plack::Handler::Net::Server::PSGI;

use strict;
use warnings;
use Net::Server::PSGI::Hook;


sub new {
	my $class = shift;
	my $self = bless { @_ }, $class;
	
	return $self;
}


sub run {
	my($self, $app) = @_;
	
	# Net::Server сам читает @ARGV
	# чтоб не было недорузумений обнулим массив параметров
	local @ARGV = ();
	
	my $server = Net::Server::PSGI::Hook->new({
		port => $self->{port}, # default plackup 5000
		ipv  => 4,
		host => $self->{host},
		server_type => ['Fork'],
		background => $self->{daemonize},
		setsid => $self->{daemonize},
		user => $self->{ns_opt}->{user} || $>,
		group => $self->{ns_opt}->{group} || $),
		# тайм аут на обработку запроса от клиента (по умолчанию 60сек)
		#timeout_idle => 600,
	});
	
	$server->app($app);
	$server->run;
}

1;
