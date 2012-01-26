#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;

use Test::More tests => 9; 
use File::Basename;
use File::Spec;
use lib qw(../lib ../../perllib);
use YAML::Tiny;

my $dir    = File::Spec->rel2abs( dirname( __FILE__ ) );

my $module = 'EPublisher::Source';
use_ok( $module );

{
   my $source = $module->new({
      type => 'Dir',
      path => File::Spec->catdir( dirname( __FILE__ ), 'lib' ),
   });
   
   ok( $source->isa( 'EPublisher::Source::Plugin::Dir' ), '$source isa EPublisher::Source::Plugin::Dir' );
   ok( $source->isa( 'EPublisher::Source::Base' ),        '$source isa EPublisher::Source::Base' );

   my ($info) = $source->load_source;
   ok( $source->load_source, 'check *::Dir::load_source()' );

   my $check = {
       pod => '=pod

=head1 Text - a test library for text output

Ein Absatz im POD.

=cut
',
       filename => 'Text.pm',
       title => 'Text.pm',
   };
   
   is_deeply( $info, $check, 'check return value of *::File::load_source()' );
}

{
   my $source = $module->new({
      type => 'Dir',
      path => File::Spec->catdir( dirname( __FILE__ ), 'lib' ),
      title => 'pod',
   });
   
   ok( $source->isa( 'EPublisher::Source::Plugin::Dir' ), '$source isa EPublisher::Source::Plugin::Dir' );
   ok( $source->isa( 'EPublisher::Source::Base' ),         '$source isa EPublisher::Source::Base' );

   my ($info) = $source->load_source;
   ok( $source->load_source, 'check *::Dir::load_source()' );

   my $check = {
       pod => '=pod

=head1 Text - a test library for text output

Ein Absatz im POD.

=cut
',
       filename => 'Text.pm',
       title => 'Text - a test library for text output',
   };
   
   is_deeply( $info, $check, 'check return value of *::Dir::load_source()' );
}

