package SDL2::FFI 0.06 {
    use lib '../lib', 'lib';

    # ABSTRACT: FFI Wrapper for SDL (Simple DirectMedia Layer) Development Library
    use strictures 2;
    use experimental 'signatures';
    use base 'Exporter::Tiny';
    use SDL2::Utils;
    use Config;
    sub bigendian () { CORE::state $bigendian //= ( $Config{byteorder} != 4321 ); $bigendian }
    our %EXPORT_TAGS;

    # I need these first
    attach version => { SDL_GetVersion => [ ['SDL_version'] ] };
    #
    SDL_GetVersion( my $ver = SDL2::version->new() );
    my $platform = $^O;                            # https://perldoc.perl.org/perlport#PLATFORMS
    my $Windows  = !!( $platform eq 'MSWin32' );
    #
    use SDL2::version;
    use SDL2::Enum;
    use SDL2::Finger;
    use SDL2::Joystick;
    use SDL2::Event;                               # Includes all known events
    use SDL2::Point;
    use SDL2::FPoint;
    use SDL2::FRect;
    use SDL2::Rect;
    use SDL2::DisplayMode;
    use SDL2::Surface;
    use SDL2::Window;
    use SDL2::WindowShaper;
    use SDL2::Texture;
    use SDL2::Renderer;
    use SDL2::GameControllerButtonBind;
    use SDL2::HapticDirection;
    use SDL2::HapticEffect;
    use SDL2::JoystickGUID;
    use SDL2::Keysym;
    use SDL2::Locale;
    use SDL2::MessageBoxData;
    use SDL2::MetalView;
    use SDL2::Mutex;
    use SDL2::Semaphore;
    use SDL2::Cond;
    use SDL2::Color;
    use SDL2::Palette;
    use SDL2::PixelFormat;
    use SDL2::RWops;
    use SDL2::Sensor;
    use SDL2::WindowShapeMode;
    #
    use Data::Dump;

    # https://github.com/libsdl-org/SDL/blob/main/include/SDL.h
    push @{ $EXPORT_TAGS{default} }, qw[:init];
    attach init => {
        SDL_Init          => [ ['uint32'] => 'int' ],
        SDL_InitSubSystem => [ ['uint32'] => 'int' ],
        SDL_Quit          => [ [] ],
        SDL_QuitSubSystem => [ ['uint32'] ],
        SDL_WasInit       => [ ['uint32'] => 'uint32' ]
    };
    use SDL2::atomic_t;
    ffi->type( 'int' => 'SDL_SpinLock' );
    attach atomic => {
        SDL_AtomicTryLock                => [ ['SDL_SpinLock'], 'SDL_bool' ],
        SDL_AtomicLock                   => [ ['SDL_SpinLock'], 'SDL_bool' ],
        SDL_AtomicUnlock                 => [ ['SDL_SpinLock'] ],
        SDL_MemoryBarrierReleaseFunction => [ [] ],                 # Undocumented
        SDL_MemoryBarrierAcquireFunction => [ [] ],                 # Undocumented
        SDL_AtomicCAS                    => [ [ 'SDL_atomic_t', 'int', 'int' ], 'SDL_bool' ],
        SDL_AtomicSet                    => [ [ 'SDL_atomic_t', 'int' ], 'int' ],
        SDL_AtomicAdd                    => [ [ 'SDL_atomic_t', 'int' ], 'int' ],

        # Will likely not need these:
        #SDL_AtomicCASPtr =>  [ ['SDL_atomic_t*', 'int*', 'int*'], 'SDL_bool'],
        #SDL_AtomicSetPtr =>  [ ['SDL_AtomicSetPtr*', 'int*' ], 'int *'],
        #SDL_AtomicGetPtr =>  [ ['SDL_AtomicSetPtr*' ], 'int *'],
    };
    define atomic => [
        [ SDL_AtomicIncRef => sub ($a) { SDL_AtomicAdd( $a, 1 ) } ],
        [ SDL_AtomicDecRef => sub ($a) { SDL_AtomicAdd( $a, -1 ) } ]
    ];
    #
    use SDL2::AudioStream;
    use SDL2::AudioCVT;
    use SDL2::AudioSpec;
    ffi->type( 'uint16'                => 'SDL_AudioFormat' );
    ffi->type( 'uint32'                => 'SDL_AudioDeviceID' );
    ffi->type( '(opaque,uint16)->void' => 'SDL_AudioFilter' );
    attach audio => {
        SDL_GetNumAudioDrivers    => [ ['int'],    'int' ],
        SDL_GetAudioDriver        => [ ['int'],    'string' ],
        SDL_AudioInit             => [ ['string'], 'int' ],
        SDL_AudioQuit             => [ [] ],
        SDL_GetCurrentAudioDriver => [ [], 'string' ],
        SDL_OpenAudio             => [
            [ 'SDL_AudioSpec', 'SDL_AudioSpec' ],
            'int' => sub ( $inner, $desired, $obtained = () ) {
                deprecate <<'END';
SDL_OpenAudio( ... ) remains for compatibility with SDL 1.2. The new, more
powerful, and preferred way to do this is SDL_OpenAudioDevice( ... );
END
                $inner->( $desired, $obtained );
            }
        ],
        SDL_GetNumAudioDevices => [ ['int'],          'int' ],
        SDL_GetAudioDeviceName => [ [ 'int', 'int' ], 'string' ], (
            $ver->patch >= 15 ?
                ( SDL_GetAudioDeviceSpec => [ [ 'int', 'int', 'SDL_AudioSpec' ], 'int' ] ) :
                ()
        ),
        SDL_OpenAudioDevice =>
            [ [ "string", "int", "SDL_AudioSpec", "SDL_AudioSpec", "int" ], "SDL_AudioDeviceID", ],
        SDL_GetAudioStatus       => [ [],                    'SDL_AudioStatus' ],
        SDL_GetAudioDeviceStatus => [ ['SDL_AudioDeviceID'], 'SDL_AudioStatus' ],
        SDL_PauseAudio           => [ ['int'] ],
        SDL_PauseAudioDevice     => [ [ 'SDL_AudioDeviceID', 'int' ] ],
        SDL_LoadWAV_RW           =>
            [ [ 'SDL_RWops', 'int', 'SDL_AudioSpec', 'opaque', 'uint32*' ], 'SDL_AudioSpec' ],
        SDL_FreeWAV       => [ ['uint8*'] ],
        SDL_BuildAudioCVT => [
            [   'SDL_AudioCVT',    'SDL_AudioFormat', 'uint8', 'int',
                'SDL_AudioFormat', 'uint8',           'int',
            ],
            'int'
        ],
        SDL_ConvertAudio   => [ ['SDL_AudioCVT'], 'int' ],
        SDL_NewAudioStream => [
            [ 'SDL_AudioFormat', 'uint8', 'int', 'SDL_AudioFormat', 'uint8', 'int' ],
            'SDL_AudioStream',
        ],
        SDL_AudioStreamPut       => [ [ 'SDL_AudioStream', 'opaque*', 'int' ], 'int' ],
        SDL_AudioStreamGet       => [ [ 'SDL_AudioStream', 'opaque*', 'int' ], 'int' ],
        SDL_AudioStreamAvailable => [ ['SDL_AudioStream'], 'int' ],
        SDL_AudioStreamFlush     => [ ['SDL_AudioStream'], 'int' ],
        SDL_AudioStreamClear     => [ ['SDL_AudioStream'] ],
        SDL_FreeAudioStream      => [ ['SDL_AudioStream'] ],
        SDL_MixAudio             => [ [ 'uint8*', 'uint8*', 'uint32', 'int' ] ],
        SDL_MixAudioFormat       => [ [ 'uint8*', 'uint8*', 'SDL_AudioFormat', 'uint32', 'int' ] ],
        SDL_QueueAudio           => [ [ 'SDL_AudioDeviceID', 'opaque*', 'uint32' ], 'int' ],
        SDL_DequeueAudio         => [ [ 'SDL_AudioDeviceID', 'opaque*', 'uint32' ], 'uint32' ],
        SDL_GetQueuedAudioSize   => [ ['SDL_AudioDeviceID'], 'uint32' ],
        SDL_ClearQueuedAudio     => [ ['SDL_AudioDeviceID'] ],
        SDL_LockAudio            => [ [] ],
        SDL_LockAudioDevice      => [ ['SDL_AudioDeviceID'] ],
        SDL_UnlockAudio          => [ [] ],
        SDL_UnlockAudioDevice    => [ ['SDL_AudioDeviceID'] ],
        SDL_CloseAudio           => [ [] ],
        SDL_CloseAudioDevice     => [ ['SDL_AudioDeviceID'] ]
    };
    define audio => [
        [   SDL_LoadWAV => sub ( $file, $spec, $audio_buf, $audio_len ) {
                SDL_LoadWAV_RW( SDL_RWFromFile( $file, 'rb' ), 1, $spec, $audio_buf, $audio_len );
            }
        ]
    ];
    attach blendmode => {
        SDL_ComposeCustomBlendMode => [
            [   'SDL_BlendFactor',    'SDL_BlendFactor',
                'SDL_BlendOperation', 'SDL_BlendFactor',
                'SDL_BlendFactor',    'SDL_BlendOperation'
            ],
            'SDL_BlendMode'
        ],
    };
    attach
        clipboard => {
        SDL_SetClipboardText => [ ['string'], 'int' ],
        SDL_GetClipboardText => [ [],         'string' ],
        SDL_HasClipboardText => [ [],         'SDL_bool' ]
        },
        cpuinfo => {
        SDL_GetCPUCount         => [ [],                  'int' ],
        SDL_GetCPUCacheLineSize => [ [],                  'int' ],
        SDL_HasRDTSC            => [ [],                  'SDL_bool' ],
        SDL_HasAltiVec          => [ [],                  'SDL_bool' ],
        SDL_HasMMX              => [ [],                  'SDL_bool' ],
        SDL_Has3DNow            => [ [],                  'SDL_bool' ],
        SDL_HasSSE              => [ [],                  'SDL_bool' ],
        SDL_HasSSE2             => [ [],                  'SDL_bool' ],
        SDL_HasSSE3             => [ [],                  'SDL_bool' ],
        SDL_HasSSE41            => [ [],                  'SDL_bool' ],
        SDL_HasSSE42            => [ [],                  'SDL_bool' ],
        SDL_HasAVX              => [ [],                  'SDL_bool' ],
        SDL_HasAVX2             => [ [],                  'SDL_bool' ],
        SDL_HasAVX512F          => [ [],                  'SDL_bool' ],
        SDL_HasARMSIMD          => [ [],                  'SDL_bool' ],
        SDL_HasNEON             => [ [],                  'SDL_bool' ],
        SDL_GetSystemRAM        => [ [],                  'int' ],
        SDL_SIMDGetAlignment    => [ [],                  'int' ],
        SDL_SIMDAlloc           => [ ['int'],             'opaque' ],
        SDL_SIMDRealloc         => [ [ 'opaque', 'int' ], 'opaque' ],
        SDL_SIMDFree            => [ ['opaque'] ],
        },
        error => {
        SDL_SetError => [
            ['string'] => 'int' =>
                sub ( $inner, $fmt, @params ) { $inner->( sprintf( $fmt, @params ) ); }
        ],
        SDL_GetError    => [ [] => 'string' ],
        SDL_GetErrorMsg => [
            [ 'string', 'int' ] => 'string' => sub ( $inner, $errstr, $maxlen = length $errstr ) {
                $_[1] = ' ' x $maxlen if !defined $_[1] || length $errstr != $maxlen;
                $inner->( $_[1], $maxlen );
            }
        ],
        SDL_ClearError => [ [] => 'void' ],
        SDL_Error      => [ ['SDL_errorcode'], 'int' ]
        },
        events => { SDL_PumpEvents => [ [] ] };
    #
    ffi->type( '(opaque,string,string,string)->void' => 'SDL_HintCallback' );
    attach hints => {
        SDL_SetHintWithPriority => [ [ 'string', 'string', 'int' ] => 'bool' ],
        SDL_SetHint             => [ [ 'string', 'string' ]        => 'bool' ],
        SDL_GetHint             => [ ['string']                    => 'string' ],
        $ver->patch >= 5 ? ( SDL_GetHintBoolean => [ [ 'string', 'bool' ] => 'bool' ] ) : (),
        SDL_AddHintCallback => [
            [ 'string', 'SDL_HintCallback', 'opaque' ] => 'void' =>
                sub ( $xsub, $name, $callback, $userdata ) {    # Fake void pointer
                my $cb = FFI::Platypus::Closure->new(
                    sub ( $ptr, @etc ) { $callback->( $userdata, @etc ) } );
                $cb->sticky;
                $xsub->( $name, $cb, $userdata );
                return $cb;
            }
        ],
        SDL_DelHintCallback => [
            [ 'string', 'SDL_HintCallback', 'opaque' ] => 'void' =>
                sub ( $xsub, $name, $callback, $userdata ) {    # Fake void pointer
                my $cb = $callback;
                $cb->unstick;
                $xsub->( $name, $cb, $userdata );
                return $cb;
            }
        ],
        SDL_ClearHints => [ [] => 'void' ],
    };
    ffi->type( '(opaque,int,int,string)->void' => 'SDL_LogOutputFunction' );
    attach log => {
        SDL_LogSetAllPriority  => [ ['SDL_LogPriority'] ],
        SDL_LogSetPriority     => [ [ 'SDL_LogCategory', 'SDL_LogPriority' ] ],
        SDL_LogGetPriority     => [ ['SDL_LogCategory'] => 'SDL_LogPriority' ],
        SDL_LogResetPriorities => [ [] ],
        SDL_Log                => [
            ['string'] => 'string' =>
                sub ( $inner, $fmt, @args ) { $inner->( sprintf( $fmt, @args ) ) }
        ],
        SDL_LogVerbose => => [
            [ 'SDL_LogCategory', 'string' ] => sub ( $inner, $category, $fmt, @args ) {
                $inner->( $category, sprintf( $fmt, @args ) );
            }
        ],
        SDL_LogDebug => => [
            [ 'SDL_LogCategory', 'string' ] => sub ( $inner, $category, $fmt, @args ) {
                $inner->( $category, sprintf( $fmt, @args ) );
            }
        ],
        SDL_LogInfo => => [
            [ 'SDL_LogCategory', 'string' ] => sub ( $inner, $category, $fmt, @args ) {
                $inner->( $category, sprintf( $fmt, @args ) );
            }
        ],
        SDL_LogWarn => => [
            [ 'SDL_LogCategory', 'string' ] => sub ( $inner, $category, $fmt, @args ) {
                $inner->( $category, sprintf( $fmt, @args ) );
            }
        ],
        SDL_LogError => => [
            [ 'SDL_LogCategory', 'string' ] => sub ( $inner, $category, $fmt, @args ) {
                $inner->( $category, sprintf( $fmt, @args ) );
            }
        ],
        SDL_LogCritical => => [
            [ 'SDL_LogCategory', 'string' ] => sub ( $inner, $category, $fmt, @args ) {
                $inner->( $category, sprintf( $fmt, @args ) );
            }
        ],
        SDL_LogMessage => [
            [ 'SDL_LogCategory', 'SDL_LogPriority', 'string' ] =>
                sub ( $inner, $category, $priority, $fmt, @args ) {
                $inner->( $category, $priority, sprintf( $fmt, @args ) );
            }
        ],

        # TODO
        SDL_LogGetOutputFunction => [ [ 'SDL_LogOutputFunction', 'opaque' ] ],
        SDL_LogSetOutputFunction => [
            [ 'SDL_LogOutputFunction', 'opaque' ] => 'void' => sub ( $xsub, $callback, $userdata )
            {    # Fake void pointer
                my $cb = FFI::Platypus::Closure->new(
                    sub ( $ptr, @etc ) { $callback->( $userdata, @etc ) } );
                $cb->sticky;
                $xsub->( $cb, $userdata );
                return $cb;
            }
        ]
    };
    #
    package SDL2::AssertData {
        use SDL2::Utils;
        has
            always_ignore => 'int',
            trigger_count => 'uint',
            condition     => 'opaque',    # string
            filename      => 'opaque',    # string
            linenum       => 'int',
            function      => 'opaque',    # string
            next          => 'opaque'     # const struct SDL_AssertData *next
    };
    attach assert => {
        SDL_ReportAssertion    => [ [ 'opaque', 'string', 'string', 'int' ], 'opaque' ],
        SDL_GetAssertionReport => [ ['SDL_AssertData'] ],
    };
    FFI::C::ArrayDef->new(    # Used sparingly when I need to pass a list of SDL_Point objects
        ffi,
        name    => 'SDL2x_PointList',
        class   => 'SDL2x::PointList',
        members => ['SDL_Point'],
    );
    FFI::C::ArrayDef->new(    # Used sparingly when I need to pass a list of SDL_Point objects
        ffi,
        name    => 'SDL2x_FPointList',
        class   => 'SDL2x::FPointList',
        members => ['SDL_Point'],
    );
    FFI::C::ArrayDef->new(    # Used sparingly when I need to pass a list of SDL_Rect objects
        ffi,
        name    => 'SDL2x_RectList',
        class   => 'SDL2x::RectList',
        members => ['SDL_Rect'],
    );
    FFI::C::ArrayDef->new(    # Used sparingly when I need to pass a list of SDL_Rect objects
        ffi,
        name    => 'SDL2x_FRectList',
        class   => 'SDL2x::FRectList',
        members => ['SDL_FRect'],
    );
    #
    ffi->type( '(opaque,opaque,opaque)->int' => 'SDL_HitTest' );

    # An opaque handle to an OpenGL context.
    package SDL2::GLContext { use SDL2::Utils; has() };
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
        ( $ver->patch >= 15 ? ( SDL_SetWindowKeyboardGrab => [ [ 'SDL_Window', 'bool' ] ] ) : () ),
        ( $ver->patch >= 15 ? ( SDL_SetWindowMouseGrab    => [ [ 'SDL_Window', 'bool' ] ] ) : () ),
        SDL_GetWindowGrab => [ ['SDL_Window'], 'bool' ],
        ( $ver->patch >= 15 ? ( SDL_GetWindowKeyboardGrab => [ ['SDL_Window'], 'bool' ] ) : () ),
        ( $ver->patch >= 15 ? ( SDL_GetWindowMouseGrab    => [ ['SDL_Window'], 'bool' ] ) : () ),
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
        ( $ver->patch >= 15 ? ( SDL_FlashWindow => [ [ 'SDL_Window', 'uint32' ], 'int' ] ) : () ),
        SDL_DestroyWindow        => [ ['SDL_Window'] ],
        SDL_IsScreenSaverEnabled => [ [], 'bool' ],
        SDL_EnableScreenSaver    => [ [] ],
        SDL_DisableScreenSaver   => [ [] ],
        },
        opengl => {
        SDL_GL_LoadLibrary        => [ ['string'], 'int' ],
        SDL_GL_GetProcAddress     => [ ['string'], 'opaque' ],
        SDL_GL_UnloadLibrary      => [ [] ],
        SDL_GL_ExtensionSupported => [ ['string'], 'bool' ],
        SDL_GL_ResetAttributes    => [ [] ],
        SDL_GL_SetAttribute       => [ [ 'SDL_GLattr', 'int' ],           'int' ],
        SDL_GL_GetAttribute       => [ [ 'SDL_GLattr', 'int*' ],          'int' ],
        SDL_GL_CreateContext      => [ ['SDL_Window'],                    'SDL_GLContext' ],
        SDL_GL_MakeCurrent        => [ [ 'SDL_Window', 'SDL_GLContext' ], 'int' ],
        SDL_GL_GetCurrentWindow   => [ [],                                'SDL_Window' ],
        SDL_GL_GetCurrentContext  => [ [],                                'SDL_GLContext' ],
        SDL_GL_GetDrawableSize    => [ [ 'SDL_Window', 'int*', 'int*' ], ],
        SDL_GL_SetSwapInterval    => [ ['int'], 'int' ],
        SDL_GL_GetSwapInterval    => [ [],      'int' ],
        SDL_GL_SwapWindow         => [ ['SDL_Window'] ],
        SDL_GL_DeleteContext      => [ ['SDL_GLContext'] ]
        };
    attach render => {
        SDL_GetNumRenderDrivers     => [ [],                            'int' ],
        SDL_GetRenderDriverInfo     => [ [ 'int', 'SDL_RendererInfo' ], 'int' ],
        SDL_CreateWindowAndRenderer => [
            [ 'int', 'int', 'uint32', 'opaque*', 'opaque*' ],
            'int' => sub ( $inner, $width, $height, $window_flags, $window = (), $renderer = () ) {
                $window   //= SDL2::Window->new;
                $renderer //= SDL2::Renderer->new;
                my $ok = $inner->( $width, $height, $window_flags, \$window, \$renderer );
                $_[4] = ffi->cast( 'opaque' => 'SDL_Window',   $window );
                $_[5] = ffi->cast( 'opaque' => 'SDL_Renderer', $renderer );

                #$ok == 0 ? (
                #    ffi->cast( 'opaque' => 'SDL_Window',   $window ),
                #    ffi->cast( 'opaque' => 'SDL_Renderer', $renderer ),
                #    ) :
                $ok;
            }
        ],
        SDL_CreateRenderer         => [ [ 'SDL_Window', 'int', 'uint32' ],      'SDL_Renderer' ],
        SDL_CreateSoftwareRenderer => [ ['SDL_Surface'],                        'SDL_Renderer' ],
        SDL_GetRenderer            => [ ['SDL_Window'],                         'SDL_Renderer' ],
        SDL_GetRendererInfo        => [ [ 'SDL_Renderer', 'SDL_RendererInfo' ], 'int' ],
        SDL_GetRendererOutputSize  => [ [ 'SDL_Renderer', 'int*', 'int*' ],     'int' ],
        SDL_CreateTexture => [ [ 'SDL_Renderer', 'uint32', 'int', 'int', 'int' ], 'SDL_Texture' ],
        SDL_CreateTextureFromSurface => [ [ 'SDL_Renderer', 'SDL_Surface' ], 'SDL_Texture' ],
        SDL_QueryTexture        => [ [ 'SDL_Texture', 'uint32*', 'int*', 'int*', 'int*' ], 'int' ],
        SDL_SetTextureColorMod  => [ [ 'SDL_Texture', 'uint8', 'uint8', 'uint8' ],         'int' ],
        SDL_GetTextureColorMod  => [ [ 'SDL_Texture', 'uint8*', 'uint8*', 'uint8*' ],      'int' ],
        SDL_SetTextureAlphaMod  => [ [ 'SDL_Texture', 'uint8' ],                           'int' ],
        SDL_GetTextureAlphaMod  => [ [ 'SDL_Texture', 'uint8*' ],                          'int' ],
        SDL_SetTextureBlendMode => [ [ 'SDL_Texture', 'SDL_BlendMode' ],                   'int' ],
        SDL_GetTextureBlendMode => [ [ 'SDL_Texture', 'int*' ],                            'int' ],
        SDL_UpdateTexture       => [ [ 'SDL_Texture', 'SDL_Rect', 'opaque*', 'int' ],      'int' ],
        SDL_UpdateYUVTexture    => [
            [ 'SDL_Texture', 'SDL_Rect', 'uint8*', 'int', 'uint8*', 'int', 'uint8*', 'int' ], 'int'
        ], (
            $ver->patch >= 15 ?
                ( SDL_UpdateNVTexture =>
                    [ [ 'SDL_Texture', 'SDL_Rect', 'uint8*', 'int', 'uint8*', 'int' ], 'int' ] ) :
                ()
        ),
        SDL_LockTexture           => [ [ 'SDL_Texture', 'SDL_Rect', 'opaque*' ], 'int' ],
        SDL_LockTextureToSurface  => [ [ 'SDL_Texture', 'SDL_Rect', 'SDL_Surface' ], 'int' ],
        SDL_UnlockTexture         => [ ['SDL_Texture'] ],
        SDL_RenderTargetSupported => [ ['SDL_Renderer'],                   'bool' ],
        SDL_SetRenderTarget       => [ [ 'SDL_Renderer', 'SDL_Texture' ],  'int' ],
        SDL_GetRenderTarget       => [ ['SDL_Renderer'],                   'SDL_Texture' ],
        SDL_RenderSetLogicalSize  => [ [ 'SDL_Renderer', 'int', 'int' ],   'int' ],
        SDL_RenderGetLogicalSize  => [ [ 'SDL_Renderer', 'int*', 'int*' ], 'int' ],
        SDL_RenderSetIntegerScale => [ [ 'SDL_Renderer', 'bool' ],         'int' ],
        SDL_RenderGetIntegerScale => [ ['SDL_Renderer'],                   'bool' ],
        SDL_RenderSetViewport     => [ [ 'SDL_Renderer', 'SDL_Rect' ],     'int' ],
        SDL_RenderGetViewport     => [ [ 'SDL_Renderer', 'SDL_Rect' ],     'int' ],
        SDL_RenderSetClipRect     => [ [ 'SDL_Renderer', 'SDL_Rect' ],     'int' ],
        SDL_RenderGetClipRect     => [ [ 'SDL_Renderer', 'SDL_Rect' ] ],
        SDL_RenderIsClipEnabled   => [ ['SDL_Renderer'], 'bool' ],
        SDL_RenderSetScale        => [ [ 'SDL_Renderer', 'float', 'float' ], 'int' ],
        SDL_RenderGetScale     => [ [ 'SDL_Renderer', 'float*', 'float*' ], ],
        SDL_SetRenderDrawColor => [ [ 'SDL_Renderer', 'uint8', 'uint8', 'uint8', 'uint8' ], 'int' ],
        SDL_GetRenderDrawColor =>
            [ [ 'SDL_Renderer', 'uint8*', 'uint8*', 'uint8*', 'uint8*' ], 'int' ],
        SDL_SetRenderDrawBlendMode => [ [ 'SDL_Renderer', 'SDL_BlendMode' ], 'int' ],
        SDL_GetRenderDrawBlendMode => [ [ 'SDL_Renderer', 'int*' ],          'int' ],
        SDL_RenderClear            => [ ['SDL_Renderer'],                    'int' ],
        SDL_RenderDrawPoint        => [ [ 'SDL_Renderer', 'int', 'int' ],    'int' ],
        SDL_RenderDrawPoints       => [
            [ 'SDL_Renderer', 'SDL2x_PointList', 'int' ],
            'int' => sub ( $inner, $renderer, @points ) {

          # XXX - This is a workaround for FFI::C::Array not being able to accept a list of objects
          # XXX - I can rethink this map when https://github.com/PerlFFI/FFI-C/issues/53 is resolved
                $inner->(
                    $renderer,
                    SDL2x::PointList->new(
                        [ map { ref $_ eq 'HASH' ? $_ : { x => $_->x, y => $_->y } } @points ]
                    ),
                    scalar @points
                );
            }
        ],
        SDL_RenderDrawLine  => [ [ 'SDL_Renderer', 'int', 'int', 'int', 'int' ], 'int' ],
        SDL_RenderDrawLines => [
            [ 'SDL_Renderer', 'SDL2x_PointList', 'int' ],
            'int' => sub ( $inner, $renderer, @points ) {

          # XXX - This is a workaround for FFI::C::Array not being able to accept a list of objects
          # XXX - I can rethink this map when https://github.com/PerlFFI/FFI-C/issues/53 is resolved
                $inner->(
                    $renderer,
                    SDL2x::PointList->new(
                        [ map { ref $_ eq 'HASH' ? $_ : { x => $_->x, y => $_->y } } @points ]
                    ),
                    scalar @points
                );
            }
        ],
        SDL_RenderDrawRect  => [ [ 'SDL_Renderer', 'SDL_Rect' ], 'int' ],
        SDL_RenderDrawRects => [
            [ 'SDL_Renderer', 'SDL2x_RectList', 'int' ],
            'int' => sub ( $inner, $renderer, @rects ) {

          # XXX - This is a workaround for FFI::C::Array not being able to accept a list of objects
          # XXX - I can rethink this map when https://github.com/PerlFFI/FFI-C/issues/53 is resolved
                $inner->(
                    $renderer,
                    SDL2x::RectList->new(
                        [   map {
                                ref $_ eq 'HASH' ? $_ :
                                    { x => $_->x, y => $_->y, w => $_->w, h => $_->h }
                            } @rects
                        ]
                    ),
                    scalar @rects
                );
            }
        ],
        SDL_RenderFillRect  => [ [ 'SDL_Renderer', 'SDL_Rect' ], 'int' ],
        SDL_RenderFillRects => [
            [ 'SDL_Renderer', 'SDL2x_RectList', 'int' ],
            'int' => sub ( $inner, $renderer, @rects ) {

          # XXX - This is a workaround for FFI::C::Array not being able to accept a list of objects
          # XXX - I can rethink this map when https://github.com/PerlFFI/FFI-C/issues/53 is resolved
                $inner->(
                    $renderer,
                    SDL2x::RectList->new(
                        [   map {
                                ref $_ eq 'HASH' ? $_ :
                                    { x => $_->x, y => $_->y, w => $_->w, h => $_->h }
                            } @rects
                        ]
                    ),
                    scalar @rects
                );
            }
        ],
        SDL_RenderCopy => [ [ 'SDL_Renderer', 'SDL_Texture', 'SDL_Rect', 'SDL_Rect' ], 'int' ],

        # XXX - I do not have an example for this function in docs
        SDL_RenderCopyEx => [
            [   'SDL_Renderer', 'SDL_Texture', 'SDL_Rect', 'SDL_Rect',
                'double',       'SDL_Point',   'SDL_RendererFlip'
            ],
            'int'
        ],
        SDL_RenderDrawPointF  => [ [ 'SDL_Renderer', 'float', 'float' ], 'int' ],
        SDL_RenderDrawPointsF => [
            [ 'SDL_Renderer', 'SDL2x_FPointList', 'int' ],
            'int' => sub ( $inner, $renderer, @points ) {

          # XXX - This is a workaround for FFI::C::Array not being able to accept a list of objects
          # XXX - I can rethink this map when https://github.com/PerlFFI/FFI-C/issues/53 is resolved
                $inner->(
                    $renderer,
                    SDL2x::PointFList->new(
                        [ map { ref $_ eq 'HASH' ? $_ : { x => $_->x, y => $_->y } } @points ]
                    ),
                    scalar @points
                );
            }
        ],
        SDL_RenderDrawLineF  => [ [ 'SDL_Renderer', 'float', 'float', 'float', 'float' ], 'int' ],
        SDL_RenderDrawLinesF => [
            [ 'SDL_Renderer', 'SDL2x_FPointList', 'int' ],
            'int' => sub ( $inner, $renderer, @points ) {

          # XXX - This is a workaround for FFI::C::Array not being able to accept a list of objects
          # XXX - I can rethink this map when https://github.com/PerlFFI/FFI-C/issues/53 is resolved
                $inner->(
                    $renderer,
                    SDL2x::FPointList->new(
                        [ map { ref $_ eq 'HASH' ? $_ : { x => $_->x, y => $_->y } } @points ]
                    ),
                    scalar @points
                );
            }
        ],
        SDL_RenderDrawRectF => [
            [ 'SDL_Renderer', 'SDL2x_FRectList', 'int' ],
            'int' => sub ( $inner, $renderer, @rects ) {

          # XXX - This is a workaround for FFI::C::Array not being able to accept a list of objects
          # XXX - I can rethink this map when https://github.com/PerlFFI/FFI-C/issues/53 is resolved
                $inner->(
                    $renderer,
                    SDL2x::FRectList->new(
                        [   map {
                                ref $_ eq 'HASH' ? $_ :
                                    { x => $_->x, y => $_->y, w => $_->w, h => $_->h }
                            } @rects
                        ]
                    ),
                    scalar @rects
                );
            }
        ],
        SDL_RenderDrawRectsF => [
            [ 'SDL_Renderer', 'SDL2x_FRectList', 'int' ],
            'int' => sub ( $inner, $renderer, @rects ) {

          # XXX - This is a workaround for FFI::C::Array not being able to accept a list of objects
          # XXX - I can rethink this map when https://github.com/PerlFFI/FFI-C/issues/53 is resolved
                $inner->(
                    $renderer,
                    SDL2x::FRectList->new(
                        [   map {
                                ref $_ eq 'HASH' ? $_ :
                                    { x => $_->x, y => $_->y, w => $_->w, h => $_->h }
                            } @rects
                        ]
                    ),
                    scalar @rects
                );
            }
        ],
        SDL_RenderFillRectsF => [
            [ 'SDL_Renderer', 'SDL2x_FRectList', 'int' ],
            'int' => sub ( $inner, $renderer, @rects ) {

          # XXX - This is a workaround for FFI::C::Array not being able to accept a list of objects
          # XXX - I can rethink this map when https://github.com/PerlFFI/FFI-C/issues/53 is resolved
                $inner->(
                    $renderer,
                    SDL2x::FRectList->new(
                        [   map {
                                ref $_ eq 'HASH' ? $_ :
                                    { x => $_->x, y => $_->y, w => $_->w, h => $_->h }
                            } @rects
                        ]
                    ),
                    scalar @rects
                );
            }
        ],

        # XXX - I do not have an example for this function in docs
        SDL_RenderCopyF => [ [ 'SDL_Renderer', 'SDL_Texture', 'SDL_Rect', 'SDL_FRect' ], 'int' ],

        # XXX - I do not have an example for this function in docs
        SDL_RenderCopyExF => [
            [   'SDL_Renderer', 'SDL_Texture', 'SDL_Rect', 'SDL_FRect',
                'double',       'SDL_FPoint',  'SDL_RendererFlip'
            ],
            'int'
        ],
        SDL_RenderReadPixels =>
            [ [ 'SDL_Renderer', 'SDL_Rect', 'uint32', 'opaque', 'int' ], 'int' ],
        SDL_RenderPresent                => [ ['SDL_Renderer'] ],
        SDL_DestroyTexture               => [ ['SDL_Texture'] ],
        SDL_DestroyRenderer              => [ ['SDL_Renderer'] ],
        SDL_RenderFlush                  => [ ['SDL_Renderer'],                      'int' ],
        SDL_GL_BindTexture               => [ [ 'SDL_Texture', 'float*', 'float*' ], 'int' ],
        SDL_GL_UnbindTexture             => [ ['SDL_Texture'],                       'int' ],
        SDL_RenderGetMetalLayer          => [ ['SDL_Renderer'],                      'opaque' ],
        SDL_RenderGetMetalCommandEncoder => [ ['SDL_Renderer'],                      'opaque' ]
    };
    ffi->type( '(opaque, int, string)->int' => 'my_closure_type' );
    ffi->type( '(uint32,opaque)->uint32'    => 'SDL_TimerCallback' );
    ffi->type( 'int'                        => 'SDL_TimerID' );
    my %_timers;
    END { %_timers = () }
    attach timer => {
        SDL_GetTicks                => [ [], 'uint32' ],
        SDL_GetPerformanceCounter   => [ [], 'uint64' ],
        SDL_GetPerformanceFrequency => [ [], 'uint64' ],
        SDL_Delay                   => [ ['uint32'] ],
        Bundle_SDL_AddTimer         => [
            [ 'uint32', 'SDL_TimerCallback', 'opaque' ],
            'SDL_TimerID',
            sub ( $inner, $delay, $code, $params = () ) {
                my $cb = ffi->closure(
                    sub {
                        my ( $delay, $etc ) = @_;
                        my $retval = $code->( $delay, $params );
                        $retval;
                    }
                );
                my $id = $inner->( $delay, $cb, undef );
                $_timers{$id} = $cb;    # Store reference
                return $id;
            }
        ],
        Bundle_SDL_RemoveTimer => [
            ['SDL_TimerID'] => 'SDL_bool' => sub ( $inner, $id ) {
                my $retval = $inner->($id);
                delete $_timers{$id};
                return $retval;
            }
        ]
        },
        touch => {
        SDL_GetNumTouchDevices => [ [],                       'int' ],
        SDL_GetTouchDevice     => [ ['int'],                  'SDL_TouchID' ],
        SDL_GetTouchDeviceType => [ ['SDL_TouchID'],          'SDL_TouchDeviceType' ],
        SDL_GetNumTouchFingers => [ ['SDL_TouchID'],          'int' ],
        SDL_GetTouchFinger     => [ [ 'SDL_TouchID', 'int' ], 'SDL_Finger' ]
        };

    # Everything below this line will be rewritten!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    #
    #https://github.com/libsdl-org/SDL/blob/main/include/SDL_surface.h#L327
    push @{ $EXPORT_TAGS{'surface'} }, 'SDL_LoadBMP';
    attach surface => { SDL_LoadBMP_RW => [ [ 'SDL_RWops', 'int' ], 'SDL_Surface' ], };
    sub SDL_LoadBMP ($file) { SDL_LoadBMP_RW( SDL_RWFromFile( $file, "rb" ), 1 ) }
    push @{ $EXPORT_TAGS{'surface'} }, 'SDL_FreeSurface';
    ffi->attach( SDL_FreeSurface => ['SDL_Surface'] );
    ffi->attach( SDL_SaveBMP_RW  => [ 'SDL_Surface', 'SDL_RWops', 'int' ], 'int' );
    ffi->attach( SDL_RWFromFile  => [ 'string', 'string' ], 'SDL_RWops' );

    sub SDL_SaveBMP ( $surface, $file ) {
        SDL_SaveBMP_RW( $surface, SDL_RWFromFile( $file, 'wb' ), 1 );
    }
    ffi->attach( SDL_GetPlatform => [] => 'string' );
    ffi->attach( SDL_CreateRGBSurface =>
            [ 'uint32', 'int', 'int', 'int', 'uint32', 'uint32', 'uint32', 'uint32' ] =>
            'SDL_Surface' );

    # https://wiki.libsdl.org/CategoryStandard
    ffi->attach( SDL_acos => ['double'] => 'double' );
    ffi->attach( SDL_asin => ['double'] => 'double' );    # Not in wiki

    # https://wiki.libsdl.org/CategoryVideo
    # Macros defined in SDL_video.h
    define video => [
        [ SDL_WINDOWPOS_UNDEFINED_MASK => 0x1FFF0000 ],
        [   SDL_WINDOWPOS_UNDEFINED_DISPLAY =>
                sub ($X) { ( SDL_WINDOWPOS_UNDEFINED_MASK() | ($X) ) }
        ],
        [ SDL_WINDOWPOS_UNDEFINED => sub () { SDL_WINDOWPOS_UNDEFINED_DISPLAY(0) } ],
        [   SDL_WINDOWPOS_ISUNDEFINED =>
                sub ($X) { ( ( ($X) & 0xFFFF0000 ) == SDL_WINDOWPOS_UNDEFINED_MASK() ) }
        ],
        #
        [ SDL_WINDOWPOS_CENTERED_MASK    => sub () {0x2FFF0000} ],
        [ SDL_WINDOWPOS_CENTERED_DISPLAY => sub ($X) { ( SDL_WINDOWPOS_CENTERED_MASK() | ($X) ) } ],
        [ SDL_WINDOWPOS_CENTERED         => sub() { SDL_WINDOWPOS_CENTERED_DISPLAY(0) } ],
        [   SDL_WINDOWPOS_ISCENTERED =>
                sub ($X) { ( ( ($X) & 0xFFFF0000 ) == SDL_WINDOWPOS_CENTERED_MASK() ) }
        ],
    ];
    attach future => {
        SDL_FillRect => [ [ 'SDL_Surface', 'opaque*', 'uint32' ], 'int' ],
        SDL_MapRGB   => [
            [ 'SDL_PixelFormat', 'uint8', 'uint8', 'uint8' ] => 'uint32' =>
                sub ( $inner, $format, $r, $g, $b ) {
                $format = ffi->cast( 'opaque', 'SDL_PixelFormat', $format ) if !ref $format;
                $inner->( $format, $r, $g, $b );
            }
        ]
    };
    ffi->type( '(opaque, opaque)->int' => 'SDL_EventFilter' );
    attach events => {
        SDL_PeepEvents => [
            [ 'SDL_Event', 'int', 'SDL_EventAction', 'uint32', 'uint32' ] => 'int' =>
                sub ( $inner, @etc ) { SDL_Yield(); $inner->(@etc) }
        ],
        SDL_HasEvent =>
            [ ['uint32'] => 'bool' => sub ( $inner, @etc ) { SDL_Yield(); $inner->(@etc) } ],
        SDL_HasEvents => [
            [ 'uint32', 'uint32' ] => 'bool' => sub ( $inner, @etc ) { SDL_Yield(); $inner->(@etc) }
        ],
        SDL_FlushEvent  => [ ['uint32'] => sub ( $inner, @etc ) { SDL_Yield(); $inner->(@etc) } ],
        SDL_FlushEvents =>
            [ [ 'uint32', 'uint32' ] => sub ( $inner, @etc ) { SDL_Yield(); $inner->(@etc) } ],
        SDL_PollEvent =>
            [ ['SDL_Event'] => 'int' => sub ( $inner, @etc ) { SDL_Yield(); $inner->(@etc) } ],
        SDL_WaitEvent =>
            [ ['SDL_Event'] => 'int' => sub ( $inner, @etc ) { SDL_Yield(); $inner->(@etc) } ],
        SDL_WaitEventTimeout => [
            [ 'SDL_Event', 'int' ] => 'int' => sub ( $inner, @etc ) { SDL_Yield(); $inner->(@etc) }
        ],
        SDL_PushEvent =>
            [ ['SDL_Event'] => 'int' => sub ( $inner, @etc ) { SDL_Yield(); $inner->(@etc) } ],
        SDL_SetEventFilter => [
            [ 'SDL_EventFilter', 'opaque' ] => sub ( $inner, @etc ) { SDL_Yield(); $inner->(@etc) }
        ],
        SDL_GetEventFilter => [
            [ 'SDL_EventFilter', 'opaque' ] => 'bool' =>
                sub ( $inner, @etc ) { SDL_Yield(); $inner->(@etc) }
        ],
        SDL_AddEventWatch => [
            [ 'SDL_EventFilter', 'opaque' ] => sub ( $inner, @etc ) { SDL_Yield(); $inner->(@etc) }
        ],
        SDL_DelEventWatch => [
            [ 'SDL_EventFilter', 'opaque' ] => sub ( $inner, @etc ) { SDL_Yield(); $inner->(@etc) }
        ],
        SDL_FilterEvents => [
            [ 'SDL_EventFilter', 'opaque' ] => sub ( $inner, @etc ) { SDL_Yield(); $inner->(@etc) }
        ],
        #
        SDL_EventState => [
            [ 'uint32', 'int' ], 'uint8' => sub ( $inner, @etc ) { SDL_Yield(); $inner->(@etc) }
        ]
    };
    #
    #
    sub SDL_GetEventState ($type) { SDL_EventState( $type, SDL_QUERY ) }
    ffi->attach( SDL_RegisterEvents => ['int'] => 'uint32' );

    # From src/events/SDL_mouse_c.h
    package SDL2::Cursor {
        use SDL2::Utils;
        has
            next       => 'opaque',    # SDL_Cursor
            driverdata => 'opaque'     # void
    };

    # From SDL_mouse.h
    ffi->attach( SDL_GetMouseFocus         => [] => 'SDL_Window' );
    ffi->attach( SDL_GetMouseState         => [ 'int',        'int' ] => 'uint32' );
    ffi->attach( SDL_GetGlobalMouseState   => [ 'int',        'int' ] => 'uint32' );
    ffi->attach( SDL_GetRelativeMouseState => [ 'int',        'int' ] => 'uint32' );
    ffi->attach( SDL_WarpMouseInWindow     => [ 'SDL_Window', 'int', 'int' ] );
    ffi->attach( SDL_SetRelativeMouseMode  => ['bool'] => 'int' );
    ffi->attach( SDL_CaptureMouse          => ['bool'] => 'int' );
    ffi->attach( SDL_GetRelativeMouseMode  => []       => 'bool' );
    ffi->attach(
        SDL_CreateCursor => [ 'uint8', 'uint8', 'int', 'int', 'int', 'int' ] => 'SDL_Cursor' );
    ffi->attach( SDL_CreateSystemCursor => ['SDL_SystemCursor'] => 'SDL_Cursor' );
    ffi->attach( SDL_SetCursor          => ['SDL_Cursor'] );
    ffi->attach( SDL_GetCursor          => []      => 'SDL_Cursor' );
    ffi->attach( SDL_GetDefaultCursor   => []      => 'SDL_Cursor' );
    ffi->attach( SDL_FreeCursor         => []      => 'SDL_Cursor' );
    ffi->attach( SDL_ShowCursor         => ['int'] => 'int' );
    attach generic => { SDL_HasIntersection => [ [ 'SDL_Rect', 'SDL_Rect' ], 'SDL_bool' ] };
    #
    # XXX - From SDL_stding.h
    # Define a four character code as a Uint32
    sub SDL_FOURCC ( $A, $B, $C, $D ) {
        ( $A << 0 ) | ( $B << 8 ) | ( $C << 16 ) | ( $D << 24 );
    }

# Unsorted - https://github.com/libsdl-org/SDL/blob/c59d4dcd38c382a1e9b69b053756f1139a861574/include/SDL_keycode.h
#    https://github.com/libsdl-org/SDL/blob/c59d4dcd38c382a1e9b69b053756f1139a861574/include/SDL_scancode.h#L151
    attach(
        all => {

            # Unknown...
            SDL_SetMainReady => [ [] => 'void' ]
        }
    );

    # TODO
    package SDL2::assert_data {
        use SDL2::Utils;
        has;
    };

    package SDL2::_GameController {
        use SDL2::Utils;
        has;
    };

    package SDL2::GameCrontroller {
        use SDL2::Utils;
        has;
    };

    package SDL2::_Haptic {
        use SDL2::Utils;
        has;
    };

    package SDL2::Haptic {
        use SDL2::Utils;
        has;
    };

    package SDL2::_JoyStick {
        use SDL2::Utils;
        has;
    };
    attach messagebox => {

#SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, ("R.E.L.I.V.E. " + BuildString()).c_str(), msg, nullptr);
        SDL_ShowSimpleMessageBox => [ [ 'uint32', 'string', 'string', 'SDL_Window' ], 'int' ]
    };

    package SDL2::Mixer {
        use SDL2::Utils;
        has;
    };

    package SDL2::Mixer::Mix::Chunk {
        use SDL2::Utils;
        has;
    };

    package SDL2::Mixer::Mix::Fading {
        use SDL2::Utils;
        has;
    };

    package SDL2::Mixer::Mix::MusicType {
        use SDL2::Utils;
        has;
    };

    package SDL2::Mixer::Mix::Music {
        use SDL2::Utils;
        has;
    };

    package SDL2::Mixer::Chunk {
        use SDL2::Utils;
        has;
    };

    package SDL2::Mixer::Fading {
        use SDL2::Utils;
        has;
    };

    package SDL2::Mixer::MusicType {
        use SDL2::Utils;
        has;
    };

    package SDL2::Mixer::Music {
        use SDL2::Utils;
        has;
    };

    package SDL2::Image {
        use SDL2::Utils;
        has;
    };

    package SDL2::iconv_t {
        use SDL2::Utils;
        has;
    };    # int ptr

    package SDL2::TTF {
        use SDL2::Utils;
        has;
    };

    package SDL2::TTF::Image {
        use SDL2::Utils;
        has;
    };

    package SDL2::TTF::Font {
        use SDL2::Utils;
        has;
    };

    package SDL2::TTF::PosBuf {
        use SDL2::Utils;
        has;
    };

    package SDL2::Net {
        use SDL2::Utils;
        has;
    };

    package SDL2::RTF {
        use SDL2::Utils;
        has;
    };

    package SDL2::RTF::Context {
        use SDL2::Utils;
        has;
    };

    package SDL2::RTF::FontEngine {
        use SDL2::Utils;
        has;
    };

    package SDL2::Thread {
        use SDL2::Utils;
        has();
    }

    package SDL2::ShapeDriver { };

    package SDL2::VideoDisplay {
        use SDL2::Utils;
        has name              => 'opaque',    # string
            max_display_modes => 'int',
            num_display_modes => 'int',
            display_modes     => 'opaque',    # SDL_DisplayMode
            desktop_mode      => 'opaque',    # SDL_DisplayMode
            orientation       => 'opaque',    # SDL_DisplayOrientation
            fullscreen_window => 'opaque',    # SDL_Window
            device            => 'opaque',    # SDL_VideoDevice
            driverdata        => 'opaque';    # void *
    };

    package SDL2::VideoDevice {
        use SDL2::Utils;
        has;
    };

    package SDL2::WindowUserData {
        use SDL2::Utils;
        has name => 'opaque',                 # string
            data => 'opaque',                 # void *
            next => 'opaque';                 # SDL_WindowUserData
    };

    package SDL2::SysWMinfo {
        use SDL2::Utils;
        has;
    };

    package SDL2::VideoBootStrap {
        use SDL2::Utils;
        has;
    };

    # bundled code testing
    my $holder;
    attach
        debug  => { Bundle_SDL_PrintEvent => [ ['SDL_Event'] ], },
        events => { Bundle_SDL_Yield      => [ [] ], };

    #warn SDL2::SDLK_UP();
    #warn SDL2::SDLK_DOWN();
    # https://github.com/libsdl-org/SDL/blob/main/include/SDL_hints.h
    # Export symbols!
    our @EXPORT_OK = map {@$_} values %EXPORT_TAGS;

    #$EXPORT_TAGS{default} = [];             # Export nothing by default
    $EXPORT_TAGS{all} = \@EXPORT_OK;    # Export everything with :all tag

    #use Data::Dump;
    #ddx \%EXPORT_TAGS;
    #ddx \%SDL2::;
};
1;

