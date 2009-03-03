#!/usr/bin/perl
# ----------------------------------------------------------------
# sysinfo for irssi and xchat
# (c) 2002,2003 S. Wenzler <sickathomedotanddotdrunkdotat>
# usage : /sys
# Optional requirements: xdpyinfo, nvclock, sensors, lspci ;)
#
# Uses code from different scripts:
# whoo's hacked up sysinfo whoo owneratowenmeanydotcom
# System Info from wolssiloa rubenkatemaildotcom
# xchatinfo Laurens "Law" Buhler and Alain "Doos" van Acker 
#           email: Lawatnixhelpdotorg and A.v.aathomedotnl
#
# Special thanx to yathateuircdotnet who helped me a lot with perl coding
#
# oh well - i forgot what belongs to which script and i m not even sure
# if i used code of these scripts - mainly i rewrote whoos stuff in perl
# if you find code that looks remarkable like yours - mail me ;)
# 
# Contributors: Christian Boerner
# ----------------------------------------------------------------
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#

my $VERSION = "1.9";
my %IRSSI = (
    authors     => "sick_boy",
    contact     => "spamtospamandmailtosick\@drunk.at",
    name        => "Sysinfo",
    description => "Linux system information",
    license     => "GPL",
    url         => "http://drunk.at/sick/download.html",
    changed     => "Mon Feb 27 23:23:23 CET 2006"
);

use strict;

BEGIN{
    use vars '$irssi','$xchat';
    eval q{
	use Irssi;
	Irssi::version();
    };
    $irssi = !$@;
    eval q{
	IRC::get_info(1);
    };
    $xchat = !$@;
}


# to nerv oder not to nerv
my $config_file ="$ENV{HOME}/.sysinfo.conf" ;
my $color = 0;

# extra path
$ENV{'PATH'} = "/usr/sbin:$ENV{'PATH'}";

# proc directory
my $procloc = "/proc";

# S.M.A.R.T. HDD
my $SMARTDRIVE = "/dev/hda";
my $SMARTDRIVE_SUDO = "";
# my $SMARTDRIVE_SUDO = "sudo";

if ( -e "$config_file" ) {
	open (CONFIGF, "<$config_file");
	$color = <CONFIGF>;
	close (CONFIGF);
}

sub set_color
{
  $color = shift;
  open (CONFIGF, ">$config_file");
  print CONFIGF "$color";
  close (CONFIGF);
  if ($xchat) {
	IRC::print ("sysinfo color set to $color");
  } else {
	print "sysinfo color set to $color";
  }
  return 1 ;
}

sub file_executable
{
   my $command = shift;
   my @directories=split(/:/, $ENV{'PATH'} );
   for (@directories) {
	if ( -x "$_/$command" ) {
	return 1;
	}
   }
   return 0;
}

