#!/usr/bin/env perl

package PipeWrap;

use 5.010001;
use Moose;
use PipeWrap::Task;

use FindBin qw($RealBin $Script);
use File::Basename;
use Storable;
use Data::Dumper;
use Log::Log4perl; #qw(:no_extra_logdie_message);

#our @ISA = qw();

our $VERSION = '0.1';

my $L = Log::Log4perl::get_logger();
# Preloaded methods go here.

=head1 NAME

PipeWrap - Checkpoint system for perl modules.
Used in chloroExtractor, a scientific tool for extraction of chloroplast dna out of a whole plant genome.

=head1 SYNOPSIS

  use PipeWrap;

=head1 DESCRIPTION

Checkpoint system that supervises a given order of tasks given by a config file.
Tasks are tracked in a .trace file.

=head2 new

PipeWrap::new();

new() creates PipeWrap object with given options from config file.

=cut

has 'id' => (is => 'rw', isa => 'Any', default => basename($Script, qw(.pl .PL)));
has 'tasks' => (is => 'rw', isa => 'ArrayRef', trigger => \&_set_tasks);
has 'continue' => (is => 'rw', isa => 'Any', default => undef);
has 'skip' => (is => 'rw', isa => 'ArrayRef', default => sub { [] });
has 'trace_file' => (is => 'rw', isa => 'Any', default => undef);
has 'opt' => (is => 'rw', isa => 'HashRef', default => sub { {} });
has 'force' => (is => 'rw', isa => 'Any', default => undef);

has '_task_iter' => (is => 'rw', isa => 'Int', default => 0);
has '_task_index' => (is => 'rw', isa => 'HashRef', default => sub { {} });
has '_trace' => (is => 'rw', isa => 'Any', default => sub { {task_results => {},
								 init_time => undef,
								 update_time => undef,
								 task_done => undef}
		 });

							 

=head2 bless_tasks

=cut

=head2 _set_tasks


=cut

sub _set_tasks {
    my $self = shift;
    my ($new_tasks, $old_tasks) = @_;
    $self->{tasks} = [ map{ PipeWrap::Task->new(%$_) } @{$new_tasks} ];
    $self->index_tasks();
    return $self->tasks;

}


=head2 index_tasks

$new->index_tasks();

index_tasks() indicates all given tasks

=cut

sub index_tasks{
    my ($self) = @_;
    my $i=0;
    my %task_index;
    foreach my $task (@{$self->tasks}){
	#$L->logdie("Non-unique task id: $task") 
	if (exists $task_index{$task->id()}) {
	    #die;
	    $L->logdie("Non-unique task id: ".$task);
	}
	else {
	
	$task_index{$task->id()} = $i;
	$i++;
	
    } 
}   
    $self->{_task_index} = \%task_index;
}

=head2 run

$new->run();

run() runs current task give by object, increases tasknumber, saves current task number, can skip tasks, returns current task

=cut
    
sub run{
    my ($self) = @_;
    if($self->_task_iter == @{$self->tasks}){
	$self->_task_iter(0); # reset to 0
	$L->info($self->id, " pipeline completed");
	return undef;
    }elsif($self->_task_iter > @{$self->tasks}){
	$L->logdie("Trying to run a task outside the index");
    }

    # prep task
    my $task = $self->current_task;
    my $taskid = $task->id;
    # skip
    if(grep{
	$_ =~ /^[\/?]/
	    ? "$taskid" =~ $_
	    : "$taskid" eq $_
       }@{$self->skip}){

	$L->info("Skipping '$taskid', reusing old results if requested by other tasks");

    }else{

	# resolve dependencies
	$self->resolve_task($task);

	$L->info("Running '$taskid': @{$task->cmd()}");

	$self->trace_task_results->{"$task"} = $task->run();
    }

    # store results
    $self->update_trace();

    # incr. task
    $self->{_task_iter}++;

    return "$task";
}

=head2 resolve_task

$new->resolve_task($task);

resolves given task and returns corresponding cmd

=cut

sub resolve_task{
   my ($self, $task) = @_;
   my $tid = $task->id;
   my $cmd = $task->cmd;

   for(my $i=0;$i<@$cmd; $i++){
       my $x;
       while($cmd->[$i] =~ s/%([^%]*?)%/
		 $self->wildcard($tid, $1)
		 /gex){
       }
   }
   $L->debug("@$cmd");
   return $cmd;
}



