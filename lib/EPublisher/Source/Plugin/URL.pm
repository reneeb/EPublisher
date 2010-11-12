package EPublisher::Source::Plugin::URL;

use strict;
use warnings;

use LWP::Simple;

use EPublisher::Source::Base;
use EPublisher::Utils::PPI qw(extract_pod_from_code);

our @ISA = qw( EPublisher::Source::Base );

our $VERSION = 0.01;

sub load_source{
    my ($self, $options) = @_;
    
    return '' unless $options->{url};
    
    my $code = get( $options->{url} );
    return extract_pod_from_code( $code );
}

1;

=head1 NAME

EPublisher::Source::Plugin::URL - URL source plugin

=head1 SYNOPSIS

  my $source_options = { type => 'URL', url => 'http://source.url/test.pm' };
  my $url_source     = EPublisher::Source->new( $source_options );
  my $pod            = $url_source->load_source;

=head1 METHODS

=head2 load_source

  $url_source->load_source;

reads the URL 

=head1 COPYRIGHT & LICENSE

Copyright 2010 Renee Baecker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of Artistic License 2.0.

=head1 AUTHOR

Renee Baecker (E<lt>URL@renee-baecker.deE<gt>)

=cut