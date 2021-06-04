use strict;
use warnings;
use Test2::V0;
use lib '../lib', 'lib';
use SDL2::FFI qw[:all];
#
my $ver = SDL_GetVersion();
is $ver->major, 2, sprintf 'SDL v%d.%d.%d', $ver->major, $ver->minor, $ver->patch;
#
done_testing;
