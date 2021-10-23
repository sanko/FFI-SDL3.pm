use strict;
use warnings;
use lib '../lib';
#
#use Carp::Always;
use SDL2::FFI qw[:init :audio SDL_RWFromFile SDL_QuitRequested SDL_Delay];
use SDL2::Mixer qw[:all];
#
$|++;

	my @delay;
{
my $PI = 3.1415926;

# Amplitude for signal, roughly 50% of max (32768) or -6db
my $amplitude = 16384;
my $freq = 440000; # Frequency in Hertz ('A4' note)
my $sample_rate = 44100;

# define time increment for calculating the wave
my $increment = 1 / $sample_rate;
my $t = 0;

#while (1) { # do this perpetually
for (0..2560) {
    $t += $increment; # Time in seconds

    my $signal = $amplitude * sin($freq * 2 * $PI * $t);
	#warn $signal;
	push @delay, $signal;
     #pack("v", $signal);
}
	}
#
my $result = 0;
my $flags  = MIX_INIT_MP3;
if ( SDL_Init(SDL_INIT_AUDIO) < 0 ) {
    printf("Failed to init SDL\n");
    exit(1);
}
if ( $flags != ( $result = Mix_Init($flags) ) ) {
    printf( "Could not initialize mixer (result: %d).\n", $result );
    printf( "Mix_Init: %s\n",                             Mix_GetError() );
    exit(1);
}
Mix_OpenAudio( 22050, AUDIO_S16SYS, 2, 640 );
my $music = Mix_LoadMUS('sound25.mp3');

use FFI::C::ArrayDef;
{
    Mix_SetPostMix(
        sub {
            my ( $udata, $stream, $len ) = @_;
			warn 'here!';
			#$$stream = [reverse @$$stream];
			#$$stream =
			return [ map  { int rand 255 } 0.. $len ];
			return $stream;
        },
        {time => time}
    );
}
Mix_PlayMusic( $music, 3 );
SDL_Delay(250) while Mix_PlayingMusic();
Mix_FreeMusic($music);
SDL_Quit();
