package PipeWrap::Task;

use Log::Log4perl qw(:easy :no_extra_logdie_message);
use overload '""' => \&id;
use Data::Dumper;

#-----------------------------------------------------------------------------#
# Globals

our $VERSION = '0.01';

my $L = Log::Log4perl::get_logger();



#-----------------------------------------------------------------------------#
=head2 new

=cut

sub new{

    $L->debug("initiating ".__PACKAGE__." object");

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
	id => '',
	cmd => [],
	parser => undef,
	# overwrite
	@_,
	# protected privates
    };

    bless $self, $proto;    

    return $self;
}


=head2 run

=cut

sub run{
    my ($self) = @_;
    # run task
    open(my $cmdh, "@{$self->cmd()} |") or $L->logdie($!);
    
    # retrieve results
    my $re = ref $self->parser eq 'CODE' ? $self->parser($cmdh) : do{local $/; <$cmdh>};
    close $cmdh;
    $L->logcroak("$tid exited:$? $@\n", $re) if ($? || $@);
    
    $L->debug("$self returned:\n".Dumper($re));

    return $re;
}


##----------------------------------------------------------------------------##
#Accessors

=head2 cmd

Get/set command.

=cut

sub cmd{
    my ($self, $cmd, $force) = @_;
    if(defined($cmd) || $force){
	$self->{cmd} = $cmd;
    }
    return $self->{cmd};
}


=head2 id

Get/set id.

=cut

sub id{
    my ($self, $id, $force) = @_;
    if(defined($id) || $force){
	$self->{id} = $id;
    }
    return $self->{id};
}

=head2 parser

Get/set result parser

=cut

sub parser{
    my ($self, $parser, $force) = @_;
    if(defined($parser) || $force){
	$self->{parser} = $parser;
    }
    return $self->{parser};
}

1;

