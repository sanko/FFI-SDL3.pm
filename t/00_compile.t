use strict;
use warnings;
use Test2::V0;
use lib '../lib', 'lib';
use SDL2;
#
my $ver = SDL2::version->new;
#
SDL_GetVersion($ver);
diag sprintf 'SDL v%d.%d.%d', $ver->major, $ver->minor, $ver->patch;
#
done_testing;
