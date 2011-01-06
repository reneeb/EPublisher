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
    
    $self->_define_fonts( $pdf );
    $self->_init_textsize;
    $self->_init_fontmap;
    
    $self->add_cover( $pdf, $cover_filename );
    $self->add_chapters( $pdf );
    $self->add_table_of_contents( $pdf );
}

sub add_cover {
    my ($self, $pdf, $cover) = @_;
}

sub add_chapters {
    my ($self,$pdf) = @_;
    
    
}

sub add_table_of_contents {
    my ($self, $pdf) = @_;
    
    my @headlines = @{ $self->{headlines} || [] };
    
    # insert toc as page nr 2
    my $page = $pdf->page( 2 );
    
    my $title = $self->_config->{toc_title} || 'Table of Content';
    
    # add title
    my ($title_font, $title_size) = $self->font( 'head1' );
    my @title_pos                 = $self->position( 'page_header' );
    my $title_text                = $pdf->text;
    
    $title_text->font( $title_font, $title_size );
    $title_text->translate( @title_pos );
    $title_text->text_left( $title );
    
    
    # add toc
    my $fonttype      = 'default';
    my ($font, $size) = $self->font( $fonttype );
    my @text_pos      = $self->position( 'text' );
    
    for my $head ( @headlines ) {
        my $text_object   = $pdf->text;
        my $text          = $head->{text};
        
        my $width = $self->text_width( $text, $font, $size );
        my $dots  = sprintf ' %s ', '.' x 3;
        
        $text_object->font($font,$size);
        $text_object->translate( @text_pos );
        $text_object->text_left( $text . $dots . $head->{page} );
    }
}

sub position {
    my ($self,$name) = @_;
    
    unless( $self->{position} ) {
        $self->{position} = {
            page_header => [0,0],
            text        => [0,0],
            default     => [0,0],
        };
    }
    
    if ( !$name or !exists $self->{position}->{$name} ) {
        $name = 'default';
    }
    
    return @{$self->{position}->{$name}};
}

sub font {
    my ($self,$name) = @_;
    
    my $map  = $self->_fontmap( $name );
    my $font = $self->_font( $map );
    my $size = $self->_textsize( $name );
    
    return ( $font, $size );
}

sub _textsize {
    my ($self,$name) = @_;
    
    if( !$name or !exists $self->{textsize}->{$name} ) {
        $name = 'default';
    }
    
    return $self->{textsize}->{$name};
}

sub _init_textsize {
    my ($self) = @_;
    
    $self->{textsize} = $self->_config->{textsize} || {
        head1   => 14,
        head2   => 12,
        head3   => 11,
        head4   => 10,
        default => 10,
    };
}

sub _fontmap {
    my ($self,$name) = @_;
    
    if ( !$name or !exists $self->{fontmap}->{$name} ) {
        $name = 'default';
    }
    
    return $self->{fontmap}->{$name};
}

sub _init_fontmap {
    my ($self) = @_;
    
    $self->{fontmap} = $self->_config->{fontmap} || {
        head1    => 'Helvetica-Bold',
        head2    => 'Helvetica-Bold',
        head3    => 'Helvetica-Bold',
        head4    => 'Helvetica-Bold',
        C        => 'Times',
        verbatim => 'Times',
        L        => 'Helvetica-Italic',
        default  => 'Helvetica',
    };
}

sub _font {
    my ($self,$name) = @_;
    
    return if !$name;
    
    my @parts = split /-/, $name;
    
    my $sub = $self->{fonts};
    
    PART:
    for my $part ( @parts ) {
        
        last PART if ref $sub and blessed $sub;
        
        return if ref $sub ne 'HASH';
        return if !exists $sub->{$part};
        
        $sub = $self->{fonts}->{$part};
    }
    
    return if ref $sub and !blessed $sub;
    return $sub;
}

sub _define_fonts {
    my ($self,$pdf) = @_;
    
    $self->{fonts} = {
        Helvetica => {
            Bold   => $pdf->corefont( 'Helvetica-Bold',    -encoding => 'UTF-8' ),
            Italic => $pdf->corefont( 'Helvetica',         -encoding => 'UTF-8' ),
            Roman  => $pdf->corefont( 'Helvetica-Oblique', -encoding => 'UTF-8' ),
        },
        Times => {
            Bold   => $pdf->corefont( 'Times-Bold',        -encoding => 'UTF-8' ),
            Italic => $pdf->corefont( 'Times',             -encoding => 'UTF-8' ),
            Roman  => $pdf->corefont( 'Times-Italic',      -encoding => 'UTF-8' ),
        },
    };
}

sub _parse_file {
    my ( $self, $file ) = @_;
    
    $self->{tree}    = Pod::Simple::SimpleTree->new->parse_file( $file )->root;
    $self->{content} = [ grep{
        my $ref = ref $_;
        $ref and $ref eq 'ARRAY' and
            $_->[0] =~ m{ \A head [12] \z }xms;
    }@{ $self->{tree} } ];
    
    #use Data::Dumper;
    #print Data::Dumper::Dumper [ $self->{tree}, $self->{content} ];
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
