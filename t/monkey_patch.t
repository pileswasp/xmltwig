#!/usr/bin/perl -w

# Probably best to keep this in a separate test as we will be monkeying with the
# symbol table
use strict;

use XML::Twig;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir,"t");
use tools;

print "1..9\n";

# Test to ensure that if we are using XML::XPathEngine, subsequent use of 
# XML::XPath by an application does not generate a warning. See:
# https://github.com/mirod/xmltwig/issues/38
if( _use( 'XML::XPathEngine') && _use( 'XML::XPath') )
  { # Pretend we didn't load XML::XPath::NodeSet
    delete $INC{'XML/XPath/NodeSet.pm'};
    for my $ref (keys %XML::XPath::NodeSet::) {
        undef *{$XML::XPath::NodeSet::{$ref}};
    }
    # use the monkey patcher
    _use( 'XML::Twig::XPath');
    eval {
        local $SIG{__WARN__} = sub { die @_ if $_[0] =~ /sort redefined/ };
        require XML::XPath::NodeSet;
    };
    ok( !$@, 'No Subroutine redefined warning' );
  }
else
  { skip( 1, 'Needs XML::XPath and XML::XPathEngine' ); }

# Test that our search works and XML::XPathEngine::NodeSet still works
# (semi-)independently. XML::XPathEngine seems okay with this, so this
# test is just for completeness.
if( _use( 'XML::XPathEngine') )
  { my $data_start = tell DATA; # save the position

    my $t= XML::Twig::XPath->new->parse( \*DATA);
    ok( $t, 'Parse success' );
    my @bbb = eval { $t->findnodes( '//a/b[2]'); };
    ok( !$@, 'No error' );
    ok( @bbb == 2, 'Found 2 ');

    seek DATA, $data_start, 0;
    my $xpe = XML::XPathEngine->new;
    @bbb = $xpe->findnodes( '//a/b[2]', $t );
    ok(@bbb, 'Found nodes');

    seek DATA, $data_start, 0; # For the next set of tests
  }
else 
  { skip( 4, 'Needs XML::XPathEngine' ); }

# Test that XML::XPath::NodeSet can still work independently
if( _use( 'XML::XPath') )
  { my $data_start = tell DATA; # save the position
    my $path = '//a/b[2]';
    my $t = XML::XPath->new( ioref => \*DATA);
    ok( $t, 'parsed ok');
    my @bbb = eval { $t->findnodes( $path); };
    ok( !$@, 'no error');
    ok(@bbb, 'found ok before');

    # Force reloading
    delete $INC{'XML/Twig/XPath.pm'};
    # Silence warnings
    for my $ref (keys %XML::Twig::XPath::) {
        undef *{$XML::Twig::XPath::{$ref}};
    }
    # Ensure we set $XPATH to XML::XPath
    XML::Twig::_disallow_use('XML::XPathEngine');
    _use( 'XML::Twig::XPath');
 
    seek DATA, $data_start, 0;
    my $xp = XML::XPath->new( ioref => \*DATA);
    my @ccc = eval { $xp->findnodes( $path); };
    ok(@ccc, 'found ok after');
    seek DATA, $data_start, 0;
  }
else 
  { skip( 4, 'Needs XML::XPath' ); }

exit 0;

__DATA__
<xml>
    <a>
        <b>some 1</b>
        <b>value 1</b>
    </a>
    <a>
        <b>some 2</b>
        <b>value 2</b>
    </a>
</xml>