=encoding utf-8

=head1 NAME

SDL2::FFI - FFI Wrapper for SDL (Simple DirectMedia Layer) Development Library

=head1 SYNOPSIS

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

=head1 DESCRIPTION

SDL2::FFI is an L<FFI::Platypus> backed bindings to the B<S>imple
B<D>irectMedia B<L>ayer - a cross-platform development library designed to
provide low level access to audio, keyboard, mouse, joystick, and graphics
hardware.

=head1 Initialization and Shutdown

The functions in this category are used to set SDL up for use and generally
have global effects in your program. These functions may be imported with the
C<:init> or C<:default> tag.

=head2 C<SDL_Init( ... )>

Initializes the SDL library. This must be called before using most other SDL
functions.

	SDL_Init( SDL_INIT_TIMER | SDL_INIT_VIDEO | SDL_INIT_EVENTS );

C<SDL_Init( ... )> simply forwards to calling L<< C<SDL_InitSubSystem( ...
)>|/C<SDL_InitSubSystem( ... )> >>. Therefore, the two may be used
interchangeably. Though for readability of your code L<< C<SDL_InitSubSystem(
... )>|/C<SDL_InitSubSystem( ... )> >> might be preferred.

The file I/O (for example: L<< C<SDL_RWFromFile( ... )>|/C<SDL_RWFromFile( ...
)> >>) and threading (L<< C<SDL_CreateThread( ... )>|/C<SDL_CreateThread( ...
)> >>) subsystems are initialized by default. Message boxes ( L<<
C<SDL_ShowSimpleMessageBox( ... )>|/C<SDL_ShowSimpleMessageBox( ... )> >> )
also attempt to work without initializing the video subsystem, in hopes of
being useful in showing an error dialog when SDL_Init fails. You must
specifically initialize other subsystems if you use them in your application.

Logging (such as L<< C<SDL_Log( ... )>|/C<SDL_Log( ... )> >> ) works without
initialization, too.

Expected parameters include:

=over

=item C<flags> which may be any be imported with the L<< C<:init>|SDL2::Enum/C<:init> >> tag and may be OR'd together

=back

Subsystem initialization is ref-counted, you must call L<< C<SDL_QuitSubSystem(
... )>|/C<SDL_QuitSubSystem( ... )> >> for each L<< C<SDL_InitSubSystem( ...
)>|/C<SDL_InitSubSystem( ... )> >> to correctly shutdown a subsystem manually
(or call L<< C<SDL_Quit( )>|/C<SDL_Quit( )> >> to force shutdown). If a
subsystem is already loaded then this call will increase the ref-count and
return.

Returns C<0> on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >> for more information.

=head2 C<SDL_InitSubSystem( ... )>

Compatibility function to initialize the SDL library.

In SDL2, this function and L<< C<SDL_Init( ... )>|/C<SDL_Init( ... )> >> are
interchangeable.

	SDL_InitSubSystem( SDL_INIT_TIMER | SDL_INIT_VIDEO | SDL_INIT_EVENTS );

Expected parameters include:

=over

=item C<flags> which may be any be imported with the L<< C<:init>|SDL2::Enum/C<:init> >> tag and may be OR'd together.

=back

Returns C<0> on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >> for more information.

=head2 C<SDL_Quit( )>

Clean up all initialized subsystems.

	SDL_Quit( );

You should call this function even if you have already shutdown each
initialized subsystem with L<< C<SDL_QuitSubSystem( )>|/C<SDL_QuitSubSystem( )>
>>. It is safe to call this function even in the case of errors in
initialization.

If you start a subsystem using a call to that subsystem's init function (for
example L<< C<SDL_VideoInit( )>|/C<SDL_VideoInit( )> >>) instead of L<<
C<SDL_Init( ... )>|/C<SDL_Init( ... )> >> or L<< C<SDL_InitSubSystem( ...
)>|/C<SDL_InitSubSystem( ... )> >>, then you must use that subsystem's quit
function (L<< C<SDL_VideoQuit( )>|/C<SDL_VideoQuit( )> >>) to shut it down
before calling C<SDL_Quit( )>. But generally, you should not be using those
functions directly anyhow; use L<< C<SDL_Init( ... )>|/C<SDL_Init( ... )> >>
instead.

You can use this function in an C<END { ... }> block to ensure that it is run
when your application is shutdown.

=head2 C<SDL_QuitSubSystem( ... )>

Shut down specific SDL subsystems.

	SDL_QuitSubSystem( SDL_INIT_VIDEO );

If you start a subsystem using a call to that subsystem's init function (for
example L<< C<SDL_VideoInit( )> |/C<SDL_VideoInit( )> >>) instead of L<<
C<SDL_Init( ... )>|/C<SDL_Init( ... )> >> or L<< C<SDL_InitSubSystem( ...
)>|/C<SDL_InitSubSystem( ... )> >>, L<< C<SDL_QuitSubSystem( ...
)>|/C<SDL_QuitSubSystem( ... )> >> and L<< C<SDL_WasInit( ...
)>|/C<SDL_WasInit( ... )> >> will not work. You will need to use that
subsystem's quit function ( L<< C<SDL_VideoQuit( )>|/C<SDL_VideoQuit( )> >>
directly instead. But generally, you should not be using those functions
directly anyhow; use L<< C<SDL_Init( ... )>|/C<SDL_Init( ... )> >> instead.

You still need to call L<< C<SDL_Quit( )>|/C<SDL_Quit( )> >> even if you close
all open subsystems with L<< C<SDL_QuitSubSystem( ... )>|/C<SDL_QuitSubSystem(
... )> >>.

Expected parameters include:

=over

=item C<flags> which may be any be imported with the L<< C<:init>|SDL2::Enum/C<:init> >> tag and may be OR'd together.

=back

=head2 C<SDL_WasInit( ... )>

Get a mask of the specified subsystems which are currently initialized.

	SDL_Init( SDL_INIT_VIDEO | SDL_INIT_AUDIO );
	warn SDL_WasInit( SDL_INIT_TIMER ); # false
	warn SDL_WasInit( SDL_INIT_VIDEO ); # true (32 == SDL_INIT_VIDEO)
	my $mask = SDL_WasInit( );
	warn 'video init!'  if ($mask & SDL_INIT_VIDEO); # yep
	warn 'video timer!' if ($mask & SDL_INIT_TIMER); # nope

Expected parameters include:

=over

