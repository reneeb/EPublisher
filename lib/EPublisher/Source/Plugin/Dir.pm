package EPublisher::Source::Plugin::Dir;

# ABSTRACT: Dir source plugin

use strict;
use warnings;

use File::Find::Rule;

use EPublisher::Source::Base;
use EPublisher::Utils::PPI qw(extract_pod);

our @ISA = qw( EPublisher::Source::Base );

our $VERSION = 0.01;

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
        
        push @pods, $pod;
    }
    
    return @pods;
}

1;

=head1 SYNOPSIS

  my $source_options = { type => 'File', path => '/var/lib/CGI.pm' };
  my $file_source    = EPublisher::Source->new( $source_options );
  my $pod            = $File_source->load_source;

=head1 METHODS

=head2 load_source

  my $pod = $file_source->load_source;

reads the File 

=head1 COPYRIGHT & LICENSE

Copyright 2010 Renee Baecker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of Artistic License 2.0.

=head1 AUTHOR

Renee Baecker (E<lt>File@renee-baecker.deE<gt>)

=cut
