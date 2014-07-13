#!/usr/bin/env perl

=head1 NAME

??

=head1 DESCRIPTION

??

=head1 SYNOPSIS

  ??

=head1 OPTIONS

=over

=item -?|--??

Does ??

=back

=head1 CHANGELOG

see git log.

=head1 CODE

=cut

#-----------------------------------------------------------------------------#
# Modules

# core
use strict;
use warnings;
no warnings 'qw';

use Carp;
use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use Log::Log4perl qw(:no_extra_logdie_message);
use Log::Log4perl::Level;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

use FindBin qw($RealBin $Script);
use lib "$RealBin/../lib/";

use File::Basename;
use File::Copy;
use File::Path;
use File::Spec;

use List::MoreUtils;
# additional modules
use Cfg;

use PipeWrap;

#-----------------------------------------------------------------------------#
# Globals

our $VERSION = 0.01;

# get a logger
my $L = Log::Log4perl::get_logger();
Log::Log4perl->init( \q(
	log4perl.rootLogger                     = INFO, Screen
	log4perl.appender.Screen                = Log::Log4perl::Appender::Screen
	log4perl.appender.Screen.stderr         = 1
	log4perl.appender.Screen.layout         = PatternLayout
	log4perl.appender.Screen.layout.ConversionPattern = [%d{yy-MM-dd HH:mm:ss}] [PipeWrap] %m%n
));


#-----------------------------------------------------------------------------#
# GetOptions
my %opt = (skip => []); 

GetOptions( # use %opt (Cfg) as defaults
	\%opt, qw(
                out|o=s
                dir|d=s
		threads|t=i
		continue:s
		skip=s{,}
		stop=s
		create_config|create-config:s
		config|c=s
		version|V!
		debug|D!
		help|h!
	)
) or $L->logcroak('Failed to "GetOptions"');

# help
$opt{help} && pod2usage(1);

# version
if($opt{version}){
	print "$VERSION\n"; 
	exit 0;
}


#-----------------------------------------------------------------------------#
# Config

# core
my $core_cfg = "$RealBin/../".basename($Script, qw(.pl)).".cfg";
my %cfg = Cfg->Read($core_cfg); 

if ($opt{config}){
    %cfg = (%cfg, Cfg->Read($opt{config}));
}

# create template for user cfg
if(defined $opt{create_config}){
	pod2usage(-msg => 'To many arguments', -exitval=>1) if @ARGV > 1;
	my $user_cfg = Cfg->Copy($core_cfg, $opt{create_config}) or $L->logdie("Creatring config failed: $!");
	$L->info("Created config file: $user_cfg");
	exit 0;
}

#-----------------------------------------------------------------------------#
# Config + Opt

%opt = (%cfg, %opt);


# required stuff  
for(qw()){
    if(ref $opt{$_} eq 'ARRAY'){
	pod2usage("required: --$_") unless @{$opt{$_}}
    }else{
	pod2usage("required: --$_") unless defined ($opt{$_})
    }
};


# debug level
$L->level($DEBUG) if $opt{debug};
$L->debug('Verbose level set to DEBUG');

$L->debug(Dumper(\%opt));



#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
# Main


my $pl = PipeWrap->new(
    tasks => $opt{tasks},
    continue => $opt{continue},
    skip => $opt{skip},
);


#print Dumper($pl);
#print Dumper($pl->tasks);
#print Dumper($pl->tdx);

#for(1..2){
#    $pl->run();
#    #print Dumper($pl->task);
#}



while(my $tid = $pl->run()){
    last if $tid eq $opt{stop};
}
#do {print "running next task\n"} while $pl->run();

#print Dumper($pl);



#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
# Parser extension

sub PipeWrap::ParseCsv{
    my ($self, $fh) = @_;
    my %re;
    while(<$fh>){
	my ($k, $v) = split(/\s+/, $_, 2);
	$re{$k} = $v;
    }
    return \%re;
}

#-----------------------------------------------------------------------------#

=head1 AUTHOR

Thomas Hackl S<thomas.hackl@uni-wuerzburg.de>

=cut
