package EPublisher::Target::Plugin::PDF;

use strict;
use warnings;
use Carp;
use Encode;
use File::Temp qw(tempfile);
use PDF::API2;
use Pod::Simple::SimpleTree;

use EPublisher;
use EPublisher::Target::Base;
our @ISA = qw(EPublisher::Target::Base);

our $VERSION = 0.01;
our $DEBUG   = 0;

my $h1_size = 16;
my $h2_size = 14;
my $h3_size = 12;
my $text_size = 11;

my $text_font;
my $bold_font;
my $italic_font;
my $verbatim_font;

sub deploy {
    my ($self) = @_;
    
    my $pods           = $self->_config->{source} || [];
    my $out_filename   = $self->_config->{output} || '';
    my $author         = $self->_config->{author} || 'Perl Author';
    my $title          = $self->_config->{title}  || 'Pod Document';
    my $language       = $self->_config->{lang}   || 'en';
    my $cover_filename = $self->_config->{cover}  || '';
    
    my $text   = join "\n\n", @{$pods};
    
    my ($pod_fh,$filename) = tempfile();
        
    print $pod_fh $text;
    close $pod_fh;
    
    my $config = $self->_config;
    
    $self->_parse_file( $filename );
    
    my $pdf = PDF::API2->new( -file => $out_filename );
    $pdf->info(
        Author       => $author,
        CreationDate => time,
        Creator      => 'EPublisher',
        Producer     => 'PDF::API2',
        Title        => $title,
    );
    
    $self->add_cover( $pdf, $cover_filename );
    $self->add_table_of_contents( $pdf );
    $self->add_chapters( $pdf );
}

sub add_cover {
    my ($self, $pdf, $cover) = @_;

sub _parse_file {
    my ( $self, $file ) = @_;
    
    $self->{tree}    = Pod::Simple::SimpleTree->new->parse_file( $file )->root;
    $self->{content} = [ grep{
        my $ref = ref $_;
        $ref and $ref eq 'ARRAY' and
            $_->[0] =~ m{ \A head [12] \z }xms;
    }@{ $self->{tree} } ];
    
    use Data::Dumper;
    print Data::Dumper::Dumper [ $self->{tree}, $self->{content} ];
}

1;

=head1 NAME

PDFlisher::Target::Plugin::PDF - Use PDF as a target for PDFlisher

=head1 SYNOPSIS

  use EPublisher::Target;
  my $PDF = EPublisher::Target->new( { type => 'PDF' } );
  $PDF->deploy;

=head1 METHODS

=head2 deploy

creates the output.

  $PDF->deploy;

=head2 testresult

=head1 YAML SPEC

  PDFTest:
    source:
      #...
    target:
      type: PDF
      author: reneeb
      output: /path/to/test.PDF

=head1 COPYRIGHT & LICENSE

Copyright 2010 Renee Baecker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms of Artistic License 2.0.

=head1 AUTHOR

Renee Baecker (E<lt>module@renee-baecker.deE<gt>)

=cut
