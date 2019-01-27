package EPublisher::Target;

# ABSTRACT: Container for Target plugins

use strict;
use warnings;
use Carp;

our $VERSION = 0.01;

sub new{
    my ($class,$args) = @_;
    my $self;
    
    my $plugin = 'EPublisher::Target::Plugin::' . $args->{type};
    eval{
        (my $file = $plugin) =~ s!::!/!g;
        $file .= '.pm';
        
        require $file;
        $self = $plugin->new( $args );
    };
    
    croak "Problems with $plugin: $@" if $@;
    
    return $self;
}

1;

=head1 SYNOPSIS

  my $target_options = { type => 'CPAN', 'pause_id' => 'reneeb', pause_pass => 'secret' };
  my $cpan_target    = EPublisher::Target->new( $target_options );
  $cpan_target->any_plugin_subroutine;

=head1 METHODS

=head2 new

=cut
