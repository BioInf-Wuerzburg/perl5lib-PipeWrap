package PipeWrap;

use 5.010001;
use strict;
use warnings;

our @ISA = qw();

our $VERSION = '0.1';


# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

PipeWrap - Checkpoint system for perl modules.
Used in chloroExtractor, a scientific tool for extraction of chloroplast dna out of a whole plant genome.

=head1 SYNOPSIS

  use PipeWrap;

=head1 DESCRIPTION

Checkpoint system that supervises a given order of tasks given by a config file.

=head2 new

PipeWrap::new();

new() creates PipeWrap object with given options from config file

=cut

=head2 bless_tasks

$new->bless_tasks();

bless_tasks() blesses tasks in PipeWrap object

=cut

=head2 index_tasks

$new->index_tasks();

index_tasks() indicates all given tasks

=cut

=head2 run

$new->run();

run() runs current task give by object, increases tasknumber, saves current task number, can skip tasks, returns current task

=cut

=head2 resolve_task

$new->resolve_task($task);

resolves given task and returns corresponding cmd

=cut

=head2 wildcard

skipped because of ????

=cut

=head2 init_trace

$new->init_trace();

Initialize a persistent trace, implemented with 'Storable'. 

=cut

=head2 load_trace

load_trace() loads persistent trace

=cut

=head2 update_trace

update_trace() stores latest pipeline status to trace

=cut

=head2 current_task

current_task() gets the current task and determines current pipeline status with $self->task_iter

=cut

#---------<<<<<<<<<#####################>>>>>>>>>---------#
#---------<<<<<<<<<###---accessors---###>>>>>>>>>---------#
#---------<<<<<<<<<#####################>>>>>>>>>---------#                                          
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

=head2 trace_update_time

$new->trace_update_time() get
$new->trace_update_time($trace_update_time) set
set and get update of time trace

=cut

=head2 trace_init_time

$new->trace_init_time() get
$new->trace_init_time($trace_init_time) get
set and get initial time trace

=cut

=head2 trace_task_done

$new->trace_task_done() get
$new->trace_task_done($trace_task_done) set
set and get trace of completed tasks

=cut

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
