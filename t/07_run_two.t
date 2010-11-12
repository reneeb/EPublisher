#!/usr/bin/perl

use Test::More tests => 2;
use File::Spec;
use File::Temp;
use File::Basename;

my $module = 'EPublisher';
use_ok( $module );

my $debug = "";

my $dir       = File::Spec->rel2abs( dirname( __FILE__ ) );
my $include   = File::Spec->catfile( $dir, 'lib' );
my $txt       = File::Temp->new;

$txt->unlink_on_destroy( 1 );

my $config = {
    Test => {
        source => {
          type => 'Module',
          inc  => $include,
          name => 'Text',
        },
        target => {
            type => 'Txt',
            file => $txt->filename,
        },
    }
};

my $obj = $module->new( debug => \&debug );
$obj->{__config} = $config;

$obj->run( ['Test'] );

my $check = q!100: Module 300: Text !;
is( $debug, $check, 'debug' );


my $txt_check   = "Text - a test library for text output\n\nEin Absatz im POD.";
my $txt_content = do{ local( @ARGV, $/) = $txt->filename; <> };
is ( $txt_content, $txt_check, 'check generated text' );

sub debug{
    $debug .= $_[0] . " ";
}