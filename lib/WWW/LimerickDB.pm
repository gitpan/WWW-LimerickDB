package WWW::LimerickDB;

use warnings;
use strict;

our $VERSION = '0.0101';

use LWP::UserAgent;
use HTML::TokeParser::Simple;
use HTML::Entities;
use overload q|""| => sub { shift->limerick };

use base 'Class::Data::Accessor';
__PACKAGE__->mk_classaccessors qw/
    error
    ua
    limericks
    limerick
/;

sub new {
    my ( $class, %args ) = @_;

    $args{ +lc } = delete $args{ $_ }
        for keys %args;

    $args{ua} ||= LWP::UserAgent->new(
        agent   => 'Mozilla',
        timeout => 30,
    );

    my $self = bless {}, $class;

    $self->$_( $args{ $_ } )
        for keys %args;

    return $self;
}

sub get_top    { shift->_get('top150'); }
sub get_bottom { shift->_get('bottom'); }
sub get_latest { shift->_get('latest'); }
sub get_random { shift->_get('random'); }
sub get_high_random { shift->_get('random2'); }

sub get_limerick {
    my ( $self, $num ) = @_;
    return $self->_get($num);
}

sub _get {
    my ( $self, $what ) = @_;

    $self->$_( undef )
        for qw/limericks limerick error/;

    my $response = $self->ua->get("http://limerickdb.com/?$what");

    $response->is_success
        or return $self->_set_error( $response );

    $self->_parse_quotes( $response->decoded_content );
}

sub _parse_quotes {
    my ( $self, $html ) = @_;

    my $p = HTML::TokeParser::Simple->new( \ $html );
    my @quotes;
    my $cur_quote = '';
    my $get_quote_text = 0;
    while ( my $t = $p->get_token ) {
        if ( $t->is_start_tag('div')
            and defined $t->get_attr('class')
            and $t->get_attr('class') eq 'quote_output'
        ) {
            $get_quote_text = 1;
        }
        elsif ( $get_quote_text and $t->is_text ) {
            $cur_quote .= $t->as_is;
        }
        elsif ( $get_quote_text and $t->is_start_tag('br') ) {
            #$cur_quote .= "\n";
        }
        elsif ( $get_quote_text and $t->is_end_tag('div') ) {
            decode_entities $cur_quote;
            $cur_quote =~ s/\240/ /g;
            $cur_quote =~ s/[^\S\n]+/ /g;
            $cur_quote =~ s/^\s+//;
            $cur_quote =~ s/\s+$//;
            push @quotes, $cur_quote;
            $cur_quote = '';
        }
    }

    $self->limerick( $quotes[0] );
    return $self->limericks( [ @quotes ] );
}


sub _set_error {
    my ( $self, $response ) = @_;
    $self->error( "Network error: " . $response->status_line );
    return;
}

1;
__END__

=head1 NAME

WWW::LimerickDB - interface to fetch limericks from http://limerickdb.com/

=head1 SYNOPSIS

    use strict;
    use warnings;
    use WWW::LimerickDB;

    my $lime = WWW::LimerickDB->new;

    $lime->get_limerick(228)
        or die $lime->error;

    print "$lime\n";

=head1 DESCRIPTION

The module provides interface to fetch limericks ("quotes" if you prefer) from
L<http://limerickdb.com/>

=head1 CONSTRUCTOR

=head2 C<new>

    my $lime = WWW::LimerickDB->new;

    my $lime = WWW::LimerickDB->new(
        ua => LWP::UserAgent->new( agent => 'Fox', timeout => 50 ),
    );

Constructs and returns a freshly cooked C<WWW::LimerickDB> object. Takes one optional argument
in a key/value fashion.

=head3 C<ua>

    my $lime = WWW::LimerickDB->new(
        ua => LWP::UserAgent->new( agent => 'Fox', timeout => 50 ),
    );

B<Optional>. Takes an L<LWP::UserAgent>-like object as a value, in other words an object with
a C<get()> method that returns L<HTTP::Response> object. By default, the following will be
used: C<< LWP::UserAgent->new( agent => 'Mozilla', timeout => 30 ) >>

=head1 FETCHING METHODS

All of fetching methods return either C<undef> or an empty list on failure and
the reason for failure will be available via C<error> method (see below).

=head2 C<get_limerick>

    my $limerick = $lime->get_limerick(288)
        or die $lime->error;

Takes one mandatory argument which is the number of the limerick you wish to retrieve.
On success returns a string containing your quote.

=head2 C<get_top>

    my $top_limericks_ref = $lime->get_top
        or die $lime->error;

Takes no arguments. On success returns an arrayref of "Top" rated limericks.

=head2 C<get_bottom>

    my $lime_limericks_ref = $lime->get_bottom
        or die $lime->error;

Takes no arguments. On success returns an arrayref of "Bottom" rated limericks.

=head2 C<get_latest>

    my $latest_limericks_ref = $lime->get_latest
        or die $lime->error;

Takes no arguments. On success returns an arrayref of "Latest" limericks.

=head2 C<get_random>

    my $random_limericks_ref = $lime->get_random
        or die $lime->error;

Takes no arguments. On success returns an arrayref of "Random" limericks.

=head2 C<get_high_random>

    my $random_high_limericks_ref = $lime->get_high_random
        or die $lime->error;

Takes no arguments. On success returns an arrayref of "Random > 0" (i.e. random with
no negative ratings) limericks.

=head1 OTHER METHODS

=head2 C<error>

    my $limerick = $lime->get_limerick(288)
        or die $lime->error;

If either of the "FETCHING METHODS" described above fail they return either C<undef>
or an empty list, depending on the context, and the reason for failure will be available
via C<error> method. Takes no arguments, return a human parsable string explaining why
a fetching method failed.

=head2 C<limerick>

    my $limerick = $lime->limerick;

    # OR

    my $limerick = "$lime";

Note the B<singular> form. Takes no arguments.
Must be called after a successful call to one of the "FETCHING
METHODS". If the "fetching method" is a C<get_limerick()> returns the same limerick that
call returned; otherwise, returns the first quote out of quotes retrieved. B<This method
is overloaded> on C<q|""|>, in other words, you can interpolate the object in a string to
obtain the value of the call to C<limerick()>.

=head2 C<limericks>

    my $limericks_ref = $lime->limericks;

Note the B<plural> form. Takes no arguments.
Must be called after a successful call to one of the "FETCHING
METHODS". Returns the same arrayref as all but C<get_limerick()> fetching methods return. In
case of method being C<get_lamerick()> returns an arrayref with just one quote that was
fetched.

=head2 C<ua>

    my $ua = $lime->ua;
    $ua->proxy('http', 'http://foo.com');
    $lime->ua( $ua );

Returns the object currently used for fetching quotes. When called with one optional
argument sets a new object that is the argument. See C<ua> argument to the constructor
for more details.

=head1 AUTHOR

'Zoffix, C<< <'zoffix at cpan.org'> >>
(L<http://zoffix.com/>, L<http://haslayout.net/>, L<http://zofdesign.com/>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-limerickdb at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-LimerickDB>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::LimerickDB

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-LimerickDB>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-LimerickDB>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-LimerickDB>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-LimerickDB>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 'Zoffix, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

