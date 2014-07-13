package PipeWrap;

use Log::Log4perl qw(:easy :no_extra_logdie_message);
use FindBin qw($RealBin $Script);
use File::Basename;
use Storable;

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
	tasks => [],
	continue => undef,
	skip => [],
	# overwrite
	@_,
	# protected privates
	_task => 0,
	_task_index => {},
	_trace => {
	    task_results => {},
	    init_time => undef,
	    update_time => undef,
	    task_done => -1,
	},
	_trace_file => basename($Script, qw(.pl .PL)).".trace",
    };

    bless $self, $proto;    

    $self->index_tasks();

    defined($self->continue) 
	? $self->load_trace($self->continue)
	: $self->init_trace();

    return $self;
}

sub index_tasks{
    my ($self) = @_;
    my $i=0;
    my %task_index;
    foreach my $t (@{$self->tasks}){
	$L->logdie("Non-unique task id: ", $task_index{$t->[0]}) if exists $task_index{$t->[0]};
	$task_index{$t->[0]} = $i;
	$i++;
    }
    
    $self->{_task_index} = \%task_index;
}



=head2 run

=cut

sub run{
    my ($self) = @_;
    if($self->task >= @{$self->tasks}){
	$self->task(0); # reset to 0
	$L->logdie("Trying to run a task outside the index");
	return undef;
    }


    # prep task
    my $task = $self->tasks->[$self->task];
    my ($tid, $cmd, $res_parser);
    $tid = $self->tasks->[$self->task][0];
    
    # skip
    if(grep{$tid =~ $_}@{$self->skip}){

	$L->info("Skipping '$tid', reusing old results if requested by other tasks");

    }else{

	# resolve dependencies
	$self->resolve_task($task);

	($tid, $cmd, $res_parser) = @$task;
	$L->info("Running '$tid': @$cmd ");

	# run task
	open(my $cmdh, "@$cmd |") or $L->logdie($!);

	# retrieve results
	$self->task_results->{$tid} = $res_parser ? $self->$res_parser($cmdh) : <$cmdh>;
	close $cmdh;
	$L->logcroak("$? $@") if ($? || $@);

    }

    # store results
    $self->update_trace();

    # incr. task
    $self->{_task}++;

    if($self->task >= @{$self->tasks}){
	$self->task(0); # reset to 0
	$L->warn("Task sequence completed");
	return undef;
    }

    return $tid;
}


=head2 resolve_tasks

=cut

sub resolve_task{
   my ($self, $task) = @_;
   my $tid = $task->[0];
   my $cmd = $task->[1];

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


sub wildcard{
    my ($self, $tid, $p) = @_;
    my ($tix, $rel, $idx, $res);

    if(! $p){
	return $tid; # this task
    }elsif(($rel, $idx, $res) = $p =~ /^\[(-)?(\d+)\](.*)?/){
        $tix = $rel 
	    ? $self->{tasks}[$self->{_task_index}{$tid} - $idx][0]  # relative task idx
	    : $self->{tasks}[$self->{_task_index}{$idx}][0];        # absolute task idx
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
		$L->info("Previous sequence finished. Restarting task sequence");
		$self->task(0);
	    }else{
		$L->info("Detected unfinished sequence, continuing after task '", $self->trace_task_done, "'");
		$self->task($self->task_index->{$self->trace_task_done} + 1);
	    }
	}else{
	    $L->logdie("Cannot continue, previous run ended with task '", $self->trace_task_done, "', which is not part of the current sequence");
	}
    }
}

=head2 update_trace

Store latest pipeline status to trace.

=cut

sub update_trace{
    my ($self) = @_;

    $self->trace_update_time(time());
    $self->trace_task_done($self->tasks->[$self->task][0]);
    store($self->trace, $self->trace_file)
    	|| $L->logdie("Cannot store updated trace file: ".$self->trace_file);
    return $self->trace;
}

##----------------------------------------------------------------------------##
#Accessors


sub tasks{
    my ($self, $tasks) = @_;
    if(defined($tasks)){
	$self->{tasks} = $tasks;
    }
    return $self->{tasks};
}

sub task_index{
    my ($self, $task_index) = @_;
    if(defined($task_index)){
	$self->{_task_index} = $task_index;
    }
    return $self->{_task_index};
}

sub task_results{
    my ($self, $task_results) = @_;
    if(defined($task_results)){
	$self->{_trace}{task_results} = $task_results;
    }
    return $self->{_trace}{task_results};
}

sub trace{
    my ($self, $trace) = @_;
    if(defined($trace)){
	$self->{_trace} = $trace;
    }
    return $self->{_trace};
}

sub skip{
    my ($self, $skip) = @_;
    if(defined($skip)){
	$self->{skip} = $skip;
    }
    return $self->{skip};
}

sub continue{
    my ($self, $continue, $force) = @_;
    if(defined($continue) || $force){
	$self->{continue} = $continue;
    }
    return $self->{continue};
}

sub task{
    my ($self, $task, $force) = @_;
    if(defined($task) || $force){
	$self->{_task} = $task;
    }
    return $self->{_task};
}


sub trace_file{
    my ($self, $trace_file, $force) = @_;
    if(defined($trace_file) || $force){
	$self->{_trace_file} = $trace_file;
    }
    return $self->{_trace_file};
}

sub trace_update_time{
    my ($self, $trace_update_time, $force) = @_;
    if(defined($trace_update_time) || $force){
	$self->trace->{update_time} = $trace_update_time;
    }
    return $self->trace->{update_time};
}

sub trace_init_time{
    my ($self, $trace_init_time, $force) = @_;
    if(defined($trace_init_time) || $force){
	$self->trace->{init_time} = $trace_init_time;
    }
    return $self->trace->{init_time};
}

sub trace_task_done{
    my ($self, $task_done, $force) = @_;
    if(defined($task_done) || $force){
	$self->trace->{task_done} = $task_done;
    }
    return $self->trace->{task_done};
}


1;

