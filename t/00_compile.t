use strict;
use warnings;
use Test::More 0.98;
use lib '../lib', 'lib';
#
use_ok $_ for qw[SDL2];
my $ver = SDL2::version->new;
#
SDL_GetVersion($ver);
diag sprintf 'SDL v%d.%d.%d', $ver->major, $ver->minor, $ver->patch;
#
done_testing;
