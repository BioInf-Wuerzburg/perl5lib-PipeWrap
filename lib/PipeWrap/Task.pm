package Task;

use 5.010001;

use Moose;
extends 'PipeWrap';

use Log::Log4perl qw(:easy :no_extra_logdie_message);
use overload '""' => \&id;
use Data::Dumper;

#our @ISA = qw();

#---------globals---------#


our $VERSION = '0.1';

my $L = Log::Log4perl::get_logger();


# Preloaded methods go here.



# Below is stub documentation for your module. You'd better edit it!

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

=head2 parse_raw

$new->parse_raw($FH)
simple parser that reads the entire output of a FH to a string

=cut

=head2 parse_csv

$new->parse_csv($FH)
simple parser that splits whitespace separated output into a hash

=cut

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
1;
=head2 parser

$new->parser() get result parser
$new->parser($parser) set result parser

=cut
__END__
