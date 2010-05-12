#!/usr/bin/perl -w
use strict;


use Carp;
use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;

$|=1;
my $DEBUG=0;
 
use XML::Twig;

my $TMAX=4;
print "1..$TMAX\n";

# escape_gt option
{
is( XML::Twig->parse( '<d/>')->root->insert_new_elt( '#COMMENT' => '- -- -')->twig->sprint,
    '<d><!-- - - - - --></d>', 'comment escaping');
}

{ my $t=  XML::Twig->parse( '<d><e a="c">foo<e>bar</e></e><e a="b">baz<e>foobar</e></e><e a="b">baz2<e a="c">foobar2</e></e></d>');
  $t->root->cut_descendants( 'e[@a="c"]');
  is( $t->sprint, '<d><e a="b">baz<e>foobar</e></e><e a="b">baz2</e></d>', 'cut_descendants');
}

{ my $t=XML::Twig->new( pretty_print => 'none')->parse( '<d />');
  is( $t->root->_pretty_print, 0, '_pretty_print');
  $t->set_pretty_print( 'indented');
  is( $t->root->_pretty_print, 3, '_pretty_print');
}
1;
