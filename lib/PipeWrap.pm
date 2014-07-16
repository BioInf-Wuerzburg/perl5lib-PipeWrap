package PipeWrap;

use Log::Log4perl qw(:easy :no_extra_logdie_message);
use FindBin qw($RealBin $Script);
use File::Basename;
use Storable;

use Data::Dumper;

use overload '""' => \&id;
use PipeWrap::Task;

#-----------------------------------------------------------------------------#
# Globals

our $VERSION = '0.01';

my $L = Log::Log4perl::get_logger();



#-----------------------------------------------------------------------------#
=head2 new

=cut

sub new{

    $L->debug("initiating object");

    my $proto = shift;
    my $self;
    my $class;
    
    # object method -> clone + overwrite
    if($class = ref $proto){ 
	return bless ({%$proto, @_}, $class);
    }

    # class method -> construct + overwrite
    # init empty obj
    $self = {
	# default
	id => basename($Script, qw(.pl .PL)),
	tasks => [],
	continue => undef,
	skip => [],
	trace_file => undef,	
	opt => {},
	# overwrite
	@_,
	# protected privates
	_task_iter => 0,
	_task_index => {},
	_trace => {
	    task_results => {},
	    init_time => undef,
	    update_time => undef,
	    task_done => undef,
	},
    };

    bless $self, $proto;    

    $self->trace_file($self->id.".trace") unless $self->trace_file;

    $self->bless_tasks();

    $self->index_tasks();

    defined($self->continue) 
	? $self->load_trace($self->continue)
	: $self->init_trace();

    return $self;
}



=head2 bless_tasks

=cut

sub bless_tasks{
    my ($self) = @_;

    return $self->tasks([
	map{
	    ref($_) eq 'PipeWrap::Task' ? $_ : PipeWrap::Task->new(%$_) 
	}@{$self->tasks}
	]);
}

=head2 index_tasks

=cut

sub index_tasks{
    my ($self) = @_;
    my $i=0;
    my %task_index;
    foreach my $task (@{$self->tasks}){
	$L->logdie("Non-unique task id: $task") if exists $task_index{"$task"};
	$task_index{"$task"} = $i;
	$i++;
    }
    
    $self->{_task_index} = \%task_index;
}



=head2 run

=cut

sub run{
    my ($self) = @_;
    if($self->task_iter >= @{$self->tasks}){
	$self->task_iter(0); # reset to 0
	$L->logdie("Trying to run a task outside the index");
	return undef;
    }


    # prep task
    my $task = $self->current_task;
    
    # skip
    if(grep{
	$_ =~ /^[\/?]/
	    ? "$task" =~ $_
	    : "$task" eq $_
       }@{$self->skip}){

	$L->info("Skipping '$tid', reusing old results if requested by other tasks");

    }else{

	# resolve dependencies
	$self->resolve_task($task);

	$L->info("Running '$task': @{$task->cmd()}");

	$self->trace_task_results->{"$task"} = $task->run();
    }

    # store results
    $self->update_trace();

    # incr. task
    $self->{_task_iter}++;

    if($self->task_iter >= @{$self->tasks}){
	$self->task_iter(0); # reset to 0
	$L->warn($self->id, " pipeline completed");
	return undef;
    }

    return "$task";
}


=head2 resolve_tasks

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

=cut

sub wildcard{
    my ($self, $tid, $p) = @_;
    my ($tix, $rel, $idx, $res);

    if(! $p){
	return $tid; # this task
    }elsif($p =~ /^bin$/i){
	return $RealBin;
    }elsif($p =~ /^opt(\{.*[\]\}])/){
	$L->logdie("$p does not exist") unless eval 'exists $self->opt->'."$1";
	$res = eval '$self->opt->'."$1";
	return ref $res eq ARRAY ? "@$res" : $res;
    }elsif(($rel, $idx, $res) = $p =~ /^\[(-)?(\d+)\](.*)?/){
        $tix = $rel 
	    ? $self->tasks->[$self->task_index->{$tid} - $idx]->id  # relative task idx
	    : $self->tasks->[$self->task_index->{$idx}]->id;        # absolute task idx
    	return $res ? eval '$self->task_results->'."{$tix}".$res : $tix;
    }elsif(($tix, $res) = $p =~ /^\{([^}]+)\}(.*)?/){
    	return $res ? eval '$self->task_results->'."{$tix}".$res : $tix;
    }else{
	$L->logdie("unknown pattern $p");
    }
}


=head2 init_trace

Initialize a persitent trace. Implemented with 'Storable'.

=cut

sub init_trace{
    my ($self) = @_;

    $self->trace_init_time(time());
    $self->trace_update_time(time());

    store($self->trace, $self->trace_file)
    	|| $L->logdie("Cannot create trace file: ".$self->trace_file);
    return $self->trace;
}

=head2 load_trace

Load persistent trace.

=cut

