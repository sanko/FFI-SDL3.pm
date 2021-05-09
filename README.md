[![Build Status](https://travis-ci.com/sanko/SDL2.pm.svg?branch=master)](https://travis-ci.com/sanko/SDL2.pm) [![MetaCPAN Release](https://badge.fury.io/pl/SDL2.svg)](https://metacpan.org/release/SDL2)
# NAME

SDL2 - FFI Wrapper for SDL (Simple DirectMedia Layer) Development Library

# SYNOPSIS

    use SDL2;
    die 'Error initializing SDL: ' . SDL_GetError() unless SDL_Init(SDL_INIT_VIDEO) == 0;
    my $win = SDL_CreateWindow( 'Example window!',
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 640, 480, SDL_WINDOW_RESIZABLE );
    die 'Could not create window: ' . SDL_GetError() unless $win;
    my $event = SDL2::Event->new;
    SDL_Init(SDL_INIT_VIDEO);
    my $renderer = SDL_CreateRenderer( $win, -1, 0 );
    SDL_SetRenderDrawColor( $renderer, 242, 242, 242, 255 );
    do {
        SDL_WaitEventTimeout( $event, 10 );
        SDL_RenderClear($renderer);
        SDL_RenderPresent($renderer);
    } until $event->type == SDL_QUIT;
    SDL_DestroyRenderer($renderer);
    SDL_DestroyWindow($win);
    exit SDL_Quit();

# DESCRIPTION

SDL2 is ...

# Installlation

Use of this package requires you have SDL2 libs installed. Depending on your
environment, this might be an easy task or a difficult one.

If you need more information (building from scratch, etc.), see
[https://wiki.libsdl.org/Installation](https://wiki.libsdl.org/Installation).

## Linux

Install the SDL2 libs with your package manager or follow instructions from the
libSDL project.

### Debian (Ubuntu, et al.)

        sudo apt-get install libsdl2-dev

### Fedora

        sudo dnf install SDL2-devel

### Arch (Manjaro, et al.)

        sudo pacman -S sdl2

## Mac OS X

This is untested but might (should) work.

Prebuilt libraries can be found here: https://www.libsdl.org/download-2.0.php

### Installing with [brew](https://brew.sh/)

        brew install sdl2
        brew install sdl2_image

### Installing with `macports`

        sudo port install libsdl2

And then add the following to you bash init script:

        export LIBRARY_PATH="$LIBRARY_PATH:/opt/local/lib/"

## Windows

You have some options with Windows but I have not tested them yet.

Prebuilt binaries can be found here: https://www.libsdl.org/download-2.0.php

# LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

# AUTHOR

Sanko Robinson <sanko@cpan.org>
