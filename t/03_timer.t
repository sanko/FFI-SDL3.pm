use strict;
use warnings;
use Test2::V0;
use Test2::Tools::ClassicCompare qw[is_deeply];
use lib -d '../t' ? './lib' : 't/lib';
use lib '../lib', 'lib';
use SDL2::FFI qw[:all];
use experimental 'signatures';
$|++;
#
needs_display();

END {
    SDL_Quit();
}
bail_out 'Error initializing SDL: ' . SDL_GetError()
    unless SDL_Init( SDL_INIT_VIDEO | SDL_INIT_TIMER ) == 0;
my $done = 0;
my $id_1 = SDL_AddTimer(
    2000,
    sub ( $delay, $args ) {
        pass 'timer triggered without args';
        ok !defined $args, 'lack of timer args is correct';
        $done++;
        0;
    }
);
ok $id_1, 'SDL_AddTimer( ... ) without args returned id == ' . $id_1;
my $id_2 = SDL_AddTimer(
    2000,
    sub ( $delay, $args ) {
        use Data::Dump;
        pass('timer triggered with args');
        is $args, 'Yes!', 'timer args are correct';
        $done++;
        0;
    },
    'Yes!'
);
ok $id_2, 'SDL_AddTimer( ... ) with args returned id == ' . $id_2;
my $id_3 = SDL_AddTimer(
    2000,
    sub ( $delay, $args ) {
        use Data::Dump;
        pass('timer triggered with list of args');
        is_deeply( $args, [ 'a', 'list' ], 'list of args are correct ([ \'a\', \'list\' ])' );
        $done++;
        0;
    },
    [qw[a list]]
);
ok $id_3, 'SDL_AddTimer( ... ) with list of args returned id == ' . $id_3;
my $id_4 = SDL_AddTimer(
    2000,
    sub ( $delay, $args ) {
        pass('timer triggered with list of args');
        is_deeply(
            $args,
            { a => 'list', time => 5 },
            'list of args are correct ({ a => \'list\', time => 5 })'
        );
        $done++;
        0;
    },
    { a => 'list', time => 5 }
);
ok $id_4, 'SDL_AddTimer( ... ) with hash args returned id == ' . $id_4;
while (1) {
    SDL_Delay(1);
    last if $done == 4;
}
SDL_RemoveTimer($_) for $id_1, $id_2, $id_3, $id_4;
#
done_testing;

sub needs_display {    # Taken from Test::NeedsDisplay but without Test::More

    # Get rid of Win32 and existing DISPLAY cases
    return 1 if $^O eq 'MSWin32';
    return 1 if $ENV{DISPLAY};

    # The quick way is to use the xvfb-run script
    diag 'No DISPLAY. Looking for xvfb-run...';
    my @PATHS = split $Config::Config{path_sep}, $ENV{PATH};
    foreach my $path (@PATHS) {
        my $xvfb_run = File::Spec->catfile( $path, 'xvfb-run' );
        next unless -e $xvfb_run;
        next unless -x $xvfb_run;
        diag 'Restarting with xvfb-run...';
        exec( $xvfb_run, $^X,
            ( $INC{'blib.pm'} ? '-Mblib' : () ),
            ( $INC{'perl5db.pl'} ? '-d' : () ), $0,
        );
    }

    # If provided with the :skip_all, abort the run
    if ( $_[1] and $_[1] eq ':skip_all' ) {
        plan( skip_all => 'Test needs a DISPLAY' );
        exit(0);
    }
    diag 'Failed to find xvfb-run.';
    diag 'Running anyway, but will probably fail...';
}
