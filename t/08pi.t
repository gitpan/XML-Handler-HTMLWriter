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

my $output = $parser->parse(Source => { SystemId => "testfiles/pi.xml" });

ok($output);

# warn("OUTPUT: $output\n");

ok($output, qr(<\?php foo > 3\?>));

