package PipeWrap;

use Log::Log4perl qw(:easy :no_extra_logdie_message);


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
	tasks => [],
	@_
    };

    bless $self, $proto;    

    $self->index_tasks();
    
    return $self;
}

sub index_tasks{
    my ($self) = @_;
    my $i=0;
    my %task_index;
    foreach my $t ($self->tasks){
	$L->logdie("Non-unique task id: ", $task_index{$t->[0]}) if exists $task_index{$t->[0]};
	$task_index{$t->[0]} = $i;
	$i++;
    }
    
    $self->{task_index} = \%task_index;
}



=head2 run

=cut

sub run{
    my ($self) = @_;
    foreach my $task ($self->tasks){
	$self->resolve_task($task);
	my ($tid, $cmd, $res_parser) = @$task;
	$L->info("$tid: @$cmd");
	open(my $cmdh, "@$cmd |") or $L->logdie($!);
	$self->{task_results}{$tid} = $res_parser ? $self->$res_parser($cmdh) : <$cmdh>;
	close $cmdh;
    }
    

    $L->logcroak("$? $@") if ($? || $@);
#    $L->debug("Returned: ",@re);

    
    
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
	    ? $self->{tasks}[$self->{task_index}{$tid} - $idx][0]  # relative task idx
	    : $self->{tasks}[$self->{task_index}{$idx}][0];        # absolute task idx
    	return $res ? eval '$self->{task_results}'."{$tix}".$res : $tix;
    }elsif(($tix, $res) = $p =~ /^\{([^}]+)\}(.*)?/){
    	return $res ? eval '$self->{task_results}'."{$tix}".$res : $tix;
    }else{
	$L->logdie("unknown pattern $p");
    }
}









##----------------------------------------------------------------------------##
#Accessors


sub tasks{
    my ($self, @tasks) = @_;
    if(@tasks){
	$self->{tasks} = \@tasks;
    }
    return @{$self->{tasks}};
}

sub task_index{
    my ($self, %task_index) = @_;
    if(%task_index){
	$self->{task_index} = \%task_index;
    }
    return %{$self->{task_index}};
}

sub task_results{
    my ($self, %task_results) = @_;
    if(%task_results){
	$self->{task_results} = \%task_results;
    }
    return %{$self->{task_results}};
}


1;

