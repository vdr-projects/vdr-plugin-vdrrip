#!/usr/bin/perl

#
#  vdrsync (c) 2003 by  Dr. Peter Sebbel, a perl script to demux VDR recordings and 
#  correcting for missing/additional  Audio frames to ensure sync of audio and 
#  video streams. Contact: peter@vdr-portal.de
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; version 2 of the License
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA



use strict;
use warnings;



my $debug          = 0;
my $path_param     = "./";
my @parameter_list = @ARGV;
my $tcmplex        = "";
my $tcmplex_panteltje= "";
my $panteltje       = 0; #uses tcmplex-panteltje instead of tcmplex
my $mplex          = 0;
my $mpeg2          = 0;
my $transcode      = 0;
my $info           = 0;
my $remuxfilename  = ""; 
my @ignore_streams;
my $dump_packets   = 0;
my $dump_payload   = 0;
my $stop_flag      = 0;
my $audio_only 	   = 0;
my $script_output  = 0;
my $divx   	   = 0;
my $divxac3        = 0;
my $divx_param     = " -V -y divx4 -w 1000 "; #enter additional parameters for divx here
my $divx_ac3_param = " -V -y divx4 -b 256 -w 1000 "; #enter additional parameters for divx with ac3 sound here
my $master_dvd     = 0;
my $master_dvd_param  = "-c 0,10:00,20:00,30:00,40:00,50:00,01:00:00,01:10:00,01:20:00,01:30:00,01:40:00,01:50:00,02:00:00,02:10:00,02:20:00,02:30:00,02:40:00,02:50:00,03:00:00";
my $show_drift	   = 0;
my $postexec       = 0;
my $dump_buffer    = 0;
my $mkiso	   = 0;


$|=1; # prevent line buffering
if (-e "/usr/bin/tcmplex")	{
	$tcmplex = "/usr/bin/tcmplex";
}
elsif (-e "/usr/local/bin/tcmplex")	{
	$tcmplex = "/usr/local/bin/tcmplex";
}
if (-e "/vdr/bin/tcmplex-panteltje"){
	$tcmplex_panteltje = "/vdr/bin/tcmplex-panteltje";
}
elsif (-e "/usr/local/bin/tcmplex-panteltje")	{
	$tcmplex_panteltje = "/usr/local/bin/tcmplex-panteltje";
}
elsif (-e "/usr/bin/tcmplex-panteltje")	{
	$tcmplex_panteltje = "/usr/bin/tcmplex-panteltje";
}

if (-e "/usr/bin/transcode") {
	$transcode = "/usr/bin/transcode";
}
elsif (-e "/usr/local/bin/transcode") {
	$transcode = "/usr/local/bin/transcode";
}
 

sub parse_parameters {
	my $parameter = shift;
	if ($parameter eq "-d") {
		$debug = 1;
	}
	elsif ($parameter eq "-o")	{
		$path_param = shift @parameter_list;
		if (!($path_param =~ /\/$/)) {
			$path_param .= "/";
		}
	}
	elsif ($parameter eq "-m")	{
		$mplex = 1;
		if ($parameter_list[0] && ($parameter_list[0] eq "panteltje")){
			$panteltje = (shift @parameter_list);
		} 
	}
    elsif ($parameter eq "-mpeg2") {
		$mpeg2 = 1;
		$master_dvd = 0;
		$mplex = 1;
		$mkiso = 0;
	}
	elsif ($parameter eq "-i")	{
		$info = 1;
	}
	elsif ($parameter eq "-ignore")	{
		 @ignore_streams = split /,/,(shift @parameter_list);
	}
	elsif ($parameter eq "-dump-packets"){
		$dump_packets = (shift @parameter_list);
	}
	elsif ($parameter eq "-show-time-drift"){
		$show_drift = 1;
	}
	elsif ($parameter eq "-dump-buffer-on-error"){
		$dump_buffer = 1;
	}
	elsif ($parameter eq "-dump-payload"){
		$dump_payload = (shift @parameter_list);
	}
	elsif ($parameter eq "-audio-only")	{
		$audio_only = 1;
	}
	elsif ($parameter eq "-script-output")	{
		$script_output = 1;
	}
	elsif ($parameter eq "-divx") {
		$divx = 1;
		if ($parameter_list[0] eq "ac3"){
			$divxac3 = (shift @parameter_list);
		}
	}
	elsif ($parameter eq "-master-dvd"){
		$master_dvd = 1;
		$mplex = 1;
		if ( ! $parameter_list[0] =~/^-/ ){
			$master_dvd_param = (shift @parameter_list);
		}
	}
	elsif ($parameter eq "-mkiso"){
		$mkiso = 1;
		$mplex = 1;
		$master_dvd = 1;
	}
	elsif ($parameter eq "-postexec"){
		$postexec  = (shift @parameter_list);
	}
	else {
		print "Unknown parameter $parameter\n";
		exit;
	}
}

my @files;
if (scalar(@ARGV) == 0) 
	{
	print "\nVDRsync    Version 0.1.2.2\n";
	print "\nUsage:     vdrsync.pl /path/to/vdr/recording/\n";
	print "or   :     vdrsync.pl vdr-file1 .... vdr-fileN\n\n";
	print "Optional  -d print strange debug messages\n";
	print "Optional  -o output_dir sets the directory where the result files\n";
	print "           are written to\n";
	print "Optional  -m tries to multiplex the demuxed streams into a dvd compatible\n";
	print "           stream (uses tcmplex)\n";
	print "Optional  -m panteltje uses tcmplex-panteltje instead of tcmplex\n";
	print "Optional  -i just tries to analyse the .vdr file and exits. -m is ignored\n";
	print "Optional  -ingore stream1[,stream2]...  tells the script to ignore  stream1..n \n"; 
	print "           Useful for deliberately omitting streams (like AC3) or if you have \n";
	print "           trouble with one stream\n";
	print "Optional  -divx tries to transcode the demuxed streams into a divx movie\n";
	print "           For DIVX with AC3 (if present in the recording)  type -divx ac3\n";
	print "           (uses transcode, adjust transcode settings at the beginning of\n";
	print "           vdrsync.pl)\n";
	print "Optional  -dump-packets NNNN tells the script to dump  the first NNNN\n";
	print "           full PES-packets (in file STREAM_ID.pes_dump) Useful for debugging \n"; 
	print "           (if you want to extract a stream that does not work and mail it to me)\n";
	print "Optional  -dump-payload NNNN tells the script to dump the raw payload of the \n";
	print "           first NNNN PES-packets (in file STREAM_ID.dump) Useful for debugging\n"; 
	print "           (if you want to extract a stream-payload that does not work and \n";
	print "           test it with other tools)\n";
	print "Optional  -postexec executes the command specified after finishing\n";
	#print "           some Dummy variables like VSlength are replaced by actual values \n";
	print "Optional  -master-dvd  creates a DVD structure in a subdirectory of outputpath\n";
	print "Optional  -audio-only discards all video streams and just writes audio\n";
	print "Optional  -script-output writes a special output format about the movie at\n";
	print "           the end of the vdrsync run. Useful for scripting, contains corrected \n";
	print "           info about the streams\n";
	print "Optional  -show-time-drift prints information about the difference between\n";
	print "           timestamps and actual video / audio data found in the recording\n";
	print "Optional  -dump-debug-buffer in case of a problem with one of the streams 3 MB\n";
	print "           of the recording are dumped to the file debug.buffer\n";
	print "Optional  -mkiso creates an ISO Image suitable for burning a DVD\n";
	print "Optional  -mpeg2 creates a generic MPEG2 File (tcmplex -m 2)\n";
	exit;
	} 


while (my $param = shift(@parameter_list))  { # check whether all files hat we got as parameters exist 
	print "Got parameter $param\n";
	if ($param =~ /^-/) {parse_parameters($param); next}
	if (-d $param)	{
		print "got a directory on the command line\n";
		my @dir_files = @{ get_file_list($param) };
		foreach (@dir_files) {
			push @files, "$param/$_";
		}
		next;
	}
	push @files, $param;
}

print "Output files will be stored in $path_param\n" if $debug;

if (!(-e $path_param)) {print "Output Directory $path_param does not exist\n"; exit 1}



print "Found " . (scalar(@ignore_streams)) ." to ignore\n" if $debug;

my %ignore_hash;
foreach (@ignore_streams) {
	$ignore_hash{$_} = 1;
}


my $PES_Obj = MPEGSTREAM->new
		(
		streamcode	=>"PES_stream", 
		debug		=>$debug, 
		outputpath	=>$path_param, 
		files		=>\@files, 
		ignore_streams 	=> \%ignore_hash,
		dump_packets	=> $dump_packets,
		dump_payload	=> $dump_payload,
		audio_only      => $audio_only,
		show_drift      => $show_drift,
		script_output   => $script_output,
		dump_buffer	    => $dump_buffer,
		);

if (!($PES_Obj)) {
	print "could not create the PES Stream Obj\n";
	exit 1;
}
if ($info) {
	$PES_Obj->print_stats();
	exit;
}


$PES_Obj->process_PES_packets();


if ((!$mplex) && (!$divx ) && (! $postexec) && (! $master_dvd)) {exit}

my @filestomux = @{$PES_Obj->output_files()};

print "Got " . scalar(@filestomux) ." files back\n" if $debug;

