# $Id: Makefile.PL,v 1.3 2002/01/27 21:23:13 matt Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'XML::Handler::HTMLWriter',
    'VERSION_FROM'	=> 'HTMLWriter.pm', # finds $VERSION
    'AUTHOR'            => 'Matt Sergeant',
    'ABSTRACT'          => 'HTML Output from XHTML SAX events',
    'PREREQ_PM'         => {
        HTML::Entities => 1.22,
        XML::SAX::Writer => 0.39,
    },
);
