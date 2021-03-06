package main;

require 5.6.1;
use strict;
use warnings;
use ExtUtils::MakeMaker qw( WriteMakefile );
use File::Spec;
use Getopt::Long;

my $live = 1;
my $local = 1;
GetOptions(
    'live!'         => \$live,
    'local!'        => \$local,
    'all'           => sub { print "All tests are on by default.  This option is deprecated.\n" },
    'mech-dump!'    => sub { print "mech-dump is always installed now.  This option is deprecated.\n" },
);

my @tests = glob File::Spec->catfile( 't', '*.t' );
push( @tests, glob File::Spec->catfile( 't', 'local', '*.t' ) ) if $local;
push( @tests, glob File::Spec->catfile( 't', 'live', '*.t' ) ) if $live;
push( @tests, glob File::Spec->catfile( 't', 'mech-dump', '*.t' ) );

my $parms = {
    NAME            => 'WWW::Mechanize',
    VERSION_FROM    => 'lib/WWW/Mechanize.pm', # finds $VERSION
    ABSTRACT_FROM   => 'lib/WWW/Mechanize.pm', # retrieve abstract from module
    AUTHOR          => 'Andy Lester <andy@petdance.com>',
    EXE_FILES       => [ 'bin/mech-dump' ],
    PREREQ_PM       => {
        'Carp'              => 0,
        'File::Temp'        => 0,
        'FindBin'           => 0,
        'Getopt::Long'      => 0,
        'HTML::Form'        => 1.038,
        'HTML::HeadParser'  => 0,
        'HTML::Parser'      => 3.33,
        'HTML::TokeParser'  => 2.28,
        'HTTP::Daemon'      => 0,
        'HTTP::Request'     => 1.30,
        'HTTP::Status'      => 0,
        'LWP'               => 5.802,
        'LWP::UserAgent'    => 2.024,
        'Pod::Usage'        => 0,
        'Test::More'        => 0.34,
        'URI'               => 1.25,
        'URI::URL'          => 0,
        'URI::file'         => 0,
    },
    test            => { TESTS => join( ' ', @tests ) },
    clean           => { FILES => 'WWW-Mechanize-*' },
};

eval { require LWP; };
if (!$@) {
    if ( ! LWP::Protocol::implementor('https') ) {
        print <<EOT;

It looks like you don't have SSL capability (like IO::Socket::SSL) installed. 
You will not be able to process https:// URLs correctly.

EOT
    }
}

my @missing;
my @nice = qw( Test::Pod Test::Memory::Cycle Test::Warn Test::Taint );
for my $nice ( @nice ) {
    eval "require $nice";
    push( @missing, $nice ) if $@;
}

if ( @missing ) {
    @missing = map { "\t$_\n" } @missing;
    print <<EOT;

WWW::Mechanize likes to have a lot of test modules for some of its tests.
The following are modules that would be nice to have, but not required.

@missing

EOT
}

WriteMakefile( %$parms );

sub MY::postamble {
    return <<'MAKE_FRAG';
.PHONY: tags critic

tags:
	ctags -f tags --recurse --totals \
		--exclude=blib \
		--exclude=.svn \
		--exclude='*~' \
		--languages=Perl --langmap=Perl:+.t \

critic:
	perlcritic -1 -q -profile perlcriticrc bin/ lib/ t/

MAKE_FRAG
}

1;
