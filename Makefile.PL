# $Id: Makefile.PL,v 1.2 2001/05/19 20:31:06 matt Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'XML::Handler::HTMLWriter',
    'VERSION_FROM'	=> 'HTMLWriter.pm', # finds $VERSION
    'AUTHOR'            => 'Matt Sergeant',
    'ABSTRACT'          => 'HTML Output from XHTML SAX events',
);
