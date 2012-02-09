package EPublisher::Source::Plugin::Dir;

# ABSTRACT: Dir source plugin

use strict;
use warnings;

use File::Find::Rule;
use File::Basename;

use EPublisher::Source::Base;
use EPublisher::Utils::PPI qw(extract_pod);

our @ISA = qw( EPublisher::Source::Base );

our $VERSION = 0.03;

sub load_source{
    my ($self) = @_;
    
    my $options = $self->_config;
    
    my $path = $options->{path};
    
    unless( $path && -d $path ) {
        $self->publisher->debug( "400: $path -> " . ( -d $path or 0 ) );
        return '';
    }
    
    my @files = File::Find::Rule->file->name( qr/\.p(?:m|od|l)\z/ )->in( $path );
    my @pods;
    
    FILE:
    for my $file ( @files ) {
        my $pod = extract_pod( $file );
        
        next FILE if !$pod;

        my $filename = basename $file;
        my $title    = $filename;

        if ( $options->{title} and $options->{title} eq 'pod' ) {
            ($title) = $pod =~ m{ =head1 \s+ (.*) }x;
            $title = '' if !defined $title;
        }
        elsif ( $options->{title} and $options->{title} ne 'pod' ) {
            $title = $options->{title};
        }
        
        push @pods, { pod => $pod, title => $title, filename => $filename };
    }
    
    return @pods;
}

1;

=head1 SYNOPSIS

  my $source_options = { type => 'Dir', path => '/var/lib/' };
  my $file_source    = EPublisher::Source->new( $source_options );
  my $pod            = $File_source->load_source;

=head1 METHODS

=head2 load_source

  my $pod = $file_source->load_source;

checks all pod/pm/pl files in the given directory (and its subdirectories)
and returns information about those files:

  (
      {
          pod      => $pod_document,
          filename => $file,
          title    => $title,
      },
  )

C<$pod_document> is the complete pod documentation that was found in the file.
C<$file> is the name of the file (without path) and C<$title> is the title of
the pod documentation. By default it is the filename, but you can say "title => 'pod'"
in the configuration. The title is the first value for I<=head1> in the pod.

=head1 COPYRIGHT & LICENSE

Copyright 2010 - 2012 Renee Baecker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of Artistic License 2.0.

=head1 AUTHOR

Renee Baecker (E<lt>module@renee-baecker.deE<gt>)

=cut