=item C<flags> which may be any be imported with the L<< C<:init>|SDL2::Enum/C<:init> >> tag and may be OR'd together.

=back

If C<flags> is C<0>, it returns a mask of all initialized subsystems, otherwise
it returns the initialization status of the specified subsystems.

The return value does not include C<SDL_INIT_NOPARACHUTE>.

=head1 Atomic Operations

B<IMPORTANT>:

If you are not an expert in concurrent lockless programming, you should only be
using the atomic lock and reference counting functions in this file. In all
other cases you should be protecting your data structures with full mutexes.

The list of "safe" functions to use are:

=over

=item L<< C<SDL_AtomicLock( ... )>|/C<SDL_AtomicLock( ... )> >>

=item L<< C<SDL_AtomicUnlock( ... )>|/C<SDL_AtomicUnlock( ... )> >>

=item L<< C<SDL_AtomicIncRef( ... )>|/C<SDL_AtomicIncRef( ... )> >>

=item L<< C<SDL_AtomicDecRef( ... )>|/C<SDL_AtomicDecRef( ... )> >>

=back

B<Seriously, here be dragons!>

You can find out a little more about lockless programming and the subtle issues
that can arise here:
L<http://msdn.microsoft.com/en-us/library/ee418650%28v=vs.85%29.aspx>

There's also lots of good information here:

=over

=item L<http://www.1024cores.net/home/lock-free-algorithms>

=item L<http://preshing.com/>

=back

These operations may or may not actually be implemented using processor
specific atomic operations. When possible they are implemented as true
processor specific atomic operations. When that is not possible the are
implemented using locks that *do* use the available atomic operations.

All of the atomic operations that modify memory are full memory barriers.

=head2 C<SDL_SpinLock>

SDL AtomicLock.

The atomic locks are efficient spinlocks using CPU instructions, but are
vulnerable to starvation and can spin forever if a thread holding a lock has
been terminated.  For this reason you should minimize the code executed inside
an atomic lock and never do expensive things like API or system calls while
holding them.

The atomic locks are not safe to lock recursively.

=head2 C<SDL_AtomicTryLock( ... )>

Try to lock a spin lock by setting it to a non-zero value.

    SDL_AtomicTryLock( 1 );

B<Please note that spinlocks are dangerous if you don't know what you're doing.
Please be careful using any sort of spinlock!>

Expected parameters:

=over

=item C<lock> - a pointer to a lock variable

=back

Returns C<SDL_TRUE> if the lock succeeded, C<SDL_FALSE> if the lock is already
held.

=head2 C<SDL_AtomicLock( ... )>

Lock a spin lock by setting it to a non-zero value.

    SDL_AtomicLock( 1 );

B<Please note that spinlocks are dangerous if you don't know what you're doing.
Please be careful using any sort of spinlock!>

Expected parameters:

=over

=item C<lock> - a pointer to a lock variable

=back

Returns C<SDL_TRUE> if the lock succeeded, C<SDL_FALSE> if the lock is already
held.

=head2 C<SDL_AtomicUnlock( ... )>

Unlock a spin lock by setting it to C<0>.

    SDL_AtomicUnlock( 1 );

B<Please note that spinlocks are dangerous if you don't know what you're doing.
Please be careful using any sort of spinlock!>

Expected parameters:

=over

=item C<lock> - a pointer to a lock variable

=back

Always returns immediately.

=head1 Memory Barriers

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
L<http://preshing.com/20120913/acquire-and-release-semantics>

=head2 C<SDL_AtomicCAS( ... )>

Set an atomic variable to a new value if it is currently an old value.

    my $atomic = SDL2::atomic_t->new( { value => 100 } );
    SDL_AtomicCAS( $atomic, 100, 2 );

B<Note: If you don't know what this function is for, you shouldn't use it!>

Expected parameters include:

=over

=item C<a> - a pointer to an L<SDL2::atomic_t> to be modified

=item C<oldval> - the old value

=item C<newval> - the new value

=back

Returns C<SDL_TRUE> if the atomic variable was set, C<SDL_FALSE> otherwise.

=head2 C<SDL_AtomicSet( ... )>

Set an atomic variable to a value.

    my $atomic = SDL2::atomic_t->new({ value => 1 });
    my $prev = SDL_AtomicSet( $atomic, 100 );

This function also acts as a full memory barrier.

B<Note: If you don't know what this function is for, you shouldn't use it!>

Expected parameters include:

=over

=item C<a> - a pointer to an L<SDL2::atomic_t> structure to be modified

=item C<v> - the desired value

=back

Returns the previous value of the atomic variable.

=head2 C<SDL_AtomicGet( ... )>

Get the value of an atomic variable.

    my $atomic = SDL2::atomic_t->new({ value => 1 });
    my $value = SDL_AtomicSet( $atomic );

B<Note: If you don't know what this function is for, you shouldn't use it!>

Expected parameters include:

=over

=item C<a> - a pointer to an L<SDL2::atomic_t> variable

=back

Returns the current value of an atomic variable.

=head2 C<SDL_AtomicAdd( ... )>

Add to an atomic variable.

    my $atomic = SDL2::atomic_t->new({ value => 1 });
    my $value = SDL_AtomicAdd( $atomic, 4 );

This function also acts as a full memory barrier.

B<Note: If you don't know what this function is for, you shouldn't use it!>

=over

=item C<a> - a pointer to an L<SDL2::atomic_t> variable to be modified

=item C<v> - the desired value to add

=back

Returns the previous value of the atomic variable.

=head2 C<SDL_AtomicIncRef( ... )>

Increment an atomic variable.

    my $atomic = SDL2::atomic_t->new({ value => 1 });
    my $value = SDL_AtomicIncRef( $atomic );

Use may be used as a reference counter.

B<Note: If you don't know what this function is for, you shouldn't use it!>

=over

=item C<a> - a pointer to an L<SDL2::atomic_t> variable to increment

=back

Returns the previous value of the atomic variable.

=head2 C<SDL_AtomicDecRef( ... )>

Decrement an atomic variable.

    my $atomic = SDL2::atomic_t->new({ value => 1 });
    my $ok = SDL_AtomicDecRef( $atomic );

Use may be used as a reference counter.

B<Note: If you don't know what this function is for, you shouldn't use it!>

=over

=item C<a> - a pointer to an L<SDL2::atomic_t> variable to decrement

=back

Returns C<SDL_TRUE> if the variable reached zero after decrementing,
C<SDL_FALSE> otherwise.

=head1 Raw Audio Mixing

These functions provide raw access to the audio mixing buffer for the SDL
library.

=head2 C<SDL_AudioCallback>

This function is called when the audio device needs more data.

Parameters to expect include:

=over

=item C<userdata> - an application-specific parameter saved in the L<SDL2::AudioSpec> structure.

=item C<stream> - a pointer to the audio data buffer

=item C<len> - the length of that buffer in bytes

=back

Once the callback returns, the buffer will no longer be valid. Sterio samples
are stored in a C<LRLRLR> ordering.

You may choose to avoid callbacks and use L<< C<SDL_QueueAudio( ...
)>|/C<SDL_QueueAudio( ... )> >> instead, if you like. Just open your audio
device as a NULL callback.

=head2 C<SDL_AudioDeviceID>

SDL Audio Device IDs.

A successful call to L<< C<SDL_OpenAudio( ... )>|/C<SDL_OpenAudio( ... )> >> is
always device id 1, and legacy SDL audio APIs assume you want this device ID.
L<< C<SDL_OpenAudioDevice( ... )>|/C<SDL_OpenAudioDevice( ... )> >> calls
always returns devices >= 2 on success. The legacy calls are good both for
backwards compatibility and when you don't care about multiple, specific, or
capture devices.

=head2 C<SDL_GetNumAudioDrivers( )>

Returns the number of audio drivers.

    my $i = SDL_GetNumAudioDrivers( );

=head2 C<SDL_GetAudioDriver( ... )>

Returns the list of built in audio drivers, in the order that they were
normally initialized by default.

    for my $i (0 .. SDL_GetNumAudioDrivers() ) {
        CORE::say SDL_GetAudioDriver( $i );
    }

Expected parameters include:

=over

=item C<index> - index of the desired audio driver

=back

Returns the name of the driver.

=head2 C<SDL_AudioInit( ... )>

    SDL_AudioInit( 'alsa' );

This function is used internally, and should not be used unless you have a
specific need to specify the audio driver you want to use. You should normally
use L<< C<SDL_Init( ... )>|/C<SDL_Init( ... )> >> or L<< C<SDL_InitSubSystem(
... )>|/C<SDL_InitSubSystem( ... )> >>.

Expected parameters include:

=over

=item C<driver_name> - name of the driver to initialize

=back

Returns C<SDL_TRUE> on success.

=head2 C<SDL_AudioQuit( )>

    SDL_AudioQuit( )

This function is used internally, and should not be used unless you have a
specific need to specify the audio driver you want to use.

=head2 C<SDL_GetCurrentAudioDriver( )>

Get the name of the current audio driver.

    my $driver = SDL_GetCurrentAudioDriver( );

The returned string points to internal static memory and thus never becomes
invalid, even if you quit the audio subsystem and initialize a new driver
(although such a case would return a different static string from another call
to this function, of course). As such, you should not modify or free the
returned string.

Returns the name of the current audio driver or NULL if no driver has been
initialized.

=head2 C<SDL_OpenAudio( ... )>

This function is a legacy means of opening the audio device.

    my $ret = SDL_OpenAudio( $desired, $obtained );

This function remains for compatibility with SDL 1.2, but also because it's
slightly easier to use than the new functions in SDL 2.0. The new, more
powerful, and preferred way to do this is SDL_OpenAudioDevice().

This function is roughly equivalent to:

    SDL_OpenAudioDevice( (), 0, $desired, $obtained, SDL_AUDIO_ALLOW_ANY_CHANGE );

With two notable exceptions:

=over

=item - If `obtained` is NULL, we use `desired` (and allow no changes), which means desired will be modified to have the correct values for silence, etc, and SDL will convert any differences between your app's specific request and the hardware behind the scenes.

=item - The return value is always success or failure, and not a device ID, which means you can only have one device open at a time with this function.

=back

Expected parameters include:

=over

=item C<desired> - an L<SDL2::AudioSpec> structure representing the desired output format. Please refer to the SDL_OpenAudioDevice documentation for details on how to prepare this structure.

=item C<obtained> - an L<SDL2::AudioSpec> structure filled in with the actual parameters, or NULL.

=back

This function opens the audio device with the desired parameters, nd returns
C<0> if successful, placing the actual hardware parameters in the structure
pointed to by C<obtained>.

If C<obtained> is NULL, the audio data passed to the callback function will be
guaranteed to be in the requested format, and will be automatically converted
to the actual hardware audio format if necessary. If C<obtained> is NULL,
C<desired> will have fields modified.

This function returns a negative error code on failure to open the audio device
or failure to set up the audio thread; call C<SDL_GetError( )> for more
information.

=head2 C<SDL_GetNumAudioDevices( ... )>

Get the number of built-in audio devices.

This function is only valid after successfully initializing the audio
subsystem.

Note that audio capture support is not implemented as of SDL 2.0.4, so the
C<iscapture> parameter is for future expansion and should always be zero for
now.

This function will return -1 if an explicit list of devices can't be
determined. Returning -1 is not an error. For example, if SDL is set up to talk
to a remote audio server, it can't list every one available on the Internet,
but it will still allow a specific host to be specified in L<<
C<SDL_OpenAudioDevice( ... )>|/C<SDL_OpenAudioDevice( ... )> >>.

In many common cases, when this function returns a value <= 0, it can still
successfully open the default device (NULL for first argument of L<<
C<SDL_OpenAudioDevice( ... )>|/C<SDL_OpenAudioDevice( ... )> >>).

This function may trigger a complete redetect of available hardware.

Expected parameters include:

=over

=item C<iscapture> - zero to request playback devices, non-zero to request recording devices

=back

Returns the number of available devices exposed by the current driver or C<-1>
if an explicit list of devices can't be determined. A return value of C<-1>
does not necessarily mean an error condition.

=head2 C<SDL_GetAudioDeviceName( ... )>

    my $name = SDL_GetAudioDeviceName( 0, 1 );

Get the human-readable name of a specific audio device.

This function is only valid after successfully initializing the audio
subsystem. The values returned by this function reflect the latest call to L<<
C<SDL_GetNumAudioDevices( )>|/C<SDL_GetNumAudioDevices( )> >>; re-call that
function to redetect available hardware.

The string returned by this function is UTF-8 encoded, read-only, and managed
internally. You are not to free it. If you need to keep the string for any
length of time, you should make your own copy of it, as it will be invalid next
time any of several other SDL functions are called.

Expected parameters include:

=over

=item C<index> - the index of the audio device; valid values range from C<0> to C<SDL_GetNumAudioDevices( ) - 1>

=item C<iscapture> - non-zero to query the list of recording devices, zero to query the list of output devices

=back

Returns the name of the audio device at the requested index, or NULL on error.

=head2 C<SDL_GetAudioDeviceSpec( ... )>

Get the preferred audio format of a specific audio device.

This function is only valid after a successfully initializing the audio
subsystem. The values returned by this function reflect the latest call to
SDL_GetNumAudioDevices(); re-call that function to redetect available hardware.

C<spec> will be filled with the sample rate, sample format, and channel count.
All other values in the structure are filled with 0. When the supported struct
members are 0, SDL was unable to get the property from the backend.

Expected parameters include:

=over

=item C<index> - the index of the audio device; valid values range from C<0> to C<SDL_GetNumAudioDevices() - 1>

=item C<iscapture> - non-zero to query the list of recording devices, zero to query the list of output devices.

=item C<spec> - the C<SDL2::AudioSpec> to be initialized by this function

=back

Returns C<0> on success, nonzero on error.

=head2 C<SDL_OpenAudioDevice( ... )>

Open a specific audio device.

C<SDL_OpenAudio( ... )>, unlike this function, always acts on device ID 1. As
such, this function will never return a 1 so as not to conflict with the legacy
function.

Please note that SDL 2.0 before 2.0.5 did not support recording; as such, this
function would fail if `iscapture` was not zero. Starting with SDL 2.0.5,
recording is implemented and this value can be non-zero.

Passing in a C<device> name of NULL requests the most reasonable default (and
is equivalent to what SDL_OpenAudio() does to choose a device). The C<device>
name is a UTF-8 string reported by C<SDL_GetAudioDeviceName()>, but some
drivers allow arbitrary and driver-specific strings, such as a hostname/IP
address for a remote audio server, or a filename in the diskaudio driver.

When filling in the desired audio spec structure:

=over

=item - C<< $desired->freq >> should be the frequency in sample-frames-per-second (Hz).

=item - C<< $desired->format >> should be the audio format (`AUDIO_S16SYS`, etc).

=item - C<< $desired->samples >> is the desired size of the audio buffer, in _sample frames_ (with stereo output, two samples--left and right--would make a single sample frame).

This number should be a power of two, and may be adjusted by the audio driver
to a value more suitable for the hardware.  Good values seem to range between
512 and 8096 inclusive, depending on the application and CPU speed.  Smaller
values reduce latency, but can lead to underflow if the application is doing
heavy processing and cannot fill the audio buffer in time. Note that the number
of sample frames is directly related to time by the following formula: C<ms =
(sampleframes*1000)/freq>

=item - C<< $desired->size >> is the size in _bytes_ of the audio buffer, and is
calculated by C<SDL_OpenAudioDevice()>. You don't initialize this.

=item - C<< $desired->silence >> is the value used to set the buffer to silence, and is calculated by SDL_OpenAudioDevice(). You don't initialize this.

=item - C<< $desired->callback >> should be set to a function that will be called when the audio device is ready for more data.

It is passed a pointer to the audio buffer, and the length in bytes of the
audio buffer.

This function usually runs in a separate thread, and so you should protect data
structures that it accesses by calling C<SDL_LockAudioDevice()> and
C<SDL_UnlockAudioDevice()> in your code. Alternately, you may pass a NULL
pointer here, and call C<SDL_QueueAudio()> with some frequency, to queue more
audio samples to be played (or for capture devices, call C<SDL_DequeueAudio()>
with some frequency, to obtain audio samples).

=item - C<< $desired->userdata >> is passed as the first parameter to your callback function. If you passed a NULL callback, this value is ignored.

=back

C<allowed_changes> can have the following flags OR'd together:

=over

=item C<SDL_AUDIO_ALLOW_FREQUENCY_CHANGE>

=item C<SDL_AUDIO_ALLOW_FORMAT_CHANGE>

=item C<SDL_AUDIO_ALLOW_CHANNELS_CHANGE>

=item C<SDL_AUDIO_ALLOW_ANY_CHANGE>

=back

These flags specify how SDL should behave when a device cannot offer a specific
feature. If the application requests a feature that the hardware doesn't offer,
SDL will always try to get the closest equivalent.

For example, if you ask for float32 audio format, but the sound card only
supports int16, SDL will set the hardware to int16. If you had set
C<SDL_AUDIO_ALLOW_FORMAT_CHANGE>, SDL will change the format in the C<obtained>
structure. If that flag was *not* set, SDL will prepare to convert your
callback's float32 audio to int16 before feeding it to the hardware and will
keep the originally requested format in the C<obtained> structure.

If your application can only handle one specific data format, pass a zero for
C<allowed_changes> and let SDL transparently handle any differences.

An opened audio device starts out paused, and should be enabled for playing by
calling C<SDL_PauseAudioDevice($devid, 0)> when you are ready for your audio
callback function to be called. Since the audio driver may modify the requested
size of the audio buffer, you should allocate any local mixing buffers after
you open the audio device.

The audio callback runs in a separate thread in most cases; you can prevent
race conditions between your callback and other threads without fully pausing
playback with C<SDL_LockAudioDevice()>. For more information about the
callback, see L<SDL2::AudioSpec>

Expected parameters include:

=over

=item C<device> - a UTF-8 string reported by C<SDL_GetAudioDeviceName()> or a driver-specific name as appropriate. NULL requests the most reasonable default device

=item C<iscapture> - non-zero to specify a device should be opened for recording, not playback

=item C<desired> - an L<SDL2::AudioSpec> structure representing the desired output format; see C<SDL_OpenAudio()> for more information

=item C<obtained> - an SDL_AudioSpec structure filled in with the actual output format; see C<SDL_OpenAudio()> for more information

=item C<allowed_changes> - C<0>, or one or more flags OR'd together

=back

Returns a valid device ID that is > 0 on success or 0 on failure; call
C<SDL_GetError( )> for more information.

For compatibility with SDL 1.2, this will never return C<1>, since SDL reserves
that ID for the legacy C<SDL_OpenAudio( )> function.

=head2 C<SDL_GetAudioStatus( )>

Get the current audio status for the current device.

    my $status = SDL_GetAudioStatus( );

Returns a L<< C<SDL_AudioStatus>|SDL2::Enum/C<:audioStatus> >> value.

=head2 C<SDL_GetAudioDeviceStatus( ... )>

Get the current audio status for the current device.

    my $status = SDL_GetAudioStatus( 4 );

Expected parameters include:

=over

=item C<dev> - Device id

=back

Returns a L<< C<SDL_AudioStatus>|SDL2::Enum/C<:audioStatus> >> value.

=head2 C<SDL_PauseAudio( ... )>

Pause the audio callback processing for the current device.

    SDL_PauseAudio( 1 );

This should be called with a parameter of C<0> after opening the audio device
to start playing sound.  This is so you can safely initialize data for your
callback function after opening the audio device. Silence will be written to
the audio device during the pause.

Expected parameters include:

=over

=item C<pause_on> - a boolean value

=back

=head2 C<SDL_PauseAudioDevice( ... )>

Pause the audio callback processing for the given device.

    SDL_PauseAudioDevice( 1 );

This should be called with a parameter of C<0> after opening the audio device
to start playing sound.  This is so you can safely initialize data for your
callback function after opening the audio device. Silence will be written to
the audio device during the pause.

Expected parameters include:

=over

=item C<dev> - a device id

=item C<pause_on> - a boolean value

=back

=head2 C<SDL_LoadWAV_RW( ... )>

Load the audio data of a WAVE file into memory.

    SDL_LoadWAV_RW(SDL_RWFromFile("sample.wav", "rb"), 1, $spec, $buf, $len);

Loading a WAVE file requires C<src>, C<spec>, C<audio_buf> and C<audio_len> to
be valid pointers. The entire data portion of the file is then loaded into
memory and decoded if necessary.

If C<freesrc> is non-zero, the data source gets automatically closed and freed
before the function returns.

Supported formats are RIFF WAVE files with the formats PCM (8, 16, 24, and 32
bits), IEEE Float (32 bits), Microsoft ADPCM and IMA ADPCM (4 bits), and A-law
and mu-law (8 bits). Other formats are currently unsupported and cause an
error.

If this function succeeds, the pointer returned by it is equal to C<spec> and
the pointer to the audio data allocated by the function is written to
C<audio_buf> and its length in bytes to C<audio_len>. The L<SDL2::AudioSpec>
members C<freq>, C<channels>, and C<format> are set to the values of the audio
data in the buffer. The C<samples> member is set to a sane default and all
others are set to zero.

It's necessary to use C<SDL_FreeWAV( )> to free the audio data returned in
C<audio_buf> when it is no longer used.

Because of the specification of the .WAV format, there are many problematic
files in the wild that cause issues with strict decoders. To provide
compatibility with these files, this decoder is lenient in regards to the
truncation of the file, the fact chunk, and the size of the RIFF chunk. The
hints C<SDL_HINT_WAVE_RIFF_CHUNK_SIZE>, C<SDL_HINT_WAVE_TRUNCATION>, and
C<SDL_HINT_WAVE_FACT_CHUNK> can be used to tune the behavior of the loading
process.

Any file that is invalid (due to truncation, corruption, or wrong values in the
headers), too big, or unsupported causes an error. Additionally, any critical
I/O error from the data source will terminate the loading process with an
error. The function returns NULL on error and in all cases (with the exception
of `src` being NULL), an appropriate error message will be set.

It is required that the data source supports seeking.

Note that the C<SDL_LoadWAV( ... )> macro does this same thing for you, but in
a less messy way:

    SDL_LoadWAV("sample.wav", $spec, $buf, $len);

Expected parameters include:

=over

=item C<src> - The data source for the WAVE data

=item C<freesrc> - If non-zero, SDL will _always_ free the data source

=item C<spec> - An L<SDL2::AudioSpec> that will be filled in with the wave file's format details

=item C<audio_buf> - A pointer filled with the audio data, allocated by the function

=item C<audio_len> - A pointer filled with the length of the audio data buffer in bytes

=back

This function, if successfully called, returns C<spec>, which will be filled
with the audio data format of the wave source data. C<audio_buf> will be filled
with a pointer to an allocated buffer containing the audio data, and
C<audio_len> is filled with the length of that audio buffer in bytes.

This function returns NULL if the .WAV file cannot be opened, uses an unknown
data format, or is corrupt; call C<SDL_GetError( )> for more information.

When the application is done with the data returned in C<audio_buf>, it should
call C<SDL_FreeWAV( )> to dispose of it.

=head2 C<SDL_LoadWAV( ... )>

Loads a WAV from a file.

    SDL_LoadWAV("sample.wav", $spec, $buf, $len);

Expected parameters include:

=over

=item C<src> - The data source for the WAVE data

=item C<spec> - An L<SDL2::AudioSpec> that will be filled in with the wave file's format details

=item C<audio_buf> - A pointer filled with the audio data, allocated by the function

=item C<audio_len> - A pointer filled with the length of the audio data buffer in bytes

=back

This is a wrapper for L<< C<SDL_LoadWAV_RW( ... )>|/C<SDL_LoadWAV_RW( ... )> >>
and returns the same data.

=head2 C<SDL_FreeWAV( ... )>

Free data previously allocated with L<< C<SDL_LoadWAV( ... )>|/C<SDL_LoadWAV(
... )> >> or L<< C<SDL_LoadWAV_RW( ... )>|/C<SDL_LoadWAV_RW( ... )> >>.

    SDL_FreeWAV( $data );

After a WAVE file has been opened with L<< C<SDL_LoadWAV( ...
)>|/C<SDL_LoadWAV( ... )> >> or L<< C<SDL_LoadWAV_RW( ... )>|/C<SDL_LoadWAV_RW(
... )> >>, its data can eventually be freed with C<SDL_FreeWAV( ... )>. It is
safe to call this function with a NULL pointer.

Expected parameters include:

=over

=item C<audio_buf> - a pointer to the buffer created by L<< C<SDL_LoadWAV( ... )>|/C<SDL_LoadWAV( ... )> >> or L<< C<SDL_LoadWAV_RW( ... )>|/C<SDL_LoadWAV_RW( ... )> >>

=back

=head2 C<SDL_BuildAudioCVT( ... )>

Initialize an L<SDL2::AudioCVT> structure for conversion.



Before an L<SDL2::AudioCVT> structure can be used to convert audio data it must
be initialized with source and destination information.

This function will zero out every field of the L<SDL2::AudioCVT>, so it must be
called before the application fills in the final buffer information.

Once this function has returned successfully, and reported that a conversion is
necessary, the application fills in the rest of the fields in
L<SDL2::AudioCVT>, now that it knows how large a buffer it needs to allocate,
and then can call C<SDL_ConvertAudio( ... )> to complete the conversion.

Expected parameters include:

=over

=item C<cvt> - an L<SDL2::AudioCVT> structure filled in with audio conversion information

=item C<src_format> - the source format of the audio data; for more info see L<SDL2::AudioFormat>

=item C<src_channels> - the number of channels in the source

=item C<src_rate> - the frequency (sample-frames-per-second) of the source

=item C<dst_format> - the destination format of the audio data; for more info see L<SDL2::AudioFormat>

=item C<dst_channels> the number of channels in the destination

=item C<dst_rate> - the frequency (sample-frames-per-second) of the destination

=back

Returns C<1> if the audio filter is prepared, C<0> if no conversion is needed,
or a negative error code on failure; call L<< C<SDL_GetError(
)>|/C<SDL_GetError( )> >> for more information.

=head2 C<SDL_ConvertAudio( ... )>

Convert audio data to a desired audio format.

This function does the actual audio data conversion, after the application has
called C<SDL_BuildAudioCVT( )> to prepare the conversion information and then
filled in the buffer details.

Once the application has initialized the C<cvt> structure using
C<SDL_BuildAudioCVT( )>, allocated an audio buffer and filled it with audio
data in the source format, this function will convert the buffer, in-place, to
the desired format.

The data conversion may go through several passes; any given pass may possibly
temporarily increase the size of the data. For example, SDL might expand 16-bit
data to 32 bits before resampling to a lower frequency, shrinking the data size
after having grown it briefly. Since the supplied buffer will be both the
source and destination, converting as necessary in-place, the application must
allocate a buffer that will fully contain the data during its largest
conversion pass. After C<SDL_BuildAudioCVT( )> returns, the application should
set the C<< cvt->len >> field to the size, in bytes, of the source data, and
allocate a buffer that is C<< cvt->len * cvt->len_mult >> bytes long for the
C<buf> field.

The source data should be copied into this buffer before the call to
C<SDL_ConvertAudio( )>. Upon successful return, this buffer will contain the
converted audio, and C<< cvt->len_cvt >> will be the size of the converted
data, in bytes. Any bytes in the buffer past `cvt->len_cvt` are undefined once
this function returns.

=over

=item C<cvt> - an L<SDL2::AudioCVT> structure that was previously set up by C<SDL_BuildAudioCVT( )>

=back

Returns C<0> if the conversion was completed successfully or a negative error
code on failure; call L<< C<SDL_GetError( )>|/C<SDL_GetError( )> >> for more
information.

=head2 C<SDL_NewAudioStream( ... )>

Create a new audio stream.

Expected parameters include:

=over

=item C<src_format> - The format of the source audio

=item C<src_channels> - The number of channels of the source audio

=item C<src_rate> - The sampling rate of the source audio

=item C<dst_format> - The format of the desired audio output

=item C<dst_channels> - The number of channels of the desired audio output

=item C<dst_rate> - The sampling rate of the desired audio output

