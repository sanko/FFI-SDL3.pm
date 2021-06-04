[![Actions Status](https://github.com/sanko/SDL2.pm/workflows/CI/badge.svg)](https://github.com/sanko/SDL2.pm/actions) [![MetaCPAN Release](https://badge.fury.io/pl/SDL2-FFI.svg)](https://metacpan.org/release/SDL2-FFI)
# NAME

SDL2::FFI - FFI Wrapper for SDL (Simple DirectMedia Layer) Development Library

# SYNOPSIS

    use SDL2::FFI qw[:all];
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

SDL2::FFI is ...

This package is named `SDL2::FFI` because `SDL2` is being squatted on and I'd
rather make games than play them over namespaces.

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

- `flags` which may be any be imported with the [`:init`](https://metacpan.org/pod/SDL2%3A%3AFFI#init) tag and may be OR'd together.

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

- `flags` which may be any be imported with the [`:init`](https://metacpan.org/pod/SDL2%3A%3AFFI#init) tag and may be OR'd together.

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

- `flags` which may be any be imported with the [`:init`](https://metacpan.org/pod/SDL2%3A%3AFFI#init) tag and may be OR'd together.

## `SDL_WasInit( ... )`

Get a mask of the specified subsystems which are currently initialized.

Expected parameters include:

- `flags` which may be any be imported with the [`:init`](https://metacpan.org/pod/SDL2%3A%3AFFI#init) tag and may be OR'd together.

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

# Log Handling

Simple log messages with categories and priorities.

By default, logs are quiet but if you're debugging SDL you might want:

        SDL_LogSetAllPriority( SDL_LOG_PRIORITY_WARN );

Here's where the messages go on different platforms:

        Windows         debug output stream
        Android         log output
        Others          standard error output (STDERR)

Messages longer than the maximum size (4096 bytes) will be truncated.

## `SDL_LogSetAllPriority( ... )`

Set the priority of all log categories.

        SDL_LogSetAllPriority( SDL_LOG_PRIORITY_WARN );

Expected parameters:

- `priority`

    The SDL\_LogPriority to assign. These may be imported with the [`:logpriority`](#logpriority) tag.

## `SDL_LogSetPriority( ... )`

Set the priority of all log categories.

        SDL_LogSetPriority( SDL_LOG_CATEGORY_APPLICATION, SDL_LOG_PRIORITY_WARN );

Expected parameters:

- `category`

    The category to assign a priority to. These may be improted with the [`:logcategory`](#logcategory) tag.

- `priority`

    The SDL\_LogPriority to assign. These may be imported with the [`:logpriority`](#logpriority) tag.

## `SDL_LogGetPriority( ... )`

Get the priority of a particular log category.

        SDL_LogGetPriority( SDL_LOG_CATEGORY_ERROR );

Expected parameters:

- `category`

    The SDL\_LogCategory to query. These may be imported with the [`:logcategory`](#logcategory) tag.

## `SDL_LogGetPriority( ... )`

Get the priority of a particular log category.

        SDL_LogGetPriority( SDL_LOG_CATEGORY_ERROR );

Expected parameters:

- `category`

    The SDL\_LogCategory to query. These may be imported with the [`:logcategory`](#logcategory) tag.

## `SDL_LogResetPriorities( )`

Reset all priorities to default.

        SDL_LogResetPriorities( );

This is called by [`SDL_Quit( )`](#sdl_quit).

## `SDL_Log( ... )`

Log a message with `SDL_LOG_CATEGORY_APPLICATION` and
`SDL_LOG_PRIORITY_INFO`.

        SDL_Log( 'HTTP Status: %s', $http->status );

Expected parameters:

- `fmt`

    A `sprintf( )` style message format string.

- `...`

    Any additional parameters matching `%` tokens in the `fmt` string, if any.

## `SDL_LogVerbose( ... )`

Log a message with `SDL_LOG_PRIORITY_VERBOSE`.

        SDL_LogVerbose( 'Current time: %s [%ds exec]', +localtime(), time - $^T );

Expected parameters:

- `category`

    The category of the message.

- `fmt`

    A `sprintf()` style message format string.

- `...`

    Additional parameters matching `%` tokens in the `fmt` string, if any.

## `SDL_LogDebug( ... )`

Log a message with `SDL_LOG_PRIORITY_DEBUG`.

        SDL_LogDebug( 'Current time: %s [%ds exec]', +localtime(), time - $^T );

Expected parameters:

- `category`

    The category of the message.

- `fmt`

    A `sprintf()` style message format string.

- `...`

    Additional parameters matching `%` tokens in the `fmt` string, if any.

## `SDL_LogInfo( ... )`

Log a message with `SDL_LOG_PRIORITY_INFO`.

        SDL_LogInfo( 'Current time: %s [%ds exec]', +localtime(), time - $^T );

Expected parameters:

- `category`

    The category of the message.

- `fmt`

    A `sprintf()` style message format string.

- `...`

    Additional parameters matching `%` tokens in the `fmt` string, if any.

## `SDL_LogWarn( ... )`

Log a message with `SDL_LOG_PRIORITY_WARN`.

        SDL_LogWarn( 'Current time: %s [%ds exec]', +localtime(), time - $^T );

Expected parameters:

- `category`

    The category of the message.

- `fmt`

    A `sprintf()` style message format string.

- `...`

    Additional parameters matching `%` tokens in the `fmt` string, if any.

## `SDL_LogError( ... )`

Log a message with `SDL_LOG_PRIORITY_ERROR`.

        SDL_LogError( 'Current time: %s [%ds exec]', +localtime(), time - $^T );

Expected parameters:

- `category`

    The category of the message.

- `fmt`

    A `sprintf()` style message format string.

- `...`

    Additional parameters matching `%` tokens in the `fmt` string, if any.

## `SDL_LogCritical( ... )`

Log a message with `SDL_LOG_PRIORITY_CRITICAL`.

        SDL_LogCritical( 'Current time: %s [%ds exec]', +localtime(), time - $^T );

Expected parameters:

- `category`

    The category of the message.

- `fmt`

    A `sprintf()` style message format string.

- `...`

    Additional parameters matching `%` tokens in the `fmt` string, if any.

## `SDL_LogMessage( ... )`

Log a message with the specified category and priority.

        SDL_LogMessage( SDL_LOG_CATEGORY_APPLICATION, SDL_LOG_PRIORITY_CRITICAL,
                                        'Current time: %s [%ds exec]', +localtime(), time - $^T );

Expected parameters:

- `category`

    The category of the message.

- `priority`

    The priority of the message.

- `fmt`

    A `sprintf()` style message format string.

- `...`

    Additional parameters matching `%` tokens in the `fmt` string, if any.

## `SDL_LogSetOutputFunction( ... )`

Replace the default log output function with one of your own.

        my $cb = SDL_LogSetOutputFunction( sub { ... }, {} );

Expected parameters:

- `callback`

    A coderef to call instead of the default callback.

    This coderef should expect the following parameters:

    - `userdata`

        What was passed as `userdata` to `SDL_LogSetOutputFunction( )`.

    - `category`

        The category of the message.

    - `priority`

        The priority of the message.

    - `message`

        The message being output.

- `userdata`

    Data passed to the `callback`.

# Querying SDL Version

These functions are used to collect or display information about the version of
SDL that is currently being used by the program or that it was compiled
against.

The version consists of three segments (`X.Y.Z`)

- X - Major Version, which increments with massive changes, additions, and enhancements
- Y - Minor Version, which increments with backwards-compatible changes to the major revision
- Z - Patchlevel, which increments with fixes to the minor revision

Example: The first version of SDL 2 was 2.0.0

The version may also be reported as a 4-digit numeric value where the thousands
place represents the major version, the hundreds place represents the minor
version, and the tens and ones places represent the patchlevel (update
version).

Example: The first version number of SDL 2 was 2000

## `SDL_GetVersion( )`

Get the version of SDL that is linked against your program.

If you are linking to SDL dynamically, then it is possible that the current
version will be different than the version you compiled against. This function
returns the current version, while SDL\_VERSION() is a macro that tells you what
version you compiled with.

This function may be called safely at any time, even before [`SDL_Init(
)`](#sdl_init).

Return value is a [SDL2::FFI::Version](https://metacpan.org/pod/SDL2%3A%3AFFI%3A%3AVersion) object.

# Display and Window Management

This category contains functions for handling display and window actions.

These functions may be imported with the `:video` tag.

## `SDL_GetNumVideoDrivers( )`

        my $num = SDL_GetNumVideoDrivers( );

Get the number of video drivers compiled into SDL.

Returns a number >= 1 on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror) for more information.

## `SDL_GetVideoDriver( ... )`

Get the name of a built in video driver.

    CORE::say SDL_GetVideoDriver($_) for 0 .. SDL_GetNumVideoDrivers() - 1;

The video drivers are presented in the order in which they are normally checked
during initialization.

Expected parameters include:

- `index` - the index of a video driver

Returns the name of the video driver with the given `index`.

## `SDL_VideoInit( ... )`

Initialize the video subsystem, optionally specifying a video driver.

        SDL_VideoInit( 'x11' );

This function initializes the video subsystem, setting up a connection to the
window manager, etc, and determines the available display modes and pixel
formats, but does not initialize a window or graphics mode.

If you use this function and you haven't used the SDL\_INIT\_VIDEO flag with
either SDL\_Init() or SDL\_InitSubSystem(), you should call SDL\_VideoQuit()
before calling SDL\_Quit().

It is safe to call this function multiple times. SDL\_VideoInit() will call
SDL\_VideoQuit() itself if the video subsystem has already been initialized.

You can use SDL\_GetNumVideoDrivers() and SDL\_GetVideoDriver() to find a
specific \`driver\_name\`.

Expected parameters include:

- `driver_name` - the name of a video driver to initialize, or undef for the default driver

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror) for more information.

## `SDL_VideoQuit( )`

Shut down the video subsystem, if initialized with [`SDL_VideoInit(
)`](#sdl_videoinit).

        SDL_VideoQuit( );

This function closes all windows, and restores the original video mode.

# Imports

This list of imports will be organized by their related tags. Of course, you
may import them all by name as well.

## `:init`

These are the flags which may be passed to `SDL_Init()`. You should specify
the subsystems which you will be using in your application.

- `SDL_INIT_TIMER`

    Timer subsystem.

- `SDL_INIT_AUDIO`

    Audio subsystem.

- `SDL_INIT_VIDEO`

    Video subsystem. Automatically initializes the events subsystem.

- `SDL_INIT_JOYSTICK`

    Joystick subsystem. Automatically initializes the events subsystem.

- `SDL_INIT_HAPTIC`

    Haptic (force feedback) subsystem.

- `SDL_INIT_GAMECONTROLLER`

    Controller subsystem. Automatically initilizes the joystick subsystem.

- `SDL_INIT_EVENTS`

    Events subsystem.

- `SDL_INIT_EVERYTHING`

    All of the above subsystems.

- `SDL_INIT_SENSOR`
- `SDL_INIT_NOPARACHUTE`

    Compatibility; this flag is ignored.

## `:hints`

- `SDL_HINT_DEFAULT` - low priority, used for default values
- `SDL_HINT_NORMAL` - medium priority
- `SDL_HINT_OVERRIDE` - high priority

## SDL\_Hint

These enum values can be passed to [Configuration Variable](https://metacpan.org/pod/SDL2#Configuration-Variables) related functions.

- `SDL_HINT_ACCELEROMETER_AS_JOYSTICK`

    A hint that specifies whether the Android / iOS built-in accelerometer should
    be listed as a joystick device, rather than listing actual joysticks only.

    Values:

        0   list only real joysticks and accept input from them
        1   list real joysticks along with the accelorometer as if it were a 3 axis joystick (the default)

    Example:

        # This disables the use of gyroscopes as axis device
        SDL_SetHint(SDL_HINT_ACCELEROMETER_AS_JOYSTICK, "0");

- `SDL_HINT_ANDROID_APK_EXPANSION_MAIN_FILE_VERSION`

    A hint that specifies the Android APK expansion main file version.

    Values:

        X   the Android APK expansion main file version (should be a string number like "1", "2" etc.)

    This hint must be set together with the hint
    `SDL_HINT_ANDROID_APK_EXPANSION_PATCH_FILE_VERSION`.

    If both hints were set then `SDL_RWFromFile()` will look into expansion files
    after a given relative path was not found in the internal storage and assets.

    By default this hint is not set and the APK expansion files are not searched.

- `SDL_HINT_ANDROID_APK_EXPANSION_PATCH_FILE_VERSION`

    A hint that specifies the Android APK expansion patch file version.

    Values:

        X   the Android APK expansion patch file version (should be a string number like "1", "2" etc.)

    This hint must be set together with the hint
    `SDL_HINT_ANDROID_APK_EXPANSION_MAIN_FILE_VERSION`.

    If both hints were set then `SDL_RWFromFile()` will look into expansion files
    after a given relative path was not found in the internal storage and assets.

    By default this hint is not set and the APK expansion files are not searched.

- `SDL_HINT_ANDROID_SEPARATE_MOUSE_AND_TOUCH`

    A hint that specifies a variable to control whether mouse and touch events are
    to be treated together or separately.

    Values:

        0   mouse events will be handled as touch events and touch will raise fake mouse events (default)
        1   mouse events will be handled separately from pure touch events

    By default mouse events will be handled as touch events and touch will raise
    fake mouse events.

    The value of this hint is used at runtime, so it can be changed at any time.

- `SDL_HINT_APPLE_TV_CONTROLLER_UI_EVENTS`

    A hint that specifies whether controllers used with the Apple TV generate UI
    events.

    Values:

        0   controller input does not gnerate UI events (default)
        1   controller input generates UI events

    When UI events are generated by controller input, the app will be backgrounded
    when the Apple TV remote's menu button is pressed, and when the pause or B
    buttons on gamepads are pressed.

    More information about properly making use of controllers for the Apple TV can
    be found here:
    https://developer.apple.com/tvos/human-interface-guidelines/remote-and-controllers/

- `SDL_HINT_APPLE_TV_REMOTE_ALLOW_ROTATION`

    A hint that specifies whether the Apple TV remote's joystick axes will
    automatically match the rotation of the remote.

    Values:

        0   remote orientation does not affect joystick axes (default)
        1   joystick axes are based on the orientation of the remote

- `SDL_HINT_BMP_SAVE_LEGACY_FORMAT`

    A hint that specifies whether SDL should not use version 4 of the bitmap header
    when saving BMPs.

    Values:

        0   version 4 of the bitmap header will be used when saving BMPs (default)
        1   version 4 of the bitmap header will not be used when saving BMPs

    The bitmap header version 4 is required for proper alpha channel support and
    SDL will use it when required. Should this not be desired, this hint can force
    the use of the 40 byte header version which is supported everywhere.

    If the hint is not set then surfaces with a colorkey or an alpha channel are
    saved to a 32-bit BMP file with an alpha mask. SDL will use the bitmap header
    version 4 and set the alpha mask accordingly. This is the default behavior
    since SDL 2.0.5.

    If the hint is set then surfaces with a colorkey or an alpha channel are saved
    to a 32-bit BMP file without an alpha mask. The alpha channel data will be in
    the file, but applications are going to ignore it. This was the default
    behavior before SDL 2.0.5.

- `SDL_HINT_EMSCRIPTEN_ASYNCIFY`

    A hint that specifies if SDL should give back control to the browser
    automatically when running with asyncify.

    Values:

        0   disable emscripten_sleep calls (if you give back browser control manually or use asyncify for other purposes)
        1   enable emscripten_sleep calls (default)

    This hint only applies to the Emscripten platform.

- `SDL_HINT_EMSCRIPTEN_KEYBOARD_ELEMENT`

    A hint that specifies a value to override the binding element for keyboard
    inputs for Emscripten builds.

    Values:

        #window     the JavaScript window object (default)
        #document   the JavaScript document object
        #screen     the JavaScript window.screen object
        #canvas     the default WebGL canvas element

    Any other string without a leading # sign applies to the element on the page
    with that ID.

    This hint only applies to the Emscripten platform.

- `SDL_HINT_FRAMEBUFFER_ACCELERATION`

    A hint that specifies how 3D acceleration is used with
    [SDL\_GetWindowSurface()](https://metacpan.org/pod/SDL2#SDL_GetWindowSurface).

    Values:

        0   disable 3D acceleration
        1   enable 3D acceleration, using the default renderer
        X   enable 3D acceleration, using X where X is one of the valid rendering drivers. (e.g. "direct3d", "opengl", etc.)

    By default SDL tries to make a best guess whether to use acceleration or not on
    each platform.

    SDL can try to accelerate the screen surface returned by
    [SDL\_GetWindowSurface()](https://metacpan.org/pod/SDL2#SDL_GetWindowSurface) by using streaming
    textures with a 3D rendering engine. This variable controls whether and how
    this is done.

- `SDL_HINT_GAMECONTROLLERCONFIG`

    A variable that lets you provide a file with extra gamecontroller db entries.

    This hint must be set before calling `SDL_Init(SDL_INIT_GAMECONTROLLER)`.

    You can update mappings after the system is initialized with
    `SDL_GameControllerMappingForGUID()` and `SDL_GameControllerAddMapping()`.

- `SDL_HINT_GRAB_KEYBOARD`

    A variable setting the double click time, in milliseconds.

- `SDL_HINT_IDLE_TIMER_DISABLED`

    A hint that specifies a variable controlling whether the idle timer is disabled
    on iOS.

    Values:

        0   enable idle timer (default)
        1   disable idle timer

    When an iOS application does not receive touches for some time, the screen is
    dimmed automatically. For games where the accelerometer is the only input this
    is problematic. This functionality can be disabled by setting this hint.

    As of SDL 2.0.4, `SDL_EnableScreenSaver()` and `SDL_DisableScreenSaver()`
    accomplish the same thing on iOS. They should be preferred over this hint.

- `SDL_HINT_IME_INTERNAL_EDITING`

    A variable to control whether we trap the Android back button to handle it
    manually. This is necessary for the right mouse button to work on some Android
    devices, or to be able to trap the back button for use in your code reliably.
    If set to true, the back button will show up as an `SDL_KEYDOWN` /
    `SDL_KEYUP` pair with a keycode of `SDL_SCANCODE_AC_BACK`.

    The variable can be set to the following values:

        0   Back button will be handled as usual for system. (default)
        1   Back button will be trapped, allowing you to handle the key press
            manually. (This will also let right mouse click work on systems
            where the right mouse button functions as back.)

    The value of this hint is used at runtime, so it can be changed at any time.

- `SDL_HINT_JOYSTICK_ALLOW_BACKGROUND_EVENTS`

    A variable controlling whether the HIDAPI joystick drivers should be used.

    This variable can be set to the following values:

        0   HIDAPI drivers are not used
        1   HIDAPI drivers are used (default)

    This variable is the default for all drivers, but can be overridden by the
    hints for specific drivers below.

- `SDL_HINT_MAC_BACKGROUND_APP`

    A hint that specifies if the SDL app should not be forced to become a
    foreground process on Mac OS X.

    Values:

        0   force the SDL app to become a foreground process (default)
        1   do not force the SDL app to become a foreground process

    This hint only applies to Mac OSX.

- `SDL_HINT_MAC_CTRL_CLICK_EMULATE_RIGHT_CLICK`

    A hint that specifies whether ctrl+click should generate a right-click event on
    Mac.

    Values:

        0   disable emulating right click (default)
        1   enable emulating right click

- `SDL_HINT_MOUSE_FOCUS_CLICKTHROUGH`

    A hint that specifies if mouse click events are sent when clicking to focus an
    SDL window.

    Values:

        0   no mouse click events are sent when clicking to focus (default)
        1   mouse click events are sent when clicking to focus

- `SDL_HINT_MOUSE_RELATIVE_MODE_WARP`

    A hint that specifies whether relative mouse mode is implemented using mouse
    warping.

    Values:

        0   relative mouse mode uses the raw input (default)
        1   relative mouse mode uses mouse warping

- `SDL_HINT_NO_SIGNAL_HANDLERS`

    A hint that specifies not to catch the `SIGINT` or `SIGTERM` signals.

    Values:

        0   SDL will install a SIGINT and SIGTERM handler, and when it
            catches a signal, convert it into an SDL_QUIT event
        1   SDL will not install a signal handler at all

- `SDL_HINT_ORIENTATIONS`

    A variable controlling which orientations are allowed on iOS/Android.

    In some circumstances it is necessary to be able to explicitly control which UI
    orientations are allowed.

    This variable is a space delimited list of the following values:

    - `LandscapeLeft`
    - `LandscapeRight`
    - `Portrait`
    - `PortraitUpsideDown`

- `SDL_HINT_RENDER_DIRECT3D11_DEBUG`

    A variable controlling whether to enable Direct3D 11+'s Debug Layer.

    This variable does not have any effect on the Direct3D 9 based renderer.

    This variable can be set to the following values:

        0   Disable Debug Layer use (default)
        1   Enable Debug Layer use

- `SDL_HINT_RENDER_DIRECT3D_THREADSAFE`

    A variable controlling whether the Direct3D device is initialized for
    thread-safe operations.

    This variable can be set to the following values:

        0   Thread-safety is not enabled (faster; default)
        1   Thread-safety is enabled

- `SDL_HINT_RENDER_DRIVER`

    A variable specifying which render driver to use.

    If the application doesn't pick a specific renderer to use, this variable
    specifies the name of the preferred renderer. If the preferred renderer can't
    be initialized, the normal default renderer is used.

    This variable is case insensitive and can be set to the following values:

    - `direct3d`
    - `opengl`
    - `opengles2`
    - `opengles`
    - `metal`
    - `software`

    The default varies by platform, but it's the first one in the list that is
    available on the current platform.

- `SDL_HINT_RENDER_OPENGL_SHADERS`

    A variable controlling whether the OpenGL render driver uses shaders if they
    are available.

    This variable can be set to the following values:

        0   Disable shaders
        1   Enable shaders (default)

- `SDL_HINT_RENDER_SCALE_QUALITY`

    A variable controlling the scaling quality

    This variable can be set to the following values:     0 or nearest    Nearest
    pixel sampling (default)     1 or linear     Linear filtering (supported by
    OpenGL and Direct3D)     2 or best       Currently this is the same as linear

- `SDL_HINT_RENDER_VSYNC`

    A variable controlling whether updates to the SDL screen surface should be
    synchronized with the vertical refresh, to avoid tearing.

    This variable can be set to the following values:

        0   Disable vsync
        1   Enable vsync

    By default SDL does not sync screen surface updates with vertical refresh.

- `SDL_HINT_RPI_VIDEO_LAYER`

    Tell SDL which Dispmanx layer to use on a Raspberry PI

    Also known as Z-order. The variable can take a negative or positive value.

    The default is `10000`.

- `SDL_HINT_THREAD_STACK_SIZE`

    A string specifying SDL's threads stack size in bytes or `0` for the backend's
    default size

    Use this hint in case you need to set SDL's threads stack size to other than
    the default. This is specially useful if you build SDL against a non glibc libc
    library (such as musl) which provides a relatively small default thread stack
    size (a few kilobytes versus the default 8MB glibc uses). Support for this hint
    is currently available only in the pthread, Windows, and PSP backend.

    Instead of this hint, in 2.0.9 and later, you can use
    `SDL_CreateThreadWithStackSize()`. This hint only works with the classic
    `SDL_CreateThread()`.

- `SDL_HINT_TIMER_RESOLUTION`

    A variable that controls the timer resolution, in milliseconds.

    he higher resolution the timer, the more frequently the CPU services timer
    interrupts, and the more precise delays are, but this takes up power and CPU
    time.  This hint is only used on Windows.

    See this blog post for more information:
    [http://randomascii.wordpress.com/2013/07/08/windows-timer-resolution-megawatts-wasted/](http://randomascii.wordpress.com/2013/07/08/windows-timer-resolution-megawatts-wasted/)

    If this variable is set to `0`, the system timer resolution is not set.

    The default value is `1`. This hint may be set at any time.

- `SDL_HINT_VIDEO_ALLOW_SCREENSAVER`

    A variable controlling whether the screensaver is enabled.

    This variable can be set to the following values:

        0   Disable screensaver
        1   Enable screensaver

    By default SDL will disable the screensaver.

- `SDL_HINT_VIDEO_HIGHDPI_DISABLED`

    If set to `1`, then do not allow high-DPI windows. ("Retina" on Mac and iOS)

- `SDL_HINT_VIDEO_MAC_FULLSCREEN_SPACES`

    A variable that dictates policy for fullscreen Spaces on Mac OS X.

    This hint only applies to Mac OS X.

    The variable can be set to the following values:

        0   Disable Spaces support (FULLSCREEN_DESKTOP won't use them and
            SDL_WINDOW_RESIZABLE windows won't offer the "fullscreen"
            button on their titlebars).
        1   Enable Spaces support (FULLSCREEN_DESKTOP will use them and
            SDL_WINDOW_RESIZABLE windows will offer the "fullscreen"
            button on their titlebars).

    The default value is `1`. Spaces are disabled regardless of this hint if the
    OS isn't at least Mac OS X Lion (10.7). This hint must be set before any
    windows are created.

- `SDL_HINT_VIDEO_MINIMIZE_ON_FOCUS_LOSS`

    Minimize your `SDL_Window` if it loses key focus when in fullscreen mode.
    Defaults to false.

    Warning: Before SDL 2.0.14, this defaulted to true! In 2.0.14, we're seeing if
    "true" causes more problems than it solves in modern times.

- `SDL_HINT_VIDEO_WIN_D3DCOMPILER`

    A variable specifying which shader compiler to preload when using the Chrome
    ANGLE binaries

    SDL has EGL and OpenGL ES2 support on Windows via the ANGLE project. It can use
    two different sets of binaries, those compiled by the user from source or those
    provided by the Chrome browser. In the later case, these binaries require that
    SDL loads a DLL providing the shader compiler.

    This variable can be set to the following values:

    - `d3dcompiler_46.dll`

        default, best for Vista or later.

    - `d3dcompiler_43.dll`

        for XP support.

    - `none`

        do not load any library, useful if you compiled ANGLE from source and included
        the compiler in your binaries.

- `SDL_HINT_VIDEO_WINDOW_SHARE_PIXEL_FORMAT`

    A variable that is the address of another `SDL_Window*` (as a hex string
    formatted with `%p`).

    If this hint is set before `SDL_CreateWindowFrom()` and the `SDL_Window*` it
    is set to has `SDL_WINDOW_OPENGL` set (and running on WGL only, currently),
    then two things will occur on the newly created `SDL_Window`:

    - 1. Its pixel format will be set to the same pixel format as this `SDL_Window`. This is needed for example when sharing an OpenGL context across multiple windows.
    - 2. The flag SDL\_WINDOW\_OPENGL will be set on the new window so it can be used for OpenGL rendering.

    This variable can be set to the address (as a string `%p`) of the
    `SDL_Window*` that new windows created with `SDL_CreateWindowFrom()` should
    share a pixel format with.

- `SDL_HINT_VIDEO_X11_NET_WM_PING`

    A variable controlling whether the X11 \_NET\_WM\_PING protocol should be
    supported.

    This variable can be set to the following values:

        0    Disable _NET_WM_PING
        1   Enable _NET_WM_PING

    By default SDL will use \_NET\_WM\_PING, but for applications that know they will
    not always be able to respond to ping requests in a timely manner they can turn
    it off to avoid the window manager thinking the app is hung. The hint is
    checked in CreateWindow.

- `SDL_HINT_VIDEO_X11_XINERAMA`

    A variable controlling whether the X11 Xinerama extension should be used.

    This variable can be set to the following values:

        0   Disable Xinerama
        1   Enable Xinerama

    By default SDL will use Xinerama if it is available.

- `SDL_HINT_VIDEO_X11_XRANDR`

    A variable controlling whether the X11 XRandR extension should be used.

    This variable can be set to the following values:

        0   Disable XRandR
        1   Enable XRandR

    By default SDL will not use XRandR because of window manager issues.

- `SDL_HINT_VIDEO_X11_XVIDMODE`

    A variable controlling whether the X11 VidMode extension should be used.

    This variable can be set to the following values:

        0   Disable XVidMode
        1   Enable XVidMode

    By default SDL will use XVidMode if it is available.

- `SDL_HINT_WINDOW_FRAME_USABLE_WHILE_CURSOR_HIDDEN`

    A variable controlling whether the window frame and title bar are interactive
    when the cursor is hidden.

    This variable can be set to the following values:

        0   The window frame is not interactive when the cursor is hidden (no move, resize, etc)
        1   The window frame is interactive when the cursor is hidden

    By default SDL will allow interaction with the window frame when the cursor is
    hidden.

- `SDL_HINT_WINDOWS_DISABLE_THREAD_NAMING`

    Tell SDL not to name threads on Windows with the 0x406D1388 Exception. The
    0x406D1388 Exception is a trick used to inform Visual Studio of a thread's
    name, but it tends to cause problems with other debuggers, and the .NET
    runtime. Note that SDL 2.0.6 and later will still use the (safer)
    SetThreadDescription API, introduced in the Windows 10 Creators Update, if
    available.

    The variable can be set to the following values:

        0   SDL will raise the 0x406D1388 Exception to name threads.
            This is the default behavior of SDL <= 2.0.4.
        1   SDL will not raise this exception, and threads will be unnamed. (default)
            This is necessary with .NET languages or debuggers that aren't Visual Studio.

- `SDL_HINT_WINDOWS_INTRESOURCE_ICON`

    A variable to specify custom icon resource id from RC file on Windows platform.

- `SDL_HINT_WINDOWS_INTRESOURCE_ICON_SMALL`

    A variable to specify custom icon resource id from RC file on Windows platform.

- `SDL_HINT_WINDOWS_ENABLE_MESSAGELOOP`

    A variable controlling whether the windows message loop is processed by SDL .

    This variable can be set to the following values:

        0   The window message loop is not run
        1   The window message loop is processed in SDL_PumpEvents()

    By default SDL will process the windows message loop.

- `SDL_HINT_WINDOWS_NO_CLOSE_ON_ALT_F4`

    Tell SDL not to generate window-close events for Alt+F4 on Windows.

    The variable can be set to the following values:

        0   SDL will generate a window-close event when it sees Alt+F4.
        1   SDL will only do normal key handling for Alt+F4.

- `SDL_HINT_WINRT_HANDLE_BACK_BUTTON`

    Allows back-button-press events on Windows Phone to be marked as handled.

    Windows Phone devices typically feature a Back button.  When pressed, the OS
    will emit back-button-press events, which apps are expected to handle in an
    appropriate manner.  If apps do not explicitly mark these events as 'Handled',
    then the OS will invoke its default behavior for unhandled back-button-press
    events, which on Windows Phone 8 and 8.1 is to terminate the app (and attempt
    to switch to the previous app, or to the device's home screen).

    Setting the `SDL_HINT_WINRT_HANDLE_BACK_BUTTON` hint to "1" will cause SDL to
    mark back-button-press events as Handled, if and when one is sent to the app.

    Internally, Windows Phone sends back button events as parameters to special
    back-button-press callback functions.  Apps that need to respond to
    back-button-press events are expected to register one or more callback
    functions for such, shortly after being launched (during the app's
    initialization phase).  After the back button is pressed, the OS will invoke
    these callbacks.  If the app's callback(s) do not explicitly mark the event as
    handled by the time they return, or if the app never registers one of these
    callback, the OS will consider the event un-handled, and it will apply its
    default back button behavior (terminate the app).

    SDL registers its own back-button-press callback with the Windows Phone OS.
    This callback will emit a pair of SDL key-press events (`SDL_KEYDOWN` and
    `SDL_KEYUP`), each with a scancode of SDL\_SCANCODE\_AC\_BACK, after which it
    will check the contents of the hint, `SDL_HINT_WINRT_HANDLE_BACK_BUTTON`. If
    the hint's value is set to `1`, the back button event's Handled property will
    get set to a `true` value. If the hint's value is set to something else, or if
    it is unset, SDL will leave the event's Handled property alone. (By default,
    the OS sets this property to 'false', to note.)

    SDL apps can either set `SDL_HINT_WINRT_HANDLE_BACK_BUTTON` well before a back
    button is pressed, or can set it in direct-response to a back button being
    pressed.

    In order to get notified when a back button is pressed, SDL apps should
    register a callback function with `SDL_AddEventWatch()`, and have it listen
    for `SDL_KEYDOWN` events that have a scancode of `SDL_SCANCODE_AC_BACK`.
    (Alternatively, `SDL_KEYUP` events can be listened-for. Listening for either
    event type is suitable.)  Any value of `SDL_HINT_WINRT_HANDLE_BACK_BUTTON` set
    by such a callback, will be applied to the OS' current back-button-press event.

    More details on back button behavior in Windows Phone apps can be found at the
    following page, on Microsoft's developer site:
    [http://msdn.microsoft.com/en-us/library/windowsphone/develop/jj247550(v=vs.105).aspx](http://msdn.microsoft.com/en-us/library/windowsphone/develop/jj247550\(v=vs.105\).aspx)

- `SDL_HINT_WINRT_PRIVACY_POLICY_LABEL`

    Label text for a WinRT app's privacy policy link.

    Network-enabled WinRT apps must include a privacy policy. On Windows 8, 8.1,
    and RT, Microsoft mandates that this policy be available via the Windows
    Settings charm. SDL provides code to add a link there, with its label text
    being set via the optional hint, `SDL_HINT_WINRT_PRIVACY_POLICY_LABEL`.

    Please note that a privacy policy's contents are not set via this hint.  A
    separate hint, `SDL_HINT_WINRT_PRIVACY_POLICY_URL`, is used to link to the
    actual text of the policy.

    The contents of this hint should be encoded as a UTF8 string.

    The default value is "Privacy Policy". This hint should only be set during app
    initialization, preferably before any calls to `SDL_Init()`.

    For additional information on linking to a privacy policy, see the
    documentation for `SDL_HINT_WINRT_PRIVACY_POLICY_URL`.

- `SDL_HINT_WINRT_PRIVACY_POLICY_URL`

    A URL to a WinRT app's privacy policy.

    All network-enabled WinRT apps must make a privacy policy available to its
    users.  On Windows 8, 8.1, and RT, Microsoft mandates that this policy be be
    available in the Windows Settings charm, as accessed from within the app. SDL
    provides code to add a URL-based link there, which can point to the app's
    privacy policy.

    To setup a URL to an app's privacy policy, set
    `SDL_HINT_WINRT_PRIVACY_POLICY_URL` before calling any `SDL_Init()`
    functions.  The contents of the hint should be a valid URL.  For example,
    [http://www.example.com](http://www.example.com).

    The default value is an empty string (``), which will prevent SDL from adding
    a privacy policy link to the Settings charm. This hint should only be set
    during app init.

    The label text of an app's "Privacy Policy" link may be customized via another
    hint, `SDL_HINT_WINRT_PRIVACY_POLICY_LABEL`.

    Please note that on Windows Phone, Microsoft does not provide standard UI for
    displaying a privacy policy link, and as such,
    SDL\_HINT\_WINRT\_PRIVACY\_POLICY\_URL will not get used on that platform.
    Network-enabled phone apps should display their privacy policy through some
    other, in-app means.

- `SDL_HINT_XINPUT_ENABLED`

    A variable that lets you disable the detection and use of Xinput gamepad
    devices

    The variable can be set to the following values:

        0   Disable XInput detection (only uses direct input)
        1   Enable XInput detection (default)

- `SDL_HINT_XINPUT_USE_OLD_JOYSTICK_MAPPING`

    A variable that causes SDL to use the old axis and button mapping for XInput
    devices.

    This hint is for backwards compatibility only and will be removed in SDL 2.1

    The default value is `0`.  This hint must be set before `SDL_Init()`

- `SDL_HINT_QTWAYLAND_WINDOW_FLAGS`

    Flags to set on QtWayland windows to integrate with the native window manager.

    On QtWayland platforms, this hint controls the flags to set on the windows. For
    example, on Sailfish OS, `OverridesSystemGestures` disables swipe gestures.

    This variable is a space-separated list of the following values (empty = no
    flags):

    - `OverridesSystemGestures`
    - `StaysOnTop`
    - `BypassWindowManager`

- `SDL_HINT_QTWAYLAND_CONTENT_ORIENTATION`

    A variable describing the content orientation on QtWayland-based platforms.

    On QtWayland platforms, windows are rotated client-side to allow for custom
    transitions. In order to correctly position overlays (e.g. volume bar) and
    gestures (e.g. events view, close/minimize gestures), the system needs to know
    in which orientation the application is currently drawing its contents.

    This does not cause the window to be rotated or resized, the application needs
    to take care of drawing the content in the right orientation (the framebuffer
    is always in portrait mode).

    This variable can be one of the following values:

    - `primary` (default)
    - `portrait`
    - `landscape`
    - `inverted-portrait`
    - `inverted-landscape`

- `SDL_HINT_RENDER_LOGICAL_SIZE_MODE`

    A variable controlling the scaling policy for `SDL_RenderSetLogicalSize`.

    This variable can be set to the following values:

    - `0` or `letterbox`

        Uses letterbox/sidebars to fit the entire rendering on screen.

    - `1` or `overscan`

        Will zoom the rendering so it fills the entire screen, allowing edges to be
        drawn offscreen.

    By default letterbox is used.

- `SDL_HINT_VIDEO_EXTERNAL_CONTEXT`

    A variable controlling whether the graphics context is externally managed.

    This variable can be set to the following values:

        0   SDL will manage graphics contexts that are attached to windows.
        1   Disable graphics context management on windows.

    By default SDL will manage OpenGL contexts in certain situations. For example,
    on Android the context will be automatically saved and restored when pausing
    the application. Additionally, some platforms will assume usage of OpenGL if
    Vulkan isn't used. Setting this to `1` will prevent this behavior, which is
    desireable when the application manages the graphics context, such as an
    externally managed OpenGL context or attaching a Vulkan surface to the window.

- <SDL\_HINT\_VIDEO\_X11\_WINDOW\_VISUALID>

    A variable forcing the visual ID chosen for new X11 windows.

- `SDL_HINT_VIDEO_X11_NET_WM_BYPASS_COMPOSITOR`

    A variable controlling whether the X11 \_NET\_WM\_BYPASS\_COMPOSITOR hint should be
    used.

    This variable can be set to the following values:

        0   Disable _NET_WM_BYPASS_COMPOSITOR
        1   Enable _NET_WM_BYPASS_COMPOSITOR

    By default SDL will use \_NET\_WM\_BYPASS\_COMPOSITOR.

- `SDL_HINT_VIDEO_X11_FORCE_EGL`

    A variable controlling whether X11 should use GLX or EGL by default

    This variable can be set to the following values:

        0   Use GLX
        1   Use EGL

    By default SDL will use GLX when both are present.

- `SDL_HINT_MOUSE_DOUBLE_CLICK_TIME`

    A variable setting the double click time, in milliseconds.

- `SDL_HINT_MOUSE_DOUBLE_CLICK_RADIUS`

    A variable setting the double click radius, in pixels.

- `SDL_HINT_MOUSE_NORMAL_SPEED_SCALE`

    A variable setting the speed scale for mouse motion, in floating point, when
    the mouse is not in relative mode.

- `SDL_HINT_MOUSE_RELATIVE_SPEED_SCALE`

    A variable setting the scale for mouse motion, in floating point, when the
    mouse is in relative mode.

- `SDL_HINT_MOUSE_RELATIVE_SCALING`

    A variable controlling whether relative mouse motion is affected by renderer
    scaling

    This variable can be set to the following values:

        0   Relative motion is unaffected by DPI or renderer's logical size
        1   Relative motion is scaled according to DPI scaling and logical size

    By default relative mouse deltas are affected by DPI and renderer scaling.

- `SDL_HINT_TOUCH_MOUSE_EVENTS`

    A variable controlling whether touch events should generate synthetic mouse
    events

    This variable can be set to the following values:

        0   Touch events will not generate mouse events
        1   Touch events will generate mouse events

    By default SDL will generate mouse events for touch events.

- `SDL_HINT_MOUSE_TOUCH_EVENTS`

    A variable controlling whether mouse events should generate synthetic touch
    events

    This variable can be set to the following values:

        0   Mouse events will not generate touch events (default for desktop platforms)
        1   Mouse events will generate touch events (default for mobile platforms, such as Android and iOS)

- `SDL_HINT_IOS_HIDE_HOME_INDICATOR`

    A variable controlling whether the home indicator bar on iPhone X should be
    hidden.

    This variable can be set to the following values:

        0   The indicator bar is not hidden (default for windowed applications)
        1   The indicator bar is hidden and is shown when the screen is touched (useful for movie playback applications)
        2   The indicator bar is dim and the first swipe makes it visible and the second swipe performs the "home" action (default for fullscreen applications)

- `SDL_HINT_TV_REMOTE_AS_JOYSTICK`

    A variable controlling whether the Android / tvOS remotes should be listed as
    joystick devices, instead of sending keyboard events.

    This variable can be set to the following values:

        0   Remotes send enter/escape/arrow key events
        1   Remotes are available as 2 axis, 2 button joysticks (the default).

- `SDL_HINT_GAMECONTROLLERTYPE`

    A variable that overrides the automatic controller type detection

    The variable should be comma separated entries, in the form: VID/PID=type

    The VID and PID should be hexadecimal with exactly 4 digits, e.g. `0x00fd`

    The type should be one of:

    - `Xbox360`
    - `XboxOne`
    - `PS3`
    - `PS4`
    - `PS5`
    - `SwitchPro`

        This hint affects what driver is used, and must be set before calling
        `SDL_Init(SDL_INIT_GAMECONTROLLER)`.

    - `SDL_HINT_GAMECONTROLLERCONFIG_FILE`

        A variable that lets you provide a file with extra gamecontroller db entries.

        The file should contain lines of gamecontroller config data, see
        SDL\_gamecontroller.h

        This hint must be set before calling `SDL_Init(SDL_INIT_GAMECONTROLLER)`

        You can update mappings after the system is initialized with
        `SDL_GameControllerMappingForGUID()` and `SDL_GameControllerAddMapping()`.

    - `SDL_HINT_GAMECONTROLLER_IGNORE_DEVICES`

        A variable containing a list of devices to skip when scanning for game
        controllers.

        The format of the string is a comma separated list of USB VID/PID pairs in
        hexadecimal form, e.g.

            0xAAAA/0xBBBB,0xCCCC/0xDDDD

        The variable can also take the form of @file, in which case the named file will
        be loaded and interpreted as the value of the variable.

    - `SDL_HINT_GAMECONTROLLER_IGNORE_DEVICES_EXCEPT`

        If set, all devices will be skipped when scanning for game controllers except
        for the ones listed in this variable.

        The format of the string is a comma separated list of USB VID/PID pairs in
        hexadecimal form, e.g.

            0xAAAA/0xBBBB,0xCCCC/0xDDDD

        The variable can also take the form of @file, in which case the named file will
        be loaded and interpreted as the value of the variable.

    - `SDL_HINT_GAMECONTROLLER_USE_BUTTON_LABELS`

        If set, game controller face buttons report their values according to their
        labels instead of their positional layout.

        For example, on Nintendo Switch controllers, normally you'd get:

                (Y)
            (X)     (B)
                (A)

        but if this hint is set, you'll get:

                (X)
            (Y)     (A)
                (B)

        The variable can be set to the following values:

            0   Report the face buttons by position, as though they were on an Xbox controller.
            1   Report the face buttons by label instead of position

        The default value is `1`. This hint may be set at any time.

    - `SDL_HINT_JOYSTICK_HIDAPI`

        A variable controlling whether the HIDAPI joystick drivers should be used.

        This variable can be set to the following values:

            0   HIDAPI drivers are not used
            1   HIDAPI drivers are used (the default)

        This variable is the default forall drivers, but can be overridden by the hints
        for specific drivers below.\\

    - `SDL_HINT_JOYSTICK_HIDAPI_PS4`

        A variable controlling whether the HIDAPI driver for PS4 controllers should be
        used.

        This variable can be set to the following values:

            0   HIDAPI driver is not used
            1   HIDAPI driver is used

        The default is the value of `SDL_HINT_JOYSTICK_HIDAPI`

    - `SDL_HINT_JOYSTICK_HIDAPI_PS4_RUMBLE`

        A variable controlling whether extended input reports should be used for PS4
        controllers when using the HIDAPI driver.

        This variable can be set to the following values:

            0   extended reports are not enabled (default)
            1   extended reports

        Extended input reports allow rumble on Bluetooth PS4 controllers, but break
        DirectInput handling for applications that don't use SDL.

        Once extended reports are enabled, they can not be disabled without power
        cycling the controller.

        For compatibility with applications written for versions of SDL prior to the
        introduction of PS5 controller support, this value will also control the state
        of extended reports on PS5 controllers when the
        `SDL_HINT_JOYSTICK_HIDAPI_PS5_RUMBLE` hint is not explicitly set.

    - `SDL_HINT_JOYSTICK_HIDAPI_PS5`

        A variable controlling whether the HIDAPI driver for PS5 controllers should be
        used.

        This variable can be set to the following values:

            0   HIDAPI driver is not used
            1   HIDAPI driver is used

        The default is the value of `SDL_HINT_JOYSTICK_HIDAPI`.

    - `SDL_HINT_JOYSTICK_HIDAPI_PS5_RUMBLE`

        A variable controlling whether extended input reports should be used for PS5
        controllers when using the HIDAPI driver.

        This variable can be set to the following values:

            0   extended reports are not enabled (default)
            1   extended reports

        Extended input reports allow rumble on Bluetooth PS5 controllers, but break
        DirectInput handling for applications that don't use SDL.

        Once extended reports are enabled, they can not be disabled without power
        cycling the controller.

        For compatibility with applications written for versions of SDL prior to the
        introduction of PS5 controller support, this value defaults to the value of
        `SDL_HINT_JOYSTICK_HIDAPI_PS4_RUMBLE`.

    - `SDL_HINT_JOYSTICK_HIDAPI_PS5_PLAYER_LED`

        A variable controlling whether the player LEDs should be lit to indicate which
        player is associated with a PS5 controller.

        This variable can be set to the following values:

            0   player LEDs are not enabled
            1   player LEDs are enabled (default)

    - `SDL_HINT_JOYSTICK_HIDAPI_STADIA`

        A variable controlling whether the HIDAPI driver for Google Stadia controllers
        should be used.

        This variable can be set to the following values:

            0   HIDAPI driver is not used
            1   HIDAPI driver is used

        The default is the value of `SDL_HINT_JOYSTICK_HIDAPI`.

    - `SDL_HINT_JOYSTICK_HIDAPI_STEAM`

        A variable controlling whether the HIDAPI driver for Steam Controllers should
        be used.

        This variable can be set to the following values:

            0   HIDAPI driver is not used
            1   HIDAPI driver is used

        The default is the value of `SDL_HINT_JOYSTICK_HIDAPI`.

    - `SDL_HINT_JOYSTICK_HIDAPI_SWITCH`

        A variable controlling whether the HIDAPI driver for Nintendo Switch
        controllers should be used.

        This variable can be set to the following values:

            0   HIDAPI driver is not used
            1   HIDAPI driver is used

        The default is the value of `SDL_HINT_JOYSTICK_HIDAPI`.

    - `SDL_HINT_JOYSTICK_HIDAPI_SWITCH_HOME_LED`

        A variable controlling whether the Home button LED should be turned on when a
        Nintendo Switch controller is opened

        This variable can be set to the following values:

            0   home button LED is left off
            1   home button LED is turned on (default)

    - `SDL_HINT_JOYSTICK_HIDAPI_JOY_CONS`

        A variable controlling whether Switch Joy-Cons should be treated the same as
        Switch Pro Controllers when using the HIDAPI driver.

        This variable can be set to the following values:

            0   basic Joy-Con support with no analog input (default)
            1   Joy-Cons treated as half full Pro Controllers with analog inputs and sensors

        This does not combine Joy-Cons into a single controller. That's up to the user.

    - `SDL_HINT_JOYSTICK_HIDAPI_XBOX`

        A variable controlling whether the HIDAPI driver for XBox controllers should be
        used.

        This variable can be set to the following values:

            0   HIDAPI driver is not used
            1   HIDAPI driver is used

        The default is `0` on Windows, otherwise the value of
        `SDL_HINT_JOYSTICK_HIDAPI`.

    - `SDL_HINT_JOYSTICK_HIDAPI_CORRELATE_XINPUT`

        A variable controlling whether the HIDAPI driver for XBox controllers on
        Windows should pull correlated data from XInput.

        This variable can be set to the following values:

            0   HIDAPI Xbox driver will only use HIDAPI data
            1   HIDAPI Xbox driver will also pull data from XInput, providing better trigger axes, guide button
                presses, and rumble support

        The default is `1`.  This hint applies to any joysticks opened after setting
        the hint.

    - `SDL_HINT_JOYSTICK_HIDAPI_GAMECUBE`

        A variable controlling whether the HIDAPI driver for Nintendo GameCube
        controllers should be used.

        This variable can be set to the following values:

            0   HIDAPI driver is not used
            1   HIDAPI driver is used

        The default is the value of `SDL_HINT_JOYSTICK_HIDAPI`.

    - `SDL_HINT_ENABLE_STEAM_CONTROLLERS`

        A variable that controls whether Steam Controllers should be exposed using the
        SDL joystick and game controller APIs

        The variable can be set to the following values:

            0   Do not scan for Steam Controllers
            1   Scan for Steam Controllers (default)

        The default value is `1`.  This hint must be set before initializing the
        joystick subsystem.

    - `SDL_HINT_JOYSTICK_RAWINPUT`

        A variable controlling whether the RAWINPUT joystick drivers should be used for
        better handling XInput-capable devices.

        This variable can be set to the following values:

            0   RAWINPUT drivers are not used
            1   RAWINPUT drivers are used (default)

    - `SDL_HINT_JOYSTICK_THREAD`

        A variable controlling whether a separate thread should be used for handling
        joystick detection and raw input messages on Windows

        This variable can be set to the following values:

            0   A separate thread is not used (default)
            1   A separate thread is used for handling raw input messages

    - `SDL_HINT_LINUX_JOYSTICK_DEADZONES`

        A variable controlling whether joysticks on Linux adhere to their HID-defined
        deadzones or return unfiltered values.

        This variable can be set to the following values:

            0   Return unfiltered joystick axis values (default)
            1   Return axis values with deadzones taken into account

    - `SDL_HINT_ALLOW_TOPMOST`

        If set to `0` then never set the top most bit on a SDL Window, even if the
        video mode expects it. This is a debugging aid for developers and not expected
        to be used by end users. The default is `1`.

        This variable can be set to the following values:

            0   don't allow topmost
            1   allow topmost (default)

    - `SDL_HINT_THREAD_PRIORITY_POLICY`

        A string specifying additional information to use with
        `SDL_SetThreadPriority`.

        By default `SDL_SetThreadPriority` will make appropriate system changes in
        order to apply a thread priority. For example on systems using pthreads the
        scheduler policy is changed automatically to a policy that works well with a
        given priority. Code which has specific requirements can override SDL's default
        behavior with this hint.

        pthread hint values are `current`, `other`, `fifo` and `rr`. Currently no
        other platform hint values are defined but may be in the future.

        Note:

        On Linux, the kernel may send `SIGKILL` to realtime tasks which exceed the
        distro configured execution budget for rtkit. This budget can be queried
        through `RLIMIT_RTTIME` after calling `SDL_SetThreadPriority()`.

    - `SDL_HINT_THREAD_FORCE_REALTIME_TIME_CRITICAL`

        Specifies whether `SDL_THREAD_PRIORITY_TIME_CRITICAL` should be treated as
        realtime.

        On some platforms, like Linux, a realtime priority thread may be subject to
        restrictions that require special handling by the application. This hint exists
        to let SDL know that the app is prepared to handle said restrictions.

        On Linux, SDL will apply the following configuration to any thread that becomes
        realtime:

        - The SCHED\_RESET\_ON\_FORK bit will be set on the scheduling policy,
        - An RLIMIT\_RTTIME budget will be configured to the rtkit specified limit.

            Exceeding this limit will result in the kernel sending `SIGKILL` to the app,

            Refer to the man pages for more information.

        This variable can be set to the following values:

            0   default platform specific behaviour
            1   Force SDL_THREAD_PRIORITY_TIME_CRITICAL to a realtime scheduling policy

    - `SDL_HINT_VIDEO_WINDOW_SHARE_PIXEL_FORMAT`

        A variable that is the address of another SDL\_Window\* (as a hex string
        formatted with `%p`).

        If this hint is set before `SDL_CreateWindowFrom()` and the `SDL_Window*` it
        is set to has `SDL_WINDOW_OPENGL` set (and running on WGL only, currently),
        then two things will occur on the newly created `SDL_Window`:

        - 1. Its pixel format will be set to the same pixel format as this `SDL_Window`. This is needed for example when sharing an OpenGL context across multiple windows.
        - 2. The flag `SDL_WINDOW_OPENGL` will be set on the new window so it can be used for OpenGL rendering.

            This variable can be set to the following values:

            - The address (as a string `%p`) of the `SDL_Window*` that new windows created with `SDL_CreateWindowFrom()` should share a pixel format with.

        - `SDL_HINT_ANDROID_TRAP_BACK_BUTTON`

            A variable to control whether we trap the Android back button to handle it
            manually. This is necessary for the right mouse button to work on some Android
            devices, or to be able to trap the back button for use in your code reliably.
            If set to true, the back button will show up as an SDL\_KEYDOWN / SDL\_KEYUP pair
            with a keycode of `SDL_SCANCODE_AC_BACK`.

            The variable can be set to the following values:

            - `0`

                Back button will be handled as usual for system. (default)

            - `1`

                Back button will be trapped, allowing you to handle the key press manually.
                (This will also let right mouse click work on systems where the right mouse
                button functions as back.)

            The value of this hint is used at runtime, so it can be changed at any time.

    - `SDL_HINT_ANDROID_BLOCK_ON_PAUSE`

        A variable to control whether the event loop will block itself when the app is
        paused.

        The variable can be set to the following values:

        - `0`

            Non blocking.

        - `1`

            Blocking. (default)

        The value should be set before SDL is initialized.

- `SDL_HINT_ANDROID_BLOCK_ON_PAUSE_PAUSEAUDIO`

    A variable to control whether SDL will pause audio in background (Requires
    `SDL_ANDROID_BLOCK_ON_PAUSE` as "Non blocking")

    The variable can be set to the following values:

    - `0`

        Non paused.

    - `1`

        Paused. (default)

    The value should be set before SDL is initialized.

- `SDL_HINT_RETURN_KEY_HIDES_IME`

    A variable to control whether the return key on the soft keyboard should hide
    the soft keyboard on Android and iOS.

    The variable can be set to the following values:

    - `0`

        The return key will be handled as a key event. This is the behaviour of SDL <=
        2.0.3. (default)

    - `1`

        The return key will hide the keyboard.

    The value of this hint is used at runtime, so it can be changed at any time.

- `SDL_HINT_WINDOWS_FORCE_MUTEX_CRITICAL_SECTIONS`

    Force SDL to use Critical Sections for mutexes on Windows. On Windows 7 and
    newer, Slim Reader/Writer Locks are available. They offer better performance,
    allocate no kernel resources and use less memory. SDL will fall back to
    Critical Sections on older OS versions or if forced to by this hint.

    This also affects Condition Variables. When SRW mutexes are used, SDL will use
    Windows Condition Variables as well. Else, a generic SDL\_cond implementation
    will be used that works with all mutexes.

    This variable can be set to the following values:

    - `0`

        Use SRW Locks when available. If not, fall back to Critical Sections. (default)

    - `1`

        Force the use of Critical Sections in all cases.

- `SDL_HINT_WINDOWS_FORCE_SEMAPHORE_KERNEL`

    Force SDL to use Kernel Semaphores on Windows. Kernel Semaphores are
    inter-process and require a context switch on every interaction. On Windows 8
    and newer, the WaitOnAddress API is available. Using that and atomics to
    implement semaphores increases performance. SDL will fall back to Kernel
    Objects on older OS versions or if forced to by this hint.

    This variable can be set to the following values:

    - `0`

        Use Atomics and WaitOnAddress API when available. If not, fall back to Kernel
        Objects. (default)

    - `1`

        Force the use of Kernel Objects in all cases.

- `SDL_HINT_WINDOWS_USE_D3D9EX`

    Use the D3D9Ex API introduced in Windows Vista, instead of normal D3D9.
    Direct3D 9Ex contains changes to state management that can eliminate device
    loss errors during scenarios like Alt+Tab or UAC prompts. D3D9Ex may require
    some changes to your application to cope with the new behavior, so this is
    disabled by default.

    This hint must be set before initializing the video subsystem.

    For more information on Direct3D 9Ex, see:

    - [https://docs.microsoft.com/en-us/windows/win32/direct3darticles/graphics-apis-in-windows-vista#direct3d-9ex](https://docs.microsoft.com/en-us/windows/win32/direct3darticles/graphics-apis-in-windows-vista#direct3d-9ex)
    - [https://docs.microsoft.com/en-us/windows/win32/direct3darticles/direct3d-9ex-improvements](https://docs.microsoft.com/en-us/windows/win32/direct3darticles/direct3d-9ex-improvements)

    This variable can be set to the following values:

    - `0`

        Use the original Direct3D 9 API (default)

    - `1`

        Use the Direct3D 9Ex API on Vista and later (and fall back if D3D9Ex is
        unavailable)

- `SDL_HINT_VIDEO_DOUBLE_BUFFER`

    Tell the video driver that we only want a double buffer.

    By default, most lowlevel 2D APIs will use a triple buffer scheme that wastes
    no CPU time on waiting for vsync after issuing a flip, but introduces a frame
    of latency. On the other hand, using a double buffer scheme instead is
    recommended for cases where low latency is an important factor because we save
    a whole frame of latency. We do so by waiting for vsync immediately after
    issuing a flip, usually just after eglSwapBuffers call in the backend's
    \*\_SwapWindow function.

    Since it's driver-specific, it's only supported where possible and implemented.
    Currently supported the following drivers:

    - KMSDRM (kmsdrm)
    - Raspberry Pi (raspberrypi)

- `SDL_HINT_KMSDRM_REQUIRE_DRM_MASTER`

    Determines whether SDL enforces that DRM master is required in order to
    initialize the KMSDRM video backend.

    The DRM subsystem has a concept of a "DRM master" which is a DRM client that
    has the ability to set planes, set cursor, etc. When SDL is DRM master, it can
    draw to the screen using the SDL rendering APIs. Without DRM master, SDL is
    still able to process input and query attributes of attached displays, but it
    cannot change display state or draw to the screen directly.

    In some cases, it can be useful to have the KMSDRM backend even if it cannot be
    used for rendering. An app may want to use SDL for input processing while using
    another rendering API (such as an MMAL overlay on Raspberry Pi) or using its
    own code to render to DRM overlays that SDL doesn't support.

    This hint must be set before initializing the video subsystem.

    This variable can be set to the following values:

    - `0`

        SDL will allow usage of the KMSDRM backend without DRM master

    - `1`

        SDL Will require DRM master to use the KMSDRM backend (default)

- `SDL_HINT_OPENGL_ES_DRIVER`

    A variable controlling what driver to use for OpenGL ES contexts.

    On some platforms, currently Windows and X11, OpenGL drivers may support
    creating contexts with an OpenGL ES profile. By default SDL uses these
    profiles, when available, otherwise it attempts to load an OpenGL ES library,
    e.g. that provided by the ANGLE project. This variable controls whether SDL
    follows this default behaviour or will always load an OpenGL ES library.

    Circumstances where this is useful include

    - - Testing an app with a particular OpenGL ES implementation, e.g ANGLE, or emulator, e.g. those from ARM, Imagination or Qualcomm.
    - Resolving OpenGL ES function addresses at link time by linking with the OpenGL ES library instead of querying them at run time with `SDL_GL_GetProcAddress()`.

    Caution: for an application to work with the default behaviour across different
    OpenGL drivers it must query the OpenGL ES function addresses at run time using
    `SDL_GL_GetProcAddress()`.

    This variable is ignored on most platforms because OpenGL ES is native or not
    supported.

    This variable can be set to the following values:

    - `0`

        Use ES profile of OpenGL, if available. (Default when not set.)

    - `1`

        Load OpenGL ES library using the default library names.

- `SDL_HINT_AUDIO_RESAMPLING_MODE`

    A variable controlling speed/quality tradeoff of audio resampling.

    If available, SDL can use libsamplerate ( http://www.mega-nerd.com/SRC/ ) to
    handle audio resampling. There are different resampling modes available that
    produce different levels of quality, using more CPU.

    If this hint isn't specified to a valid setting, or libsamplerate isn't
    available, SDL will use the default, internal resampling algorithm.

    Note that this is currently only applicable to resampling audio that is being
    written to a device for playback or audio being read from a device for capture.
    SDL\_AudioCVT always uses the default resampler (although this might change for
    SDL 2.1).

    This hint is currently only checked at audio subsystem initialization.

    This variable can be set to the following values:

    - `0` or `default`

        Use SDL's internal resampling (Default when not set - low quality, fast)

    - `1` or `fast`

        Use fast, slightly higher quality resampling, if available

    - `2` or `medium`

        Use medium quality resampling, if available

    - `3` or `best`

        Use high quality resampling, if available

- `SDL_HINT_AUDIO_CATEGORY`

    A variable controlling the audio category on iOS and Mac OS X.

    This variable can be set to the following values:

    - `ambient`

        Use the AVAudioSessionCategoryAmbient audio category, will be muted by the
        phone mute switch (default)

    - `playback`

        Use the AVAudioSessionCategoryPlayback category

    For more information, see Apple's documentation:
    [https://developer.apple.com/library/content/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/AudioSessionCategoriesandModes/AudioSessionCategoriesandModes.html](https://developer.apple.com/library/content/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/AudioSessionCategoriesandModes/AudioSessionCategoriesandModes.html)

- `SDL_HINT_RENDER_BATCHING`

    A variable controlling whether the 2D render API is compatible or efficient.

    This variable can be set to the following values:

    - `0`

        Don't use batching to make rendering more efficient.

    - `1`

        Use batching, but might cause problems if app makes its own direct OpenGL
        calls.

    Up to SDL 2.0.9, the render API would draw immediately when requested. Now it
    batches up draw requests and sends them all to the GPU only when forced to
    (during SDL\_RenderPresent, when changing render targets, by updating a texture
    that the batch needs, etc). This is significantly more efficient, but it can
    cause problems for apps that expect to render on top of the render API's
    output. As such, SDL will disable batching if a specific render backend is
    requested (since this might indicate that the app is planning to use the
    underlying graphics API directly). This hint can be used to explicitly request
    batching in this instance. It is a contract that you will either never use the
    underlying graphics API directly, or if you do, you will call SDL\_RenderFlush()
    before you do so any current batch goes to the GPU before your work begins. Not
    following this contract will result in undefined behavior.

- `SDL_HINT_AUTO_UPDATE_JOYSTICKS`

    A variable controlling whether SDL updates joystick state when getting input
    events

    This variable can be set to the following values:

    - `0`

        You'll call `SDL_JoystickUpdate()` manually

    - `1`

        SDL will automatically call `SDL_JoystickUpdate()` (default)

    This hint can be toggled on and off at runtime.

- `SDL_HINT_AUTO_UPDATE_SENSORS`

    A variable controlling whether SDL updates sensor state when getting input
    events

    This variable can be set to the following values:

    - `0`

        You'll call `SDL_SensorUpdate()` manually

    - `1`

        SDL will automatically call `SDL_SensorUpdate()` (default)

    This hint can be toggled on and off at runtime.

- `SDL_HINT_EVENT_LOGGING`

    A variable controlling whether SDL logs all events pushed onto its internal
    queue.

    This variable can be set to the following values:

    - `0`

        Don't log any events (default)

    - `1`

        Log all events except mouse and finger motion, which are pretty spammy.

    - `2`

        Log all events.

    This is generally meant to be used to debug SDL itself, but can be useful for
    application developers that need better visibility into what is going on in the
    event queue. Logged events are sent through `SDL_Log()`, which means by
    default they appear on stdout on most platforms or maybe `OutputDebugString()`
    on Windows, and can be funneled by the app with `SDL_LogSetOutputFunction()`,
    etc.

    This hint can be toggled on and off at runtime, if you only need to log events
    for a small subset of program execution.

- `SDL_HINT_WAVE_RIFF_CHUNK_SIZE`

    Controls how the size of the RIFF chunk affects the loading of a WAVE file.

    The size of the RIFF chunk (which includes all the sub-chunks of the WAVE file)
    is not always reliable. In case the size is wrong, it's possible to just ignore
    it and step through the chunks until a fixed limit is reached.

    Note that files that have trailing data unrelated to the WAVE file or corrupt
    files may slow down the loading process without a reliable boundary. By
    default, SDL stops after 10000 chunks to prevent wasting time. Use the
    environment variable SDL\_WAVE\_CHUNK\_LIMIT to adjust this value.

    This variable can be set to the following values:

    - `force`

        Always use the RIFF chunk size as a boundary for the chunk search

    - `ignorezero`

        Like "force", but a zero size searches up to 4 GiB (default)

    - `ignore`

        Ignore the RIFF chunk size and always search up to 4 GiB

    - `maximum`

        Search for chunks until the end of file (not recommended)

- `SDL_HINT_WAVE_TRUNCATION`

    Controls how a truncated WAVE file is handled.

    A WAVE file is considered truncated if any of the chunks are incomplete or the
    data chunk size is not a multiple of the block size. By default, SDL decodes
    until the first incomplete block, as most applications seem to do.

    This variable can be set to the following values:

    - `verystrict`

        Raise an error if the file is truncated

    - `strict`

        Like "verystrict", but the size of the RIFF chunk is ignored

    - `dropframe`

        Decode until the first incomplete sample frame

    - `dropblock`

        Decode until the first incomplete block (default)

- `SDL_HINT_WAVE_FACT_CHUNK`

    Controls how the fact chunk affects the loading of a WAVE file.

    The fact chunk stores information about the number of samples of a WAVE file.
    The Standards Update from Microsoft notes that this value can be used to
    'determine the length of the data in seconds'. This is especially useful for
    compressed formats (for which this is a mandatory chunk) if they produce
    multiple sample frames per block and truncating the block is not allowed. The
    fact chunk can exactly specify how many sample frames there should be in this
    case.

    Unfortunately, most application seem to ignore the fact chunk and so SDL
    ignores it by default as well.

    This variable can be set to the following values:

    - `truncate`

        Use the number of samples to truncate the wave data if the fact chunk is
        present and valid

    - `strict`

        Like "truncate", but raise an error if the fact chunk is invalid, not present
        for non-PCM formats, or if the data chunk doesn't have that many samples

    - `ignorezero`

        Like "truncate", but ignore fact chunk if the number of samples is zero

    - `ignore`

        Ignore fact chunk entirely (default)

- `SDL_HINT_DISPLAY_USABLE_BOUNDS`

    Override for `SDL_GetDisplayUsableBounds()`

    If set, this hint will override the expected results for
    `SDL_GetDisplayUsableBounds()` for display index 0. Generally you don't want
    to do this, but this allows an embedded system to request that some of the
    screen be reserved for other uses when paired with a well-behaved application.

    The contents of this hint must be 4 comma-separated integers, the first is the
    bounds x, then y, width and height, in that order.

- `SDL_HINT_AUDIO_DEVICE_APP_NAME`

    Specify an application name for an audio device.

    Some audio backends (such as PulseAudio) allow you to describe your audio
    stream. Among other things, this description might show up in a system control
    panel that lets the user adjust the volume on specific audio streams instead of
    using one giant master volume slider.

    This hints lets you transmit that information to the OS. The contents of this
    hint are used while opening an audio device. You should use a string that
    describes your program ("My Game 2: The Revenge")

    Setting this to "" or leaving it unset will have SDL use a reasonable default:
    probably the application's name or "SDL Application" if SDL doesn't have any
    better information.

    On targets where this is not supported, this hint does nothing.

- `SDL_HINT_AUDIO_DEVICE_STREAM_NAME`

    Specify an application name for an audio device.

    Some audio backends (such as PulseAudio) allow you to describe your audio
    stream. Among other things, this description might show up in a system control
    panel that lets the user adjust the volume on specific audio streams instead of
    using one giant master volume slider.

    This hints lets you transmit that information to the OS. The contents of this
    hint are used while opening an audio device. You should use a string that
    describes your what your program is playing ("audio stream" is probably
    sufficient in many cases, but this could be useful for something like "team
    chat" if you have a headset playing VoIP audio separately).

    Setting this to "" or leaving it unset will have SDL use a reasonable default:
    "audio stream" or something similar.

    On targets where this is not supported, this hint does nothing.

- `SDL_HINT_AUDIO_DEVICE_STREAM_ROLE`

    Specify an application role for an audio device.

    Some audio backends (such as Pipewire) allow you to describe the role of your
    audio stream. Among other things, this description might show up in a system
    control panel or software for displaying and manipulating media
    playback/capture graphs.

    This hints lets you transmit that information to the OS. The contents of this
    hint are used while opening an audio device. You should use a string that
    describes your what your program is playing (Game, Music, Movie, etc...).

    Setting this to "" or leaving it unset will have SDL use a reasonable default:
    "Game" or something similar.

    On targets where this is not supported, this hint does nothing.

- `SDL_HINT_ALLOW_ALT_TAB_WHILE_GRABBED`

    Specify the behavior of Alt+Tab while the keyboard is grabbed.

    By default, SDL emulates Alt+Tab functionality while the keyboard is grabbed
    and your window is full-screen. This prevents the user from getting stuck in
    your application if you've enabled keyboard grab.

    The variable can be set to the following values:

    - `0`

        SDL will not handle Alt+Tab. Your application is responsible for handling
        Alt+Tab while the keyboard is grabbed.

    - `1`

        SDL will minimize your window when Alt+Tab is pressed (default)

- `SDL_HINT_PREFERRED_LOCALES`

    Override for SDL\_GetPreferredLocales()

    If set, this will be favored over anything the OS might report for the user's
    preferred locales. Changing this hint at runtime will not generate a
    SDL\_LOCALECHANGED event (but if you can change the hint, you can push your own
    event, if you want).

    The format of this hint is a comma-separated list of language and locale,
    combined with an underscore, as is a common format: "en\_GB". Locale is
    optional: "en". So you might have a list like this: "en\_GB,jp,es\_PT"

## `:logcategory`

The predefined log categories

By default the application category is enabled at the INFO level, the assert
category is enabled at the WARN level, test is enabled at the VERBOSE level and
all other categories are enabled at the CRITICAL level.

- `SDL_LOG_CATEGORY_APPLICATION`
- `SDL_LOG_CATEGORY_ERROR`
- `SDL_LOG_CATEGORY_ASSERT`
- `SDL_LOG_CATEGORY_SYSTEM`
- `SDL_LOG_CATEGORY_AUDIO`
- `SDL_LOG_CATEGORY_VIDEO`
- `SDL_LOG_CATEGORY_RENDER`
- `SDL_LOG_CATEGORY_INPUT`
- `SDL_LOG_CATEGORY_TEST`
- `SDL_LOG_CATEGORY_RESERVED1`
- `SDL_LOG_CATEGORY_RESERVED2`
- `SDL_LOG_CATEGORY_RESERVED3`
- `SDL_LOG_CATEGORY_RESERVED4`
- `SDL_LOG_CATEGORY_RESERVED5`
- `SDL_LOG_CATEGORY_RESERVED6`
- `SDL_LOG_CATEGORY_RESERVED7`
- `SDL_LOG_CATEGORY_RESERVED8`
- `SDL_LOG_CATEGORY_RESERVED9`
- `SDL_LOG_CATEGORY_RESERVED10`
- `SDL_LOG_CATEGORY_CUSTOM`

## `:logpriority`

The predefined log priorities.

- `SDL_LOG_PRIORITY_VERBOSE`
- `SDL_LOG_PRIORITY_DEBUG`
- `SDL_LOG_PRIORITY_INFO`
- `SDL_LOG_PRIORITY_WARN`
- `SDL_LOG_PRIORITY_ERROR`
- `SDL_LOG_PRIORITY_CRITICAL`
- `SDL_NUM_LOG_PRIORITIES`

## `:windowflags`

The flags on a window.

- `SDL_WINDOW_FULLSCREEN` - Fullscreen window
- `SDL_WINDOW_OPENGL` - Window usable with OpenGL context
- `SDL_WINDOW_SHOWN` - Window is visible
- `SDL_WINDOW_HIDDEN` - Window is not visible
- `SDL_WINDOW_BORDERLESS` - No window decoration
- `SDL_WINDOW_RESIZABLE` - Window can be resized
- `SDL_WINDOW_MINIMIZED` - Window is minimized
- `SDL_WINDOW_MAXIMIZED` - Window is maximized
- `SDL_WINDOW_MOUSE_GRABBED` - Window has grabbed mouse input
- `SDL_WINDOW_INPUT_FOCUS` - Window has input focus
- `SDL_WINDOW_MOUSE_FOCUS` - Window has mouse focus
- `SDL_WINDOW_FULLSCREEN_DESKTOP` - Fullscreen window without frame
- `SDL_WINDOW_FOREIGN` - Window not created by SDL
- `SDL_WINDOW_ALLOW_HIGHDPI` - Window should be created in high-DPI mode if supported.

    On macOS NSHighResolutionCapable must be set true in the application's
    Info.plist for this to have any effect.

- `SDL_WINDOW_MOUSE_CAPTURE` - Window has mouse captured (unrelated to `MOUSE_GRABBED`)
- `SDL_WINDOW_ALWAYS_ON_TOP` - Window should always be above others 
- `SDL_WINDOW_SKIP_TASKBAR` - Window should not be added to the taskbar 
- `SDL_WINDOW_UTILITY` - Window should be treated as a utility window 
- `SDL_WINDOW_TOOLTIP` - Window should be treated as a tooltip 
- `SDL_WINDOW_POPUP_MENU` - Window should be treated as a popup menu 
- `SDL_WINDOW_KEYBOARD_GRABBED` - Window has grabbed keyboard input 
- `SDL_WINDOW_VULKAN` - Window usable for Vulkan surface 
- `SDL_WINDOW_METAL` - Window usable for Metal view
- `SDL_WINDOW_INPUT_GRABBED` - Equivalent to `SDL_WINDOW_MOUSE_GRABBED` for compatibility

## `:windowEventID`

Event subtype for window events.

- `SDL_WINDOWEVENT_NONE` - Never used
- `SDL_WINDOWEVENT_SHOWN` - Window has been shown 
- `SDL_WINDOWEVENT_HIDDEN` - Window has been hidden 
- `SDL_WINDOWEVENT_EXPOSED` - Window has been exposed and should be redrawn
- `SDL_WINDOWEVENT_MOVED` - Window has been moved to data1, data2
- `SDL_WINDOWEVENT_RESIZED` - Window has been resized to data1xdata2 
- `SDL_WINDOWEVENT_SIZE_CHANGED` - The window size has changed, either as a result of an API call or through the system or user changing the window size. 
- `SDL_WINDOWEVENT_MINIMIZED` - Window has been minimized 
- `SDL_WINDOWEVENT_MAXIMIZED` - Window has been maximized 
- `SDL_WINDOWEVENT_RESTORED` - Window has been restored to normal size and position 
- `SDL_WINDOWEVENT_ENTER` - Window has gained mouse focus 
- `SDL_WINDOWEVENT_LEAVE` - Window has lost mouse focus 
- `SDL_WINDOWEVENT_FOCUS_GAINED` - Window has gained keyboard focus
- `SDL_WINDOWEVENT_FOCUS_LOST` - Window has lost keyboard focus
- `SDL_WINDOWEVENT_CLOSE` - The window manager requests that the window be closed
- `SDL_WINDOWEVENT_TAKE_FOCUS` - Window is being offered a focus (should `SetWindowInputFocus()` on itself or a subwindow, or ignore)
- `SDL_WINDOWEVENT_HIT_TEST` - Window had a hit test that wasn't `SDL_HITTEST_NORMAL`.

## `:displayEventID`

Event subtype for display events.

- `SDL_DISPLAYEVENT_NONE` - Never used
- `SDL_DISPLAYEVENT_ORIENTATION` - Display orientation has changed to data1
- `SDL_DISPLAYEVENT_CONNECTED` - Display has been added to the system
- `SDL_DISPLAYEVENT_DISCONNECTED` - Display has been removed from the system

## `:displayOrientation`

- `SDL_ORIENTATION_UNKNOWN` - The display orientation can't be determined
- `SDL_ORIENTATION_LANDSCAPE` - The display is in landscape mode, with the right side up, relative to portrait mode
- `SDL_ORIENTATION_LANDSCAPE_FLIPPED` - The display is in landscape mode, with the left side up, relative to portrait mode
- `SDL_ORIENTATION_PORTRAIT` - The display is in portrait mode
- `SDL_ORIENTATION_PORTRAIT_FLIPPED` - The display is in portrait mode, upside down

## `:glAttr`

OpenGL configuration attributes.

- `SDL_GL_RED_SIZE`
- `SDL_GL_GREEN_SIZE`
- `SDL_GL_BLUE_SIZE`
- `SDL_GL_ALPHA_SIZE`
- `SDL_GL_BUFFER_SIZE`
- `SDL_GL_DOUBLEBUFFER`
- `SDL_GL_DEPTH_SIZE`
- `SDL_GL_STENCIL_SIZE`
- `SDL_GL_ACCUM_RED_SIZE`
- `SDL_GL_ACCUM_GREEN_SIZE`
- `SDL_GL_ACCUM_BLUE_SIZE`
- `SDL_GL_ACCUM_ALPHA_SIZE`
- `SDL_GL_STEREO`
- `SDL_GL_MULTISAMPLEBUFFERS`
- `SDL_GL_MULTISAMPLESAMPLES`
- `SDL_GL_ACCELERATED_VISUAL`
- `SDL_GL_RETAINED_BACKING`
- `SDL_GL_CONTEXT_MAJOR_VERSION`
- `SDL_GL_CONTEXT_MINOR_VERSION`
- `SDL_GL_CONTEXT_EGL`
- `SDL_GL_CONTEXT_FLAGS`
- `SDL_GL_CONTEXT_PROFILE_MASK`
- `SDL_GL_SHARE_WITH_CURRENT_CONTEXT`
- `SDL_GL_FRAMEBUFFER_SRGB_CAPABLE`
- `SDL_GL_CONTEXT_RELEASE_BEHAVIOR`
- `SDL_GL_CONTEXT_RESET_NOTIFICATION`
- `SDL_GL_CONTEXT_NO_ERROR`

## `:glProfile`

- `SDL_GL_CONTEXT_PROFILE_CORE`
- `SDL_GL_CONTEXT_PROFILE_COMPATIBILITY`
- `SDL_GL_CONTEXT_PROFILE_ES`

## `:glContextFlag`

- `SDL_GL_CONTEXT_DEBUG_FLAG`
- `SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG`
- `SDL_GL_CONTEXT_ROBUST_ACCESS_FLAG`
- `SDL_GL_CONTEXT_RESET_ISOLATION_FLAG`

## `:glContextReleaseFlag`

- `SDL_GL_CONTEXT_RELEASE_BEHAVIOR_NONE`
- `SDL_GL_CONTEXT_RELEASE_BEHAVIOR_FLUSH`

## `:glContextResetNotification`

- `SDL_GL_CONTEXT_RESET_NO_NOTIFICATION`
- `SDL_GL_CONTEXT_RESET_LOSE_CONTEXT`

# LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

# AUTHOR

Sanko Robinson <sanko@cpan.org>
