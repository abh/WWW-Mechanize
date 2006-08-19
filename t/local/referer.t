#!/usr/bin/perl -w

use warnings;
use strict;
use FindBin;

BEGIN { delete @ENV{ qw( http_proxy HTTP_PROXY ) }; }

use Test::More tests => 13;

BEGIN {
    use_ok( 'WWW::Mechanize' );
}

our $server;
my $agent = WWW::Mechanize->new();
isa_ok( $agent, 'WWW::Mechanize' );

SKIP: {
    eval { require HTTP::Daemon; };
    skip 'HTTP::Daemon required to test the referrer header',10 if $@;

    # We want to be safe from non-resolving local host names
    delete $ENV{HTTP_PROXY};

    # Now start a fake webserver, fork, and connect to ourselves
    my $command = qq'"$^X" "$FindBin::Bin/referer-server"';
    if ($^O eq 'VMS') {
        $command = qq'mcr $^X t/referer-server';
    }

    open $server, "$command |" or die "Couldn't spawn fake server: $!";
    sleep 1; # give the child some time
    my $url = <$server>;
    chomp $url;

    $agent->get( $url );
    is($agent->status, 200, 'Got first page') or diag $agent->res->message;
    is($agent->content, "Referer: ''", "First page gets sent with empty referrer");

    $agent->get( $url );
    is($agent->status, 200, 'Got second page') or diag $agent->res->message;
    is($agent->content, "Referer: '$url'", "Referer got sent for absolute url");

    $agent->get( '.' );
    is($agent->status, 200, 'Got third page') or diag $agent->res->message;
    is($agent->content, "Referer: '$url'", "Referer got sent for relative url");

    $agent->add_header( Referer => 'x' );
    $agent->get( $url );
    is($agent->status, 200, 'Got fourth page') or diag $agent->res->message;
    is($agent->content, "Referer: 'x'", "Referer can be set to empty again");

    my $ref = 'This is not the referer you are looking for *jedi gesture*';
    $agent->add_header( Referer => $ref );
    $agent->get( $url );
    is($agent->status, 200, 'Got fourth page') or diag $agent->res->message;
    is($agent->content, "Referer: '$ref'", "Custom referer can be set");
};

SKIP: {
    eval 'use Test::Memory::Cycle';
    skip 'Test::Memory::Cycle not installed', 1 if $@;

    memory_cycle_ok( $agent, 'No memory cycles found' );
}

END {
    close $server if $server;
};
