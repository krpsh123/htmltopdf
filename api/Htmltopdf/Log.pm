package Htmltopdf::Log;

use strict;
use warnings;

use Log::Dispatch;
use Log::Dispatch::File;
use Log::Dispatch::Screen;
use POSIX qw(strftime);


sub _get_cur_time {
	return strftime "%Y-%m-%d %H:%M:%S", localtime;
}


sub _print {
	my $self = shift;
	my $level = shift;
	my $msg = shift;
	my $time = $self->_get_cur_time;
	
	if ( defined $self->{psgi_env} ) {
		# для psgi
		my $prefix = $self->{psgi_env}->{REMOTE_ADDR};
		$prefix .= ':'. $self->{psgi_env}->{REMOTE_PORT};
		
		$self->{logger}->info("$time [$prefix]: [$level]: $msg");
	} else {
		# для скриптов
		$self->{logger}->info("$time $0: [$$]: [$level]: $msg");
	}
}


sub new {
	my $this = shift;
	my $log_file = shift;
	
	my $class = ref($this) || $this;
	my $self = {};
	bless($self, $class);
	
	# устанавливается когда необходимо из скриптов
	$self->{log_prfx} = undef;
	
	# устанавливается при клиентском запросе
	# это $env psgi приложения
	$self->{psgi_env} = undef;
	
	$self->{debug} = undef;
	$self->{debug} = $Htmltopdf::debug if defined $Htmltopdf::debug;
	
	
	# min_level can be specified by name or by an integer from 0 (debug) to 7 (critical).
	$self->{logger} = Log::Dispatch->new();
	
	$self->{logger}->add(
		Log::Dispatch::File->new(
			'filename' => $log_file, 'mode' => '>>',  'min_level' => 'info', 'newline' => 1
		)
	);
	
	
	if ( $self->{debug} ){
		$self->{logger}->add(
			Log::Dispatch::Screen->new(
				'min_level' => 'info', 'newline' => 1
			)
		);
	}
	
	
	return $self;
}


sub info {
	my $self = shift;
	my $msg = shift;
	
	$self->_print('INFO', $msg);
}

sub err {
	my $self = shift;
	my $msg = shift;
	
	$self->_print('ERROR', $msg);
}

sub fatal_err {
	my $self = shift;
	my $msg = shift;
	
	$self->_print('FATAL_ERROR', $msg);
}

sub warn {
	my $self = shift;
	my $msg = shift;
	
	$self->_print('WARNING', $msg);
}

sub debug {
	my $self = shift;
	my $msg = shift;
	
	$self->_print('DEBUG', $msg);
}


1;
