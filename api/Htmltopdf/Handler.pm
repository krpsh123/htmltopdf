package Htmltopdf::Handler;

use strict;
use warnings;

use Archive::Zip;
use Capture::Tiny qw/capture/;
use PDF::Tiny;


sub _get_html_file {
	my $self = shift;
	my $dir = shift;
	
	$self->{errstr} = undef;
	my @html_files;
	
	
	opendir DIR, $dir or return ["Cannot open dir '$dir' ($!)"];
	
	while ( my $file = readdir DIR ) {
		next if $file eq '.' or $file eq '..';
		
		if ( -f "$dir/$file" ) {
			push @html_files, $file if $file =~ m/.+\.html$/;
		}
	}
	
	closedir DIR;
	
	
	if ( scalar @html_files == 0 ) {
		return ["Cannot find the printed form ('*.html' file in the zip archive)"];
	} elsif ( scalar @html_files > 1 ) {
		return ["The printed form ('*.html' file in the zip archive) > 1"];
	} else {
		return $html_files[0];
	}
}


sub new {
	my $this = shift;
	
	
	my $class = ref($this) || $this;
	my $self = {};
	bless($self, $class);
	
	# psgi env
	$self->{env} = shift;
	
	$self->{debug} = undef;
	$self->{debug} = $Htmltopdf::debug if defined $Htmltopdf::debug;
	
	# очищать meta информацию из pdf файла
	$self->{clean_meta_pdf} = 1;
	
	# очищать meta информацию из jpg файла
	$self->{clean_meta_jpg} = 1;
	
	# устанавливаются из методов модуля
	$self->{errstr} = undef;
	
	# установим обработчик ошибок
	Archive::Zip::setErrorHandler( sub {die "Archive::Zip error: @_"} );
	
	return $self;
}


sub run {
	my $self = shift;
	$self->{errstr} = undef;
	
	
	###--------- upload --------------
	my $tmp_input_file = "$self->{env}->{'htmltopdf.tmp_dir'}/$self->{env}->{'htmltopdf.gen_var'}->{tmp_in_file}";
	open FILE, ">:raw", $tmp_input_file or die "Cannot create file '$tmp_input_file' ($!)";
	
	# считаем архив во временный файл
	#
	# вот так не заработало при использовании Net::Server::PSGI (просто висло)
	# при Net::Server::PSGI метод read должен считывать столько байт, сколько есть на самом деле
	#
	# при других серверах все ок
	#
	#while ( $env->{'psgi.input'}->read( $buf, 8192 ) ) {
	#	print FILE $buf;
	#}
	#
	my $buf;
	my $chunksize = 64 * 1024; # взял из Starman https://metacpan.org/source/MIYAGAWA/Starman-0.4014/lib/Starman/Server.pm
	my $cl = $self->{env}->{CONTENT_LENGTH};
	#print "cl=$cl\n";
	if ( $cl <= $chunksize ) {
		$self->{env}->{'psgi.input'}->read( $buf, $cl );
		print FILE $buf;
	} else {
		my $count_i = sprintf('%d', $cl/$chunksize);
		for ( my $i = 0; $i < $count_i; $i++) {
			$self->{env}->{'psgi.input'}->read( $buf, $chunksize );
			print FILE $buf;
		}
		$self->{env}->{'psgi.input'}->read( $buf, $cl - $chunksize * $count_i );
		print FILE $buf;
	}
	
	close FILE;
	###-------------------------------
	
	
	###----------- unzip -------------
	my $zip = Archive::Zip->new;
	$zip->read( $tmp_input_file );
	$zip->extractTree( undef, "$self->{env}->{'htmltopdf.tmp_dir'}/" );
	undef $zip;
	###-------------------------------
	
	
	###-------htmltopdf---------------
	my $pdf_output_file = "$self->{env}->{'htmltopdf.tmp_dir'}/$self->{env}->{'htmltopdf.gen_var'}->{tmp_out_file}";
	
	# найдем файл с расширением .html, который должен быть в корне архива в единственном экземпляре
	# его и передаем для html_to_pdf преобразования
	# вернется имя файла
	# или ссылка на массив, в котором первым членом будет сообщение об ошибке
	my $html_file = $self->_get_html_file( $self->{env}->{'htmltopdf.tmp_dir'} );
	if ( ref $html_file eq 'ARRAY' ) {
		$self->{errstr} = $html_file->[0];
		return undef;
	}
	
	my @wf_args = ("--orientation", "$self->{env}->{'htmltopdf.urlparam'}->{'orientation'}");
	push @wf_args, ("--margin-bottom", 0);
	push @wf_args, ("--margin-left", 0);
	push @wf_args, ("--margin-right", 0);
	push @wf_args, ("--margin-top", 0);
	push @wf_args, "$self->{env}->{'htmltopdf.tmp_dir'}/$html_file";
	push @wf_args, ("--encoding", "UTF-8");
	push @wf_args, ("--disable-javascript");
	push @wf_args, $pdf_output_file;
	
	
	my ($wf_out, $wf_err, $wf_exit_code) = capture {
		system( $self->{env}->{'htmltopdf.gen_var'}->{wkhtmltopdf}, @wf_args );
	};
	
	if ( $wf_exit_code != 0 ) {
		my @err = split /\n/, $wf_err;
		die "$self->{env}->{'htmltopdf.gen_var'}->{wkhtmltopdf} ($err[0])";
	}
	###-------------------------------
	
	
	###---- post create pdf hook------
	if ( $self->{clean_meta_pdf} == 0 and $self->{env}->{'htmltopdf.jpg'} == 0 ) {
		return $pdf_output_file;
	} elsif ( $self->{clean_meta_pdf} == 1 and $self->{env}->{'htmltopdf.jpg'} == 0 ) {
		return $self->_pdf_clean_metainfo( $pdf_output_file );
	} elsif ( $self->{clean_meta_pdf} == 0 and $self->{env}->{'htmltopdf.jpg'} == 1 ) {
		return $self->_pdf_to_jpg( $pdf_output_file );
	} else {
		# $self->{clean_meta_pdf} == 1 and $self->{env}->{'htmltopdf.jpg'} == 1
		my $pdf_no_metainfo =  $self->_pdf_clean_metainfo( $pdf_output_file );
		return $self->_pdf_to_jpg( $pdf_no_metainfo );
	}
}