sub load_trace{
    my ($self, $continue) = @_;
    -e $self->trace_file
	? $self->trace(retrieve($self->trace_file))
	: $self->init_trace;

    if(! defined($self->trace_task_done) || ! length $self->trace_task_done){
	$self->task(0);
	$L->info("Running ",$self->name," from the beginning, no previous runs detected.");
	return $self->trace;
    }

    if(defined($continue) && length $continue){ # continue from specific task
	if(exists $self->task_index->{$continue}){
	    if($self->task_index->{$continue} > $self->task_index->{$self->trace_task_done}+1){
		$L->logdie("Cannot continue from task '$continue', previous run ended earlier '",$self->trace_task_done,"'");
	    }else{
		$L->info("Continuing after task '", $continue, "'");
		$self->task($self->task_index->{$continue});
	    }
	}else{
	    $L->logdie("Cannot continue, task '", $continue, "' unknown");
	}
    }else{ # continue from last completed task
	if(exists $self->task_index->{$self->trace_task_done}){
	    if($self->task_index->{$self->trace_task_done} +1 >= @{$self->tasks}){
		$L->logdie("Complete ",$self->name," run present, disable --continue to restart");
	    }else{
		$L->info("Unfinished ",$self->name," run present, continuing after task '", $self->trace_task_done, "'");
		$self->task($self->task_index->{$self->trace_task_done} + 1);
	    }
	}else{
	    $L->logdie("Cannot continue, previous ",$self->name," run ended with task '", $self->trace_task_done, "', which is not part of the current task sequence");
	}
    }
    return $self->trace;
}

=head2 update_trace

Store latest pipeline status to trace.

=cut

sub update_trace{
    my ($self) = @_;

    $self->trace_update_time(time());
    $self->trace_task_done($self->current_task->id);
    store($self->trace, $self->trace_file)
    	|| $L->logdie("Cannot store updated trace file: ".$self->trace_file);
    return $self->trace;
}

=head2 current_task

Get the current task, uses $self->task_iter to determine current
pipeline status.

=cut

sub current_task{
    my ($self) = @_;
    return $self->tasks->[$self->task_iter];
}


##----------------------------------------------------------------------------##
#Accessors

=head2 id

=cut

sub id{
    my ($self, $id, $force) = @_;
    if(defined($id) || $force){
	$self->{id} = $id;
    }
    return $self->{id};
}

=head2 tasks

=cut

sub tasks{
    my ($self, $tasks, $force) = @_;
    if(defined($tasks) || $force){
	$self->{tasks} = $tasks;
    }
    return $self->{tasks};
}

=head2 opt

=cut

sub opt{
    my ($self, $opt, $force) = @_;
    if(defined($opt) ||  $force){
	$self->{opt} = $opt;
    }
    return $self->{opt};
}

=head2 task_index

=cut

sub task_index{
    my ($self, $task_index, $force) = @_;
    if(defined($task_index) || $force){
	$self->{_task_index} = $task_index;
    }
    return $self->{_task_index};
}

=head2 skip

=cut

sub skip{
    my ($self, $skip, $force) = @_;
    if(defined($skip) || $force){
	$self->{skip} = $skip;
    }
    return $self->{skip};
}

=head2 continue

=cut

sub continue{
    my ($self, $continue, $force) = @_;
    if(defined($continue) || $force){
	$self->{continue} = $continue;
    }
    return $self->{continue};
}

=head2 

=cut

sub task_iter{
    my ($self, $task_iter, $force) = @_;
    if(defined($task_iter) || $force){
	$self->{_task_iter} = $task_iter;
    }
    return $self->{_task_iter};
}

=head2 trace_file

=cut

sub trace_file{
    my ($self, $trace_file, $force) = @_;
    if(defined($trace_file) || $force){
	$self->{trace_file} = $trace_file;
    }
    return $self->{trace_file};
}

=head2 trace

=cut

sub trace{
    my ($self, $trace, $force) = @_;
    if(defined($trace || $force)){
	$self->{_trace} = $trace;
    }
    return $self->{_trace};
    # privates
    for my $acc (qw(trace task task_index)){
	can_ok($Class, $acc);
	my $cache;
	is(($cache = $o->$acc), $o->{'_'.$acc}, $Class."->".$acc." get");
	is($o->$acc("wtf"), "wtf", $Class."->".$acc." set");
	is($o->$acc(undef,1), undef, $Class."->".$acc." unset");
	is($o->$acc($cache), $o->{'_'.$acc}, $Class."->".$acc." reset");
    }
}

=head2 trace_task_results

=cut

sub trace_task_results{
    my ($self, $trace_task_results, $force) = @_;
    if(defined($trace_task_results || $force)){
	$self->trace->{task_results} = $trace_task_results;
    }
    return $self->trace->{task_results};
}

=head2 trace_update_time

=cut

sub trace_update_time{
    my ($self, $trace_update_time, $force) = @_;
    if(defined($trace_update_time) || $force){
	$self->trace->{update_time} = $trace_update_time;
    }
    return $self->trace->{update_time};
}

=head2 trace_init_time

=cut

sub trace_init_time{
    my ($self, $trace_init_time, $force) = @_;
    if(defined($trace_init_time) || $force){
	$self->trace->{init_time} = $trace_init_time;
    }
    return $self->trace->{init_time};
}

=head2 trace_task_done

=cut

sub trace_task_done{
    my ($self, $task_done, $force) = @_;
    if(defined($task_done) || $force){
	$self->trace->{task_done} = $task_done;
    }
    return $self->trace->{task_done};
}


1;

