package Htmltopdf;

use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;

use Plack::Builder;
use Plack::Response;
use IO::File;

use Htmltopdf::Config;
use Htmltopdf::Log;
use Htmltopdf::Handler;


####### VERSION #######
our $VERSION = '3.3.0';
#######################


our $debug = undef;
if  ( $ENV{PLACK_ENV} =~ m/^development$/ ) {
	$debug = 1;
	require Data::Dumper;
}


chdir $ENV{HOME} or die "[ERROR]: Cannot cd home dir=$ENV{HOME} ($!)\n";


###------config-----------------------
my $config = Htmltopdf::Config->new;
my $general_var = $config->get_general_var;

unless ( -d $general_var->{log_dir} ) {
	mkdir $general_var->{log_dir}, 0755 or die "[ERROR]: Connot create dir '$general_var->{log_dir}' ($!)\n";
}

my $log = Htmltopdf::Log->new( $general_var->{log_file_psgi} );
$log->info("start Htmltopdfd; version=$VERSION; config=$general_var->{conf_file}");


$config->read_conf_file( $general_var->{conf_file} );
if ( $config->{errstr} ) {
	$log->err("$config->{errstr}");
	$log->info("stop Htmltopdfd");
	
	warn "[ERROR]: $config->{errstr}\n";
	warn "stop Htmltopdfd\n";
	
	exit 1;
}
#print Data::Dumper::Dumper($config->{cnf});
#exit;
###-----------------------------------


my $default_app = sub {
	my $env = shift;
	
	my $res = Plack::Response->new(404);
	$res->content_type('text/plain');
	$res->body("Not found (default app)");
	return $res->finalize;
};


my $htmltopdf = sub {
	my $env = shift;
	
	
	# ОБработчик (приложение)
	my $hdl = eval { Htmltopdf::Handler->new($env) };
	if ($@) {
		chomp $@;
		$env->{'htmltopdf.logger'}->err( "http reply: $@" );
		return $env->{'htmltopdf.config'}->responce_500( $@ );
	}
	
	
	# если будет 500 ошибка, то умрет по die
	# если будет 400 ошибка, то вернет undef
	my $body = eval { $hdl->run };
	if ($@) {
		chomp $@;
		$env->{'htmltopdf.logger'}->err( "http reply: $@" );
		return $env->{'htmltopdf.config'}->responce_500( $@ );
	}
	unless ($body) {
		$env->{'htmltopdf.logger'}->err( "http reply: $hdl->{errstr}" );
		return $env->{'htmltopdf.config'}->responce_400( $hdl->{errstr} );
	}
	
	
	###-------- response -------------
	my $out_file = IO::File->new( $body, '<' );
	unless ( defined $out_file ) {
		$env->{'htmltopdf.logger'}->err( "http reply: Cannot open file '$body' ($!)" );
		return $env->{'htmltopdf.config'}->responce_500( "Cannot open file '$body' ($!)" );
	}
	
	
	my $res = Plack::Response->new(200);
	my $filename = $env->{'htmltopdf.urlparam'}->{'filename'};
	
	if ( $env->{'htmltopdf.jpg'} ) {
		if ( $body =~ m/\.jpg$/ ) {
			$res->content_type('image/jpeg');
			$filename .= '.jpg';
		} else {
			$res->content_type('application/zip');
			$filename .= '.zip';
		}
	} else {
		$res->content_type('application/pdf');
		$filename .= '.pdf';
	}
	
	$res->header('Content-Disposition' => "attachment; filename=\"$filename\"");
	$res->body( $out_file );
	return $res->finalize;
	###-------------------------------
};



###---------main----------------------
builder {
	
	enable "Plack::Middleware::ContentLength";
	
	mount "/htmltopdf" => builder {
		
		# только POST метод
		enable "+Htmltopdf::Plack::Middleware::PostOnly";
		
		enable "+Htmltopdf::Plack::Middleware::Config",
			config      => $config,
			general_var => $general_var,
			log         => $log,
		
		# проверка заголовка Content-Length в запросе
		enable "+Htmltopdf::Plack::Middleware::CheckContentLenght", max_size => $general_var->{max_size_upload_file};
		
		enable "+Htmltopdf::Plack::Middleware::Auth", acl_file => $general_var->{acl_file};
		
		enable "+Htmltopdf::Plack::Middleware::Tmpdir", unzip_dir => $general_var->{unzip_dir}, tmpdir_del => 1;
		
		enable "+Htmltopdf::Plack::Middleware::URLparams";
		
		enable "+Htmltopdf::Plack::Middleware::Accept";
		
		$htmltopdf;
	};
	
	mount "/" => builder {
		$default_app;
	};
};
