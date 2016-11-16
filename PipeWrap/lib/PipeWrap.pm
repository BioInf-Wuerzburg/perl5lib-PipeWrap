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

run() 

=head1 SEE ALSO                                                                                      
Mention other useful documentation such as the documentation of                                      
related modules or operating system documentation (such as man pages                                 
documentation such as RFCs or                                                                       
standards.  

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