=back

Returns C<0> on success, or C<-1> on error.

=head2 C<SDL_AudioStreamPut( ... )>

Add data to be converted/resampled to the stream.

Expected parameters include:

=over

=item C<stream> - The stream the audio data is being added to

=item C<buf> - A pointer to the audio data to add

=item C<len> - The number of bytes to write to the stream

=back

Returns C<0> on success, or C<-1> on error.

=head2 C<SDL_AudioStreamGet( ... )>

Get converted/resampled data from the stream.

Expected parameters include:

=over

=item C<stream> - The stream the audio is being requested from

=item C<buf> - A buffer to fill with audio data

=item C<len> - The maximum number of bytes to fill

=back

Returns the number of bytes read from the stream, or C<-1> on error.

=head2 C<SDL_AudioStreamAvailable( ... )>

Get the number of converted/resampled bytes available.

    my $samples = SDL_AudioStreamAvailable( $stream );

The stream may be buffering data behind the scenes until it has enough to
resample correctly, so this number might be lower than what you expect, or even
be zero. Add more data or flush the stream if you need the data now.

Expected parameters include:

=over

=item C<stream> - The stream being queried

=back

Returns the number of samples.

=head2 C<SDL_AudioStreamFlush( ... )>

Tell the stream that you're done sending data, and anything being buffered
should be converted/resampled and made available immediately.

It is legal to add more data to a stream after flushing, but there will be
audio gaps in the output. Generally this is intended to signal the end of
input, so the complete output becomes available.

Expected parameters include:

=over

=item C<stream> - An L<SDL2::AudioStream>

=back

Returns the number of samples.

=head2 C<SDL_AudioStreamClear( ... )>

Clear any pending data in the stream without converting it.

Expected parameters include:

=over

=item C<stream> - The stream being cleared

=back

=head2 C<SDL_FreeAudioStream( ... )>

Free an audio stream.

Expected parameters include:

=over

=item C<stream> - The stream being freed

=back

=head2 C<SDL_MixAudio( ... )>

This function is a legacy means of mixing audio.

This function is equivalent to calling

    SDL_MixAudioFormat( $dst, $src, $format, $len, $volume );

where C<format> is the obtained format of the audio device from the legacy
C<SDL_OpenAudio( ... )> function.

Expected parameters include:

=over

=item C<dst> - the destination for the mixed audio

=item C<src> - the source audio buffer to be mixed

=item C<len> - the length of the audio buffer in bytes

=item C<volume> - ranges from C<0 - 128>, and should be set to C<SDL_MIX_MAXVOLUME> for full audio volume

=back

=head2 C<SDL_MixAudioFormat( ... )>

Mix audio data in a specified format.

This takes an audio buffer C<src> of C<len> bytes of C<format> data and mixes
it into C<dst>, performing addition, volume adjustment, and overflow clipping.
The buffer pointed to by C<dst> must also be C<len> bytes of C<format> data.

This is provided for convenience -- you can mix your own audio data.

Do not use this function for mixing together more than two streams of sample
data. The output from repeated application of this function may be distorted by
clipping, because there is no accumulator with greater range than the input
(not to mention this being an inefficient way of doing it).

It is a common misconception that this function is required to write audio data
to an output stream in an audio callback. While you can do that,
C<SDL_MixAudioFormat( ... )> is really only needed when you're mixing a single
audio stream with a volume adjustment.

Expected parameters include:

=over

=item C<dst> - the destination for the mixed audio

=item C<src> - the source audio buffer to be mixed

=item C<format> - the SDL_AudioFormat structure representing the desired audio format

=item C<len> - the length of the audio buffer in bytes

=item C<volume> - ranges from C<0 - 128>, and should be set to C<SDL_MIX_MAXVOLUME> for full audio volume

=back

=head2 C<SDL_QueueAudio( ... )>

Queue more audio on non-callback devices.

If you are looking to retrieve queued audio from a non-callback capture device,
you want C<SDL_DequeueAudio( ... )> instead. C<SDL_QueueAudio( ... )> will
return C<-1> to signify an error if you use it with capture devices.

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

You should not call C<SDL_LockAudio( ... )> on the device before queueing; SDL
handles locking internally for this function.

Expected parameters include:

=over

=item C<dev> - the device ID to which we will queue audio

=item C<data> - the data to queue to the device for later playback

=item C<len> - the number of bytes (not samples!) to which C<data> points

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_DequeueAudio( ... )>

Dequeue more audio on non-callback devices.

If you are looking to queue audio for output on a non-callback playback device,
you want C<SDL_QueueAudio( ... )> instead. C<SDL_DequeueAudio( ... )> will
always return C<0> if you use it with playback devices.

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
need captured audio for some length of time, use C<SDL_PauseAudioDevice( )> to
stop the capture device from queueing more data. This can be useful during,
say, level loading times. When unpaused, capture devices will start queueing
data from that point, having flushed any capturable data available while
paused.

This function is thread-safe, but dequeueing from the same device from two
threads at once does not promise which thread will dequeue data first.

You may not dequeue audio from a device that is using an application-supplied
callback; doing so returns an error. You have to use the audio callback, or
dequeue audio with this function, but not both.

You should not call C<SDL_LockAudio( ... )> on the device before dequeueing;
SDL handles locking internally for this function.

Expected parameters include:

=over

=item C<dev> - the device ID from which we will dequeue audio

=item C<data> - a pointer into where audio data should be copied

=item C<len> - the number of bytes (not samples!) to which (data) points

=back

Returns the number of bytes dequeued, which could be less than requested; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GetQueuedAudioSize( ... )>

Get the number of bytes of still-queued audio.

For playback devices: this is the number of bytes that have been queued for
playback with C<SDL_QueueAudio( )>, but have not yet been sent to the hardware.

Once we've sent it to the hardware, this function can not decide the exact byte
boundary of what has been played. It's possible that we just gave the hardware
several kilobytes right before you called this function, but it hasn't played
any of it yet, or maybe half of it, etc.

For capture devices, this is the number of bytes that have been captured by the
device and are waiting for you to dequeue. This number may grow at any time, so
this only informs of the lower-bound of available data.

You may not queue or dequeue audio on a device that is using an
application-supplied callback; calling this function on such a device always
returns C<0>. You have to use the audio callback or queue audio, but not both.

You should not call C<SDL_LockAudio( )> on the device before querying; SDL
handles locking internally for this function.

Expected parameters:

=over

=item C<dev> - the device ID of which we will query queued audio size

=back

Returns the number of bytes (not samples!) of queued audio.

=head2 C<SDL_ClearQueuedAudio( ... )>

Drop any queued audio data waiting to be sent to the hardware.

Immediately after this call, C<SDL_GetQueuedAudioSize( )> will return C<0>. For
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

You should not call C<SDL_LockAudio( )> on the device before clearing the
queue; SDL handles locking internally for this function.

Expected parameters include:

=over

=item C<dev> - the device ID of which to clear the audio queue

=back

This function always succeeds and thus returns void.

=head2 C<SDL_CloseAudio( )>


=head2 C<SDL_CloseAudioDevice( ... )>

Expected parameters include:

=over

=item C<dev> - device id

=back

=head1 Audio lock functions

The lock manipulated by these functions protects the callback function. During
a L<< C<SDL_LockAudio( )>|/C<SDL_LockAudio( )> >>/L<< <SDL_UnlockAudio(
)>|/<SDL_UnlockAudio( )> >> pair, you can be guaranteed that the callback
function is not running. Do not call these from the callback function or you
will cause deadlock.

=head2 C<SDL_LockAudio( )>



=head2 C<SDL_LockAudioDevice( ... )>

Expected parameters include:

=over

=item C<dev> - device id

=back

=head2 C<SDL_UnlockAudio( )>



=head2 C<SDL_UnlockAudioDevice( ... )>

Expected parameters include:

=over

=item C<dev> - device id

=back

=head1 Blend mode for renderers

The functions C<SDL_SetRenderDrawBlendMode( ... )> and
C<SDL_SetTextureBlendMode( ... )> accept the L<SDL2::BlendMode> returned by
this function if the renderer supports it.

=head2 C<SDL_ComposeCustomBlendMode( ... )>

Compose a custom blend mode for renderers.

A blend mode controls how the pixels from a drawing operation (source) get
combined with the pixels from the render target (destination). First, the
components of the source and destination pixels get multiplied with their blend
factors. Then, the blend operation takes the two products and calculates the
result that will get stored in the render target.

Expressed in pseudocode, it would look like this:

    $dstRGB = colorOperation( $srcRGB * $srcColorFactor, $dstRGB * $dstColorFactor );
    $dstA   = alphaOperation( $srcA * $srcAlphaFactor, $dstA * $dstAlphaFactor );

Where the functions C<colorOperation( $src, $dst)> and C<alphaOperation( $src,
$dst )> can return one of the following:

=over

=item - C<$src + $dst>

=item - C<$src - $dst>

=item - C<$dst - $src>

=item - C<min($src, $dst)>

=item - C<max($src, $dst)>

=back

The red, green, and blue components are always multiplied with the first,
second, and third components of the C<SDL_BlendFactor>, respectively. The
fourth component is not used.

The alpha component is always multiplied with the fourth component of the
C<SDL_BlendFactor>. The other components are not used in the alpha calculation.

Support for these blend modes varies for each renderer. To check if a specific
C<SDL_BlendMode> is supported, create a renderer and pass it to either
C<SDL_SetRenderDrawBlendMode> or C<SDL_SetTextureBlendMode>. They will return
with an error if the blend mode is not supported.

This list describes the support of custom blend modes for each renderer in SDL
2.0.6. All renderers support the four blend modes listed in the
C<SDL_BlendMode> enumeration.

=over

=item B<direct3d>: Supports C<SDL_BLENDOPERATION_ADD> with all factors.

=item B<direct3d11>: Supports all operations with all factors. However, some factors produce unexpected results with C<SDL_BLENDOPERATION_MINIMUM> and C<SDL_BLENDOPERATION_MAXIMUM>.

=item B<opengl>: Supports the C<SDL_BLENDOPERATION_ADD> operation with all factors. OpenGL versions 1.1, 1.2, and 1.3 do not work correctly with SDL 2.0.6.

=item B<opengles>: Supports the C<SDL_BLENDOPERATION_ADD> operation with all factors. Color and alpha factors need to be the same. OpenGL ES 1 implementation specific: May also support C<SDL_BLENDOPERATION_SUBTRACT> and C<SDL_BLENDOPERATION_REV_SUBTRACT>. May support color and alpha operations being different from each other. May support color and alpha factors being different from each other.

=item B<opengles2>: Supports the C<SDL_BLENDOPERATION_ADD>, C<SDL_BLENDOPERATION_SUBTRACT>, C<SDL_BLENDOPERATION_REV_SUBTRACT> operations with all factors.

=item B<psp>: No custom blend mode support.

=item B<software>: No custom blend mode support.

=back

Some renderers do not provide an alpha component for the default render target.
The C<SDL_BLENDFACTOR_DST_ALPHA> and C<SDL_BLENDFACTOR_ONE_MINUS_DST_ALPHA>
factors do not have an effect in this case.

Expected parameters include:

=over

=item C<srcColorFactor> - the SDL_BlendFactor applied to the red, green, and blue components of the source pixels

=item C<dstColorFactor> - the SDL_BlendFactor applied to the red, green, and blue components of the destination pixels

=item C<colorOperation> - the SDL_BlendOperation used to combine the red, green, and blue components of the source and destination pixels

=item C<srcAlphaFactor> - the C<SDL_BlendFactor> applied to the alpha component of the source pixels

=item C<dstAlphaFactor> - the C<SDL_BlendFactor> applied to the alpha component of the destination pixels

=item C<alphaOperation> - the C<SDL_BlendOperation> used to combine the alpha component of the source and destination pixels

=back

Returns an C<SDL_BlendMode> that represents the chosen factors and operations.

=head1 Clipboard

Functions in this section expose the clipboard. SDL's video subsystem must be
initialized to get or modify clipboard text.

=head2 C<SDL_SetClipboardText( ... )>

Put UTF-8 text into the clipboard.

    SDL_SetClipboardText( 'Hello, world!' );

=over

=item C<text> - the text to store in the clipboard

=back

Returns C<0> on success or a negative error code on failure; call
C<SDL_GetError( )> for more information.

=head2 C<SDL_GetClipboardText( )>

Get UTF-8 text from the clipboard, which must be freed with C<SDL_free( )>.

    my $clipboard = SDL_GetClipboardText( );

This functions returns NULL if there was not enough memory left for a copy of
the clipboard's content.

Returns the clipboard text on success or NULL on failure; call C<SDL_GetError(
)> for more information. Caller must call C<SDL_free( )> on the returned
pointer when done with it.

=head2 C<SDL_HasClipboardText( )>

Query whether the clipboard exists and contains a non-empty text string.

    if ( SDL_HasClipboardText( ) ) {
        ...
    }

Returns C<SDL_TRUE> if the clipboard has text, or C<SDL_FALSE> if it does not.

=head1 CPU Feature Detection

These functions may be imported with the C<:cpuinfo> tag.

=head2 C<SDL_GetCPUCount( )>

Get the number of CPU cores available.

    my $cores = SDL_GetCPUCount( );

Returns the total number of logical CPU cores. On CPUs that include
technologies such as hyperthreading, the number of logical cores may be more
than the number of physical cores.

=head2 C<SDL_GetCPUCacheLineSize( )>

Determine the L1 cache line size of the CPU.

    my $cache = SDL_GetCPUCacheLineSize( );

This is useful for determining multi-threaded structure padding or SIMD
prefetch sizes.

Returns the L1 cache line size of the CPU, in bytes.

=head2 C<SDL_HasRDTSC( )>

Determine whether the CPU has the RDTSC instruction.

    my $rdtsc = SDL_HasRDTSC( );

This always returns false on CPUs that aren't using Intel instruction sets.

Returns C<SDL_TRUE> if the CPU has the RDTSC instruction or C<SDL_FALSE> if
not.

=head2 C<SDL_HasAltiVec( )>

Determine whether the CPU has AltiVec features.

    my $altiVec = SDL_HasAltiVec( );

This always returns false on CPUs that aren't using PowerPC instruction sets.

Returns C<SDL_TRUE> if the CPU has AltiVec features or C<SDL_FALSE> if not.

=head2 C<SDL_HasMMX( )>

Determine whether the CPU has MMX features.

    my $mmx = SDL_HasMMX( );

This always returns false on CPUs that aren't using Intel instruction sets.

Returns C<SDL_TRUE> if the CPU has MMX features or C<SDL_FALSE> if not.

=head2 C<SDL_Has3DNow( )>

Determine whether the CPU has 3DNow! features.

    my $_3dnow = SDL_Has3DNow( );

This always returns false on CPUs that aren't using AMD instruction sets.

Returns C<SDL_TRUE> if the CPU has 3DNow! features or C<SDL_FALSE> if not.

=head2 C<SDL_HasSSE( )>

Determine whether the CPU has SSE features.

    my $sse = SDL_HasSSE( );

This always returns false on CPUs that aren't using Intel instruction sets.

Returns C<SDL_TRUE> if the CPU has SSE features or C<SDL_FALSE> if not.

=head2 C<SDL_HasSSE2( )>

Determine whether the CPU has SSE2 features.

    my $sse2 = SDL_HasSSE2( );

This always returns false on CPUs that aren't using Intel instruction sets.

Returns C<SDL_TRUE> if the CPU has SSE2 features or C<SDL_FALSE> if not.

=head2 C<SDL_HasSSE3( )>

Determine whether the CPU has SSE3 features.

    my $sse3 = SDL_HasSSE3( );

This always returns false on CPUs that aren't using Intel instruction sets.

Returns C<SDL_TRUE> if the CPU has SSE3 features or C<SDL_FALSE> if not.

=head2 C<SDL_HasSSE41( )>

Determine whether the CPU has SSE4.1 features.

    my $sse41 = SDL_HasSSE41( );

This always returns false on CPUs that aren't using Intel instruction sets.

Returns C<SDL_TRUE> if the CPU has SSE4.1 features or C<SDL_FALSE> if not.

=head2 C<SDL_HasSSE42( )>

Determine whether the CPU has SSE4.2 features.

    my $sse42 = SDL_HasSSE42( );

This always returns false on CPUs that aren't using Intel instruction sets.

Returns C<SDL_TRUE> if the CPU has SSE4.2 features or C<SDL_FALSE> if not.

=head2 C<SDL_HasAVX( )>

Determine whether the CPU has AVX features.

    my $avx = SDL_HasAVX( );

This always returns false on CPUs that aren't using Intel instruction sets.

Returns C<SDL_TRUE> if the CPU has AVX features or C<SDL_FALSE> if not.

=head2 C<SDL_HasAVX2( )>

Determine whether the CPU has AVX2 features.

    my $avx2 = SDL_HasAVX2( );

This always returns false on CPUs that aren't using Intel instruction sets.

Returns C<SDL_TRUE> if the CPU has AVX2 features or C<SDL_FALSE> if not.

=head2 C<SDL_HasAVX512F( )>

Determine whether the CPU has AVX-512F (foundation) features.

    my $avx512 = SDL_HasAVX512F( );

This always returns false on CPUs that aren't using Intel instruction sets.

Returns C<SDL_TRUE> if the CPU has AVX-512F features or C<SDL_FALSE> if not.

=head2 C<SDL_HasARMSIMD( )>

Determine whether the CPU has ARM SIMD (ARMv6) features.

    my $arm6 = SDL_HasARMSIMD( );

This is different from ARM NEON, which is a different instruction set.

This always returns false on CPUs that aren't using ARM instruction sets.

Returns C<SDL_TRUE> if the CPU has ARM SIMD features or C<SDL_FALSE> if not.

=head2 C<SDL_HasNEON( )>

Determine whether the CPU has NEON (ARM SIMD) features.

    my $neon = SDL_HasNEON( );

This always returns false on CPUs that aren't using ARM instruction sets.

Returns C<SDL_TRUE> if the CPU has ARM NEON features or C<SDL_FALSE> if not.

=head2 C<SDL_GetSystemRAM( )>

Get the amount of RAM configured in the system.

    my $mb = SDL_GetSystemRAM( );

Returns the amount of RAM configured in the system in MB.

=head2 C<SDL_SIMDGetAlignment( )>

Report the alignment this system needs for SIMD allocations.

    my $size = SDL_SIMDGetAlignment( );

This will return the minimum number of bytes to which a pointer must be aligned
to be compatible with SIMD instructions on the current machine. For example, if
the machine supports SSE only, it will return 16, but if it supports AVX-512F,
it'll return 64 (etc). This only reports values for instruction sets SDL knows
about, so if your SDL build doesn't have L<< C<SDL_HasAVX512F(
)>|/C<SDL_HasAVX512F( )> >>, then it might return 16 for the SSE support it
sees and not 64 for the AVX-512 instructions that exist but SDL doesn't know
about. Plan accordingly.

Returns alignment in bytes needed for available, known SIMD instructions.

=head2 C<SDL_SIMDAlloc( ... )>

Allocate memory in a SIMD-friendly way.

    my $ptr = SDL_SIMDAlloc( 1024 * 64 );

This will allocate a block of memory that is suitable for use with SIMD
instructions. Specifically, it will be properly aligned and padded for the
system's supported vector instructions.

The memory returned will be padded such that it is safe to read or write an
incomplete vector at the end of the memory block. This can be useful so you
don't have to drop back to a scalar fallback at the end of your SIMD processing
loop to deal with the final elements without overflowing the allocated buffer.

You must free this memory with L<< C<SDL_FreeSIMD( )>|/C<SDL_FreeSIMD( )> >>,
not L<< C<SDL_free( ... )>|/C<SDL_free( ... )> >> C<undef>, variable scope
tricks, etc.

Note that SDL will only deal with SIMD instruction sets it is aware of; for
example, SDL 2.0.8 knows that SSE wants 16-byte vectors (L<< C<SDL_HasSSE(
)>|/C<SDL_HasSSE( )> >>), and AVX2 wants 32 bytes (L<< C<SDL_HasAVX2(
)>|/C<SDL_HasAVX2( )> >>), but doesn't know that AVX-512 wants 64. To be clear:
if you can't decide to use an instruction set with an C<SDL_Has*( )> function,
don't use that instruction set with memory allocated through here.

C<SDL_AllocSIMD( 0 )> will return a non-NULL pointer, assuming the system isn't
out of memory, but you are not allowed to dereference it (because you only own
zero bytes of that buffer).

Expected parameters include:

=over

=item C<len> - The length, in bytes, of the block to allocate. The actual allocated block might be larger due to padding, etc.

=back

Returns a pointer to newly-allocated block, NULL if out of memory.

=head2 C<SDL_SIMDRealloc( ... )>

Reallocate memory obtained from L<< C<SDL_SIMDAlloc( ... )>|/C<SDL_SIMDAlloc(
... )> >>.

    $ptr = SDL_SIMDRealloc( $ptr, 1024 * 32 );

It is not valid to use this function on a pointer from anything but L<<
C<SDL_SIMDAlloc( ... )>|/C<SDL_SIMDAlloc( ... )> >>. It can't be used on
pointers from malloc, realloc, SDL_malloc, memalign, new, etc.

Expected parameters include:

=over

=item C<mem> - The pointer obtained from L<< C<SDL_SIMDAlloc( ... )>|/C<SDL_SIMDAlloc( ... )> >>. This function also accepts NULL, at which point this function is the same as calling L<< C<SDL_SIMDAlloc( ... )>|/C<SDL_SIMDAlloc( ... )> >> with a NULL pointer.

=item C<len> - The length, in bytes, of the block to allocated. The actual allocated block might be larger due to padding, etc. Passing C<0> will return a non-NULL pointer, assuming the system isn't out of memory.

=back

Returns a pointer to newly-reallocated block, NULL if out of memory.

=head2 C<SDL_SIMDFree( )>

Deallocate memory obtained from L<< C<SDL_SIMDAlloc( ... )>|/C<SDL_SIMDAlloc(
... )> >>.

    SDL_SIMDFree( $ptr );

It is not valid to use this function on a pointer from anything but L<<
C<SDL_SIMDAlloc( ... )>|/C<SDL_SIMDAlloc( ... )> >> or L<< C<SDL_SIMDRealloc(
... )>|/C<SDL_SIMDRealloc( ... )> >>. It can't be used on pointers from malloc,
realloc, SDL_malloc, memalign, new, etc.

However, C<SDL_SIMDFree( undef )> is a legal no-op.

The memory pointed to by C<ptr> is no longer valid for access upon return, and
may be returned to the system or reused by a future allocation. The pointer
passed to this function is no longer safe to dereference once this function
returns, and should be discarded.

Expected parameters include:

=over

=item C<ptr> - The pointer, returned from L<< C<SDL_SIMDAlloc( ... )>|/C<SDL_SIMDAlloc( ... )> >> or L<< C<SDL_SIMDRealloc( ... )>|/C<SDL_SIMDRealloc( ... )> >>, to deallocate. NULL is a legal no-op.

=back

=head1 Error Handling

Functions in this category provide simple error message routines for SDL. L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >> can be called for almost all SDL
functions to determine what problems are occurring. Check the wiki page of each
specific SDL function to see whether L<< C<SDL_GetError( )>|/C<SDL_GetError( )>
>> is meaningful for them or not. These functions may be imported with the
C<:error> tag.

The SDL error messages are in English.

=head2 C<SDL_SetError( ... )>

Set the SDL error message for the current thread.

Calling this function will replace any previous error message that was set.

This function always returns C<-1>, since SDL frequently uses C<-1> to signify
an failing result, leading to this idiom:

	if ($error_code) {
		return SDL_SetError( 'This operation has failed: %d', $error_code );
	}

Expected parameters:

=over

=item C<fmt>

a C<printf( )>-style message format string

=item C<@params>

additional parameters matching % tokens in the C<fmt> string, if any

=back

=head2 C<SDL_GetError( )>

Retrieve a message about the last error that occurred on the current thread.

	warn SDL_GetError( );

It is possible for multiple errors to occur before calling C<SDL_GetError( )>.
Only the last error is returned.

The message is only applicable when an SDL function has signaled an error. You
must check the return values of SDL function calls to determine when to
appropriately call C<SDL_GetError( )>. You should B<not> use the results of
C<SDL_GetError( )> to decide if an error has occurred! Sometimes SDL will set
an error string even when reporting success.

SDL will B<not> clear the error string for successful API calls. You B<must>
check return values for failure cases before you can assume the error string
applies.

Error strings are set per-thread, so an error set in a different thread will
not interfere with the current thread's operation.

The returned string is internally allocated and must not be freed by the
application.

Returns a message with information about the specific error that occurred, or
an empty string if there hasn't been an error message set since the last call
to L<< C<SDL_ClearError( )>|/C<SDL_ClearError( )> >>. The message is only
applicable when an SDL function has signaled an error. You must check the
return values of SDL function calls to determine when to appropriately call
C<SDL_GetError( )>.

=head2 C<SDL_GetErrorMsg( ... )>

Get the last error message that was set for the current thread.

	my $x;
	warn SDL_GetErrorMsg($x, 300);

This allows the caller to copy the error string into a provided buffer, but
otherwise operates exactly the same as L<< C<SDL_GetError( )>|/C<SDL_GetError(
)> >>.

=over

=item C<errstr>

A buffer to fill with the last error message that was set for the current
thread

=item C<maxlen>

The size of the buffer pointed to by the errstr parameter

=back

Returns the pointer passed in as the C<errstr> parameter.

=head2 C<SDL_ClearError( )>

Clear any previous error message for this thread.

    SDL_ClearError( );

=head2 C<SDL_Error( ... )>

Set the current error to a member of the L<<
C<<SDL_errorcode>|SDL2::Enum/C<:errorcode> >> enum.

    SDL_Error( SDL_EFWRITE );

Unconditionally returns C<-1>.

=head1 Event loop

=head2 C<SDL_PumpEvents( )>

Pump the event loop, gathering events from the input devices.

    SDL_PumpEvents( );

This function updates the event queue and internal input device state.

B<WARNING>: This should only be run in the thread that initialized the video
subsystem, and for extra safety, you should consider only doing those things on
the main thread in any case.

C<SDL_PumpEvents( )> gathers all the pending input information from devices and
places it in the event queue. Without calls to C<SDL_PumpEvents( )> no events
would ever be placed on the queue. Often the need for calls to
C<SDL_PumpEvents( )> is hidden from the user since L<< C<SDL_PollEvent(
)>|/C<SDL_PollEvent( )> >> and L<< C<SDL_WaitEvent( )>|/C<SDL_WaitEvent( )> >>
implicitly call C<SDL_PumpEvents( )>. However, if you are not polling or
waiting for events (e.g. you are filtering them), then you must call
C<SDL_PumpEvents( )> to force an event queue update.










































=head1 Configuration Variables

This category contains functions to set and get configuration hints, as well as
listing each of them alphabetically.

The convention for naming hints is C<SDL_HINT_X>, where C<SDL_X> is the
environment variable that can be used to override the default. You may import
those recognised by SDL2 with the L<< C<:hints>|SDL2::Enum/C<:hints> >> tag.

In general these hints are just that - they may or may not be supported or
applicable on any given platform, but they provide a way for an application or
user to give the library a hint as to how they would like the library to work.

=head2 C<SDL_SetHintWithPriority( ... )>

Set a hint with a specific priority.

	SDL_SetHintWithPriority( SDL_EVENT_LOGGING, 2, SDL_HINT_OVERRIDE );

The priority controls the behavior when setting a hint that already has a
value. Hints will replace existing hints of their priority and lower.
Environment variables are considered to have override priority.

Expected parameters include:

=over

=item C<name>

the hint to set

=item C<value>

the value of the hint variable

=item C<priority>

the priority level for the hint

=back

Returns a true if the hint was set, untrue otherwise.

=head2 C<SDL_SetHint( ... )>

Set a hint with normal priority.

	SDL_SetHint( SDL_HINT_XINPUT_ENABLED, 1 );

