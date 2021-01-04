use strict;
use warnings;
use Test::More 0.98;
use lib '../lib', 'lib';
#
use SDL2;
ok !SDL_Delay(1), 'SDL_Delay(1)';
done_testing;