# удаляет метаинформацию из pdf файла
sub _pdf_clean_metainfo {
	my $self = shift;
	my $pdf_file_in = shift;
	$self->{errstr} = undef;
	
	my $pdf_file_no_metainfo = $pdf_file_in.'.pdf';
	my $pdf = PDF::Tiny->new($pdf_file_in);
	
	# получим info объект с метаинформацией из pdf файла
	# вернет undef, если не найдет объект
	my $info = $pdf->get_obj( $pdf->trailer->[1]->{Info}->[1] );
	unless ($info) {
		undef $pdf;
		return $pdf_file_in;
	}
	
	# бежим по списку тегов обнуляя их
	while ( my ($tag, undef) = each %{$info->[1]} ) {
		next if $tag eq 'CreationDate';
		$pdf->vivify_obj('str', '/Info', "/$tag")->[1] = '';
	}
	
	# сохраняем изменения в новый файл
	$pdf->print(filename => $pdf_file_no_metainfo);
	
	# почистим за собой
	undef $pdf;
	unlink $pdf_file_in;
	
	return $pdf_file_no_metainfo;
}

sub _pdf_to_jpg {
	my $self = shift;
	my $pdf_file_in = shift;
	$self->{errstr} = undef;
	
	my $jpg_output_file = $self->{env}->{'htmltopdf.tmp_dir'}.'/'.'gs_output_file_%d.jpg';
	my @gs_args = ('-dNOPAUSE');
	push @gs_args, ('-sDEVICE=jpeg');
	push @gs_args, ('-sOutputFile='.$jpg_output_file);
	push @gs_args, ('-dJPEGQ=90');
	push @gs_args, ('-r'.$self->{env}->{'htmltopdf.jpg_resolution'});
	push @gs_args, ('-q');
	push @gs_args, ($pdf_file_in);
	push @gs_args, ('-c', 'quit');
	
	my ($gs_out, $gs_err, $gs_exit_code) = capture {
		system( $self->{env}->{'htmltopdf.gen_var'}->{gs_bin}, @gs_args );
	};
	
	if ( $gs_exit_code != 0 ) {
		my @err = split /\n/, $gs_out;
		die "$self->{env}->{'htmltopdf.gen_var'}->{gs_bin} ($err[0])";
	}
	
	# определим кол-во образовавшихся jpg файлов
	# readdir выводит файлы в хаотичном порядке
	# нам же надо упаковать jpg файлы в архив так, чтобы номер файла соответствовал номеру страницы из pdf
	opendir DIR, $self->{env}->{'htmltopdf.tmp_dir'} or die "can't opendir $self->{env}->{'htmltopdf.tmp_dir'}: $!";
	my %jpg_files;
	while ( defined(my $file = readdir(DIR)) ) {
		$jpg_files{$1} = $file if $file =~ m/gs_output_file_(\d+)\.jpg$/;
	}
	closedir DIR;
	
	my $count_jpg_files =  scalar keys %jpg_files;
	if ( $count_jpg_files == 0 ) {
		die "Cannot search jpg files";
	} elsif ( $count_jpg_files == 1 ) {
		
		# удалим мета инфу из jpg файла
		if ( $self->{clean_meta_jpg} ) {
			$self->_jpg_clean_metainfo( $self->{env}->{'htmltopdf.tmp_dir'}.'/'.$jpg_files{1} );
		}
		
		return $self->{env}->{'htmltopdf.tmp_dir'}.'/'.$jpg_files{1};
	} else {
		# jpg файлов образовалось много и надо их упаковать в zip архив
		my $zip_output_file = $self->{env}->{'htmltopdf.tmp_dir'}.'/'.'output.zip';
		
		# удалим мета инфу из jpg файлов
		if ( $self->{clean_meta_jpg} ) {
			for ( sort {$a <=> $b} keys %jpg_files ) {
				$self->_jpg_clean_metainfo( $self->{env}->{'htmltopdf.tmp_dir'}.'/'.$jpg_files{$_} );
			}
		}
		
		# для упаковки файлов надо перейти в директорию с jpg файлами
		chdir $self->{env}->{'htmltopdf.tmp_dir'} or die "Cannot cd $self->{env}->{'htmltopdf.tmp_dir'}";
		
		my $zip = Archive::Zip->new;
		for ( sort {$a <=> $b} keys %jpg_files ) {
			$zip->addFile( $jpg_files{$_}, $self->{env}->{'htmltopdf.urlparam'}->{'filename'}. '_'. $_ . '.jpg' );
		}
		$zip->writeToFileNamed($zip_output_file);
		undef $zip;
		
		# вернемся в рабочий каталог
		chdir $self->{env}->{'htmltopdf.gen_var'}->{work_dir} or die "Cannot cd $self->{env}->{'htmltopdf.gen_var'}->{work_dir}";
		
		return $zip_output_file;
	}
}


# удаляет метаинформацию из jpg файла
# заменяет переданный файл
sub _jpg_clean_metainfo {
	my $self = shift;
	my $jpg_file_in = shift;
	$self->{errstr} = undef;
	
	#warn $jpg_file_in;
	
	# удаляем все icc профили (цветовые профили)
	# этот параметр весьма интересен - это профиль прикрепляется к изображению и говорит о том, как надо показывать цвета из этого изображения.
	# он в большей степени важен для полиграфии
	# я так понял, что если профиля не будет у изображения, то операционная система (просмоторщик изображений) применит свой профиль по умолчанию
	# поэтому мы можем без проблем удалять его
	my ($exif_out, $exif_err, $exif_exit_code) = capture {
		system( $self->{env}->{'htmltopdf.gen_var'}->{exiftool_bin}, ('-icc_profile=', $jpg_file_in) );
	};
	
	# unix like exit code
	if ( $exif_exit_code ) {
		my @err = split /\n/, $exif_err;
		die "$self->{env}->{'htmltopdf.gen_var'}->{exiftool_bin} ($err[0])";
	}
	
	return 1;
}


1;
