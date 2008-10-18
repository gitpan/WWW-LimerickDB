#!/usr/bin/env perl

use Test::More tests => 10;

BEGIN {
    use_ok('LWP::UserAgent');
    use_ok('HTML::TokeParser::Simple');
    use_ok('HTML::Entities');
    use_ok('overload');
    use_ok('Class::Data::Accessor');
	use_ok( 'WWW::LimerickDB' );
}

diag( "Testing WWW::LimerickDB $WWW::LimerickDB::VERSION, Perl $], $^X" );

can_ok( 'WWW::LimerickDB', qw/
        new
        get_limerick
        get_top
        get_bottom
        get_latest
        get_random
        get_high_random
        error
        limerick
        limericks
        ua
        new_line
        get_cached
        _get
        _parse_quotes
        _set_error
    /
);

my $lime = WWW::LimerickDB->new;

isa_ok($lime, 'WWW::LimerickDB');
isa_ok($lime->ua, 'LWP::UserAgent');

my $quote = $lime->get_limerick(288);

SKIP: {
    unless ( defined $quote ) {
        diag "Fetching error: " . $lime->error;
        ok( length($lime->error), "We got error from error method" );
        skip "Network error", 0;
    }

    my $VAR1 = "There once was a priest from Morocco \nWho's motto was really quite macho \nHe said \"To be blunt \nGod decreed we eat cunt. \nWhy else would it look like a taco?\"";

    is( $lime->limerick, $VAR1, "fetched matches expected" );
}




