package EPublisher::Source::Plugin::Module;

# ABSTRACT:  Module source plugin

use strict;
use warnings;

use Module::Info;

use File::Basename;

use EPublisher::Source::Base;
use EPublisher::Utils::PPI qw(extract_pod);

our @ISA = qw( EPublisher::Source::Base );

our $VERSION = 0.05;

sub load_source{
    my ($self, $name) = @_;
    
    my $options = $self->_config;
    my $module  = $name // $options->{name};
    
    if ( !defined $module ) {
        $self->publisher->debug( '400: No module defined' );
        return;
    }

    my @my_inc = @{ $options->{lib} || [] };
    
    my $mod = Module::Info->new_from_module( $module, @my_inc );

    if ( !$mod ) {
        $self->publisher->debug( '400: Cannot find module' );
        return;
    }

    my $pod      = extract_pod( $mod->file, $self->_config );
    my $filename = File::Basename::basename( $mod->file );
    my $title    = $module;

    $options->{title} = '' if !defined $options->{title};

    if ( $options->{title} eq 'pod' ) {
        ($title) = $pod =~ m{ =head1 \s+ (.*) }x;
        $title   = '' if !defined $title;
    }
    elsif ( length $options->{title} ) {
        $title = $options->{title};
    }

    return { pod => $pod, filename => $filename, title => $title };
}

1;


__END__
=pod

=head1 NAME

EPublisher::Source::Plugin::Module - Module source plugin

=head1 VERSION

version 0.4

=head1 SYNOPSIS

  my $source_options = { type => 'Module', name => 'CGI', lib => [qw(/lib)] };
  my $module_source  = EPublisher::Source->new( $source_options );
  my $pod            = $module_source->load_source;

=head1 METHODS

=head2 load_source

  my $pod = $module_source->load_source;

reads the module 

  {
    pod      => $pod_document,
    filename => $file,
    title    => $title,
  }

C<$pod_document> is the complete pod documentation that was found in the file.
C<$file> is the name of the file (without path) and C<$title> is the title of
the pod documentation. By default it is the module name, but you can say "title => 'pod'"
in the configuration. The title is the first value for I<=head1> in the pod.

=cut

