package EPublisher::Target::Plugin::EPub;

use strict;
use warnings;
use Carp;
use Data::UUID;
use EBook::EPUB;
use File::Temp qw(tempfile);
use Pod::Simple::XHTML;

use EPublisher;
use EPublisher::Target::Base;
our @ISA = qw(EPublisher::Target::Base);

our $VERSION = 0.01;
our $DEBUG   = 0;

sub deploy {
    my ($self) = @_;
    
    my $pods = $self->_config->{source} || [];
    
    my $author         = $self->_config->{author} || 'Perl Author';
    my $title          = $self->_config->{title}  || 'Pod Document';
    my $language       = $self->_config->{lang}   || 'en';
    my $out_filename   = $self->_config->{output} || '';
    my $css_filename   = $self->_config->{css}    || '';
    my $cover_filename = $self->_config->{cover}  || '';
    my $version        = 0;
    
    # Create EPUB object
    my $epub = EBook::EPUB->new();

    # Set the ePub metadata.
    $epub->add_title( $title );
    $epub->add_author( $author );
    $epub->add_language( $language );

    # Add user defined cover image if it supplied.
    $self->add_cover( $epub, $cover_filename ) if $cover_filename;

    # Add the Dublin Core UUID.
    my $du = Data::UUID->new();
    my $uuid = $du->create_from_name_str( NameSpace_URL, 'www.perl.org' );

    {

        # Ignore overridden UUID warning form EBook::EPUB.
        local $SIG{__WARN__} = sub { };
        $epub->add_identifier( "urn:uuid:$uuid" );
    }

    # Add some other metadata to the OPF file.
    $epub->add_meta_item( 'EPublisher version',  $EPublisher::VERSION );
    $epub->add_meta_item( 'EBook::EPUB version', $EBook::EPUB::VERSION );


    # Get the user supplied or default css file name.
    $css_filename = $self->get_css_file( $css_filename );


    # Add package content: stylesheet, font, xhtml
    $epub->copy_stylesheet( $css_filename, 'styles/style.css' );
    
    my $counter = 1;
    
    for my $pod ( @{$pods} ) {
        $self->publisher->debug( 'Test' );
    
        my $parser = Pod::Simple::XHTML->new;
        $parser->index(0);
        
        my ($in_fh_temp,$in_file_temp) = tempfile();
        print $in_fh_temp $pod;
        close $in_fh_temp;
        
        my $in_fh;
        open $in_fh, '<', $in_file_temp;
    
        my ($xhtml_fh, $xhtml_filename) = tempfile();
        
        $parser->output_fh( $xhtml_fh );
        $parser->parse_file( $in_fh );

        close $xhtml_fh;
        close $in_fh;
        
        $epub->copy_xhtml( $xhtml_filename, "text/$counter.xhtml", linear => 'no' );
        
        # cleaning up...
        unlink $xhtml_filename;
        unlink $in_file_temp;
        
        $self->add_to_table_of_contents( $counter, $parser->{to_index} );
        
        $counter++;
    }

    # Add Pod headings to table of contents.
    $self->set_table_of_contents( $epub, $self->table_of_contents );

    # clean up...
    unlink $css_filename if !$self->user_css;

    # Generate the ePub eBook.
    $epub->pack_zip( $out_filename );
}

sub add_to_table_of_contents {
    my ($self,$page, $arrayref) = @_;
    
    push @{ $self->{__toc} }, +{ page => $page, headings => $arrayref };
    return 1;
}

sub table_of_contents {
    my ($self) = @_;
    
    return $self->{__toc};
}

