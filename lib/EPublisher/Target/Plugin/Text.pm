package EPublisher::Target::Plugin::Text;

# ABSTRACT: Use Ascii text as a target for EPublisher

use strict;
use warnings;

use Carp;
use File::Basename;
use File::Temp;
use IO::String;
use Pod::Text;

use EPublisher;
use EPublisher::Target::Base;
our @ISA = qw(EPublisher::Target::Base);

our $VERSION = 0.03;
our $DEBUG   = 0;

sub deploy {
    my ($self, $sources) = @_;
    
    my $pods     = $sources || $self->_config->{source};
    my $width    = $self->_config->{width} || 78;
    my $sentence = $self->_config->{sentence};
    my $output   = $self->_config->{output};

    $pods = []                   if !defined $pods;
    $pods = [ { pod => $pods } ] if !ref $pods;

    return if 'ARRAY' ne ref $pods;
    return if !@{ $pods };

    if ( !$output ) {
        my $fh = File::Temp->new;
        $output = $fh->filename;
    }

    my $io     = IO::String->new( join "\n\n", map{ $_->{pod} }@{$pods} );
    my $parser = Pod::Text->new( sentence => $sentence, width => $width );

    $parser->parse_from_filehandle( $io, $output );
    
    return $output;
}

1;


__END__
=pod

=head1 SYNOPSIS

  use EPublisher::Target;
  my $Text = EPublisher::Target->new( { type => 'Text' } );
  $Text->deploy;

=head1 METHODS

=head2 deploy

creates the output.

  $Text->deploy;

=head2 testresult

=head1 YAML SPEC

  TextTest:
    source:
      #...
    target:
      type: Text
      output: /path/to/test.txt

=cut