Hints will not be set if there is an existing override hint or environment
variable that takes precedence. You can use SDL_SetHintWithPriority( ) to set
the hint with override priority instead.

Expected parameters:

=over

=item C<name>

the hint to set

=item C<value>

the value of the hint variable

=back

Returns a true value if the hint was set, untrue otherwise.

=head2 C<SDL_GetHint( ... )>

Get the value of a hint.

	SDL_GetHint( SDL_HINT_XINPUT_ENABLED );

Expected parameters:

=over

=item C<name>

the hint to query

=back

Returns the string value of a hint or an undefined value if the hint isn't set.

=head2 C<SDL_GetHintBoolean( ... )>

Get the boolean value of a hint variable.

	SDL_GetHintBoolean( SDL_HINT_XINPUT_ENABLED, 0);

Expected parameters:

=over

=item C<name>

the name of the hint to get the boolean value from

=item C<default_value>

the value to return if the hint does not exist

=back

Returns the boolean value of a hint or the provided default value if the hint
does not exist.

=head2 C<SDL_AddHintCallback( ... )>

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

=over

=item C<name>

the hint to watch

=item C<callback>

a code reference that will be called when the hint value changes

=item C<userdata>

a pointer to pass to the callback function

=back

Returns a pointer to a L<FFI::Platypus::Closure> which you may pass to L<<
C<SDL_DelHintCallback( ... )>|/C<SDL_DelHintCallback( ... )> >>.

=head2 C<SDL_DelHintCallback( ... )>

Remove a callback watching a particular hint.

	SDL_AddHintCallback(
		SDL_HINT_XINPUT_ENABLED,
		$cb,
		{ time => time( ), clicks => 3 }
	);

Expected parameters:

=over

=item C<name>

the hint to watch

=item C<callback>

L<FFI::Platypus::Closure> object returned by L<< C<SDL_AddHintCallback( ...
)>|/C<SDL_AddHintCallback( ... )> >>

=item C<userdata>

a pointer to pass to the callback function

=back

=head2 C<SDL_ClearHints( )>

Clear all hints.

	SDL_ClearHints( );

This function is automatically called during L<< C<SDL_Quit( )>|/C<SDL_Quit( )>
>>.

=head1 Log Handling

Simple log messages with categories and priorities. These functions may be
imported with the C<:logging> tag.

By default, logs are quiet but if you're debugging SDL you might want:

	SDL_LogSetAllPriority( SDL_LOG_PRIORITY_WARN );

Here's where the messages go on different platforms:

	Windows		debug output stream
	Android		log output
	Others		standard error output (STDERR)

Messages longer than the maximum size (4096 bytes) will be truncated.

=head2 C<SDL_LogSetAllPriority( ... )>

Set the priority of all log categories.

	SDL_LogSetAllPriority( SDL_LOG_PRIORITY_WARN );

Expected parameters:

=over

=item C<priority>

The SDL_LogPriority to assign. These may be imported with the L<<
C<:logpriority>|/C<:logpriority> >> tag.

=back

=head2 C<SDL_LogSetPriority( ... )>

Set the priority of all log categories.

	SDL_LogSetPriority( SDL_LOG_CATEGORY_APPLICATION, SDL_LOG_PRIORITY_WARN );

Expected parameters:

=over

=item C<category>

The category to assign a priority to. These may be imported with the L<<
C<:logcategory>|/C<:logcategory> >> tag.

=item C<priority>

The SDL_LogPriority to assign. These may be imported with the L<<
C<:logpriority>|/C<:logpriority> >> tag.

=back

=head2 C<SDL_LogGetPriority( ... )>

Get the priority of a particular log category.

	SDL_LogGetPriority( SDL_LOG_CATEGORY_ERROR );

Expected parameters:

=over

=item C<category>

The SDL_LogCategory to query. These may be imported with the L<<
C<:logcategory>|/C<:logcategory> >> tag.

=back

=head2 C<SDL_LogGetPriority( ... )>

Get the priority of a particular log category.

	SDL_LogGetPriority( SDL_LOG_CATEGORY_ERROR );

Expected parameters:

=over

=item C<category>

The SDL_LogCategory to query. These may be imported with the L<<
C<:logcategory>|/C<:logcategory> >> tag.

=back

=head2 C<SDL_LogResetPriorities( )>

Reset all priorities to default.

	SDL_LogResetPriorities( );

This is called by L<< C<SDL_Quit( )>|/C<SDL_Quit( )> >>.

=head2 C<SDL_Log( ... )>

Log a message with C<SDL_LOG_CATEGORY_APPLICATION> and
C<SDL_LOG_PRIORITY_INFO>.

	SDL_Log( 'HTTP Status: %s', $http->status );

Expected parameters:

=over

=item C<fmt>

A C<sprintf( )> style message format string.

=item C<...>

Any additional parameters matching C<%> tokens in the C<fmt> string, if any.

=back

=head2 C<SDL_LogVerbose( ... )>

Log a message with C<SDL_LOG_PRIORITY_VERBOSE>.

	SDL_LogVerbose( 'Current time: %s [%ds exec]', +localtime( ), time - $^T );

Expected parameters:

=over

=item C<category>

The category of the message.

=item C<fmt>

A C<sprintf( )> style message format string.

=item C<...>

Additional parameters matching C<%> tokens in the C<fmt> string, if any.

=back

=head2 C<SDL_LogDebug( ... )>

Log a message with C<SDL_LOG_PRIORITY_DEBUG>.

	SDL_LogDebug( 'Current time: %s [%ds exec]', +localtime( ), time - $^T );

Expected parameters:

=over

=item C<category>

The category of the message.

=item C<fmt>

A C<sprintf( )> style message format string.

=item C<...>

Additional parameters matching C<%> tokens in the C<fmt> string, if any.

=back

=head2 C<SDL_LogInfo( ... )>

Log a message with C<SDL_LOG_PRIORITY_INFO>.

	SDL_LogInfo( 'Current time: %s [%ds exec]', +localtime( ), time - $^T );

Expected parameters:

=over

=item C<category>

The category of the message.

=item C<fmt>

A C<sprintf( )> style message format string.

=item C<...>

Additional parameters matching C<%> tokens in the C<fmt> string, if any.

=back

=head2 C<SDL_LogWarn( ... )>

Log a message with C<SDL_LOG_PRIORITY_WARN>.

	SDL_LogWarn( 'Current time: %s [%ds exec]', +localtime( ), time - $^T );

Expected parameters:

=over

=item C<category>

The category of the message.

=item C<fmt>

A C<sprintf( )> style message format string.

=item C<...>

Additional parameters matching C<%> tokens in the C<fmt> string, if any.

=back

=head2 C<SDL_LogError( ... )>

Log a message with C<SDL_LOG_PRIORITY_ERROR>.

	SDL_LogError( 'Current time: %s [%ds exec]', +localtime( ), time - $^T );

Expected parameters:

=over

=item C<category>

The category of the message.

=item C<fmt>

A C<sprintf( )> style message format string.

=item C<...>

Additional parameters matching C<%> tokens in the C<fmt> string, if any.

=back

=head2 C<SDL_LogCritical( ... )>

Log a message with C<SDL_LOG_PRIORITY_CRITICAL>.

	SDL_LogCritical( 'Current time: %s [%ds exec]', +localtime( ), time - $^T );

Expected parameters:

=over

=item C<category>

The category of the message.

=item C<fmt>

A C<sprintf( )> style message format string.

=item C<...>

Additional parameters matching C<%> tokens in the C<fmt> string, if any.

=back

=head2 C<SDL_LogMessage( ... )>

Log a message with the specified category and priority.

	SDL_LogMessage( SDL_LOG_CATEGORY_APPLICATION, SDL_LOG_PRIORITY_CRITICAL,
					'Current time: %s [%ds exec]', +localtime( ), time - $^T );

Expected parameters:

=over

=item C<category>

The category of the message.

=item C<priority>

The priority of the message.

=item C<fmt>

A C<sprintf( )> style message format string.

=item C<...>

Additional parameters matching C<%> tokens in the C<fmt> string, if any.

=back

=head2 C<SDL_LogSetOutputFunction( ... )>

Replace the default log output function with one of your own.

	my $cb = SDL_LogSetOutputFunction( sub { ... }, {} );

Expected parameters:

=over

=item C<callback>

A coderef to call instead of the default callback.

This coderef should expect the following parameters:

=over

=item C<userdata>

What was passed as C<userdata> to C<SDL_LogSetOutputFunction( )>.

=item C<category>

The category of the message.

=item C<priority>

The priority of the message.

=item C<message>

The message being output.

=back

=item C<userdata>

Data passed to the C<callback>.

=back

=head1 Querying SDL Version

These functions are used to collect or display information about the version of
SDL that is currently being used by the program or that it was compiled
against.

The version consists of three segments (C<X.Y.Z>)

=over

=item X - Major Version, which increments with massive changes, additions, and enhancements

=item Y - Minor Version, which increments with backwards-compatible changes to the major revision

=item Z - Patchlevel, which increments with fixes to the minor revision

=back

Example: The first version of SDL 2 was 2.0.0

The version may also be reported as a 4-digit numeric value where the thousands
place represents the major version, the hundreds place represents the minor
version, and the tens and ones places represent the patchlevel (update
version).

Example: The first version number of SDL 2 was 2000

=head2 C<SDL_GetVersion( ... )>

Get the version of SDL that is linked against your program.

	my $ver = SDL2::Version->new;
	SDL_GetVersion( $ver );

This function may be called safely at any time, even before L<< C<SDL_Init(
)>|/C<SDL_Init( )> >>.

Expected parameters include:

=over

=item C<version> - An SDL2::Version object which will be filled with the proper values

=back

=head1 Display and Window Management

This category contains functions for handling display and window actions.

These functions may be imported with the C<:video> tag.

=head2 C<SDL_GetNumVideoDrivers( )>

	my $num = SDL_GetNumVideoDrivers( );

Get the number of video drivers compiled into SDL.

Returns a number >= 1 on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >> for more information.

=head2 C<SDL_GetVideoDriver( ... )>

Get the name of a built in video driver.

    CORE::say SDL_GetVideoDriver($_) for 0 .. SDL_GetNumVideoDrivers( ) - 1;

The video drivers are presented in the order in which they are normally checked
during initialization.

Expected parameters include:

=over

=item C<index> - the index of a video driver

=back

Returns the name of the video driver with the given C<index>.

=cut

=head2 C<SDL_VideoInit( ... )>

Initialize the video subsystem, optionally specifying a video driver.

	SDL_VideoInit( 'x11' );

This function initializes the video subsystem, setting up a connection to the
window manager, etc, and determines the available display modes and pixel
formats, but does not initialize a window or graphics mode.

If you use this function and you haven't used the SDL_INIT_VIDEO flag with
either SDL_Init( ) or SDL_InitSubSystem( ), you should call SDL_VideoQuit( )
before calling SDL_Quit( ).

It is safe to call this function multiple times. SDL_VideoInit( ) will call
SDL_VideoQuit( ) itself if the video subsystem has already been initialized.

You can use SDL_GetNumVideoDrivers( ) and SDL_GetVideoDriver( ) to find a
specific `driver_name`.

Expected parameters include:

=over

=item C<driver_name> - the name of a video driver to initialize, or undef for the default driver

=back

Returns C<0> on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >> for more information.

=head2 C<SDL_VideoQuit( )>

Shut down the video subsystem, if initialized with L<< C<SDL_VideoInit(
)>|/C<SDL_VideoInit( )> >>.

	SDL_VideoQuit( );

This function closes all windows, and restores the original video mode.

=head2 C<SDL_GetCurrentVideoDriver( )>

Get the name of the currently initialized video driver.

	my $driver = SDL_GetCurrentVideoDriver( );

Returns the name of the current video driver or NULL if no driver has been
initialized.

=head2 C<SDL_GetNumVideoDisplays( )>

Get the number of available video displays.

	my $screens = SDL_GetNumVideoDisplays( );

Returns a number >= 1 or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >> for more information.

=head2 C<SDL_GetDisplayName( ... )>


Get the name of a display in UTF-8 encoding.

	my $screen = SDL_GetDisplayName( 0 );

Expected parameters include:

=over

=item C<displayIndex> - the index of display from which the name should be queried

=back

Returns the name of a display or undefined for an invalid display index or
failure; call L<< C<SDL_GetError( )>|/C<SDL_GetError( )> >> for more
information.

=head2 C<SDL_GetDisplayBounds( ... )>

Get the desktop area represented by a display.

	my $rect = SDL_GetDisplayBounds( 0 );

The primary display (C<displayIndex == 0>) is always located at 0,0.

Expected parameters include:

=over

=item C<displayIndex> - the index of the display to query

=back

Returns the SDL2::Rect structure filled in with the display bounds on success
or a negative error code on failure; call L<< C<SDL_GetError(
)>|/C<SDL_GetError( )> >> for more information.


=head2 C<SDL_GetDisplayUsableBounds( ... )>

Get the usable desktop area represented by a display.

	my $rect = SDL_GetDisplayUsableBounds( 0 );

The primary display (C<displayIndex == 0>) is always located at 0,0.

This is the same area as L<< C<SDL_GetDisplayBounds( ...
)>|/C<SDL_GetDisplayBounds( ... )> >> reports, but with portions reserved by
the system removed. For example, on Apple's macOS, this subtracts the area
occupied by the menu bar and dock.

Setting a window to be fullscreen generally bypasses these unusable areas, so
these are good guidelines for the maximum space available to a non-fullscreen
window.

Expected parameters include:

=over

=item C<displayIndex> - the index of the display to query

=back

Returns the SDL2::Rect structure filled in with the display bounds on success
or a negative error code on failure; call L<< C<SDL_GetError(
)>|/C<SDL_GetError( )> >> for more information. This function also returns
C<-1> if the parameter C<displayIndex> is out of range.

=head2 C<SDL_GetDisplayDPI( ... )>

Get the dots/pixels-per-inch for a display.

	my ( $ddpi, $hdpi, $vdpi ) = SDL_GetDisplayDPI( 0 );

Diagonal, horizontal and vertical DPI can all be optionally returned if the
appropriate parameter is non-NULL.

A failure of this function usually means that either no DPI information is
available or the C<displayIndex> is out of range.

Expected parameters include:

=over

=item C<displayIndex> - the index of the display from which DPI information should be queried

=back

Returns C<[ddpi, hdpi, vdip]> on success or a negative error code on failure;
call L<< C<SDL_GetError( )>|/C<SDL_GetError( )> >> for more information.

C<ddpi> is the diagonal DPI of the display, C<hdpi> is the horizontal DPI of
the display, C<vdpi> is the vertical DPI of the display.

=head2 C<SDL_GetDisplayOrientation( ... )>

Get the orientation of a display.

	my $orientation = SDL_GetDisplayOrientation( 0 );

Expected parameters include:

=over

=item C<displayIndex> - the index of the display to query

=back

Returns a value which may be imported with C<:displayOrientation> or
C<SDL_ORIENTATION_UNKNOWN> if it isn't available.

=head2 C<SDL_GetNumDisplayModes( ... )>

Get the number of available display modes.

	my $modes = SDL_GetNumDisplayModes( 0 );

The C<displayIndex> needs to be in the range from C<0> to
C<SDL_GetNumVideoDisplays( ) - 1>.

Expected parameters include:

=over

=item C<displayIndex> - the index of the display to query

=back

Returns a number >= 1 on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( > >> for more information.


=head2 C<SDL_GetDisplayMode( ... )>

Get information about a specific display mode.

	my $mode = SDL_GetDisplayMode( 0, 0 );

The display modes are sorted in this priority:

=over

=item width - largest to smallest

=item height - largest to smallest

=item bits per pixel - more colors to fewer colors

=item packed pixel layout - largest to smallest

=item refresh rate - highest to lowest

=back

Expected parameters include:

=over

=item C<displayIndex> - the index of the display to query

=item C<modeIndex> - the index of the display mode to query

=back

Returns an L<SDL2::DisplayMode> structure filled in with the mode at
C<modeIndex> on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >> for more information.

=head2 C<SDL_GetDesktopDisplayMode( ... )>

Get information about the desktop's display mode.

	my $mode = SDL_GetDesktopDisplayMode( 0 );

There's a difference between this function and L<< C<SDL_GetCurrentDisplayMode(
... )>|/C<SDL_GetCurrentDisplayMode( ... )> >> when SDL runs fullscreen and has
changed the resolution. In that case this function will return the previous
native display mode, and not the current display mode.

Expected parameters include:

=over

=item C<displayIndex> - the index of the display to query

=back

Returns an L<SDL2::DisplayMode> structure filled in with the current display
mode on success or a negative error code on failure; call L<< C<SDL_GetError(
)>|/C<SDL_GetError( )> >> for more information.

=head2 C<SDL_GetCurrentDisplayMode( ... )>

	my $mode = SDL_GetCurrentDisplayMode( 0 );

There's a difference between this function and L<< C<SDL_GetDesktopDisplayMode(
... )>|/C<SDL_GetDesktopDisplayMode( ... )> >> when SDL runs fullscreen and has
changed the resolution. In that case this function will return the current
display mode, and not the previous native display mode.

Expected parameters include:

=over

=item C<displayIndex> - the index of the display to query

=back

Returns an L<SDL2::DisplayMode> structure filled in with the current display
mode on success or a negative error code on failure; call L<< C<SDL_GetError(
)>|/C<SDL_GetError( )> >> for more information.

=head2 C<SDL_GetClosestDisplayMode( ... )>

Get the closes match to the requested display mode.

	$mode = SDL_GetClosestDisplayMode( 0, $mode );

The available display modes are scanned and he closest mode matching the
requested mode is returned. The mode format and refresh rate default to the
desktop mode if they are set to 0. The modes are scanned with size being first
priority, format being second priority, and finally checking the refresh rate.
If all the available modes are too small, then an undefined value is returned.

Expected parameters include:

=over

=item C<displayIndex> - index of the display to query

=item C<mode> - an L<SDL2::DisplayMode> structure containing the desired display mode

=item C<closest> - an L<SDL2::DisplayMode> structure filled in with the closest match of the available display modes

=back

Returns the passed in value C<closest> or an undefined value if no matching
video mode was available; call L<< C<SDL_GetError( )>|/C<SDL_GetError( )> >>
for more information.

=head2 C<SDL_GetWindowDisplayIndex( ... )>

Get the index of the display associated with a window.

	my $index = SDL_GetWindowDisplayIndex( $window );

Expected parameters include:

=over

=item C<window>	- the window to query

=back

Returns the index of the display containing the center of the window on success
or a negative error code on failure; call  L<< C<SDL_GetError(
)>|/C<SDL_GetError( )> >> for more information.

=head2 C<SDL_SetWindowDisplayMode( ... )>

Set the display mode to use when a window is visible at fullscreen.

	my $ok = !SDL_SetWindowDisplayMode( $window, $mode );

This only affects the display mode used when the window is fullscreen. To
change the window size when the window is not fullscreen, use L<<
C<SDL_SetWindowSize( ... )>|/C<SDL_SetWindowSize( ... )> >>.

=head2 C<SDL_GetWindowDisplayMode( ... )>

Query the display mode to use when a window is visible at fullscreen.

	my $mode = SDL_GetWindowDisplayMode( $window );

Expected parameters include:

=over

=item C<window> - the window to query

=back

Returns a L<SDL2::DisplayMode> structure on success or a negative error code on
failure; call L<< C<SDL_GetError( )>|/C<SDL_GetError( )> >> for more
information.

=head2 C<SDL_GetWindowPixelFormat( ... )>

Get the pixel format associated with the window.

	my $format = SDL_GetWindowPixelFormat( $window );

Expected parameters include:

=over

=item C<window> - the window to query

=back

Returns the pixel format of the window on success or C<SDL_PIXELFORMAT_UNKNOWN>
on failure; call L<< C<SDL_GetError( )>|/C<SDL_GetError( )> >> for more
information.

=head2 C<SDL_CreateWindow( ... )>

Create a window with the specified position, dimensions, and flags.

    my $window = SDL_CreateWindow( 'Example',
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
        1280, 720,
      	SDL_WINDOW_SHOWN
    );

C<flags> may be any of the following OR'd together:

=over

=item C<SDL_WINDOW_FULLSCREEN> - fullscreen window

=item C<SDL_WINDOW_FULLSCREEN_DESKTOP> - fullscreen window at desktop resolution

=item C<SDL_WINDOW_OPENGL> - window usable with an OpenGL context

=item C<SDL_WINDOW_VULKAN> - window usable with a Vulkan instance

=item C<SDL_WINDOW_METAL> - window usable with a Metal instance

=item C<SDL_WINDOW_HIDDEN> - window is not visible

=item C<SDL_WINDOW_BORDERLESS> - no window decoration

=item C<SDL_WINDOW_RESIZABLE> - window can be resized

=item C<SDL_WINDOW_MINIMIZED> - window is minimized

=item C<SDL_WINDOW_MAXIMIZED> - window is maximized

=item C<SDL_WINDOW_INPUT_GRABBED> - window has grabbed input focus

=item C<SDL_WINDOW_ALLOW_HIGHDPI> - window should be created in high-DPI mode if supported (>= SDL 2.0.1)

=back

C<SDL_WINDOW_SHOWN> is ignored by C<SDL_CreateWindow( ... )>. The SDL_Window is
implicitly shown if C<SDL_WINDOW_HIDDEN> is not set. C<SDL_WINDOW_SHOWN> may be
queried later using L<< C<SDL_GetWindowFlags( ... )>|/C<SDL_GetWindowFlags( ...
)> >>.

On Apple's macOS, you B<must> set the NSHighResolutionCapable Info.plist
property to YES, otherwise you will not receive a High-DPI OpenGL canvas.

If the window is created with the C<SDL_WINDOW_ALLOW_HIGHDPI> flag, its size in
pixels may differ from its size in screen coordinates on platforms with
high-DPI support (e.g. iOS and macOS). Use L<< C<SDL_GetWindowSize( ...
)>|/C<SDL_GetWindowSize( ... )> >> to query the client area's size in screen
coordinates, and L<< C<SDL_GL_GetDrawableSize( )>|/C<SDL_GL_GetDrawableSize( )>
>> or L<< C<SDL_GetRendererOutputSize( )>|/C<SDL_GetRendererOutputSize( )> >>
to query the drawable size in pixels.

If the window is set fullscreen, the width and height parameters C<w> and C<h>
will not be used. However, invalid size parameters (e.g. too large) may still
fail. Window size is actually limited to 16384 x 16384 for all platforms at
window creation.

If the window is created with any of the C<SDL_WINDOW_OPENGL> or
C<SDL_WINDOW_VULKAN> flags, then the corresponding LoadLibrary function
(SDL_GL_LoadLibrary or SDL_Vulkan_LoadLibrary) is called and the corresponding
UnloadLibrary function is called by L<< C<SDL_DestroyWindow( ...
)>|/C<SDL_DestroyWindow( ... )> >>.

If C<SDL_WINDOW_VULKAN> is specified and there isn't a working Vulkan driver,
C<SDL_CreateWindow( ... )> will fail because L<< C<SDL_Vulkan_LoadLibrary(
)>|/C<SDL_Vulkan_LoadLibrary( )> >> will fail.

If C<SDL_WINDOW_METAL> is specified on an OS that does not support Metal,
C<SDL_CreateWindow( ... )> will fail.

On non-Apple devices, SDL requires you to either not link to the Vulkan loader
or link to a dynamic library version. This limitation may be removed in a
future version of SDL.

Expected parameters include:

=over

=item C<title> - the title of the window, in UTF-8 encoding

=item C<x> - the x position of the window, C<SDL_WINDOWPOS_CENTERED>, or C<SDL_WINDOWPOS_UNDEFINED>

=item C<y> - the y position of the window, C<SDL_WINDOWPOS_CENTERED>, or C<SDL_WINDOWPOS_UNDEFINED>

=item C<w> - the width of the window, in screen coordinates

=item C<h> - the height of the window, in screen coordinates

=item C<flags> - 0, or one or more L<< C<:windowFlags>|SDL2::Enum/C<:windowFlags> >> OR'd together

=back

Returns the window that was created or an undefined value on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >> for more information.


=head2 C<SDL_CreateWindowFrom( ... )>

Create an SDL window from an existing native window.

	my $window = SDL_CreateWindowFrom( $data );

In some cases (e.g. OpenGL) and on some platforms (e.g. Microsoft Windows) the
hint C<SDL_HINT_VIDEO_WINDOW_SHARE_PIXEL_FORMAT> needs to be configured before
using C<SDL_CreateWindowFrom( ... )>.

Expected parameters include:

=over

=item C<data> - driver-dependant window creation data, typically your native window

=back

Returns the window that was created or an undefined value on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >> for more information.

=head2 C<SDL_GetWindowID( ... )>

Get the numeric ID of a window.

	my $id = SDL_GetWindowID( $window );

The numeric ID is what L<SDL2::WindowEvent> references, and is necessary to map
these events to specific L<SDL2::Window> objects.

Expected parameters include:

=over

=item C<window> - the window to query

=back

Returns the ID of the window on success or C<0> on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >> for more information.

=head2 C<SDL_GetWindowFromID( ... )>

Get a window from a stored ID.

	my $window = SDL_GetWindowFromID( 2 );

The numeric ID is what L<SDL2::WindowEvent> references, and is necessary to map
these events to specific L<SDL2::Window> objects.

Expected parameters include:

=over

=item C<id> - the ID of the window

=back

Returns the window associated with C<id> or an undefined value if it doesn't
exist; call L<< C<SDL_GetError( )>|/C<SDL_GetError( )> >> for more information.

=head2 C<SDL_GetWindowFlags( ... )>

Get the window flags.

	my $id = SDL_GetWindowFlags( $window );

The numeric ID is what L<SDL2::WindowEvent> references, and is necessary to map
these events to specific L<SDL2::Window> objects.

Expected parameters include:

=over

=item C<window> - the window to query

=back

Returns a mask of the L<< C<:windowFlags>|SDL2::Enum/C<:windowFlags> >>
associated with C<window>.

=head2 C<SDL_SetWindowTitle( ... )>

Set the title of a window.

	SDL_SetWindowTitle( $window, 'Untitle file *' );

This string is expected to be in UTF-8 encoding.

Expected parameters include:

=over

=item C<window> - the window to change

=item C<title> - the desired window title in UTF-8 format

=back

=head2 C<SDL_GetWindowTitle( ... )>

Get the title of a window.

	my $title = SDL_GetWindowTitle( $window );

Expected parameters include:

=over

=item C<window> - the window to query

=back

Returns the title of the window in UTF-8 format or C<""> (an empty string) if
there is no title.

=head2 C<SDL_SetWindowIcon( ... )>

Set the icon for a window.

	SDL_SetWindowIcon( $window, $icon );

Expected parameters include:

=over

=item C<window> - the window to change

=item C<icon> - an L<SDL2::Surface> structure containing the icon for the window

=back

=head2 C<SDL_SetWindowData( ... )>

Associate an arbitrary named pointer with a window.

	my $prev = SDL_SetWindowData( $window, 'test', $data );

Expected parameters include:

=over

=item C<window> - the window to change

=item C<name> - the name of the pointer

=item C<userdata> - the associated pointer

=back

Returns the previous value associated with C<name>.


=head2 C<SDL_GetWindowData( ... )>

Retrieve the data pointer associated with a window.

	my $data = SDL_SetWindowData( $window, 'test' );

Expected parameters include:

=over

=item C<window> - the window to query

=item C<name> - the name of the pointer

=back

Returns the value associated with C<name>.

=head2 C<SDL_SetWindowPosition( ... )>

Set the position of a window.

	SDL_SetWindowPosition( $window, 100, 100 );

The window coordinate origin is the upper left of the display.

Expected parameters include:

=over

=item C<window> - the window to reposition

=item C<x> - the x coordinate of the window in screen coordinates, or C<SDL_WINDOWPOS_CENTERED> or C<SDL_WINDOWPOS_UNDEFINED>

=item C<y> - the y coordinate of the window in screen coordinates, or C<SDL_WINDOWPOS_CENTERED> or C<SDL_WINDOWPOS_UNDEFINED>

