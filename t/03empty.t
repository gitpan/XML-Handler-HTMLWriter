use Test;
use XML::Handler::HTMLWriter;
eval {
    require XML::Parser::PerlSAX;
    plan tests => 17;
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

my $output = $parser->parse(Source => { SystemId => "testfiles/empty_tags.xml" });

ok($output);

# warn("OUTPUT: $output\n");

ok($output, qr/<area>(?!<\/area>)/);
ok($output, qr(<base href="foo">(?!</base>)));
ok($output, qr(<basefont>(?!</basefont>)));
ok($output, qr(<br class="short">(?!</br>)));
ok($output, qr(<col>(?!</col>)));
ok($output, qr(<frame src="here">(?!</frame>)));
ok($output, qr(<hr class="long">(?!</hr>)));
ok($output, qr(<img src="there">(?!</img>)));
ok($output, qr(<input type="text">(?!</input>)));
ok($output, qr(<isindex>(?!</isindex>)));
ok($output, qr(<link type="text/css">(?!</link>)));
ok($output, qr(<param>(?!</param>)));
ok($output, qr/<meta .*?>(?!<\/meta>)/);

