use strict;
use warnings;
use lib '../lib';
#
use Carp::Always;
use SDL2::FFI qw[:init :audio SDL_RWFromFile SDL_QuitRequested SDL_Delay];
use SDL2::Mixer qw[:all];
#
$|++;

package blah {
    use Object::Pad;
    class Point {
        use overload
            '""' => sub { my ($s) = @_; $s->values->[ $s->pos ]; },
            '+'  => sub { my ($s) = @_; $s->set_pos( $s->pos + 1 ) };
        has $x      : param = 0;
        has $y      : param = 0;
        has $values : writer : reader;
        has $pos    : writer : reader = 0;
        method move( $dX, $dY ) {
            $x += $dX;
            $y += $dY;
        }
        method describe() {
            print "A point at ($x, $y)\n";
        }
    }
};
my $ptr = Point->new( x => 5, y => 10 );
$ptr->describe;
$ptr->set_values(  [ reverse 1 .. 10 ] );
use Data::Dump;
ddx $ptr;
$ptr++;
print $ptr;
#__END__

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
{
    XXMix_SetPostMix(
        sub {
            my ( $udata, $stream, $len ) = @_;
			warn 'here';
			use Data::Dump;
			#warn $len;
			#ddx $udata;
			#warn $udata;
			#warn $$stream;
			#$$stream = 255;
#ddx $stream;
$$stream = [ 0 x $len ];
ddx $stream;
			#warn $$stream . '|' ;
            #print '=' x ( ($$stream) / 10 );
            #print "|\n";
        },
        {time => time}
    );
}
Mix_PlayMusic( $music, 10 );
SDL_Delay(250) while Mix_PlayingMusic();
Mix_FreeMusic($music);
SDL_Quit();