=back

=head2 C<SDL_GetWindowPosition( ... )>

Get the position of a window.

	my ($x, $y) = SDL_GetWindowPosition( $window );

Expected parameters include:

=over

=item C<window> - the window to query

=back

Returns the C<x> and C<y> positions of the window, in screen coordinates,
either of which may be undefined.

=head2 C<SDL_SetWindowSize( ... )>

Set the size of a window's client area.

	SDL_SetWindowSize( $window, 100, 100 );

The window size in screen coordinates may differ from the size in pixels, if
the window was created with C<SDL_WINDOW_ALLOW_HIGHDPI> on a platform with
high-dpi support (e.g. iOS or macOS). Use L<< C<SDL_GL_GetDrawableSize( ...
)>|C<SDL_GL_GetDrawableSize( ... )> >> or L<< C<SDL_GetRendererOutputSize( ...
)>|/C<SDL_GetRendererOutputSize( ... )> >> to get the real client area size in
pixels.

Fullscreen windows automatically match the size of the display mode, and you
should use L<< C<SDL_SetWindowDisplayMode( ... )>|/C<SDL_SetWindowDisplayMode(
... )> >> to change their size.

Expected parameters include:

=over

=item C<window> - the window to change

=item C<w> - the width of the window in pixels, in screen coordinates, must be > 0

=item C<h> - the height of the window in pixels, in screen coordinates, must be > 0

=back

=head2 C<SDL_GetWindowSize( ... )>

Get the position of a window.

	my ($w, $h) = SDL_GetWindowSize( $window );

The window size in screen coordinates may differ from the size in pixels, if
the window was created with C<SDL_WINDOW_ALLOW_HIGHDPI> on a platform with
high-dpi support (e.g. iOS or macOS). Use L<< C<SDL_GL_GetDrawableSize( ...
)>|C<SDL_GL_GetDrawableSize( ... )> >>, L<< C<SDL_Vulkan_GetDrawableSize( ...
)>|/C<SDL_Vulkan_GetDrawableSize( ... )> >>, or L<<
C<SDL_GetRendererOutputSize( ... )>|/C<SDL_GetRendererOutputSize( ... )> >> to
get the real client area size in pixels.

Expected parameters include:

=over

=item C<window> - the window to query the width and height from

=back

Returns the C<width> and C<height> of the window, in screen coordinates, either
of which may be undefined.

=head2 C<SDL_GetWindowBordersSize( ... )>

Get the size of a window's borders (decorations) around the client area.

	my ($top, $left, $bottom, $right) = SDL_GetWindowBorderSize( $window );

Expected parameters include:

=over

=item C<window> - the window to query the size values of the border (decorations) from

=back

Returns the C<top>, C<left>, C<bottom>, and C<right> size values, any of which
may be undefined.

Note: If this function fails (returns -1), the size values will be initialized
to C<0, 0, 0, 0>, as if the window in question was borderless.

Note: This function may fail on systems where the window has not yet been
decorated by the display server (for example, immediately after calling L<<
C<SDL_CreateWindow( ...  )>|/C<SDL_CreateWindow( ...  )> >> ). It is
recommended that you wait at least until the window has been presented and
composited, so that the window system has a chance to decorate the window and
provide the border dimensions to SDL.

This function also returns C<-1> if getting the information is not supported.

=head2 C<SDL_SetWindowMinimumSize( ... )>

Set the minimum size of a window's client area.

	SDL_SetWindowMinimumSize( $window, 100, 100 );

Expected parameters include:

=over

=item C<window> - the window to change

=item C<w> - the minimum width of the window in pixels

=item C<h> - the minimum height of the window in pixels

=back

=head2 C<SDL_GetWindowMinimumSize( ... )>

Get the minimum size of a window's client area.

	my ($w, $h) = SDL_GetWindowMinimumSize( $window );

Expected parameters include:

=over

=item C<window> - the window to query the minimum width and minimum height from

=back

Returns the minimum C<width> and minimum C<height> of the window, either of
which may be undefined.

=head2 C<SDL_SetWindowMaximumSize( ... )>

Set the maximum size of a window's client area.

	SDL_SetWindowMaximumSize( $window, 100, 100 );

Expected parameters include:

=over

=item C<window> - the window to change

=item C<w> - the maximum width of the window in pixels

=item C<h> - the maximum height of the window in pixels

=back

=head2 C<SDL_GetWindowMaximumSize( ... )>

Get the maximum size of a window's client area.

	my ($w, $h) = SDL_GetWindowMaximumSize( $window );

Expected parameters include:

=over

=item C<window> - the window to query the maximum width and maximum height from

=back

Returns the maximum C<width> and maximum C<height> of the window, either of
which may be undefined.

=head2 C<SDL_SetWindowBordered( ... )>

Set the border state of a window.

	SDL_SetWindowBordered( $window, 1 );

This will add or remove the window's C<SDL_WINDOW_BORDERLESS> flag and add or
remove the border from the actual window. This is a no-op if the window's
border already matches the requested state.

You can't change the border state of a fullscreen window.

Expected parameters include:

=over

=item C<window> - the window of which to change the border state

=item C<bordered> - false value to remove border, true value to add border

=back

=head2 C<SDL_SetWindowResizable( ... )>

Set the user-resizable state of a window.

	SDL_SetWindowResizable( $window, 1 );

This will add or remove the window's C<SDL_WINDOW_RESIZABLE> flag and
allow/disallow user resizing of the window. This is a no-op if the window's
resizable state already matches the requested state.

You can't change the resizable state of a fullscreen window.

Expected parameters include:

=over

=item C<window> - the window of which to change the border state

=item C<bordered> - true value to allow resizing, false value to disallow

=back

=head2 C<SDL_ShowWindow( ... )>

Show a window.

	SDL_ShowWindow( $window );

Expected parameters include:

=over

=item C<window> - the window to show

=back

=head2 C<SDL_HideWindow( ... )>

Hide a window.

	SDL_HideWindow( $window );

Expected parameters include:

=over

=item C<window> - the window to hide

=back

=head2 C<SDL_RaiseWindow( ... )>

Raise a window above other windows and set the input focus.

	SDL_RaiseWindow( $window );

Expected parameters include:

=over

=item C<window> - the window to raise

=back

=head2 C<SDL_MaximizeWindow( ... )>

Make a window as large as possible.

	SDL_MaximizeWindow( $window );

Expected parameters include:

=over

=item C<window> - the window to maximize

=back

=head2 C<SDL_MinimizeWindow( ... )>

Minimize a window to an iconic representation.

	SDL_MinimizeWindow( $window );

Expected parameters include:

=over

=item C<window> - the window to minimize

=back

=head2 C<SDL_RestoreWindow( ... )>

Restore the size and position of a minimized or maximized window.

	SDL_RestoreWindow( $window );

Expected parameters include:

=over

=item C<window> - the window to restore

=back

=head2 C<SDL_SetWindowFullscreen( ... )>

Set a window's fullscreen state.

	SDL_SetWindowFullscreen( $window, SDL_WINDOW_FULLSCREEN );

Expected parameters include:

=over

=item C<window> - the window to change

=item C<flags> - C<SDL_WINDOW_FULLSCREEN>, C<SDL_WINDOW_FULLSCREEN_DESKTOP> or 0

=back

Returns  0 on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >> for more information.

=head2 C<SDL_GetWindowSurface( ... )>

Get the SDL surface associated with the window.

	my $surface = SDL_GetWindowSurface( $window );

A new surface will be created with the optimal format for the window, if
necessary. This surface will be freed when the window is destroyed. Do not free
this surface.

This surface will be invalidated if the window is resized. After resizing a
window this function must be called again to return a valid surface.

You may not combine this with 3D or the rendering API on this window.

This function is affected by C<SDL_HINT_FRAMEBUFFER_ACCELERATION>.

Expected parameters include:

=over

=item C<window> - the window to query

=back

Returns the surface associated with the window, or an undefined on failure;
call L<< C<SDL_GetError( )>|/C<SDL_GetError( )> >> for more information.

=head2 C<SDL_UpdateWindowSurface( ... )>

Copy the window surface to the screen.

	my $ok = !SDL_UpdateWindowSurface( $window );

This is the function you use to reflect any changes to the surface on the
screen.

Expected parameters include:

=over

=item C<window> - the window to query

=back

Returns C<0> on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >> for more information.

=head2 C<SDL_UpdateWindowSurfaceRects( ... )>

Copy areas of the window surface to the screen.

	SDL_UpdateWindowSurfaceRects( $window, @recs );

This is the function you use to reflect changes to portions of the surface on
the screen.

Expected parameters include:

=over

=item C<window> - the window to update

=item C<rects> - an array of L<SDL2::Rect> structures representing areas of the surface to copy

=back

Returns C<0> on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >> for more information.

=head2 C<SDL_SetWindowGrab( ... )>

Set a window's input grab mode.

	SDL_SetWindowGrab( $window, 1 );

When input is grabbed the mouse is confined to the window.

If the caller enables a grab while another window is currently grabbed, the
other window loses its grab in favor of the caller's window.

Expected parameters include:

=over

=item C<window> - the window for which the input grab mode should be set

=item C<grabbed> - a true value to grab input or a false value to release input

=back

=head2 C<SDL_SetWindowKeyboardGrab( ... )>

Set a window's keyboard grab mode.

	SDL_SetWindowKeyboardGrab( $window, 1 );

If the caller enables a grab while another window is currently grabbed, the
other window loses its grab in favor of the caller's window.

Expected parameters include:

=over

=item C<window> - The window for which the keyboard grab mode should be set.

=item C<grabbed> - This is true to grab keyboard, and false to release.

=back

=head2 C<SDL_SetWindowMouseGrab( ... )>

Set a window's mouse grab mode.

	SDL_SetWindowMouseGrab( $window, 1 );

Expected parameters include:

=over

=item C<window> - The window for which the mouse grab mode should be set.

=item C<grabbed> - This is true to grab mouse, and false to release.

=back

If the caller enables a grab while another window is currently grabbed, the
other window loses its grab in favor of the caller's window.

=head2 C<SDL_GetWindowGrab( ... )>

Get a window's input grab mode.

	my $grabbing = SDL_GetWindowGrab( $window );

Expected parameters include:

=over

=item C<window> - the window to query

=back

Returns true if input is grabbed, false otherwise.

=head2 C<SDL_GetWindowKeyboardGrab( ... )>

Get a window's keyboard grab mode.

	my $keyboard = SDL_GetWindowKeyboardGrab( $window );

Expected parameters include:

=over

=item C<window> - the window to query

=back

Returns true if keyboard is grabbed, and false otherwise.

=head2 C<SDL_GetWindowMouseGrab( ... )>

Get a window's mouse grab mode.

	my $mouse = SDL_GetWindowMouseGrab( $window );

Expected parameters include:

=over

=item C<window> - the window to query

=back

This returns true if mouse is grabbed, and false otherwise.

=head2 C<SDL_GetGrabbedWindow( )>

Get the window that currently has an input grab enabled.

	my $window = SDL_GetGrabbedWindow( );

Returns the window if input is grabbed or undefined otherwise.

=head2 C<SDL_SetWindowBrightness( ... )>

Set the brightness (gamma multiplier) for a given window's display.

	my $ok = !SDL_SetWindowBrightness( $window, 2 );

Despite the name and signature, this method sets the brightness of the entire
display, not an individual window. A window is considered to be owned by the
display that contains the window's center pixel. (The index of this display can
be retrieved using L<< C<SDL_GetWindowDisplayIndex( ...
)>|/C<SDL_GetWindowDisplayIndex( ... )> >>.) The brightness set will not follow
the window if it is moved to another display.

Many platforms will refuse to set the display brightness in modern times. You
are better off using a shader to adjust gamma during rendering, or something
similar.

Expected parameters includes:

=over

=item C<window> - the window used to select the display whose brightness will be changed

=item C<brightness> - the brightness (gamma multiplier) value to set where 0.0 is completely dark and 1.0 is normal brightness

=back

Returns C<0> on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_GetWindowBrightness( ... )>

Get the brightness (gamma multiplier) for a given window's display.

	my $gamma = SDL_GetWindowBrightness( $window );

Despite the name and signature, this method retrieves the brightness of the
entire display, not an individual window. A window is considered to be owned by
the display that contains the window's center pixel. (The index of this display
can be retrieved using L<< C<SDL_GetWindowDisplayIndex( ...
)>|/C<SDL_GetWindowDisplayIndex( ... )> >>.)

Expected parameters include:

=over

=item C<window> - the window used to select the display whose brightness will be queried

=back

Returns the brightness for the display where 0.0 is completely dark and C<1.0>
is normal brightness.

=head2 C<SDL_SetWindowOpacity( ... )>

Set the opacity for a window.

	SDL_SetWindowOpacity( $window, .5 );

The parameter C<opacity> will be clamped internally between C<0.0>
(transparent) and C<1.0> (opaque).

This function also returns C<-1> if setting the opacity isn't supported.

Expected parameters include:

=over

=item C<window> - the window which will be made transparent or opaque

=item C<opacity> - the opacity value (0.0 - transparent, 1.0 - opaque)

=back

Returns C<0> on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_GetWindowOpacity( ... )>

Get the opacity of a window.

	my $opacity = SDL_GetWindowOpacity( $window );

If transparency isn't supported on this platform, opacity will be reported as
1.0 without error.

The parameter C<opacity> is ignored if it is undefined.

This function also returns C<-1> if an invalid window was provided.

Expected parameters include:

=over

=item C<window> - the window to get the current opacity value from

=back

Returns the current opacity on success or a negative error code on failure;
call L<< C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_SetWindowModalFor( ... )>

Set the window as a modal for another window.

	my $ok = !SDL_SetWindowModalFor( $winodw, $parent );

Expected parameters include:

=over

=item C<modal_window> - the window that should be set modal

=item C<parent_window> - the parent window for the modal window

=back

Returns C<0> on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.


=head2 C<SDL_SetWindowInputFocus( ... )>

Explicitly set input focus to the window.

	SDL_SetWindowInputFocus( $window );

You almost certainly want L<< C<SDL_RaiseWindow( ... )>|/C<SDL_RaiseWindow( ...
)> >> instead of this function. Use this with caution, as you might give focus
to a window that is completely obscured by other windows.

Expected parameters include:

=over

=item C<window> - the window that should get the input focus

=back

Returns C<0> on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_SetWindowGammaRamp( ... )>

Set the gamma ramp for the display that owns a given window.

	my $ok = !SDL_SetWindowGammaRamp( $window, \@red, \@green, \@blue );

Set the gamma translation table for the red, green, and blue channels of the
video hardware. Each table is an array of 256 16-bit quantities, representing a
mapping between the input and output for that channel. The input is the index
into the array, and the output is the 16-bit gamma value at that index, scaled
to the output color precision. Despite the name and signature, this method sets
the gamma ramp of the entire display, not an individual window. A window is
considered to be owned by the display that contains the window's center pixel.
(The index of this display can be retrieved using L<<
C<SDL_GetWindowDisplayIndex( ... )>|/C<SDL_GetWindowDisplayIndex( ... )> >>.)
The gamma ramp set will not follow the window if it is moved to another
display.

Expected parameters include:

=over

=item C<window> - the window used to select the display whose gamma ramp will be changed

=item C<red> - a 256 element array of 16-bit quantities representing the translation table for the red channel, or NULL

=item C<green> - a 256 element array of 16-bit quantities representing the translation table for the green channel, or NULL

=item C<blue> - a 256 element array of 16-bit quantities representing the translation table for the blue channel, or NULL

=back

Returns C<0> on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_GetWindowGammaRamp( ... )>

Get the gamma ramp for a given window's display.

	my ($red, $green, $blue) = SDL_GetWindowGammaRamp( $window );

Despite the name and signature, this method retrieves the gamma ramp of the
entire display, not an individual window. A window is considered to be owned by
the display that contains the window's center pixel. (The index of this display
can be retrieved using L<< C<SDL_GetWindowDisplayIndex( ...
)>|/C<SDL_GetWindowDisplayIndex( ... )> >>.)

Expected parameters include:

=over

=item C<window> - the window used to select the display whose gamma ramp will be queried

=back

Returns three 256 element arrays of 16-bit quantities filled in with the
translation table for the red, gree, and blue channels on success or a negative
error code on failure; call L<< C<SDL_GetError( )>|/C<SDL_GetError( )> >>( )
for more information.

=head2 C<SDL_SetWindowHitTest( ... )>

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

Platforms that don't support this functionality will return C<-1>
unconditionally, even if you're attempting to disable hit-testing.

Your callback may fire at any time, and its firing does not indicate any
specific behavior (for example, on Windows, this certainly might fire when the
OS is deciding whether to drag your window, but it fires for lots of other
reasons, too, some unrelated to anything you probably care about B<and when the
mouse isn't actually at the location it is testing>). Since this can fire at
any time, you should try to keep your callback efficient, devoid of
allocations, etc.

Expected parameters include:

=over

=item C<window> - the window to set hit-testing on

=item C<callback> - the function to call when doing a hit-test

=item C<callback_data> - an app-defined void pointer passed to C<callback>

=back

Returns C<0> on success or C<-1> on error (including unsupported); call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_FlashWindow( ... )>

Request a window to give a signal, e.g. a visual signal, to demand attention
from the user.

	SDL_FlashWindow( $window, 10 );

Expected parameters include:

=over

=item C<window> - the window to request the flashing for

=item C<flash_count> - number of times the window gets flashed on systems that support flashing the window multiple times, like Windows, else it is ignored

=back

Returns C<0> on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_DestroyWindow( ... )>

Destroy a window.

	SDL_DestoryWindow( $window );

If C<window> is undefined, this function will return immediately after setting
the SDL error message to "Invalid window". See L<< C<SDL_GetError(
)>|/C<SDL_GetError( )> >>( ).

Expected parameters include:

=over

=item C<window> - the window to destroy

=back

=head2 C<SDL_IsScreenSaverEnabled( ... )>

Check whether the screensaver is currently enabled.

	my $enabled = SDL_IsScreenSaverEnabled( );

The screensaver is disabled by default since SDL 2.0.2. Before SDL 2.0.2 the
screensaver was enabled by default.

The default can also be changed using C<SDL_HINT_VIDEO_ALLOW_SCREENSAVER>.

Returns true if the screensaver is enabled, false if it is disabled.

=head2 C<SDL_EnableScreenSaver( ... )>

Allow the screen to be blanked by a screen saver.

	SDL_EnableScreenSaver( );


=head2 C<SDL_DisableScreenSaver( ... )>

Prevent the screen from being blanked by a screen saver.

	SDL_DisableScreenSaver( );

If you disable the screensaver, it is automatically re-enabled when SDL quits.

=head1 OpenGL Support Functions

These may be imported with the C<:opengl> tag.

=head2 C<SDL_GL_LoadLibrary( ... )>

Dynamically load an OpenGL library.

	my $ok = SDL_GL_LoadLibrary( );

This should be done after initializing the video driver, but before creating
any OpenGL windows. If no OpenGL library is loaded, the default library will be
loaded upon creation of the first OpenGL window.

If you do this, you need to retrieve all of the GL functions used in your
program from the dynamic library using L<< C<SDL_GL_GetProcAddress(
)>|/C<SDL_GL_GetProcAddress( )> >>.

Expected parameters include:

=over

=item C<path> - the platform dependent OpenGL library name, or undef to open the default OpenGL library

=back

Returns C<0> on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_GL_GetProcAddress( ... )>

Get an OpenGL function by name.

	my $ptr = SDL_GL_GetProcAddress( 'glGenBuffers' );
	...; # TODO
	# TODO: In the future, this should return an XSUB loaded with FFI.

If the GL library is loaded at runtime with L<< C<SDL_GL_LoadLibrary( ...
)>|/C<SDL_GL_LoadLibrary( ... )> >>, then all GL functions must be retrieved
this way. Usually this is used to retrieve function pointers to OpenGL
extensions.

There are some quirks to looking up OpenGL functions that require some extra
care from the application. If you code carefully, you can handle these quirks
without any platform-specific code, though:

=over

=item * On Windows, function pointers are specific to the current GL context;
this means you need to have created a GL context and made it current before
calling SDL_GL_GetProcAddress( ). If you recreate your context or create a
second context, you should assume that any existing function pointers
aren't valid to use with it. This is (currently) a Windows-specific
limitation, and in practice lots of drivers don't suffer this limitation,
but it is still the way the wgl API is documented to work and you should
expect crashes if you don't respect it. Store a copy of the function
pointers that comes and goes with context lifespan.

=item * On X11, function pointers returned by this function are valid for any
context, and can even be looked up before a context is created at all. This
means that, for at least some common OpenGL implementations, if you look up
a function that doesn't exist, you'll get a non-NULL result that is _NOT_
safe to call. You must always make sure the function is actually available
for a given GL context before calling it, by checking for the existence of
the appropriate extension with L<< C<SDL_GL_ExtensionSupported( ... )>|C<SDL_GL_ExtensionSupported( ... )> >>, or verifying
that the version of OpenGL you're using offers the function as core
functionality.

=item * Some OpenGL drivers, on all platforms, B<will> return undef if a function
isn't supported, but you can't count on this behavior. Check for extensions
you use, and if you get an undef anyway, act as if that extension wasn't
available. This is probably a bug in the driver, but you can code
defensively for this scenario anyhow.

=item * Just because you're on Linux/Unix, don't assume you'll be using X11.
Next-gen display servers are waiting to replace it, and may or may not make
the same promises about function pointers.

=item * OpenGL function pointers must be declared C<APIENTRY> as in the example
code. This will ensure the proper calling convention is followed on
platforms where this matters (Win32) thereby avoiding stack corruption.

=back

Expected parameters include:

=over

=item C<proc> - the name of an OpenGL function

=back

Returns a pointer to the named OpenGL function. The returned pointer should be
cast to the appropriate function signature.

=head2 C<SDL_GL_UnloadLibrary( )>

Unload the OpenGL library previously loaded by L<< C<SDL_GL_LoadLibrary( ...
)>|/C<SDL_GL_LoadLibrary( ... )> >>.

=head2 C<SDL_GL_ExtensionSupported( ... )>

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

=over

=item C<extension> - the name of the extension to check

=back

Returns true if the extension is supported, false otherwise.

=head2 C<SDL_GL_ResetAttributes( )>

Reset all previously set OpenGL context attributes to their default values.

	SDL_GL_ResetAttributes( );

=head2 C<SDL_GL_SetAttribute( ... )>

Set an OpenGL window attribute before window creation.

	SDL_GL_SetAttribute(SDL_GL_RED_SIZE, 5);
	SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE, 5);
	SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE, 5);
	SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 16);
	SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);

This function sets the OpenGL attribute C<attr> to C<value>. The requested
attributes should be set before creating an OpenGL window. You should use L<<
C<SDL_GL_GetAttribute( ... )>|/C<SDL_GL_GetAttribute( ... )> >> to check the
values after creating the OpenGL context, since the values obtained can differ
from the requested ones.

Expected parameters include:

=over

=item C<attr> - an SDL_GLattr enum value specifying the OpenGL attribute to set

=item C<value> - the desired value for the attribute

=back

Returns C<0> on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_GL_GetAttribute( ... )>

Get the actual value for an attribute from the current context.

	my $value = SDL_GL_GetAttribute(SDL_GL_DOUBLEBUFFER);

Expected parameters include:

=over

=item C<attr> - an SDL_GLattr enum value specifying the OpenGL attribute to get

=back

Returns the value on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_GL_CreateContext( ... )>

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
library or with L<< C<SDL_GL_GetProcAddress( ... )>|/C<SDL_GL_GetProcAddress(
... )> >> and its related functions.

SDL2::GLContext is opaque to the application.

Expected parameters include:

=over

=item C<window> - the window to associate with the context

=back

Returns the OpenGL context associated with C<window> or undef on error; call
L<< C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more details.

=head2 C<SDL_GL_MakeCurrent( ... )>

Set up an OpenGL context for rendering into an OpenGL window.

	SDL_GL_MakeCurrent( $window, $gl );

The context must have been created with a compatible window.

Expected parameters include:

=over

=item C<window> - the window to associate with the context

=item C<context> - the OpenGL context to associate with the window

=back

Returns C<0> on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_GL_GetCurrentWindow( )>

Get the currently active OpenGL window.

	my $window = SDL_GL_GetCurrentWindow( );

Returns the currently active OpenGL window on success or undef on failure; call
L<< C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_GL_GetCurrentContext( )>

Get the currently active OpenGL context.

	my $gl = SDL_GL_GetCurrentContext( );

Returns the currently active OpenGL context or NULL on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_GL_GetDrawableSize( ... )>

Get the size of a window's underlying drawable in pixels.

	my ($w, $h) = SDL_GL_GetDrawableSize( $window );

This returns info useful for calling C<glViewport( ... )>.

This may differ from L<< C<SDL_GetWindowSize( ... )>|/C<SDL_GetWindowSize( ...
)> >> if we're rendering to a high-DPI drawable, i.e. the window was created
with C<SDL_WINDOW_ALLOW_HIGHDPI> on a platform with high-DPI support (Apple
calls this "Retina"), and not disabled by the
C<SDL_HINT_VIDEO_HIGHDPI_DISABLED> hint.

Expected parameters include:

=over

=item C<window> - the window from which the drawable size should be queried

=back

Returns the width and height in pixels, either of which may be undefined.

=head2 C<SDL_GL_SetSwapInterval( ... )>

Set the swap interval for the current OpenGL context.

	my $ok = !SDL_GL_SetSwapInterval( 1 );

Some systems allow specifying C<-1> for the interval, to enable adaptive vsync.
Adaptive vsync works the same as vsync, but if you've already missed the
vertical retrace for a given frame, it swaps buffers immediately, which might
be less jarring for the user during occasional framerate drops. If application
requests adaptive vsync and the system does not support it, this function will
fail and return C<-1>. In such a case, you should probably retry the call with
C<1> for the interval.

Adaptive vsync is implemented for some glX drivers with
C<GLX_EXT_swap_control_tear>:
L<https://www.opengl.org/registry/specs/EXT/glx_swap_control_tear.txt> and for
some Windows drivers with C<WGL_EXT_swap_control_tear>:
L<https://www.opengl.org/registry/specs/EXT/wgl_swap_control_tear.txt>

Read more on the Khronos wiki:
L<https://www.khronos.org/opengl/wiki/Swap_Interval#Adaptive_Vsync>

Expected parameters include:

=over

=item C<interval> - 0 for immediate updates, 1 for updates synchronized with the vertical retrace, -1 for adaptive vsync

=back

Returns C<0> on success or C<-1> if setting the swap interval is not supported;
call L<< C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_GL_GetSwapInterval( )>

Get the swap interval for the current OpenGL context.

	my $interval = SDL_GL_GetSwapInterval( );

If the system can't determine the swap interval, or there isn't a valid current
context, this function will return 0 as a safe default.

Returns C<0> if there is no vertical retrace synchronization, C<1> if the
buffer swap is synchronized with the vertical retrace, and C<-1> if late swaps
happen immediately instead of waiting for the next retrace; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_GL_SwapWindow( ... )>

Update a window with OpenGL rendering.

	SDL_GL_SwapWindow( $window );

This is used with double-buffered OpenGL contexts, which are the default.

On macOS, make sure you bind 0 to the draw framebuffer before swapping the
window, otherwise nothing will happen. If you aren't using C<glBindFramebuffer(
)>, this is the default and you won't have to do anything extra.

Expected parameters include:

=over

=item C<window> - the window to change

=back

=head2 C<SDL_GL_DeleteContext( ... )>

Delete an OpenGL context.

	SDL_GL_DeleteContext( $context );

Expected parameters include:

=over

=item C<context> - the OpenGL context to be deleted

=back

=head2 2D Accelerated Rendering

This category contains functions for 2D accelerated rendering. You may import
these functions with the C<:render> tag.

This API supports the following features:

=over

=item single pixel points

=item single pixel lines

=item filled rectangles

=item texture images

=back

All of these may be drawn in opaque, blended, or additive modes.

