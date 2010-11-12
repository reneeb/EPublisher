#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;

use Test::More tests => 4;
use File::Basename;
use File::Spec;

my $dir    = File::Spec->rel2abs( dirname( __FILE__ ) );
unshift @INC, File::Spec->catdir( $dir, 'lib' );

my $module = 'EPublisher::Target';
use_ok( $module );

#
# Server
###
{
   my $target = $module->new({
      type => 'Text', 
      file => 'test.txt',
   });
   
   ok( $target->isa( 'EPublisher::Target::Plugin::Server' ), '$target isa EPublisher::Target::Plugin::Server' );
   ok( $target->isa( 'EPublisher::Target::Base' ),           '$target isa EPublisher::Target::Base' );
}

#
# Force Error
###
{
   eval{
      my $target = $module->new({
         type => 'AnyNonExistentTargetPlugin',
      });
   };
   
   like( $@, qr/Problems with/, 'Force error' );
}