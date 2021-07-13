use strictures 2;
use lib '../lib', 'lib';
use experimental 'signatures';
use constant { WND_W => 1280, WND_H => 720 };
use SDL2::FFI qw[:all];
$|++;

package Pong::Ball {
    use Moo;
    use strictures 2;
    use experimental 'signatures';
    use Types::Standard qw[Int Num];
    use SDL2::FFI qw[SDL_SetRenderDrawColor SDL_RenderFillRect];
    has [qw[vx vy speed]] => ( is => 'rw', isa => Num, default => 0, lazy => 1, trigger => \&move );
    has [qw[x y w h]] => ( is => 'rw', isa => Num, default => 20, lazy => 1 );

    sub move ( $s, $new ) {
        $s->x( $s->x + ( $s->vx * $s->speed ) );
        $s->y( $s->y + ( $s->vy * $s->speed ) );
    }

    sub draw ( $s, $renderer ) {
        SDL_SetRenderDrawColor( $renderer, 255, 255, 255, 255 );
        SDL_RenderFillRect( $renderer,
            SDL2::Rect->new( { x => $s->x - $s->w / 2, y => $s->y, w => $s->w, h => $s->h } ) );
    }
};

package Pong::Player {
    use Moo;
    use strictures 2;
    use experimental 'signatures';
    use Types::Standard qw[Int Num InstanceOf];
    use SDL2::FFI qw[SDL_SetRenderDrawColor SDL_RenderFillRect];
    has [qw[score speed x y w h]] => ( is => 'rw', isa => Num, default => 0 );

    sub draw ( $s, $renderer ) {
        SDL_SetRenderDrawColor( $renderer, 200, 200, 200, 255 );
        SDL_RenderFillRect( $renderer,
            SDL2::Rect->new( { x => $s->x, y => $s->y, w => $s->w, h => $s->h } ) );
    }
};
END { SDL_Quit() }
#
die 'Failed to Initialise SDL: ' . SDL_GetError() if SDL_Init(SDL_INIT_EVERYTHING) == -1;
my $win = SDL_CreateWindow( 'Pong?', SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, WND_W, WND_H,
    SDL_WINDOW_SHOWN );
$win // die 'Failed to create SDL Window: ' . SDL_GetError();
my $ren = SDL_CreateRenderer( $win, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC );
$ren // die 'Failed to create SDL Renderer: ' . SDL_GetError();
#
my $l     = Pong::Player->new( x => 100,         y => ( WND_H / 2 ) - 75, w => 20, h => 150 );
my $r     = Pong::Player->new( x => WND_W - 120, y => ( WND_H / 2 ) - 75, w => 20, h => 150 );
my $ball  = Pong::Ball->new( x => 100, y => 40, vx => 1, vy => 1, speed => 5 );
my @angle = ( -1, -.75, -.5, -.25, 0, 0, .25, .5, .75, 1 );
#
while (1) {
    while ( SDL_PollEvent( my $e = SDL2::Event->new ) ) {
        exit if $e->type == SDL_QUIT;
        if ( $e->type eq SDL_KEYDOWN ) {
            exit                                 if $e->key->keysym->sym == SDLK_ESCAPE;
            $l->y( $l->y() - int( WND_H / 20 ) ) if $e->key->keysym->sym == SDLK_UP && $l->y > 0;
            $l->y( $l->y() + int( WND_H / 20 ) )
                if $e->key->keysym->sym == SDLK_DOWN && $l->y < WND_H - $l->h;
        }
        elsif ( $e->type == SDL_MOUSEWHEEL ) {
            $r->y( $r->y() - int( WND_H / 20 ) ) if $e->wheel->y > 0 && $r->y > 0;
            $r->y( $r->y() + int( WND_H / 20 ) ) if $e->wheel->y < 0 && $r->y < ( WND_H - $r->h );
        }
    }
    $r->score( $r->score + 1 ) if $ball->x <= 0;
    $l->score( $l->score + 1 ) if $ball->x >= ( WND_W - $r->w );
    if ( ( $ball->x + $ball->w ) >= $r->x &&
        $ball->vx == 1 &&
        ( $ball->y >= $r->y && $ball->y <= ( $r->y + $r->h ) ) ) {
        $ball->vy( $angle[ ( ( $ball->y - $r->y ) / ( $r->h / +@angle ) ) ] // $ball->vy );
        $ball->vx(-1);
    }
    elsif ( $ball->x <= ( $l->x + $l->w ) &&
        $ball->vx == -1 &&
        ( $ball->y >= $l->y && $ball->y <= ( $l->y + $l->h ) ) ) {
        $ball->vy( $angle[ ( ( $ball->y - $l->y ) / ( $l->h / +@angle ) ) ] // $ball->vy );
        $ball->vx(1);
    }
    else {
        $ball->vx( $ball->x >= WND_W - $ball->w ? -1 : $ball->x <= 0 ? 1 : $ball->vx );
        $ball->vy( $ball->y >= WND_H - $ball->h ? -1 : $ball->y <= 0 ? 1 : $ball->vy );
    }
    SDL_SetRenderDrawColor( $ren, 33, 34, 35, 255 );
    SDL_RenderClear($ren);
    SDL_SetRenderDrawColor( $ren, 255, 255, 255, 255 );
    $_ % 5 && SDL_RenderDrawPoint( $ren, WND_W / 2, $_ ) for 0 .. WND_H;
    $_->draw($ren) for $l, $r, $ball;
    SDL_RenderPresent($ren);
}

# TODO:
# - display score
# - hold ball after score
