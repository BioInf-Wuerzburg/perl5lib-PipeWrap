package PipeWrap::Task;

use 5.010001;

use Moose;
use Log::Log4perl;
use Data::Dumper;

#our @ISA = qw();

#---------globals---------#

our $VERSION = '0.9';

my $L = Log::Log4perl::get_logger();

=head1 NAME

PipeWrap::Task - 

=head1 SYNOPSIS

    use PipeWrap::Task;

=head1 DESCRIPTION

Checkpoint system that supervises a given order of tasks given by a config file.

=head2 new

    PipeWrap::Task::new();

new() creates PipeWrap task object

=cut

has 'id' => (is =>'rw', isa => 'Any', default => '');
has 'cmd' => (is => 'rw', isa => 'ArrayRef', default => sub { [] });
has 'parser' => (is => 'rw', isa => 'Any', default => undef);

=head2 run

$new->run()
gets tasks from object and calls corresponding command

=cut

sub run {
    my ($self) = @_;
    # run task
    open(my $cmdh, "@{$self->cmd()} |") or $L->logdie($!);
    
    # retrieve results
    my $re;

    my $parser = $self->parser || "parse_raw";
    if(ref $parser eq 'CODE'){
	$L->debug("Using custom parser routine, returned");
	$re = &{$parser}($cmdh);
	$L->debug(Dumper($re));
    }else{
	$L->debug("Using predefined parser");
	$re = $self->$parser($cmdh);
    }
    
    close $cmdh;
    $L->logcroak($self->id." exited:$? $@\n", $re) if ($? || $@);
    
    $L->debug($self->id."returned:\n",  ref $re ? Dumper($re) : $re);

    return $re;
}

=head2 parse_raw

$new->parse_raw($FH)
simple parser that reads the entire output of a FH to a string

=cut

sub parse_raw {
    my ($self, $fh) = @_;
    return scalar do{local $/; <$fh>}
}

=head2 parse_csv

$new->parse_csv($FH)
simple parser that splits whitespace separated output into a hash

=cut

sub parse_csv {
    my ($self, $fh) = @_;
    my %re;
    while(<$fh>){
        my ($k, $v) = split(/\s+/, $_, 2);
	chomp($v);
        $re{$k} = $v;
    }
    return \%re;
}

=head1 ACCESSORS
=cut

=head2 cmd

$new->cmd() get command
$new->cmd($cmd) set $cmd

=cut

=head2 id

$new->id() get id
$new->id($id) set id

=cut

=head2 parser

$new->parser() get result parser
$new->parser($parser) set result parser

=cut
1;
__END__
