use strict;
use warnings;
use Test2::V0;
use SDL3 qw[:all];
#
ok !SDL_Delay(1), 'SDL_Delay(1)';
#
done_testing;