=head2 wildcard

skipped because of ????

=cut

=head2 init_trace

$new->init_trace();

Initialize a persistent trace, implemented with 'Storable'. 

=cut

sub init_trace{
    my ($self) = @_;

    $self->trace_init_time(time());
    $self->trace_update_time(time());

    store($self->_trace, $self->trace_file)
	|| $L->logdie("Cannot create trace file: ".$self->trace_file);
    return $self->_trace;
}

=head2 load_trace

load_trace() loads persistent trace.

=cut

sub load_trace {
    my ($self, $continue) = @_;
    if (-e $self->trace_file) {
	my $inputdata;
	eval { $inputdata = retrieve($self->trace_file) };
	if ($@) {
	    $L->logdie("An unexpected error occured while trying to load file");
	} else {
	    $L->info("Import file trace from file");
	    $self->_trace($inputdata)
	}
    } else {
	$self->init_trace;
}

        if(! defined($self->trace_task_done) || ! length $self->trace_task_done){
	$self->_task_iter(0);
	$L->info("Running ",$self->id," from the beginning, no previous runs detected.");
	return $self->_trace;
    }

    if(defined($continue) && length $continue){ # continue from specific task
	if(exists $self->_task_index->{$continue}){
 	    if($self->_task_index->{$continue} && ! $self->force && ! exists $self->trace_task_results->{$self->_task_index->{$continue} -1}){
		$L->logdie("You want to continue from '$continue', however the previous task ".($self->_task_index->{$continue} -1) ." never finished. Use force to overrule");
	    }
	    
	    $L->info("Continuing after task '", $continue, "'");
	    $self->_task_iter($self->_task_index->{$continue});

	}else{
	    $L->logdie("Cannot continue, task '", $continue, "' unknown");
	}
    }else{ # continue from last completed task
	if(exists $self->_task_index->{$self->trace_task_done}){
	    if($self->_task_index->{$self->trace_task_done} +1 >= @{$self->tasks}){
		$L->logdie("Complete ",$self->id," run present, disable --continue to restart");
	    }

	    $L->info("Unfinished ",$self->id," run present, continuing after task '", $self->trace_task_done, "'");
	    $self->_task_iter($self->_task_index->{$self->trace_task_done} + 1);

	}else{
	    $L->logdie("Cannot continue, previous ",$self->id," run ended with task '", $self->trace_task_done, "', which is not part of the current task sequence");
	}
    }
    return $self->_trace;
}


=head2 update_trace

update_trace() stores latest pipeline status in .trace file

=cut

sub update_trace{
    my ($self) = @_;

    $self->trace_update_time(time());
    $self->trace_task_done($self->current_task->id);
    store($self->_trace, $self->trace_file)
	|| $L->logdie("Cannot store updated trace file: ".$self->trace_file);
    return $self->_trace;
}

=head2 current_task

current_task() gets the current task and determines current pipeline status with $self->task_iter

=cut

sub current_task{
    my ($self) = @_;
    return $self->tasks->[$self->_task_iter];
}

=head2 wildcard

wildcard() checks tasks for patterns and dies in doubt of non_identifyable tasks.

=cut
    
sub wildcard{
    my ($self, $tid, $p) = @_;
    my ($tix, $rel, $idx, $res);

    if(! $p){
	return $tid; # this task
    } # id
    elsif((my $id) = $p =~ /^\{([^\}]+)}$/){
	$L->logdie("Unknown task id '$id'") unless exists $self->_task_index->{$id};
	return $id;
    } # idx
    elsif(($rel, $idx) = $p =~ /^\[(-)?(\d+)\]$/){
        return $rel 
	    ? $self->tasks->[$self->_task_index->{$tid} - $idx]->id  # relative task idx
	    : $self->tasks->[$idx]->id;        # absolute task idx
    } # bin
    elsif($p =~ /^bin$/i){ # bin
	return $RealBin.'/';
    } # opt
    elsif($p =~ /^opt([\{\[].*[\]\}])/){
	$L->logdie("$p does not exist") unless eval 'exists $self->opt->'."$1";
	$res = eval '$self->opt->'."$1";
	return ref $res eq 'ARRAY' ? "@$res" : $res;
    } # res
    elsif((my $type, my $id_idx, $res) = $p =~ /^res
		(\[-|\{|\[)		# [- or [ or {
		([^\}\]]+)[\}\]]	# not ] or }, ] or }
		(.*)?/x			# result access
	){
	my $id;

	# idx, abs/rel
	$id = $self->tasks->[$self->_task_index->{$tid} - $id_idx]->id if $type eq '[-';
	$id = $self->tasks->[$id_idx]->id if $type eq '[';
	$id = $id_idx if $type eq '{';

    	return $res ? eval '$self->trace_task_results->'."{$id}".$res : eval '$self->trace_task_results->'."{$id}";
    }else{
	$L->logdie("unknown pattern $p");
    }
}

