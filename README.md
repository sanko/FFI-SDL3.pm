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
    SDL_Quit();

# DESCRIPTION

SDL2::FFI is an [FFI::Platypus](https://metacpan.org/pod/FFI%3A%3APlatypus) backed bindings to the **S**imple
**D**irectMedia **L**ayer - a cross-platform development library designed to
provide low level access to audio, keyboard, mouse, joystick, and graphics
hardware.

# Initialization and Shutdown

The functions in this category are used to set SDL up for use and generally
have global effects in your program. These functions may be imported with the
`:init` or `:default` tag.

## `SDL_Init( ... )`

Initializes the SDL library. This must be called before using most other SDL
functions.

        SDL_Init( SDL_INIT_TIMER | SDL_INIT_VIDEO | SDL_INIT_EVENTS );

`SDL_Init( ... )` simply forwards to calling [`SDL_InitSubSystem( ...
)`](#sdl_initsubsystem). Therefore, the two may be used
interchangeably. Though for readability of your code [`SDL_InitSubSystem(
... )`](#sdl_initsubsystem) might be preferred.

The file I/O (for example: [`SDL_RWFromFile( ... )`](#sdl_rwfromfile)) and threading ([`SDL_CreateThread( ... )`](#sdl_createthread)) subsystems are initialized by default. Message boxes ( [`SDL_ShowSimpleMessageBox( ... )`](#sdl_showsimplemessagebox) )
also attempt to work without initializing the video subsystem, in hopes of
being useful in showing an error dialog when SDL\_Init fails. You must
specifically initialize other subsystems if you use them in your application.

Logging (such as [`SDL_Log( ... )`](#sdl_log) ) works without
initialization, too.

Expected parameters include:

- `flags` which may be any be imported with the [`:init`](https://metacpan.org/pod/SDL2%3A%3AEnum#init) tag and may be OR'd together

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

        SDL_InitSubSystem( SDL_INIT_TIMER | SDL_INIT_VIDEO | SDL_INIT_EVENTS );

Expected parameters include:

- `flags` which may be any be imported with the [`:init`](https://metacpan.org/pod/SDL2%3A%3AEnum#init) tag and may be OR'd together.

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror) for more information.

## `SDL_Quit( )`

Clean up all initialized subsystems.

        SDL_Quit( );

You should call this function even if you have already shutdown each
initialized subsystem with [`SDL_QuitSubSystem( )`](#sdl_quitsubsystem). It is safe to call this function even in the case of errors in
initialization.

If you start a subsystem using a call to that subsystem's init function (for
example [`SDL_VideoInit( )`](#sdl_videoinit)) instead of [`SDL_Init( ... )`](#sdl_init) or [`SDL_InitSubSystem( ...
)`](#sdl_initsubsystem), then you must use that subsystem's quit
function ([`SDL_VideoQuit( )`](#sdl_videoquit)) to shut it down
before calling `SDL_Quit( )`. But generally, you should not be using those
functions directly anyhow; use [`SDL_Init( ... )`](#sdl_init)
instead.

You can use this function in an `END { ... }` block to ensure that it is run
when your application is shutdown.

## `SDL_QuitSubSystem( ... )`

Shut down specific SDL subsystems.

        SDL_QuitSubSystem( SDL_INIT_VIDEO );

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

- `flags` which may be any be imported with the [`:init`](https://metacpan.org/pod/SDL2%3A%3AEnum#init) tag and may be OR'd together.

## `SDL_WasInit( ... )`

Get a mask of the specified subsystems which are currently initialized.

        SDL_Init( SDL_INIT_VIDEO | SDL_INIT_AUDIO );
        warn SDL_WasInit( SDL_INIT_TIMER ); # false
        warn SDL_WasInit( SDL_INIT_VIDEO ); # true (32 == SDL_INIT_VIDEO)
        my $mask = SDL_WasInit( );
        warn 'video init!'  if ($mask & SDL_INIT_VIDEO); # yep
        warn 'video timer!' if ($mask & SDL_INIT_TIMER); # nope

Expected parameters include:

- `flags` which may be any be imported with the [`:init`](https://metacpan.org/pod/SDL2%3A%3AEnum#init) tag and may be OR'd together.

If `flags` is `0`, it returns a mask of all initialized subsystems, otherwise
it returns the initialization status of the specified subsystems.

The return value does not include `SDL_INIT_NOPARACHUTE`.

# Atomic Operations

**IMPORTANT**:

If you are not an expert in concurrent lockless programming, you should only be
using the atomic lock and reference counting functions in this file. In all
other cases you should be protecting your data structures with full mutexes.

The list of "safe" functions to use are:

- [`SDL_AtomicLock( ... )`](#sdl_atomiclock)
- [`SDL_AtomicUnlock( ... )`](#sdl_atomicunlock)
- [`SDL_AtomicIncRef( ... )`](#sdl_atomicincref)
- [`SDL_AtomicDecRef( ... )`](#sdl_atomicdecref)

**Seriously, here be dragons!**

You can find out a little more about lockless programming and the subtle issues
that can arise here:
[http://msdn.microsoft.com/en-us/library/ee418650%28v=vs.85%29.aspx](http://msdn.microsoft.com/en-us/library/ee418650%28v=vs.85%29.aspx)

There's also lots of good information here:

- [http://www.1024cores.net/home/lock-free-algorithms](http://www.1024cores.net/home/lock-free-algorithms)
- [http://preshing.com/](http://preshing.com/)

These operations may or may not actually be implemented using processor
specific atomic operations. When possible they are implemented as true
processor specific atomic operations. When that is not possible the are
implemented using locks that \*do\* use the available atomic operations.

All of the atomic operations that modify memory are full memory barriers.

## `SDL_SpinLock`

SDL AtomicLock.

The atomic locks are efficient spinlocks using CPU instructions, but are
vulnerable to starvation and can spin forever if a thread holding a lock has
been terminated.  For this reason you should minimize the code executed inside
an atomic lock and never do expensive things like API or system calls while
holding them.

The atomic locks are not safe to lock recursively.

## `SDL_AtomicTryLock( ... )`

Try to lock a spin lock by setting it to a non-zero value.

    SDL_AtomicTryLock( 1 );

**Please note that spinlocks are dangerous if you don't know what you're doing.
Please be careful using any sort of spinlock!**

Expected parameters:

- `lock` - a pointer to a lock variable

Returns `SDL_TRUE` if the lock succeeded, `SDL_FALSE` if the lock is already
held.

## `SDL_AtomicLock( ... )`

Lock a spin lock by setting it to a non-zero value.

    SDL_AtomicLock( 1 );

**Please note that spinlocks are dangerous if you don't know what you're doing.
Please be careful using any sort of spinlock!**

Expected parameters:

- `lock` - a pointer to a lock variable

Returns `SDL_TRUE` if the lock succeeded, `SDL_FALSE` if the lock is already
held.

## `SDL_AtomicUnlock( ... )`

Unlock a spin lock by setting it to `0`.

    SDL_AtomicUnlock( 1 );

**Please note that spinlocks are dangerous if you don't know what you're doing.
Please be careful using any sort of spinlock!**

Expected parameters:

- `lock` - a pointer to a lock variable

Always returns immediately.

# Memory Barriers

Memory barriers are designed to prevent reads and writes from being reordered
by the compiler and being seen out of order on multi-core CPUs.

A typical pattern would be for thread A to write some data and a flag, and for
thread B to read the flag and get the data. In this case you would insert a
release barrier between writing the data and the flag, guaranteeing that the
data write completes no later than the flag is written, and you would insert an
acquire barrier between reading the flag and reading the data, to ensure that
all the reads associated with the flag have completed.

In this pattern you should always see a release barrier paired with an acquire
barrier and you should gate the data reads/writes with a single flag variable.

For more information on these semantics, take a look at the blog post:
[http://preshing.com/20120913/acquire-and-release-semantics](http://preshing.com/20120913/acquire-and-release-semantics)

## `SDL_AtomicCAS( ... )`

Set an atomic variable to a new value if it is currently an old value.

    my $atomic = SDL2::atomic_t->new( { value => 100 } );
    SDL_AtomicCAS( $atomic, 100, 2 );

**Note: If you don't know what this function is for, you shouldn't use it!**

Expected parameters include:

- `a` - a pointer to an [SDL2::atomic\_t](https://metacpan.org/pod/SDL2%3A%3Aatomic_t) to be modified
- `oldval` - the old value
- `newval` - the new value

Returns `SDL_TRUE` if the atomic variable was set, `SDL_FALSE` otherwise.

## `SDL_AtomicSet( ... )`

Set an atomic variable to a value.

    my $atomic = SDL2::atomic_t->new({ value => 1 });
    my $prev = SDL_AtomicSet( $atomic, 100 );

This function also acts as a full memory barrier.

**Note: If you don't know what this function is for, you shouldn't use it!**

Expected parameters include:

- `a` - a pointer to an [SDL2::atomic\_t](https://metacpan.org/pod/SDL2%3A%3Aatomic_t) structure to be modified
- `v` - the desired value

Returns the previous value of the atomic variable.

## `SDL_AtomicGet( ... )`

Get the value of an atomic variable.

    my $atomic = SDL2::atomic_t->new({ value => 1 });
    my $value = SDL_AtomicSet( $atomic );

**Note: If you don't know what this function is for, you shouldn't use it!**

Expected parameters include:

- `a` - a pointer to an [SDL2::atomic\_t](https://metacpan.org/pod/SDL2%3A%3Aatomic_t) variable

Returns the current value of an atomic variable.

## `SDL_AtomicAdd( ... )`

Add to an atomic variable.

    my $atomic = SDL2::atomic_t->new({ value => 1 });
    my $value = SDL_AtomicAdd( $atomic, 4 );

This function also acts as a full memory barrier.

**Note: If you don't know what this function is for, you shouldn't use it!**

- `a` - a pointer to an [SDL2::atomic\_t](https://metacpan.org/pod/SDL2%3A%3Aatomic_t) variable to be modified
- `v` - the desired value to add

Returns the previous value of the atomic variable.

## `SDL_AtomicIncRef( ... )`

Increment an atomic variable.

    my $atomic = SDL2::atomic_t->new({ value => 1 });
    my $value = SDL_AtomicIncRef( $atomic );

Use may be used as a reference counter.

**Note: If you don't know what this function is for, you shouldn't use it!**

- `a` - a pointer to an [SDL2::atomic\_t](https://metacpan.org/pod/SDL2%3A%3Aatomic_t) variable to increment

Returns the previous value of the atomic variable.

## `SDL_AtomicDecRef( ... )`

Decrement an atomic variable.

    my $atomic = SDL2::atomic_t->new({ value => 1 });
    my $ok = SDL_AtomicDecRef( $atomic );

Use may be used as a reference counter.

**Note: If you don't know what this function is for, you shouldn't use it!**

- `a` - a pointer to an [SDL2::atomic\_t](https://metacpan.org/pod/SDL2%3A%3Aatomic_t) variable to decrement

Returns `SDL_TRUE` if the variable reached zero after decrementing,
`SDL_FALSE` otherwise.

# Raw Audio Mixing

These functions provide raw access to the audio mixing buffer for the SDL
library.

## `SDL_AudioCallback`

This function is called when the audio device needs more data.

Parameters to expect include:

- `userdata` - an application-specific parameter saved in the [SDL2::AudioSpec](https://metacpan.org/pod/SDL2%3A%3AAudioSpec) structure.
- `stream` - a pointer to the audio data buffer
- `len` - the length of that buffer in bytes

Once the callback returns, the buffer will no longer be valid. Sterio samples
are stored in a `LRLRLR` ordering.

You may choose to avoid callbacks and use [`SDL_QueueAudio( ...
)`](#sdl_queueaudio) instead, if you like. Just open your audio
device as a NULL callback.

## `SDL_AudioDeviceID`

SDL Audio Device IDs.

A successful call to [`SDL_OpenAudio( ... )`](#sdl_openaudio) is
always device id 1, and legacy SDL audio APIs assume you want this device ID.
[`SDL_OpenAudioDevice( ... )`](#sdl_openaudiodevice) calls
always returns devices >= 2 on success. The legacy calls are good both for
backwards compatibility and when you don't care about multiple, specific, or
capture devices.

## `SDL_GetNumAudioDrivers( )`

Returns the number of audio drivers.

    my $i = SDL_GetNumAudioDrivers( );

## `SDL_GetAudioDriver( ... )`

Returns the list of built in audio drivers, in the order that they were
normally initialized by default.

    for my $i (0 .. SDL_GetNumAudioDrivers() ) {
        CORE::say SDL_GetAudioDriver( $i );
    }

Expected parameters include:

- `index` - index of the desired audio driver

Returns the name of the driver.

## `SDL_AudioInit( ... )`

    SDL_AudioInit( 'alsa' );

This function is used internally, and should not be used unless you have a
specific need to specify the audio driver you want to use. You should normally
use [`SDL_Init( ... )`](#sdl_init) or [`SDL_InitSubSystem(
... )`](#sdl_initsubsystem).

Expected parameters include:

- `driver_name` - name of the driver to initialize

Returns `SDL_TRUE` on success.

## `SDL_AudioQuit( )`

    SDL_AudioQuit( )

This function is used internally, and should not be used unless you have a
specific need to specify the audio driver you want to use.

## `SDL_GetCurrentAudioDriver( )`

Get the name of the current audio driver.

    my $driver = SDL_GetCurrentAudioDriver( );

The returned string points to internal static memory and thus never becomes
invalid, even if you quit the audio subsystem and initialize a new driver
(although such a case would return a different static string from another call
to this function, of course). As such, you should not modify or free the
returned string.

Returns the name of the current audio driver or NULL if no driver has been
initialized.

## `SDL_OpenAudio( ... )`

This function is a legacy means of opening the audio device.

    my $ret = SDL_OpenAudio( $desired, $obtained );

This function remains for compatibility with SDL 1.2, but also because it's
slightly easier to use than the new functions in SDL 2.0. The new, more
powerful, and preferred way to do this is SDL\_OpenAudioDevice().

This function is roughly equivalent to:

    SDL_OpenAudioDevice( (), 0, $desired, $obtained, SDL_AUDIO_ALLOW_ANY_CHANGE );

With two notable exceptions:

- - If \`obtained\` is NULL, we use \`desired\` (and allow no changes), which means desired will be modified to have the correct values for silence, etc, and SDL will convert any differences between your app's specific request and the hardware behind the scenes.
- - The return value is always success or failure, and not a device ID, which means you can only have one device open at a time with this function.

Expected parameters include:

- `desired` - an [SDL2::AudioSpec](https://metacpan.org/pod/SDL2%3A%3AAudioSpec) structure representing the desired output format. Please refer to the SDL\_OpenAudioDevice documentation for details on how to prepare this structure.
- `obtained` - an [SDL2::AudioSpec](https://metacpan.org/pod/SDL2%3A%3AAudioSpec) structure filled in with the actual parameters, or NULL.

This function opens the audio device with the desired parameters, nd returns
`0` if successful, placing the actual hardware parameters in the structure
pointed to by `obtained`.

If `obtained` is NULL, the audio data passed to the callback function will be
guaranteed to be in the requested format, and will be automatically converted
to the actual hardware audio format if necessary. If `obtained` is NULL,
`desired` will have fields modified.

This function returns a negative error code on failure to open the audio device
or failure to set up the audio thread; call `SDL_GetError( )` for more
information.

## `SDL_GetNumAudioDevices( ... )`

Get the number of built-in audio devices.

This function is only valid after successfully initializing the audio
subsystem.

Note that audio capture support is not implemented as of SDL 2.0.4, so the
`iscapture` parameter is for future expansion and should always be zero for
now.

This function will return -1 if an explicit list of devices can't be
determined. Returning -1 is not an error. For example, if SDL is set up to talk
to a remote audio server, it can't list every one available on the Internet,
but it will still allow a specific host to be specified in [`SDL_OpenAudioDevice( ... )`](#sdl_openaudiodevice).

In many common cases, when this function returns a value <= 0, it can still
successfully open the default device (NULL for first argument of [`SDL_OpenAudioDevice( ... )`](#sdl_openaudiodevice)).

This function may trigger a complete redetect of available hardware.

Expected parameters include:

- `iscapture` - zero to request playback devices, non-zero to request recording devices

Returns the number of available devices exposed by the current driver or `-1`
if an explicit list of devices can't be determined. A return value of `-1`
does not necessarily mean an error condition.

## `SDL_GetAudioDeviceName( ... )`

    my $name = SDL_GetAudioDeviceName( 0, 1 );

Get the human-readable name of a specific audio device.

This function is only valid after successfully initializing the audio
subsystem. The values returned by this function reflect the latest call to [`SDL_GetNumAudioDevices( )`](#sdl_getnumaudiodevices); re-call that
function to redetect available hardware.

The string returned by this function is UTF-8 encoded, read-only, and managed
internally. You are not to free it. If you need to keep the string for any
length of time, you should make your own copy of it, as it will be invalid next
time any of several other SDL functions are called.

Expected parameters include:

- `index` - the index of the audio device; valid values range from `0` to `SDL_GetNumAudioDevices( ) - 1`
- `iscapture` - non-zero to query the list of recording devices, zero to query the list of output devices

Returns the name of the audio device at the requested index, or NULL on error.

## `SDL_GetAudioDeviceSpec( ... )`

Get the preferred audio format of a specific audio device.

This function is only valid after a successfully initializing the audio
subsystem. The values returned by this function reflect the latest call to
SDL\_GetNumAudioDevices(); re-call that function to redetect available hardware.

`spec` will be filled with the sample rate, sample format, and channel count.
All other values in the structure are filled with 0. When the supported struct
members are 0, SDL was unable to get the property from the backend.

Expected parameters include:

- `index` - the index of the audio device; valid values range from `0` to `SDL_GetNumAudioDevices() - 1`
- `iscapture` - non-zero to query the list of recording devices, zero to query the list of output devices.
- `spec` - the `SDL2::AudioSpec` to be initialized by this function

Returns `0` on success, nonzero on error.

## `SDL_OpenAudioDevice( ... )`

Open a specific audio device.

`SDL_OpenAudio( ... )`, unlike this function, always acts on device ID 1. As
such, this function will never return a 1 so as not to conflict with the legacy
function.

Please note that SDL 2.0 before 2.0.5 did not support recording; as such, this
function would fail if \`iscapture\` was not zero. Starting with SDL 2.0.5,
recording is implemented and this value can be non-zero.

Passing in a `device` name of NULL requests the most reasonable default (and
is equivalent to what SDL\_OpenAudio() does to choose a device). The `device`
name is a UTF-8 string reported by `SDL_GetAudioDeviceName()`, but some
drivers allow arbitrary and driver-specific strings, such as a hostname/IP
address for a remote audio server, or a filename in the diskaudio driver.

When filling in the desired audio spec structure:

- - `$desired->freq` should be the frequency in sample-frames-per-second (Hz).
- - `$desired->format` should be the audio format (\`AUDIO\_S16SYS\`, etc).
- - `$desired->samples` is the desired size of the audio buffer, in \_sample frames\_ (with stereo output, two samples--left and right--would make a single sample frame).

    This number should be a power of two, and may be adjusted by the audio driver
    to a value more suitable for the hardware.  Good values seem to range between
    512 and 8096 inclusive, depending on the application and CPU speed.  Smaller
    values reduce latency, but can lead to underflow if the application is doing
    heavy processing and cannot fill the audio buffer in time. Note that the number
    of sample frames is directly related to time by the following formula: `ms =
    (sampleframes*1000)/freq`

- - `$desired->size` is the size in \_bytes\_ of the audio buffer, and is
calculated by `SDL_OpenAudioDevice()`. You don't initialize this.
- - `$desired->silence` is the value used to set the buffer to silence, and is calculated by SDL\_OpenAudioDevice(). You don't initialize this.
- - `$desired->callback` should be set to a function that will be called when the audio device is ready for more data.

    It is passed a pointer to the audio buffer, and the length in bytes of the
    audio buffer.

    This function usually runs in a separate thread, and so you should protect data
    structures that it accesses by calling `SDL_LockAudioDevice()` and
    `SDL_UnlockAudioDevice()` in your code. Alternately, you may pass a NULL
    pointer here, and call `SDL_QueueAudio()` with some frequency, to queue more
    audio samples to be played (or for capture devices, call `SDL_DequeueAudio()`
    with some frequency, to obtain audio samples).

- - `$desired->userdata` is passed as the first parameter to your callback function. If you passed a NULL callback, this value is ignored.

`allowed_changes` can have the following flags OR'd together:

- `SDL_AUDIO_ALLOW_FREQUENCY_CHANGE`
- `SDL_AUDIO_ALLOW_FORMAT_CHANGE`
- `SDL_AUDIO_ALLOW_CHANNELS_CHANGE`
- `SDL_AUDIO_ALLOW_ANY_CHANGE`

These flags specify how SDL should behave when a device cannot offer a specific
feature. If the application requests a feature that the hardware doesn't offer,
SDL will always try to get the closest equivalent.

For example, if you ask for float32 audio format, but the sound card only
supports int16, SDL will set the hardware to int16. If you had set
`SDL_AUDIO_ALLOW_FORMAT_CHANGE`, SDL will change the format in the `obtained`
structure. If that flag was \*not\* set, SDL will prepare to convert your
callback's float32 audio to int16 before feeding it to the hardware and will
keep the originally requested format in the `obtained` structure.

If your application can only handle one specific data format, pass a zero for
`allowed_changes` and let SDL transparently handle any differences.

An opened audio device starts out paused, and should be enabled for playing by
calling `SDL_PauseAudioDevice($devid, 0)` when you are ready for your audio
callback function to be called. Since the audio driver may modify the requested
size of the audio buffer, you should allocate any local mixing buffers after
you open the audio device.

The audio callback runs in a separate thread in most cases; you can prevent
race conditions between your callback and other threads without fully pausing
playback with `SDL_LockAudioDevice()`. For more information about the
callback, see [SDL2::AudioSpec](https://metacpan.org/pod/SDL2%3A%3AAudioSpec)

Expected parameters include:

- `device` - a UTF-8 string reported by `SDL_GetAudioDeviceName()` or a driver-specific name as appropriate. NULL requests the most reasonable default device
- `iscapture` - non-zero to specify a device should be opened for recording, not playback
- `desired` - an [SDL2::AudioSpec](https://metacpan.org/pod/SDL2%3A%3AAudioSpec) structure representing the desired output format; see `SDL_OpenAudio()` for more information
- `obtained` - an SDL\_AudioSpec structure filled in with the actual output format; see `SDL_OpenAudio()` for more information
- `allowed_changes` - `0`, or one or more flags OR'd together

Returns a valid device ID that is > 0 on success or 0 on failure; call
`SDL_GetError( )` for more information.

For compatibility with SDL 1.2, this will never return `1`, since SDL reserves
that ID for the legacy `SDL_OpenAudio( )` function.

## `SDL_GetAudioStatus( )`

Get the current audio status for the current device.

    my $status = SDL_GetAudioStatus( );

Returns a [`SDL_AudioStatus`](https://metacpan.org/pod/SDL2%3A%3AEnum#audioStatus) value.

## `SDL_GetAudioDeviceStatus( ... )`

Get the current audio status for the current device.

    my $status = SDL_GetAudioStatus( 4 );

Expected parameters include:

- `dev` - Device id

Returns a [`SDL_AudioStatus`](https://metacpan.org/pod/SDL2%3A%3AEnum#audioStatus) value.

## `SDL_PauseAudio( ... )`

Pause the audio callback processing for the current device.

    SDL_PauseAudio( 1 );

This should be called with a parameter of `0` after opening the audio device
to start playing sound.  This is so you can safely initialize data for your
callback function after opening the audio device. Silence will be written to
the audio device during the pause.

Expected parameters include:

- `pause_on` - a boolean value

## `SDL_PauseAudioDevice( ... )`

Pause the audio callback processing for the given device.

    SDL_PauseAudioDevice( 1 );

This should be called with a parameter of `0` after opening the audio device
to start playing sound.  This is so you can safely initialize data for your
callback function after opening the audio device. Silence will be written to
the audio device during the pause.

Expected parameters include:

- `dev` - a device id
- `pause_on` - a boolean value

## `SDL_LoadWAV_RW( ... )`

Load the audio data of a WAVE file into memory.

    SDL_LoadWAV_RW(SDL_RWFromFile("sample.wav", "rb"), 1, $spec, $buf, $len);

Loading a WAVE file requires `src`, `spec`, `audio_buf` and `audio_len` to
be valid pointers. The entire data portion of the file is then loaded into
memory and decoded if necessary.

If `freesrc` is non-zero, the data source gets automatically closed and freed
before the function returns.

Supported formats are RIFF WAVE files with the formats PCM (8, 16, 24, and 32
bits), IEEE Float (32 bits), Microsoft ADPCM and IMA ADPCM (4 bits), and A-law
and mu-law (8 bits). Other formats are currently unsupported and cause an
error.

If this function succeeds, the pointer returned by it is equal to `spec` and
the pointer to the audio data allocated by the function is written to
`audio_buf` and its length in bytes to `audio_len`. The [SDL2::AudioSpec](https://metacpan.org/pod/SDL2%3A%3AAudioSpec)
members `freq`, `channels`, and `format` are set to the values of the audio
data in the buffer. The `samples` member is set to a sane default and all
others are set to zero.

It's necessary to use `SDL_FreeWAV( )` to free the audio data returned in
`audio_buf` when it is no longer used.

Because of the specification of the .WAV format, there are many problematic
files in the wild that cause issues with strict decoders. To provide
compatibility with these files, this decoder is lenient in regards to the
truncation of the file, the fact chunk, and the size of the RIFF chunk. The
hints `SDL_HINT_WAVE_RIFF_CHUNK_SIZE`, `SDL_HINT_WAVE_TRUNCATION`, and
`SDL_HINT_WAVE_FACT_CHUNK` can be used to tune the behavior of the loading
process.

Any file that is invalid (due to truncation, corruption, or wrong values in the
headers), too big, or unsupported causes an error. Additionally, any critical
I/O error from the data source will terminate the loading process with an
error. The function returns NULL on error and in all cases (with the exception
of \`src\` being NULL), an appropriate error message will be set.

It is required that the data source supports seeking.

Note that the `SDL_LoadWAV( ... )` macro does this same thing for you, but in
a less messy way:

    SDL_LoadWAV("sample.wav", $spec, $buf, $len);

Expected parameters include:

- `src` - The data source for the WAVE data
- `freesrc` - If non-zero, SDL will \_always\_ free the data source
- `spec` - An [SDL2::AudioSpec](https://metacpan.org/pod/SDL2%3A%3AAudioSpec) that will be filled in with the wave file's format details
- `audio_buf` - A pointer filled with the audio data, allocated by the function
- `audio_len` - A pointer filled with the length of the audio data buffer in bytes

This function, if successfully called, returns `spec`, which will be filled
with the audio data format of the wave source data. `audio_buf` will be filled
with a pointer to an allocated buffer containing the audio data, and
`audio_len` is filled with the length of that audio buffer in bytes.

This function returns NULL if the .WAV file cannot be opened, uses an unknown
data format, or is corrupt; call `SDL_GetError( )` for more information.

When the application is done with the data returned in `audio_buf`, it should
call `SDL_FreeWAV( )` to dispose of it.

## `SDL_LoadWAV( ... )`

Loads a WAV from a file.

    SDL_LoadWAV("sample.wav", $spec, $buf, $len);

Expected parameters include:

- `src` - The data source for the WAVE data
- `spec` - An [SDL2::AudioSpec](https://metacpan.org/pod/SDL2%3A%3AAudioSpec) that will be filled in with the wave file's format details
- `audio_buf` - A pointer filled with the audio data, allocated by the function
- `audio_len` - A pointer filled with the length of the audio data buffer in bytes

This is a wrapper for [`SDL_LoadWAV_RW( ... )`](#sdl_loadwav_rw)
and returns the same data.

## `SDL_FreeWAV( ... )`

Free data previously allocated with [`SDL_LoadWAV( ... )`](#sdl_loadwav) or [`SDL_LoadWAV_RW( ... )`](#sdl_loadwav_rw).

    SDL_FreeWAV( $data );

After a WAVE file has been opened with [`SDL_LoadWAV( ...
)`](#sdl_loadwav) or [`SDL_LoadWAV_RW( ... )`](#sdl_loadwav_rw), its data can eventually be freed with `SDL_FreeWAV( ... )`. It is
safe to call this function with a NULL pointer.

Expected parameters include:

- `audio_buf` - a pointer to the buffer created by [`SDL_LoadWAV( ... )`](#sdl_loadwav) or [`SDL_LoadWAV_RW( ... )`](#sdl_loadwav_rw)

## `SDL_BuildAudioCVT( ... )`

Initialize an [SDL2::AudioCVT](https://metacpan.org/pod/SDL2%3A%3AAudioCVT) structure for conversion.

Before an [SDL2::AudioCVT](https://metacpan.org/pod/SDL2%3A%3AAudioCVT) structure can be used to convert audio data it must
be initialized with source and destination information.

This function will zero out every field of the [SDL2::AudioCVT](https://metacpan.org/pod/SDL2%3A%3AAudioCVT), so it must be
called before the application fills in the final buffer information.

Once this function has returned successfully, and reported that a conversion is
necessary, the application fills in the rest of the fields in
[SDL2::AudioCVT](https://metacpan.org/pod/SDL2%3A%3AAudioCVT), now that it knows how large a buffer it needs to allocate,
and then can call `SDL_ConvertAudio( ... )` to complete the conversion.

Expected parameters include:

- `cvt` - an [SDL2::AudioCVT](https://metacpan.org/pod/SDL2%3A%3AAudioCVT) structure filled in with audio conversion information
- `src_format` - the source format of the audio data; for more info see [SDL2::AudioFormat](https://metacpan.org/pod/SDL2%3A%3AAudioFormat)
- `src_channels` - the number of channels in the source
- `src_rate` - the frequency (sample-frames-per-second) of the source
- `dst_format` - the destination format of the audio data; for more info see [SDL2::AudioFormat](https://metacpan.org/pod/SDL2%3A%3AAudioFormat)
- `dst_channels` the number of channels in the destination
- `dst_rate` - the frequency (sample-frames-per-second) of the destination

Returns `1` if the audio filter is prepared, `0` if no conversion is needed,
or a negative error code on failure; call [`SDL_GetError(
)`](#sdl_geterror) for more information.

## `SDL_ConvertAudio( ... )`

Convert audio data to a desired audio format.

This function does the actual audio data conversion, after the application has
called `SDL_BuildAudioCVT( )` to prepare the conversion information and then
filled in the buffer details.

Once the application has initialized the `cvt` structure using
`SDL_BuildAudioCVT( )`, allocated an audio buffer and filled it with audio
data in the source format, this function will convert the buffer, in-place, to
the desired format.

The data conversion may go through several passes; any given pass may possibly
temporarily increase the size of the data. For example, SDL might expand 16-bit
data to 32 bits before resampling to a lower frequency, shrinking the data size
after having grown it briefly. Since the supplied buffer will be both the
source and destination, converting as necessary in-place, the application must
allocate a buffer that will fully contain the data during its largest
conversion pass. After `SDL_BuildAudioCVT( )` returns, the application should
set the `cvt->len` field to the size, in bytes, of the source data, and
allocate a buffer that is `cvt->len * cvt->len_mult` bytes long for the
`buf` field.

The source data should be copied into this buffer before the call to
`SDL_ConvertAudio( )`. Upon successful return, this buffer will contain the
converted audio, and `cvt->len_cvt` will be the size of the converted
data, in bytes. Any bytes in the buffer past \`cvt->len\_cvt\` are undefined once
this function returns.

- `cvt` - an [SDL2::AudioCVT](https://metacpan.org/pod/SDL2%3A%3AAudioCVT) structure that was previously set up by `SDL_BuildAudioCVT( )`

Returns `0` if the conversion was completed successfully or a negative error
code on failure; call [`SDL_GetError( )`](#sdl_geterror) for more
information.

## `SDL_NewAudioStream( ... )`

Create a new audio stream.

Expected parameters include:

- `src_format` - The format of the source audio
- `src_channels` - The number of channels of the source audio
- `src_rate` - The sampling rate of the source audio
- `dst_format` - The format of the desired audio output
- `dst_channels` - The number of channels of the desired audio output
- `dst_rate` - The sampling rate of the desired audio output

Returns `0` on success, or `-1` on error.

## `SDL_AudioStreamPut( ... )`

Add data to be converted/resampled to the stream.

Expected parameters include:

- `stream` - The stream the audio data is being added to
- `buf` - A pointer to the audio data to add
- `len` - The number of bytes to write to the stream

Returns `0` on success, or `-1` on error.

## `SDL_AudioStreamGet( ... )`

Get converted/resampled data from the stream.

Expected parameters include:

- `stream` - The stream the audio is being requested from
- `buf` - A buffer to fill with audio data
- `len` - The maximum number of bytes to fill

Returns the number of bytes read from the stream, or `-1` on error.

## `SDL_AudioStreamAvailable( ... )`

Get the number of converted/resampled bytes available.

    my $samples = SDL_AudioStreamAvailable( $stream );

The stream may be buffering data behind the scenes until it has enough to
resample correctly, so this number might be lower than what you expect, or even
be zero. Add more data or flush the stream if you need the data now.

Expected parameters include:

- `stream` - The stream being queried

Returns the number of samples.

## `SDL_AudioStreamFlush( ... )`

Tell the stream that you're done sending data, and anything being buffered
should be converted/resampled and made available immediately.

It is legal to add more data to a stream after flushing, but there will be
audio gaps in the output. Generally this is intended to signal the end of
input, so the complete output becomes available.

Expected parameters include:

- `stream` - An [SDL2::AudioStream](https://metacpan.org/pod/SDL2%3A%3AAudioStream)

Returns the number of samples.

## `SDL_AudioStreamClear( ... )`

Clear any pending data in the stream without converting it.

Expected parameters include:

- `stream` - The stream being cleared

## `SDL_FreeAudioStream( ... )`

Free an audio stream.

Expected parameters include:

- `stream` - The stream being freed

## `SDL_MixAudio( ... )`

This function is a legacy means of mixing audio.

This function is equivalent to calling

    SDL_MixAudioFormat( $dst, $src, $format, $len, $volume );

where `format` is the obtained format of the audio device from the legacy
`SDL_OpenAudio( ... )` function.

Expected parameters include:

- `dst` - the destination for the mixed audio
- `src` - the source audio buffer to be mixed
- `len` - the length of the audio buffer in bytes
- `volume` - ranges from `0 - 128`, and should be set to `SDL_MIX_MAXVOLUME` for full audio volume

## `SDL_MixAudioFormat( ... )`

Mix audio data in a specified format.

This takes an audio buffer `src` of `len` bytes of `format` data and mixes
it into `dst`, performing addition, volume adjustment, and overflow clipping.
The buffer pointed to by `dst` must also be `len` bytes of `format` data.

This is provided for convenience -- you can mix your own audio data.

Do not use this function for mixing together more than two streams of sample
data. The output from repeated application of this function may be distorted by
clipping, because there is no accumulator with greater range than the input
(not to mention this being an inefficient way of doing it).

It is a common misconception that this function is required to write audio data
to an output stream in an audio callback. While you can do that,
`SDL_MixAudioFormat( ... )` is really only needed when you're mixing a single
audio stream with a volume adjustment.

Expected parameters include:

- `dst` - the destination for the mixed audio
- `src` - the source audio buffer to be mixed
- `format` - the SDL\_AudioFormat structure representing the desired audio format
- `len` - the length of the audio buffer in bytes
- `volume` - ranges from `0 - 128`, and should be set to `SDL_MIX_MAXVOLUME` for full audio volume

## `SDL_QueueAudio( ... )`

Queue more audio on non-callback devices.

If you are looking to retrieve queued audio from a non-callback capture device,
you want `SDL_DequeueAudio( ... )` instead. `SDL_QueueAudio( ... )` will
return `-1` to signify an error if you use it with capture devices.

SDL offers two ways to feed audio to the device: you can either supply a
callback that SDL triggers with some frequency to obtain more audio (pull
method), or you can supply no callback, and then SDL will expect you to supply
data at regular intervals (push method) with this function.

There are no limits on the amount of data you can queue, short of exhaustion of
address space. Queued data will drain to the device as necessary without
further intervention from you. If the device needs audio but there is not
enough queued, it will play silence to make up the difference. This means you
will have skips in your audio playback if you aren't routinely queueing
sufficient data.

This function copies the supplied data, so you are safe to free it when the
function returns. This function is thread-safe, but queueing to the same device
from two threads at once does not promise which buffer will be queued first.

You may not queue audio on a device that is using an application-supplied
callback; doing so returns an error. You have to use the audio callback or
queue audio with this function, but not both.

You should not call `SDL_LockAudio( ... )` on the device before queueing; SDL
handles locking internally for this function.

Expected parameters include:

- `dev` - the device ID to which we will queue audio
- `data` - the data to queue to the device for later playback
- `len` - the number of bytes (not samples!) to which `data` points

Returns `0` on success or a negative error code on failure; call
`SDL_GetError( )` for more information.

## `SDL_DequeueAudio( ... )`

Dequeue more audio on non-callback devices.

If you are looking to queue audio for output on a non-callback playback device,
you want `SDL_QueueAudio( ... )` instead. `SDL_DequeueAudio( ... )` will
always return `0` if you use it with playback devices.

SDL offers two ways to retrieve audio from a capture device: you can either
supply a callback that SDL triggers with some frequency as the device records
more audio data, (push method), or you can supply no callback, and then SDL
will expect you to retrieve data at regular intervals (pull method) with this
function.

There are no limits on the amount of data you can queue, short of exhaustion of
address space. Data from the device will keep queuing as necessary without
further intervention from you. This means you will eventually run out of memory
if you aren't routinely dequeueing data.

Capture devices will not queue data when paused; if you are expecting to not
need captured audio for some length of time, use `SDL_PauseAudioDevice( )` to
stop the capture device from queueing more data. This can be useful during,
say, level loading times. When unpaused, capture devices will start queueing
data from that point, having flushed any capturable data available while
paused.

This function is thread-safe, but dequeueing from the same device from two
threads at once does not promise which thread will dequeue data first.

You may not dequeue audio from a device that is using an application-supplied
callback; doing so returns an error. You have to use the audio callback, or
dequeue audio with this function, but not both.

You should not call `SDL_LockAudio( ... )` on the device before dequeueing;
SDL handles locking internally for this function.

Expected parameters include:

- `dev` - the device ID from which we will dequeue audio
- `data` - a pointer into where audio data should be copied
- `len` - the number of bytes (not samples!) to which (data) points

Returns the number of bytes dequeued, which could be less than requested; call
`SDL_GetError( )` for more information.

## `SDL_GetQueuedAudioSize( ... )`

Get the number of bytes of still-queued audio.

For playback devices: this is the number of bytes that have been queued for
playback with `SDL_QueueAudio( )`, but have not yet been sent to the hardware.

Once we've sent it to the hardware, this function can not decide the exact byte
boundary of what has been played. It's possible that we just gave the hardware
several kilobytes right before you called this function, but it hasn't played
any of it yet, or maybe half of it, etc.

For capture devices, this is the number of bytes that have been captured by the
device and are waiting for you to dequeue. This number may grow at any time, so
this only informs of the lower-bound of available data.

You may not queue or dequeue audio on a device that is using an
application-supplied callback; calling this function on such a device always
returns `0`. You have to use the audio callback or queue audio, but not both.

You should not call `SDL_LockAudio( )` on the device before querying; SDL
handles locking internally for this function.

Expected parameters:

- `dev` - the device ID of which we will query queued audio size

Returns the number of bytes (not samples!) of queued audio.

## `SDL_ClearQueuedAudio( ... )`

Drop any queued audio data waiting to be sent to the hardware.

Immediately after this call, `SDL_GetQueuedAudioSize( )` will return `0`. For
output devices, the hardware will start playing silence if more audio isn't
queued. For capture devices, the hardware will start filling the empty queue
with new data if the capture device isn't paused.

This will not prevent playback of queued audio that's already been sent to the
hardware, as we can not undo that, so expect there to be some fraction of a
second of audio that might still be heard. This can be useful if you want to,
say, drop any pending music or any unprocessed microphone input during a level
change in your game.

You may not queue or dequeue audio on a device that is using an
application-supplied callback; calling this function on such a device always
returns 0. You have to use the audio callback or queue audio, but not both.

You should not call `SDL_LockAudio( )` on the device before clearing the
queue; SDL handles locking internally for this function.

Expected parameters include:

- `dev` - the device ID of which to clear the audio queue

This function always succeeds and thus returns void.

## `SDL_CloseAudio( )`

## `SDL_CloseAudioDevice( ... )`

Expected parameters include:

- `dev` - device id

# Audio lock functions

The lock manipulated by these functions protects the callback function. During
a [`SDL_LockAudio( )`](#sdl_lockaudio)/[<SDL\_UnlockAudio(
)>](#sdl_unlockaudio) pair, you can be guaranteed that the callback
function is not running. Do not call these from the callback function or you
will cause deadlock.

## `SDL_LockAudio( )`

## `SDL_LockAudioDevice( ... )`

Expected parameters include:

- `dev` - device id

## `SDL_UnlockAudio( )`

## `SDL_UnlockAudioDevice( ... )`

Expected parameters include:

- `dev` - device id

# Blend mode for renderers

The functions `SDL_SetRenderDrawBlendMode( ... )` and
`SDL_SetTextureBlendMode( ... )` accept the [SDL2::BlendMode](https://metacpan.org/pod/SDL2%3A%3ABlendMode) returned by
this function if the renderer supports it.

## `SDL_ComposeCustomBlendMode( ... )`

Compose a custom blend mode for renderers.

A blend mode controls how the pixels from a drawing operation (source) get
combined with the pixels from the render target (destination). First, the
components of the source and destination pixels get multiplied with their blend
factors. Then, the blend operation takes the two products and calculates the
result that will get stored in the render target.

Expressed in pseudocode, it would look like this:

    $dstRGB = colorOperation( $srcRGB * $srcColorFactor, $dstRGB * $dstColorFactor );
    $dstA   = alphaOperation( $srcA * $srcAlphaFactor, $dstA * $dstAlphaFactor );

Where the functions `colorOperation( $src, $dst)` and `alphaOperation( $src,
$dst )` can return one of the following:

- - `$src + $dst`
- - `$src - $dst`
- - `$dst - $src`
- - `min($src, $dst)`
- - `max($src, $dst)`

The red, green, and blue components are always multiplied with the first,
second, and third components of the `SDL_BlendFactor`, respectively. The
fourth component is not used.

The alpha component is always multiplied with the fourth component of the
`SDL_BlendFactor`. The other components are not used in the alpha calculation.

Support for these blend modes varies for each renderer. To check if a specific
`SDL_BlendMode` is supported, create a renderer and pass it to either
`SDL_SetRenderDrawBlendMode` or `SDL_SetTextureBlendMode`. They will return
with an error if the blend mode is not supported.

This list describes the support of custom blend modes for each renderer in SDL
2.0.6. All renderers support the four blend modes listed in the
`SDL_BlendMode` enumeration.

- **direct3d**: Supports `SDL_BLENDOPERATION_ADD` with all factors.
- **direct3d11**: Supports all operations with all factors. However, some factors produce unexpected results with `SDL_BLENDOPERATION_MINIMUM` and `SDL_BLENDOPERATION_MAXIMUM`.
- **opengl**: Supports the `SDL_BLENDOPERATION_ADD` operation with all factors. OpenGL versions 1.1, 1.2, and 1.3 do not work correctly with SDL 2.0.6.
- **opengles**: Supports the `SDL_BLENDOPERATION_ADD` operation with all factors. Color and alpha factors need to be the same. OpenGL ES 1 implementation specific: May also support `SDL_BLENDOPERATION_SUBTRACT` and `SDL_BLENDOPERATION_REV_SUBTRACT`. May support color and alpha operations being different from each other. May support color and alpha factors being different from each other.
- **opengles2**: Supports the `SDL_BLENDOPERATION_ADD`, `SDL_BLENDOPERATION_SUBTRACT`, `SDL_BLENDOPERATION_REV_SUBTRACT` operations with all factors.
- **psp**: No custom blend mode support.
- **software**: No custom blend mode support.

Some renderers do not provide an alpha component for the default render target.
The `SDL_BLENDFACTOR_DST_ALPHA` and `SDL_BLENDFACTOR_ONE_MINUS_DST_ALPHA`
factors do not have an effect in this case.

Expected parameters include:

- `srcColorFactor` - the SDL\_BlendFactor applied to the red, green, and blue components of the source pixels
- `dstColorFactor` - the SDL\_BlendFactor applied to the red, green, and blue components of the destination pixels
- `colorOperation` - the SDL\_BlendOperation used to combine the red, green, and blue components of the source and destination pixels
- `srcAlphaFactor` - the `SDL_BlendFactor` applied to the alpha component of the source pixels
- `dstAlphaFactor` - the `SDL_BlendFactor` applied to the alpha component of the destination pixels
- `alphaOperation` - the `SDL_BlendOperation` used to combine the alpha component of the source and destination pixels

Returns an `SDL_BlendMode` that represents the chosen factors and operations.

# Clipboard

Functions in this section expose the clipboard. SDL's video subsystem must be
initialized to get or modify clipboard text.

## `SDL_SetClipboardText( ... )`

Put UTF-8 text into the clipboard.

    SDL_SetClipboardText( 'Hello, world!' );

- `text` - the text to store in the clipboard

Returns `0` on success or a negative error code on failure; call
`SDL_GetError( )` for more information.

## `SDL_GetClipboardText( )`

Get UTF-8 text from the clipboard, which must be freed with `SDL_free( )`.

    my $clipboard = SDL_GetClipboardText( );

This functions returns NULL if there was not enough memory left for a copy of
the clipboard's content.

Returns the clipboard text on success or NULL on failure; call `SDL_GetError(
)` for more information. Caller must call `SDL_free( )` on the returned
pointer when done with it.

## `SDL_HasClipboardText( )`

Query whether the clipboard exists and contains a non-empty text string.

    if ( SDL_HasClipboardText( ) ) {
        ...
    }

Returns `SDL_TRUE` if the clipboard has text, or `SDL_FALSE` if it does not.

# CPU Feature Detection

These functions may be imported with the `:cpuinfo` tag.

## `SDL_GetCPUCount( )`

Get the number of CPU cores available.

    my $cores = SDL_GetCPUCount( );

Returns the total number of logical CPU cores. On CPUs that include
technologies such as hyperthreading, the number of logical cores may be more
than the number of physical cores.

## `SDL_GetCPUCacheLineSize( )`

Determine the L1 cache line size of the CPU.

    my $cache = SDL_GetCPUCacheLineSize( );

This is useful for determining multi-threaded structure padding or SIMD
prefetch sizes.

Returns the L1 cache line size of the CPU, in bytes.

## `SDL_HasRDTSC( )`

Determine whether the CPU has the RDTSC instruction.

    my $rdtsc = SDL_HasRDTSC( );

This always returns false on CPUs that aren't using Intel instruction sets.

Returns `SDL_TRUE` if the CPU has the RDTSC instruction or `SDL_FALSE` if
not.

## `SDL_HasAltiVec( )`

Determine whether the CPU has AltiVec features.

    my $altiVec = SDL_HasAltiVec( );

This always returns false on CPUs that aren't using PowerPC instruction sets.

Returns `SDL_TRUE` if the CPU has AltiVec features or `SDL_FALSE` if not.

## `SDL_HasMMX( )`

Determine whether the CPU has MMX features.

    my $mmx = SDL_HasMMX( );

This always returns false on CPUs that aren't using Intel instruction sets.

Returns `SDL_TRUE` if the CPU has MMX features or `SDL_FALSE` if not.

## `SDL_Has3DNow( )`

Determine whether the CPU has 3DNow! features.

    my $_3dnow = SDL_Has3DNow( );

This always returns false on CPUs that aren't using AMD instruction sets.

Returns `SDL_TRUE` if the CPU has 3DNow! features or `SDL_FALSE` if not.

## `SDL_HasSSE( )`

Determine whether the CPU has SSE features.

    my $sse = SDL_HasSSE( );

This always returns false on CPUs that aren't using Intel instruction sets.

Returns `SDL_TRUE` if the CPU has SSE features or `SDL_FALSE` if not.

## `SDL_HasSSE2( )`

Determine whether the CPU has SSE2 features.

    my $sse2 = SDL_HasSSE2( );

This always returns false on CPUs that aren't using Intel instruction sets.

Returns `SDL_TRUE` if the CPU has SSE2 features or `SDL_FALSE` if not.

## `SDL_HasSSE3( )`

Determine whether the CPU has SSE3 features.

    my $sse3 = SDL_HasSSE3( );

This always returns false on CPUs that aren't using Intel instruction sets.

Returns `SDL_TRUE` if the CPU has SSE3 features or `SDL_FALSE` if not.

## `SDL_HasSSE41( )`

Determine whether the CPU has SSE4.1 features.

    my $sse41 = SDL_HasSSE41( );

This always returns false on CPUs that aren't using Intel instruction sets.

Returns `SDL_TRUE` if the CPU has SSE4.1 features or `SDL_FALSE` if not.

## `SDL_HasSSE42( )`

Determine whether the CPU has SSE4.2 features.

    my $sse42 = SDL_HasSSE42( );

This always returns false on CPUs that aren't using Intel instruction sets.

Returns `SDL_TRUE` if the CPU has SSE4.2 features or `SDL_FALSE` if not.

## `SDL_HasAVX( )`

Determine whether the CPU has AVX features.

    my $avx = SDL_HasAVX( );

This always returns false on CPUs that aren't using Intel instruction sets.

Returns `SDL_TRUE` if the CPU has AVX features or `SDL_FALSE` if not.

## `SDL_HasAVX2( )`

Determine whether the CPU has AVX2 features.

    my $avx2 = SDL_HasAVX2( );

This always returns false on CPUs that aren't using Intel instruction sets.

Returns `SDL_TRUE` if the CPU has AVX2 features or `SDL_FALSE` if not.

## `SDL_HasAVX512F( )`

Determine whether the CPU has AVX-512F (foundation) features.

    my $avx512 = SDL_HasAVX512F( );

This always returns false on CPUs that aren't using Intel instruction sets.

Returns `SDL_TRUE` if the CPU has AVX-512F features or `SDL_FALSE` if not.

## `SDL_HasARMSIMD( )`

Determine whether the CPU has ARM SIMD (ARMv6) features.

    my $arm6 = SDL_HasARMSIMD( );

This is different from ARM NEON, which is a different instruction set.

This always returns false on CPUs that aren't using ARM instruction sets.

Returns `SDL_TRUE` if the CPU has ARM SIMD features or `SDL_FALSE` if not.

## `SDL_HasNEON( )`

Determine whether the CPU has NEON (ARM SIMD) features.

    my $neon = SDL_HasNEON( );

This always returns false on CPUs that aren't using ARM instruction sets.

Returns `SDL_TRUE` if the CPU has ARM NEON features or `SDL_FALSE` if not.

## `SDL_GetSystemRAM( )`

Get the amount of RAM configured in the system.

    my $mb = SDL_GetSystemRAM( );

Returns the amount of RAM configured in the system in MB.

## `SDL_SIMDGetAlignment( )`

Report the alignment this system needs for SIMD allocations.

    my $size = SDL_SIMDGetAlignment( );

This will return the minimum number of bytes to which a pointer must be aligned
to be compatible with SIMD instructions on the current machine. For example, if
the machine supports SSE only, it will return 16, but if it supports AVX-512F,
it'll return 64 (etc). This only reports values for instruction sets SDL knows
about, so if your SDL build doesn't have [`SDL_HasAVX512F(
)`](#sdl_hasavx512f), then it might return 16 for the SSE support it
sees and not 64 for the AVX-512 instructions that exist but SDL doesn't know
about. Plan accordingly.

Returns alignment in bytes needed for available, known SIMD instructions.

## `SDL_SIMDAlloc( ... )`

Allocate memory in a SIMD-friendly way.

    my $ptr = SDL_SIMDAlloc( 1024 * 64 );

This will allocate a block of memory that is suitable for use with SIMD
instructions. Specifically, it will be properly aligned and padded for the
system's supported vector instructions.

The memory returned will be padded such that it is safe to read or write an
incomplete vector at the end of the memory block. This can be useful so you
don't have to drop back to a scalar fallback at the end of your SIMD processing
loop to deal with the final elements without overflowing the allocated buffer.

You must free this memory with [`SDL_FreeSIMD( )`](#sdl_freesimd),
not [`SDL_free( ... )`](#sdl_free) `undef`, variable scope
tricks, etc.

Note that SDL will only deal with SIMD instruction sets it is aware of; for
example, SDL 2.0.8 knows that SSE wants 16-byte vectors ([`SDL_HasSSE(
)`](#sdl_hassse)), and AVX2 wants 32 bytes ([`SDL_HasAVX2(
)`](#sdl_hasavx2)), but doesn't know that AVX-512 wants 64. To be clear:
if you can't decide to use an instruction set with an `SDL_Has*( )` function,
don't use that instruction set with memory allocated through here.

`SDL_AllocSIMD( 0 )` will return a non-NULL pointer, assuming the system isn't
out of memory, but you are not allowed to dereference it (because you only own
zero bytes of that buffer).

Expected parameters include:

- `len` - The length, in bytes, of the block to allocate. The actual allocated block might be larger due to padding, etc.

Returns a pointer to newly-allocated block, NULL if out of memory.

## `SDL_SIMDRealloc( ... )`

Reallocate memory obtained from [`SDL_SIMDAlloc( ... )`](#sdl_simdalloc).

    $ptr = SDL_SIMDRealloc( $ptr, 1024 * 32 );

It is not valid to use this function on a pointer from anything but [`SDL_SIMDAlloc( ... )`](#sdl_simdalloc). It can't be used on
pointers from malloc, realloc, SDL\_malloc, memalign, new, etc.

Expected parameters include:

- `mem` - The pointer obtained from [`SDL_SIMDAlloc( ... )`](#sdl_simdalloc). This function also accepts NULL, at which point this function is the same as calling [`SDL_SIMDAlloc( ... )`](#sdl_simdalloc) with a NULL pointer.
- `len` - The length, in bytes, of the block to allocated. The actual allocated block might be larger due to padding, etc. Passing `0` will return a non-NULL pointer, assuming the system isn't out of memory.

Returns a pointer to newly-reallocated block, NULL if out of memory.

## `SDL_SIMDFree( )`

Deallocate memory obtained from [`SDL_SIMDAlloc( ... )`](#sdl_simdalloc).

    SDL_SIMDFree( $ptr );

It is not valid to use this function on a pointer from anything but [`SDL_SIMDAlloc( ... )`](#sdl_simdalloc) or [`SDL_SIMDRealloc(
... )`](#sdl_simdrealloc). It can't be used on pointers from malloc,
realloc, SDL\_malloc, memalign, new, etc.

However, `SDL_SIMDFree( undef )` is a legal no-op.

The memory pointed to by `ptr` is no longer valid for access upon return, and
may be returned to the system or reused by a future allocation. The pointer
passed to this function is no longer safe to dereference once this function
returns, and should be discarded.

Expected parameters include:

- `ptr` - The pointer, returned from [`SDL_SIMDAlloc( ... )`](#sdl_simdalloc) or [`SDL_SIMDRealloc( ... )`](#sdl_simdrealloc), to deallocate. NULL is a legal no-op.

# Error Handling

Functions in this category provide simple error message routines for SDL. [`SDL_GetError( )`](#sdl_geterror) can be called for almost all SDL
functions to determine what problems are occurring. Check the wiki page of each
specific SDL function to see whether [`SDL_GetError( )`](#sdl_geterror) is meaningful for them or not. These functions may be imported with the
`:error` tag.

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

    a `printf( )`-style message format string

- `@params`

    additional parameters matching % tokens in the `fmt` string, if any

## `SDL_GetError( )`

Retrieve a message about the last error that occurred on the current thread.

        warn SDL_GetError( );

It is possible for multiple errors to occur before calling `SDL_GetError( )`.
Only the last error is returned.

The message is only applicable when an SDL function has signaled an error. You
must check the return values of SDL function calls to determine when to
appropriately call `SDL_GetError( )`. You should **not** use the results of
`SDL_GetError( )` to decide if an error has occurred! Sometimes SDL will set
an error string even when reporting success.

SDL will **not** clear the error string for successful API calls. You **must**
check return values for failure cases before you can assume the error string
applies.

Error strings are set per-thread, so an error set in a different thread will
not interfere with the current thread's operation.

The returned string is internally allocated and must not be freed by the
application.

Returns a message with information about the specific error that occurred, or
an empty string if there hasn't been an error message set since the last call
to [`SDL_ClearError( )`](#sdl_clearerror). The message is only
applicable when an SDL function has signaled an error. You must check the
return values of SDL function calls to determine when to appropriately call
`SDL_GetError( )`.

## `SDL_GetErrorMsg( ... )`

Get the last error message that was set for the current thread.

        my $x;
        warn SDL_GetErrorMsg($x, 300);

This allows the caller to copy the error string into a provided buffer, but
otherwise operates exactly the same as [`SDL_GetError( )`](#sdl_geterror).

- `errstr`

    A buffer to fill with the last error message that was set for the current
    thread

- `maxlen`

    The size of the buffer pointed to by the errstr parameter

Returns the pointer passed in as the `errstr` parameter.

## `SDL_ClearError( )`

Clear any previous error message for this thread.

    SDL_ClearError( );

## `SDL_Error( ... )`

Set the current error to a member of the [`<SDL_errorcode`](https://metacpan.org/pod/SDL2%3A%3AEnum#errorcode) enum.

    SDL_Error( SDL_EFWRITE );

Unconditionally returns `-1`.

# Event loop

## `SDL_PumpEvents( )`

Pump the event loop, gathering events from the input devices.

    SDL_PumpEvents( );

This function updates the event queue and internal input device state.

**WARNING**: This should only be run in the thread that initialized the video
subsystem, and for extra safety, you should consider only doing those things on
the main thread in any case.

`SDL_PumpEvents( )` gathers all the pending input information from devices and
places it in the event queue. Without calls to `SDL_PumpEvents( )` no events
would ever be placed on the queue. Often the need for calls to
`SDL_PumpEvents( )` is hidden from the user since [`SDL_PollEvent(
)`](#sdl_pollevent) and [`SDL_WaitEvent( )`](#sdl_waitevent)
implicitly call `SDL_PumpEvents( )`. However, if you are not polling or
waiting for events (e.g. you are filtering them), then you must call
`SDL_PumpEvents( )` to force an event queue update.

# Configuration Variables

This category contains functions to set and get configuration hints, as well as
listing each of them alphabetically.

The convention for naming hints is `SDL_HINT_X`, where `SDL_X` is the
environment variable that can be used to override the default. You may import
those recognised by SDL2 with the [`:hints`](https://metacpan.org/pod/SDL2%3A%3AEnum#hints) tag.

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
variable that takes precedence. You can use SDL\_SetHintWithPriority( ) to set
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
                { time => time( ), clicks => 3 }
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
                { time => time( ), clicks => 3 }
        );

Expected parameters:

- `name`

    the hint to watch

- `callback`

    [FFI::Platypus::Closure](https://metacpan.org/pod/FFI%3A%3APlatypus%3A%3AClosure) object returned by [`SDL_AddHintCallback( ...
    )`](#sdl_addhintcallback)

- `userdata`

    a pointer to pass to the callback function

## `SDL_ClearHints( )`

Clear all hints.

        SDL_ClearHints( );

This function is automatically called during [`SDL_Quit( )`](#sdl_quit).

# Log Handling

Simple log messages with categories and priorities. These functions may be
imported with the `:logging` tag.

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

    The category to assign a priority to. These may be imported with the [`:logcategory`](#logcategory) tag.

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

        SDL_LogVerbose( 'Current time: %s [%ds exec]', +localtime( ), time - $^T );

Expected parameters:

- `category`

    The category of the message.

- `fmt`

    A `sprintf( )` style message format string.

- `...`

    Additional parameters matching `%` tokens in the `fmt` string, if any.

## `SDL_LogDebug( ... )`

Log a message with `SDL_LOG_PRIORITY_DEBUG`.

        SDL_LogDebug( 'Current time: %s [%ds exec]', +localtime( ), time - $^T );

Expected parameters:

- `category`

    The category of the message.

- `fmt`

    A `sprintf( )` style message format string.

- `...`

    Additional parameters matching `%` tokens in the `fmt` string, if any.

## `SDL_LogInfo( ... )`

Log a message with `SDL_LOG_PRIORITY_INFO`.

        SDL_LogInfo( 'Current time: %s [%ds exec]', +localtime( ), time - $^T );

Expected parameters:

- `category`

    The category of the message.

- `fmt`

    A `sprintf( )` style message format string.

- `...`

    Additional parameters matching `%` tokens in the `fmt` string, if any.

## `SDL_LogWarn( ... )`

Log a message with `SDL_LOG_PRIORITY_WARN`.

        SDL_LogWarn( 'Current time: %s [%ds exec]', +localtime( ), time - $^T );

Expected parameters:

- `category`

    The category of the message.

- `fmt`

    A `sprintf( )` style message format string.

- `...`

    Additional parameters matching `%` tokens in the `fmt` string, if any.

## `SDL_LogError( ... )`

Log a message with `SDL_LOG_PRIORITY_ERROR`.

        SDL_LogError( 'Current time: %s [%ds exec]', +localtime( ), time - $^T );

Expected parameters:

- `category`

    The category of the message.

- `fmt`

    A `sprintf( )` style message format string.

- `...`

    Additional parameters matching `%` tokens in the `fmt` string, if any.

## `SDL_LogCritical( ... )`

Log a message with `SDL_LOG_PRIORITY_CRITICAL`.

        SDL_LogCritical( 'Current time: %s [%ds exec]', +localtime( ), time - $^T );

Expected parameters:

- `category`

    The category of the message.

- `fmt`

    A `sprintf( )` style message format string.

- `...`

    Additional parameters matching `%` tokens in the `fmt` string, if any.

## `SDL_LogMessage( ... )`

Log a message with the specified category and priority.

        SDL_LogMessage( SDL_LOG_CATEGORY_APPLICATION, SDL_LOG_PRIORITY_CRITICAL,
                                        'Current time: %s [%ds exec]', +localtime( ), time - $^T );

Expected parameters:

- `category`

    The category of the message.

- `priority`

    The priority of the message.

- `fmt`

    A `sprintf( )` style message format string.

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

## `SDL_GetVersion( ... )`

Get the version of SDL that is linked against your program.

        my $ver = SDL2::Version->new;
        SDL_GetVersion( $ver );

This function may be called safely at any time, even before [`SDL_Init(
)`](#sdl_init).

Expected parameters include:

- `version` - An SDL2::Version object which will be filled with the proper values

# Display and Window Management

This category contains functions for handling display and window actions.

These functions may be imported with the `:video` tag.

## `SDL_GetNumVideoDrivers( )`

        my $num = SDL_GetNumVideoDrivers( );

Get the number of video drivers compiled into SDL.

Returns a number >= 1 on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror) for more information.

## `SDL_GetVideoDriver( ... )`

Get the name of a built in video driver.

    CORE::say SDL_GetVideoDriver($_) for 0 .. SDL_GetNumVideoDrivers( ) - 1;

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
either SDL\_Init( ) or SDL\_InitSubSystem( ), you should call SDL\_VideoQuit( )
before calling SDL\_Quit( ).

It is safe to call this function multiple times. SDL\_VideoInit( ) will call
SDL\_VideoQuit( ) itself if the video subsystem has already been initialized.

You can use SDL\_GetNumVideoDrivers( ) and SDL\_GetVideoDriver( ) to find a
specific \`driver\_name\`.

Expected parameters include:

- `driver_name` - the name of a video driver to initialize, or undef for the default driver

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror) for more information.

## `SDL_VideoQuit( )`

Shut down the video subsystem, if initialized with [`SDL_VideoInit(
)`](#sdl_videoinit).

        SDL_VideoQuit( );

This function closes all windows, and restores the original video mode.

## `SDL_GetCurrentVideoDriver( )`

Get the name of the currently initialized video driver.

        my $driver = SDL_GetCurrentVideoDriver( );

Returns the name of the current video driver or NULL if no driver has been
initialized.

## `SDL_GetNumVideoDisplays( )`

Get the number of available video displays.

        my $screens = SDL_GetNumVideoDisplays( );

Returns a number >= 1 or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror) for more information.

## `SDL_GetDisplayName( ... )`

Get the name of a display in UTF-8 encoding.

        my $screen = SDL_GetDisplayName( 0 );

Expected parameters include:

- `displayIndex` - the index of display from which the name should be queried

Returns the name of a display or undefined for an invalid display index or
failure; call [`SDL_GetError( )`](#sdl_geterror) for more
information.

## `SDL_GetDisplayBounds( ... )`

Get the desktop area represented by a display.

        my $rect = SDL_GetDisplayBounds( 0 );

The primary display (`displayIndex == 0`) is always located at 0,0.

Expected parameters include:

- `displayIndex` - the index of the display to query

Returns the SDL2::Rect structure filled in with the display bounds on success
or a negative error code on failure; call [`SDL_GetError(
)`](#sdl_geterror) for more information.

## `SDL_GetDisplayUsableBounds( ... )`

Get the usable desktop area represented by a display.

        my $rect = SDL_GetDisplayUsableBounds( 0 );

The primary display (`displayIndex == 0`) is always located at 0,0.

This is the same area as [`SDL_GetDisplayBounds( ...
)`](#sdl_getdisplaybounds) reports, but with portions reserved by
the system removed. For example, on Apple's macOS, this subtracts the area
occupied by the menu bar and dock.

Setting a window to be fullscreen generally bypasses these unusable areas, so
these are good guidelines for the maximum space available to a non-fullscreen
window.

Expected parameters include:

- `displayIndex` - the index of the display to query

Returns the SDL2::Rect structure filled in with the display bounds on success
or a negative error code on failure; call [`SDL_GetError(
)`](#sdl_geterror) for more information. This function also returns
`-1` if the parameter `displayIndex` is out of range.

## `SDL_GetDisplayDPI( ... )`

Get the dots/pixels-per-inch for a display.

        my ( $ddpi, $hdpi, $vdpi ) = SDL_GetDisplayDPI( 0 );

Diagonal, horizontal and vertical DPI can all be optionally returned if the
appropriate parameter is non-NULL.

A failure of this function usually means that either no DPI information is
available or the `displayIndex` is out of range.

Expected parameters include:

- `displayIndex` - the index of the display from which DPI information should be queried

Returns `[ddpi, hdpi, vdip]` on success or a negative error code on failure;
call [`SDL_GetError( )`](#sdl_geterror) for more information.

`ddpi` is the diagonal DPI of the display, `hdpi` is the horizontal DPI of
the display, `vdpi` is the vertical DPI of the display.

## `SDL_GetDisplayOrientation( ... )`

Get the orientation of a display.

        my $orientation = SDL_GetDisplayOrientation( 0 );

Expected parameters include:

- `displayIndex` - the index of the display to query

Returns a value which may be imported with `:displayOrientation` or
`SDL_ORIENTATION_UNKNOWN` if it isn't available.

## `SDL_GetNumDisplayModes( ... )`

Get the number of available display modes.

        my $modes = SDL_GetNumDisplayModes( 0 );

The `displayIndex` needs to be in the range from `0` to
`SDL_GetNumVideoDisplays( ) - 1`.

Expected parameters include:

- `displayIndex` - the index of the display to query

Returns a number >= 1 on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror) for more information.

## `SDL_GetDisplayMode( ... )`

Get information about a specific display mode.

        my $mode = SDL_GetDisplayMode( 0, 0 );

The display modes are sorted in this priority:

- width - largest to smallest
- height - largest to smallest
- bits per pixel - more colors to fewer colors
- packed pixel layout - largest to smallest
- refresh rate - highest to lowest

Expected parameters include:

- `displayIndex` - the index of the display to query
- `modeIndex` - the index of the display mode to query

Returns an [SDL2::DisplayMode](https://metacpan.org/pod/SDL2%3A%3ADisplayMode) structure filled in with the mode at
`modeIndex` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror) for more information.

## `SDL_GetDesktopDisplayMode( ... )`

Get information about the desktop's display mode.

        my $mode = SDL_GetDesktopDisplayMode( 0 );

There's a difference between this function and [`SDL_GetCurrentDisplayMode(
... )`](#sdl_getcurrentdisplaymode) when SDL runs fullscreen and has
changed the resolution. In that case this function will return the previous
native display mode, and not the current display mode.

Expected parameters include:

- `displayIndex` - the index of the display to query

Returns an [SDL2::DisplayMode](https://metacpan.org/pod/SDL2%3A%3ADisplayMode) structure filled in with the current display
mode on success or a negative error code on failure; call [`SDL_GetError(
)`](#sdl_geterror) for more information.

## `SDL_GetCurrentDisplayMode( ... )`

        my $mode = SDL_GetCurrentDisplayMode( 0 );

There's a difference between this function and [`SDL_GetDesktopDisplayMode(
... )`](#sdl_getdesktopdisplaymode) when SDL runs fullscreen and has
changed the resolution. In that case this function will return the current
display mode, and not the previous native display mode.

Expected parameters include:

- `displayIndex` - the index of the display to query

Returns an [SDL2::DisplayMode](https://metacpan.org/pod/SDL2%3A%3ADisplayMode) structure filled in with the current display
mode on success or a negative error code on failure; call [`SDL_GetError(
)`](#sdl_geterror) for more information.

## `SDL_GetClosestDisplayMode( ... )`

Get the closes match to the requested display mode.

        $mode = SDL_GetClosestDisplayMode( 0, $mode );

The available display modes are scanned and he closest mode matching the
requested mode is returned. The mode format and refresh rate default to the
desktop mode if they are set to 0. The modes are scanned with size being first
priority, format being second priority, and finally checking the refresh rate.
If all the available modes are too small, then an undefined value is returned.

Expected parameters include:

- `displayIndex` - index of the display to query
- `mode` - an [SDL2::DisplayMode](https://metacpan.org/pod/SDL2%3A%3ADisplayMode) structure containing the desired display mode
- `closest` - an [SDL2::DisplayMode](https://metacpan.org/pod/SDL2%3A%3ADisplayMode) structure filled in with the closest match of the available display modes

Returns the passed in value `closest` or an undefined value if no matching
video mode was available; call [`SDL_GetError( )`](#sdl_geterror)
for more information.

## `SDL_GetWindowDisplayIndex( ... )`

Get the index of the display associated with a window.

        my $index = SDL_GetWindowDisplayIndex( $window );

Expected parameters include:

- `window`	- the window to query

Returns the index of the display containing the center of the window on success
or a negative error code on failure; call  [`SDL_GetError(
)`](#sdl_geterror) for more information.

## `SDL_SetWindowDisplayMode( ... )`

Set the display mode to use when a window is visible at fullscreen.

        my $ok = !SDL_SetWindowDisplayMode( $window, $mode );

This only affects the display mode used when the window is fullscreen. To
change the window size when the window is not fullscreen, use [`SDL_SetWindowSize( ... )`](#sdl_setwindowsize).

## `SDL_GetWindowDisplayMode( ... )`

Query the display mode to use when a window is visible at fullscreen.

        my $mode = SDL_GetWindowDisplayMode( $window );

Expected parameters include:

- `window` - the window to query

Returns a [SDL2::DisplayMode](https://metacpan.org/pod/SDL2%3A%3ADisplayMode) structure on success or a negative error code on
failure; call [`SDL_GetError( )`](#sdl_geterror) for more
information.

## `SDL_GetWindowPixelFormat( ... )`

Get the pixel format associated with the window.

        my $format = SDL_GetWindowPixelFormat( $window );

Expected parameters include:

- `window` - the window to query

Returns the pixel format of the window on success or `SDL_PIXELFORMAT_UNKNOWN`
on failure; call [`SDL_GetError( )`](#sdl_geterror) for more
information.

## `SDL_CreateWindow( ... )`

Create a window with the specified position, dimensions, and flags.

    my $window = SDL_CreateWindow( 'Example',
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
        1280, 720,
        SDL_WINDOW_SHOWN
    );

`flags` may be any of the following OR'd together:

- `SDL_WINDOW_FULLSCREEN` - fullscreen window
- `SDL_WINDOW_FULLSCREEN_DESKTOP` - fullscreen window at desktop resolution
- `SDL_WINDOW_OPENGL` - window usable with an OpenGL context
- `SDL_WINDOW_VULKAN` - window usable with a Vulkan instance
- `SDL_WINDOW_METAL` - window usable with a Metal instance
- `SDL_WINDOW_HIDDEN` - window is not visible
- `SDL_WINDOW_BORDERLESS` - no window decoration
- `SDL_WINDOW_RESIZABLE` - window can be resized
- `SDL_WINDOW_MINIMIZED` - window is minimized
- `SDL_WINDOW_MAXIMIZED` - window is maximized
- `SDL_WINDOW_INPUT_GRABBED` - window has grabbed input focus
- `SDL_WINDOW_ALLOW_HIGHDPI` - window should be created in high-DPI mode if supported (>= SDL 2.0.1)

`SDL_WINDOW_SHOWN` is ignored by `SDL_CreateWindow( ... )`. The SDL\_Window is
implicitly shown if `SDL_WINDOW_HIDDEN` is not set. `SDL_WINDOW_SHOWN` may be
queried later using [`SDL_GetWindowFlags( ... )`](#sdl_getwindowflags).

On Apple's macOS, you **must** set the NSHighResolutionCapable Info.plist
property to YES, otherwise you will not receive a High-DPI OpenGL canvas.

If the window is created with the `SDL_WINDOW_ALLOW_HIGHDPI` flag, its size in
pixels may differ from its size in screen coordinates on platforms with
high-DPI support (e.g. iOS and macOS). Use [`SDL_GetWindowSize( ...
)`](#sdl_getwindowsize) to query the client area's size in screen
coordinates, and [`SDL_GL_GetDrawableSize( )`](#sdl_gl_getdrawablesize) or [`SDL_GetRendererOutputSize( )`](#sdl_getrendereroutputsize)
to query the drawable size in pixels.

If the window is set fullscreen, the width and height parameters `w` and `h`
will not be used. However, invalid size parameters (e.g. too large) may still
fail. Window size is actually limited to 16384 x 16384 for all platforms at
window creation.

If the window is created with any of the `SDL_WINDOW_OPENGL` or
`SDL_WINDOW_VULKAN` flags, then the corresponding LoadLibrary function
(SDL\_GL\_LoadLibrary or SDL\_Vulkan\_LoadLibrary) is called and the corresponding
UnloadLibrary function is called by [`SDL_DestroyWindow( ...
)`](#sdl_destroywindow).

If `SDL_WINDOW_VULKAN` is specified and there isn't a working Vulkan driver,
`SDL_CreateWindow( ... )` will fail because [`SDL_Vulkan_LoadLibrary(
)`](#sdl_vulkan_loadlibrary) will fail.

If `SDL_WINDOW_METAL` is specified on an OS that does not support Metal,
`SDL_CreateWindow( ... )` will fail.

On non-Apple devices, SDL requires you to either not link to the Vulkan loader
or link to a dynamic library version. This limitation may be removed in a
future version of SDL.

Expected parameters include:

- `title` - the title of the window, in UTF-8 encoding
- `x` - the x position of the window, `SDL_WINDOWPOS_CENTERED`, or `SDL_WINDOWPOS_UNDEFINED`
- `y` - the y position of the window, `SDL_WINDOWPOS_CENTERED`, or `SDL_WINDOWPOS_UNDEFINED`
- `w` - the width of the window, in screen coordinates
- `h` - the height of the window, in screen coordinates
- `flags` - 0, or one or more [`:windowFlags`](https://metacpan.org/pod/SDL2%3A%3AEnum#windowFlags) OR'd together

Returns the window that was created or an undefined value on failure; call [`SDL_GetError( )`](#sdl_geterror) for more information.

## `SDL_CreateWindowFrom( ... )`

Create an SDL window from an existing native window.

        my $window = SDL_CreateWindowFrom( $data );

In some cases (e.g. OpenGL) and on some platforms (e.g. Microsoft Windows) the
hint `SDL_HINT_VIDEO_WINDOW_SHARE_PIXEL_FORMAT` needs to be configured before
using `SDL_CreateWindowFrom( ... )`.

Expected parameters include:

- `data` - driver-dependant window creation data, typically your native window

Returns the window that was created or an undefined value on failure; call [`SDL_GetError( )`](#sdl_geterror) for more information.

## `SDL_GetWindowID( ... )`

Get the numeric ID of a window.

        my $id = SDL_GetWindowID( $window );

The numeric ID is what [SDL2::WindowEvent](https://metacpan.org/pod/SDL2%3A%3AWindowEvent) references, and is necessary to map
these events to specific [SDL2::Window](https://metacpan.org/pod/SDL2%3A%3AWindow) objects.

Expected parameters include:

- `window` - the window to query

Returns the ID of the window on success or `0` on failure; call [`SDL_GetError( )`](#sdl_geterror) for more information.

## `SDL_GetWindowFromID( ... )`

Get a window from a stored ID.

        my $window = SDL_GetWindowFromID( 2 );

The numeric ID is what [SDL2::WindowEvent](https://metacpan.org/pod/SDL2%3A%3AWindowEvent) references, and is necessary to map
these events to specific [SDL2::Window](https://metacpan.org/pod/SDL2%3A%3AWindow) objects.

Expected parameters include:

- `id` - the ID of the window

Returns the window associated with `id` or an undefined value if it doesn't
exist; call [`SDL_GetError( )`](#sdl_geterror) for more information.

## `SDL_GetWindowFlags( ... )`

Get the window flags.

        my $id = SDL_GetWindowFlags( $window );

The numeric ID is what [SDL2::WindowEvent](https://metacpan.org/pod/SDL2%3A%3AWindowEvent) references, and is necessary to map
these events to specific [SDL2::Window](https://metacpan.org/pod/SDL2%3A%3AWindow) objects.

Expected parameters include:

- `window` - the window to query

Returns a mask of the [`:windowFlags`](https://metacpan.org/pod/SDL2%3A%3AEnum#windowFlags)
associated with `window`.

## `SDL_SetWindowTitle( ... )`

Set the title of a window.

        SDL_SetWindowTitle( $window, 'Untitle file *' );

This string is expected to be in UTF-8 encoding.

Expected parameters include:

- `window` - the window to change
- `title` - the desired window title in UTF-8 format

## `SDL_GetWindowTitle( ... )`

Get the title of a window.

        my $title = SDL_GetWindowTitle( $window );

Expected parameters include:

- `window` - the window to query

Returns the title of the window in UTF-8 format or `""` (an empty string) if
there is no title.

## `SDL_SetWindowIcon( ... )`

Set the icon for a window.

        SDL_SetWindowIcon( $window, $icon );

Expected parameters include:

- `window` - the window to change
- `icon` - an [SDL2::Surface](https://metacpan.org/pod/SDL2%3A%3ASurface) structure containing the icon for the window

## `SDL_SetWindowData( ... )`

Associate an arbitrary named pointer with a window.

        my $prev = SDL_SetWindowData( $window, 'test', $data );

Expected parameters include:

- `window` - the window to change
- `name` - the name of the pointer
- `userdata` - the associated pointer

Returns the previous value associated with `name`.

## `SDL_GetWindowData( ... )`

Retrieve the data pointer associated with a window.

        my $data = SDL_SetWindowData( $window, 'test' );

Expected parameters include:

- `window` - the window to query
- `name` - the name of the pointer

Returns the value associated with `name`.

## `SDL_SetWindowPosition( ... )`

Set the position of a window.

        SDL_SetWindowPosition( $window, 100, 100 );

The window coordinate origin is the upper left of the display.

Expected parameters include:

- `window` - the window to reposition
- `x` - the x coordinate of the window in screen coordinates, or `SDL_WINDOWPOS_CENTERED` or `SDL_WINDOWPOS_UNDEFINED`
- `y` - the y coordinate of the window in screen coordinates, or `SDL_WINDOWPOS_CENTERED` or `SDL_WINDOWPOS_UNDEFINED`

## `SDL_GetWindowPosition( ... )`

Get the position of a window.

        my ($x, $y) = SDL_GetWindowPosition( $window );

Expected parameters include:

- `window` - the window to query

Returns the `x` and `y` positions of the window, in screen coordinates,
either of which may be undefined.

## `SDL_SetWindowSize( ... )`

Set the size of a window's client area.

        SDL_SetWindowSize( $window, 100, 100 );

The window size in screen coordinates may differ from the size in pixels, if
the window was created with `SDL_WINDOW_ALLOW_HIGHDPI` on a platform with
high-dpi support (e.g. iOS or macOS). Use [`SDL_GL_GetDrawableSize( ...
)`](https://metacpan.org/pod/SDL_GL_GetDrawableSize%28%20...%20%29) or [`SDL_GetRendererOutputSize( ...
)`](#sdl_getrendereroutputsize) to get the real client area size in
pixels.

Fullscreen windows automatically match the size of the display mode, and you
should use [`SDL_SetWindowDisplayMode( ... )`](#sdl_setwindowdisplaymode) to change their size.

Expected parameters include:

- `window` - the window to change
- `w` - the width of the window in pixels, in screen coordinates, must be > 0
- `h` - the height of the window in pixels, in screen coordinates, must be > 0

## `SDL_GetWindowSize( ... )`

Get the position of a window.

        my ($w, $h) = SDL_GetWindowSize( $window );

The window size in screen coordinates may differ from the size in pixels, if
the window was created with `SDL_WINDOW_ALLOW_HIGHDPI` on a platform with
high-dpi support (e.g. iOS or macOS). Use [`SDL_GL_GetDrawableSize( ...
)`](https://metacpan.org/pod/SDL_GL_GetDrawableSize%28%20...%20%29), [`SDL_Vulkan_GetDrawableSize( ...
)`](#sdl_vulkan_getdrawablesize), or [`SDL_GetRendererOutputSize( ... )`](#sdl_getrendereroutputsize) to
get the real client area size in pixels.

Expected parameters include:

- `window` - the window to query the width and height from

Returns the `width` and `height` of the window, in screen coordinates, either
of which may be undefined.

## `SDL_GetWindowBordersSize( ... )`

Get the size of a window's borders (decorations) around the client area.

        my ($top, $left, $bottom, $right) = SDL_GetWindowBorderSize( $window );

Expected parameters include:

- `window` - the window to query the size values of the border (decorations) from

Returns the `top`, `left`, `bottom`, and `right` size values, any of which
may be undefined.

Note: If this function fails (returns -1), the size values will be initialized
to `0, 0, 0, 0`, as if the window in question was borderless.

Note: This function may fail on systems where the window has not yet been
decorated by the display server (for example, immediately after calling [`SDL_CreateWindow( ...  )`](#sdl_createwindow) ). It is
recommended that you wait at least until the window has been presented and
composited, so that the window system has a chance to decorate the window and
provide the border dimensions to SDL.

This function also returns `-1` if getting the information is not supported.

## `SDL_SetWindowMinimumSize( ... )`

Set the minimum size of a window's client area.

        SDL_SetWindowMinimumSize( $window, 100, 100 );

Expected parameters include:

- `window` - the window to change
- `w` - the minimum width of the window in pixels
- `h` - the minimum height of the window in pixels

## `SDL_GetWindowMinimumSize( ... )`

Get the minimum size of a window's client area.

        my ($w, $h) = SDL_GetWindowMinimumSize( $window );

Expected parameters include:

- `window` - the window to query the minimum width and minimum height from

Returns the minimum `width` and minimum `height` of the window, either of
which may be undefined.

## `SDL_SetWindowMaximumSize( ... )`

Set the maximum size of a window's client area.

        SDL_SetWindowMaximumSize( $window, 100, 100 );

Expected parameters include:

- `window` - the window to change
- `w` - the maximum width of the window in pixels
- `h` - the maximum height of the window in pixels

## `SDL_GetWindowMaximumSize( ... )`

Get the maximum size of a window's client area.

        my ($w, $h) = SDL_GetWindowMaximumSize( $window );

Expected parameters include:

- `window` - the window to query the maximum width and maximum height from

Returns the maximum `width` and maximum `height` of the window, either of
which may be undefined.

## `SDL_SetWindowBordered( ... )`

Set the border state of a window.

        SDL_SetWindowBordered( $window, 1 );

This will add or remove the window's `SDL_WINDOW_BORDERLESS` flag and add or
remove the border from the actual window. This is a no-op if the window's
border already matches the requested state.

You can't change the border state of a fullscreen window.

Expected parameters include:

- `window` - the window of which to change the border state
- `bordered` - false value to remove border, true value to add border

## `SDL_SetWindowResizable( ... )`

Set the user-resizable state of a window.

        SDL_SetWindowResizable( $window, 1 );

This will add or remove the window's `SDL_WINDOW_RESIZABLE` flag and
allow/disallow user resizing of the window. This is a no-op if the window's
resizable state already matches the requested state.

You can't change the resizable state of a fullscreen window.

Expected parameters include:

- `window` - the window of which to change the border state
- `bordered` - true value to allow resizing, false value to disallow

## `SDL_ShowWindow( ... )`

Show a window.

        SDL_ShowWindow( $window );

Expected parameters include:

- `window` - the window to show

## `SDL_HideWindow( ... )`

Hide a window.

        SDL_HideWindow( $window );

Expected parameters include:

- `window` - the window to hide

## `SDL_RaiseWindow( ... )`

Raise a window above other windows and set the input focus.

        SDL_RaiseWindow( $window );

Expected parameters include:

- `window` - the window to raise

## `SDL_MaximizeWindow( ... )`

Make a window as large as possible.

        SDL_MaximizeWindow( $window );

Expected parameters include:

- `window` - the window to maximize

## `SDL_MinimizeWindow( ... )`

Minimize a window to an iconic representation.

        SDL_MinimizeWindow( $window );

Expected parameters include:

- `window` - the window to minimize

## `SDL_RestoreWindow( ... )`

Restore the size and position of a minimized or maximized window.

        SDL_RestoreWindow( $window );

Expected parameters include:

- `window` - the window to restore

## `SDL_SetWindowFullscreen( ... )`

Set a window's fullscreen state.

        SDL_SetWindowFullscreen( $window, SDL_WINDOW_FULLSCREEN );

Expected parameters include:

- `window` - the window to change
- `flags` - `SDL_WINDOW_FULLSCREEN`, `SDL_WINDOW_FULLSCREEN_DESKTOP` or 0

Returns  0 on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror) for more information.

## `SDL_GetWindowSurface( ... )`

Get the SDL surface associated with the window.

        my $surface = SDL_GetWindowSurface( $window );

A new surface will be created with the optimal format for the window, if
necessary. This surface will be freed when the window is destroyed. Do not free
this surface.

This surface will be invalidated if the window is resized. After resizing a
window this function must be called again to return a valid surface.

You may not combine this with 3D or the rendering API on this window.

This function is affected by `SDL_HINT_FRAMEBUFFER_ACCELERATION`.

Expected parameters include:

- `window` - the window to query

Returns the surface associated with the window, or an undefined on failure;
call [`SDL_GetError( )`](#sdl_geterror) for more information.

## `SDL_UpdateWindowSurface( ... )`

Copy the window surface to the screen.

        my $ok = !SDL_UpdateWindowSurface( $window );

This is the function you use to reflect any changes to the surface on the
screen.

Expected parameters include:

- `window` - the window to query

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror) for more information.

## `SDL_UpdateWindowSurfaceRects( ... )`

Copy areas of the window surface to the screen.

        SDL_UpdateWindowSurfaceRects( $window, @recs );

This is the function you use to reflect changes to portions of the surface on
the screen.

Expected parameters include:

- `window` - the window to update
- `rects` - an array of [SDL2::Rect](https://metacpan.org/pod/SDL2%3A%3ARect) structures representing areas of the surface to copy

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror) for more information.

## `SDL_SetWindowGrab( ... )`

Set a window's input grab mode.

        SDL_SetWindowGrab( $window, 1 );

When input is grabbed the mouse is confined to the window.

If the caller enables a grab while another window is currently grabbed, the
other window loses its grab in favor of the caller's window.

Expected parameters include:

- `window` - the window for which the input grab mode should be set
- `grabbed` - a true value to grab input or a false value to release input

## `SDL_SetWindowKeyboardGrab( ... )`

Set a window's keyboard grab mode.

        SDL_SetWindowKeyboardGrab( $window, 1 );

If the caller enables a grab while another window is currently grabbed, the
other window loses its grab in favor of the caller's window.

Expected parameters include:

- `window` - The window for which the keyboard grab mode should be set.
- `grabbed` - This is true to grab keyboard, and false to release.

## `SDL_SetWindowMouseGrab( ... )`

Set a window's mouse grab mode.

        SDL_SetWindowMouseGrab( $window, 1 );

Expected parameters include:

- `window` - The window for which the mouse grab mode should be set.
- `grabbed` - This is true to grab mouse, and false to release.

If the caller enables a grab while another window is currently grabbed, the
other window loses its grab in favor of the caller's window.

## `SDL_GetWindowGrab( ... )`

Get a window's input grab mode.

        my $grabbing = SDL_GetWindowGrab( $window );

Expected parameters include:

- `window` - the window to query

Returns true if input is grabbed, false otherwise.

## `SDL_GetWindowKeyboardGrab( ... )`

Get a window's keyboard grab mode.

        my $keyboard = SDL_GetWindowKeyboardGrab( $window );

Expected parameters include:

- `window` - the window to query

Returns true if keyboard is grabbed, and false otherwise.

## `SDL_GetWindowMouseGrab( ... )`

Get a window's mouse grab mode.

        my $mouse = SDL_GetWindowMouseGrab( $window );

Expected parameters include:

- `window` - the window to query

This returns true if mouse is grabbed, and false otherwise.

## `SDL_GetGrabbedWindow( )`

Get the window that currently has an input grab enabled.

        my $window = SDL_GetGrabbedWindow( );

Returns the window if input is grabbed or undefined otherwise.

## `SDL_SetWindowBrightness( ... )`

Set the brightness (gamma multiplier) for a given window's display.

        my $ok = !SDL_SetWindowBrightness( $window, 2 );

Despite the name and signature, this method sets the brightness of the entire
display, not an individual window. A window is considered to be owned by the
display that contains the window's center pixel. (The index of this display can
be retrieved using [`SDL_GetWindowDisplayIndex( ...
)`](#sdl_getwindowdisplayindex).) The brightness set will not follow
the window if it is moved to another display.

Many platforms will refuse to set the display brightness in modern times. You
are better off using a shader to adjust gamma during rendering, or something
similar.

Expected parameters includes:

- `window` - the window used to select the display whose brightness will be changed
- `brightness` - the brightness (gamma multiplier) value to set where 0.0 is completely dark and 1.0 is normal brightness

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GetWindowBrightness( ... )`

Get the brightness (gamma multiplier) for a given window's display.

        my $gamma = SDL_GetWindowBrightness( $window );

Despite the name and signature, this method retrieves the brightness of the
entire display, not an individual window. A window is considered to be owned by
the display that contains the window's center pixel. (The index of this display
can be retrieved using [`SDL_GetWindowDisplayIndex( ...
)`](#sdl_getwindowdisplayindex).)

Expected parameters include:

- `window` - the window used to select the display whose brightness will be queried

Returns the brightness for the display where 0.0 is completely dark and `1.0`
is normal brightness.

## `SDL_SetWindowOpacity( ... )`

Set the opacity for a window.

        SDL_SetWindowOpacity( $window, .5 );

The parameter `opacity` will be clamped internally between `0.0`
(transparent) and `1.0` (opaque).

This function also returns `-1` if setting the opacity isn't supported.

Expected parameters include:

- `window` - the window which will be made transparent or opaque
- `opacity` - the opacity value (0.0 - transparent, 1.0 - opaque)

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GetWindowOpacity( ... )`

Get the opacity of a window.

        my $opacity = SDL_GetWindowOpacity( $window );

If transparency isn't supported on this platform, opacity will be reported as
1.0 without error.

The parameter `opacity` is ignored if it is undefined.

This function also returns `-1` if an invalid window was provided.

Expected parameters include:

- `window` - the window to get the current opacity value from

Returns the current opacity on success or a negative error code on failure;
call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_SetWindowModalFor( ... )`

Set the window as a modal for another window.

        my $ok = !SDL_SetWindowModalFor( $winodw, $parent );

Expected parameters include:

- `modal_window` - the window that should be set modal
- `parent_window` - the parent window for the modal window

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_SetWindowInputFocus( ... )`

Explicitly set input focus to the window.

        SDL_SetWindowInputFocus( $window );

You almost certainly want [`SDL_RaiseWindow( ... )`](#sdl_raisewindow) instead of this function. Use this with caution, as you might give focus
to a window that is completely obscured by other windows.

Expected parameters include:

- `window` - the window that should get the input focus

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_SetWindowGammaRamp( ... )`

Set the gamma ramp for the display that owns a given window.

        my $ok = !SDL_SetWindowGammaRamp( $window, \@red, \@green, \@blue );

Set the gamma translation table for the red, green, and blue channels of the
video hardware. Each table is an array of 256 16-bit quantities, representing a
mapping between the input and output for that channel. The input is the index
into the array, and the output is the 16-bit gamma value at that index, scaled
to the output color precision. Despite the name and signature, this method sets
the gamma ramp of the entire display, not an individual window. A window is
considered to be owned by the display that contains the window's center pixel.
(The index of this display can be retrieved using [`SDL_GetWindowDisplayIndex( ... )`](#sdl_getwindowdisplayindex).)
The gamma ramp set will not follow the window if it is moved to another
display.

Expected parameters include:

- `window` - the window used to select the display whose gamma ramp will be changed
- `red` - a 256 element array of 16-bit quantities representing the translation table for the red channel, or NULL
- `green` - a 256 element array of 16-bit quantities representing the translation table for the green channel, or NULL
- `blue` - a 256 element array of 16-bit quantities representing the translation table for the blue channel, or NULL

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GetWindowGammaRamp( ... )`

Get the gamma ramp for a given window's display.

        my ($red, $green, $blue) = SDL_GetWindowGammaRamp( $window );

Despite the name and signature, this method retrieves the gamma ramp of the
entire display, not an individual window. A window is considered to be owned by
the display that contains the window's center pixel. (The index of this display
can be retrieved using [`SDL_GetWindowDisplayIndex( ...
)`](#sdl_getwindowdisplayindex).)

Expected parameters include:

- `window` - the window used to select the display whose gamma ramp will be queried

Returns three 256 element arrays of 16-bit quantities filled in with the
translation table for the red, gree, and blue channels on success or a negative
error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( )
for more information.

## `SDL_SetWindowHitTest( ... )`

Provide a callback that decides if a window region has special properties.

        SDL_SetWindowHitTest( $window, sub ($win, $point, $data) {
        warn sprintf 'Click at x:%d y:%d', $point->x, $point->y;
        ...;
        });

Normally, windows are dragged and resized by decorations provided by the system
window manager (a title bar, borders, etc), but for some apps, it makes sense
to drag them from somewhere else inside the window itself; for example, one
might have a borderless window that wants to be draggable from any part, or
simulate its own title bar, etc.

This function lets the app provide a callback that designates pieces of a given
window as special. This callback is run during event processing if we need to
tell the OS to treat a region of the window specially; the use of this callback
is known as "hit testing."

Mouse input may not be delivered to your application if it is within a special
area; the OS will often apply that input to moving the window or resizing the
window and not deliver it to the application.

Specifying undef for a callback disables hit-testing. Hit-testing is disabled
by default.

Platforms that don't support this functionality will return `-1`
unconditionally, even if you're attempting to disable hit-testing.

Your callback may fire at any time, and its firing does not indicate any
specific behavior (for example, on Windows, this certainly might fire when the
OS is deciding whether to drag your window, but it fires for lots of other
reasons, too, some unrelated to anything you probably care about **and when the
mouse isn't actually at the location it is testing**). Since this can fire at
any time, you should try to keep your callback efficient, devoid of
allocations, etc.

Expected parameters include:

- `window` - the window to set hit-testing on
- `callback` - the function to call when doing a hit-test
- `callback_data` - an app-defined void pointer passed to `callback`

Returns `0` on success or `-1` on error (including unsupported); call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_FlashWindow( ... )`

Request a window to give a signal, e.g. a visual signal, to demand attention
from the user.

        SDL_FlashWindow( $window, 10 );

Expected parameters include:

- `window` - the window to request the flashing for
- `flash_count` - number of times the window gets flashed on systems that support flashing the window multiple times, like Windows, else it is ignored

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_DestroyWindow( ... )`

Destroy a window.

        SDL_DestoryWindow( $window );

If `window` is undefined, this function will return immediately after setting
the SDL error message to "Invalid window". See [`SDL_GetError(
)`](#sdl_geterror)( ).

Expected parameters include:

- `window` - the window to destroy

## `SDL_IsScreenSaverEnabled( ... )`

Check whether the screensaver is currently enabled.

        my $enabled = SDL_IsScreenSaverEnabled( );

The screensaver is disabled by default since SDL 2.0.2. Before SDL 2.0.2 the
screensaver was enabled by default.

The default can also be changed using `SDL_HINT_VIDEO_ALLOW_SCREENSAVER`.

Returns true if the screensaver is enabled, false if it is disabled.

## `SDL_EnableScreenSaver( ... )`

Allow the screen to be blanked by a screen saver.

        SDL_EnableScreenSaver( );

## `SDL_DisableScreenSaver( ... )`

Prevent the screen from being blanked by a screen saver.

        SDL_DisableScreenSaver( );

If you disable the screensaver, it is automatically re-enabled when SDL quits.

# OpenGL Support Functions

These may be imported with the `:opengl` tag.

## `SDL_GL_LoadLibrary( ... )`

Dynamically load an OpenGL library.

        my $ok = SDL_GL_LoadLibrary( );

This should be done after initializing the video driver, but before creating
any OpenGL windows. If no OpenGL library is loaded, the default library will be
loaded upon creation of the first OpenGL window.

If you do this, you need to retrieve all of the GL functions used in your
program from the dynamic library using [`SDL_GL_GetProcAddress(
)`](#sdl_gl_getprocaddress).

Expected parameters include:

- `path` - the platform dependent OpenGL library name, or undef to open the default OpenGL library

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GL_GetProcAddress( ... )`

Get an OpenGL function by name.

        my $ptr = SDL_GL_GetProcAddress( 'glGenBuffers' );
        ...; # TODO
        # TODO: In the future, this should return an XSUB loaded with FFI.

If the GL library is loaded at runtime with [`SDL_GL_LoadLibrary( ...
)`](#sdl_gl_loadlibrary), then all GL functions must be retrieved
this way. Usually this is used to retrieve function pointers to OpenGL
extensions.

There are some quirks to looking up OpenGL functions that require some extra
care from the application. If you code carefully, you can handle these quirks
without any platform-specific code, though:

- On Windows, function pointers are specific to the current GL context;
this means you need to have created a GL context and made it current before
calling SDL\_GL\_GetProcAddress( ). If you recreate your context or create a
second context, you should assume that any existing function pointers
aren't valid to use with it. This is (currently) a Windows-specific
limitation, and in practice lots of drivers don't suffer this limitation,
but it is still the way the wgl API is documented to work and you should
expect crashes if you don't respect it. Store a copy of the function
pointers that comes and goes with context lifespan.
- On X11, function pointers returned by this function are valid for any
context, and can even be looked up before a context is created at all. This
means that, for at least some common OpenGL implementations, if you look up
a function that doesn't exist, you'll get a non-NULL result that is \_NOT\_
safe to call. You must always make sure the function is actually available
for a given GL context before calling it, by checking for the existence of
the appropriate extension with [`SDL_GL_ExtensionSupported( ... )`](https://metacpan.org/pod/SDL_GL_ExtensionSupported%28%20...%20%29), or verifying
that the version of OpenGL you're using offers the function as core
functionality.
- Some OpenGL drivers, on all platforms, **will** return undef if a function
isn't supported, but you can't count on this behavior. Check for extensions
you use, and if you get an undef anyway, act as if that extension wasn't
available. This is probably a bug in the driver, but you can code
defensively for this scenario anyhow.
- Just because you're on Linux/Unix, don't assume you'll be using X11.
Next-gen display servers are waiting to replace it, and may or may not make
the same promises about function pointers.
- OpenGL function pointers must be declared `APIENTRY` as in the example
code. This will ensure the proper calling convention is followed on
platforms where this matters (Win32) thereby avoiding stack corruption.

Expected parameters include:

- `proc` - the name of an OpenGL function

Returns a pointer to the named OpenGL function. The returned pointer should be
cast to the appropriate function signature.

## `SDL_GL_UnloadLibrary( )`

Unload the OpenGL library previously loaded by [`SDL_GL_LoadLibrary( ...
)`](#sdl_gl_loadlibrary).

## `SDL_GL_ExtensionSupported( ... )`

Check if an OpenGL extension is supported for the current context.

        my $ok = SDL_GL_ExtensionSupported( 'GL_ARB_texture_rectangle' );

This function operates on the current GL context; you must have created a
context and it must be current before calling this function. Do not assume that
all contexts you create will have the same set of extensions available, or that
recreating an existing context will offer the same extensions again.

While it's probably not a massive overhead, this function is not an O(1)
operation. Check the extensions you care about after creating the GL context
and save that information somewhere instead of calling the function every time
you need to know.

Expected parameters include:

- `extension` - the name of the extension to check

Returns true if the extension is supported, false otherwise.

## `SDL_GL_ResetAttributes( )`

Reset all previously set OpenGL context attributes to their default values.

        SDL_GL_ResetAttributes( );

## `SDL_GL_SetAttribute( ... )`

Set an OpenGL window attribute before window creation.

        SDL_GL_SetAttribute(SDL_GL_RED_SIZE, 5);
        SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE, 5);
        SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE, 5);
        SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 16);
        SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);

This function sets the OpenGL attribute `attr` to `value`. The requested
attributes should be set before creating an OpenGL window. You should use [`SDL_GL_GetAttribute( ... )`](#sdl_gl_getattribute) to check the
values after creating the OpenGL context, since the values obtained can differ
from the requested ones.

Expected parameters include:

- `attr` - an SDL\_GLattr enum value specifying the OpenGL attribute to set
- `value` - the desired value for the attribute

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GL_GetAttribute( ... )`

Get the actual value for an attribute from the current context.

        my $value = SDL_GL_GetAttribute(SDL_GL_DOUBLEBUFFER);

Expected parameters include:

- `attr` - an SDL\_GLattr enum value specifying the OpenGL attribute to get

Returns the value on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GL_CreateContext( ... )`

Create an OpenGL context for an OpenGL window, and make it current.

        # Window mode MUST include SDL_WINDOW_OPENGL for use with OpenGL.
        my $window = SDL_CreateWindow(
        'SDL2/OpenGL Demo', 0, 0, 640, 480,
        SDL_WINDOW_OPENGL|SDL_WINDOW_RESIZABLE);

        # Create an OpenGL context associated with the window
        my $glcontext = SDL_GL_CreateContext( $window );

        # now you can make GL calls.
        glClearColor( 0, 0, 0 ,1 );
        glClear( GL_COLOR_BUFFER_BIT );
        SDL_GL_SwapWindow( $window );

        # Once finished with OpenGL functions, the SDL_GLContext can be deleted.
        SDL_GL_DeleteContext( $glcontext );

Windows users new to OpenGL should note that, for historical reasons, GL
functions added after OpenGL version 1.1 are not available by default. Those
functions must be loaded at run-time, either with an OpenGL extension-handling
library or with [`SDL_GL_GetProcAddress( ... )`](#sdl_gl_getprocaddress) and its related functions.

SDL2::GLContext is opaque to the application.

Expected parameters include:

- `window` - the window to associate with the context

Returns the OpenGL context associated with `window` or undef on error; call
[`SDL_GetError( )`](#sdl_geterror)( ) for more details.

## `SDL_GL_MakeCurrent( ... )`

Set up an OpenGL context for rendering into an OpenGL window.

        SDL_GL_MakeCurrent( $window, $gl );

The context must have been created with a compatible window.

Expected parameters include:

- `window` - the window to associate with the context
- `context` - the OpenGL context to associate with the window

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GL_GetCurrentWindow( )`

Get the currently active OpenGL window.

        my $window = SDL_GL_GetCurrentWindow( );

Returns the currently active OpenGL window on success or undef on failure; call
[`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GL_GetCurrentContext( )`

Get the currently active OpenGL context.

        my $gl = SDL_GL_GetCurrentContext( );

Returns the currently active OpenGL context or NULL on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GL_GetDrawableSize( ... )`

Get the size of a window's underlying drawable in pixels.

        my ($w, $h) = SDL_GL_GetDrawableSize( $window );

This returns info useful for calling `glViewport( ... )`.

This may differ from [`SDL_GetWindowSize( ... )`](#sdl_getwindowsize) if we're rendering to a high-DPI drawable, i.e. the window was created
with `SDL_WINDOW_ALLOW_HIGHDPI` on a platform with high-DPI support (Apple
calls this "Retina"), and not disabled by the
`SDL_HINT_VIDEO_HIGHDPI_DISABLED` hint.

Expected parameters include:

- `window` - the window from which the drawable size should be queried

Returns the width and height in pixels, either of which may be undefined.

## `SDL_GL_SetSwapInterval( ... )`

Set the swap interval for the current OpenGL context.

        my $ok = !SDL_GL_SetSwapInterval( 1 );

Some systems allow specifying `-1` for the interval, to enable adaptive vsync.
Adaptive vsync works the same as vsync, but if you've already missed the
vertical retrace for a given frame, it swaps buffers immediately, which might
be less jarring for the user during occasional framerate drops. If application
requests adaptive vsync and the system does not support it, this function will
fail and return `-1`. In such a case, you should probably retry the call with
`1` for the interval.

Adaptive vsync is implemented for some glX drivers with
`GLX_EXT_swap_control_tear`:
[https://www.opengl.org/registry/specs/EXT/glx\_swap\_control\_tear.txt](https://www.opengl.org/registry/specs/EXT/glx_swap_control_tear.txt) and for
some Windows drivers with `WGL_EXT_swap_control_tear`:
[https://www.opengl.org/registry/specs/EXT/wgl\_swap\_control\_tear.txt](https://www.opengl.org/registry/specs/EXT/wgl_swap_control_tear.txt)

Read more on the Khronos wiki:
[https://www.khronos.org/opengl/wiki/Swap\_Interval#Adaptive\_Vsync](https://www.khronos.org/opengl/wiki/Swap_Interval#Adaptive_Vsync)

Expected parameters include:

- `interval` - 0 for immediate updates, 1 for updates synchronized with the vertical retrace, -1 for adaptive vsync

Returns `0` on success or `-1` if setting the swap interval is not supported;
call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GL_GetSwapInterval( )`

Get the swap interval for the current OpenGL context.

        my $interval = SDL_GL_GetSwapInterval( );

If the system can't determine the swap interval, or there isn't a valid current
context, this function will return 0 as a safe default.

Returns `0` if there is no vertical retrace synchronization, `1` if the
buffer swap is synchronized with the vertical retrace, and `-1` if late swaps
happen immediately instead of waiting for the next retrace; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GL_SwapWindow( ... )`

Update a window with OpenGL rendering.

        SDL_GL_SwapWindow( $window );

This is used with double-buffered OpenGL contexts, which are the default.

On macOS, make sure you bind 0 to the draw framebuffer before swapping the
window, otherwise nothing will happen. If you aren't using `glBindFramebuffer(
)`, this is the default and you won't have to do anything extra.

Expected parameters include:

- `window` - the window to change

## `SDL_GL_DeleteContext( ... )`

Delete an OpenGL context.

        SDL_GL_DeleteContext( $context );

Expected parameters include:

- `context` - the OpenGL context to be deleted

## 2D Accelerated Rendering

This category contains functions for 2D accelerated rendering. You may import
these functions with the `:render` tag.

This API supports the following features:

- single pixel points
- single pixel lines
- filled rectangles
- texture images

All of these may be drawn in opaque, blended, or additive modes.

The texture images can have an additional color tint or alpha modulation
applied to them, and may also be stretched with linear interpolation, rotated
or flipped/mirrored.

For advanced functionality like particle effects or actual 3D you should use
SDL's OpenGL/Direct3D support or one of the many available 3D engines.

This API is not designed to be used from multiple threads, see [SDL issue
\#986](https://github.com/libsdl-org/SDL/issues/986) for details.

## `SDL_GetNumRenderDrivers( )`

Get the number of 2D rendering drivers available for the current display.

        my $drivers = SDL_GetNumRenderDrivers( );

A render driver is a set of code that handles rendering and texture management
on a particular display. Normally there is only one, but some drivers may have
several available with different capabilities.

There may be none if SDL was compiled without render support.

Returns a number >= 0 on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GetRenderDriverInfo( ... )`

Get info about a specific 2D rendering driver for the current display.

        my $info = !SDL_GetRendererDriverInfo( );

Expected parameters include:

- `index` - the index of the driver to query information about

Returns an [SDL2::RendererInfo](https://metacpan.org/pod/SDL2%3A%3ARendererInfo) structure on success or a negative error code
on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more
information.

## `SDL_CreateWindowAndRenderer( ... )`

Create a window and default renderer.

        my ($window, $renderer) = SDL_CreateWindowAndRenderer(640, 480, 0);

Expected parameters include:

- `width` - the width of the window
- `height` - the height of the window
- `window_flags` - the flags used to create the window (see [`SDL_CreateWindow( ... )`](#sdl_createwindow))

Returns a [SDL2::Window](https://metacpan.org/pod/SDL2%3A%3AWindow) and [SDL2::Renderer](https://metacpan.org/pod/SDL2%3A%3ARenderer) objects on success, or -1 on
error; call [`SDL_GetError( )`](#sdl_geterror)( ) for more
information.

## `SDL_CreateRenderer( ... )`

Create a 2D rendering context for a window.

        my $renderer = SDL_CreateRenderer( $window, -1, 0);

Expected parameters include:

- `window` - the window where rendering is displayed
- `index` - the index of the rendering driver to initialize, or `-1` to initialize the first one supporting the requested flags
- `flags` - `0`, or one or more `SDL_RendererFlags` OR'd together

Returns a valid rendering context or undefined if there was an error; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_CreateSoftwareRenderer( ... )`

Create a 2D software rendering context for a surface.

        my $renderer = SDL_CreateSoftwareRenderer( $surface );

Two other API which can be used to create SDL\_Renderer:

[`SDL_CreateRenderer( ... )`](#sdl_createrenderer) and [`SDL_CreateWindowAndRenderer( ... )`](#sdl_createwindowandrenderer). These can **also** create a software renderer, but they are intended to be
used with an [SDL2::Window](https://metacpan.org/pod/SDL2%3A%3AWindow) as the final destination and not an
[SDL2::Surface](https://metacpan.org/pod/SDL2%3A%3ASurface).

Expected parameters include:

- `surface` - the [SDL2::Surface](https://metacpan.org/pod/SDL2%3A%3ASurface) structure representing the surface where rendering is done

Returns a valid rendering context or undef if there was an error; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GetRenderer( ... )`

Get the renderer associated with a window.

        my $renderer = SDL_GetRenderer( $window );

Expected parameters include:

- `window` - the window to query

Returns the rendering context on success or undef on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GetRendererInfo( ... )`

Get information about a rendering context.

        my $info = !SDL_GetRendererInfo( $renderer );

Expected parameters include:

- `renderer` - the rendering context

Returns an [SDL2::RendererInfo](https://metacpan.org/pod/SDL2%3A%3ARendererInfo) structure on success or a negative error code
on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more
information.

## `SDL_GetRendererOutputSize( ... )`

Get the output size in pixels of a rendering context.

        my ($w, $h) = SDL_GetRendererOutputSize( $renderer );

Due to high-dpi displays, you might end up with a rendering context that has
more pixels than the window that contains it, so use this instead of [`SDL_GetWindowSize( ... )`](#sdl_getwindowsize) to decide how much
drawing area you have.

Expected parameters include:

- `renderer` - the rendering context

Returns the width and height on success or a negative error code on failure;
call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_CreateTexture( ... )`

Create a texture for a rendering context.

    my $texture = SDL_CreateTexture( $renderer, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_TARGET, 1024, 768);

You can set the texture scaling method by setting
`SDL_HINT_RENDER_SCALE_QUALITY` before creating the texture.

Expected parameters include:

- `renderer` - the rendering context
- `format` - one of the enumerated values in `:pixelFormatEnum`
- `access` - one of the enumerated values in `:textureAccess`
- `w` - the width of the texture in pixels
- `h` - the height of the texture in pixels

Returns a pointer to the created texture or undefined if no rendering context
was active, the format was unsupported, or the width or height were out of
range; call [`SDL_GetError( )`](#sdl_geterror)( ) for more
information.

## `SDL_CreateTextureFromSurface( ... )`

Create a texture from an existing surface.

        use Config;
        my ($rmask, $gmask, $bmask, $amask) =
        $Config{byteorder} == 4321 ? (0xff000000,0x00ff0000,0x0000ff00,0x000000ff) :
                                                         (0x000000ff,0x0000ff00,0x00ff0000,0xff000000);
        my $surface = SDL_CreateRGBSurface( 0, 640, 480, 32, $rmask, $gmask, $bmask, $amask );
        my $texture = SDL_CreateTextureFromSurface( $renderer, $surface );

The surface is not modified or freed by this function.

The SDL\_TextureAccess hint for the created texture is
`SDL_TEXTUREACCESS_STATIC`.

The pixel format of the created texture may be different from the pixel format
of the surface. Use [`SDL_QueryTexture( ... )`](#sdl_querytexture) to query the pixel format of the texture.

Expected parameters include:

- `renderer` - the rendering context
- `surface` - the [SDL2::Surface](https://metacpan.org/pod/SDL2%3A%3ASurface) structure containing pixel data used to fill the texture

Returns the created texture or undef on failure; call [`SDL_GetError(
)`](#sdl_geterror)( ) for more information.

## `SDL_QueryTexture( ... )`

Query the attributes of a texture.

        my ( $format, $access, $w, $h ) = SDL_QueryTexture( $texture );

Expected parameters include:

- `texture` - the texture to query

Returns the following on success...

- `format` - a pointer filled in with the raw format of the texture; the
actual format may differ, but pixel transfers will use this
format (one of the [`:pixelFormatEnum`](#pixelformatenum) values)
- `access` - a pointer filled in with the actual access to the texture (one of the [`:textureAccess`](#textureaccess) values)
- `w` - a pointer filled in with the width of the texture in pixels
- `h` - a pointer filled in with the height of the texture in pixels

...or a negative error code on failure; call [`SDL_GetError(
)`](#sdl_geterror)( ) for more information.

## `SDL_SetTextureColorMod( ... )`

Set an additional color value multiplied into render copy operations.

        my $ok = !SDL_SetTextureColorMod( $texture, 64, 64, 64 );

When this texture is rendered, during the copy operation each source color
channel is modulated by the appropriate color value according to the following
formula:

        srcC = srcC * (color / 255)

Color modulation is not always supported by the renderer; it will return `-1`
if color modulation is not supported.

Expected parameters include:

- `texture` - the texture to update
- `r` - the red color value multiplied into copy operations
- `g` - the green color value multiplied into copy operations
- `b` - the blue color value multiplied into copy operations

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GetTextureColorMod( ... )`

Get the additional color value multiplied into render copy operations.

        my ( $r, $g, $b ) = SDL_GetTextureColorMod( $texture );

Expected parameters include:

- `texture` - the texture to query

Returns the current red, green, and blue color values on success or a negative
error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( )
for more information.

## `SDL_SetTextureAlphaMod( ... )`

Set an additional alpha value multiplied into render copy operations.

        SDL_SetTextureAlphaMod( $texture, 100 );

When this texture is rendered, during the copy operation the source alpha

value is modulated by this alpha value according to the following formula:

        srcA = srcA * (alpha / 255)

Alpha modulation is not always supported by the renderer; it will return `-1`
if alpha modulation is not supported.

Expected parameters include:

- `texture` - the texture to update
- `alpha` - the source alpha value multiplied into copy operations

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GetTextureAlphaMod( ... )`

Get the additional alpha value multiplied into render copy operations.

        my $alpha = SDL_GetTextureAlphaMod( $texture );

Expected parameters include:

- `texture` - the texture to query

Returns the current alpha value on success or a negative error code on failure;
call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_SetTextureBlendMode( ... )`

Set the blend mode for a texture, used by [`SDL_RenderCopy( ...
)`](#sdl_rendercopy).

If the blend mode is not supported, the closest supported mode is chosen and
this function returns `-1`.

Expected parameters include:

- `texture` - the texture to update
- `blendMode` - the [`:blendMode`](#blendmode) to use for texture blending

Returns 0 on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GetTextureBlendMode( ... )`

Get the blend mode used for texture copy operations.

        SDL_GetTextureBlendMode( $texture, SDL_BLENDMODE_ADD );

Expected parameters include:

- `texture` - the texture to query

Returns the current `:blendMode` on success or a negative error code on
failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more
information.

## `SDL_SetTextureScaleMode( ... )`

Set the scale mode used for texture scale operations.

        SDL_SetTextureScaleMode( $texture, $scaleMode );

If the scale mode is not supported, the closest supported mode is chosen.

Expected parameters include:

- `texture` - The texture to update.
- `scaleMode` - the SDL\_ScaleMode to use for texture scaling.

Returns `0` on success, or `-1` if the texture is not valid.

## `SDL_GetTextureScaleMode( ... )`

Get the scale mode used for texture scale operations.

        my $ok = SDL_GetTextureScaleMode( $texture );

Expected parameters include:

- `texture` - the texture to query.

Returns the current scale mode on success, or `-1` if the texture is not
valid.

## `SDL_UpdateTexture( ... )`

Update the given texture rectangle with new pixel data.

        my $rect = SDL2::Rect->new( { x => 0, y => ..., w => $surface->w, h => $surface->h } );
        SDL_UpdateTexture( $texture, $rect, $surface->pixels, $surface->pitch );

The pixel data must be in the pixel format of the texture. Use [`SDL_QueryTexture( ... )`](#sdl_querytexture) to query the pixel
format of the texture.

This is a fairly slow function, intended for use with static textures that do
not change often.

If the texture is intended to be updated often, it is preferred to create the
texture as streaming and use the locking functions referenced below. While this
function will work with streaming textures, for optimization reasons you may
not get the pixels back if you lock the texture afterward.

Expected parameters include:

- `texture` - the texture to update
- `rect` - an [SDL2::Rect](https://metacpan.org/pod/SDL2%3A%3ARect) structure representing the area to update, or undef to update the entire texture
- `pixels` - the raw pixel data in the format of the texture
- `pitch` - the number of bytes in a row of pixel data, including padding between lines

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_UpdateYUVTexture( ... )`

Update a rectangle within a planar YV12 or IYUV texture with new pixel data.

        SDL_UpdateYUVTexture( $texture, $rect, $yPlane, $yPitch, $uPlane, $uPitch, $vPlane, $vPitch );

You can use [`SDL_UpdateTexture( ... )`](#sdl_updatetexture) as
long as your pixel data is a contiguous block of Y and U/V planes in the proper
order, but this function is available if your pixel data is not contiguous.

Expected parameters include:

- `texture` - the texture to update
- `rect` - a pointer to the rectangle of pixels to update, or undef to update the entire texture
- `Yplane` - the raw pixel data for the Y plane
- `Ypitch` - the number of bytes between rows of pixel data for the Y plane
- `Uplane` - the raw pixel data for the U plane
- `Upitch` - the number of bytes between rows of pixel data for the U plane
- `Vplane` - the raw pixel data for the V plane
- `Vpitch` - the number of bytes between rows of pixel data for the V plane

Returns `0` on success or -1 if the texture is not valid; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_UpdateNVTexture( ... )`

Update a rectangle within a planar NV12 or NV21 texture with new pixels.

        SDL_UpdateNVTexture( $texture, $rect, $yPlane, $yPitch, $uPlane, $uPitch );

You can use [`SDL_UpdateTexture( ... )`](#sdl_updatetexture) as
long as your pixel data is a contiguous block of NV12/21 planes in the proper
order, but this function is available if your pixel data is not contiguous.

Expected parameters include:

- `texture` - the texture to update
- `rect` - a pointer to the rectangle of pixels to update, or undef to update the entire texture.
- `Yplane` - the raw pixel data for the Y plane.
- `Ypitch` - the number of bytes between rows of pixel data for the Y plane.
- `UVplane` - the raw pixel data for the UV plane.
- `UVpitch` - the number of bytes between rows of pixel data for the UV plane.

Returns `0` on success, or `-1` if the texture is not valid.

## `SDL_LockTexture( ... )`

Lock a portion of the texture for **write-only** pixel access.

        SDL_LockTexture( $texture, $rect, $pixels, $pitch );

As an optimization, the pixels made available for editing don't necessarily
contain the old texture data. This is a write-only operation, and if you need
to keep a copy of the texture data you should do that at the application level.

You must use [`SDL_UpdateTexture( ... )`](#sdl_updatetexture) to
unlock the pixels and apply any changes.

Expected parameters include:

- `texture` - the texture to lock for access, which was created with `SDL_TEXTUREACCESS_STREAMING`
- `rect` - an [SDL2::Rect](https://metacpan.org/pod/SDL2%3A%3ARect) structure representing the area to lock for access; undef to lock the entire texture
- `pixels` - this is filled in with a pointer to the locked pixels, appropriately offset by the locked area
- `pitch` - this is filled in with the pitch of the locked pixels; the pitch is the length of one row in bytes

Returns 0 on success or a negative error code if the texture is not valid or
was not created with \`SDL\_TEXTUREACCESS\_STREAMING\`; call [`SDL_GetError(
)`](#sdl_geterror)( ) for more information.

## `SDL_LockTextureToSurface( ... )`

Lock a portion of the texture for **write-only** pixel access, and expose it as
a SDL surface.

        my $surface = SDL_LockTextureSurface( $texture, $rect );

Besides providing an [SDL2::Surface](https://metacpan.org/pod/SDL2%3A%3ASurface) instead of raw pixel data, this function
operates like [SDL2::LockTexture](https://metacpan.org/pod/SDL2%3A%3ALockTexture).

As an optimization, the pixels made available for editing don't necessarily
contain the old texture data. This is a write-only operation, and if you need
to keep a copy of the texture data you should do that at the application level.

You must use [`SDL_UnlockTexture( ... )`](#sdl_unlocktexture) to
unlock the pixels and apply any changes.

The returned surface is freed internally after calling [`SDL_UnlockTexture(
... )`](#sdl_unlocktexture) or [`SDL_DestroyTexture( ...
)`](#sdl_destroytexture). The caller should not free it.

Expected parameters include:

- `texture` - the texture to lock for access, which was created with `SDL_TEXTUREACCESS_STREAMING`
- `rect` - a pointer to the rectangle to lock for access. If the rect is undef, the entire texture will be locked

Returns the [SDL2::Surface](https://metacpan.org/pod/SDL2%3A%3ASurface) structure on success, or `-1` if the texture is
not valid or was not created with `SDL_TEXTUREACCESS_STREAMING`.

## `SDL_UnlockTexture( ... )`

Unlock a texture, uploading the changes to video memory, if needed.

        SDL_UnlockTexture( $texture );

**Warning**: Please note that [`SDL_LockTexture( ... )`](#sdl_locktexture) is intended to be write-only; it will not guarantee the previous
contents of the texture will be provided. You must fully initialize any area of
a texture that you lock before unlocking it, as the pixels might otherwise be
uninitialized memory.

Which is to say: locking and immediately unlocking a texture can result in
corrupted textures, depending on the renderer in use.

Expected parameters include:

- `texture` - a texture locked by [`SDL_LockTexture( ... )`](#sdl_locktexture)

## `SDL_RenderTargetSupported( ... )`

Determine whether a renderer supports the use of render targets.

        my $bool = SDL_RenderTargetSupported( $renderer );

Expected parameters include:

- `renderer` - the renderer that will be checked

Returns true if supported or false if not.

## `SDL_SetRenderTarget( ... )`

Set a texture as the current rendering target.

        SDL_SetRenderTarget( $renderer, $texture );

Before using this function, you should check the `SDL_RENDERER_TARGETTEXTURE`
bit in the flags of [SDL2::RendererInfo](https://metacpan.org/pod/SDL2%3A%3ARendererInfo) to see if render targets are
supported.

The default render target is the window for which the renderer was created. To
stop rendering to a texture and render to the window again, call this function
with a undefined `texture`.

Expected parameters include:

- `renderer` - the rendering context
- `texture` - the targeted texture, which must be created with the `SDL_TEXTUREACCESS_TARGET` flag, or undef to render to the window instead of a texture.

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GetRenderTarget( ... )`

Get the current render target.

        my $texture = SDL_GetRenderTarget( $renderer );

The default render target is the window for which the renderer was created, and
is reported an undefined value here.

Expected parameters include:

- `renderer` - the rendering context

Returns the current render target or undef for the default render target.

## `SDL_RenderSetLogicalSize( ... )`

Set a device independent resolution for rendering.

        SDL_RenderSetLogicalSize( $renderer, 100, 100 );

This function uses the viewport and scaling functionality to allow a fixed
logical resolution for rendering, regardless of the actual output resolution.
If the actual output resolution doesn't have the same aspect ratio the output
rendering will be centered within the output display.

If the output display is a window, mouse and touch events in the window will be
filtered and scaled so they seem to arrive within the logical resolution.

If this function results in scaling or subpixel drawing by the rendering
backend, it will be handled using the appropriate quality hints.

Expected parameters include:

- `renderer` - the renderer for which resolution should be set
- `w` - the width of the logical resolution
- `h` - the height of the logical resolution

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_RenderGetLogicalSize( ... )`

Get device independent resolution for rendering.

        my ($w, $h) = SDL_RenderGetLogicalSize( $renderer );

This may return `0` for `w` and `h` if the [SDL2::Renderer](https://metacpan.org/pod/SDL2%3A%3ARenderer) has never had
its logical size set by [`SDL_RenderSetLogicalSize( ...
)`](#sdl_rendersetlogicalsize) and never had a render target set.

Expected parameters include:

- `renderer` - a rendering context

Returns the width and height.

## `SDL_RenderSetIntegerScale( ... )`

Set whether to force integer scales for resolution-independent rendering.

        SDL_RenderSetIntegerScale( $renderer, 1 );

This function restricts the logical viewport to integer values - that is, when
a resolution is between two multiples of a logical size, the viewport size is
rounded down to the lower multiple.

Expected parameters include:

- `renderer` - the renderer for which integer scaling should be set
- `enable` - enable or disable the integer scaling for rendering

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_RenderGetIntegerScale( ... )`

Get whether integer scales are forced for resolution-independent rendering.

        SDL_RenderGetIntegerScale( $renderer );

Expected parameters include:

- `renderer` - the renderer from which integer scaling should be queried

Returns true if integer scales are forced or false if not and on failure; call
[`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_RenderSetViewport( ... )`

Set the drawing area for rendering on the current target.

        SDL_RenderSetViewport( $renderer, $rect );

When the window is resized, the viewport is reset to fill the entire new window
size.

Expected parameters include:

- `renderer` - the rendering context
- `rect` - the [SDL2::Rect](https://metacpan.org/pod/SDL2%3A%3ARect) structure representing the drawing area, or undef to set the viewport to the entire target

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_RenderGetViewport( ... )`

Get the drawing area for the current target.

        my $rect = SDL_RenderGetViewport( $renderer );

Expected parameters include:

- `renderer` - the rendering context

Returns an [SDL2::Rect](https://metacpan.org/pod/SDL2%3A%3ARect) structure filled in with the current drawing area.

## `SDL_RenderSetClipRect( ... )`

Set the clip rectangle for rendering on the specified target.

        SDL_RenderSetClipRect( $renderer, $rect );

Expected parameters include:

- `renderer` - the rendering context for which clip rectangle should be set
- `rect` - an [SDL2::Rect](https://metacpan.org/pod/SDL2%3A%3ARect) structure representing the clip area, relative to the viewport, or undef to disable clipping

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_RenderGetClipRect( ... )`

Get the clip rectangle for the current target.

        my $rect = SDL_RenderGetClipRect( $renderer );

Expected parameters include:

- `renderer` - the rendering context from which clip rectangle should be queried

Returns an [SDL2::Rect](https://metacpan.org/pod/SDL2%3A%3ARect) structure filled in with the current clipping area or
an empty rectangle if clipping is disabled.

## `SDL_RenderIsClipEnabled( ... )`

Get whether clipping is enabled on the given renderer.

        my $tf = SDL_RenderIsClipEnabled( $renderer );

Expected parameters include:

- `renderer` - the renderer from which clip state should be queried

Returns true if clipping is enabled or false if not; call [`SDL_GetError(
)`](#sdl_geterror)( ) for more information.

## `SDL_RenderSetScale( ... )`

Set the drawing scale for rendering on the current target.

        SDL_RenderSetScale( $renderer, .5, 1 );

The drawing coordinates are scaled by the x/y scaling factors before they are
used by the renderer. This allows resolution independent drawing with a single
coordinate system.

If this results in scaling or subpixel drawing by the rendering backend, it
will be handled using the appropriate quality hints. For best results use
integer scaling factors.

Expected parameters include:

- `renderer` - a rendering context
- `scaleX` - the horizontal scaling factor
- `scaleY` - the vertical scaling factor

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_RenderGetScale( ... )`

Get the drawing scale for the current target.

        my ($scaleX, $scaleY) = SDL_RenderGetScale( $renderer );

Expected parameters include:

- `renderer` - the renderer from which drawing scale should be queried

Returns the horizonal and vertical scaling factors.

## `SDL_SetRenderDrawColor( ... )`

Set the color used for drawing operations (Rect, Line and Clear).

        SDL_SetRenderDrawColor( $renderer, 0, 0, 128, SDL_ALPHA_OPAQUE );

Set the color for drawing or filling rectangles, lines, and points, and for [`SDL_RenderClear( ... )`](#sdl_renderclear).

Expected parameters include:

- `renderer` - the rendering context
- `r` - the red value used to draw on the rendering target
- `g` - the green value used to draw on the rendering target
- `b` - the blue value used to draw on the rendering target
- `a` - the alpha value used to draw on the rendering target; usually `SDL_ALPHA_OPAQUE` (255). Use `SDL_SetRenderDrawBlendMode` to specify how the alpha channel is used

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GetRenderDrawColor( ... )`

Get the color used for drawing operations (Rect, Line and Clear).

        my ($r, $g, $b, $a) = SDL_GetRenderDrawColor( $renderer );

Expected parameters include:

- `renderer` - the rendering context

Returns red, green, blue, and alpha values on success or a negative error code
on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more
information.

## `SDL_SetRenderDrawBlendMode( ... )`

Set the blend mode used for drawing operations (Fill and Line).

        SDL_SetRenderDrawBlendMode( $renderer, SDL_BLENDMODE_BLEND );

If the blend mode is not supported, the closest supported mode is chosen.

Expected parameters include:

- `renderer` - the rendering context
- `blendMode` - the [`:blendMode`](#blendmode) to use for blending

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GetRenderDrawBlendMode( ... )`

Get the blend mode used for drawing operations.

        my $blendMode = SDL_GetRenderDrawBlendMode( $rendering );

Expected parameters include:

- `renderer` - the rendering context

Returns the current `:blendMode` on success or a negative error code on
failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more
information.

## `SDL_RenderClear( ... )`

Clear the current rendering target with the drawing color.

        SDL_RenderClear( $renderer );

This function clears the entire rendering target, ignoring the viewport and the
clip rectangle.

- `renderer` - the rendering context

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_RenderDrawPoint( ... )`

Draw a point on the current rendering target.

        SDL_RenderDrawPoint( $renderer, 100, 100 );

`SDL_RenderDrawPoint( ... )` draws a single point. If you want to draw
multiple, use [`SDL_RenderDrawPoints( ... )`](#sdl_renderdrawpoints) instead.

Expected parameters include:

- `renderer` - the rendering context
- `x` - the x coordinate of the point
- `y` - the y coordinate of the point

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_RenderDrawPoints( ... )`

Draw multiple points on the current rendering target.

        my @points = map { SDL2::Point->new( {x => int rand, y => int rand } ) } 1..1024;
        SDL_RenderDrawPoints( $renderer, @points );

- `renderer` - the rendering context
- `points` - an array of [SDL2::Point](https://metacpan.org/pod/SDL2%3A%3APoint) structures that represent the points to draw

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_RenderDrawLine( ... )`

Draw a line on the current rendering target.

        SDL_RenderDrawLine( $renderer, 300, 240, 340, 240 );

`SDL_RenderDrawLine( ... )` draws the line to include both end points. If you
want to draw multiple, connecting lines use [`SDL_RenderDrawLines( ...
)`](#sdl_renderdrawlines) instead.

Expected parameters include:

- `renderer` - the rendering context
- `x1` - the x coordinate of the start point
- `y1` - the y coordinate of the start point
- `x2` - the x coordinate of the end point
- `y2` - the y coordinate of the end point

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_RenderDrawLines( ... )`

Draw a series of connected lines on the current rendering target.

        SDL_RenderDrawLines( $renderer, @points);

Expected parameters include:

- `renderer` - the rendering context
- `points` - an array of [SDL2::Point](https://metacpan.org/pod/SDL2%3A%3APoint) structures representing points along the lines

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_RenderDrawRect( ... )`

Draw a rectangle on the current rendering target.

        SDL_RenderDrawRect( $renderer, SDL2::Rect->new( { x => 100, y => 100, w => 100, h => 100 } ) );

Expected parameters include:

- `renderer` - the rendering context
- `rect` - an [SDL2::Rect](https://metacpan.org/pod/SDL2%3A%3ARect) structure representing the rectangle to draw

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_RenderDrawRects( ... )`

Draw some number of rectangles on the current rendering target.

        SDL_RenderDrawRects( $renderer,
                SDL2::Rect->new( { x => 100, y => 100, w => 100, h => 100 } ),
        SDL2::Rect->new( { x => 75,  y => 75,  w => 50,  h => 50 } )
    );

Expected parameters include:

- `renderer` - the rendering context
- `rects` - an array of SDL2::Rect structures representing the rectangles to be drawn

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_RenderFillRect( ... )`

Fill a rectangle on the current rendering target with the drawing color.

        SDL_RenderFillRect( $renderer, SDL2::Rect->new( { x => 100, y => 100, w => 100, h => 100 } ) );

The current drawing color is set by [`SDL_SetRenderDrawColor( ...
)`](#sdl_setrenderdrawcolor), and the color's alpha value is ignored
unless blending is enabled with the appropriate call to [`SDL_SetRenderDrawBlendMode( ... )`](#sdl_setrenderdrawblendmode).

Expected parameters include:

- `renderer` - the rendering context
- `rect` - the [SDL2::Rect](https://metacpan.org/pod/SDL2%3A%3ARect) structure representing the rectangle to fill

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_RenderFillRects( ... )`

Fill some number of rectangles on the current rendering target with the drawing
color.

        SDL_RenderFillRects( $renderer,
                SDL2::Rect->new( { x => 100, y => 100, w => 100, h => 100 } ),
        SDL2::Rect->new( { x => 75,  y => 75,  w => 50,  h => 50 } )
    );

Expected parameters include:

- `renderer` - the rendering context
- `rects` - an array of [SDL2::Rect](https://metacpan.org/pod/SDL2%3A%3ARect) structures representing the rectangles to be filled

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_RenderCopy( ... )`

Copy a portion of the texture to the current rendering target.

        SDL_RenderCopy( $renderer, $blueShapes, $srcR, $destR );

The texture is blended with the destination based on its blend mode set with
[`SDL_SetTextureBlendMode( ... )`](#sdl_settextureblendmode).

The texture color is affected based on its color modulation set by [`SDL_SetTextureColorMod( ... )`](#sdl_settexturecolormod).

The texture alpha is affected based on its alpha modulation set by [`SDL_SetTextureAlphaMod( ... )`](#sdl_settexturealphamod).

Expected parameters include:

- `renderer` - the rendering context
- `texture` - the source texture
- `srcrect` - the source [SDL2::Rect](https://metacpan.org/pod/SDL2%3A%3ARect) structure
- `dstrect` - the destination [SDL2::Rect](https://metacpan.org/pod/SDL2%3A%3ARect) structure; the texture will be stretched to fill the given rectangle

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_RenderCopyEx( ... )`

Copy a portion of the texture to the current rendering, with optional rotation
and flipping.

Copy a portion of the texture to the current rendering target, optionally
rotating it by angle around the given center and also flipping it top-bottom
and/or left-right.

The texture is blended with the destination based on its blend mode set with
[`SDL_SetTextureBlendMode( ... )`](#sdl_settextureblendmode).

The texture color is affected based on its color modulation set by [`SDL_SetTextureColorMod( ... )`](#sdl_settexturecolormod).

The texture alpha is affected based on its alpha modulation set by [`SDL_SetTextureAlphaMod( ... )`](#sdl_settexturealphamod).

Expected parameters include:

- `renderer` - the rendering context
- `texture` - the source texture
- `srcrect` - the source [SDL2::Rect](https://metacpan.org/pod/SDL2%3A%3ARect) structure
- `dstrect` - the destination SDL\_Rect structure
- `angle` - an angle in degrees that indicates the rotation that will be applied to dstrect, rotating it in a clockwise direction
- `center` - a pointer to a point indicating the point around which dstrect will be rotated (if NULL, rotation will be done around `dstrect.w / 2`, `dstrect.h / 2`)
- `flip` - a [:rendererFlip](https://metacpan.org/pod/%3ArendererFlip) value stating which flipping actions should be performed on the texture

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_RenderDrawPointF( ... )`

Draw a point on the current rendering target at subpixel precision.

        SDL_RenderDrawPointF( $renderer, 25.5, 100.25 );

Expected parameters include:

- `renderer` - The renderer which should draw a point.
- `x` - The x coordinate of the point.
- `y` - The y coordinate of the point.

Returns `0` on success, or `-1` on error

## `SDL_RenderDrawPointsF( ... )`

Draw multiple points on the current rendering target at subpixel precision.

        my @points = map { SDL2::Point->new( {x => int rand, y => int rand } ) } 1..1024;
        SDL_RenderDrawPointsF( $renderer, @points );

Expected parameters include:

- `renderer` - The renderer which should draw multiple points
- `points` - The points to draw

Returns `0` on success, or `-1` on error; call [`SDL_GetError(
)`](#sdl_geterror)( ) for more information.

## `SDL_RenderDrawLineF( ... )`

Draw a line on the current rendering target at subpixel precision.

        SDL_RenderDrawLineF( $renderer, 100, 100, 250, 100);

Expected parameters include:

- `renderer` - The renderer which should draw a line.
- `x1` - The x coordinate of the start point.
- `y1` - The y coordinate of the start point.
- `x2` - The x coordinate of the end point.
- `y2` - The y coordinate of the end point.

Returns `0` on success, or `-1` on error.

## `SDL_RenderDrawLinesF( ... )`

Draw a series of connected lines on the current rendering target at subpixel
precision.

        SDL_RenderDrawLines( $renderer, @points);

Expected parameters include:

- `renderer` - The renderer which should draw multiple lines.
- `points` - The points along the lines

Return `0` on success, or `-1` on error.

## `SDL_RenderDrawRectF( ... )`

Draw a rectangle on the current rendering target at subpixel precision.

        SDL_RenderDrawRectF( $renderer, $point);

Expected parameters include:

- `renderer` - The renderer which should draw a rectangle.
- `rect` - A pointer to the destination rectangle

Returns `0` on success, or `-1` on error

## `SDL_RenderDrawRectsF( ... )`

Draw some number of rectangles on the current rendering target at subpixel
precision.

        SDL_RenderDrawRectsF( $renderer,
                SDL2::Rect->new( { x => 100, y => 100, w => 100, h => 100 } ),
        SDL2::Rect->new( { x => 75,  y => 75,  w => 50,  h => 50 } )
    );

Expected parameters include:

- `renderer` - The renderer which should draw multiple rectangles.
- `rects` - A pointer to an array of destination rectangles.

Returns `0` on success, or `-1` on error.

## `SDL_RenderFillRectF( ... )`

Fill a rectangle on the current rendering target with the drawing color at
subpixel precision.

        SDL_RenderFillRectF( $renderer,
        SDL2::Rect->new( { x => 75,  y => 75,  w => 50,  h => 50 } )
    );

Expected parameters include:

- `renderer` - The renderer which should fill a rectangle.
- `rect` - A pointer to the destination rectangle

Returns `0` on success, or `-1` on error.

## `SDL_RenderFillRectsF( ... )`

Fill some number of rectangles on the current rendering target with the drawing
color at subpixel precision.

        SDL_RenderFillRectsF( $renderer,
                SDL2::Rect->new( { x => 100, y => 100, w => 100, h => 100 } ),
        SDL2::Rect->new( { x => 75,  y => 75,  w => 50,  h => 50 } )
    );

Expected parameters include:

- `renderer` - The renderer which should fill multiple rectangles.
- `rects` - A pointer to an array of destination rectangles.

Returns `0` on success, or `-1` on error.

## `SDL_RenderCopyF( ... )`

Copy a portion of the texture to the current rendering target at subpixel
precision.

Expected parameters include:

- `renderer` - The renderer which should copy parts of a texture
- `texture` - The source texture
- `srcrect` - A pointer to the source rectangle
- `dstrect` - A pointer to the destination rectangle

Returns `0` on success, or `-1` on error.

## `SDL_RenderCopyExF( ... )`

Copy a portion of the source texture to the current rendering target, with
rotation and flipping, at subpixel precision.

- `renderer` - The renderer which should copy parts of a texture
- `texture` - The source texture
- `srcrect` - A pointer to the source rectangle
- `dstrect` - A pointer to the destination rectangle
- `angle` - An angle in degrees that indicates the rotation that will be applied to dstrect, rotating it in a clockwise direction
- `center` - A pointer to a point indicating the point around which dstrect will be rotated (if NULL, rotation will be done around `dstrect.w/2`, `dstrect.h/2`)
- `flip` - A `:rendererFlip` value stating which flipping actions should be performed on the texture

Returns `0` on success, or `-1` on error

## `SDL_RenderReadPixels( ... )`

Read pixels from the current rendering target to an array of pixels.

        SDL_RenderReadPixels(
        $renderer,
        SDL2::Rect->new( { x => 0, y => 0, w => 640, h => 480 } ),
        SDL_PIXELFORMAT_RGB888,
        $surface->pixels, $surface->pitch
    );

**WARNING**: This is a very slow operation, and should not be used frequently.

`pitch` specifies the number of bytes between rows in the destination
`pixels` data. This allows you to write to a subrectangle or have padded rows
in the destination. Generally, `pitch` should equal the number of pixels per
row in the \`pixels\` data times the number of bytes per pixel, but it might
contain additional padding (for example, 24bit RGB Windows Bitmap data pads all
rows to multiples of 4 bytes).

Expected parameters include:

- `renderer` - the rendering context
- `rect` - an [SDL2::Rect](https://metacpan.org/pod/SDL2%3A%3ARect) structure representing the area to read
- `format` - an `:pixelFormatEnum` value of the desired format of the pixel data, or `0` to use the format of the rendering target
- `pixels` - pointer to the pixel data to copy into
- `pitch` - the pitch of the `pixels` parameter

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_RenderPresent( ... )`

Update the screen with any rendering performed since the previous call.

        SDL_RenderPresent( $renderer );

SDL's rendering functions operate on a backbuffer; that is, calling a rendering
function such as [`SDL_RenderDrawLine( ... )`](#sdl_renderdrawline) does not directly put a line on the screen, but rather updates the
backbuffer. As such, you compose your entire scene and \*present\* the composed
backbuffer to the screen as a complete picture.

Therefore, when using SDL's rendering API, one does all drawing intended for
the frame, and then calls this function once per frame to present the final
drawing to the user.

The backbuffer should be considered invalidated after each present; do not
assume that previous contents will exist between frames. You are strongly
encouraged to call [`SDL_RenderClear( ... )`](#sdl_renderclear)
to initialize the backbuffer before starting each new frame's drawing, even if
you plan to overwrite every pixel.

Expected parameters include:

- `renderer` - the rendering context

## `SDL_DestroyTexture( ... )`

Destroy the specified texture.

        SDL_DestroyTexture( $texture );

Passing undef or an otherwise invalid texture will set the SDL error message to
"Invalid texture".

Expected parameters include:

- `texture` - the texture to destroy

## `SDL_DestroyRenderer( ... )`

Destroy the rendering context for a window and free associated textures.

        SDL_DestroyRenderer( $renderer );

Expected parameters include:

- `renderer` - the rendering context

## `SDL_RenderFlush( ... )`

Force the rendering context to flush any pending commands to the underlying
rendering API.

        SDL_RenderFlush( $renderer );

You do not need to (and in fact, shouldn't) call this function unless you are
planning to call into OpenGL/Direct3D/Metal/whatever directly in addition to
using an SDL\_Renderer.

This is for a very-specific case: if you are using SDL's render API, you asked
for a specific renderer backend (OpenGL, Direct3D, etc), you set
`SDL_HINT_RENDER_BATCHING` to "`1`", and you plan to make OpenGL/D3D/whatever
calls in addition to SDL render API calls. If all of this applies, you should
call [`SDL_RenderFlush( ... )`](#sdl_renderflush) between calls
to SDL's render API and the low-level API you're using in cooperation.

In all other cases, you can ignore this function. This is only here to get
maximum performance out of a specific situation. In all other cases, SDL will
do the right thing, perhaps at a performance loss.

This function is first available in SDL 2.0.10, and is not needed in 2.0.9 and
earlier, as earlier versions did not queue rendering commands at all, instead
flushing them to the OS immediately.

Expected parameters include:

- `renderer` - the rendering context

Returns `0` on success or a negative error code on failure; call [`SDL_GetError( )`](#sdl_geterror)( ) for more information.

## `SDL_GL_BindTexture( ... )`

Bind an OpenGL/ES/ES2 texture to the current context.

        my ($texw, $texh) = SDL_GL_BindTexture( $texture );

This is for use with OpenGL instructions when rendering OpenGL primitives
directly.

If not NULL, the returned width and height values suitable for the provided
texture. In most cases, both will be `1.0`, however, on systems that support
the GL\_ARB\_texture\_rectangle extension, these values will actually be the pixel
width and height used to create the texture, so this factor needs to be taken
into account when providing texture coordinates to OpenGL.

You need a renderer to create an [SDL2::Texture](https://metacpan.org/pod/SDL2%3A%3ATexture), therefore you can only use
this function with an implicit OpenGL context from [`SDL_CreateRenderer(
... )`](#sdl_createrenderer), not with your own OpenGL context. If
you need control over your OpenGL context, you need to write your own
texture-loading methods.

Also note that SDL may upload RGB textures as BGR (or vice-versa), and re-order
the color channels in the shaders phase, so the uploaded texture may have
swapped color channels.

Expected parameters include:

- `texture` - the texture to bind to the current OpenGL/ES/ES2 context

Returns the texture's with and height on success, or -1 if the operation is not
supported; call [`SDL_GetError( )`](#sdl_geterror)( ) for more
information.

## `SDL_GL_UnbindTexture( ... )`

Unbind an OpenGL/ES/ES2 texture from the current context.

        SDL_GL_UnbindTexture( $texture );

See [`SDL_GL_BindTexture( ... )`](#sdl_gl_bindtexture) for
examples on how to use these functions.

Expected parameters include:

- `texture` - the texture to unbind from the current OpenGL/ES/ES2 context

Returns `0` on success, or `-1` if the operation is not supported.

## `SDL_RenderGetMetalLayer( ... )`

Get the CAMetalLayer associated with the given Metal renderer.

        my $opaque = SDL_RenderGetMetalLayer( $renderer );

This function returns `void *`, so SDL doesn't have to include Metal's
headers, but it can be safely cast to a `CAMetalLayer *`.

Expected parameters include:

- `renderer` - the renderer to query

Returns `CAMetalLayer*` on success, or undef if the renderer isn't a Metal
renderer.

## `SDL_RenderGetMetalCommandEncoder( ... )`

Get the Metal command encoder for the current frame

        $opaque = SDL_RenderGetMetalCommandEncoder( $renderer );

This function returns `void *`, so SDL doesn't have to include Metal's
headers, but it can be safely cast to an
`id<MTLRenderCommandEncoder>`.

Expected parameters include:

- `renderer` - the renderer to query

Returns `id<MTLRenderCommandEncoder>` on success, or undef if the
renderer isn't a Metal renderer.

## `SDL_ComposeCustomBlendMode( ... )`

Compose a custom blend mode for renderers.

The functions SDL\_SetRenderDrawBlendMode and SDL\_SetTextureBlendMode accept the
SDL\_BlendMode returned by this function if the renderer supports it.

A blend mode controls how the pixels from a drawing operation (source) get
combined with the pixels from the render target (destination). First, the
components of the source and destination pixels get multiplied with their blend
factors. Then, the blend operation takes the two products and calculates the
result that will get stored in the render target.

Expressed in pseudocode, it would look like this:

        my $dstRGB = colorOperation( $srcRGB * $srcColorFactor, $dstRGB * $dstColorFactor );
        my $dstA   = alphaOperation( $srcA * $srcAlphaFactor, $dstA * $dstAlphaFactor );

Where the functions `colorOperation(src, dst)` and `alphaOperation(src, dst)`
can return one of the following:

- `src + dst`
- `src - dst`
- `dst - src`
- `min(src, dst)`
- `max(src, dst)`

The red, green, and blue components are always multiplied with the first,
second, and third components of the SDL\_BlendFactor, respectively. The fourth
component is not used.

The alpha component is always multiplied with the fourth component of the [`:blendFactor`](#blendfactor). The other components are not used in the
alpha calculation.

Support for these blend modes varies for each renderer. To check if a specific
[`:blendMode`](#blendmode) is supported, create a renderer and pass it
to either `SDL_SetRenderDrawBlendMode` or `SDL_SetTextureBlendMode`. They
will return with an error if the blend mode is not supported.

This list describes the support of custom blend modes for each renderer in SDL
2.0.6. All renderers support the four blend modes listed in the [`:blendMode`](#blendmode) enumeration.

- **direct3d** - Supports `SDL_BLENDOPERATION_ADD` with all factors.
- **direct3d11** - Supports all operations with all factors. However, some factors produce unexpected results with `SDL_BLENDOPERATION_MINIMUM` and `SDL_BLENDOPERATION_MAXIMUM`.
- **opengl** - Supports the `SDL_BLENDOPERATION_ADD` operation with all factors. OpenGL versions 1.1, 1.2, and 1.3 do not work correctly with SDL 2.0.6.
- **opengles** - Supports the `SDL_BLENDOPERATION_ADD` operation with all factors. Color and alpha factors need to be the same. OpenGL ES 1 implementation specific: May also support `SDL_BLENDOPERATION_SUBTRACT` and `SDL_BLENDOPERATION_REV_SUBTRACT`. May support color and alpha operations being different from each other. May support color and alpha factors being different from each other.
- **opengles2** - Supports the `SDL_BLENDOPERATION_ADD`, `SDL_BLENDOPERATION_SUBTRACT`, `SDL_BLENDOPERATION_REV_SUBTRACT` operations with all factors.
- **psp** - No custom blend mode support.
- **software** - No custom blend mode support.

Some renderers do not provide an alpha component for the default render target.
The `SDL_BLENDFACTOR_DST_ALPHA` and `SDL_BLENDFACTOR_ONE_MINUS_DST_ALPHA`
factors do not have an effect in this case.

Expected parameters include:

- `srcColorFactor` -the `:blendFactor` applied to the red, green, and blue components of the source pixels
- `dstColorFactor` - the `:blendFactor` applied to the red, green, and blue components of the destination pixels
- `colorOperation` - the `:blendOperation` used to combine the red, green, and blue components of the source and destination pixels
- `srcAlphaFactor` - the `:blendFactor` applied to the alpha component of the source pixels
- `dstAlphaFactor` - the `:blendFactor` applied to the alpha component of the destination pixels
- `alphaOperation` - the `:blendOperation` used to combine the alpha component of the source and destination pixels

Returns a `:blendMode` that represents the chosen factors and operations.

# Time Management Routines

This section contains functions for handling the SDL time management routines.
They may be imported with the `:timer` tag.

## `SDL_GetTicks( )`

Get the number of milliseconds since SDL library initialization.

        my $time = SDL_GetTicks( );

This value wraps if the program runs for more than `~49` days.

Returns an unsigned 32-bit value representing the number of milliseconds since
the SDL library initialized.

## `SDL_GetPerformanceCounter( )`

Get the current value of the high resolution counter.

        my $high_timer = SDL_GetPerformanceCounter( );

This function is typically used for profiling.

The counter values are only meaningful relative to each other. Differences
between values can be converted to times by using [`SDL_GetPerformanceFrequency( )`](#sdl_getperformancefrequency).

Returns the current counter value.

## `SDL_GetPerformanceFrequency( ... )`

Get the count per second of the high resolution counter.

        my $hz = SDL_GetPerformanceFrequency( );

Returns a platform-specific count per second.

## `SDL_Delay( ... )`

Wait a specified number of milliseconds before returning.

        SDL_Delay( 1000 );

This function waits a specified number of milliseconds before returning. It
waits at least the specified time, but possibly longer due to OS scheduling.

Expected parameters include:

- `ms` - the number of milliseconds to delay

## `SDL_AddTimer( ... )`

Call a callback function at a future time.

    my $id = SDL_AddTimer( 1000, sub ( $interval, $data ) { warn 'ping!'; $interval; } );

If you use this function, you must pass `SDL_INIT_TIMER` to [`SDL_Init(
... )`](#sdl_init).

The callback function is passed the current timer interval and returns the next
timer interval. If the returned value is the same as the one passed in, the
periodic alarm continues, otherwise a new alarm is scheduled. If the callback
returns `0`, the periodic alarm is cancelled.

The callback is run on a separate thread.

Timers take into account the amount of time it took to execute the callback.
For example, if the callback took 250 ms to execute and returned 1000 (ms), the
timer would only wait another 750 ms before its next iteration.

Timing may be inexact due to OS scheduling. Be sure to note the current time
with [`SDL_GetTicks( )`](#sdl_getticks) or  [`SDL_GetPerformanceCounter( )`](#sdl_getperformancecounter) in case
your callback needs to adjust for variances.

Expected parameters include:

- `interval` - the timer delay, in milliseconds, passed to `callback`
- `callback` - the `CODE` reference to call when the specified `interval` elapses
- `param` - a pointer that is passed to `callback`

Returns a timer ID or `0` if an error occurs; call [`SDL_GetError(
)`](#sdl_geterror)( ) for more information.

## `SDL_RemoveTimer( ... )`

        SDL_RemoveTimer( $id );

Remove a timer created with [`SDL_AddTimer( ... )`](#sdl_addtimer).

Expected parameters include:

- `id` - the ID of the timer to remove

Returns true if the timer is removed or false if the timer wasn't found.

# Touch Event Handling

This section contains functions for handling the SDL touch event routines. They
may be imported with the `:touch` tag.

## `SDL_GetNumTouchDevices( )`

Get the number of registered touch devices.

    my $count = SDL_GetNumTouchDevices();

On some platforms SDL first sees the touch device if it was actually used.
Therefore `SDL_GetNumTouchDevices( )` may return `0` although devices are
available. After using all devices at least once the number will be correct.

## `SDL_GetTouchDevice( ... )`

Get the touch ID with the given index.

    my $tID = SDL_GetTouchDevice( 0 );

Expected parameters include:

- `index` - the touch device index

Returns the touch ID with the given index on success or `0` if the index is
invalid; call [`SDL_GetError( )`](#sdl_geterror) for more
information.

## `SDL_GetTouchDeviceType( ... )`

Get the type of the given touch device.

        my $type = SDL_GetTouchDeviceType( 0 );

Expected parameters include:

- `touchID` - the touch device ID

Returns the `SDL_TouchDeviceType`.

## `SDL_GetNumTouchFingers( ... )`

Get the number of active fingers for a given touch device.

        my $fingers = SDL_GetNumTouchFingers( 0 );

Expected parameters include:

- `touchID` - the touch device ID

Returns the number of active fingers for a given touch device on success or
`0` on failure; call [`SDL_GetError( )`](#sdl_geterror) for more
information.

## `SDL_GetTouchFinger( ... )`

Get the finger object for specified touch device ID and finger index.

        my $finger = SDL_GetTouchFinger( 0, 1 );

Expected parameters include:

- `touchID` - the ID of the requested touch device
- `index` - the index of the requested finger

Returns an [SDL2::Finger](https://metacpan.org/pod/SDL2%3A%3AFinger) object on success or `undef` if no object at the
given ID and index could be found.

# Raw Audio Mixing

These methods provide access to the raw audio mixing buffer for the SDL
library. They may be imported with the `:audio` tag.

## `SDL_GetNumAudioDrivers( )`

Returns a list of built in audio drivers, in the order that they were normally
initialized by default.

## `SDL_GetAudioDriver( ... )`

Returns an audio driver by name.

        my $driver = SDL_GetAudioDriver( 1 );

Expected parameters include:

- `index` - The zero-based index of the desired audio driver

## `SDL_AudioInit( ... )`

Audio system initialization.

        SDL_AudioInit( 'pulseaudio' );

This method is used internally, and should not be used unless you have a
specific need to specify the audio driver you want to use. You should normally
use [`SDL_Init( ... )`](#sdl_init).

Returns `0` on success.

## `SDL_AudioQuit( )`

Cleaning up initialized audio system.

        SDL_AudioQuit( );

This method is used internally, and should not be used unless you have a
specific need to close the selected audio driver. You should normally use [`SDL_Quit( )`](#sdl_quit).

## `SDL_GetCurrentAudioDriver( )`

Get the name of the current audio driver.

        my $driver = SDL_GetCurrentAudioDriver( );

The returned string points to internal static memory and thus never becomes
invalid, even if you quit the audio subsystem and initialize a new driver
(although such a case would return a different static string from another call
to this function, of course). As such, you should not modify or free the
returned string.

Returns the name of the current audio driver or undef if no driver has been
initialized.

## `SDL_OpenAudio( ... )`

This function is a legacy means of opening the audio device.

    my $obtained = SDL_OpenAudio(
        SDL2::AudioSpec->new( { freq => 48000, channels => 2, format => AUDIO_F32 } ) );

This function remains for compatibility with SDL 1.2, but also because it's
slightly easier to use than the new functions in SDL 2.0. The new, more
powerful, and preferred way to do this is [`SDL_OpenAudioDevice( ...
)`](#sdl_openaudiodevice) .

This function is roughly equivalent to:

        SDL_OpenAudioDevice( (), 0, $desired, SDL_AUDIO_ALLOW_ANY_CHANGE );

With two notable exceptions:

- - If `obtained` is undefined, we use `desired` (and allow no changes), which
means desired will be modified to have the correct values for silence,
etc, and SDL will convert any differences between your app's specific
request and the hardware behind the scenes.
- - The return value is always success or failure, and not a device ID, which
means you can only have one device open at a time with this function.

    * \param desired an SDL_AudioSpec structure representing the desired output
    *                format. Please refer to the SDL_OpenAudioDevice documentation
    *                for details on how to prepare this structure.
    * \param obtained an SDL_AudioSpec structure filled in with the actual
    *                 parameters, or NULL.
    * \returns This function opens the audio device with the desired parameters,
    *          and returns 0 if successful, placing the actual hardware
    *          parameters in the structure pointed to by `obtained`.
    *
    *          If `obtained` is NULL, the audio data passed to the callback
    *          function will be guaranteed to be in the requested format, and
    *          will be automatically converted to the actual hardware audio
    *          format if necessary. If `obtained` is NULL, `desired` will
    *          have fields modified.
    *
    *          This function returns a negative error code on failure to open the
    *          audio device or failure to set up the audio thread; call
    *          SDL_GetError() for more information.

# LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

# AUTHOR

Sanko Robinson <sanko@cpan.org>