my @basename_list;
foreach (@filestomux) {
	my $base_name = (split /\//,$_)[-1];
	$base_name =~ s/\.//;
	push @basename_list, $base_name;
}

if ($divx == 1) {
 	if (scalar(@filestomux) < 2) {print "Need at least two streams for multiplexing\n";exit}
	if (($filestomux[1] =~ /.ac3$/) && ($divxac3)) {
		#transcode -i e0.mpv -A -N 0x2000 -p bd.ac3  -y divx4 -o test.avi
		my $command = "nice -19 $transcode -i $filestomux[0] -A -N 0x2000 -p $filestomux[1]  ";
		$remuxfilename  .= $path_param . "/$basename_list[0]_$basename_list[1]_";
		$command .= " $divx_ac3_param -o $remuxfilename" . "divx.avi";
		print "executeing $command\n";
		system $command;
		exit;
	}
	else {
		#transcode -i e0.mpv -p c0.mpa -y divx4 -o test.avi
		my $command = "nice -19  $transcode -i $filestomux[0] -p $filestomux[1]  ";
		$remuxfilename  .= $path_param . "/$basename_list[0]_$basename_list[1]_";
		$command .= " $divx_param -o $remuxfilename" . "divx.avi";
		print "executeing $command\n";
		system $command;
		exit;
	}
}

my $mplex_command;

if ($mplex == 1) {
	if (scalar(@filestomux) < 2) {print "Need at least two streams for multiplexing\n";exit}
	if (! $panteltje){
		$mplex_command = "nice -19 $tcmplex -i $filestomux[0] -p $filestomux[1]";
	}
	else {
		$mplex_command = "nice -19 $tcmplex_panteltje -i $filestomux[0] -0 $filestomux[1]";
	}
	$remuxfilename  .= $path_param . "/$basename_list[0]_$basename_list[1]_";

	if (scalar(@filestomux) > 2) {
		if (! $panteltje){
			$mplex_command .= " -s $filestomux[2]";
			$remuxfilename .= "$basename_list[2]_";
		}
		else {
			print "Mplexing using tcmplex-panteltje\n";
			my $counter = 2;
			while (scalar(@filestomux) > $counter) {
				print "adding to $counter $filestomux[$counter]\n";
				$mplex_command .= " -" . ($counter-1) . " $filestomux[$counter]";
				$remuxfilename .= "$basename_list[$counter]_";
				$counter++;
			}
		}
	}
	$remuxfilename .= "remux.mpg";

	if ($mpeg2) {
		$mplex_command .= " -m 2 ";
	} 
	else {
	  $mplex_command .= " -m d ";
	}
	
	print "$remuxfilename as outputname\n";
	
	if (! $master_dvd)	{
		$mplex_command .= "-o $remuxfilename";
		print "executeing $mplex_command\n";
		system $mplex_command; 
	}
}

if ($master_dvd) {
	print "we got a the master_dvd parameter\n";
	create_dvd_image();
}


if ($postexec) {
	print "Executing: $postexec\n";
	if ($postexec =~ /VSlength/) {
		my $length = $PES_Obj->get_movie_length();
		$postexec =~ s/VSlength/$length/g;
	}
	exec $postexec;
}

if ($mplex) {
	clean_up();
}


exit;

sub create_dvd_image {
	my $pid;
	my $result = system "mkfifo  $path_param"."remuxfifo";
	print "the attempt to create FIFO returnd $result\n";
	my $asp_ratio = $PES_Obj->get_aspect_ratio();
	
	if ($pid = fork) {
        my $command = "dvdauthor -v $asp_ratio $master_dvd_param -o $path_param" . "/DVD $path_param" . "remuxfifo";
		print "starting $command\n";
		system $command;
		$command = "dvdauthor -T -o $path_param" . "/DVD";
		print "starting $command\n";
		system $command;
		sleep 1;
	}
	else {
		print "mplexing file to fifo\n";
		print "should execute $mplex_command and put it to the fifo\n";
		$mplex_command .= " -o $path_param" . "remuxfifo";
		print "now the command is $mplex_command\n";
		system $mplex_command;
		print "finished mplexing\n";
		exit;
	}
	if (! $mkiso) {
		print "***********************************************************\n";
		print "vdrsync finished\n";
		print "***********************************************************\n";
		print "now you can burn the Image to a DVD-R(W) using the command:\n\n";
		print "mkisofs -dvd-video  $path_param" . '/DVD | dvdrecord tsize=$(echo "`mkisofs  -dvd-video --print-size ' .$path_param . '/DVD 2>/dev/null`*2048" | bc -l ) dev=1,0,0 -v -dao -' . "\n";
		print "NOTE: Of course you have to adjust the dev=N,N,N parameter to match your device settings\n\n";
		print "NOTE: It might be a good idea to check it first with:\n\n";
		print "mplayer -dvd 1 -dvd-device $path_param" . "/DVD\n\n";
	}
	else {
		my $command = "mkisofs -dvd-video  $path_param" . '/DVD > ' . " $path_param/DVDimage.iso\n";
		system $command;
		print "***********************************************************\n";
		print "vdrsync finished\n";
		print "***********************************************************\n";
		print "now you can burn the Image to a DVD-R(W) using the command:\n\n";
		print "dvdrecord dev=1,0,0 -v -dao $path_param" . "DVDimage.iso\n";
		print "NOTE: Of course you have to adjust the dev=N,N,N parameter to match your device settings\n\n";
	}
}

sub clean_up {
	print "Deleting temp files\n";
	for my $delfile (@filestomux) {
		if (-e $delfile){
			print "$delfile\n";
			unlink($delfile);
		}
	}
	if (-e  "$path_param"."remuxfifo") {
		unlink ("$path_param"."remuxfifo");
	}
	if ($mkiso) {
		my $command = "rm -r $path_param" . "DVD";
		print "Deleting DVD Files with: $command\n";
		system $command;
		
	}
}

sub get_file_list {
	my $indir = shift;
	my $DIR;
	opendir $DIR, $indir || die "Can not open $indir $!\n";
	print "trying to open $indir\n";
	if (! $DIR){
		die "did not get a handle back\n";
	}
	my @allfiles =   grep { ! /^\./  } readdir $DIR;
	my @vdrfiles =   sort (grep { /\d{3}.vdr$/  } @allfiles);
	return \@vdrfiles;
	#$summary_file = $indir . "summary.vdr" if (-e "$indir/summary.vdr");
	#$marks_file = $indir . "marks.vdr" if (-e "$indir/marks.vdr");
	#$index_file = $indir . "index.vdr" if (-e "$indir/index.vdr");
}



BEGIN
{
package      MPEGSTREAM;
require      Exporter;
# A place available to all instances for storing the cuts in the file...
our @cutlist;
our $kill_me = "";	
our $total_size = 0;
our $bytes_read = 0;
our %bitrates =	(
	MPEG1_Layer_1 => {
		"0001"	=> "32",
		"0010"	=> "64",
		"0011"	=> "96",
		"0100"	=> "128",
		"0101"	=> "160",
		"0110"	=> "192",
		"0111"	=> "224",
		"1000"	=> "256",
		"1001"	=> "288",
		"1010"	=> "320",
		"1011"	=> "352",
		"1100"	=> "384",
		"1101"	=> "416",
		"1110"	=> "448",
	},
	MPEG1_Layer_2 => {
		"0001"	=> "32",
		"0010"	=> "48",
		"0011"	=> "56",
		"0100"	=> "64",
		"0101"	=> "80",
		"0110"	=> "96",
		"0111"	=> "112",
		"1000"	=> "128",
		"1001"	=> "160",
		"1010"	=> "192",
		"1011"	=> "224",
		"1100"	=> "256",
		"1101"	=> "320",
		"1110"	=> "384",
	},
	MPEG1_Layer_3 => {
		"0001"	=> "32",
		"0010"	=> "40",
		"0011"	=> "48",
		"0100"	=> "56",
		"0101"	=> "64",
		"0110"	=> "80",
		"0111"	=> "96",
		"1000"	=> "112",
		"1001"	=> "128",
		"1010"	=> "160",
		"1011"	=> "192",
		"1100"	=> "224",
		"1101"	=> "256",
		"1110"	=> "320",
	},
	MPEG2_Layer_1 => {
		"0001"	=> "32",
		"0010"	=> "64",
		"0011"	=> "96",
		"0100"	=> "128",
		"0101"	=> "160",
		"0110"	=> "192",
		"0111"	=> "224",
		"1000"	=> "256",
		"1001"	=> "288",
		"1010"	=> "320",
		"1011"	=> "352",
		"1100"	=> "384",
		"1101"	=> "416",
		"1110"	=> "448",
	},
	MPEG2_Layer_2 => {
		"0001"	=> "32",
		"0010"	=> "48",
		"0011"	=> "56",
		"0100"	=> "64",
		"0101"	=> "80",
		"0110"	=> "96",
		"0111"	=> "112",
		"1000"	=> "128",
		"1001"	=> "160",
		"1010"	=> "192",
		"1011"	=> "224",
		"1100"	=> "256",
		"1101"	=> "320",
		"1110"	=> "384",
	},
	MPEG2_Layer_3 => {
		"0001"	=> "8",
		"0010"	=> "16",
		"0011"	=> "24",
		"0100"	=> "32",
		"0101"	=> "64",
		"0110"	=> "80",
		"0111"	=> "56",
		"1000"	=> "64",
		"1001"	=> "128",
		"1010"	=> "160",
		"1011"	=> "112",
		"1100"	=> "128",
		"1101"	=> "256",
		"1110"	=> "320",
	},
);
our %freqs =(
		MPEG1 => {
			"00" =>  "44100",
			"01" =>  "48000",
			"10" =>  "32000",
		},
		MPEG2 => {
			"00" => "22050",
			"01" => "24000",
			"10" => "16000",
		},
);

our %AC3_frame_info =	(
	"32000" => {
		"000000"	=> "192",
		"000001"	=> "192",
		"000010"	=> "240",
		"000011"	=> "240",
		"000100"	=> "288",
		"000101"	=> "288",
		"000110"	=> "336",
		"000111"	=> "336",
		"001000"	=> "384",
		"001001"	=> "384",
		"001010"	=> "480",
		"001011"	=> "480",
		"001100"	=> "576",
		"001101"	=> "576",
		"001110"	=> "672",
		"001111"	=> "672",
		"010000"	=> "768",
		"010001"	=> "768",
		"010010"	=> "960",
		"010011"	=> "960",
		"010100"	=> "1152",
		"010101"	=> "1152",
		"010110"	=> "1344",
		"010111"	=> "1344",
		"011000"	=> "1536",
		"011001"	=> "1536",
		"011010"	=> "1920",
		"011011"	=> "1920",
		"011100"	=> "2304",
		"011101"	=> "2304",
		"011110"	=> "2688",
		"011111"	=> "2688",
		"100000"	=> "3072",
		"100001"	=> "3072",
		"100010"	=> "3456",
		"100011"	=> "3456",
		"100100"	=> "3840",
		"100101"	=> "3840",
	},
	"44100" => {
		"000000"	=> "138",
		"000001"	=> "140",
		"000010"	=> "194",
		"000011"	=> "196",
		"000100"	=> "208",
		"000101"	=> "210",
		"000110"	=> "242",
		"000111"	=> "244",
		"001000"	=> "278",
		"001001"	=> "280",
		"001010"	=> "348",
		"001011"	=> "350",
		"001100"	=> "416",
		"001101"	=> "418",
		"001110"	=> "486",
		"001111"	=> "488",
		"010000"	=> "556",
		"010001"	=> "558",
		"010010"	=> "696",
		"010011"	=> "698",
		"010100"	=> "834",
		"010101"	=> "836",
		"010110"	=> "974",
		"010111"	=> "976",
		"011000"	=> "1114",
		"011001"	=> "1116",
		"011010"	=> "1392",
		"011011"	=> "1394",
		"011100"	=> "1670",
		"011101"	=> "1672",
		"011110"	=> "1950",
		"011111"	=> "1952",
		"100000"	=> "2228",
		"100001"	=> "2230",
		"100010"	=> "2506",
		"100011"	=> "2508",
		"100100"	=> "2786",
		"100101"	=> "2788",
	},
	"48000" => {
		"000000"	=> "128",
		"000001"	=> "120",
		"000010"	=> "160",
		"000011"	=> "160",
		"000100"	=> "192",
		"000101"	=> "192",
		"000110"	=> "224",
		"000111"	=> "224",
		"001000"	=> "256",
		"001001"	=> "256",
		"001010"	=> "320",
		"001011"	=> "320",
		"001100"	=> "384",
		"001101"	=> "384",
		"001110"	=> "448",
		"001111"	=> "448",
		"010000"	=> "512",
		"010001"	=> "512",
		"010010"	=> "640",
		"010011"	=> "640",
		"010100"	=> "768",
		"010101"	=> "768",
		"010110"	=> "896",
		"010111"	=> "896",
		"011000"	=> "1024",
		"011001"	=> "1024",
		"011010"	=> "1280",
		"011011"	=> "1280",
		"011100"	=> "1336",
		"011101"	=> "1336",
		"011110"	=> "1792",
		"011111"	=> "1792",
		"100000"	=> "2048",
		"100001"	=> "2048",
		"100010"	=> "2304",
		"100011"	=> "2304",
		"100100"	=> "2560",
		"100101"	=> "2560",
	},
	"bitrate" => {
		"000000"	=> "32000",
		"000001"	=> "32000",
		"000010"	=> "40000",
		"000011"	=> "40000",
		"000100"	=> "48000",
		"000101"	=> "48000",
		"000110"	=> "56000",
		"000111"	=> "56000",
		"001000"	=> "64000",
		"001001"	=> "64000",
		"001010"	=> "80000",
		"001011"	=> "80000",
		"001100"	=> "96000",
		"001101"	=> "96000",
		"001110"	=> "112000",
		"001111"	=> "112000",
		"010000"	=> "128000",
		"010001"	=> "128000",
		"010010"	=> "160000",
		"010011"	=> "160000",
		"010100"	=> "192000",
		"010101"	=> "192000",
		"010110"	=> "224000",
		"010111"	=> "224000",
		"011000"	=> "256000",
		"011001"	=> "256000",
		"011010"	=> "320000",
		"011011"	=> "320000",
		"011100"	=> "384000",
		"011101"	=> "384000",
		"011110"	=> "448000",
		"011111"	=> "448000",
		"100000"	=> "512000",
		"100001"	=> "512000",
		"100010"	=> "576000",
		"100011"	=> "576000",
		"100100"	=> "640000",
		"100101"	=> "640000",
	},
);
	
our $mp2_regex = 
		#(pack ("B16", "1111111111110000")) . "|" .
        #(pack ("B16", "1111111111110001")) . "|" .
		#(pack ("B16", "1111111111110010")) . "|" .
		#(pack ("B16", "1111111111110011")) . "|" .                      These are Mpeg 2 Audio  Headers, 
		#(pack ("B16", "1111111111110100")) . "|" .		        They should not occur
		#(pack ("B16", "1111111111110101")) . "|" .
		#(pack ("B16", "1111111111110110")) . "|" .
		#(pack ("B16", "1111111111110111")) . "|" .
		
		#(pack ("B16", "1111111111111000")) . "|" .
		#(pack ("B16", "1111111111111001")) . "|" .
		#(pack ("B16", "1111111111111010")) . "|" .    	          These are Layer I and III headers
		#(pack ("B16", "1111111111111011")) . "|" .
		#(pack ("B16", "1111111111111110")) . "|" .
		#(pack ("B16", "1111111111111111")) . "|" .
		
		(pack ("B16", "1111111111111100")) . "|" .
		(pack ("B16", "1111111111111101"))		
		;	
	
$mp2_regex = qr/$mp2_regex/;

our $AC3_regex =
		(pack("B16", "0000101101110111"));  # AC3 Frames always have this 16 Bit Syncword at the beginning
		
$AC3_regex = qr/$AC3_regex/;		


sub get_cutlist { return @cutlist; }

our @ISA       = qw(Exporter);
our @EXPORT    = qw(	add_PES_packet
			bitrate
			streamtype
			streamcode
			print_stats
			output_files
			process_PES_packets
		   );

our $VERSION   = 0.1.2.2; # Version number




sub new {
    my $invocant = shift;
    my $class   = ref($invocant) || $invocant;
	
    my $self = {
	streamcode  	       => "PES_stream", #will be overridden
    streamtype  	       => undef, 	# 
    bitrate     	       => undef,	# only for Audio
	freq		           => undef,	# only for Audio 
	copyright	           => undef,	# only for Audio
	frame_bytes	           => undef,	# only for Audio
	frame_ticks	           => undef,	# one tick is 1 / 90000 of a second
	frameno     	       => 0,		# READ frames counter, not written frames
	GOPno		           => 0,		# just for video stats
	packet_start	       => undef,	# a signature that is found a the beginning of a frame, should read frame_start
	packet_rest	           => "",		# only audio, if a frame does not finish in a PES-Packet, the first part of the frame is stored here
	check_frames           => undef,	# a placeholder for the sub that actually manages the frames of a given type (mp2 / ac3 / mpv)
	analyse_frames         => undef,	# a placeholder for the sub that actually analyses the frames of a given type (mp2 / ac3 )
	masterstream	       => "",		# here the stream_id of the videostream is stored (it is not always e0 as I thought first)
	outputpath	           => "./",	    # where to store the result files
	outfilename			   => "", 		# The name of the output file
	cutcounter	           => 0,		# used as an index to the cuts list (see below), for sync we need the current and the previous cut
	last_ts		           => 0,        # last timestamp that was read
	final_desync	       => [],
	GOP_buffer             => "",       # A GOP is buffered here before analysed and written
	GOP_ts				   => 0,        # Here we store the first GOP ts, for the strrange recordings that have no ts at GOP start
	frame_buffer	       => [],		# an array that holds the buffered audio frames
	frame_times 	       => [],		# an array that holds the timestamp for each audio frame
	frame_lengths 	       => [],		# an array that holds the length for each audio frame
	frames_written	       => 0,		# used only for stats
	timestamps	           => [],	    # all timesstamps are stored here, probably a waste of memory, but maybe used for stricter checks
	written_chunks         => [],		# an array of scalars for debugging, from where to where were Audio STreams written?
	final_desync	       => 0,        # how many ticks desync after correction? Used in the next sync attempt
	show_drift             => 0,    	# if set to 1, info about timedrift will be printed
	time_drift             => 0,    	# The current mismatch between TS and actual Pakets found
	audio_only	           => 0,		# if this is set, all video Streams are discarded and audio ist just written out
	script_output	       => 0,
	Unit_analysis_counter  => 0,
	Unit_analysis_hash     => {},        # Here the different settings for apsepect_ratio etc are collected for later print
	first_flush            => 1,         # This flag indicates that it is the first time that the audio buffer is flushrd, an a start sync is needed
	@_,				                     # Override previous attributes
	};
	if ($self->{streamcode} eq "PES_stream")	{
		
		if (scalar(@{$self->{files}}) == 0)	{
			print "No input files specified, exiting\n"; exit 1 ;
		}
		
		foreach (@{$self->{files}})  {# check whether all files that we got as parameters exist
			if (!(-e $_)) {print "Input file $_ not found\n"; exit 1 }
		}
		$self->{packets_before_sync} = 0;
		print "dump only the first $self->{dump_packets} packets\n"  if $self->{dump_packets};
		foreach (keys (%{$self->{ignore_streams}})) {print "Ignoring stream $_\n";}
		print "Lots of debug stuff will be printed\n"  if $self->{debug};
		print "Printing Information about the time drift\n" if $self->{show_drift};
		init_PES_stream($self);
		foreach(@{$self->{files}}) {
			$total_size += -s $_;
		}
		print "Total Input Size is $total_size\n";# if $self->{debug};
	}
	return bless $self, $class;
}


sub init_stream	{
	my $self = shift;
	my $payload = shift;
	my %pes_header = %{shift @_};
	my $decimal_code = hex($pes_header{stream_id});
	print "we got the decimal code $decimal_code for $pes_header{stream_id}\n"if $self->{debug};
	if (($decimal_code > 191) && ($decimal_code < 224))		{
		print "we got the stream $decimal_code ($pes_header{stream_id}), checking Audio\n"if $self->{debug};
		analyse_audio_stream($self, $payload, \%pes_header);
		#$self->{streamtype} = "audio";
	}
	elsif (($decimal_code > 223) && ($decimal_code < 240))	{
		print "we got the stream $decimal_code ($pes_header{stream_id}), checking Video\n"if $self->{debug};
		analyse_video_stream($self, $payload, \%pes_header);
		$self->{streamtype} = "video";
	}
	elsif ($decimal_code == 189)		{
		analyse_ac3_stream($self, $payload, \%pes_header);
		$self->{streamtype} = "AC3_audio";
	}
	else	{
		print "unknown stream type found, skipping contents of stream $pes_header{stream_id}\n";
	}
}


sub output_files {
	my $self = shift;
	
	if ($self->{streamcode} ne "PES_stream") {return}
	
	my @audiofiles;
	my $moviefile;
	my @filelist;
	
	foreach(keys(%{$self->{streams}})) {
		if ($self->{ignore_streams}{$_}){
			next;
		}
		if ( $_ =~ /(c|b)/ ) {
			push @audiofiles, $self->{streams}{$_}{outfilename};
		}
		else {
			$moviefile = $self->{streams}{$_}{outfilename};
		}
	}
	@audiofiles = sort(@audiofiles);
	@filelist = ($moviefile, @audiofiles);
	return \@filelist;
}

sub analyse_ac3_stream {
	my $self = shift;
	my $payload = shift;
	my %pes_header = %{shift @_};
	$self->{frame_regex} = $AC3_regex;	
	($payload, my %frame_info) = analyse_ac3_frame($self, $payload);
	if ($payload eq "-1") {
		print "AC3 Packet could not be analysed, skipping\n";
		return;
	}
	
	$self->{packet_start} = substr($payload,0,2);
	
	
	$self->{freq} = $frame_info{freq};
	
	$self->{frame_bytes} = $frame_info{frame_bytes};
	$self->{bitrate}     = $frame_info{bitrate};
	$self->{mode}	     = $frame_info{mode};
	
	##################################################################
	############ ONE FRAME is 32 ms
	##################################################################
	
	$self->{frame_ticks} =  $frame_info{frame_ticks};
		
	
	$self->{outfilename} = "$self->{outputpath}/$self->{streamcode}.ac3";
	open $self->{outfile}, ">$self->{outputpath}/$self->{streamcode}.ac3" || die "Can not open file for ac3: $!\n" if (!($self->{outfile}));
	binmode $self->{outfile};
	$self->{check_frames} = \&check_audio_frames;
	$self->{analyse_frames} = \&analyse_ac3_frame;
	$self->{frame_regex} = $AC3_regex;
}

sub analyse_ac3_frame {
	my $self = shift;
	my $payload = shift;
	my $bits = unpack("B64", substr($payload, 0, 8));
	my %frame_info;
	if (!(substr($payload, 0, 2) =~ /^$AC3_regex$/)) {
	#if (substr($bits,0,16) ne "0000101101110111") {
		print "No Audio syncword found for stream $self->{streamcode}, searching for audio sync\n" if $self->{debug};
		print substr($bits,0,16) . " found, 0000101101110111 expected\n" if $self->{debug};
		if ($payload =~ /$AC3_regex/g) {
			print "\n AC3 regex matched at " . pos($payload) . "\n" if $self->{debug};
			$payload = substr($payload, (pos($payload)-2));
		}
		else {
			print "No audio frame found in this paket\n";
			return -1;
		}
		$bits = unpack("B64", substr($payload, 0, 8));
	}
	
	my $fscod = substr($bits,32,2);
	
	if ($fscod == "00")    {$frame_info{freq} = 48000}
	elsif ($fscod == "01") {$frame_info{freq} = 44100}
	elsif ($fscod == "11") {$frame_info{freq} = 32000}
	elsif ($fscod == "10") {print "Illeagal AC3 freq\n"; return -1}
		
	my $frmsizecod = substr($bits,34,6);
	$frame_info{frame_bytes} = $AC3_frame_info{$frame_info{freq}}{$frmsizecod};
	$frame_info{bitrate} = $AC3_frame_info{bitrate}{$frmsizecod};
	
	my $acmod = substr($bits, 48, 3);
	if    ($acmod == "000") {$frame_info{mode} = "1+1"}
	elsif ($acmod == "001") {$frame_info{mode} = "1/0"}
	elsif ($acmod == "010") {$frame_info{mode} = "2/0"}
	elsif ($acmod == "011") {$frame_info{mode} = "3/0"}
	elsif ($acmod == "100") {$frame_info{mode} = "2/1"}
	elsif ($acmod == "101") {$frame_info{mode} = "3/1"}
	elsif ($acmod == "110") {$frame_info{mode} = "2/2"}
	elsif ($acmod == "111") {$frame_info{mode} = "3/2"}
	
	##################################################################
	############ ONE FRAME is 32 ms
	##################################################################
	if ($fscod ne "00") {print "not an 48 KHz stream, exiting\n"; return -1}
	$frame_info{frame_ticks} =  8 * $frame_info{frame_bytes} * 90000 / $frame_info{bitrate};
	$frame_info{streamtype} = "AC3_Audio";
	if ($self->{Unit_analysis_counter}++ > 20) {
		$self->{Unit_analysis_hash}{mode}{$frame_info{mode}}++;
	}

	
	return $payload, %frame_info;
}

sub check_audio_frames	{
	my $self = shift;
	my $payload = shift;
	my %pes_header = %{shift @_};
	my $counter = 0;
	my $FH = $self->{outfile};
	
	
	if ($self->{change_message}) {return}
	
	if ($self->{dump_payload}) {
		print "Dumping payload of stream $self->{streamcode}, ($self->{dump_payload} to dump left)\n" if $self->{debug};
		my $DUMPFH;
		if (! $self->{"$self->{streamcode}.dump"}) {
			print "Trying to open dumpfile\n";
			open $DUMPFH, ">$self->{streamcode}.dump" || die "Can not open dumpfile: $!\n";
			binmode $DUMPFH;
			$self->{"$self->{streamcode}.dump"} = $DUMPFH;
			print "opened dumpfile\n";
		}
		$DUMPFH = $self->{"$self->{streamcode}.dump"};
		print $DUMPFH $payload;
		if ($self->{dump_payload}-- == 1) {
			exit;
		}
		return;
	}
	
	$payload = $self->{packet_rest} . $payload;
	
	($payload, my %frame_info) = &{$self->{analyse_frames}}($self, $payload) ;
	if  (!$frame_info{frame_ticks}) {
		print "Analysis failed in audio stream $self->{streamcode}, returning from check_audio_frames\n" if $self->{debug};
		return;
	}
	if ((!($self->{frame_bytes} eq $frame_info{frame_bytes}) || (!($self->{bitrate} eq $frame_info{bitrate}))) && ($self->{streamcode} ne "bd")) {
		if ($self->{audio_only}){
			$self->{copyright} = $frame_info{copyright};
			$self->{bitrate} = $frame_info{bitrate};
			$self->{freq} = $frame_info{freq};
			$self->{padding_bit} = $frame_info{padding_bit};
			$self->{streamtype} = $frame_info{streamtype};
			$self->{frame_bytes} = $frame_info{frame_bytes}; 
			$self->{frame_ticks} = $frame_info{frame_ticks}; 
			$self->{mode}        = $frame_info{mode};
			print "\nAudio Format Changed:\n";
			print "\naudio stream $self->{streamcode} info ($self->{streamtype}):\n";
			print "Sample frequency:    $self->{freq}\n";			# only for Audio 
			print "Bitrate:             $self->{bitrate}\n";     		# only for Audio
			print "Mode:                $self->{mode}\n";     		# only for Audio
			print "Copyright:           $self->{copyright}\n" if  $self->{copyright};		# only for Audio
			print "Frame length (bytes) $self->{frame_bytes}\n";		# only for Audio
			print "Frame length (ticks) $self->{frame_ticks} (90000 / sec)\n\n\n";		# one tick is 1 / 90000 of a second
		}
		
		
		elsif (!$self->{frames_written}) {	
			@{$self->{frame_times}}  = ();
			$self->{frame_times}[0] = 0;
			@{$self->{frame_buffer}} = ();
			@{$self->{frame_length}} = ();
			$self->{frameno} = 0;
			$self->{copyright} = $frame_info{copyright};
			$self->{bitrate} = $frame_info{bitrate};
			$self->{freq} = $frame_info{freq};
			$self->{padding_bit} = $frame_info{padding_bit};
			$self->{streamtype} = $frame_info{streamtype};
			$self->{frame_bytes} = $frame_info{frame_bytes}; 
			$self->{frame_ticks} = $frame_info{frame_ticks}; 
			$self->{mode}        = $frame_info{mode};
			
			$self->{single_frame} = get_silent_frame($self, \%frame_info);
			if ($self->{single_frame}  eq "-1") {
				$self->{single_frame} = substr($payload, 0, $frame_info{frame_bytes});
				print "Defined first audio frame as single frame for later sync in stream $self->{streamcode}\n" if $self->{debug};
				print "Frame has a length of " . length($self->{single_frame}) . "\n" if $self->{debug};
			}
					
			print "\nAUDIO FORMAT CHANGED, new parameters:\n";
			print "\naudio stream $self->{streamcode} info ($self->{streamtype}):\n";
			print "Sample frequency:    $self->{freq}\n";			# only for Audio 
			print "Bitrate:             $self->{bitrate}\n";     		# only for Audio
			print "Mode:                $self->{mode}\n";     		# only for Audio
			print "Copyright:           $self->{copyright}\n" if  $self->{copyright};		# only for Audio
			print "Frame length (bytes) $self->{frame_bytes}\n";		# only for Audio
			print "Frame length (ticks) $self->{frame_ticks} (90000 / sec)\n\n\n";
		}
		elsif ($total_size - $bytes_read < 10000000) {
				if (! $self->{change_message}) {
					print "\nAudio Format changed " . int(($total_size - $bytes_read)/1000000) ." MBytes before end, continuing...\n";
					$self->{change_message} = 1;
				}
				return;
		}
		else {
			print "Change in Audio Mode from $self->{mode} to $frame_info{mode}, this will not work during remux, stopping!\n";
			print "Change in Audio bitrate from $self->{bitrate} to $frame_info{bitrate}, this will not work during remux, stopping!\n";
			print "You should cut the movie at this position and process the pieces independently\n";
			my $frame_number = $self->{frames_written} + scalar(@{$self->{frame_buffer}});
			my $seconds = $frame_number * $self->{frame_ticks} / 90000; #/
			print "Current position: $seconds sec.\n";
			$kill_me = $self->{streamcode};
		}
	}
	
	if ((! $self->{frame_times}[0]) && ( $pes_header{PTS_decimal}) && ($self->{frameno} > 0)){
		print "\nFirst audio timestamp at $self->{frameno} for stream $self->{streamcode}\n" if $self->{debug};
		print "First Audio Timestamp is $pes_header{PTS_decimal}\n" if $self->{debug};
		for (my $i = 1;  $i <= $self->{frameno}; $i++) {
			$self->{frame_times}[$self->{frameno} - $i] = $pes_header{PTS_decimal} - ($i * $self->{frame_ticks});
		}
	print "\nAudio now starting at $self->{frame_times}[0]\n" if $self->{debug};
	}
		
	my $first_timestamp = 0;
	
	if ($pes_header{PTS_decimal}) {
		$first_timestamp = $pes_header{PTS_decimal};
	}
	else {
		$first_timestamp = ${$self->{frame_times}}[-1] + $frame_info{frame_ticks} if (${$self->{frame_times}}[-1]);
	}
	
	if (!($self->{single_frame})) {
		
		$self->{single_frame} = get_silent_frame($self, \%frame_info);
		if ($self->{single_frame}  eq "-1") {
			$self->{single_frame} = substr($payload, 0, $frame_info{frame_bytes});
			print "\nDefined first audio frame as single frame for later sync in stream $self->{streamcode}\n" if $self->{debug};
			print "Frame has a length of " . length($self->{single_frame}) . "\n" if $self->{debug};
		}
	}
	
	my $packet_offset = 0;
	while ($packet_offset + $frame_info{frame_bytes} +2 <= (length($payload))) {
		
		if ((substr($payload, $packet_offset, 2) =~ /^$self->{frame_regex}$/)) {
			push @{$self->{frame_buffer}}, substr($payload, $packet_offset, $frame_info{frame_bytes});
			
			push @{$self->{frame_times}}, $first_timestamp + $counter * $frame_info{frame_ticks};
			push @{$self->{frame_length}}, $frame_info{frame_ticks};
			$packet_offset += $frame_info{frame_bytes};
			$counter++;
			$self->{frameno}++;
		}
		else {
			print "\n$self->{frame_regex} did not match against " . (substr($payload,$packet_offset,2)) . "\n" if $self->{debug};
			if ($counter == 0) {
				$payload = search_audio_sync($self, substr($payload, $packet_offset));
				$self->{packet_rest} = "";
				$packet_offset = 0;
			}
			else {
				print "\nAudio Format change within packet, skipping \n" if $self->{debug};
				$self->{packet_rest} ="";
				return;
			}
		}
	}
	
	if ($packet_offset < (length($payload)))	{
		$self->{packet_rest} = substr($payload, $packet_offset);
	}
	else { 
		$self->{packet_rest} = "";
	}
	if (scalar(@{$self->{frame_times}}) < 100)	{
		return;
	}
	new_flush($self);
	return;
}

sub new_flush {
	my $self = shift;
	my $FH = $self->{outfile};
	
	if ($self->{audio_only}) {
		while (scalar(@{$self->{frame_times}}) > 50) {
			$self->{last_frame_time} =  shift @{$self->{frame_times}};
			shift @{$self->{frame_length}};
			print $FH shift @{$self->{frame_buffer}};
			$self->{frames_written} ++;
		}
		return;
	}

	my ($chunk_start, $chunk_end, $video_frameno) = split /::/,$cutlist[$self->{cutcounter}];
	if ($self->{first_flush}){
		sync_audio_start($self, $chunk_start);
		$self->{first_flush} = 0;
	}
	
	#
	# Here the new time drift correction is performed. Note that this is performed wthe the beginning of a Aufio flush NOT when it occurs
	# This should be ok, since a) The shift builds up very slowly and b) a buffer flush is only 60 Frames (max 1,8 sec)  long
	#
	if (abs($self->{time_drift}) > ($self->{frame_ticks} * 1.5)) {
		if (abs($self->{time_drift}) > 900000) {
			print "Timedrift bigger than 10 Seconds, killing stream $self->{streamcode}\n";
			$kill_me = $self->{streamcode};
			return;
		}
		print "Timedrift is too big, trying to correct $self->{time_drift} ticks\n";
		#sleep 1;
		if ($self->{time_drift} < 0) {
			while ($self->{time_drift} < ($self->{frame_ticks} * -1.5)) {
				shift @{$self->{frame_buffer}};
				shift @{$self->{frame_times}};
				$self->{time_drift} += shift @{$self->{frame_length}};
				print "Dropped frame to correct time drift EXPERIMENTAL!!!\n";
				if (@{$self->{frame_buffer}} == 0) {
					print "could not drop enough Audio frames in stream $self->{streamcode}to compensate for timedrift, still $self->{time_drift} left\nContinuing anyway...\n";
		#			sleep 1;
					if ($self->{dump_buffer}) {$kill_me = "all"}
					return;
				}
			}
		}
		else {		
			my $ins_frames = insert_frames($self, $self->{time_drift});
			my $ins_time = $ins_frames * $self->{frame_ticks};
			print "Inserted $ins_frames Audio Frames ($ins_time ticks) to correct a drift of $self->{time_drift}. EXPERIMENTAL\n";
			$self->{time_drift} -= $ins_time;
		}
	}
	
	#
	#If the currenct chunk's end has not been determined yet, then we just flush 60 frames and calculate the timedrift
	#
	
	if (! $chunk_end) {
		#my $frame;
		#my $time;
		#print "No Chunk end, just flushing\n";
		my $counter = 0;
		my $bufferstart = ${$self->{frame_times}}[0];
		my $drift;
		my $calc_end = $bufferstart;
		while (scalar(@{$self->{frame_times}}) > 40) {
			$self->{last_frame_time} =  shift @{$self->{frame_times}};
			$calc_end += shift @{$self->{frame_length}};
			print $FH shift @{$self->{frame_buffer}};
			$counter++;
			$self->{frames_written}++;
		}
		$drift = $self->{last_frame_time} - $calc_end  + $self->{frame_ticks};
		
		#This should not be necessary, since a PTS Overflow will be treated as a cut...
		#
		#if ($drift < -8000000000) {
		#	print "Time drift indicates a PTS overflow, correcting\n";
		#	$drift += 8589934592;
		#	print "Now time drift will be " . ($self->{time_drift} + $drift) .  "\n";
		#}
		$self->{time_drift} += $drift;
		if ($self->{show_drift} && (abs($drift) > 0)) {
			print "\nAUDIO TIMEDRIFT for stream $self->{streamcode}: $self->{time_drift}\n" if (abs($self->{time_drift}) > 100);
		}
		return;
	}
	
	#
	#If the currenct chunk's end has been determined, but is at the end of the buffer, only 20 Frames are flushed to "move" the cut to the middle of the buffer
	#Thereby we ensure that enough Audioframes for syncing are in the buffer before AND after the cut
	#
	my $cut_diff = $chunk_end - $self->{last_frame_time};
	
	if (60 * ${$self->{frame_length}}[0] + $self->{last_frame_time}  < $chunk_end) {
		
		print "delaying sync to next run, chunk_end is $chunk_end\n" if $self->{debug};
		my $calc = 60 * ${$self->{frame_length}}[0] + $self->{last_frame_time};
		while (scalar(@{$self->{frame_times}}) > 80) {
			$self->{last_frame_time} =  shift @{$self->{frame_times}};
			shift @{$self->{frame_length}};
			print $FH shift @{$self->{frame_buffer}};
			$self->{frames_written}++;
		}
		return;
	}
	
	# Then we test wether the cut is no cut but a PTS overflow .... If yes, we just dump the buffer, increase the cutcount and continue. 
	# No Timedrift is computed for this buffer
	if ($chunk_end > 8589889595) {
		print "syncing at PTS Overflow, special care is taken!\n";
		while (scalar(@{$self->{frame_times}}) > 20) {
			$self->{last_frame_time} =  shift @{$self->{frame_times}};
			shift @{$self->{frame_length}};
			print $FH shift @{$self->{frame_buffer}};
			$self->{frames_written}++;
		}
		$self->{cutcounter}++;
		return;
	}
	
	
	#
	# Finally we sync the end of the Audio chunk
	#
	
	
	sync_audio_end($self, $chunk_end, $video_frameno);
	$self->{cutcounter}++;
	# Extract the beginning of the next chunk
	($chunk_start, $chunk_end) = split /::/,$cutlist[$self->{cutcounter}];
	if (! $chunk_start) {
		print "Could not extract chunk start from $cutlist[$self->{cutcounter}]\n";
		$kill_me = $self->{streamcode};
	}
	# And sync the start of the next chunk
	sync_audio_start($self, $chunk_start);
}

sub sync_audio_end {
	my $self = shift;
	my $chunk_end = shift;
	my $video_frameno = shift;
	
	my $FH = $self->{outfile};
	my $counter = 0;
	my $cut_frame = 0;
	
	for (my $i = 0; $i < scalar(@{$self->{frame_times}}); $i++)  {
		if (abs(${$self->{frame_times}}[$i + 1] - ${$self->{frame_times}}[$i]) > 90000) {
			$cut_frame = $i;
			#print "The end of the chunk is at frame $cut_frame of the buffer\n";
			last;
		}
	}
	print "\nsyncing end of chunk in stream $self->{streamcode}...\n" if $self->{debug};
	my $bufferstart = ${$self->{frame_times}}[0];
	my $calc_end = $bufferstart;
	while ((${$self->{frame_times}}[0] < $chunk_end - $self->{final_desync} + ($self->{frame_ticks} * 0.5))
		  && ($counter < $cut_frame)){
		
		$self->{last_frame_time} = shift @{$self->{frame_times}};
		$calc_end += shift @{$self->{frame_length}};
		print $FH shift @{$self->{frame_buffer}};
		$self->{frames_written}++;
		$counter++;
		if (scalar(@{$self->{frame_times}}) == 0) {
		    print "syncing failed for stream $self->{streamcode} while trying to write Frames until $chunk_end\n";
		    print "time of last frame written was $self->{last_frame_time}\n";
		    $kill_me = $self->{streamcode};
		}
	}
	print "written $self->{frames_written} frames, time $self->{last_frame_time}\n"if $self->{debug};
	#
	# We dont need a timedrift calc at the end of a cunk, it is not corrected anyway...At the end the real length correction is performed
	#
	#my $drift = $self->{last_frame_time} - $calc_end  + ${$self->{frame_length}}[0];
	#if ($drift < -8000000000) {
	#		print "Time drift indicates a PTS overflow, correcting\n";
	#		$drift += 8589934592;
	#		print "Now time drift will be " . ($self->{time_drift} + $drift) .  "\n";
	#}
	#$self->{time_drift} += $drift;
	#if ($self->{show_drift} && (abs($drift) > 0)) {
	#	print "\nAUDIO TIMEDRIFT for stream $self->{streamcode}: $self->{time_drift}\n" if (abs($self->{time_drift}) > 100);
	#}
	#my $diff = $chunk_end - ($self->{last_frame_time} + $self->{frame_ticks});
	my $vid_time = $video_frameno * 3600;
	my $aud_time = $self->{frames_written} * $self->{frame_ticks};
	my $frame_diff = $vid_time - $aud_time;
	print "For the end sync $self->{cutcounter} of $self->{streamcode} frames were printed up to $self->{last_frame_time} to match $chunk_end of chunk $self->{cutcounter} leaving: $frame_diff)\n"if $self->{debug};
	my $ins_frames = insert_frames($self, $frame_diff);
	$self->{frames_written} += $ins_frames;
	$aud_time = $self->{frames_written} * $self->{frame_ticks};
	$self->{final_desync} = $vid_time - $aud_time;
	$self->{time_drift} = 0;
	$self->{written_chunks}[$self->{cutcounter}] .= ($self->{last_frame_time} + $self->{frame_ticks} * ($ins_frames+1));
}

sub sync_audio_start {
	my $self = shift;
	my $chunk_start = shift;
	print "\nFirst packet ts for stream $self->{streamcode} in buffer $self->{frame_times}[0] last:$self->{frame_times}[-1]\n" if $self->{debug};
	print "\nIn stream $self->{streamcode}: new start $chunk_start\n" if $self->{debug};
	my $counter = 0;
	while ((${$self->{frame_times}}[0] < $chunk_start - $self->{frame_ticks} * 0.5)
	   || ( (${$self->{frame_times}}[0] - $chunk_start) > 90000 )) { # For PTS overflows and "catted" movies
		#print "\ndropping frame with time ${$self->{frame_times}}[$counter]\n" if $self->{debug};
		shift @{$self->{frame_times}};
		shift @{$self->{frame_buffer}};
		shift @{$self->{frame_length}};
		$counter++;
		if (scalar(@{$self->{frame_times}}) == 0) {
		    print "\nsyncing failed for stream $self->{streamcode} while trying to drop Frames until $chunk_start\n";
		    #print "time of last frame dropped was $time_drop\n";
		    $kill_me = $self->{streamcode};
		}
	}
	my $diff = $chunk_start - ${$self->{frame_times}}[0];
	my $ins_frames = insert_frames($self, $diff);
	print "IN SYNC AUDIO START ($self->{streamcode}): diff is now: $diff\n" if $self->{debug};
	$self->{frames_written} += $ins_frames;
	$self->{last_frame_time} = ${$self->{frame_times}}[0];
	$self->{written_chunks}[$self->{cutcounter}] = (${$self->{frame_times}}[0] - $self->{frame_ticks} * $ins_frames) . "::";
	print "\nCHUNKSTART: dropped $counter frames at the beginning of $self->{streamcode}, start is now ${$self->{frame_times}}[0] matching $chunk_start leaving $diff\n" if $self->{debug};
}



sub insert_frames {
	my $self = shift;
	my $diff = shift;

	$diff += $self->{final_desync};
	my $FH = $self->{outfile};
	my $abs_diff = abs($diff);
	
	my $counter = 0;
	if ($abs_diff > 900000) {
		print "more than 10 seconds auf Audio missing, killing stream $self->{streamcode}\n";
		$kill_me = $self->{streamcode}; 
		return;
	}
	while ($abs_diff > ($self->{frame_ticks} * 0.5 )) {
		print $FH $self->{single_frame};
		$abs_diff -= $self->{frame_ticks};
		$counter++;
	}
	if ($diff < 0) {$abs_diff *= -1}
	print "INSERT FRAMES:wrote additional $counter frames to close $diff ticks, leaving $abs_diff\n" if $self->{debug};
	$self->{final_desync} = $abs_diff;
	#print "Final desync is now $self->{final_desync}\n";
	return $counter;
}

sub analyse_video_stream {
	my $self = shift;
	my $payload = shift;
	my %pes_header = %{shift @_};
	
	$self->{packet_start} = pack("H8", "00000100");
	my $seqstart = pack("H8", "000001b3");
	if (!($payload =~ /$seqstart(.{8})/s)) {print "No SeqHeader in the first Frame, exiting\n"; $kill_me = "all"}
	
	# Here we used to kill the stream if no PTS is found, that changed... We kill the strream if we find a GOP withou ANY ts
	$self->{check_frames} = \&check_GOPs;
	
	my $bitview = unpack("B64", $1);
	print "Matched: $& at $-[0] bitview of the header\n$bitview \n" if $self->{debug};
	my $hor_size = "0b" . substr($bitview,0,12);
	$self->{horizontal_size} = oct $hor_size; 
	my $ver_size = "0b" . substr($bitview,12,12);
	$self->{vertical_size} = oct $ver_size;
	my $asp_ratio = substr($bitview,24,4);

	if ($asp_ratio eq "0001"){
		$self->{aspect_ratio} = "1:1";
	}
	elsif ($asp_ratio eq "0010") {
		$self->{aspect_ratio} = "4:3";
	}
	elsif ($asp_ratio eq "0011") {
		$self->{aspect_ratio} = "16:9";
	}
	elsif ($asp_ratio eq "0111") {
		$self->{aspect_ratio} = "2.21:1";
	}
	else {
		$self->{aspect_ratio} = "$asp_ratio";
	}
	
	my $fps = substr($bitview,28,4);
	if ($fps eq "0001")	{
		$self->{fps} = 23.967;
	}
	elsif ($fps eq "0010")	{
		$self->{fps} = 24;
	}
	elsif ($fps eq "0011")	{
		$self->{fps} = 25;
	}
	elsif ($fps eq "0100")	{
		$self->{fps} = 29.97;
	}
	elsif ($fps eq "0101")	{
		$self->{fps} = 30.97;
	}
	 
	$self->{bitrate_value} = 400 * ( oct ("0b" . substr($bitview,32, 18)));
	my $marker_bit = substr($bitview,50, 1);
	print "we got for fps: $fps\n" if $self->{debug};
	$self->{frame_ticks} =  90000 / $self->{fps};
	$self->{outfilename} = "$self->{outputpath}/$self->{streamcode}.mpv";
	open $self->{outfile}, ">$self->{outputpath}/$self->{streamcode}.mpv" || die "Can not open file for m2v: $!\n";
	binmode $self->{outfile};
}


sub analyse_GOP {
	my $self = shift;

	
	my %GOP_info;
	my $seqstart = pack("H8", "000001b3");
	if (!($self->{GOP_buffer} =~ /$seqstart(.{8})/s)) {
	
		if (! $self->{GOPno}) {
			print "\nNo Seq Header in the GOP, exiting\n"; 
			$kill_me = "all";
		}
		else {
			print "\nA GOP without Sequence Header. Weird recording\n";
			open DFH, ">./strange_gop.mpg";
			print DFH $self->{GOP_buffer};
			close DFH;
			return;
		}
	}
	
	my $bitview = unpack("B64", $1);
	my $hor_size = "0b" . substr($bitview,0,12);
	$GOP_info{horizontal_size} = oct $hor_size; 
	$self->{Unit_analysis_hash}{horizontal_size}{$GOP_info{horizontal_size}}++;
	my $ver_size = "0b" . substr($bitview,12,12);
	$GOP_info{vertical_size} = oct $ver_size;
	$self->{Unit_analysis_hash}{vertical_size}{$GOP_info{vertical_size}}++;
	my $asp_ratio = substr($bitview,24,4);

	if ($asp_ratio eq "0001"){
		$GOP_info{aspect_ratio} = "1:1";
	}
	elsif ($asp_ratio eq "0010") {
		$GOP_info{aspect_ratio} = "4:3";
	}
	elsif ($asp_ratio eq "0011") {
		$GOP_info{aspect_ratio} = "16:9";
	}
	elsif ($asp_ratio eq "0111") {
		$GOP_info{aspect_ratio} = "2.21:1";
	}
	else {
		$GOP_info{aspect_ratio} = "$asp_ratio";
	}
	
	
	my $fps = substr($bitview,28,4);
	if ($fps eq "0001")	{
		$GOP_info{fps} = 23.967;
	}
	elsif ($fps eq "0010")	{
		$GOP_info{fps} = 24;
	}
	elsif ($fps eq "0011")	{
		$GOP_info{fps} = 25;
	}
	elsif ($fps eq "0100")	{
		$GOP_info{fps} = 29.97;
	}
	elsif ($fps eq "0101")	{
		$GOP_info{fps} = 30.97;
	}
	
	
	$GOP_info{bitrate_value} = 400 * ( oct ("0b" . substr($bitview,32, 18)));
	$self->{Unit_analysis_hash}{bitrate_value}{$GOP_info{bitrate_value}}++;
	$self->{Unit_analysis_hash}{aspect_ratio}{$GOP_info{aspect_ratio}}++;
	$self->{Unit_analysis_hash}{fps}{$GOP_info{fps}}++;

}


sub check_GOPs {
	my $self = shift;
	my $payload = shift;
	my %pes_header = %{shift @_};
	my $FH = $self->{outfile};
	my $gopstart = pack("H8", "000001b8");
	# First we just grep for the GOP start sequence
	if ((! $self->{GOPno})  && (! $self->{GOP_buffer} )) {
		$cutlist[$self->{cutcounter}] = "$pes_header{PTS_decimal}";
		push @{$self->{timestamps}}, $pes_header{PTS_decimal};
		my $seqstart = pack("H8", "000001b3");
		$payload =~ /$seqstart/g;
		if (pos($payload)-4 != 0) {
			print "The very first GOP did not start at 0, but at " . (pos($payload)-4) ."\n";
			$payload = substr($payload, (pos($payload)-4));
		}
		else {
			print "Yes, it did start at 0\n" if $self->{debug};
		}
		$self->{GOP_buffer} .= $payload;
		return;
	}
	
	if (! ($payload =~ /$gopstart/gm) ){
		$self->{GOP_buffer} .= $payload;
		#print "no GOPstart found, returning\n";
		return;
	}
	
	$self->{GOPno}++;
	
	my @pics = $self->{GOP_buffer} =~ /$self->{packet_start}/gm;
	my $frames_in_GOP = scalar(@pics);
	

	$self->{frameno} += $frames_in_GOP;
	
	if ($self->{Unit_analysis_counter}++ > 9) {
		$self->{Unit_analysis_counter} = 1;
		analyse_GOP($self);
	}
	
	
	if (! $pes_header{PTS_decimal}) {die "Found no ts at GOP start\n";}
	
	push @{$self->{timestamps}}, $pes_header{PTS_decimal};
	
	my $pts_diff = ${$self->{timestamps}}[-1] - ${$self->{timestamps}}[-2];
	my $calc = $self->{frame_ticks} * $frames_in_GOP;
	#print "Timestamp diff is $pts_diff and frame time is $calc\n";
	
	if ($calc != $pts_diff)	{
		my $ts_shift = $pts_diff - $calc;
		#print "TS not as expected, diff is $ts_shift\n";
		if (abs($ts_shift) > 90000) {
			my $chunk_end = ${$self->{timestamps}}[-2] + $frames_in_GOP * $self->{frame_ticks}; 
			if ($ts_shift > 0) {
				print "\nCut detected in Video at $chunk_end\n";
			}
			else { 
				print "\nCut detected at $chunk_end, possibly a PTS Overflow\n";
			}
			$cutlist[$self->{cutcounter}] .= "::$chunk_end" . "::$self->{frameno}";
			print "Chunk entry is $cutlist[$self->{cutcounter}]\n"if $self->{debug};
			$self->{cutcounter}++;
			$cutlist[$self->{cutcounter}] = "$pes_header{PTS_decimal}";
			$self->{time_drift} = 0;
		}
		else {
			#print "shift is too small for a cut, storing the shift for later use\n";
			$self->{time_drift} += $ts_shift; 
			if (abs($self->{time_drift}) > 1000) {
				print "\nTime Drift in VIDEO is now $self->{time_drift}, ts: ${$self->{timestamps}}[-2] and ${$self->{timestamps}}[-1] \n" if $self->{show_drift};
			}
		}
	}
	print $FH $self->{GOP_buffer};
	$self->{GOP_buffer} = $payload;
}


sub search_audio_sync {
		
	my $self = shift;
	my $payload = shift;
	my $new_offset = -1;
	print "Searching for audio sync\n"if $self->{debug};
	while ($payload =~ /$self->{frame_regex}/g)	{
		my $potential_start = (pos($payload)-2);
		print "\tFound a  potential audio syncword at $potential_start: " . unpack("H*" ,substr($payload,$potential_start,3)) . "\n" if $self->{debug};
		(my $dummy_payload, my %frame_info) = analyse_audio_frame($self, substr($payload,$potential_start));
		if (($potential_start + $frame_info{frame_bytes}) < length($payload)) {
			print "\twe should have enough payload left to verify...\n" if $self->{debug};
			#(my $dummy_payload, my %frame_info) = analyse_audio_frame($self, substr($payload,$potential_start));
			
			print "\tchecking " .  unpack("H4",substr($payload,($potential_start + $frame_info{frame_bytes}),2)) ."\n" if $self->{debug};
		
			if ($frame_info{packet_start} eq substr($payload,($potential_start + $frame_info{frame_bytes}),2)) {
				print "\tfound an additional audio sync in the right distance\n\tAll should be fine\n" if $self->{debug};
				$new_offset = $potential_start;
				print "\tNew attempt will be started at $new_offset\n" if $self->{debug};
				$self->{packet_rest} ="";
				last;
			}
			else {
				print "\tNext audio start not found, continuing to check...\n" if $self->{debug};
			}
		}
		else {
			print "\tnot enough payload left to verify\n\tGood Luck\n\tSkipping to next packet\n" if $self->{debug};
			last;
		}
	}
	
	if ($new_offset != -1)	{
		return (substr($payload,$new_offset));
		#		&{$self->{check_frames}} ($self, substr($payload,$new_offset), \%pes_header);
	}
	else {
		print "\tCould not find anything usefull in this packet, contents dropped, maybe next packet?\n" if $self->{debug};
		return (-1);
	}
}

sub print_stats	{
	my $self = shift;

	foreach (keys(%{$self->{streams}}))	{
		print "$self->{streams}{$_}{streamtype} for stream $_\n" if $self->{debug};
		if ($self->{ignore_streams}{$_}) {
			print "Ignoring stream $_\n";
			next;
		}
			
		if (($self->{streams}{$_}{streamtype} =~ /audio/) || ($self->{streams}{$_}{streamtype} =~ /Layer/))	{
			print "\naudio stream $_ info ($self->{streams}{$_}{streamtype}):\n";
			print "Sample frequency:    $self->{streams}{$_}->{freq}\n";			# only for Audio 
			print "Bitrate:             $self->{streams}{$_}->{bitrate}\n";     		# only for Audio
			print "Mode:                $self->{streams}{$_}->{mode}\n";     		# only for Audio
			print "Copyright:           $self->{streams}{$_}->{copyright}\n" if  $self->{streams}{$_}->{copyright};		# only for Audio
			print "Frame length (bytes) $self->{streams}{$_}->{frame_bytes}\n";		# only for Audio
			print "Frame length (ticks) $self->{streams}{$_}->{frame_ticks} (90000 / sec)\n\n\n";		# one tick is 1 / 90000 of a second
		}
		if ($self->{streams}{$_}{streamtype} eq "video") {
			print "video stream $_ info:\n";
			print "Frame length (ticks) $self->{streams}{$_}->{frame_ticks} (90000 / sec)\n";		# one tick is 1 / 90000 of a second
			print "Aspect ratio         $self->{streams}{$_}->{aspect_ratio}\n";
			print "Horizontal size      $self->{streams}{$_}->{horizontal_size} \n";
			print "Vertical size        $self->{streams}{$_}->{vertical_size} \n";
			print "Frames per Second    $self->{streams}{$_}->{fps} \n";
			print "Bitrate:             $self->{streams}{$_}{bitrate_value}\n\n\n";
		}
	}
}
	
sub analyse_audio_stream {
	my $self = shift;
	my $payload = shift;
	my %pes_header = %{shift @_};
	
	#$self->{cuts}[0] = "new start: $self->{first_ts} at 0\t"; #{frameno}  : $pes_header{PTS_decimal} : -1 : -1 : $self->{streamcode} : ";
	
	$self->{frame_regex} = $mp2_regex;
	
	($payload, my %frame_info) = analyse_audio_frame($self, $payload);
	
	if ($payload eq "-1") {
		print "Audio Packet could not be analysed, skipping\n" if $self->{debug};
		return;
	}
	$self->{copyright} = $frame_info{copyright};
	$self->{bitrate} = $frame_info{bitrate};
	$self->{freq} = $frame_info{freq};
	$self->{padding_bit} = $frame_info{padding_bit};
	$self->{streamtype} = $frame_info{streamtype};
	$self->{frame_bytes} = $frame_info{frame_bytes}; 
	$self->{frame_ticks} = $frame_info{frame_ticks}; 
	$self->{mode}        = $frame_info{mode};
	print "streamtype is: $self->{streamtype}\nbitrate is $self->{bitrate}\nfreq is $self->{freq}\ncopyright is $self->{copyright}\nframelength in byte is $self->{frame_bytes}\nin sec: " . ($self->{frame_ticks}/90000) . "\n" if $self->{debug};#/
	
	if ($self->{streamtype} eq "MPEG1_Layer_2")	{
		$self->{check_frames} = \&check_audio_frames;
		$self->{analyse_frames} = \&analyse_audio_frame;
		$self->{frame_regex} = $mp2_regex;
	}
	$self->{outfilename} = "$self->{outputpath}/$self->{streamcode}.mpa";
	open $self->{outfile}, ">$self->{outputpath}/$self->{streamcode}.mpa" || die "Can not open file for mpa: $!\n";
	binmode $self->{outfile};
}

sub analyse_audio_frame	{
	my $self = shift;
	my $frame = shift;
	#my %pes_header = %{shift @_};
	
	my %frame_info;	
	my $streamtype = "";
	if (!(substr($frame, 0, 2) =~ /^$mp2_regex$/)) {
		print "No Audio syncword at the beginning of the frame, searching\n" if $self->{debug};
		if ($frame =~ /$mp2_regex/g) {
			$frame = substr($frame, (pos($frame) - 2))
		}
		else {
			print "No Audio Sync found, returning -1\n" if $self->{debug}; 
			return -1;
		}
		print "found sync for mp2 stream $self->{streamcode}\n" if $self->{debug};
	}
	if (length($frame) < 8) {print "Frame too small to analyse, returning for stream $self->{streamcode}\n"; return;}
	my $BITS = unpack("B32", $frame);
	if (substr($BITS,12,1) == 1) {$streamtype = "MPEG1"} else {$streamtype = "MPEG2"}

	if (substr($BITS,13,2) eq "01") {$streamtype .= "_Layer_3"}
	elsif (substr($BITS,13,2) eq "10") {$streamtype .= "_Layer_2"}
	elsif (substr($BITS,13,2) eq "11") {$streamtype .= "_Layer_1"}
	else {print "Streamtype invalid, returning -1\n"; return -1}
	
	$frame_info{copyright} = substr($BITS,15,1);
	if ($bitrates{$streamtype}{substr($BITS,16,4)}) {
		$frame_info{bitrate} = $bitrates{$streamtype}{substr($BITS,16,4)} . "000"
	}
	else {
		print "\nBitrate of the audio stream $self->{streamcode} could not be determined, skipping packet and trying again later\n";
		print "Bitrate bits are:" .  substr($BITS,14,4) . "\n" if $self->{debug};
		return -1;
	}
	
	$frame_info{freq} = $freqs{substr($streamtype,0,5)}{substr($BITS,20,2)};
	if (! $frame_info{freq}) {
		print "\nFrequence of the audio stream $self->{streamcode} could not be determined, skipping packet and trying again later\n";
		print "Freq bits are:" .  substr($BITS,20,2) . "\n" if $self->{debug};
		return -1;
	}
	$frame_info{padding_bit} = substr($BITS,22,1);

	$frame_info{streamtype} = $streamtype;
	
	
	if    (substr($BITS,24,2) eq "00") {$frame_info{mode} = "stereo"}
	elsif (substr($BITS,24,2) eq "01") {$frame_info{mode} = "joint_stereo"}
	elsif (substr($BITS,24,2) eq "10") {$frame_info{mode} = "dual_channel"}
	elsif (substr($BITS,24,2) eq "11") {$frame_info{mode} = "mono"}
	#print "Mode: $frame_info{mode}\nbitrate: $frame_info{bitrate}, freq: $frame_info{freq}" if $self->{debug};
	
	
	$frame_info{frame_bytes} = ($frame_info{bitrate} * 144 / $frame_info{freq}) + $frame_info{padding_bit}; 
	$frame_info{frame_ticks} = 8 * $frame_info{frame_bytes} * 90000 / $frame_info{bitrate}; 
	
	#print "Mode: $frame_info{mode}\nbytes: $frame_info{frame_bytes}\nticks: $frame_info{frame_ticks}\nbitrate: $frame_info{bitrate}\n";
	$frame_info{packet_start} = substr($frame,0,2);
	#print "The start of the packet is: $frame_info{packet_start}\n";
	return ($frame, %frame_info);
	#print "frame analysed\n";
}

sub find_next_pes_packet {
	my $self = shift;
	my $buffer = shift;
	my $old_offset = shift;
	my $search_buffer;
	if ($old_offset > 0) {
		$search_buffer = substr($buffer, $old_offset);
	}
	else {
		$search_buffer = $buffer;
	}
	my $packet_start = pack("H6", "000001");
	print "TRYING TO FIND A NEW PES PACKET START AFTER $old_offset\n";
	 print "Got a buffer of length " . length($buffer) . " to match against\n";  
	open DOF, ">./debug_buffer.vdr" || die "Can not open File to dump buffer\n";
	binmode DOF;
	print DOF $buffer;
	close DOF;
	my $counter = 0;
	while ($search_buffer =~ /$packet_start/g)	{
		
		print "Now we found the new start at " . (pos($search_buffer)-3) . " \n";
		return (pos($search_buffer) - 3 + (length($buffer) - length($search_buffer)));
	}
	
	print "did not find  a new start\n";
	return -1;
}

sub final_flush {
	my $self = shift;
	my $FH = $self->{outfile};
	print "should do the final flush for stream $self->{streamcode}\n"if $self->{debug};
	if ($self->{streamcode} eq $self->{masterstream}) {
		print "Flushing Video Buffer, " . (length($self->{GOP_buffer})) . " bytes left\n"if $self->{debug};
		my @pics = $self->{GOP_buffer} =~ /$self->{packet_start}/gm;
		print "The last GOP contains " . (scalar(@pics)) . " pics\n"if $self->{debug};
		print $FH $self->{GOP_buffer};
		$self->{GOP_buffer} = "";
		$self->{frameno} += scalar(@pics);
		my $chunk_end = ${$self->{timestamps}}[-1] + (scalar(@pics)) * $self->{frame_ticks};
		$cutlist[$self->{cutcounter}] .= "::$chunk_end" . "::$self->{frameno}";
		if ($self->{debug}) {
			foreach(@cutlist) {print "FINAL: $_\n";}
		}
		$self->{frames_written} = $self->{frameno};
		return;
	}
	print $FH @{$self->{frame_buffer}};
	$self->{frames_written} += scalar(@{$self->{frame_buffer}});
	@{$self->{frame_buffer}} = "";
	if (! $self->{audio_only}) {
		my ($chunk_start, $chunk_end, $video_frameno) = split /::/,$cutlist[-1];
		my $vid_time = $video_frameno * 3600;
		my $aud_time = $self->{frames_written} * $self->{frame_ticks};
		my $diff = $vid_time - $aud_time;
		$self->{frames_written} += insert_frames($self, $diff);
	}
}


sub process_PES_packets	{
	my $self = shift;
	my $limit = shift;
	my $offset = 0;  		# stores the position we are at in the current buffer
	$self->{IFH} = undef; 		# Stores the filehandle for the current file
	$self->{EOF} = 0; 		# All files processed ?
	$self->{total_input} = 0;
	my $lengthcounter = 0;
	my $packetcounter = 0;
	
	my %pes_header;
	my $head_tmpl = 'H6 H2 n1 B8 B8 C1 B40';
	my $dts_tmpl = 'B40';
	
	my $buffer = ${ readNextChunk($self) }; 	# First we read the first chunk of data
	
	( $pes_header{startcode}, $pes_header{stream_id}, 
	    $pes_header{PES_packet_length}, $pes_header{eflags1}, 
	    $pes_header{eflags2}, $pes_header{header_length},
	    $pes_header{PTS_raw_bits}) 
	    = unpack ( $head_tmpl, substr($buffer, 0, 12) );
		
	while (($self->{EOF} eq 0 || $offset +  $pes_header{PES_packet_length}  + 1) < (length($buffer))) {
		if ($kill_me) {
			my @kill_list;
			if ($kill_me eq "all") { @kill_list = keys(% {$self->{streams} })}
			else { push @kill_list, $kill_me }
			if ($self->{dump_buffer}) {
				print "Something nasty happend, dumping debug.buffer and exit\n";
				my $start = 0;
				if ($offset < 10000) {
					print "Unfortunately the nasty thing happend at the start of a buffer \n";
					print "offset is only $offset; Dumping anyway...\n";
				}
				if ((length($buffer) - $offset )< 1000000) {
					print "Unfortunately the nasty thing happend at the end of a buffer \n";
					print "offset is already $offset Dumping anyway...\n";
				}
				if ($offset > 1000000) {$start = $offset - 1000000}
				open DFH,  ">./debug.buffer";
				binmode DFH;
				print DFH substr($buffer, $start, $start + 2000000);
				close DFH;
				print "please mail the file and a short description of the recording to \n";
				print "vdrsync\@gmx.net, then I will try to fix the bug\n";
				exit 1;dump_buffer($self)
			}
			print "got the kill list @kill_list\n";
			foreach (@kill_list) {
				$self->{ignore_streams}{$_} = 1;
				my $FH = $self->{streams}{$_}->{outfile};
				close $FH;
				unlink $self->{streams}{$_}->{outfilename};
				print "Stream $_ was killed due to an error\n";
			}
			if ($kill_me eq "all") {die "Skript stopped due to an error\n";}
			$kill_me="";
			
		}
		
		
		( $pes_header{startcode}, $pes_header{stream_id}, 
	    $pes_header{PES_packet_length}, $pes_header{eflags1}, 
	    $pes_header{eflags2}, $pes_header{header_length},
	    $pes_header{PTS_raw_bits}) 
	    = unpack ( $head_tmpl, substr($buffer, $offset, 14) );
	
		if ($pes_header{startcode} ne "000001")	{
			print "No 0x000001 found at current packet, found $pes_header{startcode} instead\noffset is $offset\n"; 
			$offset = find_next_pes_packet($self, $buffer, $offset);
			
			next;
		}
		my $decimal_code = hex($pes_header{stream_id});
		if ((!(191 < $decimal_code ) &&  (240 > $decimal_code)) &&  (! $decimal_code == 189)) {
			print "unknown Streamtype $pes_header{stream_id}, decimal $decimal_code ignoring\n" if $self->{debug};
			$offset +=  $pes_header{PES_packet_length} + 6;
			next;
		}
		# MPEG2 Audio and Video must have an extended Header as well as AC3
		$pes_header{payload_start} = (9 + $pes_header{header_length});
		# We check whether a TimeStamp is present:
		$pes_header{PTS_DTS_flags} = substr($pes_header{eflags2}, 0, 2);

		#FIXME: overflow of PTS not checked
		if (($pes_header{PTS_DTS_flags} eq "10") || ($pes_header{PTS_DTS_flags} eq "11")) {
			$pes_header{PTS_value_bits} = substr($pes_header{PTS_raw_bits},4,3) . substr($pes_header{PTS_raw_bits},8,15) . substr($pes_header{PTS_raw_bits},24,15);
			# decode the timestamp
			$pes_header{PTS_decimal} = oct("0b" . substr($pes_header{PTS_value_bits},1));
			$pes_header{PTS_decimal} += 4294967296 if (substr($pes_header{PTS_value_bits},0,1) == 1);
		}
		else {
			$pes_header{PTS_decimal} = 0;
		}
		$pes_header{data_align} = substr($pes_header{eflags1},6,1);
		
		if ((($offset + $pes_header{PES_packet_length} + 150) > (length($buffer))) && ($self->{EOF} == 0)) {
			my $helpbuffer = substr($buffer, $offset);
			$buffer = $helpbuffer . ${ readNextChunk($self) };
			$offset = 0;
		}

		my $packet = substr($buffer, $offset, $pes_header{PES_packet_length} + 6);
		$offset +=  $pes_header{PES_packet_length} + 6;
		$packetcounter++;
		$lengthcounter += ($pes_header{PES_packet_length} + 6);
		
		
		if ($self->{ignore_streams}{$pes_header{stream_id}}) {
			print "ignoring packet for stream $pes_header{stream_id}\n" if $self->{debug};
			next;
		}
		if (!($self->{streams}{$pes_header{stream_id}})) {
			print "\nNew Stream with id $pes_header{stream_id}. Ignoring the stream\n" if (! $self->{audio_only});
			$self->{ignore_streams}{$pes_header{stream_id}} = 1;
			next;
		}
		if ($self->{dump_packets}) {
			print "Dumping packet of stream $pes_header{stream_id} ($self->{dump_packets} to dump left)\n";
			my $DUMPFH;
			if (! $self->{"$pes_header{stream_id}.pes_dump"}) {
				open $DUMPFH, ">$pes_header{stream_id}.pes_dump" || die "Can not open dumpfile: $!\n";
				binmode $DUMPFH;
				$self->{"$pes_header{stream_id}.pes_dump"} = $DUMPFH;
			}
			$DUMPFH = $self->{"$pes_header{stream_id}.pes_dump"};
			print $DUMPFH $packet;
			if ($self->{dump_packets}-- == 1) {
				exit;
			}
			next;
		}
		&{$self->{streams}{$pes_header{stream_id}}->{check_frames}} (
					$self->{streams}{$pes_header{stream_id}},
					substr($packet,$pes_header{payload_start}), 
					\%pes_header
					);
		}
	
	print "\n $packetcounter PES packets processed\n";
	
	
	if (! $self->{audio_only}) {
		$self->{streams}{$self->{masterstream}}->final_flush($self->{streams}{$self->{masterstream}});
	}
	foreach (keys (%{$self->{streams}})) {
		if ($self->{ignore_streams}{$_}) {next}
		if (! ($self->{masterstream} eq $_)) {
			print "Final flush for stream $_\n"if $self->{debug};
			$self->{streams}{$_}->final_flush($self->{streams}{$_});
		}
		my $seconds = $self->{streams}{$_}{frames_written} * $self->{streams}{$_}{frame_ticks} / 90000; #/
		print "$self->{streams}{$_}{frames_written} frames written for stream $_ ($seconds sec) \n";
		next;
	}
	print_script_output($self);
	if (! $self->{script_output}){print_stats($self)};
	
	
}

sub print_script_output {
	my $self = shift;
	
	my %final_properties;
	my $master = $self->{streams}{$self->{masterstream}};
	my $max = 0;
	
	foreach my $movie_property(keys(%{$master->{Unit_analysis_hash}})) {
		print "found key $movie_property\n" if $self->{debug};
		foreach my $subkey (keys(%{$master->{Unit_analysis_hash}{$movie_property}})) {
			print "found subkey $subkey with value $master->{Unit_analysis_hash}{$movie_property}{$subkey}\n" if $self->{debug};
			if ((!$final_properties{$movie_property}) || $max < $master->{Unit_analysis_hash}{$movie_property}{$subkey}) {
				$final_properties{$movie_property} = $subkey;
				$max = $master->{Unit_analysis_hash}{$movie_property}{$subkey};
			}
		
		}
	}
	$max = 0;
	if ($self->{streams}{bd}) {
		my $ac3_audio= $self->{streams}{bd};
		foreach my $ac3_property(keys(%{$ac3_audio->{Unit_analysis_hash}})) {
			print "found key $ac3_property\n" if $self->{debug};
			foreach my $subkey (keys(%{$ac3_audio->{Unit_analysis_hash}{$ac3_property}})) {
				print "found subkey $subkey with value $ac3_audio->{Unit_analysis_hash}{$ac3_property}{$subkey}\n" if $self->{debug};
				if ((!$final_properties{$ac3_property}) || $max < $ac3_audio->{Unit_analysis_hash}{$ac3_property}{$subkey}) {
					$final_properties{$ac3_property} = $subkey;
					$max = $ac3_audio->{Unit_analysis_hash}{$ac3_property}{$subkey};
				}
			}
		}
	}
	
	
	foreach (keys(%final_properties)) {
		print "Property $_ is $final_properties{$_}\n" if $self->{debug};
		$self->{streams}{$self->{masterstream}}->{$_} = $final_properties{$_}; 
	}
	if (! $self->{script_output}) {
		return
	}
	
	
	print "*" x 45  ."\n";
	foreach (keys(%{$self->{streams}}))	{
		print "$self->{streams}{$_}{streamtype} for stream $_\n" if $self->{debug};
		if ($self->{ignore_streams}{$_}) {
			print "Ignoring stream $_\n" if $self->{debug};
			next;
		}
			
		if (($self->{streams}{$_}{streamtype} =~ /audio/) || ($self->{streams}{$_}{streamtype} =~ /Layer/))	{
			
			my $seconds = $self->{streams}{$_}->{frames_written} * $self->{streams}{$_}->{frame_ticks} / 90000; #/
			print "$_" . "_Audio_stream=yes\n";
			print "$_" . "_Audio_type=$self->{streams}{$_}{streamtype}\n";
			print "$_" . "_Sample_frequency=$self->{streams}{$_}->{freq}\n";			# only for Audio 
			print "$_" . "_Bitrate=$self->{streams}{$_}->{bitrate}\n";     		# only for Audio
			print "$_" . "_Mode=$self->{streams}{$_}->{mode}\n";     		# only for Audio
			print "$_" . "_Copyright=$self->{streams}{$_}->{copyright}\n" if  $self->{streams}{$_}->{copyright};		# only for Audio
			print "$_" . "_Bytes_per_frame=$self->{streams}{$_}->{frame_bytes}\n";		# only for Audio
			print "$_" . "_Ticks_per_frame=$self->{streams}{$_}->{frame_ticks}\n";		# one tick is 1 / 90000 of a second
			print "$_" . "_Total_frames=$self->{streams}{$_}->{frames_written}\n";
			print "$_" . "_Total_time=$seconds\n\n";
			
		}
		if ($self->{streams}{$_}{streamtype} eq "video") {
						
			my $seconds = $self->{streams}{$_}->{frames_written} * $self->{streams}{$_}->{frame_ticks} / 90000; #/
			print "$_" . "_Video_stream=yes\n";
			print "$_" . "_Aspect_ratio=$self->{streams}{$_}->{aspect_ratio}\n";
			print "$_" . "_Horizontal_size=$self->{streams}{$_}->{horizontal_size}\n";
			print "$_" . "_Vertical_size=$self->{streams}{$_}->{vertical_size}\n";
			print "$_" . "_Frames_per_Second=$self->{streams}{$_}->{fps}\n";
			print "$_" . "_Bitrate=$self->{streams}{$_}{bitrate_value}\n";
			print "$_" . "_Ticks_per_frame=$self->{streams}{$_}->{frame_ticks}\n";		
			print "$_" . "_Total_frames=$self->{streams}{$_}->{frames_written}\n";
			print "$_" . "_Total_time=$seconds\n\n";
			
		}
	}
}

sub init_PES_stream {
	my $self = shift;
	my $limit = shift;
	my $offset = 0;  		# stores the position we are at in the current buffer
	my $plength = 0;
	$self->{IFH} = undef; 		# Stores the filehandle for the current file
	$self->{EOF} = 0; 		# All files processed ?
	$self->{total_input} = 0;
	my %pes_header;
	$pes_header{packet_length} = 0;
	my $head_tmpl = 'H6 H2 n1 B8 B8 C1 B40';
	
		
	
	my $packetcounter = 0;
	
	print "Initialising and analysing the streams....\n";
	my @save_file_list = @{$self->{files}};
	
	my $buffer = ${ readNextChunk($self) }; 	# First we read the first chunk of data
	
	while ((($self->{EOF} eq 0 || $offset + $pes_header{packet_length} + 1) < (length($buffer))) && ($packetcounter < 2000))	{
		( $pes_header{startcode}, $pes_header{stream_id}, 
		$pes_header{PES_packet_length}, $pes_header{eflags1}, 
		$pes_header{eflags2}, $pes_header{header_length},
		$pes_header{PTS_raw_bits}) 
		= unpack ( $head_tmpl, substr($buffer, $offset, 12) );
		
		$pes_header{payload_start} = (9 + $pes_header{header_length});
		# there are at leat six bytes of header at the beginning of a PES packet
		if ( $pes_header{startcode} ne "000001") {
			print "No 0x000001 found at current packet, searching for next Packet start\n";
			$offset = find_next_pes_packet($self, $buffer, $offset);
			if ($offset == -1) {$kill_me = "all"}
			next;			
		}
		# We check whether a TimeStamp is present:
		$pes_header{PTS_DTS_flags} = substr($pes_header{eflags2}, 0, 2);
		if (($pes_header{PTS_DTS_flags} eq "10") || ($pes_header{PTS_DTS_flags} eq "11")) {
			$pes_header{PTS_value_bits} = substr($pes_header{PTS_raw_bits},4,3) . substr($pes_header{PTS_raw_bits},8,15) . substr($pes_header{PTS_raw_bits},24,15);
			# decode the timestamp
			$pes_header{PTS_decimal} = unpack("N", (pack ("B32", substr($pes_header{PTS_value_bits},1))));
			$pes_header{PTS_decimal} += 4294967296 if (substr($pes_header{PTS_value_bits},0,1) == 1);
		}
		else {
			$pes_header{PTS_decimal} = 0;
		}
		if ((($offset + $pes_header{PES_packet_length} + 150) > (length($buffer))) && ($self->{EOF} == 0)) {
			my $helpbuffer = substr($buffer, $offset);
			$buffer = $helpbuffer . ${ readNextChunk($self) };
			$offset = 0;
		}

		my $packet = substr($buffer, $offset, ($pes_header{PES_packet_length} + 6));
		$offset +=  $pes_header{PES_packet_length} + 6;
		$packetcounter++;
		
		#print "analysed the first $packetcounter packets...\n" if $self->{debug};
		if (!$self->{streams}{$pes_header{stream_id}}) {
			if ($self->{ignore_streams}{$pes_header{stream_id}}){
				next;
			}
			
			my $decimal_code = hex($pes_header{stream_id});
			if ((223 < $decimal_code ) &&  (240 > $decimal_code)){
				if ($self->{audio_only}) {
					$self->{ingnore_streams}{$pes_header{stream_id}} = 1;
					next;
				}
				
				if ($self->{masterstream}){
					print "Video stream already defined, but found stream $pes_header{stream_id} in addition. Ingnoring stream $pes_header{stream_id}\n";
					$self->{ingnore_streams}{$pes_header{stream_id}} = 1;
					next;
				}
				else {
					$self->{streams}{$pes_header{stream_id}} = MPEGSTREAM->new
							(
							streamcode 	=> $pes_header{stream_id},
							outputpath 	=> $self->{outputpath}, 
							masterstream 	=> $pes_header{stream_id}, 
							debug 		    => $self->{debug},
							dump_payload	=> $self->{dump_payload},
							show_drift 		=> $self->{show_drift},
							dump_buffer     => $self->{dump_buffer},
							);
					$self->{masterstream} = $pes_header{stream_id};
					print "\nCreated new MPEG stream object for stream $pes_header{stream_id}, master video stream\n";
				}
			}
			else {
				$self->{streams}{$pes_header{stream_id}} = MPEGSTREAM->new
							(
							streamcode 	=> $pes_header{stream_id}, 
							masterstream 	=> $self->{masterstream}, 
							outputpath 	=> $self->{outputpath}, 
							debug 		=> $self->{debug},
							dump_payload	=> $self->{dump_payload},
							audio_only	=> $self->{audio_only},
							show_drift	=> $self->{show_drift},
							dump_buffer => $self->{dump_buffer},
							);	
				print "\nCreated new MPEG stream object for stream $pes_header{stream_id} \n";
			}
						
		}
		
		if (!($self->{streams}{$pes_header{stream_id}}{check_frames}))
			{
			print "sending frame number $packetcounter for analysis of stream $pes_header{stream_id}\n" if $self->{debug};
			init_stream($self->{streams}{$pes_header{stream_id}}, substr($packet, $pes_header{payload_start}), \%pes_header);
			}
		}
		
		
	@{$self->{files}} = @save_file_list;
	print "analysed the first $packetcounter packets...\n";
	my $IFH = $self->{IFH};
	close $IFH;
	
	if (!($self->{masterstream}))
		{
		die "No video stream could be found within the first 2000 packets, exiting\n" if (! $self->{ignore_streams});
		}
	
	foreach (keys(%{$self->{streams}}))
		{
		$self->{streams}{$_}{masterstream} = $self->{masterstream};
		
		if ((!($self->{streams}{$_}{check_frames})) && (!($self->{ignore_streams}{$_})))
			{
			print "The contents of stream $_ could not be identified, the stream will be skipped!\n";
			$self->{ignore_streams}{$_} = 1;
			}
		}
	
	print_stats($self) if $self->{debug};
	return;
}



sub get_aspect_ratio {
	my $self = shift;
	return $self->{streams}{$self->{masterstream}}->{aspect_ratio};
}

sub readNextChunk {
	my $self = shift;
	my $IFH = $self->{IFH};
	

	if (!($self->{IFH})) {
		my $firstfile = shift @{$self->{files}};
		print "trying to open $firstfile\n" if $self->{debug};
		open $IFH, $firstfile  || die "$! happend while opening $firstfile\n";
		binmode $IFH;
		$self->{IFH} = $IFH;
	}
	
	my $rbuffer;
	my $rbytes = sysread $IFH, $rbuffer, 10000000, 0;
	
	if ($rbytes != 10000000 ) {
		if ((scalar(@{$self->{files}}))== 0) {
			print "\nall Input files processed\n";
			print "EOF reached\n";
			$self->{EOF} = 1;
		}
		else {
			my $nextf = shift @{$self->{files}};
			print "$nextf is the next file\n";
			close $IFH;
			open $IFH, $nextf  || die "$! happend while opening $nextf\n";
			binmode $IFH;
			$self->{IFH} = $IFH;
			my $helpbuffer;
			my $helprbytes = sysread $self->{IFH}, $helpbuffer, (10000000 - length($rbuffer)), 0;
			$rbuffer .= $helpbuffer;
			$rbytes += $helprbytes;
		}
	}
 	$self->{total_input} += $rbytes;
	my $status = sprintf ("%4d",  ($self->{total_input} / 1000000));#/
	$bytes_read = $self->{total_input};
	print "\r$status Mbytes of " . int($total_size/1000000) . " read"; #if $self->{debug};  f
	return \$rbuffer;
}



sub get_silent_frame {
	my $self = shift;
	my %info = % { shift @_ };
	my $frame;
	my $function;
	
	if ($info{streamtype} eq "MPEG1_Layer_2") {
		$function = "get_$info{mode}_" . "$info{bitrate}";
	}
	elsif ($info{streamtype} eq "AC3_Audio") {
		$info{mode} =~ s/\//_/;
		$function = "get_ac3_$info{mode}_" . "$info{bitrate}";
	}
	else {
		print "Can not understand Format $info{streamtype}, no silent frame available\n" if $self->{debug}; return -1;
	}
	
	my $uu_frame =  eval $function ;
	if (! $uu_frame) {print "No silent frame available for $function\n" if $self->{debug};  return -1}
	foreach (split "\n", $uu_frame) {
		last if /^end/;
		next if /[a-z]/;
		next unless int((((ord() - 32) & 077) + 2) / 3) == int(length() / 4);
		$frame .= unpack "u", $_;
	}
	
	return $frame;
}



sub get_mono_32000 {
my $frame = <<'End_FRAME';
M__T4P!%)I&JJOOOOOOOOFM?/EL?/FM:^?+8^?-:U\^6Q\^:UKY\MCY\UK7SY
M;'SYK6OGRV/GS6M?/EL?/FM:^?+8^?-:U\^6Q\^:UKY\MCY\UK7SY;'SYK6O
&GRV/GS0`
end
End_FRAME
return $frame;
}

sub get_mono_48000 {
my $frame = <<'End_FRAME';
M__TDP#-R-NJJOOOOOOOOEL6Q;'=W=UL6Q;%L6Q;'=W=UL6Q;%L6Q;'=W=UL6
MQ;%L6Q;'=W=UL6Q;%L6Q;'=W=UL6Q;%L6Q;'=W=UL6Q;%L6Q;'=W=UL6Q;%L
M6Q;'=W=UL6Q;%L6Q;'=W=UL6Q;%L6Q;'=W=UL6Q;%L6Q;'=W=UL6Q;%L6Q;'
)=W=UL6Q;````
end
End_FRAME
return $frame;
}

sub get_mono_56000 {

my $frame = <<'End_FRAME';
M__TTP!(C,R(B$D``````JJJJOOOOOOOOOOOOOFMMMMMMMM\^?/FM:UMMMMMM
MMOGSY\UK6MMMMMMMM\^?/FM:UMMMMMMMOGSY\UK6MMMMMMMM\^?/FM:UMMMM
MMMMOGSY\UK6MMMMMMMM\^?/FM:UMMMMMMMOGSY\UK6MMMMMMMM\^?/FM:UMM
AMMMMMOGSY\UK6MMMMMMMM\^?/FM:UMMMMMMMOGSY\UK0
end
End_FRAME

return $frame;
}

sub get_mono_64000 {
my $frame = <<'End_FRAME';
M__U$P"(D1$,B)$``````JJJJOOOOOOOOOOOOOFVVVVMBV+8MC;?/GSYK;;;;
M6Q;%L6QMOGSY\UMMMMK8MBV+8VWSY\^:VVVVUL6Q;%L;;Y\^?-;;;;:V+8MB
MV-M\^?/FMMMMM;%L6Q;&V^?/GS6VVVVMBV+8MC;?/GSYK;;;;6Q;%L6QMOGS
MY\UMMMMK8MBV+8VWSY\^:VVVVUL6Q;%L;;Y\^?-;;;;:V+8MBV-M\^?/FMMM
,MM;%L6Q;&V^?/GS0
end
End_FRAME
return $frame;
}


sub get_mono_80000 {
my $frame = <<'End_FRAME';
M__U4P"(U541#-HD`````JJJJJ^^^^^^^^^^^^^^^;;;=W=W=W=W6Q;%L;;;;
M;YK6VVW=W=W=W=UL6Q;&VVVV^:UMMMW=W=W=W=;%L6QMMMMOFM;;;=W=W=W=
MW6Q;%L;;;;;YK6VVW=W=W=W=UL6Q;&VVVV^:UMMMW=W=W=W=;%L6QMMMMOFM
M;;;=W=W=W=W6Q;%L;;;;;YK6VVW=W=W=W=UL6Q;&VVVV^:UMMMW=W=W=W=;%
ML6QMMMMOFM;;;=W=W=W=W6Q;%L;;;;;YK6VVW=W=W=W=UL6Q;&VVVV^:UMMM
/W=W=W=W=;%L6QMMMMOFM
end
End_FRAME
return $frame;
}

sub get_mono_96000 {
my $frame = <<'End_FRAME';
M__UDP#,V9E5$2-$@````JJJJJOOOOOOOOOOOOOOOOG=W=W=WO>][WO>[N[NM
MBV+8MC;?-:[N[N[N][WO>][W=W=UL6Q;%L;;YK7=W=W=WO>][WO>[N[NMBV+
M8MC;?-:[N[N[N][WO>][W=W=UL6Q;%L;;YK7=W=W=WO>][WO>[N[NMBV+8MC
M;?-:[N[N[N][WO>][W=W=UL6Q;%L;;YK7=W=W=WO>][WO>[N[NMBV+8MC;?-
M:[N[N[N][WO>][W=W=UL6Q;%L;;YK7=W=W=WO>][WO>[N[NMBV+8MC;?-:[N
M[N[N][WO>][W=W=UL6Q;%L;;YK7=W=W=WO>][WO>[N[NMBV+8MC;?-:[N[N[
2N][WO>][W=W=UL6Q;%L;;YK0
end
End_FRAME
return $frame;
}

sub get_mono_112000 {
my $frame = <<'End_FRAME';
M__UTP#-&=F956R(D````JJJJJK[[[[[[[[[[[[[[[[YW=W=[WO>]]]][WO>]
M[WN[N[N[N[K8MCYK7=W=WO>][WWWWO>][WO>[N[N[N[NMBV/FM=W=W>][WO?
M??>][WO>][N[N[N[NZV+8^:UW=W=[WO>]]]][WO>][WN[N[N[N[K8MCYK7=W
M=WO>][WWWWO>][WO>[N[N[N[NMBV/FM=W=W>][WO???>][WO>][N[N[N[NZV
M+8^:UW=W=[WO>]]]][WO>][WN[N[N[N[K8MCYK7=W=WO>][WWWWO>][WO>[N
M[N[N[NMBV/FM=W=W>][WO???>][WO>][N[N[N[NZV+8^:UW=W=[WO>]]]][W
MO>][WN[N[N[N[K8MCYK7=W=WO>][WWWWO>][WO>[N[N[N[NMBV/FM=W=W>][
5WO???>][WO>][N[N[N[NZV+8^:T`
end
End_FRAME
return $frame;
}

sub get_mono_128000 {
my $frame = <<'End_FRAME';
M__V$P$17=V9F:V-D````JJJJJK[[[[[[[[[[[[[[[[Y[WO>]]]]]]]]]]]]]
M[WO>][WO>][WN[N[K8VVVU[WO>]]]]]]]]]]]]][WO>][WO>][WN[N[K8VVV
MU[WO>]]]]]]]]]]]]][WO>][WO>][WN[N[K8VVVU[WO>]]]]]]]]]]]]][WO
M>][WO>][WN[N[K8VVVU[WO>]]]]]]]]]]]]][WO>][WO>][WN[N[K8VVVU[W
MO>]]]]]]]]]]]]][WO>][WO>][WN[N[K8VVVU[WO>]]]]]]]]]]]]][WO>][
MWO>][WN[N[K8VVVU[WO>]]]]]]]]]]]]][WO>][WO>][WN[N[K8VVVU[WO>]
M]]]]]]]]]]]][WO>][WO>][WN[N[K8VVVU[WO>]]]]]]]]]]]]][WO>][WO>
M][WN[N[K8VVVU[WO>]]]]]]]]]]]]][WO>][WO>][WN[N[K8VVVU[WO>]]]]
8]]]]]]]]][WO>][WO>][WN[N[K8VVVT`
end
End_FRAME
return $frame;
}

sub get_mono_160000 {
my $frame = <<'End_FRAME';
M__V4P%5HF(=W?;60@```JJJJJJ^^^^^^^^^^^^^^^^^^???????OW[]^_?W]
M_?OW[]^_????????????>][WO>][NZV+8U]]]]]]^_?OW[]_?W]^_?OW[]]]
M]]]]]]]]]][WO>][WN[K8MC7WWWWWW[]^_?OW]_?W[]^_?OWWWWWWWWWWWWW
MO>][WO>[NMBV-???????OW[]^_?W]_?OW[]^_????????????>][WO>][NZV
M+8U]]]]]]^_?OW[]_?W]^_?OW[]]]]]]]]]]]]][WO>][WN[K8MC7WWWWWW[
M]^_?OW]_?W[]^_?OWWWWWWWWWWWWWO>][WO>[NMBV-???????OW[]^_?W]_?
MOW[]^_????????????>][WO>][NZV+8U]]]]]]^_?OW[]_?W]^_?OW[]]]]]
M]]]]]]]][WO>][WN[K8MC7WWWWWW[]^_?OW]_?W[]^_?OWWWWWWWWWWWWWO>
M][WO>[NMBV-???????OW[]^_?W]_?OW[]^_????????????>][WO>][NZV+8
MU]]]]]]^_?OW[]_?W]^_?OW[]]]]]]]]]]]]][WO>][WN[K8MC7WWWWWW[]^
>_?OW]_?W[]^_?OWWWWWWWWWWWWWO>][WO>[NMBV-
end
End_FRAME
return $frame;
}

sub get_mono_192000 {
my $frame = <<'End_FRAME';
M__VDP%9IF8B(?[:Q$```JJJJJJOOOOOOOOOOOOOOOOOOOGWWW[]^_?OW]_?W
M]_?W]_?W[]^_?OW[]^_?OWWWW__?_]__WO>][WO>[NMCYK[[[]^_?OW[^_O[
M^_O[^_O[]^_?OW[]^_?OW[[[[__O_^__[WO>][WO=W6Q\U]]]^_?OW[]_?W]
M_?W]_?W]^_?OW[]^_?OW[]]]]__W__?_][WO>][WN[K8^:^^^_?OW[]^_O[^
M_O[^_O[^_?OW[]^_?OW[]^^^^__[__O_^][WO>][W=UL?-????OW[]^_?W]_
M?W]_?W]_?OW[]^_?OW[]^_????_]__W__>][WO>][NZV/FOOOOW[]^_?O[^_
MO[^_O[^_OW[]^_?OW[]^_?OOOO_^__[__O>][WO>]W=;'S7WWW[]^_?OW]_?
MW]_?W]_?W[]^_?OW[]^_?OWWWW__?_]__WO>][WO>[NMCYK[[[]^_?OW[^_O
M[^_O[^_O[]^_?OW[]^_?OW[[[[__O_^__[WO>][WO=W6Q\U]]]^_?OW[]_?W
M]_?W]_?W]^_?OW[]^_?OW[]]]]__W__?_][WO>][WN[K8^:^^^_?OW[]^_O[
M^_O[^_O[^_?OW[]^_?OW[]^^^^__[__O_^][WO>][W=UL?-????OW[]^_?W]
M_?W]_?W]_?OW[]^_?OW[]^_????_]__W__>][WO>][NZV/FOOOOW[]^_?O[^
D_O[^_O[^_OW[]^_?OW[]^_?OOOO_^__[__O>][WO>]W=;'S0
end
End_FRAME
return $frame;
}


sub get_stereo_48000 {
my $frame = <<'End_FRAME';
M__TD```1)22)))JJJJK[[[[[[[[[[[[[YK6M?/GSYK6M:UK6M?/GSYK6M:UK
M6M?/GSYK6M:UK6M?/GSYK6M:UK6M?/GSYK6M:UK6M?/GSYK6M:UK6M?/GSYK
M6M:UK6M?/GSYK6M:UK6M?/GSYK6M:UK6M?/GSYK6M:UK6M?/GSYK6M:UK6M?
)/GSYK6M:T```
end
End_FRAME
return $frame;
}

sub get_stereo_56000{
my $frame = <<'End_FRAME';
M__TT`!$11222))JJJJJOOOOOOOOOOOOOOOOFM:U\U\^?/GSYK6M:UK7S7SY\
M^?/FM:UK6M?-?/GSY\^:UK6M:U\U\^?/GSYK6M:UK7S7SY\^?/FM:UK6M?-?
M/GSY\^:UK6M:U\U\^?/GSYK6M:UK7S7SY\^?/FM:UK6M?-?/GSY\^:UK6M:U
A\U\^?/GSYK6M:UK7S7SY\^?/FM:UK6M?-?/GSY\^:UK0
end
End_FRAME
return $frame;
}

sub get_stereo_64000 {
my $frame = <<'End_FRAME';
M__U$`!$12;;21)JJJJJOOOOOOOOOOOOOOOOFM:U\^6Q;%L6Q\^?-:UK6M?/E
ML6Q;%L?/GS6M:UK7SY;%L6Q;'SY\UK6M:U\^6Q;%L6Q\^?-:UK6M?/EL6Q;%
ML?/GS6M:UK7SY;%L6Q;'SY\UK6M:U\^6Q;%L6Q\^?-:UK6M?/EL6Q;%L?/GS
M6M:UK7SY;%L6Q;'SY\UK6M:U\^6Q;%L6Q\^?-:UK6M?/EL6Q;%L?/GS6M:UK
,7SY;%L6Q;'SY\UK0
end
End_FRAME
return $frame;
}

sub get_stereo_80000{
my $frame = <<'End_FRAME';
M__U4`"(B;;;;;2JJJJJOOOOOOOOOOOOOOOOGSY\^6Q;%L6Q;%L6Q;%L6Q\^?
M/GSY;%L6Q;%L6Q;%L6Q;'SY\^?/EL6Q;%L6Q;%L6Q;%L?/GSY\^6Q;%L6Q;%
ML6Q;%L6Q\^?/GSY;%L6Q;%L6Q;%L6Q;'SY\^?/EL6Q;%L6Q;%L6Q;%L?/GSY
M\^6Q;%L6Q;%L6Q;%L6Q\^?/GSY;%L6Q;%L6Q;%L6Q;'SY\^?/EL6Q;%L6Q;%
ML6Q;%L?/GSY\^6Q;%L6Q;%L6Q;%L6Q\^?/GSY;%L6Q;%L6Q;%L6Q;'SY\^?/
/EL6Q;%L6Q;%L6Q;%L?/@
end
End_FRAME
return $frame;
}

sub get_stereo_96000{
my $frame = <<'End_FRAME';
M__UD`#,SCDDD;;JJJJJOOOOOOOOOOOOOOOOEL6Q;%L=W6QW=W=W=W=W=W=;%
ML6Q;%L6Q;%L=W6QW=W=W=W=W=W=;%L6Q;%L6Q;%L=W6QW=W=W=W=W=W=;%L6
MQ;%L6Q;%L=W6QW=W=W=W=W=W=;%L6Q;%L6Q;%L=W6QW=W=W=W=W=W=;%L6Q;
M%L6Q;%L=W6QW=W=W=W=W=W=;%L6Q;%L6Q;%L=W6QW=W=W=W=W=W=;%L6Q;%L
M6Q;%L=W6QW=W=W=W=W=W=;%L6Q;%L6Q;%L=W6QW=W=W=W=W=W=;%L6Q;%L6Q
M;%L=W6QW=W=W=W=W=W=;%L6Q;%L6Q;%L=W6QW=W=W=W=W=W=;%L6Q;%L6Q;%
2L=W6QW=W=W=W=W=W=;%L6Q;`
end
End_FRAME
return $frame;
}

sub get_stereo_112000{
my $frame = <<'End_FRAME';
M__UT`!$B(C-#,S(B(B(1))````````````"JJJJJJJJOOOOOOOOOOOOOOOOO
MOOOOOOOOOFM;;;;;;;;;6QMMMMMM\^?/GSY\UK6M:UK;;;;;;;;:V-MMMMMO
MGSY\^?/FM:UK6M;;;;;;;;;6QMMMMMM\^?/GSY\UK6M:UK;;;;;;;;:V-MMM
MMMOGSY\^?/FM:UK6M;;;;;;;;;6QMMMMMM\^?/GSY\UK6M:UK;;;;;;;;:V-
MMMMMMOGSY\^?/FM:UK6M;;;;;;;;;6QMMMMMM\^?/GSY\UK6M:UK;;;;;;;;
M:V-MMMMMOGSY\^?/FM:UK6M;;;;;;;;;6QMMMMMM\^?/GSY\UK6M:UK;;;;;
M;;;:V-MMMMMOGSY\^?/FM:UK6M;;;;;;;;;6QMMMMMM\^?/GSY\UK6M:UK;;
5;;;;;;:V-MMMMMOGSY\^?/FM:UK0
end
End_FRAME
return $frame;
}

sub get_stereo_128000{
my $frame = <<'End_FRAME';
M__V$`"(B(D1$1#,R(B(B)))```````````"JJJJJJJJJ^^^^^^^^^^^^^^^^
M^^^^^^^^^^^^;;;;;;;;;6Q;%L6Q;%L;;;;;Y\^?/GSYK6M:UMMMMMMMMM;%
ML6Q;%L6QMMMMOGSY\^?/FM:UK6VVVVVVVVUL6Q;%L6Q;&VVVV^?/GSY\^:UK
M6M;;;;;;;;;6Q;%L6Q;%L;;;;;Y\^?/GSYK6M:UMMMMMMMMM;%L6Q;%L6QMM
MMMOGSY\^?/FM:UK6VVVVVVVVUL6Q;%L6Q;&VVVV^?/GSY\^:UK6M;;;;;;;;
M;6Q;%L6Q;%L;;;;;Y\^?/GSYK6M:UMMMMMMMMM;%L6Q;%L6QMMMMOGSY\^?/
MFM:UK6VVVVVVVVUL6Q;%L6Q;&VVVV^?/GSY\^:UK6M;;;;;;;;;6Q;%L6Q;%
ML;;;;;Y\^?/GSYK6M:UMMMMMMMMM;%L6Q;%L6QMMMMOGSY\^?/FM:UK6VVVV
8VVVVUL6Q;%L6Q;&VVVV^?/GSY\^:UK6M
end
End_FRAME
return $frame;
}


sub get_stereo_160000{
my $frame = <<'End_FRAME';
M__V4`"(R,U55541$0S,S;2))``````````"JJJJJJJJJK[[[[[[[[[[[[[[[
M[[[[[[[[[[[[[[YMMMW=MN[N[N[N[N[N[N[N[K8MBV+8MC;;;;;;;;;;?/FM
M:UMMMW=MN[N[N[N[N[N[N[N[K8MBV+8MC;;;;;;;;;;?/FM:UMMMW=MN[N[N
M[N[N[N[N[N[K8MBV+8MC;;;;;;;;;;?/FM:UMMMW=MN[N[N[N[N[N[N[N[K8
MMBV+8MC;;;;;;;;;;?/FM:UMMMW=MN[N[N[N[N[N[N[N[K8MBV+8MC;;;;;;
M;;;;?/FM:UMMMW=MN[N[N[N[N[N[N[N[K8MBV+8MC;;;;;;;;;;?/FM:UMMM
MW=MN[N[N[N[N[N[N[N[K8MBV+8MC;;;;;;;;;;?/FM:UMMMW=MN[N[N[N[N[
MN[N[N[K8MBV+8MC;;;;;;;;;;?/FM:UMMMW=MN[N[N[N[N[N[N[N[K8MBV+8
MMC;;;;;;;;;;?/FM:UMMMW=MN[N[N[N[N[N[N[N[K8MBV+8MC;;;;;;;;;;?
M/FM:UMMMW=MN[N[N[N[N[N[N[N[K8MBV+8MC;;;;;;;;;;?/FM:UMMMW=MN[
>N[N[N[N[N[N[N[K8MBV+8MC;;;;;;;;;;?/FM:T`
end
End_FRAME
return $frame;
}

sub get_stereo_192000{
my $frame = <<'End_FRAME';
M__VD`#,S,V9F9E551$1$DC21)`````````"JJJJJJJJJJOOOOOOOOOOOOOOO
MOOOOOOOOOOOOOOOOOG=W=W=W=W=W=WO>][WO>][WO>][W=W=W=W=UL6Q;%L6
MQ;%L6Q;&V^?/FM:[N[N[N[N[N[N][WO>][WO>][WO>[N[N[N[NMBV+8MBV+8
MMBV+8VWSY\UK7=W=W=W=W=W=WO>][WO>][WO>][W=W=W=W=UL6Q;%L6Q;%L6
MQ;&V^?/FM:[N[N[N[N[N[N][WO>][WO>][WO>[N[N[N[NMBV+8MBV+8MBV+8
MVWSY\UK7=W=W=W=W=W=WO>][WO>][WO>][W=W=W=W=UL6Q;%L6Q;%L6Q;&V^
M?/FM:[N[N[N[N[N[N][WO>][WO>][WO>[N[N[N[NMBV+8MBV+8MBV+8VWSY\
MUK7=W=W=W=W=W=WO>][WO>][WO>][W=W=W=W=UL6Q;%L6Q;%L6Q;&V^?/FM:
M[N[N[N[N[N[N][WO>][WO>][WO>[N[N[N[NMBV+8MBV+8MBV+8VWSY\UK7=W
M=W=W=W=W=WO>][WO>][WO>][W=W=W=W=UL6Q;%L6Q;%L6Q;&V^?/FM:[N[N[
MN[N[N[N][WO>][WO>][WO>[N[N[N[NMBV+8MBV+8MBV+8VWSY\UK7=W=W=W=
MW=W=WO>][WO>][WO>][W=W=W=W=UL6Q;%L6Q;%L6Q;&V^?/FM:[N[N[N[N[N
D[N][WO>][WO>][WO>[N[N[N[NMBV+8MBV+8MBV+8VWSY\UK0
end
End_FRAME
return $frame;
}


sub get_stereo_224000{
my $frame = <<'End_FRAME';
M__VT`#,S1'=W9F9F5555MD;2))````````"JJJJJJJJJJJ^^^^^^^^^^^^^^
M^^^^^^^^^^^^^^^^^^^^=W=W=W=W>][WO????????????>][WO>][WO>][WO
M=W=W=W=W=W=W=W=W6Q;&VVWSYK6M=W=W=W=W>][WO????????????>][WO>]
M[WO>][WO=W=W=W=W=W=W=W=W6Q;&VVWSYK6M=W=W=W=W>][WO???????????
M?>][WO>][WO>][WO=W=W=W=W=W=W=W=W6Q;&VVWSYK6M=W=W=W=W>][WO???
M?????????>][WO>][WO>][WO=W=W=W=W=W=W=W=W6Q;&VVWSYK6M=W=W=W=W
M>][WO????????????>][WO>][WO>][WO=W=W=W=W=W=W=W=W6Q;&VVWSYK6M
M=W=W=W=W>][WO????????????>][WO>][WO>][WO=W=W=W=W=W=W=W=W6Q;&
MVVWSYK6M=W=W=W=W>][WO????????????>][WO>][WO>][WO=W=W=W=W=W=W
M=W=W6Q;&VVWSYK6M=W=W=W=W>][WO????????????>][WO>][WO>][WO=W=W
M=W=W=W=W=W=W6Q;&VVWSYK6M=W=W=W=W>][WO????????????>][WO>][WO>
M][WO=W=W=W=W=W=W=W=W6Q;&VVWSYK6M=W=W=W=W>][WO????????????>][
MWO>][WO>][WO=W=W=W=W=W=W=W=W6Q;&VVWSYK6M=W=W=W=W>][WO???????
M?????>][WO>][WO>][WO=W=W=W=W=W=W=W=W6Q;&VVWSYK6M=W=W=W=W>][W
JO????????????>][WO>][WO>][WO=W=W=W=W=W=W=W=W6Q;&VVWSYK6M
end
End_FRAME
return $frame;
}

sub get_stereo_256000{
my $frame = <<'End_FRAME';
M__W$`$1$57=W=V9F9F9FVMD;:)````````"JJJJJJJJJJJ^^^^^^^^^^^^^^
M^^^^^^^^^^^^^^^^^^^^>][WO>][WO????????????????????????>][WO>
M][WO>][WO>][WO>][WO>][WO=W=W6Q;&VVVV^:U[WO>][WO>]]]]]]]]]]]]
M]]]]]]]]]]]]][WO>][WO>][WO>][WO>][WO>][WO>]W=W=;%L;;;;;YK7O>
M][WO>][WWWWWWWWWWWWWWWWWWWWWWWWWO>][WO>][WO>][WO>][WO>][WO>]
M[W=W=UL6QMMMMOFM>][WO>][WO????????????????????????>][WO>][WO
M>][WO>][WO>][WO>][WO=W=W6Q;&VVVV^:U[WO>][WO>]]]]]]]]]]]]]]]]
M]]]]]]]]][WO>][WO>][WO>][WO>][WO>][WO>]W=W=;%L;;;;;YK7O>][WO
M>][WWWWWWWWWWWWWWWWWWWWWWWWWO>][WO>][WO>][WO>][WO>][WO>][W=W
M=UL6QMMMMOFM>][WO>][WO????????????????????????>][WO>][WO>][W
MO>][WO>][WO>][WO=W=W6Q;&VVVV^:U[WO>][WO>]]]]]]]]]]]]]]]]]]]]
M]]]]][WO>][WO>][WO>][WO>][WO>][WO>]W=W=;%L;;;;;YK7O>][WO>][W
MWWWWWWWWWWWWWWWWWWWWWWWWO>][WO>][WO>][WO>][WO>][WO>][W=W=UL6
MQMMMMOFM>][WO>][WO????????????????????????>][WO>][WO>][WO>][
MWO>][WO>][WO=W=W6Q;&VVVV^:U[WO>][WO>]]]]]]]]]]]]]]]]]]]]]]]]
M][WO>][WO>][WO>][WO>][WO>][WO>]W=W=;%L;;;;;YK7O>][WO>][WWWWW
MWWWWWWWWWWWWWWWWWWWWO>][WO>][WO>][WO>][WO>][WO>][W=W=UL6QMMM
#MOFM
end
End_FRAME
return $frame;
}

sub get_stereo_320000{
my $frame = <<'End_FRAME';
M__W4`%559IB9B(AW=W=WVVVMDC)```````"JJJJJJJJJJJK[[[[[[[[[[[[[
M[[[[[[[[[[[[[[[[[[[[[[Y]]]]]]]]]]]]^_?OW[]_?W]^_?O[^_O[^_OW[
M]^_?OW[]^_?OOOOOOOOOOOOOOOOOOOOOOOOO>][WO>][WO>][WN[N[K8MBV-
MMK7WWWWWWWWWWWW[]^_?OW]_?W[]^_O[^_O[^_?OW[]^_?OW[]^^^^^^^^^^
M^^^^^^^^^^^^^^^][WO>][WO>][WO>[N[NMBV+8VVM?????????????OW[]^
M_?W]_?OW[^_O[^_O[]^_?OW[]^_?OW[[[[[[[[[[[[[[[[[[[[[[[[[WO>][
MWO>][WO>][N[NZV+8MC;:U]]]]]]]]]]]]^_?OW[]_?W]^_?O[^_O[^_OW[]
M^_?OW[]^_?OOOOOOOOOOOOOOOOOOOOOOOOO>][WO>][WO>][WN[N[K8MBV-M
MK7WWWWWWWWWWWW[]^_?OW]_?W[]^_O[^_O[^_?OW[]^_?OW[]^^^^^^^^^^^
M^^^^^^^^^^^^^^][WO>][WO>][WO>[N[NMBV+8VVM?????????????OW[]^_
M?W]_?OW[^_O[^_O[]^_?OW[]^_?OW[[[[[[[[[[[[[[[[[[[[[[[[[WO>][W
MO>][WO>][N[NZV+8MC;:U]]]]]]]]]]]]^_?OW[]_?W]^_?O[^_O[^_OW[]^
M_?OW[]^_?OOOOOOOOOOOOOOOOOOOOOOOOO>][WO>][WO>][WN[N[K8MBV-MK
M7WWWWWWWWWWWW[]^_?OW]_?W[]^_O[^_O[^_?OW[]^_?OW[]^^^^^^^^^^^^
M^^^^^^^^^^^^^][WO>][WO>][WO>[N[NMBV+8VVM?????????????OW[]^_?
MW]_?OW[^_O[^_O[]^_?OW[]^_?OW[[[[[[[[[[[[[[[[[[[[[[[[[WO>][WO
M>][WO>][N[NZV+8MC;:U]]]]]]]]]]]]^_?OW[]_?W]^_?O[^_O[^_OW[]^_
M?OW[]^_?OOOOOOOOOOOOOOOOOOOOOOOOO>][WO>][WO>][WN[N[K8MBV-MK7
MWWWWWWWWWWWW[]^_?OW]_?W[]^_O[^_O[^_?OW[]^_?OW[]^^^^^^^^^^^^^
M^^^^^^^^^^^^][WO>][WO>][WO>[N[NMBV+8VVM?????????????OW[]^_?W
M]_?OW[^_O[^_O[]^_?OW[]^_?OW[[[[[[[[[[[[[[[[[[[[[[[[[WO>][WO>
/][WO>][N[NZV+8MC;:T`
end
End_FRAME
return $frame;
}


sub get_stereo_384000 {
my $frame = <<'End_FRAME';
M__WD`%5F9IF9F8B(AW=W_^VML;2```````"JJJJJJJJJJJK[[[[[[[[[[[[[
M[[[[[[[[[[[[[[[[[[[[[[Y]]]]]]^_?OW[]^_?OW[]_?W]_?W]_?W]_?W]_
M?W]_?W]^_?OW[]^_?OW[]^_?OOOOOOOOOOOOOOOO_^__[__O_^__[__O_^__
M[__O>][WO>]W=W=W=;&VVWSY]]]]]]^_?OW[]^_?OW[]_?W]_?W]_?W]_?W]
M_?W]_?W]^_?OW[]^_?OW[]^_?OOOOOOOOOOOOOOOO_^__[__O_^__[__O_^_
M_[__O>][WO>]W=W=W=;&VVWSY]]]]]]^_?OW[]^_?OW[]_?W]_?W]_?W]_?W
M]_?W]_?W]^_?OW[]^_?OW[]^_?OOOOOOOOOOOOOOOO_^__[__O_^__[__O_^
M__[__O>][WO>]W=W=W=;&VVWSY]]]]]]^_?OW[]^_?OW[]_?W]_?W]_?W]_?
MW]_?W]_?W]^_?OW[]^_?OW[]^_?OOOOOOOOOOOOOOOO_^__[__O_^__[__O_
M^__[__O>][WO>]W=W=W=;&VVWSY]]]]]]^_?OW[]^_?OW[]_?W]_?W]_?W]_
M?W]_?W]_?W]^_?OW[]^_?OW[]^_?OOOOOOOOOOOOOOOO_^__[__O_^__[__O
M_^__[__O>][WO>]W=W=W=;&VVWSY]]]]]]^_?OW[]^_?OW[]_?W]_?W]_?W]
M_?W]_?W]_?W]^_?OW[]^_?OW[]^_?OOOOOOOOOOOOOOOO_^__[__O_^__[__
MO_^__[__O>][WO>]W=W=W=;&VVWSY]]]]]]^_?OW[]^_?OW[]_?W]_?W]_?W
M]_?W]_?W]_?W]^_?OW[]^_?OW[]^_?OOOOOOOOOOOOOOOO_^__[__O_^__[_
M_O_^__[__O>][WO>]W=W=W=;&VVWSY]]]]]]^_?OW[]^_?OW[]_?W]_?W]_?
MW]_?W]_?W]_?W]^_?OW[]^_?OW[]^_?OOOOOOOOOOOOOOOO_^__[__O_^__[
M__O_^__[__O>][WO>]W=W=W=;&VVWSY]]]]]]^_?OW[]^_?OW[]_?W]_?W]_
M?W]_?W]_?W]_?W]^_?OW[]^_?OW[]^_?OOOOOOOOOOOOOOOO_^__[__O_^__
M[__O_^__[__O>][WO>]W=W=W=;&VVWSY]]]]]]^_?OW[]^_?OW[]_?W]_?W]
M_?W]_?W]_?W]_?W]^_?OW[]^_?OW[]^_?OOOOOOOOOOOOOOOO_^__[__O_^_
M_[__O_^__[__O>][WO>]W=W=W=;&VVWSY]]]]]]^_?OW[]^_?OW[]_?W]_?W
M]_?W]_?W]_?W]_?W]^_?OW[]^_?OW[]^_?OOOOOOOOOOOOOOOO_^__[__O_^
M__[__O_^__[__O>][WO>]W=W=W=;&VVWSY]]]]]]^_?OW[]^_?OW[]_?W]_?
MW]_?W]_?W]_?W]_?W]^_?OW[]^_?OW[]^_?OOOOOOOOOOOOOOOO_^__[__O_
;^__[__O_^__[__O>][WO>]W=W=W=;&VVWSX`
end
End_FRAME
return $frame;
}


sub get_ac3_2_0_448000 {
my $frame = <<'End_FRAME';
M"W>KMQY`0W_X2P:@N&'_.KY\^?/GSY\^?/GSY\^?/GSY\^?/GSY\^?/GSY\^
M?/GSY\^?/GSY\^?/GSY\^?/GSY\^?/GSY\^?/GSY\^??_.KY\^?/GSY\^?/G
MSY\^?/GSY\^?/GSY\^?/GSY\^?/GSY\^?/GSY\^?/GSY\^?/GSY\^?/GSY\^
M?/GSY\^?>4^D($``````````````````````````````````````````````
M````````````````````````````````````````````````````````````
M`````````````````````````````````````````````````````````\>/
M'CQX\>/'CQX`````````````````````````````````````````````````
M````````````````````````````````````````````````````````````
M`````````````````````````````````````````````````````'CQX\>/
M'CQX\>/#````````````````````````````````````````````````````
M````````````````````````````````````````````````````````````
M````````````````````````````````````````````````````'CQX\>/'
MCQX\>/``````````````````````````````````````````````````````
M````````````````````````````````````````````````````````````
M`````````````````````````````````````````````````\>/'CQX\>/'
MCQX8````````````````````````````````````````````````````````
M````````````````````````````````````````````````````````````
M````````````````````````````````````````````````\>/'CQX\>/'C
MQX``````````````````````````````````````````````````````````
M````````````````````````````````````````````````````````````
M````````````````````````````````````````````'CQX\>/'CQX\>/#`
M````````````````````````````````````````````````````````````
M````````````````````````````````````````````````````````````
M```````````````````````````````````````````'CQX\>/'CQX\>/```
M````````````````````````````````````````````````````````````
M````````````````````````````````````````````````````````````
M````````````````````````````````````````\>/'CQX\>/'CQX8`0>`7
M9',I_X0C2.]?[C,4O>``````````````````````````````````````````
M````````````````````````````````````````````````````````````
M````````````````````````````````````````````````````````````
M'CQX\>/'CQX\>/``````````````````````````````````````````````
M````````````````````````````````````````````````````````````
M`````````````````````````````````````````````````````````\>/
M'CQX\>/'CQX8`0X`1GEVD"Z"X6#I04H";@OIC#8Z]Q8X)BNY;28^@```````
M````````````````````````````````````````````````````````````
M````````````````````````````````````````````````````````````
M``````````````````````````````````!X\>/'CQX\>/'CP```````````
M````````````````````````````````````````````````````````````
M````````````````````````````````````````````````````````````
E```````````````````````````````/'CQX\>/'CQX\>``C>@``
end
End_FRAME
return $frame;
}

sub get_ac3_3_2_448000 {
my $frame = <<'End_FRAME';
M"W>9&!Y`X=_^$L`^_UE_P\/X>'\/#^'A_#P55X^?/GSY\^?/GSY\^?/GSY\^
M??\ZOGSY\^?/GSY\^?/GSY\^?/GSY\^?/GSY\^?/GSY\^?/GSY\^?/GSY\^?
M/GW_SJ^?/GSY\^?/GSY\^?/GSY\^?/GSY\^?/GSY\^?/GSY\^?/GSY\^?/GS
MY\^??_.KY\^?/GSY\^?/GSY\^?/GSY\^?/GSY\^?/GSY\^?/GSY\^?/GSY\^
M?/GSY]_\ZOGSY\^?/GSY\^?/GSY\^?/GSY\^?/GSY\^?/GSY\^?/GSY\^?/G
MSY\^?/GW_SJ^?/GSY\^?/GSY\^?/GSY\^?/GSY\^?/GSY\^?/GSY\^?/GSY\
M^?/GSY\^??_.N4^&)$B1(D2)``````&^;;;;;;;;>/'CN[N[N[N[N[N[N[N[
MN[QX\;;;?/FM:UK6M:UK6M:UK6M:UK0````&VVVVVVVV\>/'=W=W=W=W=W=W
M=W=W=WCQXVVV^?-:UK6M:UK6M:UK6M:UK6@````-MMMMMMMMX\>.[N[N[N[N
M[N[N[N[N[O'CQMMM\^:UK6M:UK6M:UK6M:UK6M`````;YMMMMMMMMX\>.[N[
MN[N[N[N[N[N[N[O'CQMMM\^:UK6M:UK6M:UK6M:UK6M`````;;;;;;;;;QX\
M=W=W=W=W=W=W=W=W=W>/'C;;;Y\UK6M:UK6M:UK6M:UK6M:`````V#X`````
M```!OFVVVVVVVWCQX[N[N[N[N[N[N[N[N[N\>/&VVWSYK6M:UK6M:UK6M:UK
M6M:T````!MMMMMMMMO'CQW=W=W=W=W=W=W=W=W=X\>-MMOGS6M:UK6M:UK6M
M:UK6M:UH````#;;;;;;;;>/'CN[N[N[N[N[N[N[N[N[QX\;;;?/FM:UK6M:U
MK6M:UK6M:UK0````&^;;;;;;;;>/'CN[N[N[N[N[N[N[N[N[QX\;;;?/FM:U
MK6M:UK6M:UK6M:UK0````&VVVVVVVV\>/'=W=W=W=W=W=W=W=W=WCQXVVV^?
M-:UK6M:UK6M:UK6M:UK6@````-@^`````````;YMMMMMMMMX\>.[N[N[N[N[
MN[N[N[N[O'CQMMM\^:UK6M:UK6M:UK6M:UK6M`````;;;;;;;;;QX\=W=W=W
M=W=W=W=W=W=W>/'C;;;Y\UK6M:UK6M:UK6M:UK6M:`````VVVVVVVVWCQX[N
M[N[N[N[N[N[N[N[N\>/&VVWSYK6M:UK6M:UK6M:UK6M:T````!OFVVVVVVVW
MCQX[N[N[N[N[N[N[N[N[N\>/&VVWSYK6M:UK6M:UK6M:UK6M:T````!MMMMM
MMMMO'CQW=W=W=W=W=W=W=W=W=X\>-MMOGS6M:UK6M:UK6M:UK6M:UH````#8
M/@````````&^;;;;;;;;>/'CN[N[N[N[N[N[N[N[N[QX\;;;?/FM:UK6M:UK
M6M:UK6M:UK0````&VVVVVVVV\>/'=W=W=W=W=W=W=W=W=WCQXVVV^?-:UK6M
M:UK6M:UK6M:UK6@````-MMMMMMMMX\>.[N[N[N[N[N[N[N[N[O'CQMMM\^:U
MK6M:UK6M:UK6M:UK6M`````;YMMMMMMMMX\>.[N[N[N[N[N[N[N[N[O'CQMM
MM\^:UK6M:UK6M:UK6M:UK6M`````;;;;;;;;;QX\=W=W=W=W=W=W=W=W=W>/
M'C;;;Y\UK6M:UK6M:UK6M:UK6M:`````V#X````````!OFVVVVVVVWCQX[N[
MN[N[N[N[N[N[N[N\>/&VVWSYK6M:UK6M:UK6M:UK6M:T````!MMMMMMMMO'C
MQW=W=W=W=W=W=W=W=W=X\>-MMOGS6M:UK6M:UK6M:UK6M:UH````#;;;;;;;
M;>/'CN[N[N[N[N[N[N[N[N[QX\;;;?/FM:UK6M:UK6M:UK6M:UK0````&^;;
M;;;;;;>/'CN[N[N[N[N[N[N[N[N[QX\;;;?/FM:UK6M:UK6M:UK6M:UK0```
M`&VVVVVVVV\>/'=W=W=W=W=W=W=W=W=WCQXVVV^?-:UK6M:UK6M:UK6M:UK6
M@````-@^```!`@!=D<R`````WS;;;;;;;;QX\=W=W=W=W=W=W=W=W=W>/'C;
M;;Y\UK6M:UK6M:UK6M:UK6M:`````VVVVVVVVWCQX[N[N[N[N[N[N[N[N[N\
M>/&VVWSYK6M:UK6M:UK6M:UK6M:T````!MMMMMMMMO'CQW=W=W=W=W=W=W=W
M=W=X\>-MMOGS6M:UK6M:UK6M:UK6M:UH````#?-MMMMMMMO'CQW=W=W=W=W=
MW=W=W=W=X\>-MMOGS6M:UK6M:UK6M:UK6M:UH````#;;;;;;;;>/'CN[N[N[
EN[N[N[N[N[N[QX\;;;?/FM:UK6M:UK6M:UK6M:UK0````&PK$```
end
End_FRAME
return $frame;
}

}
