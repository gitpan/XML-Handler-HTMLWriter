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

my $output = $parser->parse(Source => { SystemId => "testfiles/script_and_style.xml" });

ok($output);

# warn("OUTPUT: $output\n");

ok($output, qr((?s)<script>.*here < 4.*</script>));
ok($output, qr((?s)<style>.*&(?!amp;).*</style>));

