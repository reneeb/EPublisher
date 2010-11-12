#!/usr/bin/perl

=pod

08_sources.t - test for the source plugins

=cut

use strict;
use warnings;

use Data::Dumper;

use Test::More tests => 21;
use File::Basename;
use File::Spec;
use lib qw(../lib ../../perllib);
use YAML::Tiny;

my $dir    = File::Spec->rel2abs( dirname( __FILE__ ) );

my $module = 'EPublisher::Source';
use_ok( $module );

#
# Module
###
{
   # test EPublisher::Source::Plugin::ReneePC
   my $source = $module->new({
      type => 'Module',
      name => 'EPublisher', 
   });
   ok( $source->isa( 'EPublisher::Source::Plugin::ReneePC' ), '$source isa EPublisher::Source::Plugin::ReneePC' );
   ok( $source->isa( 'EPublisher::Source::Base' ),            '$source isa EPublisher::Source::Base' );
   
   is( $source->load_source, 'EPublisher', 'check *::Module::load_source()' );
}

#
# File
###
{
   my $source = $module->new({
      type => 'File',
      path => __FILE__,
   });
   
   ok( $source->isa( 'EPublisher::Source::Plugin::File' ), '$source isa EPublisher::Source::Plugin::File' );
   ok( $source->isa( 'EPublisher::Source::Base' ),         '$source isa EPublisher::Source::Base' );
   
   is( $source->load_source, __FILE__, 'check *::SVN::LocalCopy::load_source()' );
}

#
# Force Error
###
{
   eval{
      my $source = $module->new({
         type => 'AnyNonExistentTargetPlugin',
      });
   };
   
   like( $@, qr/Problems with/, 'Force error' );
}
