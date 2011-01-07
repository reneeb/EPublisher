package EPublisher::Utils::PPI;

use strict;
use warnings;

use Exporter;
use PPI;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw(
    extract_pod
    extract_pod_from_code
);

sub extract_pod {
    my ($file) = @_;
    
    return if !$file || ! -f $file;
    
    my $content = do{ local (@ARGV,$/) = $file; <> };
    return extract_pod_from_code( $content );
}

sub extract_pod_from_code {
    my ($code) = @_;
    
    return if !$code;
    
    my $parser    = PPI::Document->new( \$code );
    my $pod_nodes = $parser->find(
        sub {
             $_[1]->isa( 'PPI::Token::Pod' );
        },
    );
    
    my $merged = PPI::Token::Pod->merge( @{$pod_nodes || []} );
    
    return '' if !$merged;
    return $merged->content;
}

1;

=head1 NAME

EPublisher::Utils::PPI - PPI utility for EPublisher

=head1 COPYRIGHT & LICENSE

Copyright 2010 Renee Baecker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms of Artistic License 2.0.

=head1 AUTHOR

Renee Baecker (E<lt>module@renee-baecker.deE<gt>)

=cut