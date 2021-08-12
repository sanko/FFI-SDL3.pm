use strict;
use warnings;
use Test2::V0;
use lib -d '../t' ? './lib' : 't/lib';
use SDL2::FFI qw[:all];
use Test::NeedsDisplay;
#
plan tests => 2;
END { SDL_Quit() }
bail_out 'Error initializing SDL: ' . SDL_GetError()
    unless SDL_Init( SDL_INIT_VIDEO | SDL_INIT_TIMER ) == 0;
my $done;
my $id = SDL_AddTimer( 2000, sub { pass('Timer triggered'); $done++; 0; } );
ok $id, 'SDL_AddTimer( ... ) returned id == ' . $id;
for ( 1 .. 5 ) { SDL_Yield(); last if $done; sleep 1; }
#
done_testing;
