use Test;
use XML::Handler::HTMLWriter;
eval {
    require XML::Parser::PerlSAX;
    plan tests => 5;
    ok(1);
};
if ($@) {
    plan tests => 0;
    exit();
}

my $writer = XML::Handler::HTMLWriter->new();
ok($writer);
my $parser = XML::Parser::PerlSAX->new(Handler => $writer);
ok($parser);

my $output = $parser->parse(Source => { SystemId => "testfiles/url_attribs.xml" });

ok($output);

# warn("OUTPUT: $output\n");

ok($output, qr(<img src="foo%20bar.jpg%3Ffoo%3D1&amp;bar%3D2">));