sub display_sys_info
{  
   #--COLORS--#
   my $TITLE_S = "\002";
   my $TITLE_E = "\002";
   my $ALERT_S = "\002";
   my $NORMAL_S = "";
   my $ALERT_E = "\002";
   my $NORMAL_E = "";
   if ( $color ) {
   	$ALERT_E = "\003";
   	$NORMAL_E = "\003";
	$ALERT_S = "\0034";
	$NORMAL_S = "\0033";
   }

   #--UNAME--#
   open (X, "${procloc}/version");
   my $UNAME = <X>;
   close (X);

   $UNAME =~ s/^(\S+) \S+ (\S+) .*\n$/$1 $2/;

   my $SPEW = "${TITLE_S}SysInfo:${TITLE_E} $UNAME ${TITLE_S}";

   #--PROCESSOR--#
   my $NUM = 0;
   my $MIPS = 0;
   my ($MODEL,$SYSTEM);
   my $CPU = 0;

   open (X, "${procloc}/cpuinfo");
   while (<X>)
   {
	if (/^(cpu model|model name).*: (.*)\n$/) {
		$MODEL = $2;
		$NUM += 1;
	} elsif (/^system type.*: (.*)\n$/) {
		$SYSTEM = $1;
	} elsif (!$CPU && /^cpu MHz.*: (.*)\n$/) {
		$CPU = $1;
	} elsif (/^bogomips.*: (.*)\n$/i) {
		$MIPS += $1;
	}
    }
    close (X);

    #--SUPPORT FOR MULTIPLE PROCS--#
    if ($NUM == 2 ) { $MODEL="Dual $MODEL"; }
    if ($NUM == 4 ) { $MODEL="Quad $MODEL"; }

    $MODEL = $SYSTEM . " " . $MODEL;

    # Fix for Linux/Mips
    my $VGA = "unknown";
    if (!$CPU) {
	open (X, "/var/log/dmesg");
	while (<X>)
	{
		if (/\ \[?(\d+\.\d+) MHz (CPU|processor)/) { $CPU = $1; }
		if (/^Console: (.*) \d+x\d+/) { $VGA = $1; }
	}
	close (X);
    }
    	
    $SPEW .= "|${TITLE_E} $MODEL $CPU MHz ${TITLE_S}| Bogomips:${TITLE_E} $MIPS ${TITLE_S}";

    #--MEMORY--#
    my($MEMTOTAL,$MEMFREE);
    open(X, "${procloc}/meminfo") or $MEMTOTAL = 1;
    while(<X>){
	chomp;
	if(/^MemTotal:\s+(\d+)/){
		$MEMTOTAL = sprintf("%.0f",$1/1024);
	}elsif(/^MemFree:\s+(\d+)/){
		$MEMFREE = sprintf("%.0f",$1/1024);
	}elsif(/^Buffers:\s+(\d+)/){
		$MEMFREE += sprintf("%.0f",$1/1024);
	}elsif(/^Cached:\s+(\d+)/){
		$MEMFREE += sprintf("%.0f",$1/1024);
	}
    }
    close(X);

    #--PERCENTAGE OF MEMORY FREE--#
    my $MEMPERCENT = sprintf("%.1f",(100/${MEMTOTAL}*${MEMFREE}));

    #--BARGRAPH OF MEMORY FREE--#
    my $FREEBAR = int(${MEMPERCENT}/10);
    my $MEMBAR;
    my $x;

    $MEMBAR = "${TITLE_S}\[${NORMAL_S}";

    for ($x = 0;$x < 10; $x++)
    {
        if ( $x == $FREEBAR ) {
	    $MEMBAR .= "${ALERT_S}";
	}
	$MEMBAR .= "\|";
    }
    $MEMBAR .= "${ALERT_E}]${TITLE_E}";

    $SPEW .= "| Mem:${TITLE_E} ${MEMFREE}/${MEMTOTAL}M $MEMBAR ${TITLE_S}";
    
    #--DISKSPACE--#
    my $HDD = 0;
    my $HDDFREE = 0;
    my $SCSI = 0;
    my $SCSIFREE = 0;

    for (`df 2>/dev/null`) {
	if (/^\/dev\/(ida\/c[0-9]d[0-9]p[0-9]|[sh]d[a-z][0-9]+)\s+(\d+)\s+\d+\s+(\d+)\s+\d+%/) {
		$HDD += $2;
		$HDDFREE += $3;
	}
	if (/^\/dev\/(ida\/c[0-9]d[0-9]p[0-9]|sd[a-z][0-9]+)\s+(\d+)\s+\d+\s+(\d+)\s+\d+%/) {
		$SCSI += $2;
		$SCSIFREE += $3;
	}
    }

    my $ALL = $HDD;
    $HDDFREE = sprintf("%.02f", $HDDFREE / 1048576)."G";
    $HDD = sprintf("%.02f", $HDD / 1048576)."G";
    $SPEW .= "| Diskspace:${TITLE_E} $HDD ${TITLE_S}Free:${TITLE_E} $HDDFREE ${TITLE_S}";

    #--PROCS RUNNING--#
    opendir(PROC, "${procloc}");
    my $PROCS = scalar grep(/^\d/,readdir PROC);
    $SPEW .= "| Procs:${TITLE_E} $PROCS ${TITLE_S}";
    
    #--UPTIME--#
    open (X, "${procloc}/uptime");
    my ($up,$time)= "";
    my $uptime = <X>;
    close (X);
    $uptime =~ s/(\d+\.\d+)\s\d+\.\d+/$1/;
    my $days=int($uptime/86400);
    for ([31536000, "yr"], [604800, "wk"], [86400, "day"], [3600, "hr"], [60, "min"], [1, "sec"]){
		$time = sprintf ("%.d",$uptime/$_->[0]) || 0;
		$uptime -= ($time * $_->[0]);
		$up .= $time =~ /^1$/ ? "$time $_->[1] " : "$time $_->[1]s " if $time;
    }
    $SPEW .= "| Uptime:${TITLE_E} $up ${TITLE_S}";

    #--LOAD--#
    if (open (X, "${procloc}/loadavg")) {
	my $LOADAVG = <X>;
	close (X);
	$LOADAVG =~ s/^((\d+\.\d+\s){3}).*\n$/$1/;
	$SPEW .= "| Load:${TITLE_E} $LOADAVG ${TITLE_S}";
    }

    #--Virtual Penis--#	
    my $VPENIS = 70;
    $VPENIS += $uptime/10;
    $VPENIS += $CPU*$NUM/30;
    $VPENIS += $MEMTOTAL/3;
    $VPENIS += ($ALL+$SCSI)/1024/50/15;
    $VPENIS = int($VPENIS)/10;
    $SPEW .= "| Vpenis:${TITLE_E} $VPENIS cm ${TITLE_S}";

    #--GRAPHICSCARD--#
    if (file_executable("lspci") == 1) {
	for (`lspci 2>/dev/null`){
		if (/VGA compatible controller:\s(.*)$/){
		$VGA = $1; }
 	}
    }
    elsif ( -e "${procloc}/pci" ){
	open(X, "${procloc}/pci") ;
	while(<X>){
		chomp;
		if (/VGA compatible controller:\s(.*)\.$/){
		$VGA = $1; }
	}
        close(X);
    }
    $SPEW .= "| Screen:${TITLE_E} ${VGA} ";

    #--SCREEN RESOLUTION--#
    my ($DEPTH,$RES);
    if (file_executable("xdpyinfo")) {
	    for(`xdpyinfo 2>/dev/null`){
	          if(/\s+dimensions:\s+(\S+)/){
	                 $RES = $1;
	          }elsif(/\s+depth:\s+(\S+)/){
	                 $DEPTH = $1;
	          }
	    }
    if ($DEPTH) { $SPEW .= "\@ $RES ($DEPTH bpp) "; }
    }


    #--NVIDIA CORE FREQUENCY--#
    my $NVCLOCK;
    if (file_executable("nvclock") == 1) {
	for (`nvclock -s 2>/dev/null`){
		if (/^C.*ore speed:\s+(\d+\.\d+\sMHz)$/){
		$NVCLOCK = $1;
		}
 	}
    $SPEW .= "${TITLE_S}Corespeed:${TITLE_E} $NVCLOCK ";
    }

    #--NETINFO--# 
    my $route = "";
    my $netdev = "";
    my $NETDEVICE = "lo";

    open(X, "${procloc}/net/route") or $route = "NA";
    while(<X>){
    	chomp;
    	if (/^(.*?)\s+\d+\s+.*\s+0003\s+\d\s+/)
		{ $NETDEVICE = $1; }
    }
    close(X);

    my $PACKIN;
    my $PACKOUT;

    if ( open(X, "${procloc}/net/dev")) {
	while(<X>){
		chomp;
		if (/^(\s+)?$NETDEVICE/) {
		/^\s+(.*?):(\s+|)(\d+)\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+(\d+)\s+/;
		$PACKIN = sprintf("%.2f",$3 / 1048576);
		$PACKOUT = sprintf("%.2f",$4 / 1048576);
		}
	}
	close(X);
    if($PACKIN < 1024) { $PACKIN .= "M"; } else { $PACKIN = sprintf("%.02f", $PACKIN / 1024)."G"; }
    if($PACKOUT < 1024) { $PACKOUT .= "M"; } else { $PACKOUT = sprintf("%.02f", $PACKOUT / 1024)."G"; }
    $SPEW .= "${TITLE_S}| $NETDEVICE: In:${TITLE_E} $PACKIN ${TITLE_S}Out:${TITLE_E} $PACKOUT ";
    }
 
    #--LM_SENSORS--#
    my $SPEW2 = "";
    my $SENSOR1 = "NA";
    my $SENSOR2 = "NA";
    my $SENSOR3 = "NA";
    my $SENSOR4 = "NA";
    if ( file_executable("sensors") == 1) {
	for (`sensors 2>/dev/null`){
		if (/^[tT]emp2.*:\s+(.*(\s|.|)[FC])\s+\(.*\)(\s+ALARM)?/) {
			if (!$2) { $SENSOR1 = "${NORMAL_S} $1${NORMAL_E}"; } 
			else { $SENSOR1 = "${ALERT_S} $1${ALERT_E}"; }
		} elsif (/^[tT]emp1.*:\s+(.*(\s|.|)[FC])\s+\(.*\)(\s+ALARM)?/) {
			if (!$2) { $SENSOR2 = "${NORMAL_S} $1${NORMAL_E}"; } 
			else { $SENSOR2 = "${ALERT_S} $1${ALERT_E}"; }
		} elsif (/^fan1:\s+(\d+\sRPM)\s+\(.*\)(\s+ALARM)?/) {
			if (!$2) { $SENSOR3 = "${NORMAL_S} $1${NORMAL_E}"; } 
			else { $SENSOR3 = "${ALERT_S} $1${ALERT_E}"; }
		} elsif (/^fan2:\s+(\d+\sRPM)\s+\(.*\)(\s+ALARM)?/) {
			if (!$2) { $SENSOR4 = "${NORMAL_S} $1${NORMAL_E}"; } 
			else { $SENSOR4 = "${ALERT_S} $1${ALERT_E}"; }
		}
 	}
    if ( $SENSOR1 . $SENSOR2 . $SENSOR3 . $SENSOR4 ne "NANANANA") {
    	    $SENSOR1 =~ s/ C/ °C/g;
	    $SENSOR2 =~ s/ C/ °C/g;
	    $SPEW2 .= "${TITLE_S}CPU:${TITLE_E}$SENSOR1 ${TITLE_S}Fan:${TITLE_E}$SENSOR3 ${TITLE_S}Case:${TITLE_E}$SENSOR2 ${TITLE_S}Fan:${TITLE_E}$SENSOR4 ";
    }
    }

    #--HDDTEMP--#
    my ($HDDTEMP,$HDD,$DEG);
    if ( file_executable("hddtemp") == 1) {
       for (`$SMARTDRIVE_SUDO hddtemp $SMARTDRIVE 2>/dev/null`){
		if (/^\/dev\/[sh]da:\s+(.*):\s+(.*)$/) {
		$HDD = $1;
		$DEG = $2;
		$HDDTEMP .= " $HDD:$DEG";
		}
	}
    $HDDTEMP =~ s/ C/ °C/g;
    $SPEW2 .= "${TITLE_S}HDD:${TITLE_E}$HDDTEMP"; 
    }


    #--CHANNEL OUTPUT--#
    if ($irssi) {
	Irssi::active_win->command("/say $SPEW");
	if ($SPEW2) { Irssi::active_win->command("/say ${TITLE_S}Sensors:${TITLE_E} $SPEW2") };
    } elsif ($xchat) {
	IRC::command("/say $SPEW");
	if ( $SPEW2 ne "") { IRC::command("/say ${TITLE_S}Sensors:${TITLE_E} $SPEW2") };
    } else {
	print "$SPEW\n";
	if ($SPEW2) { print "${TITLE_S}Sensors:${TITLE_E} $SPEW2\n" };
    }


return 1;
}

#--END OF SUB--#

if ($irssi) {
    Irssi::command_bind('sys', 'display_sys_info');
    Irssi::command_bind('syscolor', 'set_color');
    Irssi::print("sick's perlified sysinfo script");
    Irssi::print("usage: /sys /syscolor");
} elsif ($xchat) {
    IRC::register("Sysinfo", "${VERSION}.1", "", "");
    IRC::print ("Loading sick's perlified \0034sysinfo\003 script");
    IRC::print ("Usage: /sys");
    IRC::print ("       /syscolor (0|1)");
    IRC::add_command_handler("sys", "display_sys_info");
    IRC::add_command_handler("syscolor","set_color") ;
} else {
    display_sys_info();
}
