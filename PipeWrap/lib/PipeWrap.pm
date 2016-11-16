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

=head2 init_trace

tba

=cut

=head2 load_trace

tba

=cut

=head2 update_trace

tba

=cut

=head2 current_task

tba

=cut

#---------<<<<<<<<<#####################>>>>>>>>>---------#
#---------<<<<<<<<<###---accessors---###>>>>>>>>>---------#
#---------<<<<<<<<<#####################>>>>>>>>>---------#                                          
=head2 id

tba

=cut

=head2 tasks

tba

=cut

=head2 opt

tba

=cut

=head2 task_index

tba

=cut

=head2 skip

tba

=cut

=head2 continue

tba

=cut

=head2 task_iter

tba

=cut

=head2 force

tba

=cut

=head2 trace_file

tba

=cut

=head2 trace

tba

=cut

=head2 trace_task_results

tba

=cut

=head2 trace_update_time

tba

=cut

=head2 trace_init_time

tba

=cut

=head2 trace_task_done

tba

=cut

#---------<<<<<<<<<#####################>>>>>>>>>---------#
#---------<<<<<<<<<###---COPYRIGHT---###>>>>>>>>>---------#
#---------<<<<<<<<<###------AND------###>>>>>>>>>---------#                                         #---------<<<<<<<<<###----LICENSE----###>>>>>>>>>---------#                                         
#---------<<<<<<<<<#####################>>>>>>>>>---------#                                         

=head1 SEE ALSO                                                                 
Mention other use  

=head1 AUTHOR

Thomas Hackl, E<lt>mail<gt>
Simon Pfaff, E<lt>simon.pfaff@stud-mail.uni-wuerzburg.de<gt>
Aaron Sigmund, E<lt>aaron.sigmund@stud-mail.uni-wuerzburg.de<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by CCTB UniWuerzburg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
