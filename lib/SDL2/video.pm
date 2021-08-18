package SDL2::video {
    use lib '../../lib';
    use strictures 2;
    use experimental 'signatures';
    use SDL2::Utils;
    #
    #use SDL2::pixels;
    #use SDL2::rect;
    #use SDL2::DisplayMode;
    #
    ffi->type( '(opaque,opaque,opaque)->int' => 'SDL_HitTest' );
    attach video => {
        SDL_GetNumVideoDrivers     => [ [],         'int' ],
        SDL_GetVideoDriver         => [ ['int'],    'string' ],
        SDL_VideoInit              => [ ['string'], 'int' ],
        SDL_VideoQuit              => [ [] ],
        SDL_GetCurrentVideoDriver  => [ [],                                              'string' ],
        SDL_GetNumVideoDisplays    => [ [],                                              'int' ],
        SDL_GetDisplayName         => [ ['int'],                                         'string' ],
        SDL_GetDisplayBounds       => [ [ 'int', 'SDL_Rect' ],                           'int' ],
        SDL_GetDisplayUsableBounds => [ [ 'int', 'SDL_Rect' ],                           'int' ],
        SDL_GetDisplayDPI          => [ [ 'int', 'float *', 'float *', 'float *' ],      'int' ],
        SDL_GetDisplayOrientation  => [ ['int'],                                         'int' ],
        SDL_GetNumDisplayModes     => [ ['int'],                                         'int' ],
        SDL_GetDisplayMode         => [ [ 'int', 'int', 'SDL_DisplayMode' ],             'int' ],
        SDL_GetDesktopDisplayMode  => [ [ 'int', 'SDL_DisplayMode' ],                    'int' ],
        SDL_GetCurrentDisplayMode  => [ [ 'int', 'SDL_DisplayMode' ],                    'int' ],
        SDL_GetClosestDisplayMode  => [ [ 'int', 'SDL_DisplayMode', 'SDL_DisplayMode' ], 'opaque' ],
        SDL_GetWindowDisplayIndex  => [ ['SDL_Window'],                                  'int' ],
        SDL_SetWindowDisplayMode   => [ [ 'SDL_Window', 'SDL_DisplayMode' ],             'int' ],
        SDL_GetWindowDisplayMode   => [ [ 'SDL_Window', 'SDL_DisplayMode' ],             'int' ],
        SDL_GetWindowPixelFormat   => [ ['SDL_Window'],                                  'uint32' ],
        SDL_CreateWindow => [ [ 'string', 'int', 'int', 'int', 'int', 'uint32' ] => 'SDL_Window' ],
        SDL_CreateWindowFrom => [ ['opaque']     => 'SDL_Window' ],
        SDL_GetWindowID      => [ ['SDL_Window'] => 'uint32' ],
        SDL_GetWindowFromID  => [ ['uint32']     => 'SDL_Window' ],
        SDL_GetWindowFlags   => [ ['SDL_Window'] => 'uint32' ],
        SDL_SetWindowTitle   => [ [ 'SDL_Window', 'string' ] ],
        SDL_GetWindowTitle   => [ ['SDL_Window'], 'string' ],
        SDL_SetWindowIcon    => [ [ 'SDL_Window', 'SDL_Surface' ] ],

        # These don't work correctly yet. (cast issues)
        SDL_SetWindowData            => [ [ 'SDL_Window', 'string', 'opaque*' ], 'opaque*' ],
        SDL_GetWindowData            => [ [ 'SDL_Window', 'string' ], 'opaque*' ],
        SDL_SetWindowPosition        => [ [ 'SDL_Window', 'int',  'int' ] ],
        SDL_GetWindowPosition        => [ [ 'SDL_Window', 'int*', 'int*' ] ],
        SDL_SetWindowSize            => [ [ 'SDL_Window', 'int',  'int' ] ],
        SDL_GetWindowSize            => [ [ 'SDL_Window', 'int*', 'int*' ] ],
        SDL_GetWindowBordersSize     => [ [ 'SDL_Window', 'int*', 'int*', 'int*', 'int*' ], 'int' ],
        SDL_SetWindowMinimumSize     => [ [ 'SDL_Window', 'int',  'int' ] ],
        SDL_GetWindowMinimumSize     => [ [ 'SDL_Window', 'int*', 'int*' ] ],
        SDL_SetWindowMaximumSize     => [ [ 'SDL_Window', 'int',  'int' ] ],
        SDL_GetWindowMaximumSize     => [ [ 'SDL_Window', 'int*', 'int*' ] ],
        SDL_SetWindowBordered        => [ [ 'SDL_Window', 'bool' ] ],
        SDL_SetWindowResizable       => [ [ 'SDL_Window', 'bool' ] ],
        SDL_ShowWindow               => [ ['SDL_Window'] ],
        SDL_HideWindow               => [ ['SDL_Window'] ],
        SDL_RaiseWindow              => [ ['SDL_Window'] ],
        SDL_MaximizeWindow           => [ ['SDL_Window'] ],
        SDL_MinimizeWindow           => [ ['SDL_Window'] ],
        SDL_RestoreWindow            => [ ['SDL_Window'] ],
        SDL_SetWindowFullscreen      => [ [ 'SDL_Window', 'uint32' ],         'int' ],
        SDL_GetWindowSurface         => [ ['SDL_Window'],                     'SDL_Surface' ],
        SDL_UpdateWindowSurface      => [ ['SDL_Window'],                     'int' ],
        SDL_UpdateWindowSurfaceRects => [ [ 'SDL_Window', 'opaque*', 'int' ], 'int' ],
        SDL_SetWindowGrab            => [ [ 'SDL_Window', 'bool' ] ],
        ( ver->patch >= 15 ? ( SDL_SetWindowKeyboardGrab => [ [ 'SDL_Window', 'bool' ] ] ) : () ),
        ( ver->patch >= 15 ? ( SDL_SetWindowMouseGrab    => [ [ 'SDL_Window', 'bool' ] ] ) : () ),
        SDL_GetWindowGrab => [ ['SDL_Window'], 'bool' ],
        ( ver->patch >= 15 ? ( SDL_GetWindowKeyboardGrab => [ ['SDL_Window'], 'bool' ] ) : () ),
        ( ver->patch >= 15 ? ( SDL_GetWindowMouseGrab    => [ ['SDL_Window'], 'bool' ] ) : () ),
        SDL_GetGrabbedWindow    => [ [],                             'SDL_Window' ],
        SDL_SetWindowBrightness => [ [ 'SDL_Window', 'float' ],      'int' ],
        SDL_GetWindowBrightness => [ ['SDL_Window'],                 'float' ],
        SDL_SetWindowOpacity    => [ [ 'SDL_Window', 'float' ],      'int' ],
        SDL_GetWindowOpacity    => [ [ 'SDL_Window', 'float*' ],     'int' ],
        SDL_SetWindowModalFor   => [ [ 'SDL_Window', 'SDL_Window' ], 'int' ],
        SDL_SetWindowInputFocus => [ ['SDL_Window'],                 'int' ],
        SDL_SetWindowGammaRamp  =>
            [ [ 'SDL_Window', 'uint32[256]', 'uint32[256]', 'uint32[256]' ], 'int' ],
        SDL_GetWindowGammaRamp => [
            [ 'SDL_Window', 'uint32[256]', 'uint32[256]', 'uint32[256]' ], 'int'

                #=> sub ( $inner, $window ) {
                #    my @red = my @blue = my @green = map { \0 } 1 .. 256;
                #    my $ok  = $inner->( $window, \@red, \@green, \@blue );
                #    $ok == 0 ? ( \@red, \@green, \@blue ) : $ok;
                #}
        ],
        SDL_SetWindowHitTest => [
            [ 'SDL_Window', 'SDL_HitTest', 'opaque' ],
            'int' => sub ( $xsub, $window, $callback, $callback_data = () ) {    # Fake void pointer
                my $cb = $callback;
                if ( defined $callback ) {
                    $cb = FFI::Platypus::Closure->new(
                        sub ( $win, $area, $data ) {
                            $callback->(
                                ffi->cast( 'opaque' => 'SDL_Window', $win ),
                                ffi->cast( 'opaque' => 'SDL_Point',  $area ),
                                $callback_data
                            );
                        }
                    );
                    $cb->sticky;
                }
                $xsub->( $window, $cb, $callback_data );
                return $cb;
            }
        ],
        ( ver->patch >= 15 ? ( SDL_FlashWindow => [ [ 'SDL_Window', 'uint32' ], 'int' ] ) : () ),
        SDL_DestroyWindow        => [ ['SDL_Window'] ],
        SDL_IsScreenSaverEnabled => [ [], 'bool' ],
        SDL_EnableScreenSaver    => [ [] ],
        SDL_DisableScreenSaver   => [ [] ],
    };

=encoding utf-8

=head1 NAME

SDL2::video - SDL Video Functions

=head1 SYNOPSIS

    use SDL2 qw[:version];
    SDL_GetVersion( my $ver = SDL2::version->new );
    CORE::say sprintf 'SDL version %d.%d.%d', $ver->major, $ver->minor, $ver->patch;

=head1 DESCRIPTION

SDL2::version represents the library's version as three levels: major, minor,
and patch level.

=head1 Fields

=head2 C<major( )>

Returns value which increments with massive changes, additions, and
enhancements.

=head2 C<minor( )>

Returns value which increments with backwards-compatible changes to the major
revision.

=head2 C<patch( )>

Returns value which increments with fixes to the minor revision.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

=end stopwords

=cut

};
1;
