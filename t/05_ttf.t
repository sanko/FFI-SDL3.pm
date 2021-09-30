use strict;
use warnings;
use Test2::V0;
use lib -d '../t' ? './lib' : 't/lib';
use lib '../lib', 'lib';
use SDL2::FFI qw[:ttf SDL_RWFromFile];
$|++;
#
my $hello_world_ttf = ( -d '../t' ? './' : './t/' ) . '/etc/hello-world.ttf';
#
my $compile_version = SDL2::Version->new();
my $link_version    = TTF_Linked_Version();
SDL_TTF_VERSION($compile_version);
diag sprintf 'compiled with SDL_ttf version: %d.%d.%d', $compile_version->major,
    $compile_version->minor, $compile_version->patch;
diag sprintf 'running with SDL_ttf version: %d.%d.%d', $link_version->major, $link_version->minor,
    $link_version->patch;
#
is TTF_WasInit(), 0, 'TTF_WasInit( ) returns 0 before TTF_Init( )';
is TTF_Init(),    0, 'TTF_Init( ) returned 0';
is TTF_WasInit(), 1, 'TTF_WasInit( ) returns 1 after TTF_Init( )';
TTF_Quit();
is TTF_WasInit(), 0, 'TTF_WasInit( ) returns 0 after TTF_Quit( )';
#
TTF_SetError( 'myfunc is not implemented! %d was passed in.', 6 );
is TTF_GetError(), 'myfunc is not implemented! 6 was passed in.',
    'TTF_SetError( ... ) and TTF_GetError( ... ) work';
#
# load font.ttf at size 16 into font
ok !TTF_OpenFont( 'fake.ttf', 16 ),
    'TTF_OpenFont( ... ) with a fake font does not work before TTF_Init( )';
diag 'TTF_GetError is: ' . TTF_GetError();
ok !TTF_OpenFont( ( -d '../t' ? './' : './t/' ) . '/etc/hello-world.ttf', 16 ),
    'TTF_OpenFont( ... ) with a real font does not work before TTF_Init( )';
diag 'TTF_GetError is: ' . TTF_GetError();
diag 'Calling TTF_Init( ) again';
TTF_Init();
ok !TTF_OpenFont( 'fake.ttf', 16 ), 'TTF_OpenFont( ... ) with a fake font still does not work';
diag 'TTF_GetError is: ' . TTF_GetError();
ok my $font = TTF_OpenFont( $hello_world_ttf, 16 ),
    'TTF_OpenFont( ... ) with a real font works now';
ok $font->isa('SDL2::TTF::Font'), 'font returned is an SDL2::TTF::Font object';
ok $font = TTF_OpenFontRW( SDL_RWFromFile( $hello_world_ttf, 'rb' ), 1, 16 ),
    'TTF_OpenFontRW( ... ) with a real font works';
ok $font->isa('SDL2::TTF::Font'), 'font returned is an SDL2::TTF::Font object';
ok $font = TTF_OpenFontIndex( $hello_world_ttf, 16, 0 ),
    'TTF_OpenFontIndex( ... ) with a real font works now';
ok $font->isa('SDL2::TTF::Font'), 'font returned is an SDL2::TTF::Font object';
ok $font = TTF_OpenFontIndexRW( SDL_RWFromFile( $hello_world_ttf, 'rb' ), 1, 16 ),
    'TTF_OpenFontIndexRW( ... ) with a real font works';
ok $font->isa('SDL2::TTF::Font'), 'font returned is an SDL2::TTF::Font object';

# Returns void... Just making sure it doesn't die
TTF_CloseFont($font);
#
done_testing;
__END__

#
needs_display();

END {
    diag(__LINE__);
    SDL_Quit();
    diag(__LINE__);
}
bail_out 'Error initializing SDL: ' . SDL_GetError()
    unless SDL_Init( SDL_INIT_VIDEO | SDL_INIT_TIMER ) == 0;
my $done;
share($done) if $threads;
#
diag(__LINE__);
my $id = SDL_AddTimer( 2000, sub { pass('Timer triggered'); $done++; 0; } );
diag(__LINE__);
ok $id, 'SDL_AddTimer( ... ) returned id == ' . $id;
diag(__LINE__);
for ( 1 .. 5 ) {
    diag( __LINE__ . '|' . $_ );
    SDL_PollEvent( my $event = SDL2::Event->new() );
    last if $done;
    sleep 1;
}
diag(__LINE__);
SDL_RemoveTimer($id);
diag(__LINE__);
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
