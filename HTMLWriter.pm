# $Id: HTMLWriter.pm,v 1.2 2001/05/19 20:32:26 matt Exp $

package XML::Handler::HTMLWriter;

use strict;
use vars qw($VERSION);

$VERSION = '0.01';

use vars qw/$xmlns_ns/;

$xmlns_ns = "http://www.w3.org/2000/xmlns/";

sub new {
    my $class = shift;
    my %params = @_;
    bless {}, $class;
}

sub print {
    my $self = shift;
    
    my $fh = $self->{Output};
    print $fh @_ if $fh;
    push(@{$self->{Strings}}, @_) unless $self->{NoString};
}

my %xml_escapes = (
    '&' => '&amp;',
    '<' => '&lt;',
    '"' => '&quot;',
    );

sub escape_xml {
    my $self = shift;
    my $text = shift;
    $text =~ s/([&<"])/$xml_escapes{$1}/g;
    return $text;
}

sub escape_attrib {
    my $self = shift;
    my $text = shift;
    $text =~ s/&(?!\{)/&amp;/g;
    $text =~ s/"/&quot;/g;
    return $text;
}

sub escape_url {
    my $self = shift;
    my $toencode = shift;
    $toencode =~ s/&(?!\{)/&amp;/g;
    $toencode =~ s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/eg;
    return $toencode;
}

sub output_as_xml {
    my $self = shift;
    my %params = @_;
    
    if (my $element = $params{start}) {
        $self->print("<$element->{Name}");

        foreach my $attr (@{$element->{Attributes}}) {
            $self->print(" $attr->{Name}=\"", 
                $self->escape_xml($attr->{Value}),
                "\"");
        }

        $self->print(">");

    }
    
    if (my $element = $params{end}) {
        $self->print("</$element->{Name}>");
    }
}

my @html_tags = qw(
    a abbr acronym address
    applet area b base
    basefont bdo big blockquote
    body br button caption
    center cite code col
    colgroup dd del dfn
    dir div dl dt
    em fieldset font form
    frame frameset h1 h2
    h3 h4 h5 h6
    head hr html i
    iframe img input ins
    isindex kbd label legend
    li link map menu
    meta noframes noscript object
    ol optgroup option p
    param pre q s
    samp script select small
    span strike strong style
    sub sup table tbody
    td textarea tfoot th
    thead title tr tt
    u ul var
    );

sub is_html_tag {
    my $self = shift;
    my $tag = lc(shift);
    
    return grep /^$tag$/, @html_tags;
}

my @empty_tags = qw(
    area base basefont
    br col frame hr img 
    input isindex link 
    meta param
    );

sub is_empty_tag {
    my $self = shift;
    my $tag = lc(shift);
    
    return grep /^$tag$/, @empty_tags;
}

my @uri_attribs = qw(
    form/action
    body/background
    blockquote/cite
    q/cite
    del/cite
    ins/cite
    object/classid
    object/codebase
    applet/codebase
    object/data
    a/href
    area/href
    link/href
    base/href
    img/longdesc
    frame/longdesc
    iframe/longdesc
    head/profile
    script/src
    input/src
    frame/src
    iframe/src
    img/src
    img/usemap
    input/usemap
    object/usemap
    );

sub is_uri_attrib {
    my $self = shift;
    my $test = lc(shift);
    
    return grep /^$test$/, @uri_attribs;
}

my @bool_attribs = qw(
    input/checked
    dir/compact
    dl/compact
    menu/compact
    ol/compact
    ul/compact
    object/declare
    script/defer
    button/disabled
    input/disabled
    optgroup/disabled
    option/disabled
    select/disabled
    textarea/disabled
    img/ismap
    input/ismap
    select/multiple
    area/nohref
    frame/noresize
    hr/noshade
    td/nowrap
    th/nowrap
    textarea/readonly
    input/readonly
    option/selected
    );

sub is_boolean_attrib {
    my $self = shift;
    my $test = lc(shift);
    
    return grep /^$test$/, @bool_attribs;
}

sub make_sax2_attribs {
    my $self = shift;
    my $element = shift;
    
    if (ref($element->{Attributes}) ne 'HASH') {
        # already SAX2 attribs!
        return;
    }
    
    $self->{Current_Is_SAX1} = 1;
    
    push @{ $self->{InScopeNamespaceStack} },
         { %{ $self->{InScopeNamespaceStack}[-1] } };
    $self->_scan_namespaces(%{$element->{Attributes}});
    
    my @attribs;
    foreach my $key (keys %{$element->{Attributes}}) {
        my $namespace = $self->_namespace($key);
        push @attribs, {
                Name => $key,
                Value => $element->{Attributes}{$key},
                NamespaceURI => $namespace,
                };
    }
    
    $element->{Attributes} = \@attribs;
}

sub start_document {
    my ($self, $document) = @_;
    
    $self->{InScopeNamespaceStack} = [ { '_Default' => undef,
				         'xmlns' => $xmlns_ns } ];
    
    undef $self->{FirstElement};
    
    if ($self->{'AsFile'}) {
	require IO::File;
	$self->{'Output'} = new IO::File(">".$self->{'AsFile'});
    }

}

sub end_document {
    my $self = shift;
    
    if ($self->{'AsFile'}) {
	close($self->{'Output'});
	delete $self->{'Output'};
    }
    
    if (defined(wantarray())) {
        return join('', @{$self->{'Strings'}});
    }
}

sub start_element {
    my ($self, $element) = @_;
    
    $self->make_sax2_attribs($element);
    
    if (!exists $element->{NamespaceURI}) {
        $element->{NamespaceURI} = $self->_namespace($element->{Name});
    }
    
    $element->{Parent} = $self->{Current_Element};
    $self->{Current_Element} = $element;
    
    if (!$self->{FirstElement}) {
        $self->{FirstElement}++;
        
        if (lc($element->{Name}) ne 'html') {
            die "First element has to be <html>";
        }
        else {
            $element->{Name} = 'HTML';
        }
        
        if ($self->{DoctypePublic}) {
            $self->print(qq(<!DOCTYPE HTML PUBLIC "$self->{DoctypePublic}"));
            if ($self->{DoctypeSystem}) {
                $self->print(qq( "$self->{DoctypeSystem}"));
            }
            $self->print(">\n");
        }
        elsif ($self->{DoctypeSystem}) {
            $self->print(qq(<!DOCTYPE HTML SYSTEM "$self->{DoctypeSystem}">\n));
        }
        else {
            $self->print(
                qq(<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
                      "http://www.w3.org/TR/html4/strict.dtd">\n)
                );
        }
    }
    
    if (!$element->{NamespaceURI} && $self->is_html_tag($element->{Name})) {
        # HTML special cases...
        $self->print("<$element->{Name}");
        
        foreach my $attr (@{$element->{Attributes}}) {
            my $test = "$element->{Name}/$attr->{Name}";
            if ($self->is_boolean_attrib($test)) {
                $self->print(" $attr->{Name}");
            }
            elsif ($self->is_url_attrib($test)) {
                $self->print(" $attr->{Name}=\"", $self->escape_url($attr->{Value}), "\"");
            }
            else {
                $self->print(" $attr->{Name}=\"", 
                    $self->escape_attrib($attr->{Value}),
                    "\"");
            }
        }
        
        $self->print(">");
        
        if (lc($element->{Name}) eq 'head') {
            # output META tag?
            if ($self->{Encoding}) {
                $self->print(qq(
  <META http-equiv="Content-Type" content="text/html; charset=$self->{Encoding}">));
            }
        }
    }
    else {
        $self->output_as_xml(start => $element);
    }
}

sub end_element {
    my ($self, $element) = @_;
    
    if ($self->{Current_Is_SAX1}) {
        pop @{ $self->{InScopeNamespaceStack} };
        undef $self->{Current_Is_SAX1};
    }

    if (!$element->{NamespaceURI} && $self->is_html_tag($element->{Name})) {
        return if $self->is_empty_tag($element->{Name});
    }
    
    $self->output_as_xml(end => $element);
    
    $self->{Current_Element} = $self->{Current_Element}->{Parent};
}

sub characters {
    my ($self, $chars) = @_;
    
    my $element = $self->{Current_Element};
    
    if (!$element->{NamespaceURI} && $self->is_html_tag($element->{Name})) {
        if (lc($element->{Name}) =~ /^(script|style)$/) {
            $self->print($chars->{Data});
        }
        else {
            $self->print($self->escape_xml($chars->{Data}));
        }
    }
    else {
        $self->print($self->escape_xml($chars->{Data}));
    }
}

sub processing_instruction {
    my ($self, $pi) = @_;
    
    $self->print("<?", $pi->{Target}, " ", $self->{Data}, ">");
}

sub comment {
    my ($self, $comment) = @_;
}

sub _scan_namespaces {
    my ($self, %attributes) = @_;

    while (my ($attr_name, $value) = each %attributes) {
	if ($attr_name =~ /^xmlns(:(.*))?$/) {
            my $prefix = $2 || '_Default';
            $self->{InScopeNamespaceStack}[-1]{$prefix} = $value;
	}
    }
}

sub _namespace {
    my ($self, $name) = @_;

    my ($prefix, $localname) = split(/:/, $name);
    if (!defined($localname)) {
	if ($prefix eq 'xmlns') {
	    return undef;
	} else {
	    return $self->{InScopeNamespaceStack}[-1]{'_Default'};
	}
    } else {
	return $self->{InScopeNamespaceStack}[-1]{$prefix};
    }
}

1;
__END__

=head1 NAME

XML::Handler::HTMLWriter - SAX Handler for writing HTML 4.0

=head1 SYNOPSIS

  use XML::Handler::HTMLWriter;
  my $writer = XML::Handler::HTMLWriter->new(

=head1 DESCRIPTION

This module is based on the rules for outputting HTML according to
http://www.w3.org/TR/xslt - the XSLT specification. It is based on
the concepts in XML::Handler::YAWriter, and the usage is the same as
that module.

=head2 HTML Output Method

Here is the relevant excerpt from TR/xslt [note that a bit of an
understanding of XSLT is necessary to read this, but don't worry -
understanding isn't necessary to use this module :-)]:

The html output method should not output an element differently from
the xml output method unless the expanded-name of the element has a
null namespace URI; an element whose expanded-name has a non-null
namespace URI should be output as XML. If the expanded-name of the
element has a null namespace URI, but the local part of the
expanded-name is not recognized as the name of an HTML element, the
element should output in the same way as a non-empty, inline element
such as span.

The html output method should not output an end-tag for empty
elements. For HTML 4.0, the empty elements are area, base, basefont,
br, col, frame, hr, img, input, isindex, link, meta and param. For
example, an element written as <br/> or <br></br> in the stylesheet
should be output as <br>.

The html output method should recognize the names of HTML elements
regardless of case. For example, elements named br, BR or Br should all
be recognized as the HTML br element and output without an end-tag.

The html output method should not perform escaping for the content of
the script and style elements. For example, a literal result element
written in the stylesheet as

  <script>if (a &lt; b) foo()</script>

or

  <script><![CDATA[if (a < b) foo()]]></script>

should be output as

  <script>if (a < b) foo()</script>

The html output method should not escape < characters occurring in
attribute values.

If the indent attribute has the value yes, then the html output method
may add or remove whitespace as it outputs the result tree, so long as
it does not change how an HTML user agent would render the output. The
default value is yes.

The html output method should escape non-ASCII characters in URI
attribute values using the method recommended in Section B.2.1 of the
HTML 4.0 Recommendation.

The html output method may output a character using a character entity
reference, if one is defined for it in the version of HTML that the
output method is using.

The html output method should terminate processing instructions with >
rather than ?>.

The html output method should output boolean attributes (that is
attributes with only a single allowed value that is equal to the name
of the attribute) in minimized form. For example, a start-tag written
in the stylesheet as

  <OPTION selected="selected">

should be output as

  <OPTION selected>

The html output method should not escape a & character occurring in an
attribute value immediately followed by a { character (see Section
B.7.1 of the HTML 4.0 Recommendation). For example, a start-tag written
in the stylesheet as

  <BODY bgcolor='&amp;{{randomrbg}};'>

should be output as

  <BODY bgcolor='&{randomrbg};'>

The encoding attribute specifies the preferred encoding to be used. If
there is a HEAD element, then the html output method should add a META
element immediately after the start-tag of the HEAD element specifying
the character encoding actually used. For example,

  <HEAD>
  <META http-equiv="Content-Type" content="text/html; charset=EUC-JP">
  ...

It is possible that the result tree will contain a character that
cannot be represented in the encoding that the XSLT processor is using
for output. In this case, if the character occurs in a context where
HTML recognizes character references, then the character should be
output as a character entity reference or decimal numeric character
reference; otherwise (for example, in a script or style element or in a
comment), the XSLT processor should signal an error.

If the doctype-public or doctype-system attributes are specified, then
the html output method should output a document type declaration
immediately before the first element. The name following <!DOCTYPE
should be HTML or html. If the doctype-public attribute is specified,
then the output method should output PUBLIC followed by the specified
public identifier; if the doctype-system attribute is also specified,
it should also output the specified system identifier following the
public identifier. If the doctype-system attribute is specified but the
doctype-public attribute is not specified, then the output method
should output SYSTEM followed by the specified system identifier.

The media-type attribute is applicable for the html output method. The
default value is text/html.

=head1 SAX1 or SAX2?

This module is designed to work with either SAX1 or SAX2. It implements
a transparent layer to allow either SAX1 or SAX2 events to work.

=head1 AUTHOR

Matt Sergeant, matt@sergeant.org

=head1 SEE ALSO

L<XML::Handler::YAWriter>, L<XML::Parser::PerlSAX>.

=cut