sub _html_header {
    return
        qq{<?xml version="1.0" encoding="UTF-8"?>\n}
          . qq{<!DOCTYPE html\n}
          . qq{     PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"\n}
          . qq{    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">\n}
          . qq{\n}
          . qq{<html xmlns="http://www.w3.org/1999/xhtml">\n}
          . qq{<head>\n}
          . qq{<title></title>\n}
          . qq{<meta http-equiv="Content-Type" }
          . qq{content="text/html; charset=iso-8859-1"/>\n}
          . qq{<link rel="stylesheet" href="../styles/style.css" }
          . qq{type="text/css"/>\n}
          . qq{</head>\n}
          . qq{\n}
          . qq{<body>\n};
}

*Pod::Simple::XHTML::start_L  = sub {

    # The main code is taken from Pod::Simple::XHTML.
    my ( $self, $flags ) = @_;
    my ( $type, $to, $section ) = @{$flags}{ 'type', 'to', 'section' };
    my $url =
        $type eq 'url' ? $to
      : $type eq 'pod' ? $self->resolve_pod_page_link( $to, $section )
      : $type eq 'man' ? $self->resolve_man_page_link( $to, $section )
      :                  undef;

    # This is the new/overridden section.
    if ( defined $url ) {
        $url = Pod::Simple::XHTML::encode_entities( $url );
    }

    # If it's an unknown type, use an attribute-less <a> like HTML.pm.
    $self->{'scratch'} .= '<a' . ( $url ? ' href="' . $url . '">' : '>' );
};

sub set_table_of_contents {
    my ($self,$epub,$pod_headings) = @_;

    my $play_order   = 1;
    my $navpoint_obj = $epub;
    
    for my $content_part ( @{$pod_headings} ) {
        
        my $headings = $content_part->{headings};
        my $page     = $content_part->{page};

        for my $heading ( @{$headings} ) {

            my $heading_level = $heading->[0];
            my $section       = $heading->[1];
            my $label         = $heading->[2];
            my $content       = "text/$page.xhtml";

            # Only deal with head1 and head2 headings.
            next if $heading_level > 2;

            # Add the pod section to the NCX data, Except for the root heading.
            $content .= '#' . $section if $play_order > 1;

            my %options = (
                content    => $content,
                id         => 'navPoint-' . $play_order,
                play_order => $play_order,
                label      => $label,
            );

            $play_order++;

            # Add the navpoints at the correct nested level.
            if ( $heading_level == 1 ) {
                $navpoint_obj = $epub->add_navpoint( %options );
            }
            else {
                $navpoint_obj->add_navpoint( %options );
            }
        }
    }
}

sub get_css_file {
    my ($self,$css_filename) = @_;
    
    my $css_fh;

    # If the user supplied the css filename check if it exists.
    if ( $css_filename ) {
        if ( -e $css_filename ) {
            $self->user_css(1);
            return $css_filename;
        }
        else {
            warn "CSS file $css_filename not found.\n";
        }
    }

    # If the css file doesn't exist or wasted supplied create a default.
    ( $css_fh, $css_filename ) = tempfile();

    print $css_fh "h1         { font-size: 110%; }\n";
    print $css_fh "h2, h3, h4 { font-size: 100%; }\n";

    close $css_fh;

    return $css_filename;
}

sub user_css {
    my ($self,$value) = @_;
    
    return $self->{__user_css} if @_ != 2;
    $self->{__user_css} = $value;
}

sub add_cover {
    my ($self,$epub,$cover_filename) = @_;

    # Check if the cover image exists.
    if ( !-e $cover_filename ) {
        warn "Cover image $cover_filename not found.\n";
        return undef;
    }

    # Add cover metadata for iBooks.
    my $cover_id = $epub->copy_image( $cover_filename, 'images/cover.jpg' );
    $epub->add_meta_item( 'cover', $cover_id );

    # Add an additional cover page for other eBook readers.
    my $cover_xhtml =
        qq[<?xml version="1.0" encoding="UTF-8"?>\n]
      . qq[<!DOCTYPE html\n]
      . qq[     PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"\n]
      . qq[    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">\n\n]
      . qq[<html xmlns="http://www.w3.org/1999/xhtml">\n]
      . qq[<head>\n]
      . qq[<title></title>\n]
      . qq[<meta http-equiv="Content-Type" ]
      . qq[content="text/html; charset=iso-8859-1"/>\n]
      . qq[<style type="text/css"> img { max-width: 100%; }</style>\n]
      . qq[</head>\n]
      . qq[<body>\n]
      . qq[    <img alt="" src="../images/cover.jpg" />\n]
      . qq[</body>\n]
      . qq[</html>\n\n];

    # Crete a temp file for the cover xhtml.
    my ( $tmp_fh, $tmp_filename ) = tempfile();

    print $tmp_fh $cover_xhtml;
    close $tmp_fh;

    # Add the cover page to the ePub doc.
    $epub->copy_xhtml( $tmp_filename, 'text/cover.xhtml', linear => 'no' );

    # Add the cover to the OPF guide.
    my $guide_options = {
        type  => 'cover',
        href  => 'text/cover.xhtml',
        title => 'Cover',
    };

    $epub->guide->add_reference( $guide_options );

    # Cleanup the temp file.
    unlink $cover_xhtml;

    return $cover_id;
}

1;

=head1 NAME

EPublisher::Target::Plugin::EPub - Use EPub as a target for EPublisher

=head1 SYNOPSIS

  use EPublisher::Target;
  my $EPub = EPublisher::Target->new( { type => 'EPub' } );
  $EPub->deploy;

=head1 METHODS

=head2 deploy

creates the output.

  $EPub->deploy;

=head2 testresult

=head1 YAML SPEC

  EPubTest:
    source:
      #...
    target:
      type: EPub
      author: reneeb
      output: /path/to/test.epub

=head1 COPYRIGHT & LICENSE

Copyright 2010 Renee Baecker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms of Artistic License 2.0.

=head1 AUTHOR

Renee Baecker (E<lt>module@renee-baecker.deE<gt>)

=cut
