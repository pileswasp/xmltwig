#!/usr/bin/perl -w
use strict;

use Carp;
use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;

$|=1;
my $DEBUG=0;
 
use XML::Twig;

my $TMAX=34;
print "1..$TMAX\n";

{ my $d="<d><title section='1'>title</title><para>p 1</para> <para>p 2</para></d>";
  is( lf_in_t( XML::Twig->parse( pretty_print => 'indented', discard_spaces => 1, $d)), 1, 'space prevents indentation'); 
  is( lf_in_t( XML::Twig->parse( pretty_print => 'indented', discard_all_spaces => 1, $d)), 5, 'discard_all_spaces restores indentation'); 
}

sub lf_in_t
  { my($t)= @_;
    my @lfs= $t->sprint=~ m{\n}g;
    return scalar @lfs;
  }



{ my $d='<d id="d"><t1 id="t1"/><t2 id="t2"/><t3 att="a|b" id="t3-1" /><t3 att="a" id="t3-2" a2="a|b"/><t3 id="t3-3"><t4 id="t4"/></t3></d>';
  my @tests=
    ( [ 't1|t2',                  HN => 't1t2' ],
      [ 't1|t2|t3[@att="a|b"]',   HN => 't1t2t3-1' ],
      [ 't1|t2|t3[@att!="a|b"]',  HN => 't1t2t3-2t3-3' ],
      [ 't1|level(1)',            H  => 't1t1t2t3-1t3-2t3-3' ],
      [ 't1|level(2)',            H  => 't1t4' ],
      [ 't1|_all_',               H  => 't1t1t2t3-1t3-2t4t3-3d'],
      [ qr/t[12]/ . '|t3/t4',     H  => 't1t2t4' ],
      [ 't3[@a2="a|b"]',          HN => 't3-2' ],
      [ 't3[@a2="a|b"]|t3|t3/t4', H => 't3-1t3-2t3-2t4t3-3' ],
   );
  foreach my $test (@tests)
    { my $nb=0;
      my $ids='';
      my( $trigger, $test_cat, $expected_ids)= @$test;
      my $handlers= $test_cat =~ m{H} ?  { $trigger => sub { $ids.=$_->id; 1; } } : {};
      my $t= XML::Twig->new( twig_handlers => $handlers )->parse( $d);
      is( $ids, $expected_ids, "(H) trigger with alt: '$trigger'"); 

      my $uniq_ids= join '', sort $expected_ids=~m{(t\d(?:-\d)?)}g;

      if( $test_cat =~ m{X})
        { (my $xpath= "//$trigger")=~ s{\|t}{|//t}g;
          is( join( '', map { $_->id } $t->findnodes( $xpath)), $uniq_ids, " (X) path with |: '$trigger'"); 
        }

      if( $test_cat =~ m{N})
        { is( join( '', map { $_->id } $t->root->children( $trigger)), $uniq_ids, "(N)navigation with |: '$trigger'"); }
    }

}

{ my $t1= XML::Twig->parse( '<d id="d1"/>');
  is( XML::Twig->active_twig()->root->id, 'd1', 'active_twig, one twig');
  my $t2= XML::Twig->parse( '<d id="d2"/>');
  is( XML::Twig->active_twig()->root->id, 'd2', 'active_twig, second twig');
}

{ eval { XML::Twig->new(error_context => 1)->parse( $0); };
  matches( $@, "you seem to have used the parse method on a filename", 'parse on a file name');
}

{ my $got;
  XML::Twig->parse( twig_handlers => { 'e[@a]' => sub { $got .= $_->id; } }, '<d><e a="a" id="i1"/><e id="i2"/><e a="0" id="i3"/></d>');
  is( $got, 'i1i3', 'bare attribute in handler condition');
}

{ my $doc= q{<!DOCTYPE doc [ <!ELEMENT doc (#PCDATA)><!ENTITY ext SYSTEM "not_there.txt">]><doc>&ext;</doc>};
  ok( XML::Twig->parse( expand_external_ents => -1, $doc), 'failsafe expand_external_ents');
}
  
{ my $t=XML::Twig->parse( q{<doc><e><e1>e11</e1><e2>e21</e2></e><e><e1>e12</e1></e></doc>});
  is( join( ':',  $t->findvalues( [$t->root->children], "./e1")), 'e11:e12', 'findvalues on array');
}

{ my $t=XML::Twig->parse( "<doc/>"); 
  $t->set_encoding( "UTF-8");
  is( $t->sprint, qq{<?xml version="1.0" encoding="UTF-8"?>\n<doc/>}, 'set_encoding without XML declaration');
}

{ my $t=XML::Twig->parse( "<doc/>"); 
  $t->set_standalone( 1);
  is( $t->sprint, qq{<?xml version="1.0" standalone="yes"?>\n<doc/>}, 'set_standalone (yes) without XML declaration');
}

{ my $t=XML::Twig->parse( "<doc/>"); 
  $t->set_standalone( 0);
  is( $t->sprint, qq{<?xml version="1.0" standalone="no"?>\n<doc/>}, 'set_standalone (no) without XML declaration');
}

{ my $t=XML::Twig->parse( "<doc/>"); 
  nok( $t->xml_version, 'xml_version with no XML declaration');
  $t->set_xml_version( 1.1);
  is( $t->sprint, qq{<?xml version="1.1"?>\n<doc/>}, 'set_xml_version without XML declaration');
  is( $t->xml_version, 1.1, 'xml_version after being set');
}

{ my $t= XML::Twig->new;
  is( $t->_dump, "document\n", '_dump on an empty twig');
}

{ my $t=XML::Twig->parse( pretty_print => 'none', '<doc><f a="a">foo</f><f a="b">bar</f></doc>');
  $t->root->field_to_att( 'f[@a="b"]', 'g');
  is( $t->sprint, '<doc g="bar"><f a="a">foo</f></doc>', 'field_to_att on non-simple condition');
  $t->root->att_to_field( g => 'gg');
  is( $t->sprint, '<doc><gg>bar</gg><f a="a">foo</f></doc>', 'att_to_field with att != field');
}

{ my $t=XML::Twig->parse( '<root/>');
  $t->root->wrap_in( 'nroot');
  is( $t->sprint, '<nroot><root/></nroot>', 'wrapping the root');
}

{
my $t=XML::Twig->new;
XML::Twig::_set_weakrefs(0);
my $doc='<doc>\n  <e att="a">text</e><e>text <![CDATA[cdata text]]> more text <e>foo</e>\n more</e></doc>';
$t->parse( $doc);
$doc=~ s{\n  }{}; # just the first one
is( $t->sprint, $doc, 'parse with no weakrefs');
$t->root->insert_new_elt( first_child => x => 'text');
$doc=~ s{<doc>}{<doc><x>text</x>};
is( $t->sprint, $doc, 'insert first child with no weakrefs');
$t->root->insert_new_elt( last_child => x => 'text');
$doc=~ s{</doc>}{<x>text</x></doc>};
is( $t->sprint, $doc, 'insert last child with no weakrefs');
}

XML::Twig::_set_weakrefs(1);
