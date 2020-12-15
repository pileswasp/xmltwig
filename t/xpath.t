#!/usr/bin/perl -w

use strict;

use XML::XPath;

print "1..9\n";

    my $data_start = tell DATA; # save the position
    my $xp = XML::XPath->new( ioref => \*DATA );
use Data::Dumper; warn Dumper $xp;
    my @ccc = eval { $xp->findnodes( '//a/b[2]'); };
use Data::Dumper; warn Dumper \@ccc, 'found ok xpath';
    seek DATA, $data_start, 0;

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