The texture images can have an additional color tint or alpha modulation
applied to them, and may also be stretched with linear interpolation, rotated
or flipped/mirrored.

For advanced functionality like particle effects or actual 3D you should use
SDL's OpenGL/Direct3D support or one of the many available 3D engines.

This API is not designed to be used from multiple threads, see L<SDL issue
#986|https://github.com/libsdl-org/SDL/issues/986> for details.

=head2 C<SDL_GetNumRenderDrivers( )>

Get the number of 2D rendering drivers available for the current display.

	my $drivers = SDL_GetNumRenderDrivers( );

A render driver is a set of code that handles rendering and texture management
on a particular display. Normally there is only one, but some drivers may have
several available with different capabilities.

There may be none if SDL was compiled without render support.

Returns a number >= 0 on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_GetRenderDriverInfo( ... )>

Get info about a specific 2D rendering driver for the current display.

	my $info = !SDL_GetRendererDriverInfo( );

Expected parameters include:

=over

=item C<index> - the index of the driver to query information about

=back

Returns an L<SDL2::RendererInfo> structure on success or a negative error code
on failure; call L<< C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more
information.

=head2 C<SDL_CreateWindowAndRenderer( ... )>

Create a window and default renderer.

	my ($window, $renderer) = SDL_CreateWindowAndRenderer(640, 480, 0);

Expected parameters include:

=over

=item C<width> - the width of the window

=item C<height> - the height of the window

=item C<window_flags> - the flags used to create the window (see L<< C<SDL_CreateWindow( ... )>|/C<SDL_CreateWindow( ... )> >>)

=back

Returns a L<SDL2::Window> and L<SDL2::Renderer> objects on success, or -1 on
error; call L<< C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more
information.

=head2 C<SDL_CreateRenderer( ... )>

Create a 2D rendering context for a window.

	my $renderer = SDL_CreateRenderer( $window, -1, 0);

Expected parameters include:

=over

=item C<window> - the window where rendering is displayed

=item C<index> - the index of the rendering driver to initialize, or C<-1> to initialize the first one supporting the requested flags

=item C<flags> - C<0>, or one or more C<SDL_RendererFlags> OR'd together

=back

Returns a valid rendering context or undefined if there was an error; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_CreateSoftwareRenderer( ... )>

Create a 2D software rendering context for a surface.

	my $renderer = SDL_CreateSoftwareRenderer( $surface );

Two other API which can be used to create SDL_Renderer:

L<< C<SDL_CreateRenderer( ... )>|/C<SDL_CreateRenderer( ... )> >> and L<<
C<SDL_CreateWindowAndRenderer( ... )>|/C<SDL_CreateWindowAndRenderer( ... )>
>>. These can B<also> create a software renderer, but they are intended to be
used with an L<SDL2::Window> as the final destination and not an
L<SDL2::Surface>.

Expected parameters include:

=over

=item C<surface> - the L<SDL2::Surface> structure representing the surface where rendering is done

=back

Returns a valid rendering context or undef if there was an error; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_GetRenderer( ... )>

Get the renderer associated with a window.

	my $renderer = SDL_GetRenderer( $window );

Expected parameters include:

=over

=item C<window> - the window to query

=back

Returns the rendering context on success or undef on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_GetRendererInfo( ... )>

Get information about a rendering context.

	my $info = !SDL_GetRendererInfo( $renderer );

Expected parameters include:

=over

=item C<renderer> - the rendering context

=back

Returns an L<SDL2::RendererInfo> structure on success or a negative error code
on failure; call L<< C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more
information.

=head2 C<SDL_GetRendererOutputSize( ... )>

Get the output size in pixels of a rendering context.

	my ($w, $h) = SDL_GetRendererOutputSize( $renderer );

Due to high-dpi displays, you might end up with a rendering context that has
more pixels than the window that contains it, so use this instead of L<<
C<SDL_GetWindowSize( ... )>|/C<SDL_GetWindowSize( ... )> >> to decide how much
drawing area you have.

Expected parameters include:

=over

=item C<renderer> - the rendering context

=back

Returns the width and height on success or a negative error code on failure;
call L<< C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_CreateTexture( ... )>

Create a texture for a rendering context.

    my $texture = SDL_CreateTexture( $renderer, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_TARGET, 1024, 768);

=for TODO: https://gist.github.com/malja/2193bd656fe50c203f264ce554919976

You can set the texture scaling method by setting
C<SDL_HINT_RENDER_SCALE_QUALITY> before creating the texture.

Expected parameters include:

=over

=item C<renderer> - the rendering context

=item C<format> - one of the enumerated values in C<:pixelFormatEnum>

=item C<access> - one of the enumerated values in C<:textureAccess>

=item C<w> - the width of the texture in pixels

=item C<h> - the height of the texture in pixels

=back

Returns a pointer to the created texture or undefined if no rendering context
was active, the format was unsupported, or the width or height were out of
range; call L<< C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more
information.

=head2 C<SDL_CreateTextureFromSurface( ... )>

Create a texture from an existing surface.

	use Config;
	my ($rmask, $gmask, $bmask, $amask) =
	$Config{byteorder} == 4321 ? (0xff000000,0x00ff0000,0x0000ff00,0x000000ff) :
    							 (0x000000ff,0x0000ff00,0x00ff0000,0xff000000);
	my $surface = SDL_CreateRGBSurface( 0, 640, 480, 32, $rmask, $gmask, $bmask, $amask );
	my $texture = SDL_CreateTextureFromSurface( $renderer, $surface );

The surface is not modified or freed by this function.

The SDL_TextureAccess hint for the created texture is
C<SDL_TEXTUREACCESS_STATIC>.

The pixel format of the created texture may be different from the pixel format
of the surface. Use L<< C<SDL_QueryTexture( ... )>|/C<SDL_QueryTexture( ... )>
>> to query the pixel format of the texture.

Expected parameters include:

=over

=item C<renderer> - the rendering context

=item C<surface> - the L<SDL2::Surface> structure containing pixel data used to fill the texture

=back

Returns the created texture or undef on failure; call L<< C<SDL_GetError(
)>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_QueryTexture( ... )>

Query the attributes of a texture.

	my ( $format, $access, $w, $h ) = SDL_QueryTexture( $texture );

Expected parameters include:

=over

=item C<texture> - the texture to query

=back

Returns the following on success...

=over

=item C<format> - a pointer filled in with the raw format of the texture; the
actual format may differ, but pixel transfers will use this
format (one of the L<< C<:pixelFormatEnum>|/C<:pixelFormatEnum> >> values)

=item C<access> - a pointer filled in with the actual access to the texture (one of the L<< C<:textureAccess>|/C<:textureAccess> >> values)

=item C<w> - a pointer filled in with the width of the texture in pixels

=item C<h> - a pointer filled in with the height of the texture in pixels

=back

...or a negative error code on failure; call L<< C<SDL_GetError(
)>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_SetTextureColorMod( ... )>

Set an additional color value multiplied into render copy operations.

	my $ok = !SDL_SetTextureColorMod( $texture, 64, 64, 64 );

When this texture is rendered, during the copy operation each source color
channel is modulated by the appropriate color value according to the following
formula:

	srcC = srcC * (color / 255)

Color modulation is not always supported by the renderer; it will return C<-1>
if color modulation is not supported.

Expected parameters include:

=over

=item C<texture> - the texture to update

=item C<r> - the red color value multiplied into copy operations

=item C<g> - the green color value multiplied into copy operations

=item C<b> - the blue color value multiplied into copy operations

=back

Returns C<0> on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_GetTextureColorMod( ... )>

Get the additional color value multiplied into render copy operations.

	my ( $r, $g, $b ) = SDL_GetTextureColorMod( $texture );

Expected parameters include:

=over

=item C<texture> - the texture to query

=back

Returns the current red, green, and blue color values on success or a negative
error code on failure; call L<< C<SDL_GetError( )>|/C<SDL_GetError( )> >>( )
for more information.

=head2 C<SDL_SetTextureAlphaMod( ... )>

Set an additional alpha value multiplied into render copy operations.

	SDL_SetTextureAlphaMod( $texture, 100 );

When this texture is rendered, during the copy operation the source alpha

value is modulated by this alpha value according to the following formula:

	srcA = srcA * (alpha / 255)

Alpha modulation is not always supported by the renderer; it will return C<-1>
if alpha modulation is not supported.

Expected parameters include:

=over

=item C<texture> - the texture to update

=item C<alpha> - the source alpha value multiplied into copy operations

=back

Returns C<0> on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_GetTextureAlphaMod( ... )>

Get the additional alpha value multiplied into render copy operations.

	my $alpha = SDL_GetTextureAlphaMod( $texture );

Expected parameters include:

=over

=item C<texture> - the texture to query

=back

Returns the current alpha value on success or a negative error code on failure;
call L<< C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_SetTextureBlendMode( ... )>

Set the blend mode for a texture, used by L<< C<SDL_RenderCopy( ...
)>|/C<SDL_RenderCopy( ... )> >>.

If the blend mode is not supported, the closest supported mode is chosen and
this function returns C<-1>.

Expected parameters include:

=over

=item C<texture> - the texture to update

=item C<blendMode> - the L<< C<:blendMode>|/C<:blendMode> >> to use for texture blending

=back

Returns 0 on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_GetTextureBlendMode( ... )>

Get the blend mode used for texture copy operations.

	SDL_GetTextureBlendMode( $texture, SDL_BLENDMODE_ADD );

Expected parameters include:

=over

=item C<texture> - the texture to query

=back

Returns the current C<:blendMode> on success or a negative error code on
failure; call L<< C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more
information.

=head2 C<SDL_SetTextureScaleMode( ... )>

Set the scale mode used for texture scale operations.

	SDL_SetTextureScaleMode( $texture, $scaleMode );

If the scale mode is not supported, the closest supported mode is chosen.

Expected parameters include:

=over

=item C<texture> - The texture to update.

=item C<scaleMode> - the SDL_ScaleMode to use for texture scaling.

=back

Returns C<0> on success, or C<-1> if the texture is not valid.

=head2 C<SDL_GetTextureScaleMode( ... )>

Get the scale mode used for texture scale operations.

	my $ok = SDL_GetTextureScaleMode( $texture );

Expected parameters include:

=over

=item C<texture> - the texture to query.

=back

Returns the current scale mode on success, or C<-1> if the texture is not
valid.

=head2 C<SDL_UpdateTexture( ... )>

Update the given texture rectangle with new pixel data.

	my $rect = SDL2::Rect->new( { x => 0, y => ..., w => $surface->w, h => $surface->h } );
	SDL_UpdateTexture( $texture, $rect, $surface->pixels, $surface->pitch );

The pixel data must be in the pixel format of the texture. Use L<<
C<SDL_QueryTexture( ... )>|/C<SDL_QueryTexture( ... )> >> to query the pixel
format of the texture.

This is a fairly slow function, intended for use with static textures that do
not change often.

If the texture is intended to be updated often, it is preferred to create the
texture as streaming and use the locking functions referenced below. While this
function will work with streaming textures, for optimization reasons you may
not get the pixels back if you lock the texture afterward.

Expected parameters include:

=over

=item C<texture> - the texture to update

=item C<rect> - an L<SDL2::Rect> structure representing the area to update, or undef to update the entire texture

=item C<pixels> - the raw pixel data in the format of the texture

=item C<pitch> - the number of bytes in a row of pixel data, including padding between lines

=back

Returns C<0> on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_UpdateYUVTexture( ... )>

Update a rectangle within a planar YV12 or IYUV texture with new pixel data.

	SDL_UpdateYUVTexture( $texture, $rect, $yPlane, $yPitch, $uPlane, $uPitch, $vPlane, $vPitch );

You can use L<< C<SDL_UpdateTexture( ... )>|/C<SDL_UpdateTexture( ... )> >> as
long as your pixel data is a contiguous block of Y and U/V planes in the proper
order, but this function is available if your pixel data is not contiguous.

Expected parameters include:

=over

=item C<texture> - the texture to update

=item C<rect> - a pointer to the rectangle of pixels to update, or undef to update the entire texture

=item C<Yplane> - the raw pixel data for the Y plane

=item C<Ypitch> - the number of bytes between rows of pixel data for the Y plane

=item C<Uplane> - the raw pixel data for the U plane

=item C<Upitch> - the number of bytes between rows of pixel data for the U plane

=item C<Vplane> - the raw pixel data for the V plane

=item C<Vpitch> - the number of bytes between rows of pixel data for the V plane

=back

Returns C<0> on success or -1 if the texture is not valid; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_UpdateNVTexture( ... )>

Update a rectangle within a planar NV12 or NV21 texture with new pixels.

	SDL_UpdateNVTexture( $texture, $rect, $yPlane, $yPitch, $uPlane, $uPitch );

You can use L<< C<SDL_UpdateTexture( ... )>|/C<SDL_UpdateTexture( ... )> >> as
long as your pixel data is a contiguous block of NV12/21 planes in the proper
order, but this function is available if your pixel data is not contiguous.

Expected parameters include:

=over

=item C<texture> - the texture to update

=item C<rect> - a pointer to the rectangle of pixels to update, or undef to update the entire texture.

=item C<Yplane> - the raw pixel data for the Y plane.

=item C<Ypitch> - the number of bytes between rows of pixel data for the Y plane.

=item C<UVplane> - the raw pixel data for the UV plane.

=item C<UVpitch> - the number of bytes between rows of pixel data for the UV plane.

=back

Returns C<0> on success, or C<-1> if the texture is not valid.

=head2 C<SDL_LockTexture( ... )>

Lock a portion of the texture for B<write-only> pixel access.

	SDL_LockTexture( $texture, $rect, $pixels, $pitch );

As an optimization, the pixels made available for editing don't necessarily
contain the old texture data. This is a write-only operation, and if you need
to keep a copy of the texture data you should do that at the application level.

You must use L<< C<SDL_UpdateTexture( ... )>|/C<SDL_UpdateTexture( ... )> >> to
unlock the pixels and apply any changes.

Expected parameters include:

=over

=item C<texture> - the texture to lock for access, which was created with C<SDL_TEXTUREACCESS_STREAMING>

=item C<rect> - an L<SDL2::Rect> structure representing the area to lock for access; undef to lock the entire texture

=item C<pixels> - this is filled in with a pointer to the locked pixels, appropriately offset by the locked area

=item C<pitch> - this is filled in with the pitch of the locked pixels; the pitch is the length of one row in bytes

=back

Returns 0 on success or a negative error code if the texture is not valid or
was not created with `SDL_TEXTUREACCESS_STREAMING`; call L<< C<SDL_GetError(
)>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_LockTextureToSurface( ... )>

Lock a portion of the texture for B<write-only> pixel access, and expose it as
a SDL surface.

	my $surface = SDL_LockTextureSurface( $texture, $rect );

Besides providing an L<SDL2::Surface> instead of raw pixel data, this function
operates like L<SDL2::LockTexture>.

As an optimization, the pixels made available for editing don't necessarily
contain the old texture data. This is a write-only operation, and if you need
to keep a copy of the texture data you should do that at the application level.

You must use L<< C<SDL_UnlockTexture( ... )>|/C<SDL_UnlockTexture( ... )> >> to
unlock the pixels and apply any changes.

The returned surface is freed internally after calling L<< C<SDL_UnlockTexture(
... )>|/C<SDL_UnlockTexture( ... )> >> or L<< C<SDL_DestroyTexture( ...
)>|/C<SDL_DestroyTexture( ... )> >>. The caller should not free it.

Expected parameters include:

=over

=item C<texture> - the texture to lock for access, which was created with C<SDL_TEXTUREACCESS_STREAMING>

=item C<rect> - a pointer to the rectangle to lock for access. If the rect is undef, the entire texture will be locked

=back

Returns the L<SDL2::Surface> structure on success, or C<-1> if the texture is
not valid or was not created with C<SDL_TEXTUREACCESS_STREAMING>.

=head2 C<SDL_UnlockTexture( ... )>

Unlock a texture, uploading the changes to video memory, if needed.

	SDL_UnlockTexture( $texture );

B<Warning>: Please note that L<< C<SDL_LockTexture( ... )>|/C<SDL_LockTexture(
... )> >> is intended to be write-only; it will not guarantee the previous
contents of the texture will be provided. You must fully initialize any area of
a texture that you lock before unlocking it, as the pixels might otherwise be
uninitialized memory.

Which is to say: locking and immediately unlocking a texture can result in
corrupted textures, depending on the renderer in use.

Expected parameters include:

=over

=item C<texture> - a texture locked by L<< C<SDL_LockTexture( ... )>|/C<SDL_LockTexture( ... )> >>

=back

=head2 C<SDL_RenderTargetSupported( ... )>

Determine whether a renderer supports the use of render targets.

	my $bool = SDL_RenderTargetSupported( $renderer );

Expected parameters include:

=over

=item C<renderer> - the renderer that will be checked

=back

Returns true if supported or false if not.

=head2 C<SDL_SetRenderTarget( ... )>

Set a texture as the current rendering target.

	SDL_SetRenderTarget( $renderer, $texture );

Before using this function, you should check the C<SDL_RENDERER_TARGETTEXTURE>
bit in the flags of L<SDL2::RendererInfo> to see if render targets are
supported.

The default render target is the window for which the renderer was created. To
stop rendering to a texture and render to the window again, call this function
with a undefined C<texture>.

Expected parameters include:

=over

=item C<renderer> - the rendering context

=item C<texture> - the targeted texture, which must be created with the C<SDL_TEXTUREACCESS_TARGET> flag, or undef to render to the window instead of a texture.

=back

Returns C<0> on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_GetRenderTarget( ... )>

Get the current render target.

	my $texture = SDL_GetRenderTarget( $renderer );

The default render target is the window for which the renderer was created, and
is reported an undefined value here.

Expected parameters include:

=over

=item C<renderer> - the rendering context

=back

Returns the current render target or undef for the default render target.

=head2 C<SDL_RenderSetLogicalSize( ... )>

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

=over

=item C<renderer> - the renderer for which resolution should be set

=item C<w> - the width of the logical resolution

=item C<h> - the height of the logical resolution

=back

Returns C<0> on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_RenderGetLogicalSize( ... )>

Get device independent resolution for rendering.

	my ($w, $h) = SDL_RenderGetLogicalSize( $renderer );

This may return C<0> for C<w> and C<h> if the L<SDL2::Renderer> has never had
its logical size set by L<< C<SDL_RenderSetLogicalSize( ...
)>|/C<SDL_RenderSetLogicalSize( ... )> >> and never had a render target set.

Expected parameters include:

=over

=item C<renderer> - a rendering context

=back

Returns the width and height.

=head2 C<SDL_RenderSetIntegerScale( ... )>

Set whether to force integer scales for resolution-independent rendering.

	SDL_RenderSetIntegerScale( $renderer, 1 );

This function restricts the logical viewport to integer values - that is, when
a resolution is between two multiples of a logical size, the viewport size is
rounded down to the lower multiple.

Expected parameters include:

=over

=item C<renderer> - the renderer for which integer scaling should be set

=item C<enable> - enable or disable the integer scaling for rendering

=back

Returns C<0> on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_RenderGetIntegerScale( ... )>

Get whether integer scales are forced for resolution-independent rendering.

	SDL_RenderGetIntegerScale( $renderer );

Expected parameters include:

=over

=item C<renderer> - the renderer from which integer scaling should be queried

=back

Returns true if integer scales are forced or false if not and on failure; call
L<< C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_RenderSetViewport( ... )>

Set the drawing area for rendering on the current target.

	SDL_RenderSetViewport( $renderer, $rect );

When the window is resized, the viewport is reset to fill the entire new window
size.

Expected parameters include:

=over

=item C<renderer> - the rendering context

=item C<rect> - the L<SDL2::Rect> structure representing the drawing area, or undef to set the viewport to the entire target

=back

Returns C<0> on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_RenderGetViewport( ... )>

Get the drawing area for the current target.

	my $rect = SDL_RenderGetViewport( $renderer );

Expected parameters include:

=over

=item C<renderer> - the rendering context

=back

Returns an L<SDL2::Rect> structure filled in with the current drawing area.

=head2 C<SDL_RenderSetClipRect( ... )>

Set the clip rectangle for rendering on the specified target.

	SDL_RenderSetClipRect( $renderer, $rect );

Expected parameters include:

=over

=item C<renderer> - the rendering context for which clip rectangle should be set

=item C<rect> - an L<SDL2::Rect> structure representing the clip area, relative to the viewport, or undef to disable clipping

=back

Returns C<0> on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_RenderGetClipRect( ... )>

Get the clip rectangle for the current target.

	my $rect = SDL_RenderGetClipRect( $renderer );

Expected parameters include:

=over

=item C<renderer> - the rendering context from which clip rectangle should be queried

=back

Returns an L<SDL2::Rect> structure filled in with the current clipping area or
an empty rectangle if clipping is disabled.

=head2 C<SDL_RenderIsClipEnabled( ... )>

Get whether clipping is enabled on the given renderer.

	my $tf = SDL_RenderIsClipEnabled( $renderer );

Expected parameters include:

=over

=item C<renderer> - the renderer from which clip state should be queried

=back

Returns true if clipping is enabled or false if not; call L<< C<SDL_GetError(
)>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_RenderSetScale( ... )>

Set the drawing scale for rendering on the current target.

	SDL_RenderSetScale( $renderer, .5, 1 );

The drawing coordinates are scaled by the x/y scaling factors before they are
used by the renderer. This allows resolution independent drawing with a single
coordinate system.

If this results in scaling or subpixel drawing by the rendering backend, it
will be handled using the appropriate quality hints. For best results use
integer scaling factors.

Expected parameters include:

=over

=item C<renderer> - a rendering context

=item C<scaleX> - the horizontal scaling factor

=item C<scaleY> - the vertical scaling factor

=back

Returns C<0> on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_RenderGetScale( ... )>

Get the drawing scale for the current target.

	my ($scaleX, $scaleY) = SDL_RenderGetScale( $renderer );

Expected parameters include:

=over

=item C<renderer> - the renderer from which drawing scale should be queried

=back

Returns the horizonal and vertical scaling factors.

=head2 C<SDL_SetRenderDrawColor( ... )>

Set the color used for drawing operations (Rect, Line and Clear).

	SDL_SetRenderDrawColor( $renderer, 0, 0, 128, SDL_ALPHA_OPAQUE );

Set the color for drawing or filling rectangles, lines, and points, and for L<<
C<SDL_RenderClear( ... )>|/C<SDL_RenderClear( ... )> >>.

Expected parameters include:

=over

=item C<renderer> - the rendering context

=item C<r> - the red value used to draw on the rendering target

=item C<g> - the green value used to draw on the rendering target

=item C<b> - the blue value used to draw on the rendering target

=item C<a> - the alpha value used to draw on the rendering target; usually C<SDL_ALPHA_OPAQUE> (255). Use C<SDL_SetRenderDrawBlendMode> to specify how the alpha channel is used

=back

Returns C<0> on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_GetRenderDrawColor( ... )>

Get the color used for drawing operations (Rect, Line and Clear).

	my ($r, $g, $b, $a) = SDL_GetRenderDrawColor( $renderer );

Expected parameters include:

=over

=item C<renderer> - the rendering context

=back

Returns red, green, blue, and alpha values on success or a negative error code
on failure; call L<< C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more
information.

=head2 C<SDL_SetRenderDrawBlendMode( ... )>

Set the blend mode used for drawing operations (Fill and Line).

	SDL_SetRenderDrawBlendMode( $renderer, SDL_BLENDMODE_BLEND );

If the blend mode is not supported, the closest supported mode is chosen.

Expected parameters include:

=over

=item C<renderer> - the rendering context

=item C<blendMode> - the L<< C<:blendMode>|/C<:blendMode> >> to use for blending

=back

Returns C<0> on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_GetRenderDrawBlendMode( ... )>

Get the blend mode used for drawing operations.

	my $blendMode = SDL_GetRenderDrawBlendMode( $rendering );

Expected parameters include:

=over

=item C<renderer> - the rendering context

=back

Returns the current C<:blendMode> on success or a negative error code on
failure; call L<< C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more
information.

=head2 C<SDL_RenderClear( ... )>

Clear the current rendering target with the drawing color.

	SDL_RenderClear( $renderer );

This function clears the entire rendering target, ignoring the viewport and the
clip rectangle.

=over

=item C<renderer> - the rendering context

=back

Returns C<0> on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_RenderDrawPoint( ... )>

Draw a point on the current rendering target.

	SDL_RenderDrawPoint( $renderer, 100, 100 );

C<SDL_RenderDrawPoint( ... )> draws a single point. If you want to draw
multiple, use L<< C<SDL_RenderDrawPoints( ... )>|/C<SDL_RenderDrawPoints( ...
)> >> instead.

Expected parameters include:

=over

=item C<renderer> - the rendering context

=item C<x> - the x coordinate of the point

=item C<y> - the y coordinate of the point

=back

Returns C<0> on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_RenderDrawPoints( ... )>

Draw multiple points on the current rendering target.

	my @points = map { SDL2::Point->new( {x => int rand, y => int rand } ) } 1..1024;
	SDL_RenderDrawPoints( $renderer, @points );

=over

=item C<renderer> - the rendering context

=item C<points> - an array of L<SDL2::Point> structures that represent the points to draw

=back

Returns C<0> on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_RenderDrawLine( ... )>

Draw a line on the current rendering target.

	SDL_RenderDrawLine( $renderer, 300, 240, 340, 240 );

C<SDL_RenderDrawLine( ... )> draws the line to include both end points. If you
want to draw multiple, connecting lines use L<< C<SDL_RenderDrawLines( ...
)>|/C<SDL_RenderDrawLines( ... )> >> instead.

Expected parameters include:

=over

=item C<renderer> - the rendering context

=item C<x1> - the x coordinate of the start point

=item C<y1> - the y coordinate of the start point

=item C<x2> - the x coordinate of the end point

=item C<y2> - the y coordinate of the end point

=back

Returns C<0> on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_RenderDrawLines( ... )>

Draw a series of connected lines on the current rendering target.

	SDL_RenderDrawLines( $renderer, @points);

Expected parameters include:

=over

=item C<renderer> - the rendering context

=item C<points> - an array of L<SDL2::Point> structures representing points along the lines

=back

Returns C<0> on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_RenderDrawRect( ... )>

Draw a rectangle on the current rendering target.

	SDL_RenderDrawRect( $renderer, SDL2::Rect->new( { x => 100, y => 100, w => 100, h => 100 } ) );

Expected parameters include:

=over

=item C<renderer> - the rendering context

=item C<rect> - an L<SDL2::Rect> structure representing the rectangle to draw

=for TODO - or undef to outline the entire rendering target

=back

Returns C<0> on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_RenderDrawRects( ... )>

Draw some number of rectangles on the current rendering target.

	SDL_RenderDrawRects( $renderer,
		SDL2::Rect->new( { x => 100, y => 100, w => 100, h => 100 } ),
        SDL2::Rect->new( { x => 75,  y => 75,  w => 50,  h => 50 } )
    );

Expected parameters include:

=over

=item C<renderer> - the rendering context

=item C<rects> - an array of SDL2::Rect structures representing the rectangles to be drawn

=back

Returns C<0> on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_RenderFillRect( ... )>

Fill a rectangle on the current rendering target with the drawing color.

	SDL_RenderFillRect( $renderer, SDL2::Rect->new( { x => 100, y => 100, w => 100, h => 100 } ) );

The current drawing color is set by L<< C<SDL_SetRenderDrawColor( ...
)>|/C<SDL_SetRenderDrawColor( ... )> >>, and the color's alpha value is ignored
unless blending is enabled with the appropriate call to L<<
C<SDL_SetRenderDrawBlendMode( ... )>|/C<SDL_SetRenderDrawBlendMode( ... )> >>.

Expected parameters include:

=over

=item C<renderer> - the rendering context

=item C<rect> - the L<SDL2::Rect> structure representing the rectangle to fill

=for TODO - or undef for the entire rendering target

=back

Returns C<0> on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_RenderFillRects( ... )>

