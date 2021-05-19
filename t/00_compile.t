use strict;
use warnings;
use Test2::V0;
use lib '../lib', 'lib';
use SDL2;
#
my $ver = SDL2::version->new;
#
is $ver->major, 0, 'Empty version object';
SDL_GetVersion($ver);
is $ver->major, 2, sprintf 'SDL v%d.%d.%d', $ver->major, $ver->minor, $ver->patch;
#
done_testing;
