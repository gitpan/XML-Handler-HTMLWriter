use Test;
use XML::Handler::HTMLWriter;
eval {
    require XML::Parser::PerlSAX;
    plan tests => 6;
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

my $output = $parser->parse(Source => { SystemId => "testfiles/namespace.xml" });

ok($output);

ok($output, qr/<ns:foo xmlns:ns="http:\/\/www.example.com\/foo">/);
ok($output, qr/<default xmlns="http:\/\/www.example.com\/default"/);