Fill some number of rectangles on the current rendering target with the drawing
color.

	SDL_RenderFillRects( $renderer,
		SDL2::Rect->new( { x => 100, y => 100, w => 100, h => 100 } ),
        SDL2::Rect->new( { x => 75,  y => 75,  w => 50,  h => 50 } )
    );

Expected parameters include:

=over

=item C<renderer> - the rendering context

=item C<rects> - an array of L<SDL2::Rect> structures representing the rectangles to be filled

=back

Returns C<0> on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_RenderCopy( ... )>

Copy a portion of the texture to the current rendering target.

	SDL_RenderCopy( $renderer, $blueShapes, $srcR, $destR );

The texture is blended with the destination based on its blend mode set with
L<< C<SDL_SetTextureBlendMode( ... )>|/C<SDL_SetTextureBlendMode( ... )> >>.

The texture color is affected based on its color modulation set by L<<
C<SDL_SetTextureColorMod( ... )>|/C<SDL_SetTextureColorMod( ... )> >>.

The texture alpha is affected based on its alpha modulation set by L<<
C<SDL_SetTextureAlphaMod( ... )>|/C<SDL_SetTextureAlphaMod( ... )> >>.

Expected parameters include:

=over

=item C<renderer> - the rendering context

=item C<texture> - the source texture

=item C<srcrect> - the source L<SDL2::Rect> structure

=for TODO: or NULL for the entire texture

=item C<dstrect> - the destination L<SDL2::Rect> structure; the texture will be stretched to fill the given rectangle

=for TODO or NULL for the entire rendering target;

=back

Returns C<0> on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_RenderCopyEx( ... )>

Copy a portion of the texture to the current rendering, with optional rotation
and flipping.

=for TODO: I need an example for this... it's complex

Copy a portion of the texture to the current rendering target, optionally
rotating it by angle around the given center and also flipping it top-bottom
and/or left-right.

The texture is blended with the destination based on its blend mode set with
L<< C<SDL_SetTextureBlendMode( ... )>|/C<SDL_SetTextureBlendMode( ... )> >>.

The texture color is affected based on its color modulation set by L<<
C<SDL_SetTextureColorMod( ... )>|/C<SDL_SetTextureColorMod( ... )> >>.

The texture alpha is affected based on its alpha modulation set by L<<
C<SDL_SetTextureAlphaMod( ... )>|/C<SDL_SetTextureAlphaMod( ... )> >>.

Expected parameters include:

=over

=item C<renderer> - the rendering context

=item C<texture> - the source texture

=item C<srcrect> - the source L<SDL2::Rect> structure

=for TODO: or NULL for the entire texture

=item C<dstrect> - the destination SDL_Rect structure

=for TODO: or NULL for the entire rendering target

=item C<angle> - an angle in degrees that indicates the rotation that will be applied to dstrect, rotating it in a clockwise direction

=item C<center> - a pointer to a point indicating the point around which dstrect will be rotated (if NULL, rotation will be done around C<dstrect.w / 2>, C<dstrect.h / 2>)

=item C<flip> - a L<:rendererFlip> value stating which flipping actions should be performed on the texture

=back

Returns C<0> on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_RenderDrawPointF( ... )>

Draw a point on the current rendering target at subpixel precision.

	SDL_RenderDrawPointF( $renderer, 25.5, 100.25 );

Expected parameters include:

=over

=item C<renderer> - The renderer which should draw a point.

=item C<x> - The x coordinate of the point.

=item C<y> - The y coordinate of the point.

=back

Returns C<0> on success, or C<-1> on error

=head2 C<SDL_RenderDrawPointsF( ... )>

Draw multiple points on the current rendering target at subpixel precision.

	my @points = map { SDL2::Point->new( {x => int rand, y => int rand } ) } 1..1024;
	SDL_RenderDrawPointsF( $renderer, @points );

Expected parameters include:

=over

=item C<renderer> - The renderer which should draw multiple points

=item C<points> - The points to draw

=back

Returns C<0> on success, or C<-1> on error; call L<< C<SDL_GetError(
)>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_RenderDrawLineF( ... )>

Draw a line on the current rendering target at subpixel precision.

	SDL_RenderDrawLineF( $renderer, 100, 100, 250, 100);

Expected parameters include:

=over

=item C<renderer> - The renderer which should draw a line.

=item C<x1> - The x coordinate of the start point.

=item C<y1> - The y coordinate of the start point.

=item C<x2> - The x coordinate of the end point.

=item C<y2> - The y coordinate of the end point.

=back

Returns C<0> on success, or C<-1> on error.

=head2 C<SDL_RenderDrawLinesF( ... )>

Draw a series of connected lines on the current rendering target at subpixel
precision.

	SDL_RenderDrawLines( $renderer, @points);

Expected parameters include:

=over

=item C<renderer> - The renderer which should draw multiple lines.

=item C<points> - The points along the lines

=back

Return C<0> on success, or C<-1> on error.

=head2 C<SDL_RenderDrawRectF( ... )>

Draw a rectangle on the current rendering target at subpixel precision.

	SDL_RenderDrawRectF( $renderer, $point);

Expected parameters include:

=over

=item C<renderer> - The renderer which should draw a rectangle.

=item C<rect> - A pointer to the destination rectangle

=for TODO: or NULL to outline the entire rendering target.

=back

Returns C<0> on success, or C<-1> on error

=head2 C<SDL_RenderDrawRectsF( ... )>

Draw some number of rectangles on the current rendering target at subpixel
precision.

	SDL_RenderDrawRectsF( $renderer,
		SDL2::Rect->new( { x => 100, y => 100, w => 100, h => 100 } ),
        SDL2::Rect->new( { x => 75,  y => 75,  w => 50,  h => 50 } )
    );

Expected parameters include:

=over

=item C<renderer> - The renderer which should draw multiple rectangles.

=item C<rects> - A pointer to an array of destination rectangles.

=back

Returns C<0> on success, or C<-1> on error.

=head2 C<SDL_RenderFillRectF( ... )>

Fill a rectangle on the current rendering target with the drawing color at
subpixel precision.

	SDL_RenderFillRectF( $renderer,
        SDL2::Rect->new( { x => 75,  y => 75,  w => 50,  h => 50 } )
    );

Expected parameters include:

=over

=item C<renderer> - The renderer which should fill a rectangle.

=item C<rect> - A pointer to the destination rectangle

=for TODO: or NULL for the entire rendering target.

=back

Returns C<0> on success, or C<-1> on error.

=head2 C<SDL_RenderFillRectsF( ... )>

Fill some number of rectangles on the current rendering target with the drawing
color at subpixel precision.

	SDL_RenderFillRectsF( $renderer,
		SDL2::Rect->new( { x => 100, y => 100, w => 100, h => 100 } ),
        SDL2::Rect->new( { x => 75,  y => 75,  w => 50,  h => 50 } )
    );

Expected parameters include:

=over

=item C<renderer> - The renderer which should fill multiple rectangles.

=item C<rects> - A pointer to an array of destination rectangles.

=back

Returns C<0> on success, or C<-1> on error.

=head2 C<SDL_RenderCopyF( ... )>

Copy a portion of the texture to the current rendering target at subpixel
precision.

=for TODO: I need to come up with an example for this as well

Expected parameters include:

=over

=item C<renderer> - The renderer which should copy parts of a texture

=item C<texture> - The source texture

=item C<srcrect> - A pointer to the source rectangle

=for TODO: or NULL for the entiretexture.

=item C<dstrect> - A pointer to the destination rectangle

=for TODO: or NULL for the entire rendering target

=back

Returns C<0> on success, or C<-1> on error.

=head2 C<SDL_RenderCopyExF( ... )>

Copy a portion of the source texture to the current rendering target, with
rotation and flipping, at subpixel precision.

=for TODO: I need to come up with an example for this as well

=over

=item C<renderer> - The renderer which should copy parts of a texture

=item C<texture> - The source texture

=item C<srcrect> - A pointer to the source rectangle

=for TODO: or NULL for the entire texture

=item C<dstrect> - A pointer to the destination rectangle

=for TODO: or NULL for the entire rendering target.

=item C<angle> - An angle in degrees that indicates the rotation that will be applied to dstrect, rotating it in a clockwise direction

=item C<center> - A pointer to a point indicating the point around which dstrect will be rotated (if NULL, rotation will be done around C<dstrect.w/2>, C<dstrect.h/2>)

=item C<flip> - A C<:rendererFlip> value stating which flipping actions should be performed on the texture

=back

Returns C<0> on success, or C<-1> on error

=head2 C<SDL_RenderReadPixels( ... )>

Read pixels from the current rendering target to an array of pixels.

	SDL_RenderReadPixels(
        $renderer,
        SDL2::Rect->new( { x => 0, y => 0, w => 640, h => 480 } ),
        SDL_PIXELFORMAT_RGB888,
        $surface->pixels, $surface->pitch
    );

B<WARNING>: This is a very slow operation, and should not be used frequently.

C<pitch> specifies the number of bytes between rows in the destination
C<pixels> data. This allows you to write to a subrectangle or have padded rows
in the destination. Generally, C<pitch> should equal the number of pixels per
row in the `pixels` data times the number of bytes per pixel, but it might
contain additional padding (for example, 24bit RGB Windows Bitmap data pads all
rows to multiples of 4 bytes).

Expected parameters include:

=over

=item C<renderer> - the rendering context

=item C<rect> - an L<SDL2::Rect> structure representing the area to read

=for TODO: or NULL for the entire render target

=item C<format> - an C<:pixelFormatEnum> value of the desired format of the pixel data, or C<0> to use the format of the rendering target

=item C<pixels> - pointer to the pixel data to copy into

=item C<pitch> - the pitch of the C<pixels> parameter

=back

Returns C<0> on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_RenderPresent( ... )>

Update the screen with any rendering performed since the previous call.

	SDL_RenderPresent( $renderer );

SDL's rendering functions operate on a backbuffer; that is, calling a rendering
function such as L<< C<SDL_RenderDrawLine( ... )>|/C<SDL_RenderDrawLine( ... )>
>> does not directly put a line on the screen, but rather updates the
backbuffer. As such, you compose your entire scene and *present* the composed
backbuffer to the screen as a complete picture.

Therefore, when using SDL's rendering API, one does all drawing intended for
the frame, and then calls this function once per frame to present the final
drawing to the user.

The backbuffer should be considered invalidated after each present; do not
assume that previous contents will exist between frames. You are strongly
encouraged to call L<< C<SDL_RenderClear( ... )>|/C<SDL_RenderClear( ... )> >>
to initialize the backbuffer before starting each new frame's drawing, even if
you plan to overwrite every pixel.

Expected parameters include:

=over

=item C<renderer> - the rendering context

=back

=head2 C<SDL_DestroyTexture( ... )>

Destroy the specified texture.

	SDL_DestroyTexture( $texture );

Passing undef or an otherwise invalid texture will set the SDL error message to
"Invalid texture".

Expected parameters include:

=over

=item C<texture> - the texture to destroy

=back


=head2 C<SDL_DestroyRenderer( ... )>

Destroy the rendering context for a window and free associated textures.

	SDL_DestroyRenderer( $renderer );

Expected parameters include:

=over

=item C<renderer> - the rendering context

=back

=head2 C<SDL_RenderFlush( ... )>

Force the rendering context to flush any pending commands to the underlying
rendering API.

	SDL_RenderFlush( $renderer );

You do not need to (and in fact, shouldn't) call this function unless you are
planning to call into OpenGL/Direct3D/Metal/whatever directly in addition to
using an SDL_Renderer.

This is for a very-specific case: if you are using SDL's render API, you asked
for a specific renderer backend (OpenGL, Direct3D, etc), you set
C<SDL_HINT_RENDER_BATCHING> to "C<1>", and you plan to make OpenGL/D3D/whatever
calls in addition to SDL render API calls. If all of this applies, you should
call L<< C<SDL_RenderFlush( ... )>|/C<SDL_RenderFlush( ... )> >> between calls
to SDL's render API and the low-level API you're using in cooperation.

In all other cases, you can ignore this function. This is only here to get
maximum performance out of a specific situation. In all other cases, SDL will
do the right thing, perhaps at a performance loss.

This function is first available in SDL 2.0.10, and is not needed in 2.0.9 and
earlier, as earlier versions did not queue rendering commands at all, instead
flushing them to the OS immediately.

Expected parameters include:

=over

=item C<renderer> - the rendering context

=back

Returns C<0> on success or a negative error code on failure; call L<<
C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more information.


=head2 C<SDL_GL_BindTexture( ... )>

Bind an OpenGL/ES/ES2 texture to the current context.

	my ($texw, $texh) = SDL_GL_BindTexture( $texture );

This is for use with OpenGL instructions when rendering OpenGL primitives
directly.

If not NULL, the returned width and height values suitable for the provided
texture. In most cases, both will be C<1.0>, however, on systems that support
the GL_ARB_texture_rectangle extension, these values will actually be the pixel
width and height used to create the texture, so this factor needs to be taken
into account when providing texture coordinates to OpenGL.

You need a renderer to create an L<SDL2::Texture>, therefore you can only use
this function with an implicit OpenGL context from L<< C<SDL_CreateRenderer(
... )>|/C<SDL_CreateRenderer( ... )> >>, not with your own OpenGL context. If
you need control over your OpenGL context, you need to write your own
texture-loading methods.

Also note that SDL may upload RGB textures as BGR (or vice-versa), and re-order
the color channels in the shaders phase, so the uploaded texture may have
swapped color channels.

Expected parameters include:

=over

=item C<texture> - the texture to bind to the current OpenGL/ES/ES2 context

=back

Returns the texture's with and height on success, or -1 if the operation is not
supported; call L<< C<SDL_GetError( )>|/C<SDL_GetError( )> >>( ) for more
information.

=head2 C<SDL_GL_UnbindTexture( ... )>

Unbind an OpenGL/ES/ES2 texture from the current context.

	SDL_GL_UnbindTexture( $texture );

See L<< C<SDL_GL_BindTexture( ... )>|/C<SDL_GL_BindTexture( ... )> >> for
examples on how to use these functions.

Expected parameters include:

=over

=item C<texture> - the texture to unbind from the current OpenGL/ES/ES2 context

=back

Returns C<0> on success, or C<-1> if the operation is not supported.

=head2 C<SDL_RenderGetMetalLayer( ... )>

Get the CAMetalLayer associated with the given Metal renderer.

	my $opaque = SDL_RenderGetMetalLayer( $renderer );

This function returns C<void *>, so SDL doesn't have to include Metal's
headers, but it can be safely cast to a C<CAMetalLayer *>.

Expected parameters include:

=over

=item C<renderer> - the renderer to query

=back

Returns C<CAMetalLayer*> on success, or undef if the renderer isn't a Metal
renderer.

=head2 C<SDL_RenderGetMetalCommandEncoder( ... )>

Get the Metal command encoder for the current frame

	$opaque = SDL_RenderGetMetalCommandEncoder( $renderer );

This function returns C<void *>, so SDL doesn't have to include Metal's
headers, but it can be safely cast to an
C<idE<lt>MTLRenderCommandEncoderE<gt>>.

Expected parameters include:

=over

=item C<renderer> - the renderer to query

=back

Returns C<idE<lt>MTLRenderCommandEncoderE<gt>> on success, or undef if the
renderer isn't a Metal renderer.





















































=head2 C<SDL_ComposeCustomBlendMode( ... )>

Compose a custom blend mode for renderers.



The functions SDL_SetRenderDrawBlendMode and SDL_SetTextureBlendMode accept the
SDL_BlendMode returned by this function if the renderer supports it.

A blend mode controls how the pixels from a drawing operation (source) get
combined with the pixels from the render target (destination). First, the
components of the source and destination pixels get multiplied with their blend
factors. Then, the blend operation takes the two products and calculates the
result that will get stored in the render target.

Expressed in pseudocode, it would look like this:

	my $dstRGB = colorOperation( $srcRGB * $srcColorFactor, $dstRGB * $dstColorFactor );
 	my $dstA   = alphaOperation( $srcA * $srcAlphaFactor, $dstA * $dstAlphaFactor );

Where the functions C<colorOperation(src, dst)> and C<alphaOperation(src, dst)>
can return one of the following:

=over

=item C<src + dst>

=item C<src - dst>

=item C<dst - src>

=item C<min(src, dst)>

=item C<max(src, dst)>

=back

The red, green, and blue components are always multiplied with the first,
second, and third components of the SDL_BlendFactor, respectively. The fourth
component is not used.

The alpha component is always multiplied with the fourth component of the L<<
C<:blendFactor>|/C<:blendFactor> >>. The other components are not used in the
alpha calculation.

Support for these blend modes varies for each renderer. To check if a specific
L<< C<:blendMode>|/C<:blendMode> >> is supported, create a renderer and pass it
to either C<SDL_SetRenderDrawBlendMode> or C<SDL_SetTextureBlendMode>. They
will return with an error if the blend mode is not supported.

This list describes the support of custom blend modes for each renderer in SDL
2.0.6. All renderers support the four blend modes listed in the L<<
C<:blendMode>|/C<:blendMode> >> enumeration.

=over

=item B<direct3d> - Supports C<SDL_BLENDOPERATION_ADD> with all factors.

=item B<direct3d11> - Supports all operations with all factors. However, some factors produce unexpected results with C<SDL_BLENDOPERATION_MINIMUM> and C<SDL_BLENDOPERATION_MAXIMUM>.

=item B<opengl> - Supports the C<SDL_BLENDOPERATION_ADD> operation with all factors. OpenGL versions 1.1, 1.2, and 1.3 do not work correctly with SDL 2.0.6.

=item B<opengles> - Supports the C<SDL_BLENDOPERATION_ADD> operation with all factors. Color and alpha factors need to be the same. OpenGL ES 1 implementation specific: May also support C<SDL_BLENDOPERATION_SUBTRACT> and C<SDL_BLENDOPERATION_REV_SUBTRACT>. May support color and alpha operations being different from each other. May support color and alpha factors being different from each other.

=item B<opengles2> - Supports the C<SDL_BLENDOPERATION_ADD>, C<SDL_BLENDOPERATION_SUBTRACT>, C<SDL_BLENDOPERATION_REV_SUBTRACT> operations with all factors.

=item B<psp> - No custom blend mode support.

=item B<software> - No custom blend mode support.

=back

Some renderers do not provide an alpha component for the default render target.
The C<SDL_BLENDFACTOR_DST_ALPHA> and C<SDL_BLENDFACTOR_ONE_MINUS_DST_ALPHA>
factors do not have an effect in this case.

Expected parameters include:

=over

=item C<srcColorFactor> -the C<:blendFactor> applied to the red, green, and blue components of the source pixels

=item C<dstColorFactor> - the C<:blendFactor> applied to the red, green, and blue components of the destination pixels

=item C<colorOperation> - the C<:blendOperation> used to combine the red, green, and blue components of the source and destination pixels

=item C<srcAlphaFactor> - the C<:blendFactor> applied to the alpha component of the source pixels

=item C<dstAlphaFactor> - the C<:blendFactor> applied to the alpha component of the destination pixels

=item C<alphaOperation> - the C<:blendOperation> used to combine the alpha component of the source and destination pixels

=back

Returns a C<:blendMode> that represents the chosen factors and operations.

=head1 Time Management Routines

This section contains functions for handling the SDL time management routines.
They may be imported with the C<:timer> tag.

=head2 C<SDL_GetTicks( )>

Get the number of milliseconds since SDL library initialization.

	my $time = SDL_GetTicks( );

This value wraps if the program runs for more than C<~49> days.

Returns an unsigned 32-bit value representing the number of milliseconds since
the SDL library initialized.

=head2 C<SDL_GetPerformanceCounter( )>

Get the current value of the high resolution counter.

	my $high_timer = SDL_GetPerformanceCounter( );

This function is typically used for profiling.

The counter values are only meaningful relative to each other. Differences
between values can be converted to times by using L<<
C<SDL_GetPerformanceFrequency( )>|/C<SDL_GetPerformanceFrequency( )> >>.

Returns the current counter value.

=head2 C<SDL_GetPerformanceFrequency( ... )>

Get the count per second of the high resolution counter.

	my $hz = SDL_GetPerformanceFrequency( );

Returns a platform-specific count per second.

=head2 C<SDL_Delay( ... )>

Wait a specified number of milliseconds before returning.

	SDL_Delay( 1000 );

This function waits a specified number of milliseconds before returning. It
waits at least the specified time, but possibly longer due to OS scheduling.

Expected parameters include:

=over

=item C<ms> - the number of milliseconds to delay

=back

=head2 C<SDL_AddTimer( ... )>

Call a callback function at a future time.

   my $id = SDL_AddTimer( 1000, sub ( $interval, $data ) { warn 'ping!'; $interval; } );

If you use this function, you must pass C<SDL_INIT_TIMER> to L<< C<SDL_Init(
... )>|/C<SDL_Init( ... )> >>.

The callback function is passed the current timer interval and returns the next
timer interval. If the returned value is the same as the one passed in, the
periodic alarm continues, otherwise a new alarm is scheduled. If the callback
returns C<0>, the periodic alarm is cancelled.

The callback is run on a separate thread.

Timers take into account the amount of time it took to execute the callback.
For example, if the callback took 250 ms to execute and returned 1000 (ms), the
timer would only wait another 750 ms before its next iteration.

Timing may be inexact due to OS scheduling. Be sure to note the current time
with L<< C<SDL_GetTicks( )>|/C<SDL_GetTicks( )> >> or  L<<
C<SDL_GetPerformanceCounter( )>|/C<SDL_GetPerformanceCounter( )> >> in case
your callback needs to adjust for variances.

Expected parameters include:

=over

=item C<interval> - the timer delay, in milliseconds, passed to C<callback>

=item C<callback> - the C<CODE> reference to call when the specified C<interval> elapses

=item C<param> - a pointer that is passed to C<callback>

=back

Returns a timer ID or C<0> if an error occurs; call L<< C<SDL_GetError(
)>|/C<SDL_GetError( )> >>( ) for more information.

=head2 C<SDL_RemoveTimer( ... )>

	SDL_RemoveTimer( $id );

Remove a timer created with L<< C<SDL_AddTimer( ... )>|/C<SDL_AddTimer( ... )>
>>.

Expected parameters include:

=over

=item C<id> - the ID of the timer to remove

=back

Returns true if the timer is removed or false if the timer wasn't found.

=head1 Touch Event Handling

This section contains functions for handling the SDL touch event routines. They
may be imported with the C<:touch> tag.

=head2 C<SDL_GetNumTouchDevices( )>

Get the number of registered touch devices.

    my $count = SDL_GetNumTouchDevices();

On some platforms SDL first sees the touch device if it was actually used.
Therefore C<SDL_GetNumTouchDevices( )> may return C<0> although devices are
available. After using all devices at least once the number will be correct.

=head2 C<SDL_GetTouchDevice( ... )>

Get the touch ID with the given index.

    my $tID = SDL_GetTouchDevice( 0 );

Expected parameters include:

=over

=item C<index> - the touch device index

=back

Returns the touch ID with the given index on success or C<0> if the index is
invalid; call L<< C<SDL_GetError( )>|/C<SDL_GetError( )> >> for more
information.

=head2 C<SDL_GetTouchDeviceType( ... )>

Get the type of the given touch device.

	my $type = SDL_GetTouchDeviceType( 0 );

Expected parameters include:

=over

=item C<touchID> - the touch device ID

=back

Returns the C<SDL_TouchDeviceType>.

=head2 C<SDL_GetNumTouchFingers( ... )>

Get the number of active fingers for a given touch device.

	my $fingers = SDL_GetNumTouchFingers( 0 );

Expected parameters include:

=over

=item C<touchID> - the touch device ID

=back

Returns the number of active fingers for a given touch device on success or
C<0> on failure; call L<< C<SDL_GetError( )>|/C<SDL_GetError( )> >> for more
information.

=head2 C<SDL_GetTouchFinger( ... )>

Get the finger object for specified touch device ID and finger index.

	my $finger = SDL_GetTouchFinger( 0, 1 );

Expected parameters include:

=over

=item C<touchID> - the ID of the requested touch device

=item C<index> - the index of the requested finger

=back

Returns an L<SDL2::Finger> object on success or C<undef> if no object at the
given ID and index could be found.

=head1 Raw Audio Mixing

These methods provide access to the raw audio mixing buffer for the SDL
library. They may be imported with the C<:audio> tag.

=head2 C<SDL_GetNumAudioDrivers( )>

Returns a list of built in audio drivers, in the order that they were normally
initialized by default.

=head2 C<SDL_GetAudioDriver( ... )>

Returns an audio driver by name.

	my $driver = SDL_GetAudioDriver( 1 );

Expected parameters include:

=over

=item C<index> - The zero-based index of the desired audio driver

=back

=head2 C<SDL_AudioInit( ... )>

Audio system initialization.

	SDL_AudioInit( 'pulseaudio' );

This method is used internally, and should not be used unless you have a
specific need to specify the audio driver you want to use. You should normally
use L<< C<SDL_Init( ... )>|/C<SDL_Init( ... )> >>.

Returns C<0> on success.

=head2 C<SDL_AudioQuit( )>

Cleaning up initialized audio system.

	SDL_AudioQuit( );

This method is used internally, and should not be used unless you have a
specific need to close the selected audio driver. You should normally use L<<
C<SDL_Quit( )>|/C<SDL_Quit( )> >>.

=head2 C<SDL_GetCurrentAudioDriver( )>

Get the name of the current audio driver.

	my $driver = SDL_GetCurrentAudioDriver( );

The returned string points to internal static memory and thus never becomes
invalid, even if you quit the audio subsystem and initialize a new driver
(although such a case would return a different static string from another call
to this function, of course). As such, you should not modify or free the
returned string.

Returns the name of the current audio driver or undef if no driver has been
initialized.

=head2 C<SDL_OpenAudio( ... )>

This function is a legacy means of opening the audio device.

    my $obtained = SDL_OpenAudio(
        SDL2::AudioSpec->new( { freq => 48000, channels => 2, format => AUDIO_F32 } ) );

This function remains for compatibility with SDL 1.2, but also because it's
slightly easier to use than the new functions in SDL 2.0. The new, more
powerful, and preferred way to do this is L<< C<SDL_OpenAudioDevice( ...
)>|/C<SDL_OpenAudioDevice( ... )> >> .

This function is roughly equivalent to:

	SDL_OpenAudioDevice( (), 0, $desired, SDL_AUDIO_ALLOW_ANY_CHANGE );

With two notable exceptions:

=over

=item - If C<obtained> is undefined, we use C<desired> (and allow no changes), which
means desired will be modified to have the correct values for silence,
etc, and SDL will convert any differences between your app's specific
request and the hardware behind the scenes.

=item - The return value is always success or failure, and not a device ID, which
means you can only have one device open at a time with this function.

=back

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



=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

libSDL enum iOS iPhone tvOS gamepad gamepads bitmap colorkey asyncify keycode
ctrl+click OpenGL glibc pthread screensaver fullscreen SDL_gamecontroller.h
XBox XInput pthread pthreads realtime rtkit Keycode mutexes resources imple
irectMedia ayer errstr coderef patchlevel distro WinRT raspberrypi psp macOS
NSHighResolutionCapable lowlevel vsync gamecontroller framebuffer XRandR
XVidMode libc musl non letterbox libsamplerate AVAudioSessionCategoryAmbient
AVAudioSessionCategoryPlayback VoIP OpenGLES opengl opengles opengles2 spammy
popup tooltip taskbar subwindow high-dpi subpixel borderless draggable viewport
user-resizable resizable srcA srcC GiB dstrect rect subrectangle pseudocode ms
verystrict resampler eglSwapBuffers backbuffer scancode unhandled lifespan wgl
glX framerate deadzones vice-versa kmsdrm jp CAMetalLayer lockless spinlocks
spinlock redetect dequeueing dequeue capturable unpaused src iscapture nd
diskaudio underflow dequeued realloc memalign (ARMv6) deallocate hyperthreading
prefetch 3DNow PowerPC

=end stopwords

=cut

# Examples:
#  - https://github.com/crust/sdl2-examples
#
