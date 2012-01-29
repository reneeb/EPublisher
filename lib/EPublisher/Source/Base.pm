package EPublisher::Source::Base;

# ABSTRACT: Base class for Source plugins

use strict;
use warnings;
use Carp;

our $VERSION = 0.02;

sub new{
    my ($class,$args) = @_;
    
    my $self = bless {}, $class;
    $self->_config( $args );
    
    return $self;
}

sub _config{
    my ($self,$args) = @_;
    
    $self->{__config} = $args if defined $args;
    return $self->{__config};
}

sub publisher {
    my ($self,$object) = @_;
    
    return $self->{__publisher} if @_ != 2;
    
    $self->{__publisher} = $object;
}

1;

=head1 SYNOPSIS

  package EPublisher::Source::Plugin::AnyVCS;
  use  EPublisher::Source::Base;
  
  our @ISA = qw(EPublisher::Source::Base);
  
  # ... more code ...

=head1 METHODS

=head2 new

=head2 publisher

=head2 _config

=head1 HOW TO WRITE YOUR OWN SOURCE PLUGIN

It's fairly simple to write your own plugin. Basically it has to inherit from
this module and it has to provide the methods C<new> and C<load_source>.

C<new> has to return an object and C<load_source> has to return a list
of hashreferences where each reference should look like

  {
      pod => $pod_as_string,
      filename => $filename_of_documentation,
      title    => $a_title_for_documentation,
  }

=head1 COPYRIGHT & LICENSE

Copyright 2010 - 2012 Renee Baecker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms of Artistic License 2.0.

=head1 AUTHOR

Renee Baecker (E<lt>module@renee-baecker.deE<gt>)

=cut