#---------<<<<<<<<<#####################>>>>>>>>>---------#
#---------<<<<<<<<<###---accessors---###>>>>>>>>>---------#
#---------<<<<<<<<<#####################>>>>>>>>>---------#                           

# Basic accessors are provided by Moose. See Moose manual for further explanations.
               
=head1 ACCESSORS
=cut
=head2 id

$new->id() get
$new->id($id) set
set and get id in the object

=cut

=head2 tasks

$new->tasks() get
$new->tasks($tasks) set
set and get tasks in the object

=cut

=head2 opt

$new->opt() get
$new->opt($opt) set
set and get options in the object

=cut

=head2 task_index

$new->task_index() get
$new->task_index($task_index) set
set and get task indicies

=cut

=head2 skip

$new->skip() get
$new->skip($skip) set
set and get tasks that shall not be run

=cut

=head2 continue

$new->continue() get
$new->continue($continue) set
set and get task after that shall be continued

=cut

=head2 task_iter

$new->task_iter() get
$new->task_iter($task_iter) set
set and get iteration of the current task

=cut

=head2 force

$new->force() get
$new->force($force) set
set and get if a task shall be forced 

=cut

=head2 trace_file

$new->trace_file() get
$new->trace_file($trace_file) set
set and get file trace 

=cut

=head2 trace

$new->trace() get
$new->trace($trace) set
set and get _trace
_trace contains task_results, init_time, update_time, task_done

=cut

=head2 trace_task_results

$new->trace_task_results() get
$new->trace_task_results($task_results) set
set and get task_results

=cut

sub trace_task_results{
    my ($self, $trace_task_results, $force) = @_;
    if (defined($trace_task_results || $force)) {
	$self->_trace->{task_results} = $trace_task_results;
    }
    return $self->_trace->{task_results};

}

=head2 trace_update_time

$new->trace_update_time() get
$new->trace_update_time($trace_update_time) set
set and get update of time trace

=cut

sub trace_update_time{
    my ($self, $trace_update_time, $force) = @_;
    if (defined($trace_update_time || $force)) {
        $self->_trace->{update_time} = $trace_update_time;
    }
    return $self->_trace->{update_time};

}

=head2 trace_init_time

$new->trace_init_time() get
$new->trace_init_time($trace_init_time) get
set and get initial time trace

=cut

sub trace_init_time{
    my ($self, $trace_init_time, $force) = @_;
    if (defined($trace_init_time || $force)) {
        $self->_trace->{init_time} = $trace_init_time;
    }
    return $self->_trace->{init_time};

}

=head2 trace_task_done

$new->trace_task_done() get
$new->trace_task_done($trace_task_done) set
set and get trace of completed tasks

=cut

sub trace_task_done{
    my ($self, $trace_task_done, $force) = @_;
    if (defined($trace_task_done || $force)) {
        $self->_trace->{task_done} = $trace_task_done;
    }
    return $self->_trace->{task_done};

}

1;
__END__

#---------<<<<<<<<<#####################>>>>>>>>>---------#
#---------<<<<<<<<<###---COPYRIGHT---###>>>>>>>>>---------#
#---------<<<<<<<<<###------AND------###>>>>>>>>>---------#                                         #---------<<<<<<<<<###----LICENSE----###>>>>>>>>>---------#                                         
#---------<<<<<<<<<#####################>>>>>>>>>---------#                                         

=head1 SEE ALSO                                                                 
Mention other use  

=head1 AUTHOR

Thomas Hackl, E<lt>mail<gt>\n
Simon Pfaff, E<lt>simon.pfaff@stud-mail.uni-wuerzburg.de<gt>\n
Aaron Sigmund, E<lt>aaron.sigmund@stud-mail.uni-wuerzburg.de<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by CCTB UniWuerzburg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
