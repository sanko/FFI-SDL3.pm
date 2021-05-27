[![Actions Status](https://github.com/sanko/SDL2.pm/workflows/CI/badge.svg)](https://github.com/sanko/SDL2.pm/actions) [![MetaCPAN Release](https://badge.fury.io/pl/SDL2.svg)](https://metacpan.org/release/SDL2)
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

# Initialization and Shutdown

The functions in this category are used to set up SDL for use and generally
have global effects in your program.

## `SDL_Init( ... )`

Initialize the SDL library.

`SDL_Init( ... )` simply forwards to calling [`SDL_InitSubSystem( ...
)`](#sdl_initsubsystem). Therefore, the two may be used
interchangeably. Though for readability of your code [`SDL_InitSubSystem(
... )`](#sdl_initsubsystem) might be preferred.

The file I/O (for example: SDL\_RWFromFile) and threading (SDL\_CreateThread)
subsystems are initialized by default. Message boxes (SDL\_ShowSimpleMessageBox)
also attempt to work without initializing the video subsystem, in hopes of
being useful in showing an error dialog when SDL\_Init fails. You must
specifically initialize other subsystems if you use them in your application.

Logging (such as SDL\_Log) works without initialization, too.

Expected parameters include:

- `flags` which may be any be imported from SDL2::Enum with the [`:init`](https://metacpan.org/pod/SDL2%3A%3AEnum#init) tag and may be OR'd together.

Subsystem initialization is ref-counted, you must call [`SDL_QuitSubSystem(
... )`](#sdl_quitsubsystem) for each [`SDL_InitSubSystem( ...
)`](#sdl_initsubsystem) to correctly shutdown a subsystem manually
(or call [`SDL_Quit( )`](#sdl_quit) to force shutdown). If a
subsystem is already loaded then this call will increase the ref-count and
return.

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror) for more information.

## `SDL_InitSubSystem( ... )`

Compatibility function to initialize the SDL library.

In SDL2, this function and [`SDL_Init( ... )`](#sdl_init) are
interchangeable.

Expected parameters include:

- `flags` which may be any be imported from SDL2::Enum with the [`:init`](https://metacpan.org/pod/SDL2%3A%3AEnum#init) tag and may be OR'd together.

Returns `0` on success or a negative error code on failure; call [`SDL_GetError()`](#sdl_geterror) for more information.

## `SDL_Quit( )`

Clean up all initialized subsystems.

You should call this function even if you have already shutdown each
initialized subsystem with [`SDL_QuitSubSystem( )`](#sdl_quitsubsystem). It is safe to call this function even in the case of errors in
initialization.

If you start a subsystem using a call to that subsystem's init function (for
example [`SDL_VideoInit()`](#sdl_videoinit)) instead of [`SDL_Init( ... )`](#sdl_init) or [`SDL_InitSubSystem( ...
)`](#sdl_initsubsystem), then you must use that subsystem's quit
function ([`SDL_VideoQuit( )`](#sdl_videoquit)) to shut it down
before calling `SDL_Quit( )`. But generally, you should not be using those
functions directly anyhow; use [`SDL_Init( ... )`](#sdl_init)
instead.

You can use this function in an `END { ... }` block to ensure that it is run
when your application is shutdown.

## `SDL_QuitSubSystem( ... )`

Shut down specific SDL subsystems.

If you start a subsystem using a call to that subsystem's init function (for
example [`SDL_VideoInit( )` ](#sdl_videoinit)) instead of [`SDL_Init( ... )`](#sdl_init) or [`SDL_InitSubSystem( ...
)`](#sdl_initsubsystem), [`SDL_QuitSubSystem( ...
)`](#sdl_quitsubsystem) and [`SDL_WasInit( ...
)`](#sdl_wasinit) will not work. You will need to use that
subsystem's quit function ( [`SDL_VideoQuit( )`](#sdl_videoquit)
directly instead. But generally, you should not be using those functions
directly anyhow; use [`SDL_Init( ... )`](#sdl_init) instead.

You still need to call [`SDL_Quit( )`](#sdl_quit) even if you close
all open subsystems with [`SDL_QuitSubSystem( ... )`](#sdl_quitsubsystem).

Expected parameters include:

- `flags` which may be any be imported from SDL2::Enum with the [`:init`](https://metacpan.org/pod/SDL2%3A%3AEnum#init) tag and may be OR'd together.

## `SDL_WasInit( ... )`

Get a mask of the specified subsystems which are currently initialized.

Expected parameters include:

- `flags` which may be any be imported from SDL2::Enum with the [`:init`](https://metacpan.org/pod/SDL2%3A%3AEnum#init) tag and may be OR'd together.

If `flags` is `0`, it returns a mask of all initialized subsystems, otherwise
it returns the initialization status of the specified subsystems.

The return value does not include `SDL_INIT_NOPARACHUTE`.

# Configuration Variables

This category contains functions to set and get configuration hints, as well as
listing each of them alphabetically.

The convention for naming hints is `SDL_HINT_X`, where `SDL_X` is the
environment variable that can be used to override the default.

In general these hints are just that - they may or may not be supported or
applicable on any given platform, but they provide a way for an application or
user to give the library a hint as to how they would like the library to work.

## `SDL_SetHintWithPriority( ... )`

Set a hint with a specific priority.

        SDL_SetHintWithPriority( SDL_EVENT_LOGGING, 2, SDL_HINT_OVERRIDE );

The priority controls the behavior when setting a hint that already has a
value. Hints will replace existing hints of their priority and lower.
Environment variables are considered to have override priority.

Expected parameters include:

- `name`

    the hint to set

- `value`

    the value of the hint variable

- `priority`

    the priority level for the hint

Returns a true if the hint was set, untrue otherwise.

## `SDL_SetHint( ... )`

Set a hint with normal priority.

        SDL_SetHint( SDL_HINT_XINPUT_ENABLED, 1 );

Hints will not be set if there is an existing override hint or environment
variable that takes precedence. You can use SDL\_SetHintWithPriority() to set
the hint with override priority instead.

Expected parameters:

- `name`

    the hint to set

- `value`

    the value of the hint variable

Returns a true value if the hint was set, untrue otherwise.

## `SDL_GetHint( ... )`

Get the value of a hint.

        SDL_GetHint( SDL_HINT_XINPUT_ENABLED );

Expected parameters:

- `name`

    the hint to query

Returns the string value of a hint or an undefined value if the hint isn't set.

## `SDL_GetHintBoolean( ... )`

Get the boolean value of a hint variable.

        SDL_GetHintBoolean( SDL_HINT_XINPUT_ENABLED, 0);

Expected parameters:

- `name`

    the name of the hint to get the boolean value from

- `default_value`

    the value to return if the hint does not exist

Returns the boolean value of a hint or the provided default value if the hint
does not exist.

## `SDL_AddHintCallback( ... )`

Add a function to watch a particular hint.

        my $cb = SDL_AddHintCallback(
                SDL_HINT_XINPUT_ENABLED,
                sub {
                        my ($userdata, $name, $oldvalue, $newvalue) = @_;
                        ...;
                },
                { time => time(), clicks => 3 }
        );

Expected parameters:

- `name`

    the hint to watch

- `callback`

    a code reference that will be called when the hint value changes

- `userdata`

    a pointer to pass to the callback function

Returns a pointer to a [FFI::Platypus::Closure](https://metacpan.org/pod/FFI%3A%3APlatypus%3A%3AClosure) which you may pass to [`SDL_DelHintCallback( ... )`](#sdl_delhintcallback).

## `SDL_DelHintCallback( ... )`

Remove a callback watching a particular hint.

        SDL_AddHintCallback(
                SDL_HINT_XINPUT_ENABLED,
                $cb,
                { time => time(), clicks => 3 }
        );

Expected parameters:

- `name`

    the hint to watch

- `callback`

    [FFI::Platypus::Closure](https://metacpan.org/pod/FFI%3A%3APlatypus%3A%3AClosure) object returned by [`SDL_AddHintCallback( ...
    )`](#sdl_addhintcallback)

- `userdata`

    a pointer to pass to the callback function

## `SDL_ClearHints()`

Clear all hints.

        SDL_ClearHints();

This function is automatically called during [`SDL_Quit( )`](#sdl_quit).

# Error Handling

Functions in this category provide simple error message routines for SDL. [`SDL_GetError( )`](#sdl_geterror) can be called for almost all SDL
functions to determine what problems are occurring. Check the wiki page of each
specific SDL function to see whether [`SDL_GetError( )`](#sdl_geterror) is meaningful for them or not.

The SDL error messages are in English.

## `SDL_SetError( ... )`

Set the SDL error message for the current thread.

Calling this function will replace any previous error message that was set.

This function always returns `-1`, since SDL frequently uses `-1` to signify
an failing result, leading to this idiom:

        if ($error_code) {
                return SDL_SetError( 'This operation has failed: %d', $error_code );
        }

Expected parameters:

- `fmt`

    a `printf()`-style message format string

- `@params`

    additional parameters matching % tokens in the `fmt` string, if any

## `SDL_GetError( )`

Retrieve a message about the last error that occurred on the current thread.

        warn SDL_GetError();

It is possible for multiple errors to occur before calling `SDL_GetError()`.
Only the last error is returned.

The message is only applicable when an SDL function has signaled an error. You
must check the return values of SDL function calls to determine when to
appropriately call `SDL_GetError()`. You should **not** use the results of
`SDL_GetError()` to decide if an error has occurred! Sometimes SDL will set an
error string even when reporting success.

SDL will **not** clear the error string for successful API calls. You **must**
check return values for failure cases before you can assume the error string
applies.

Error strings are set per-thread, so an error set in a different thread will
not interfere with the current thread's operation.

The returned string is internally allocated and must not be freed by the
application.

Returns a message with information about the specific error that occurred, or
an empty string if there hasn't been an error message set since the last call
to [`SDL_ClearError()`](#sdl_clearerror). The message is only
applicable when an SDL function has signaled an error. You must check the
return values of SDL function calls to determine when to appropriately call
`SDL_GetError()`.

## `SDL_GetErrorMsg( ... )`

Get the last error message that was set for the current thread.

        my $x;
        warn SDL_GetErrorMsg($x, 300);

This allows the caller to copy the error string into a provided buffer, but
otherwise operates exactly the same as [`SDL_GetError()`](#sdl_geterror).

- `errstr`

    A buffer to fill with the last error message that was set for the current
    thread

- `maxlen`

    The size of the buffer pointed to by the errstr parameter

Returns the pointer passed in as the `errstr` parameter.

## `SDL_ClearError( )`

Clear any previous error message for this thread.

# LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

# AUTHOR

Sanko Robinson <sanko@cpan.org>
