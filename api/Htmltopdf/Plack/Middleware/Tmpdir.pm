package Htmltopdf::Plack::Middleware::Tmpdir;

use strict;
use warnings;
use parent qw/Plack::Middleware/;

use File::Temp ();
use File::Path qw/remove_tree/;


sub prepare_app {
	my $self = shift;
	
	unless ( -d $self->{unzip_dir} ) {
		mkdir $self->{unzip_dir}, 0755 or die "Connot create dir '$self->{unzip_dir}' ($!)";
	} else {
		# почистим оставшиеся временные дирректории,
		# которые образуются в результате останова или перезапуска psgi приложения
		opendir DIR,  $self->{unzip_dir} or die "Cannot open dir '$self->{unzip_dir}' ($!)";
		while ( my $file = readdir DIR ) {
			next if $file eq '.' or $file eq '..';
			
			if ( -f "$self->{unzip_dir}/$file" ) {
				unlink "$self->{unzip_dir}/$file" or warn "[WARNING]: Cannot delete file '$self->{unzip_dir}/$file' ($!)\n";
			} elsif ( -d "$self->{unzip_dir}/$file" ) {
				remove_tree( "$self->{unzip_dir}/$file", {error => \my $err} );
				if (@$err) {
					warn "[WARNING]: Cannot delete dir '$self->{unzip_dir}/$file'\n";
					
					#for my $diag (@$err) {
					#	my ($file, $message) = %$diag;
					#	if ($file eq '') {
					#		warn "[WARNING]: general error: $message\n";
					#		}
					#	else {
					#		warn "[WARNING]: problem unlinking $file: $message\n";
					#	}
					#}
				}
			} else {
				warn "[WARNING]: Unknown file '$self->{unzip_dir}/$file'\n";
			}
		}
		closedir DIR;
	}
}


sub call {
	my ($self, $env) = @_;
	
	#my $tmp_dir = $self->{unzip_dir}."/".$env->{'htmltopdf.config'}->{uid}->create_str;
	#unless ( mkdir $tmp_dir, 0755 ) {
	#	$env->{'htmltopdf.logger'}->err("Cannot create dir='$tmp_dir' ($!)");
	#	return $env->{'htmltopdf.config'}->responce_500;
	#}
	
	my $template = time."_XXXXXXXXXX";
	my $tmp_dir = eval { File::Temp->newdir( $template, DIR => $self->{unzip_dir}, CLEANUP => 1 ) };
	if ($@) {
		$env->{'htmltopdf.logger'}->err("Cannot create tmp_dir ($@)");
		return $env->{'htmltopdf.config'}->responce_500;
	}
	
	$env->{'htmltopdf.tmp_dir'} = $tmp_dir;
	
	
	if ( $self->{tmpdir_del} ) {
		my $res = $self->app->($env);
		
		# удалим временную директорию
		# это работает, только если модель запуска приложения префорк
		# при модели форкед (на каждый запрос, порождение процесса) и так все удаляется
		$env->{'htmltopdf.tmp_dir'} = undef;
		
		return $res;
	} else {
		return $self->app->($env);
	}
}


1;
