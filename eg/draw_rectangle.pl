use strictures 2;
use lib '../lib';
use SDL2;

# https://gigi.nullneuron.net/gigilabs/drawing-lines-with-sdl2/
my $quit  = 0;
my $event = SDL2::Event->new;
SDL_Init(SDL_INIT_VIDEO);
my $window = SDL_CreateWindow( "My SDL Empty Window",
    SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 640, 480, 0 );
my $renderer = SDL_CreateRenderer( $window, -1, 0 );
my ( $y1, $y2, $x1, $x2 );
my $drawing = 0;
my @rects;

while ( !$quit ) {
    SDL_WaitEventTimeout( $event, 10 );
    if ( $event->type == SDL_QUIT ) {
        $quit = 1;
    }
    elsif ( $event->type == SDL_MOUSEBUTTONDOWN ) {
        if ( $event->button->button == SDL_BUTTON_LEFT ) {
            $x1      = $event->motion->x;
            $y1      = $event->motion->y;
            $x2      = $event->motion->x;
            $y2      = $event->motion->y;
            $drawing = 1;
        }
    }
    elsif ( $event->type == SDL_MOUSEBUTTONUP && $drawing ) {
        if ( $event->button->button == SDL_BUTTON_LEFT ) {
            push @rects, { x => $x1, y => $y1, w => $x2 - $x1, h => $y2 - $y1 };
            $drawing = 0;
        }
    }
    elsif ( $event->type == SDL_MOUSEMOTION ) {
        if ($drawing) {
            $x2 = $event->motion->x;
            $y2 = $event->motion->y;
        }
    }
    SDL_SetRenderDrawColor( $renderer, 242, 242, 242, 255 );
    SDL_RenderClear($renderer);
    if ($drawing) {
        SDL_SetRenderDrawColor( $renderer, 0, 0, 0, 255 );
        SDL_RenderDrawRect( $renderer,
            SDL2::Rect->new( { x => $x1, y => $y1, w => $x2 - $x1, h => $y2 - $y1 } ) );
    }
    if (@rects) {
        SDL_SetRenderDrawColor( $renderer, 128, 128, 128, 255 );
        for my $rect (@rects) {
            SDL_RenderDrawRect( $renderer, SDL2::Rect->new($rect) );
        }
    }
    SDL_RenderPresent($renderer);
}
SDL_DestroyRenderer($renderer);
SDL_DestroyWindow($window);
SDL_Quit();
exit;
