package Htmltopdf::Config;

use strict;
use warnings;
use Config::Tiny;


sub new {
	my $this = shift;
	
	my $class = ref($this) || $this;
	my $self = {};
	bless($self, $class);
	
	$self->{debug} = undef;
	$self->{debug} = $Htmltopdf::debug if defined $Htmltopdf::debug;
	
	# устанавливаются из методов модуля
	$self->{errstr} = undef;
	# валидный конфиг файл
	$self->{cnf} = undef;
	
	return $self;
}


sub get_general_var {
	my $self = shift;
	my $work_dir = "$ENV{HOME}/api";
	my $log_dir = "$work_dir/log";
	
	$self->{errstr} = undef;
	
	my %hash_general_var = (
		'work_dir' => $work_dir,
		'conf_file' => "$work_dir/htmltopdf.conf",
		'acl_file' => "$work_dir/acl.conf",
		
		# if change this parametr
		# change logrotate file htmltopdf.logrotate
		'log_dir' => "$log_dir",
		'log_file_psgi' => "$log_dir/api.log",
		
		# unzip dir
		'unzip_dir' => "$work_dir/unzipping",
		
		# tmp input file
		'tmp_in_file' => 'input.zip',
		# tmp output file
		'tmp_out_file' => 'output.pdf',
		
		# wkhtmltopdf
		'wkhtmltopdf' => "/usr/local/bin/wkhtmltopdf",
		
		# максимальный размер принимаемого файла (zip архива)
		# определяется по заголовку Content-Length
		max_size_upload_file => 1024 * 100000,
		
		# ghostscript
		'gs_bin' => -e '/bin/gs' ? '/bin/gs' : '/usr/bin/gs',
		
		# exiftool
		'exiftool_bin' => -e '/bin/exiftool' ? '/bin/exiftool' : '/usr/bin/exiftool',
	);
	
	return \%hash_general_var;
}


sub responce_500 {
	my $self = shift;
	my $body = shift || 'Internal Server Error';
	
	return [ 500,
		[ 'Content-Type' => 'text/plain'],
		[ $body ] ];
}


sub responce_400 {
	my $self = shift;
	my $body = shift || 'Bad Request';
	
	return [ 400,
		[ 'Content-Type' => 'text/plain' ],
		[ $body ] ];
}


sub get_version {
	my $self = shift;
	return "$Htmltopdf::VERSION\n" if defined $Htmltopdf::VERSION;
	
	my $version = '0.0.0';
	my $general_var = $self->get_general_var;
	# TODO: вместо app.psgi можно анализировать ключь -a, --app у plackup или первый аргумент у plackup
	if ( open FILE, "<", "$general_var->{work_dir}/app.psgi" ) {
		while (<FILE>) {
			chomp;
			if ($_ = m/^\s*our\s*\$VERSION\s*=\s*'(.+)'/) {
				$version = $1;
				last;
			}
		}
		close FILE;
	}
	
	return $version;
}


sub read_conf_file {
	my $self = shift;
	my $file = shift;
	
	$self->{errstr} = undef;
	
	$self->{cnf} = Config::Tiny->read($file);
	if ( $Config::Tiny::errstr ) {
		$self->{errstr} = $Config::Tiny::errstr;
		return undef;
	}
	
	return $self->_valid_config_param;
}


sub _valid_config_param {
	my $self = shift;
	$self->{errstr} = undef;
	
	my $prf = "Config invalid:";
	
	if ( !defined $self->{cnf} ) {
		$self->{errstr} = "$prf undefined config file";
		return undef;
	}
	
	if ( ref $self->{cnf} ne 'Config::Tiny' ) {
		$self->{errstr} = "$prf config file ne Config::Tiny";
		return undef;
	}
	
	# главная секция не имеющая название
	if ( ! defined $self->{cnf}->{_} ) {
		$self->{errstr} = "$prf undefined '_' section";
		return undef;
	}
	
	if ( ref $self->{cnf}->{_} ne 'HASH' ) {
		$self->{errstr} = "$prf section '_' ne HASH";
		return undef;
	}
	
	if ( !defined $self->{cnf}->{_}->{jpg_resolution} ) {
		$self->{errstr} = "$prf undefined param 'jpg_resolution'";
		return undef;
	} elsif ( $self->{cnf}->{_}->{jpg_resolution} !~ m/^\d+$/ ) {
		$self->{errstr} = "$prf param 'jpg_resolution' must be integer";
		return undef;
	} elsif ( $self->{cnf}->{_}->{jpg_resolution} < 2 or $self->{cnf}->{_}->{jpg_resolution} > 1000 ) {
		$self->{errstr} = "$prf param 'jpg_resolution' < 2 or > 1000";
		return undef;
	}
	
	return 1;
}

1;
