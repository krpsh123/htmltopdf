package Plack::Handler::Net::Server::PSGI;

use strict;
use warnings;
use Net::Server::PSGI::Hook;


sub new {
	my $class = shift;
	return bless { @_ }, $class;
}


sub run {
	my($self, $app) = @_;
	
	# Net::Server reads @ARGV itself
	# so that there are no misunderstandings, we will reset the array of parameters
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
		# timeout for processing a request from the client (default 60s)
		#timeout_idle => 600,
	});
	
	$server->app($app);
	$server->run;
}

1;
