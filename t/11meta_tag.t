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

my $output = $parser->parse(Source => { SystemId => "testfiles/meta_tag.xml" });

ok($output);

# warn("OUTPUT: $output\n");

ok($output, qr((?i)<head><meta http-equiv));

$writer = XML::Handler::HTMLWriter->new(Encoding => "ISO-8859-1");
$parser = XML::Parser::PerlSAX->new(Handler => $writer);

$output = $parser->parse(Source => { SystemId => "testfiles/meta_tag.xml" });
skip($writer->{Iconv}, $output, qr/(?i)ISO-8859-1/);

# warn("OUTPUT: Latin-1: $output\n");

