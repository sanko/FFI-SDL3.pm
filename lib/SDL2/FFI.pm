package SDL2::FFI 0.01 {
    use strictures 2;
    #
    $|++;

    #use Carp::Always;
    #$ENV{FFI_PLATYPUS_DLERROR} = 1;
    use Data::Dump;
    #
    use FFI::CheckLib;
    use FFI::Platypus 1.00;
    use FFI::C;

    #use FFI::C::StructDef;
    use FFI::Platypus::Memory qw[malloc strcpy free];
    use FFI::C::ArrayDef;
    use FFI::Platypus::Closure;
    #
    use experimental 'signatures';
    use base 'Exporter::Tiny';
    use Alien::libsdl2;
    #
    my $ffi = FFI::Platypus->new( api => 1, experimental => 2,
        lib => [ Alien::libsdl2->dynamic_libs ] );
    FFI::C->ffi($ffi);
    use Config;
    my $bigendian = $Config{byteorder} != 4321;

    # I need these first
    class( SDL_version => [ major => 'uint8', minor => 'uint8', patch => 'uint8' ] );
    attach(
        version => {
            SDL_GetVersion => [
                ['SDL_version'] => sub ($inner) {
                    my $ver = SDL2::Version->new;
                    $inner->($ver);
                    $ver;
                }
            ]
        }
    );
    #
    my $ver      = SDL_GetVersion();
    my $platform = $^O;                            # https://perldoc.perl.org/perlport#PLATFORMS
    my $Windows  = !!( $platform eq 'MSWin32' );
    #
    # Export symbols!
    our %EXPORT_TAGS;

    # Sugar
    sub deprecate ($str) {
        warnings::warn( 'deprecated', $str ) if warnings::enabled('deprecated');
    }

    sub define (%args) {
        for my $tag ( keys %args ) {

            #print $_->[0] . ' ' for sort { $a->[0] cmp $b->[0] } @{ $Defines{$tag} };
            no strict 'refs';
            ref $_->[1] eq 'CODE' ? *{ __PACKAGE__ . '::' . $_->[0] } = $_->[1] :
                constant->import( $_->[0] => $_->[1] )
                for @{ $args{$tag} };

            #constant->import( $_ => $_ ) for @{ $Defines{$tag} };
            $EXPORT_TAGS{ lc substr $tag, 4 }
                = [ sort map { ref $_ ? $_->[0] : $_ } @{ $args{$tag} } ];
        }
    }

    sub enum (%args) {
        for my $tag ( keys %args ) {
            FFI::C->enum( $tag => $args{$tag} );
            $EXPORT_TAGS{ lc substr $tag, 4 }
                = [ sort map { ref $_ ? ref $_ eq 'CODE' ? $_->() : $_->[0] : $_ }
                    @{ $args{$tag} } ];
        }
    }

    sub attach (%args) {
        for my $tag ( sort keys %args ) {
            for my $func ( sort keys %{ $args{$tag} } ) {
                warn sprintf '$ffi->attach( %s => %s);', $func,
                    Data::Dump::dump( @{ $args{$tag}{$func} } )
                    if ref $args{$tag}{$func}[1] && ref $args{$tag}{$func}[1] eq 'ARRAY';
                $ffi->attach( $func => @{ $args{$tag}{$func} } );
                push @{ $EXPORT_TAGS{$tag} }, $func;
            }
        }
    }

    sub class (%args) {
        for my $name ( keys %args ) {
            my $class = $name;
            $class =~ s[^SDL_(.+)$]['SDL2::' . ucfirst $1 ]e;
            warn sprintf '%-20s => %-20s%s', $name, $class, (
                -f sub ($package) { $package =~ m[::(.+)]; './lib/SDL2/' . $1 . '.pod' }
                    ->($class) ? '' : ' (undocumented)'
            );
            FFI::C::StructDef->new(
                $ffi,
                name     => $name,
                class    => $class,
                members  => $args{$name},
                nullable => 1
            );
        }
    }
    #
    enum(
        # https://github.com/libsdl-org/SDL/blob/main/include/SDL_hints.h
        SDL_HintPriority => [qw[SDL_HINT_DEFAULT SDL_HINT_NORMAL SDL_HINT_OVERRIDE]],
        SDL_LogCategory  => [
            qw[
                SDL_LOG_CATEGORY_APPLICATION SDL_LOG_CATEGORY_ERROR SDL_LOG_CATEGORY_ASSERT
                SDL_LOG_CATEGORY_SYSTEM      SDL_LOG_CATEGORY_AUDIO SDL_LOG_CATEGORY_VIDEO
                SDL_LOG_CATEGORY_RENDER      SDL_LOG_CATEGORY_INPUT SDL_LOG_CATEGORY_TEST
                SDL_LOG_CATEGORY_RESERVED1   SDL_LOG_CATEGORY_RESERVED2
                SDL_LOG_CATEGORY_RESERVED3   SDL_LOG_CATEGORY_RESERVED4
                SDL_LOG_CATEGORY_RESERVED5   SDL_LOG_CATEGORY_RESERVED6
                SDL_LOG_CATEGORY_RESERVED7   SDL_LOG_CATEGORY_RESERVED8
                SDL_LOG_CATEGORY_RESERVED9   SDL_LOG_CATEGORY_RESERVED10
                SDL_LOG_CATEGORY_CUSTOM
            ]
        ],
        SDL_LogPriority => [
            [ SDL_LOG_PRIORITY_VERBOSE => 1 ], qw[SDL_LOG_PRIORITY_DEBUG SDL_LOG_PRIORITY_INFO
                SDL_LOG_PRIORITY_WARN SDL_LOG_PRIORITY_ERROR SDL_LOG_PRIORITY_CRITICAL
                SDL_NUM_LOG_PRIORITIES]
        ],
    );
    define(
        SDL_Init => [
            [ SDL_INIT_TIMER          => 0x00000001 ],
            [ SDL_INIT_AUDIO          => 0x00000010 ],
            [ SDL_INIT_VIDEO          => 0x00000020 ],
            [ SDL_INIT_JOYSTICK       => 0x00000200 ],
            [ SDL_INIT_HAPTIC         => 0x00001000 ],
            [ SDL_INIT_GAMECONTROLLER => 0x00002000 ],
            [ SDL_INIT_EVENTS         => 0x00004000 ],
            [ SDL_INIT_SENSOR         => 0x00008000 ],
            [ SDL_INIT_NOPARACHUTE    => 0x00100000 ],
            [   SDL_INIT_EVERYTHING => sub {
                    SDL_INIT_TIMER() | SDL_INIT_AUDIO() | SDL_INIT_VIDEO() | SDL_INIT_EVENTS()
                        | SDL_INIT_JOYSTICK() | SDL_INIT_HAPTIC() | SDL_INIT_GAMECONTROLLER()
                        | SDL_INIT_SENSOR();
                }
            ]
        ],

        # https://github.com/libsdl-org/SDL/blob/main/include/SDL_hints.h
        SDL_Hint => [
            [ SDL_HINT_ACCELEROMETER_AS_JOYSTICK   => 'SDL_ACCELEROMETER_AS_JOYSTICK' ],
            [ SDL_HINT_ALLOW_ALT_TAB_WHILE_GRABBED => 'SDL_ALLOW_ALT_TAB_WHILE_GRABBED' ],
            [ SDL_HINT_ALLOW_TOPMOST               => 'SDL_ALLOW_TOPMOST' ],
            [   SDL_HINT_ANDROID_APK_EXPANSION_MAIN_FILE_VERSION =>
                    'SDL_ANDROID_APK_EXPANSION_MAIN_FILE_VERSION'
            ],
            [   SDL_HINT_ANDROID_APK_EXPANSION_PATCH_FILE_VERSION =>
                    'SDL_ANDROID_APK_EXPANSION_PATCH_FILE_VERSION'
            ],
            [ SDL_HINT_ANDROID_BLOCK_ON_PAUSE => 'SDL_ANDROID_BLOCK_ON_PAUSE' ],
            [   SDL_HINT_ANDROID_BLOCK_ON_PAUSE_PAUSEAUDIO =>
                    'SDL_ANDROID_BLOCK_ON_PAUSE_PAUSEAUDIO'
            ],
            [ SDL_HINT_ANDROID_SEPARATE_MOUSE_AND_TOUCH => 'SDL_ANDROID_SEPARATE_MOUSE_AND_TOUCH' ],
            [ SDL_HINT_ANDROID_TRAP_BACK_BUTTON         => 'SDL_ANDROID_TRAP_BACK_BUTTON' ],
            [ SDL_HINT_APPLE_TV_CONTROLLER_UI_EVENTS    => 'SDL_APPLE_TV_CONTROLLER_UI_EVENTS' ],
            [ SDL_HINT_APPLE_TV_REMOTE_ALLOW_ROTATION   => 'SDL_APPLE_TV_REMOTE_ALLOW_ROTATION' ],
            [ SDL_HINT_AUDIO_CATEGORY                   => 'SDL_AUDIO_CATEGORY' ],
            [ SDL_HINT_AUDIO_DEVICE_APP_NAME            => 'SDL_AUDIO_DEVICE_APP_NAME' ],
            [ SDL_HINT_AUDIO_DEVICE_STREAM_NAME         => 'SDL_AUDIO_DEVICE_STREAM_NAME' ],
            [ SDL_HINT_AUDIO_DEVICE_STREAM_ROLE         => 'SDL_AUDIO_DEVICE_STREAM_ROLE' ],
            [ SDL_HINT_AUDIO_RESAMPLING_MODE            => 'SDL_AUDIO_RESAMPLING_MODE' ],
            [ SDL_HINT_AUTO_UPDATE_JOYSTICKS            => 'SDL_AUTO_UPDATE_JOYSTICKS' ],
            [ SDL_HINT_AUTO_UPDATE_SENSORS              => 'SDL_AUTO_UPDATE_SENSORS' ],
            [ SDL_HINT_BMP_SAVE_LEGACY_FORMAT           => 'SDL_BMP_SAVE_LEGACY_FORMAT' ],
            [ SDL_HINT_DISPLAY_USABLE_BOUNDS            => 'SDL_DISPLAY_USABLE_BOUNDS' ],
            [ SDL_HINT_EMSCRIPTEN_ASYNCIFY              => 'SDL_EMSCRIPTEN_ASYNCIFY' ],
            [ SDL_HINT_EMSCRIPTEN_KEYBOARD_ELEMENT      => 'SDL_EMSCRIPTEN_KEYBOARD_ELEMENT' ],
            [ SDL_HINT_ENABLE_STEAM_CONTROLLERS         => 'SDL_ENABLE_STEAM_CONTROLLERS' ],
            [ SDL_HINT_EVENT_LOGGING                    => 'SDL_EVENT_LOGGING' ],
            [ SDL_HINT_FRAMEBUFFER_ACCELERATION         => 'SDL_FRAMEBUFFER_ACCELERATION' ],
            [ SDL_HINT_GAMECONTROLLERCONFIG             => 'SDL_GAMECONTROLLERCONFIG' ],
            [ SDL_HINT_GAMECONTROLLERCONFIG_FILE        => 'SDL_GAMECONTROLLERCONFIG_FILE' ],
            [ SDL_HINT_GAMECONTROLLERTYPE               => 'SDL_GAMECONTROLLERTYPE' ],
            [ SDL_HINT_GAMECONTROLLER_IGNORE_DEVICES    => 'SDL_GAMECONTROLLER_IGNORE_DEVICES' ],
            [   SDL_HINT_GAMECONTROLLER_IGNORE_DEVICES_EXCEPT =>
                    'SDL_GAMECONTROLLER_IGNORE_DEVICES_EXCEPT'
            ],
            [ SDL_HINT_GAMECONTROLLER_USE_BUTTON_LABELS => 'SDL_GAMECONTROLLER_USE_BUTTON_LABELS' ],
            [ SDL_HINT_GRAB_KEYBOARD                    => 'SDL_GRAB_KEYBOARD' ],
            [ SDL_HINT_IDLE_TIMER_DISABLED              => 'SDL_IDLE_TIMER_DISABLED' ],
            [ SDL_HINT_IME_INTERNAL_EDITING             => 'SDL_IME_INTERNAL_EDITING' ],
            [ SDL_HINT_IOS_HIDE_HOME_INDICATOR          => 'SDL_IOS_HIDE_HOME_INDICATOR' ],
            [ SDL_HINT_JOYSTICK_ALLOW_BACKGROUND_EVENTS => 'SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS' ],
            [ SDL_HINT_JOYSTICK_HIDAPI                  => 'SDL_JOYSTICK_HIDAPI' ],
            [ SDL_HINT_JOYSTICK_HIDAPI_CORRELATE_XINPUT => 'SDL_JOYSTICK_HIDAPI_CORRELATE_XINPUT' ],
            [ SDL_HINT_JOYSTICK_HIDAPI_GAMECUBE         => 'SDL_JOYSTICK_HIDAPI_GAMECUBE' ],
            [ SDL_HINT_JOYSTICK_HIDAPI_JOY_CONS         => 'SDL_JOYSTICK_HIDAPI_JOY_CONS' ],
            [ SDL_HINT_JOYSTICK_HIDAPI_PS4              => 'SDL_JOYSTICK_HIDAPI_PS4' ],
            [ SDL_HINT_JOYSTICK_HIDAPI_PS4_RUMBLE       => 'SDL_JOYSTICK_HIDAPI_PS4_RUMBLE' ],
            [ SDL_HINT_JOYSTICK_HIDAPI_PS5              => 'SDL_JOYSTICK_HIDAPI_PS5' ],
            [ SDL_HINT_JOYSTICK_HIDAPI_PS5_PLAYER_LED   => 'SDL_JOYSTICK_HIDAPI_PS5_PLAYER_LED' ],
            [ SDL_HINT_JOYSTICK_HIDAPI_PS5_RUMBLE       => 'SDL_JOYSTICK_HIDAPI_PS5_RUMBLE' ],
            [ SDL_HINT_JOYSTICK_HIDAPI_STADIA           => 'SDL_JOYSTICK_HIDAPI_STADIA' ],
            [ SDL_HINT_JOYSTICK_HIDAPI_STEAM            => 'SDL_JOYSTICK_HIDAPI_STEAM' ],
            [ SDL_HINT_JOYSTICK_HIDAPI_SWITCH           => 'SDL_JOYSTICK_HIDAPI_SWITCH' ],
            [ SDL_HINT_JOYSTICK_HIDAPI_SWITCH_HOME_LED  => 'SDL_JOYSTICK_HIDAPI_SWITCH_HOME_LED' ],
            [ SDL_HINT_JOYSTICK_HIDAPI_XBOX             => 'SDL_JOYSTICK_HIDAPI_XBOX' ],
            [ SDL_HINT_JOYSTICK_RAWINPUT                => 'SDL_JOYSTICK_RAWINPUT' ],
            [ SDL_HINT_JOYSTICK_THREAD                  => 'SDL_JOYSTICK_THREAD' ],
            [ SDL_HINT_KMSDRM_REQUIRE_DRM_MASTER        => 'SDL_KMSDRM_REQUIRE_DRM_MASTER' ],
            [ SDL_HINT_LINUX_JOYSTICK_DEADZONES         => 'SDL_LINUX_JOYSTICK_DEADZONES' ],
            [ SDL_HINT_MAC_BACKGROUND_APP               => 'SDL_MAC_BACKGROUND_APP' ],
            [   SDL_HINT_MAC_CTRL_CLICK_EMULATE_RIGHT_CLICK =>
                    'SDL_MAC_CTRL_CLICK_EMULATE_RIGHT_CLICK'
            ],
            [ SDL_HINT_MOUSE_DOUBLE_CLICK_RADIUS     => 'SDL_MOUSE_DOUBLE_CLICK_RADIUS' ],
            [ SDL_HINT_MOUSE_DOUBLE_CLICK_TIME       => 'SDL_MOUSE_DOUBLE_CLICK_TIME' ],
            [ SDL_HINT_MOUSE_FOCUS_CLICKTHROUGH      => 'SDL_MOUSE_FOCUS_CLICKTHROUGH' ],
            [ SDL_HINT_MOUSE_NORMAL_SPEED_SCALE      => 'SDL_MOUSE_NORMAL_SPEED_SCALE' ],
            [ SDL_HINT_MOUSE_RELATIVE_MODE_WARP      => 'SDL_MOUSE_RELATIVE_MODE_WARP' ],
            [ SDL_HINT_MOUSE_RELATIVE_SCALING        => 'SDL_MOUSE_RELATIVE_SCALING' ],
            [ SDL_HINT_MOUSE_RELATIVE_SPEED_SCALE    => 'SDL_MOUSE_RELATIVE_SPEED_SCALE' ],
            [ SDL_HINT_MOUSE_TOUCH_EVENTS            => 'SDL_MOUSE_TOUCH_EVENTS' ],
            [ SDL_HINT_NO_SIGNAL_HANDLERS            => 'SDL_NO_SIGNAL_HANDLERS' ],
            [ SDL_HINT_OPENGL_ES_DRIVER              => 'SDL_OPENGL_ES_DRIVER' ],
            [ SDL_HINT_ORIENTATIONS                  => 'SDL_ORIENTATIONS' ],
            [ SDL_HINT_PREFERRED_LOCALES             => 'SDL_PREFERRED_LOCALES' ],
            [ SDL_HINT_QTWAYLAND_CONTENT_ORIENTATION => 'SDL_QTWAYLAND_CONTENT_ORIENTATION' ],
            [ SDL_HINT_QTWAYLAND_WINDOW_FLAGS        => 'SDL_QTWAYLAND_WINDOW_FLAGS' ],
            [ SDL_HINT_RENDER_BATCHING               => 'SDL_RENDER_BATCHING' ],
            [ SDL_HINT_RENDER_DIRECT3D11_DEBUG       => 'SDL_RENDER_DIRECT3D11_DEBUG' ],
            [ SDL_HINT_RENDER_DIRECT3D_THREADSAFE    => 'SDL_RENDER_DIRECT3D_THREADSAFE' ],
            [ SDL_HINT_RENDER_DRIVER                 => 'SDL_RENDER_DRIVER' ],
            [ SDL_HINT_RENDER_LOGICAL_SIZE_MODE      => 'SDL_RENDER_LOGICAL_SIZE_MODE' ],
            [ SDL_HINT_RENDER_OPENGL_SHADERS         => 'SDL_RENDER_OPENGL_SHADERS' ],
            [ SDL_HINT_RENDER_SCALE_QUALITY          => 'SDL_RENDER_SCALE_QUALITY' ],
            [ SDL_HINT_RENDER_VSYNC                  => 'SDL_RENDER_VSYNC' ],
            [ SDL_HINT_RETURN_KEY_HIDES_IME          => 'SDL_RETURN_KEY_HIDES_IME' ],
            [ SDL_HINT_RPI_VIDEO_LAYER               => 'SDL_RPI_VIDEO_LAYER' ],
            [   SDL_HINT_THREAD_FORCE_REALTIME_TIME_CRITICAL =>
                    'SDL_THREAD_FORCE_REALTIME_TIME_CRITICAL'
            ],
            [ SDL_HINT_THREAD_PRIORITY_POLICY          => 'SDL_THREAD_PRIORITY_POLICY' ],
            [ SDL_HINT_THREAD_STACK_SIZE               => 'SDL_THREAD_STACK_SIZE' ],
            [ SDL_HINT_TIMER_RESOLUTION                => 'SDL_TIMER_RESOLUTION' ],
            [ SDL_HINT_TOUCH_MOUSE_EVENTS              => 'SDL_TOUCH_MOUSE_EVENTS' ],
            [ SDL_HINT_TV_REMOTE_AS_JOYSTICK           => 'SDL_TV_REMOTE_AS_JOYSTICK' ],
            [ SDL_HINT_VIDEO_ALLOW_SCREENSAVER         => 'SDL_VIDEO_ALLOW_SCREENSAVER' ],
            [ SDL_HINT_VIDEO_DOUBLE_BUFFER             => 'SDL_VIDEO_DOUBLE_BUFFER' ],
            [ SDL_HINT_VIDEO_EXTERNAL_CONTEXT          => 'SDL_VIDEO_EXTERNAL_CONTEXT' ],
            [ SDL_HINT_VIDEO_HIGHDPI_DISABLED          => 'SDL_VIDEO_HIGHDPI_DISABLED' ],
            [ SDL_HINT_VIDEO_MAC_FULLSCREEN_SPACES     => 'SDL_VIDEO_MAC_FULLSCREEN_SPACES' ],
            [ SDL_HINT_VIDEO_MINIMIZE_ON_FOCUS_LOSS    => 'SDL_VIDEO_MINIMIZE_ON_FOCUS_LOSS' ],
            [ SDL_HINT_VIDEO_WINDOW_SHARE_PIXEL_FORMAT => 'SDL_VIDEO_WINDOW_SHARE_PIXEL_FORMAT' ],
            [ SDL_HINT_VIDEO_WIN_D3DCOMPILE            => 'SDL_VIDEO_WIN_D3DCOMPILE' ],
            [ SDL_HINT_VIDEO_WIN_D3DCOMPILER           => 'SDL_VIDEO_WIN_D3DCOMPILER' ],
            [ SDL_HINT_VIDEO_X11_FORCE_EGL             => 'SDL_VIDEO_X11_FORCE_EGL' ],
            [   SDL_HINT_VIDEO_X11_NET_WM_BYPASS_COMPOSITOR =>
                    'SDL_VIDEO_X11_NET_WM_BYPASS_COMPOSITOR'
            ],
            [ SDL_HINT_VIDEO_X11_NET_WM_PING         => 'SDL_VIDEO_X11_NET_WM_PING' ],
            [ SDL_HINT_VIDEO_X11_WINDOW_VISUALID     => 'SDL_VIDEO_X11_WINDOW_VISUALID' ],
            [ SDL_HINT_VIDEO_X11_XINERAMA            => 'SDL_VIDEO_X11_XINERAMA' ],
            [ SDL_HINT_VIDEO_X11_XRANDR              => 'SDL_VIDEO_X11_XRANDR' ],
            [ SDL_HINT_VIDEO_X11_XVIDMODE            => 'SDL_VIDEO_X11_XVIDMODE' ],
            [ SDL_HINT_WAVE_FACT_CHUNK               => 'SDL_WAVE_FACT_CHUNK' ],
            [ SDL_HINT_WAVE_RIFF_CHUNK_SIZE          => 'SDL_WAVE_RIFF_CHUNK_SIZE' ],
            [ SDL_HINT_WAVE_TRUNCATION               => 'SDL_WAVE_TRUNCATION' ],
            [ SDL_HINT_WINDOWS_DISABLE_THREAD_NAMING => 'SDL_WINDOWS_DISABLE_THREAD_NAMING' ],
            [ SDL_HINT_WINDOWS_ENABLE_MESSAGELOOP    => 'SDL_WINDOWS_ENABLE_MESSAGELOOP' ],
            [   SDL_HINT_WINDOWS_FORCE_MUTEX_CRITICAL_SECTIONS =>
                    'SDL_WINDOWS_FORCE_MUTEX_CRITICAL_SECTIONS'
            ],
            [ SDL_HINT_WINDOWS_FORCE_SEMAPHORE_KERNEL => 'SDL_WINDOWS_FORCE_SEMAPHORE_KERNEL' ],
            [ SDL_HINT_WINDOWS_INTRESOURCE_ICON       => 'SDL_WINDOWS_INTRESOURCE_ICON' ],
            [ SDL_HINT_WINDOWS_INTRESOURCE_ICON_SMALL => 'SDL_WINDOWS_INTRESOURCE_ICON_SMALL' ],
            [ SDL_HINT_WINDOWS_NO_CLOSE_ON_ALT_F4     => 'SDL_WINDOWS_NO_CLOSE_ON_ALT_F4' ],
            [ SDL_HINT_WINDOWS_USE_D3D9EX             => 'SDL_WINDOWS_USE_D3D9EX' ],
            [   SDL_HINT_WINDOW_FRAME_USABLE_WHILE_CURSOR_HIDDEN =>
                    'SDL_WINDOW_FRAME_USABLE_WHILE_CURSOR_HIDDEN'
            ],
            [ SDL_HINT_WINRT_HANDLE_BACK_BUTTON        => 'SDL_WINRT_HANDLE_BACK_BUTTON' ],
            [ SDL_HINT_WINRT_PRIVACY_POLICY_LABEL      => 'SDL_WINRT_PRIVACY_POLICY_LABEL' ],
            [ SDL_HINT_WINRT_PRIVACY_POLICY_URL        => 'SDL_WINRT_PRIVACY_POLICY_URL' ],
            [ SDL_HINT_XINPUT_ENABLED                  => 'SDL_XINPUT_ENABLED' ],
            [ SDL_HINT_XINPUT_USE_OLD_JOYSTICK_MAPPING => 'SDL_XINPUT_USE_OLD_JOYSTICK_MAPPING' ]
        ]
    );
    class
        SDL_Point  => [ x => 'int',   y => 'int' ],
        SDL_FPoint => [ x => 'float', y => 'float' ],
        SDL_Rect   => [ x => 'int',   y => 'int',   w => 'int',   h => 'int' ],
        SDL_FRect  => [ x => 'float', y => 'float', w => 'float', h => 'float' ];
    FFI::C::ArrayDef->new(    # Used sparingly when I need to pass a list of SDL_Point objects
        $ffi,
        name    => 'SDLx_PointList',
        class   => 'SDL2x::PointList',
        members => ['SDL_Point'],
    );
    FFI::C::ArrayDef->new(    # Used sparingly when I need to pass a list of SDL_Point objects
        $ffi,
        name    => 'SDLx_FPointList',
        class   => 'SDL2x::FPointList',
        members => ['SDL_Point'],
    );
    FFI::C::ArrayDef->new(    # Used sparingly when I need to pass a list of SDL_Rect objects
        $ffi,
        name    => 'SDLx_RectList',
        class   => 'SDL2x::RectList',
        members => ['SDL_Rect'],
    );
    FFI::C::ArrayDef->new(    # Used sparingly when I need to pass a list of SDL_Rect objects
        $ffi,
        name    => 'SDLx_FRectList',
        class   => 'SDL2x::FRectList',
        members => ['SDL_FRect'],
    );
    class SDL_Surface => [
        flags     => 'uint32',
        format    => 'opaque',     # SDL_PixelFormat*
        w         => 'int',
        h         => 'int',
        pitch     => 'int',
        pixels    => 'opaque',     # void*
        userdata  => 'opaque',     # void*
        locked    => 'int',
        lock_data => 'opaque',     # void*
        clip_rect => 'SDL_Rect',
        map       => 'opaque',     # SDL_BlitMap*
        refcount  => 'int'
    ];
    #
    attach default => {
        SDL_Init          => [ ['uint32'] => 'int' ],
        SDL_InitSubSystem => [ ['uint32'] => 'int' ],
        SDL_QuitSubSystem => [ ['uint32'] ],
        SDL_WasInit       => [ ['uint32'] => 'uint32' ],
        SDL_Quit          => [ [] ],
    };
    #
    $ffi->type( '(opaque,string,string,string)->void' => 'SDL_HintCallback' );
    $ffi->type( '(opaque,int,int,string)->void'       => 'SDL_LogOutputFunction' );
    $ffi->type( '(opaque,opaque,opaque)->int'         => 'SDL_HitTest' );
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
        SDL_ClearError => [ [] => 'void' ]
        },
        log => {
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

    # https://github.com/libsdl-org/SDL/blob/main/include/SDL_video.h
    class
        SDL_DisplayMode => [
        format       => 'uint32',
        w            => 'int',
        h            => 'int',
        refresh_rate => 'int',
        driverdata   => 'opaque'
        ],
        SDL_Window => [
        magic                 => 'opaque',
        id                    => 'uint32',
        title                 => 'opaque',         # char *
        icon                  => 'SDL_Surface',
        x                     => 'int',
        y                     => 'int',
        w                     => 'int',
        h                     => 'int',
        min_w                 => 'int',
        min_h                 => 'int',
        max_w                 => 'int',
        max_h                 => 'int',
        flags                 => 'uint32',
        last_fullscreen_flags => 'uint32',
        windowed              => 'SDL_Rect',
        fullscreen_mode       => 'opaque',         # SDL_DisplayMode
        opacity               => 'float',
        brightness            => 'float',
        gamma                 => 'uint16[255]',    # uint16*
        saved_gamma           => 'uint16[255]',    # uint16*
        surface               => 'opaque',         # SDL_Surface*
        surface_valid         => 'bool',
        is_hiding             => 'bool',
        is_destroying         => 'bool',
        is_dropping           => 'bool',
        shaper                => 'opaque',         # SDL_WindowShaper
        hit_test              => 'opaque',         # SDL_HitTest
        hit_test_data         => 'opaque',         # void*
        data                  => 'opaque',         # SDL_WindowUserData*
        driverdata            => 'opaque',         # void*
        prev                  => 'opaque',         # SDL_Window*
        next                  => 'opaque'          # SDL_Window*
        ];
    enum
        SDL_WindowFlags => [
        [ SDL_WINDOW_FULLSCREEN         => 0x00000001 ],
        [ SDL_WINDOW_OPENGL             => 0x00000002 ],
        [ SDL_WINDOW_SHOWN              => 0x00000004 ],
        [ SDL_WINDOW_HIDDEN             => 0x00000008 ],
        [ SDL_WINDOW_BORDERLESS         => 0x00000010 ],
        [ SDL_WINDOW_RESIZABLE          => 0x00000020 ],
        [ SDL_WINDOW_MINIMIZED          => 0x00000040 ],
        [ SDL_WINDOW_MAXIMIZED          => 0x00000080 ],
        [ SDL_WINDOW_MOUSE_GRABBED      => 0x00000100 ],
        [ SDL_WINDOW_INPUT_FOCUS        => 0x00000200 ],
        [ SDL_WINDOW_MOUSE_FOCUS        => 0x00000400 ],
        [ SDL_WINDOW_FULLSCREEN_DESKTOP => sub { ( SDL_WINDOW_FULLSCREEN() | 0x00001000 ) } ],
        [ SDL_WINDOW_FOREIGN            => 0x00000800 ],
        [ SDL_WINDOW_ALLOW_HIGHDPI      => 0x00002000 ],
        [ SDL_WINDOW_MOUSE_CAPTURE      => 0x00004000 ],
        [ SDL_WINDOW_ALWAYS_ON_TOP      => 0x00008000 ],
        [ SDL_WINDOW_SKIP_TASKBAR       => 0x00010000 ],
        [ SDL_WINDOW_UTILITY            => 0x00020000 ],
        [ SDL_WINDOW_TOOLTIP            => 0x00040000 ],
        [ SDL_WINDOW_POPUP_MENU         => 0x00080000 ],
        [ SDL_WINDOW_KEYBOARD_GRABBED   => 0x00100000 ],
        [ SDL_WINDOW_VULKAN             => 0x10000000 ],
        [ SDL_WINDOW_METAL              => 0x20000000 ],
        [ SDL_WINDOW_INPUT_GRABBED      => sub { SDL_WINDOW_MOUSE_GRABBED() } ],
        ],
        SDL_WindowFlags => [
        qw[
            SDL_WINDOWEVENT_NONE
            SDL_WINDOWEVENT_SHOWN
            SDL_WINDOWEVENT_HIDDEN
            SDL_WINDOWEVENT_EXPOSED
            SDL_WINDOWEVENT_MOVED
            SDL_WINDOWEVENT_RESIZED
            SDL_WINDOWEVENT_SIZE_CHANGED
            SDL_WINDOWEVENT_MINIMIZED
            SDL_WINDOWEVENT_MAXIMIZED
            SDL_WINDOWEVENT_RESTORED
            SDL_WINDOWEVENT_ENTER
            SDL_WINDOWEVENT_LEAVE
            SDL_WINDOWEVENT_FOCUS_GAINED
            SDL_WINDOWEVENT_FOCUS_LOST
            SDL_WINDOWEVENT_CLOSE
            SDL_WINDOWEVENT_TAKE_FOCUS
            SDL_WINDOWEVENT_HIT_TEST
        ]
        ],
        SDL_DisplayEventID => [
        qw[SDL_DISPLAYEVENT_NONE SDL_DISPLAYEVENT_ORIENTATION
            SDL_DISPLAYEVENT_CONNECTED SDL_DISPLAYEVENT_DISCONNECTED
        ]
        ],
        SDL_DisplayOrientation => [
        qw[SDL_ORIENTATION_UNKNOWN
            SDL_ORIENTATION_LANDSCAPE SDL_ORIENTATION_LANDSCAPE_FLIPPED
            SDL_ORIENTATION_PORTRAIT  SDL_ORIENTATION_PORTRAIT_FLIPPED
        ]
        ];

    # An opaque handle to an OpenGL context.
    class SDL_GLContext => [];
    enum SDL_GLattr     => [
        qw[
            SDL_GL_RED_SIZE
            SDL_GL_GREEN_SIZE
            SDL_GL_BLUE_SIZE
            SDL_GL_ALPHA_SIZE
            SDL_GL_BUFFER_SIZE
            SDL_GL_DOUBLEBUFFER
            SDL_GL_DEPTH_SIZE
            SDL_GL_STENCIL_SIZE
            SDL_GL_ACCUM_RED_SIZE
            SDL_GL_ACCUM_GREEN_SIZE
            SDL_GL_ACCUM_BLUE_SIZE
            SDL_GL_ACCUM_ALPHA_SIZE
            SDL_GL_STEREO
            SDL_GL_MULTISAMPLEBUFFERS
            SDL_GL_MULTISAMPLESAMPLES
            SDL_GL_ACCELERATED_VISUAL
            SDL_GL_RETAINED_BACKING
            SDL_GL_CONTEXT_MAJOR_VERSION
            SDL_GL_CONTEXT_MINOR_VERSION
            SDL_GL_CONTEXT_EGL
            SDL_GL_CONTEXT_FLAGS
            SDL_GL_CONTEXT_PROFILE_MASK
            SDL_GL_SHARE_WITH_CURRENT_CONTEXT
            SDL_GL_FRAMEBUFFER_SRGB_CAPABLE
            SDL_GL_CONTEXT_RELEASE_BEHAVIOR
            SDL_GL_CONTEXT_RESET_NOTIFICATION
            SDL_GL_CONTEXT_NO_ERROR
        ]
        ],
        SDL_GLprofile => [
        [ SDL_GL_CONTEXT_PROFILE_CORE          => 0x0001 ],
        [ SDL_GL_CONTEXT_PROFILE_COMPATIBILITY => 0x0002 ],
        [ SDL_GL_CONTEXT_PROFILE_ES            => 0x0004 ]
        ],
        SDL_GLcontextFlag => [
        [ SDL_GL_CONTEXT_DEBUG_FLAG              => 0x0001 ],
        [ SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG => 0x0002 ],
        [ SDL_GL_CONTEXT_ROBUST_ACCESS_FLAG      => 0x0004 ],
        [ SDL_GL_CONTEXT_RESET_ISOLATION_FLAG    => 0x0008 ]
        ],
        SDL_GLcontextReleaseFlag => [
        [ SDL_GL_CONTEXT_RELEASE_BEHAVIOR_NONE  => 0x0000 ],
        [ SDL_GL_CONTEXT_RELEASE_BEHAVIOR_FLUSH => 0x0001 ]
        ],
        SDL_GLContextResetNotification => [
        [ SDL_GL_CONTEXT_RESET_NO_NOTIFICATION => 0x0000 ],
        [ SDL_GL_CONTEXT_RESET_LOSE_CONTEXT    => 0x0001 ]
        ];
    attach video => {
        SDL_GetNumVideoDrivers    => [ [],         'int' ],
        SDL_GetVideoDriver        => [ ['int'],    'string' ],
        SDL_VideoInit             => [ ['string'], 'int' ],
        SDL_VideoQuit             => [ [] ],
        SDL_GetCurrentVideoDriver => [ [],      'string' ],
        SDL_GetNumVideoDisplays   => [ [],      'int' ],
        SDL_GetDisplayName        => [ ['int'], 'string' ],
        SDL_GetDisplayBounds      => [
            [ 'int', 'SDL_Rect' ],
            'int' => sub ( $inner, $displayIndex ) {
                my $rect = SDL2::Rect->new();
                my $ret  = $inner->( $displayIndex, $rect );
                $ret == 0 ? $rect : $ret;
            }
        ],
        SDL_GetDisplayUsableBounds => [
            [ 'int', 'SDL_Rect' ],
            'int' => sub ( $inner, $displayIndex ) {
                my $rect = SDL2::Rect->new();
                my $ret  = $inner->( $displayIndex, $rect );
                $ret == 0 ? $rect : $ret;
            }
        ],
        SDL_GetDisplayDPI => [
            [ 'int', 'float *', 'float *', 'float *' ],
            'int' => sub ( $inner, $displayIndex ) {
                my $ret = $inner->( $displayIndex, \my ( $ddpi, $hdpi, $vdpi ) ) // 0;
                $ret == 0 ? ( $ddpi, $hdpi, $vdpi ) : $ret;
            }
        ],
        SDL_GetDisplayOrientation => [ ['int'], 'int' ],
        SDL_GetNumDisplayModes    => [ ['int'], 'int' ],
        SDL_GetDisplayMode        => [
            [ 'int', 'int', 'SDL_DisplayMode' ],
            'int' => sub ( $inner, $displayIndex, $modeIndex ) {
                my $mode = SDL2::DisplayMode->new();
                my $ret  = $inner->( $displayIndex, $modeIndex, $mode ) // 0;
                $ret == 0 ? $mode : $ret;
            }
        ],
        SDL_GetDesktopDisplayMode => [
            [ 'int', 'SDL_DisplayMode' ],
            'int' => sub ( $inner, $displayIndex ) {
                my $mode = SDL2::DisplayMode->new();
                my $ret  = $inner->( $displayIndex, $mode ) // 0;
                $ret == 0 ? $mode : $ret;
            }
        ],
        SDL_GetCurrentDisplayMode => [
            [ 'int', 'SDL_DisplayMode' ],
            'int' => sub ( $inner, $displayIndex ) {
                my $mode = SDL2::DisplayMode->new();
                my $ret  = $inner->( $displayIndex, $mode ) // 0;
                $ret == 0 ? $mode : $ret;
            }
        ],
        SDL_GetClosestDisplayMode => [ [ 'int', 'SDL_DisplayMode', 'SDL_DisplayMode' ], 'opaque' ],
        SDL_GetWindowDisplayIndex => [ ['SDL_Window'],                                  'int' ],
        SDL_SetWindowDisplayMode  => [ [ 'SDL_Window', 'SDL_DisplayMode' ],             'int' ],
        SDL_GetWindowDisplayMode  => [
            [ 'SDL_Window', 'SDL_DisplayMode' ],
            'int' => sub ( $inner, $displayIndex ) {
                my $mode = SDL2::DisplayMode->new();
                my $ret  = $inner->( $displayIndex, $mode ) // 0;
                $ret == 0 ? $mode : $ret;
            }
        ],
        SDL_GetWindowPixelFormat => [ ['SDL_Window'], 'uint32' ],
        SDL_CreateWindow => [ [ 'string', 'int', 'int', 'int', 'int', 'uint32' ] => 'SDL_Window' ],
        SDL_CreateWindowFrom => [ ['opaque']     => 'SDL_Window' ],
        SDL_GetWindowID      => [ ['SDL_Window'] => 'uint32' ],
        SDL_GetWindowFromID  => [ ['uint32']     => 'SDL_Window' ],
        SDL_GetWindowFlags   => [ ['SDL_Window'] => 'uint32' ],
        SDL_SetWindowTitle   => [ [ 'SDL_Window', 'string' ] ],
        SDL_GetWindowTitle   => [ ['SDL_Window'], 'string' ],
        SDL_SetWindowIcon    => [ [ 'SDL_Window', 'SDL_Surface' ] ],

        # These don't work correctly yet. (cast issues)
        SDL_SetWindowData     => [ [ 'SDL_Window', 'string', 'opaque*' ], 'opaque*' ],
        SDL_GetWindowData     => [ [ 'SDL_Window', 'string' ], 'opaque*' ],
        SDL_SetWindowPosition => [ [ 'SDL_Window', 'int', 'int' ] ],
        SDL_GetWindowPosition => [
            [ 'SDL_Window', 'int*', 'int*' ] => sub ( $inner, $window ) {
                my ( $x, $y );
                $inner->( $window, \$x, \$y );
                return ( $x, $y );
            }
        ],
        SDL_SetWindowSize => [ [ 'SDL_Window', 'int', 'int' ] ],
        SDL_GetWindowSize => [
            [ 'SDL_Window', 'int*', 'int*' ] => sub ( $inner, $window ) {
                my ( $x, $y );
                $inner->( $window, \$x, \$y );
                return ( $x, $y );
            }
        ],
        SDL_GetWindowBordersSize => [
            [ 'SDL_Window', 'int*', 'int*', 'int*', 'int*' ],
            'int' => sub ( $inner, $window ) {
                my ( $top, $left, $bottom, $right );
                my $ret = $inner->( $window, \$top, \$left, \$bottom, \$right );
                return $ret == 0 ? ( $top, $left, $bottom, $right ) : $ret;
            }
        ],
        SDL_SetWindowMinimumSize => [ [ 'SDL_Window', 'int', 'int' ] ],
        SDL_GetWindowMinimumSize => [
            [ 'SDL_Window', 'int*', 'int*' ] => sub ( $inner, $window ) {
                my ( $x, $y );
                $inner->( $window, \$x, \$y );
                return ( $x, $y );
            }
        ],
        SDL_SetWindowMaximumSize => [ [ 'SDL_Window', 'int', 'int' ] ],
        SDL_GetWindowMaximumSize => [
            [ 'SDL_Window', 'int*', 'int*' ] => sub ( $inner, $window ) {
                my ( $x, $y );
                $inner->( $window, \$x, \$y );
                return ( $x, $y );
            }
        ],
        SDL_SetWindowBordered        => [ [ 'SDL_Window', 'bool' ] ],
        SDL_SetWindowResizable       => [ [ 'SDL_Window', 'bool' ] ],
        SDL_ShowWindow               => [ ['SDL_Window'] ],
        SDL_HideWindow               => [ ['SDL_Window'] ],
        SDL_RaiseWindow              => [ ['SDL_Window'] ],
        SDL_MaximizeWindow           => [ ['SDL_Window'] ],
        SDL_MinimizeWindow           => [ ['SDL_Window'] ],
        SDL_RestoreWindow            => [ ['SDL_Window'] ],
        SDL_SetWindowFullscreen      => [ [ 'SDL_Window', 'uint32' ], 'int' ],
        SDL_GetWindowSurface         => [ ['SDL_Window'],             'SDL_Surface' ],
        SDL_UpdateWindowSurface      => [ ['SDL_Window'],             'int' ],
        SDL_UpdateWindowSurfaceRects => [
            [ 'SDL_Window', 'opaque*', 'int' ],
            'int' => sub ( $inner, $window, @recs ) {
                $inner->( $window, \\@recs, scalar @recs );
            }
        ],
        SDL_SetWindowGrab => [ [ 'SDL_Window', 'bool' ] ],
        ( $ver->patch >= 15 ? ( SDL_SetWindowKeyboardGrab => [ [ 'SDL_Window', 'bool' ] ] ) : () ),
        ( $ver->patch >= 15 ? ( SDL_SetWindowMouseGrab    => [ [ 'SDL_Window', 'bool' ] ] ) : () ),
        SDL_GetWindowGrab => [ ['SDL_Window'], 'bool' ],
        ( $ver->patch >= 15 ? ( SDL_GetWindowKeyboardGrab => [ ['SDL_Window'], 'bool' ] ) : () ),
        ( $ver->patch >= 15 ? ( SDL_GetWindowMouseGrab    => [ ['SDL_Window'], 'bool' ] ) : () ),
        SDL_GetGrabbedWindow    => [ [],                        'SDL_Window' ],
        SDL_SetWindowBrightness => [ [ 'SDL_Window', 'float' ], 'int' ],
        SDL_GetWindowBrightness => [ ['SDL_Window'],            'float' ],
        SDL_SetWindowOpacity    => [ [ 'SDL_Window', 'float' ], 'int' ],
        SDL_GetWindowOpacity    => [
            [ 'SDL_Window', 'float*' ],
            'int' => sub ( $inner, $window ) {
                my $out_opacity;
                my $ok = $inner->( $window, \$out_opacity );
                $ok == 0 ? $out_opacity : $ok;
            }
        ],
        SDL_SetWindowModalFor   => [ [ 'SDL_Window', 'SDL_Window' ], 'int' ],
        SDL_SetWindowInputFocus => [ ['SDL_Window'],                 'int' ],
        SDL_SetWindowGammaRamp  =>
            [ [ 'SDL_Window', 'uint32[256]', 'uint32[256]', 'uint32[256]' ], 'int' ],
        SDL_GetWindowGammaRamp => [
            [ 'SDL_Window', 'uint32[256]', 'uint32[256]', 'uint32[256]' ],
            'int' => sub ( $inner, $window ) {
                my @red = my @blue = my @green = map { \0 } 1 .. 256;
                my $ok  = $inner->( $window, \@red, \@green, \@blue );
                $ok == 0 ? ( \@red, \@green, \@blue ) : $ok;
            }
        ],
        SDL_SetWindowHitTest => [
            [ 'SDL_Window', 'SDL_HitTest', 'opaque' ],
            'int' => sub ( $xsub, $window, $callback, $callback_data = () ) {    # Fake void pointer
                my $cb = $callback;
                if ( defined $callback ) {
                    $cb = FFI::Platypus::Closure->new(
                        sub ( $win, $area, $data ) {
                            $callback->(
                                $ffi->cast( 'opaque' => 'SDL_Window', $win ),
                                $ffi->cast( 'opaque' => 'SDL_Point',  $area ),
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
        SDL_GL_SetAttribute       => [ [ 'SDL_GLattr', 'int' ], 'int' ],
        SDL_GL_GetAttribute       => [
            [ 'SDL_GLattr', 'int*' ],
            'int' => sub ( $inner, $attr ) {
                my $value;
                my $ok = $inner->( $attr, \$value );
                $ok == 0 ? $value : $ok;
            }
        ],
        SDL_GL_CreateContext     => [ ['SDL_Window'],                    'SDL_GLContext' ],
        SDL_GL_MakeCurrent       => [ [ 'SDL_Window', 'SDL_GLContext' ], 'int' ],
        SDL_GL_GetCurrentWindow  => [ [],                                'SDL_Window' ],
        SDL_GL_GetCurrentContext => [ [],                                'SDL_GLContext' ],
        SDL_GL_GetDrawableSize   => [
            [ 'SDL_Window', 'int*', 'int*' ],
            sub ( $inner, $window ) {
                my ( $w, $h );
                $inner->( $window, \$w, \$h );
                ( $w, $h );
            }
        ],
        SDL_GL_SetSwapInterval => [ ['int'], 'int' ],
        SDL_GL_GetSwapInterval => [ [],      'int' ],
        SDL_GL_SwapWindow      => [ ['SDL_Window'] ],
        SDL_GL_DeleteContext   => [ ['SDL_GLContext'] ]
        };
    enum SDL_RendererFlags => [
        [ SDL_RENDERER_SOFTWARE      => 0x00000001 ],
        [ SDL_RENDERER_ACCELERATED   => 0x00000002 ],
        [ SDL_RENDERER_PRESENTVSYNC  => 0x00000004 ],
        [ SDL_RENDERER_TARGETTEXTURE => 0x00000008 ]
    ];
    class SDL_RendererInfo => [
        name                => 'opaque',       # string
        flags               => 'uint32',
        num_texture_formats => 'uint32',
        texture_formats     => 'uint32[16]',
        max_texture_width   => 'int',
        max_texture_height  => 'int'
    ];
    enum
        SDL_ScaleMode     => [qw[SDL_SCALEMODENEAREST SDL_SCALEMODELINEAR SDL_SCALEMODEBEST]],
        SDL_TextureAccess =>
        [qw[SDL_TEXTUREACCESS_STATIC SDL_TEXTUREACCESS_STREAMING SDL_TEXTUREACCESS_TARGET]],
        SDL_TextureModulate => [
        [ SDL_TEXTUREMODULATE_NONE  => 0x00000000 ],
        [ SDL_TEXTUREMODULATE_COLOR => 0x00000001 ],
        [ SDL_TEXTUREMODULATE_ALPHA => 0x00000002 ]
        ],
        SDL_RendererFlip => [
        [ SDL_FLIP_NONE       => 0x00000000 ],
        [ SDL_FLIP_HORIZONTAL => 0x00000001 ],
        [ SDL_FLIP_VERTICAL   => 0x00000002 ]
        ],
        SDL_BlendMode => [
        [ SDL_BLENDMODE_NONE    => 0x00000000 ],
        [ SDL_BLENDMODE_BLEND   => 0x00000001 ],
        [ SDL_BLENDMODE_ADD     => 0x00000002, ],
        [ SDL_BLENDMODE_MOD     => 0x00000004, ],
        [ SDL_BLENDMODE_MUL     => 0x00000008, ],
        [ SDL_BLENDMODE_INVALID => 0x7FFFFFFF ]
        ],
        SDL_BlendOperation => [
        [ SDL_BLENDOPERATION_ADD          => 0x1 ],
        [ SDL_BLENDOPERATION_SUBTRACT     => 0x2 ],
        [ SDL_BLENDOPERATION_REV_SUBTRACT => 0x3 ],
        [ SDL_BLENDOPERATION_MINIMUM      => 0x4 ],
        [ SDL_BLENDOPERATION_MAXIMUM      => 0x5 ]
        ],
        SDL_BlendFactor => [
        [ SDL_BLENDFACTOR_ZERO                => 0x1 ],
        [ SDL_BLENDFACTOR_ONE                 => 0x2 ],
        [ SDL_BLENDFACTOR_SRC_COLOR           => 0x3 ],
        [ SDL_BLENDFACTOR_ONE_MINUS_SRC_COLOR => 0x4 ],
        [ SDL_BLENDFACTOR_SRC_ALPHA           => 0x5 ],
        [ SDL_BLENDFACTOR_ONE_MINUS_SRC_ALPHA => 0x6 ],
        [ SDL_BLENDFACTOR_DST_COLOR           => 0x7 ],
        [ SDL_BLENDFACTOR_ONE_MINUS_DST_COLOR => 0x8 ],
        [ SDL_BLENDFACTOR_DST_ALPHA           => 0x9 ],
        [ SDL_BLENDFACTOR_ONE_MINUS_DST_ALPHA => 0xA ]
        ];
    class
        SDL_Renderer => [],
        SDL_Texture  => [];
    attach render => {
        SDL_GetNumRenderDrivers => [ [], 'int' ],
        SDL_GetRenderDriverInfo => [
            [ 'int', 'SDL_RendererInfo' ],
            'int',
            sub ( $inner, $index ) {
                my $info = SDL2::RendererInfo->new();
                my $ok   = $inner->( $index, $info );
                $ok == 0 ? $info : $ok;
            }
        ],
        SDL_CreateWindowAndRenderer => [
            [ 'int', 'int', 'uint32', 'opaque*', 'opaque*' ],
            'int' => sub ( $inner, $width, $height, $window_flags ) {
                my $window   = SDL2::Window->new;
                my $renderer = SDL2::Renderer->new;
                my $ok       = $inner->( $width, $height, $window_flags, \$window, \$renderer );
                $ok == 0 ? (
                    $ffi->cast( 'opaque' => 'SDL_Window',   $window ),
                    $ffi->cast( 'opaque' => 'SDL_Renderer', $renderer ),
                    ) :
                    $ok;
            }
        ],
        SDL_CreateRenderer         => [ [ 'SDL_Window', 'int', 'uint32' ], 'SDL_Renderer' ],
        SDL_CreateSoftwareRenderer => [ ['SDL_Renderer'],                  'SDL_Surface' ],
        SDL_GetRenderer            => [ ['SDL_Window'],                    'SDL_Renderer' ],
        SDL_GetRendererInfo        => [
            [ 'SDL_Renderer', 'SDL_RendererInfo' ],
            'int' => sub ( $inner, $renderer ) {
                my $info = SDL2::RendererInfo->new();
                my $ok   = $inner->( $renderer, $info );
                $ok == 0 ? $info : $ok;
            }
        ],
        SDL_GetRendererOutputSize => [
            [ 'SDL_Renderer', 'int*', 'int*' ],
            'int' => sub ( $inner, $renderer ) {
                my ( $w, $h );
                my $ok = $inner->( $renderer, \$w, \$h );
                $ok == 0 ? ( $w, $h ) : $ok;
            }
        ],
        SDL_CreateTexture => [ [ 'SDL_Renderer', 'uint32', 'int', 'int', 'int' ], 'SDL_Texture' ],
        SDL_CreateTextureFromSurface => [ [ 'SDL_Renderer', 'SDL_Surface' ], 'SDL_Texture' ],
        SDL_QueryTexture             => [
            [ 'SDL_Texture', 'uint32*', 'int*', 'int*', 'int*' ],
            'int' => sub ( $inner, $texture ) {
                my ( $format, $access, $w, $h );
                my $ok = $inner->( $texture, \$format, \$access, \$w, \$h );
                $ok == 0 ? ( $format, $access, $w, $h ) : $ok;
            }
        ],
        SDL_SetTextureColorMod => [ [ 'SDL_Texture', 'uint8', 'uint8', 'uint8' ], 'int' ],
        SDL_GetTextureColorMod => [
            [ 'SDL_Texture', 'uint8*', 'uint8*', 'uint8*' ],
            'int' => sub ( $inner, $texture ) {
                my ( $r, $g, $b );
                my $ok = $inner->( $texture, \$r, \$g, \$b );
                $ok == 0 ? ( $r, $g, $b ) : $ok;
            }
        ],
        SDL_SetTextureAlphaMod => [ [ 'SDL_Texture', 'uint8' ], 'int' ],
        SDL_GetTextureAlphaMod => [
            [ 'SDL_Texture', 'uint8*' ],
            'int' => sub ( $inner, $texture ) {
                my $alpha;
                my $ok = $inner->( $texture, \$alpha );
                $ok == 0 ? $alpha : $ok;
            }
        ],
        SDL_SetTextureBlendMode => [ [ 'SDL_Texture', 'SDL_BlendMode' ], 'int' ],
        SDL_GetTextureBlendMode => [
            [ 'SDL_Texture', 'int*' ],
            'int' => sub ( $inner, $texture ) {
                my $blendMode;
                my $ok = $inner->( $texture, \$blendMode );
                $ok == 0 ? $blendMode : $ok;
            }
        ],
        SDL_UpdateTexture    => [ [ 'SDL_Texture', 'SDL_Rect', 'opaque*', 'int' ], 'int' ],
        SDL_UpdateYUVTexture => [
            [ 'SDL_Texture', 'SDL_Rect', 'uint8*', 'int', 'uint8*', 'int', 'uint8*', 'int' ], 'int'
        ], (
            $ver->patch >= 15 ?
                ( SDL_UpdateNVTexture =>
                    [ [ 'SDL_Texture', 'SDL_Rect', 'uint8*', 'int', 'uint8*', 'int' ], 'int' ] ) :
                ()
        ),
        SDL_LockTexture          => [ [ 'SDL_Texture', 'SDL_Rect', 'opaque*' ], 'int' ],
        SDL_LockTextureToSurface => [
            [ 'SDL_Texture', 'SDL_Rect', 'SDL_Surface' ],
            'int' => sub ( $inner, $texture, $rect ) {
                my $surface = SDL2::Surface->new();
                my $ok      = $inner->( $texture, $rect, $surface );
                $ok == 0 ? $surface : $ok;
            }
        ],
        SDL_UnlockTexture         => [ ['SDL_Texture'] ],
        SDL_RenderTargetSupported => [ ['SDL_Renderer'],                  'bool' ],
        SDL_SetRenderTarget       => [ [ 'SDL_Renderer', 'SDL_Texture' ], 'int' ],
        SDL_GetRenderTarget       => [ ['SDL_Renderer'],                  'SDL_Texture' ],
        SDL_RenderSetLogicalSize  => [ [ 'SDL_Renderer', 'int', 'int' ],  'int' ],
        SDL_RenderGetLogicalSize  => [
            [ 'SDL_Renderer', 'int*', 'int*' ],
            'int' => sub ( $inner, $renderer ) {
                my ( $w, $h );
                $inner->( $renderer, \$w, \$h );
                ( $w, $h );
            }
        ],
        SDL_RenderSetIntegerScale => [ [ 'SDL_Renderer', 'bool' ],     'int' ],
        SDL_RenderGetIntegerScale => [ ['SDL_Renderer'],               'bool' ],
        SDL_RenderSetViewport     => [ [ 'SDL_Renderer', 'SDL_Rect' ], 'int' ],
        SDL_RenderGetViewport     => [
            [ 'SDL_Renderer', 'SDL_Rect' ],
            'int' => sub ( $inner, $renderer ) {
                my $rect = SDL2::Rect->new();
                $inner->( $renderer, $rect );
                $rect;
            }
        ],
        SDL_RenderSetClipRect => [ [ 'SDL_Renderer', 'SDL_Rect' ], 'int' ],
        SDL_RenderGetClipRect => [
            [ 'SDL_Renderer', 'SDL_Rect' ] => sub ( $inner, $renderer ) {
                my $rect = SDL2::Rect->new();
                $inner->( $renderer, $rect );
                $rect;
            }
        ],
        SDL_RenderIsClipEnabled => [ ['SDL_Renderer'],                     'bool' ],
        SDL_RenderSetScale      => [ [ 'SDL_Renderer', 'float', 'float' ], 'int' ],
        SDL_RenderGetScale      => [
            [ 'SDL_Renderer', 'float*', 'float*' ],
            sub ( $inner, $renderer ) {
                my ( $scaleX, $scaleY );
                $inner->( $renderer, \$scaleX, \$scaleY );
                ( $scaleX, $scaleY );
            }
        ],
        SDL_SetRenderDrawColor => [ [ 'SDL_Renderer', 'uint8', 'uint8', 'uint8', 'uint8' ], 'int' ],
        SDL_GetRenderDrawColor => [
            [ 'SDL_Renderer', 'uint8*', 'uint8*', 'uint8*', 'uint8*' ],
            'int' => sub ( $inner, $renderer ) {
                my ( $r, $g, $b, $a );
                my $ok = $inner->( $renderer, \$r, \$g, \$b, \$a );
                $ok == 0 ? ( $r, $g, $b, $a ) : $ok;
            }
        ],
        SDL_SetRenderDrawBlendMode => [ [ 'SDL_Renderer', 'SDL_BlendMode' ], 'int' ],
        SDL_GetRenderDrawBlendMode => [
            [ 'SDL_Renderer', 'int*' ],
            'int' => sub ( $inner, $renderer ) {
                my $blendMode;
                my $ok = $inner->( $renderer, \$blendMode );
                $ok == 0 ? $blendMode : $ok;
            }
        ],
        SDL_RenderClear      => [ ['SDL_Renderer'],                 'int' ],
        SDL_RenderDrawPoint  => [ [ 'SDL_Renderer', 'int', 'int' ], 'int' ],
        SDL_RenderDrawPoints => [
            [ 'SDL_Renderer', 'SDLx_PointList', 'int' ],
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
            [ 'SDL_Renderer', 'SDLx_PointList', 'int' ],
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
            [ 'SDL_Renderer', 'SDLx_RectList', 'int' ],
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
            [ 'SDL_Renderer', 'SDLx_RectList', 'int' ],
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
            [ 'SDL_Renderer', 'SDLx_FPointList', 'int' ],
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
            [ 'SDL_Renderer', 'SDLx_FPointList', 'int' ],
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
            [ 'SDL_Renderer', 'SDLx_FRectList', 'int' ],
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
            [ 'SDL_Renderer', 'SDLx_FRectList', 'int' ],
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
            [ 'SDL_Renderer', 'SDLx_FRectList', 'int' ],
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
        SDL_RenderPresent   => [ ['SDL_Renderer'] ],
        SDL_DestroyTexture  => [ ['SDL_Texture'] ],
        SDL_DestroyRenderer => [ ['SDL_Renderer'] ],
        SDL_RenderFlush     => [ ['SDL_Renderer'], 'int' ],
        SDL_GL_BindTexture  => [
            [ 'SDL_Texture', 'float*', 'float*' ],
            'int' => sub ( $inner, $texture ) {
                my ( $texw, $texh );
                my $ok = $inner->( $texture, \$texw, \$texh );
                $ok == 0 ? ( $texw, $texh ) : $ok;
            }
        ],
        SDL_GL_UnbindTexture             => [ ['SDL_Texture'],  'int' ],
        SDL_RenderGetMetalLayer          => [ ['SDL_Renderer'], 'opaque' ],
        SDL_RenderGetMetalCommandEncoder => [ ['SDL_Renderer'], 'opaque' ]
    };
    $ffi->type( '(int,opaque)->uint32' => 'SDL_TimerCallback' );
    attach timer => {
        SDL_GetTicks                => [ [], 'uint32' ],
        SDL_GetPerformanceCounter   => [ [], 'uint64' ],
        SDL_GetPerformanceFrequency => [ [], 'uint64' ],
        SDL_Delay                   => [ ['uint32'] ],
        SDL_AddTimer                => [
            [ 'uint32', 'SDL_TimerCallback', 'opaque' ],
            'int' => sub ( $xsub, $interval, $callback, $param = () ) {

                # Fake void pointer
                my $cb = FFI::Platypus::Closure->new( sub { $callback->(@_); } );
                $cb->sticky;
                $xsub->( $interval, $cb, $param );
            }
        ],
        SDL_RemoveTimer => [ ['uint32'] => 'bool' ],
    };
    define audio => [
        [ SDL_AUDIO_MASK_BITSIZE   => 0xFF ],
        [ SDL_AUDIO_MASK_DATATYPE  => ( 1 << 8 ) ],
        [ SDL_AUDIO_MASK_ENDIAN    => ( 1 << 12 ) ],
        [ SDL_AUDIO_MASK_SIGNED    => ( 1 << 15 ) ],
        [ SDL_AUDIO_BITSIZE        => sub ($x) { $x & SDL_AUDIO_MASK_BITSIZE() } ],
        [ SDL_AUDIO_ISFLOAT        => sub ($x) { $x & SDL_AUDIO_MASK_DATATYPE() } ],
        [ SDL_AUDIO_ISBIGENDIAN    => sub ($x) { $x & SDL_AUDIO_MASK_ENDIAN() } ],
        [ SDL_AUDIO_ISSIGNED       => sub ($x) { $x & SDL_AUDIO_MASK_SIGNED() } ],
        [ SDL_AUDIO_ISINT          => sub ($x) { !SDL_AUDIO_ISFLOAT($x) } ],
        [ SDL_AUDIO_ISLITTLEENDIAN => sub ($x) { !SDL_AUDIO_ISBIGENDIAN($x) } ],
        [ SDL_AUDIO_ISUNSIGNED     => sub ($x) { !SDL_AUDIO_ISSIGNED($x) } ],
        [ AUDIO_U8                 => 0x0008 ],
        [ AUDIO_S8                 => 0x8008 ],
        [ AUDIO_U16LSB             => 0x0010 ],
        [ AUDIO_S16LSB             => 0x8010 ],
        [ AUDIO_U16MSB             => 0x1010 ],
        [ AUDIO_S16MSB             => 0x9010 ],
        [ AUDIO_U16                => sub () { AUDIO_U16LSB() } ],
        [ AUDIO_S16                => sub () { AUDIO_S16LSB() } ],
        [ AUDIO_S32LSB             => 0x8020 ],
        [ AUDIO_S32MSB             => 0x9020 ],
        [ AUDIO_S32                => sub () { AUDIO_S32LSB() } ],
        [ AUDIO_F32LSB             => 0x8120 ],
        [ AUDIO_F32MSB             => 0x9120 ],
        [ AUDIO_F32                => sub () { AUDIO_F32LSB() } ], (
            $bigendian ? (
                [ AUDIO_U16SYS => sub () { AUDIO_U16MSB() } ],
                [ AUDIO_S16SYS => sub () { AUDIO_S16MSB() } ],
                [ AUDIO_S32SYS => sub () { AUDIO_S32MSB() } ],
                [ AUDIO_F32SYS => sub () { AUDIO_F32MSB() } ]
                ) : (
                [ AUDIO_U16SYS => sub () { AUDIO_U16LSB() } ],
                [ AUDIO_S16SYS => sub () { AUDIO_S16LSB() } ],
                [ AUDIO_S32SYS => sub () { AUDIO_S32LSB() } ],
                [ AUDIO_F32SYS => sub () { AUDIO_F32LSB() } ],
                )
        ),
        [ SDL_AUDIO_ALLOW_FREQUENCY_CHANGE => sub () {0x00000001} ],
        [ SDL_AUDIO_ALLOW_FORMAT_CHANGE    => sub () {0x00000002} ],
        [ SDL_AUDIO_ALLOW_CHANNELS_CHANGE  => sub () {0x00000004} ],
        [ SDL_AUDIO_ALLOW_SAMPLES_CHANGE   => sub () {0x00000008} ],
        [   SDL_AUDIO_ALLOW_ANY_CHANGE => sub () {
                ( SDL_AUDIO_ALLOW_FREQUENCY_CHANGE() | SDL_AUDIO_ALLOW_FORMAT_CHANGE()
                        | SDL_AUDIO_ALLOW_CHANNELS_CHANGE() | SDL_AUDIO_ALLOW_SAMPLES_CHANGE() )
            }
        ],
    ];
    $ffi->type( '(opaque,string,int)->void' => 'SDL_AudioCallback' );
    class SDL_AudioSpec => [
        freq     => 'int',
        format   => 'uint16',
        channels => 'uint8',
        silence  => 'uint8',
        samples  => 'uint16',
        padding  => 'uint16',
        size     => 'uint32',
        callback => 'opaque',    # SDL_AudioCallback
        userdata => 'opaque'     # void *
    ];
    class SDL_AudioCVT => [
        needed       => 'int',
        src_format   => 'uint16',    # SDL_AudioFormat
        dst_format   => 'uint16',    # SDL_AudioFormat
        rate_incr    => 'double',
        buf          => 'opaque',    # uint8 *
        len          => 'int',
        len_cvt      => 'int',
        len_mult     => 'int',
        len_ratio    => 'double',
        filters      => 'opaque',    #SDL_AudioFilter[SDL_AUDIOCVT_MAX_FILTERS + 1];
        filter_index => 'int'
    ];
    $ffi->type( '(opaque,uint16)->void' => 'SDL_AudioFilter' );
    define audio => [ [ SDL_AUDIOCVT_MAX_FILTERS => 9 ], ];
    attach audio => {
        SDL_GetNumAudioDrivers    => [ [],         'int' ],
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

                #my $obtained = SDL2::AudioSpec->new();
                my $ok = $inner->( $desired, $obtained );
                $ok == 0 ? $obtained : $ok;
            }
        ],
        SDL_GetNumAudioDevices => [ ['int'], 'int' ],
    };

    # START HERE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    # https://wiki.libsdl.org/CategoryPlatform
    #
    class SDL_RWops => [];

    #class SDL_PixelFormat => [];
    $ffi->attach( SDL_RWFromFile  => [ 'string', 'string' ], 'SDL_RWops' );
    $ffi->attach( SDL_FreeSurface => ['SDL_Surface'] );
    $ffi->attach( SDL_SaveBMP_RW  => [ 'SDL_Surface', 'SDL_RWops', 'int' ], 'int' );
    attach future => {
        SDL_ComposeCustomBlendMode => [
            [   'SDL_BlendFactor',    'SDL_BlendFactor',
                'SDL_BlendOperation', 'SDL_BlendFactor',
                'SDL_BlendFactor',    'SDL_BlendOperation'
            ],
            'SDL_BlendMode'
        ],
    };

    sub SDL_SaveBMP ( $surface, $file ) {
        SDL_SaveBMP_RW( $surface, SDL_RWFromFile( $file, 'wb' ), 1 );
    }
    $ffi->attach( SDL_GetPlatform => [] => 'string' );
    $ffi->attach( SDL_CreateRGBSurface =>
            [ 'uint32', 'int', 'int', 'int', 'uint32', 'uint32', 'uint32', 'uint32' ] =>
            'SDL_Surface' );

    # https://wiki.libsdl.org/CategoryCPU
    $ffi->attach( SDL_GetCPUCacheLineSize => [] => 'int' );
    $ffi->attach( SDL_GetCPUCount         => [] => 'int' );
    $ffi->attach( SDL_GetSystemRAM        => [] => 'int' );
    $ffi->attach( SDL_Has3DNow            => [] => 'bool' );
    $ffi->attach( SDL_HasAVX              => [] => 'bool' );
    $ffi->attach( SDL_HasAVX2             => [] => 'bool' );
    $ffi->attach( SDL_HasAltiVec          => [] => 'bool' );
    $ffi->attach( SDL_HasMMX              => [] => 'bool' );
    $ffi->attach( SDL_HasRDTSC            => [] => 'bool' );
    $ffi->attach( SDL_HasSSE              => [] => 'bool' );
    $ffi->attach( SDL_HasSSE2             => [] => 'bool' );
    $ffi->attach( SDL_HasSSE3             => [] => 'bool' );
    $ffi->attach( SDL_HasSSE41            => [] => 'bool' );
    $ffi->attach( SDL_HasSSE42            => [] => 'bool' );

    # https://wiki.libsdl.org/CategoryPower
    FFI::C->enum(
        'SDL_PowerState',
        [   qw[
                SDL_POWERSTATE_UNKNOWN
                SDL_POWERSTATE_ON_BATTERY SDL_POWERSTATE_NO_BATTERY
                SDL_POWERSTATE_CHARGING   SDL_POWERSTATE_CHARGED]
        ]
    );
    $ffi->attach( SDL_GetPowerInfo => [ 'int*', 'int*' ] => 'int' );

    # https://wiki.libsdl.org/CategoryStandard
    $ffi->attach( SDL_acos => ['double'] => 'double' );
    $ffi->attach( SDL_asin => ['double'] => 'double' );    # Not in wiki

    # https://wiki.libsdl.org/CategoryVideo
    # Macros defined in SDL_video.h
    sub SDL_WINDOWPOS_UNDEFINED_MASK ()      {0x1FFF0000}
    sub SDL_WINDOWPOS_UNDEFINED_DISPLAY ($X) { ( SDL_WINDOWPOS_UNDEFINED_MASK | ($X) ) }
    sub SDL_WINDOWPOS_UNDEFINED ()           { SDL_WINDOWPOS_UNDEFINED_DISPLAY(0) }
    sub SDL_WINDOWPOS_ISUNDEFINED ($X) { ( ( ($X) & 0xFFFF0000 ) == SDL_WINDOWPOS_UNDEFINED_MASK ) }
    #
    sub SDL_WINDOWPOS_CENTERED_MASK ()      {0x2FFF0000}
    sub SDL_WINDOWPOS_CENTERED_DISPLAY ($X) { ( SDL_WINDOWPOS_CENTERED_MASK | ($X) ) }
    sub SDL_WINDOWPOS_CENTERED ()           { SDL_WINDOWPOS_CENTERED_DISPLAY(0) }
    sub SDL_WINDOWPOS_ISCENTERED ($X) { ( ( ($X) & 0xFFFF0000 ) == SDL_WINDOWPOS_CENTERED_MASK ) }

    # https://wiki.libsdl.org/CategoryPixels
    FFI::C::StructDef->new(
        $ffi,
        name    => 'SDL_Color',
        class   => 'SDL2::Color',
        members => [ r => 'uint8', g => 'uint8', b => 'uint8', a => 'uint8' ]
    );
    FFI::C::StructDef->new(
        $ffi,
        name    => 'SDL_Palette',
        class   => 'SDL2::Palette',
        members => [ ncolors => 'int', colors => 'SDL_Color' ]
    );
    FFI::C::StructDef->new(
        $ffi,
        name    => 'SDL_PixelFormat',
        class   => 'SDL2::PixelFormat',
        members => [
            format        => 'uint32',
            palette       => 'SDL_Palette',
            BitsPerPixel  => 'uint8',
            BytesPerPixel => 'uint8',
            padding       => 'uint32[2]',
            Rmask         => 'uint32',
            Gmask         => 'uint32',
            Bmask         => 'uint32',
            Amask         => 'uint32',
            Rloss         => 'uint8',
            Gloss         => 'uint8',
            Bloss         => 'uint8',
            Aloss         => 'uint8',
            Rshift        => 'uint8',
            Gshift        => 'uint8',
            Bshift        => 'uint8',
            Ashift        => 'uint8',
            refcount      => 'int',
            next          => 'opaque'         # SDL_PixelFormat *
        ]
    );
    attach future => {
        SDL_FillRect => [ [ 'SDL_Surface', 'opaque', 'uint32' ], 'int' ],
        SDL_MapRGB   => [
            [ 'SDL_PixelFormat', 'uint8', 'uint8', 'uint8' ] => 'uint32' =>
                sub ( $inner, $format, $r, $g, $b ) {
                $format = $ffi->cast( 'opaque', 'SDL_PixelFormat', $format ) if !ref $format;
                $inner->( $format, $r, $g, $b );
            }
        ]
    };

    # https://wiki.libsdl.org/CategoryEvents
    sub SDL_RELEASED () {0}
    sub SDL_PRESSED()   {1}

    # SDL_EventType
    sub SDL_FIRSTEVENT () {0}    #     /**< Unused (do not remove) */

    #
    sub SDL_QUIT ()                   {0x100}              # /**< User-requested quit */
    sub SDL_APP_TERMINATING ()        { SDL_QUIT() + 1 }
    sub SDL_APP_LOWMEMORY ()          { SDL_QUIT() + 2 }
    sub SDL_APP_WILLENTERBACKGROUND() { SDL_QUIT() + 3 }
    sub SDL_APP_DIDENTERBACKGROUND () { SDL_QUIT() + 4 }
    sub SDL_APP_WILLENTERFOREGROUND() { SDL_QUIT() + 5 }
    sub SDL_APP_DIDENTERFOREGROUND()  { SDL_QUIT() + 6 }
    #
    sub SDL_DISPLAYEVENT () {0x150}
    #
    sub SDL_WINDOWEVENT () {0x200}
    sub SDL_SYSWMEVENT ()  { SDL_WINDOWEVENT() + 1 }
    #
    sub SDL_KEYDOWN ()       {0x300}
    sub SDL_KEYUP ()         { SDL_KEYDOWN() + 1 }
    sub SDL_TEXTEDITING ()   { SDL_KEYDOWN() + 2 }
    sub SDL_TEXTINPUT ()     { SDL_KEYDOWN() + 3 }
    sub SDL_KEYMAPCHANGED () { SDL_KEYDOWN() + 4 }
    #
    sub SDL_MOUSEMOTION ()    {0x400}
    sub SDL_MOUSEBUTTONDOWN() { SDL_MOUSEMOTION() + 1 }
    sub SDL_MOUSEBUTTONUP()   { SDL_MOUSEMOTION() + 2 }
    sub SDL_MOUSEWHEEL()      { SDL_MOUSEMOTION() + 3 }
    #
    sub SDL_JOYAXISMOTION ()   {0x600}
    sub SDL_JOYBALLMOTION()    { SDL_JOYAXISMOTION() + 1 }
    sub SDL_JOYHATMOTION()     { SDL_JOYAXISMOTION() + 2 }
    sub SDL_JOYBUTTONDOWN()    { SDL_JOYAXISMOTION() + 3 }
    sub SDL_JOYBUTTONUP()      { SDL_JOYAXISMOTION() + 4 }
    sub SDL_JOYDEVICEADDED()   { SDL_JOYAXISMOTION() + 5 }
    sub SDL_JOYDEVICEREMOVED() { SDL_JOYAXISMOTION() + 6 }
    #
    sub SDL_CONTROLLERAXISMOTION ()    {0x650}
    sub SDL_CONTROLLERBUTTONDOWN()     { SDL_CONTROLLERAXISMOTION() + 1 }
    sub SDL_CONTROLLERBUTTONUP()       { SDL_CONTROLLERAXISMOTION() + 2 }
    sub SDL_CONTROLLERDEVICEADDED()    { SDL_CONTROLLERAXISMOTION() + 3 }
    sub SDL_CONTROLLERDEVICEREMOVED()  { SDL_CONTROLLERAXISMOTION() + 4 }
    sub SDL_CONTROLLERDEVICEREMAPPED() { SDL_CONTROLLERAXISMOTION() + 5 }
    #
    sub SDL_FINGERDOWN ()  {0x700}
    sub SDL_FINGERUP()     { SDL_FINGERDOWN() + 1 }
    sub SDL_FINGERMOTION() { SDL_FINGERDOWN() + 2 }
    #
    sub SDL_DOLLARGESTURE () {0x800}
    sub SDL_DOLLARRECORD()   { SDL_DOLLARGESTURE() + 1 }
    sub SDL_MULTIGESTURE()   { SDL_DOLLARGESTURE() + 2 }
    #
    sub SDL_CLIPBOARDUPDATE () {0x900}
    #
    sub SDL_DROPFILE ()    {0x1000}
    sub SDL_DROPTEXT()     { SDL_DROPFILE() + 1 }
    sub SDL_DROPBEGIN()    { SDL_DROPFILE() + 2 }
    sub SDL_DROPCOMPLETE() { SDL_DROPFILE() + 3 }
    #
    sub SDL_AUDIODEVICEADDED ()  {0x1100}
    sub SDL_AUDIODEVICEREMOVED() { SDL_AUDIODEVICEADDED() + 1 }
    #
    sub SDL_SENSORUPDATE () {0x1200}
    #
    sub SDL_RENDER_TARGETS_RESET () {0x2000}
    sub SDL_RENDER_DEVICE_RESET()   { SDL_RENDER_TARGETS_RESET() + 1 }
    #
    sub SDL_USEREVENT () {0x8000}
    #
    sub SDL_LASTEVENT () {0xFFFF}
    #
    FFI::C::StructDef->new(
        $ffi,
        name    => 'SDL_CommonEvent',
        class   => 'SDL2::CommonEvent',
        members => [ type => 'uint32', timestamp => 'uint32' ]
    );
    FFI::C::StructDef->new(
        $ffi,
        name    => 'SDL_DisplayEvent',
        class   => 'SDL2::DisplayEvent',
        members => [
            type      => 'uint32',
            timestamp => 'uint32',
            display   => 'uint32',
            event     => 'uint8',
            padding1  => 'uint8',
            padding2  => 'uint8',
            padding3  => 'uint8',
            data1     => 'sint32'
        ]
    );
    FFI::C::StructDef->new(
        $ffi,
        name    => 'SDL_WindowEvent',
        class   => 'SDL2::WindowEvent',
        members => [
            type      => 'uint32',
            timestamp => 'uint32',
            windowId  => 'uint32',
            event     => 'uint8',
            padding1  => 'uint8',
            padding2  => 'uint8',
            padding3  => 'uint8',
            data1     => 'sint32',
            data2     => 'sint32'
        ]
    );
    FFI::C::StructDef->new(
        $ffi,
        name    => 'SDL_KeyboardEvent',
        class   => 'SDL2::KeyboardEvent',
        members => [
            type      => 'uint32',
            timestamp => 'uint32',
            windowId  => 'uint32',
            state     => 'uint8',
            repeat    => 'uint8',
            padding2  => 'uint8',
            padding3  => 'uint8',
            keysym    => 'opaque'    # SDL_Keysym
        ]
    );
    sub SDL_TEXTEDITINGEVENT_TEXT_SIZE () {32}
    FFI::C::StructDef->new(
        $ffi,
        name    => 'SDL_TextEditingEvent',
        class   => 'SDL2::TextEditingEvent',
        members => [
            type      => 'uint32',
            timestamp => 'uint32',
            windowId  => 'uint32',
            text      => 'char[' . SDL_TEXTEDITINGEVENT_TEXT_SIZE . ']',
            start     => 'sint32',
            length    => 'sint32'
        ]
    );
    sub SDL_TEXTINPUTEVENT_TEXT_SIZE () {32}
    FFI::C::StructDef->new(
        $ffi,
        name    => 'SDL_TextInputEvent',
        class   => 'SDL2::TextInputEvent',
        members => [
            type      => 'uint32',
            timestamp => 'uint32',
            windowId  => 'uint32',
            text      => 'char[' . SDL_TEXTEDITINGEVENT_TEXT_SIZE . ']'
        ]
    );
    FFI::C::StructDef->new(
        $ffi,
        name    => 'SDL_MouseMotionEvent',
        class   => 'SDL2::MouseMotionEvent',
        members => [
            type      => 'uint32',
            timestamp => 'uint32',
            windowId  => 'uint32',
            which     => 'uint32',
            state     => 'uint8',
            x         => 'sint32',
            y         => 'sint32',
            xrel      => 'sint32',
            yrel      => 'sint32'
        ]
    );
    FFI::C::StructDef->new(
        $ffi,
        name    => 'SDL_MouseButtonEvent',
        class   => 'SDL2::MouseButtonEvent',
        members => [
            type      => 'uint32',
            timestamp => 'uint32',
            windowID  => 'uint32',
            which     => 'uint32',
            button    => 'uint8',
            state     => 'uint8',
            clicks    => 'uint8',
            padding1  => 'uint8',
            x         => 'sint32',
            y         => 'sint32'
        ]
    );
    FFI::C::StructDef->new(
        $ffi,
        name    => 'SDL_MouseWheelEvent',
        class   => 'SDL2::MouseWheelEvent',
        members => [
            type      => 'uint32',
            timestamp => 'uint32',
            windowId  => 'uint32',
            which     => 'uint8',
            x         => 'sint32',
            y         => 'sint32',
            direction => 'uint32'
        ]
    );
    FFI::C::StructDef->new(
        $ffi,
        name    => 'SDL_JoyAxisEvent',
        class   => 'SDL2::JoyAxisEvent',
        members => [
            type      => 'uint32',
            timestamp => 'uint32',
            which     => 'opaque',    # SDL_JoystickID
            padding1  => 'uint8',
            padding2  => 'uint8',
            padding3  => 'uint8',
            value     => 'sint16',
            padding4  => 'uint16'
        ]
    );
    FFI::C::StructDef->new(
        $ffi,
        name    => 'SDL_JoyBallEvent',
        class   => 'SDL2::JoyBallEvent',
        members => [
            type      => 'uint32',
            timestamp => 'uint32',
            which     => 'opaque',    # SDL_JoystickID
            padding1  => 'uint8',
            padding2  => 'uint8',
            padding3  => 'uint8',
            xrel      => 'sint16',
            yrel      => 'uint16',
        ]
    );
    FFI::C::StructDef->new(
        $ffi,
        name    => 'SDL_JoyHatEvent',
        class   => 'SDL2::JoyHatEvent',
        members => [
            type      => 'uint32',
            timestamp => 'uint32',
            which     => 'opaque',    # SDL_JoystickID
            hat       => 'uint8',
            value     => 'uint8',
            padding1  => 'uint8',
            padding2  => 'uint8'
        ]
    );
    FFI::C::StructDef->new(
        $ffi,
        name    => 'SDL_JoyButtonEvent',
        class   => 'SDL2::JoyButtonEvent',
        members => [
            type      => 'uint32',
            timestamp => 'uint32',
            which     => 'opaque',    # SDL_JoystickID
            button    => 'uint8',
            state     => 'uint8',
            padding1  => 'uint8',
            padding2  => 'uint8'
        ]
    );
    FFI::C::StructDef->new(
        $ffi,
        name    => 'SDL_JoyDeviceEvent',
        class   => 'SDL2::JoyDeviceEvent',
        members => [ type => 'uint32', timestamp => 'uint32', which => 'sint32' ]
    );
    FFI::C::StructDef->new(
        $ffi,
        name    => 'SDL_ControllerAxisEvent',
        class   => 'SDL2::ControllerAxisEvent',
        members => [
            type      => 'uint32',
            timestamp => 'uint32',
            which     => 'opaque',    # SDL_JoystickID
            axis      => 'uint8',
            padding1  => 'uint8',
            padding2  => 'uint8',
            padding3  => 'uint8',
            value     => 'sint16',
            padding4  => 'uint8'
        ]
    );
    FFI::C::StructDef->new(
        $ffi,
        name    => 'SDL_ControllerButtonEvent',
        class   => 'SDL2::ControllerButtonEvent',
        members => [
            type      => 'uint32',
            timestamp => 'uint32',
            which     => 'opaque',    # SDL_JoystickID
            button    => 'uint8',
            state     => 'uint8',
            padding1  => 'uint8',
            padding2  => 'uint8',
        ]
    );
    FFI::C::StructDef->new(
        $ffi,
        name    => 'SDL_ControllerDeviceEvent',
        class   => 'SDL2::ControllerDeviceEvent',
        members => [ type => 'uint32', timestamp => 'uint32', which => 'sint32' ]
    );
    FFI::C::StructDef->new(
        $ffi,
        name    => 'SDL_AudioDeviceEvent',
        class   => 'SDL2::AudioDeviceEvent',
        members => [
            type      => 'uint32',
            timestamp => 'uint32',
            which     => 'uint32',
            iscapture => 'uint8',
            padding1  => 'uint8',
            padding2  => 'uint8',
            padding3  => 'uint8'
        ]
    );
    FFI::C::StructDef->new(
        $ffi,
        name    => 'SDL_TouchFingerEvent',
        class   => 'SDL2::TouchFingerEvent',
        members => [
            type      => 'uint32',
            timestamp => 'uint32',
            touchId   => 'opaque',    # SDL_TouchID
            fingerId  => 'opaque',    # SDL_FingerID
            x         => 'float',
            y         => 'float',
            dx        => 'float',
            dy        => 'float',
            pressure  => 'float'
        ]
    );
    FFI::C::StructDef->new(
        $ffi,
        name    => 'SDL_MultiGestureEvent',
        class   => 'SDL2::MultiGestureEvent',
        members => [
            type       => 'uint32',
            timestamp  => 'uint32',
            touchId    => 'opaque',    # SDL_TouchID
            dTheta     => 'float',
            dDist      => 'float',
            x          => 'float',
            y          => 'float',
            numFingers => 'uint16',
            padding    => 'uint16'
        ]
    );
    FFI::C::StructDef->new(
        $ffi,
        name    => 'SDL_DollarGestureEvent',
        class   => 'SDL2::DollarGestureEvent',
        members => [
            type       => 'uint32',
            timestamp  => 'uint32',
            touchId    => 'opaque',    # SDL_TouchID
            gestureId  => 'opaque',    # SDL_GestureID
            numFingers => 'uint32',
            error      => 'float',
            x          => 'float',
            y          => 'float'
        ]
    );
    FFI::C::StructDef->new(
        $ffi,
        name    => 'SDL_DropEvent',
        class   => 'SDL2::DropEvent',
        members =>
            [ type => 'uint32', timestamp => 'uint32', file => 'char[256]', windowID => 'uint32' ]
    );
    FFI::C::StructDef->new(
        $ffi,
        name    => 'SDL_SensorEvent',
        class   => 'SDL2::SensorEvent',
        members =>
            [ type => 'uint32', timestamp => 'uint32', which => 'sint32', data => 'float[6]' ]
    );
    FFI::C::StructDef->new(
        $ffi,
        name    => 'SDL_QuitEvent',
        class   => 'SDL2::QuitEvent',
        members => [ type => 'uint32', timestamp => 'uint32', ]
    );
    FFI::C::StructDef->new(
        $ffi,
        name    => 'SDL_OSEvent',
        class   => 'SDL2::OSEvent',
        members => [ type => 'uint32', timestamp => 'uint32', ]
    );
    FFI::C::StructDef->new(
        $ffi,
        name    => 'SDL_UserEvent',
        class   => 'SDL2::UserEvent',
        members => [
            type      => 'uint32',
            timestamp => 'uint32',
            windowID  => 'uint32',
            code      => 'sint32',
            data1     => 'opaque',    # void *
            data2     => 'opaque',    # void *
        ]
    );
    FFI::C::StructDef->new(
        $ffi,
        name    => 'SDL_SysWMmsg',
        class   => 'SDL2::SysWMmsg',
        members => []
    );
    FFI::C::StructDef->new(
        $ffi,
        name    => 'SDL_SysWMEvent',
        class   => 'SDL2::SysWMEvent',
        members => [
            type      => 'uint32',
            timestamp => 'uint32',
            msg       => 'opaque',    # SDL_SysWMmsg
        ]
    );
    use FFI::C::UnionDef;
    FFI::C::UnionDef->new(
        $ffi,
        name    => 'SDL_Event',
        class   => 'SDL2::Event',
        members => [
            type     => 'uint32',
            common   => 'SDL_CommonEvent',
            display  => 'SDL_DisplayEvent',
            window   => 'SDL_WindowEvent',
            key      => 'SDL_KeyboardEvent',
            edit     => 'SDL_TextEditingEvent',
            text     => 'SDL_TextInputEvent',
            motion   => 'SDL_MouseMotionEvent',
            button   => 'SDL_MouseButtonEvent',
            wheel    => 'SDL_MouseWheelEvent',
            jaxis    => 'SDL_JoyAxisEvent',
            jball    => 'SDL_JoyBallEvent',
            jhat     => 'SDL_JoyHatEvent',
            jbutton  => 'SDL_JoyButtonEvent',
            jdevice  => 'SDL_JoyDeviceEvent',
            caxis    => 'SDL_ControllerAxisEvent',
            cbutton  => 'SDL_ControllerButtonEvent',
            cdevice  => 'SDL_ControllerDeviceEvent',
            adevice  => 'SDL_AudioDeviceEvent',
            sensor   => 'SDL_SensorEvent',
            quit     => 'SDL_QuitEvent',
            user     => 'SDL_UserEvent',
            syswm    => 'SDL_SysWMEvent',
            tfinger  => 'SDL_TouchFingerEvent',
            mgesture => 'SDL_MultiGestureEvent',
            dgesture => 'SDL_DollarGestureEvent',
            drop     => 'SDL_DropEvent',
            padding  => 'uint8[56]'
        ]
    );
    FFI::C->enum(
        'SDL_eventaction',
        [   qw[
                SDL_ADDEVENT
                SDL_PEEKEVENT
                SDL_GETEVENT]
        ]
    );
    $ffi->attach(
        SDL_PeepEvents => [ 'SDL_Event', 'int', 'SDL_eventaction', 'uint32', 'uint32' ] => 'int' );
    $ffi->attach( SDL_HasEvent         => ['uint32']             => 'bool' );
    $ffi->attach( SDL_HasEvents        => [ 'uint32', 'uint32' ] => 'bool' );
    $ffi->attach( SDL_FlushEvent       => ['uint32'] );
    $ffi->attach( SDL_FlushEvents      => [ 'uint32', 'uint32' ] );
    $ffi->attach( SDL_PollEvent        => ['SDL_Event']          => 'int' );
    $ffi->attach( SDL_WaitEvent        => ['SDL_Event']          => 'int' );
    $ffi->attach( SDL_WaitEventTimeout => [ 'SDL_Event', 'int' ] => 'int' );
    $ffi->attach( SDL_PushEvent        => ['SDL_Event']          => 'int' );
    $ffi->type( '(opaque, opaque)->int' => 'SDL_EventFilter' );
    $ffi->attach( SDL_SetEventFilter => [ 'SDL_EventFilter', 'opaque' ] );
    $ffi->attach( SDL_GetEventFilter => [ 'SDL_EventFilter', 'opaque' ] => 'bool' );
    $ffi->attach( SDL_AddEventWatch  => [ 'SDL_EventFilter', 'opaque' ] );
    $ffi->attach( SDL_DelEventWatch  => [ 'SDL_EventFilter', 'opaque' ] );
    $ffi->attach( SDL_FilterEvents   => [ 'SDL_EventFilter', 'opaque' ] );
    #
    sub SDL_QUERY ()   {-1}
    sub SDL_IGNORE ()  {0}
    sub SDL_DISABLE () {0}
    sub SDL_ENABLE ()  {1}
    #
    $ffi->attach( SDL_EventState => [ 'uint32', 'int' ] => 'uint8' );
    sub SDL_GetEventState ($type) { SDL_EventState( $type, SDL_QUERY ) }
    $ffi->attach( SDL_RegisterEvents => ['int'] => 'uint32' );

    # From src/events/SDL_mouse_c.h
    FFI::C::StructDef->new(
        $ffi,
        name    => 'SDL_Cursor',
        class   => 'SDL2::Cursor',
        members => [
            next       => 'opaque',    # SDL_Cursor
            driverdata => 'opaque'     # void *
        ]
    );

    # From SDL_mouse.h
    FFI::C->enum(
        'SDL_SystemCursor',
        [   qw[
                SDL_SYSTEM_CURSOR_ARROW
                SDL_SYSTEM_CURSOR_IBEAM
                SDL_SYSTEM_CURSOR_WAIT
                SDL_SYSTEM_CURSOR_CROSSHAIR
                SDL_SYSTEM_CURSOR_WAITARROW
                SDL_SYSTEM_CURSOR_SIZENWSE
                SDL_SYSTEM_CURSOR_SIZENESW
                SDL_SYSTEM_CURSOR_SIZEWE
                SDL_SYSTEM_CURSOR_SIZENS
                SDL_SYSTEM_CURSOR_SIZEALL
                SDL_SYSTEM_CURSOR_NO
                SDL_SYSTEM_CURSOR_HAND
                SDL_NUM_SYSTEM_CURSORS]
        ]
    );
    FFI::C->enum(
        'SDL_MouseWheelDirection',
        [   qw[
                SDL_MOUSEWHEEL_NORMAL
                SDL_MOUSEWHEEL_FLIPPED
            ]
        ]
    );
    $ffi->attach( SDL_GetMouseFocus         => [] => 'SDL_Window' );
    $ffi->attach( SDL_GetMouseState         => [ 'int',        'int' ] => 'uint32' );
    $ffi->attach( SDL_GetGlobalMouseState   => [ 'int',        'int' ] => 'uint32' );
    $ffi->attach( SDL_GetRelativeMouseState => [ 'int',        'int' ] => 'uint32' );
    $ffi->attach( SDL_WarpMouseInWindow     => [ 'SDL_Window', 'int', 'int' ] );
    $ffi->attach( SDL_SetRelativeMouseMode  => ['bool'] => 'int' );
    $ffi->attach( SDL_CaptureMouse          => ['bool'] => 'int' );
    $ffi->attach( SDL_GetRelativeMouseMode  => []       => 'bool' );
    $ffi->attach(
        SDL_CreateCursor => [ 'uint8', 'uint8', 'int', 'int', 'int', 'int' ] => 'SDL_Cursor' );
    $ffi->attach( SDL_CreateSystemCursor => ['SDL_SystemCursor'] => 'SDL_Cursor' );
    $ffi->attach( SDL_SetCursor          => ['SDL_Cursor'] );
    $ffi->attach( SDL_GetCursor          => []      => 'SDL_Cursor' );
    $ffi->attach( SDL_GetDefaultCursor   => []      => 'SDL_Cursor' );
    $ffi->attach( SDL_FreeCursor         => []      => 'SDL_Cursor' );
    $ffi->attach( SDL_ShowCursor         => ['int'] => 'int' );
    sub SDL_BUTTON ($X)      { ( 1 << ( ($X) - 1 ) ) }
    sub SDL_BUTTON_LEFT ()   {1}
    sub SDL_BUTTON_MIDDLE () {2}
    sub SDL_BUTTON_RIGHT ()  {3}
    sub SDL_BUTTON_X1 ()     {4}
    sub SDL_BUTTON_X2 ()     {5}
    sub SDL_BUTTON_LMASK ()  { SDL_BUTTON(SDL_BUTTON_LEFT) }
    sub SDL_BUTTON_MMASK ()  { SDL_BUTTON(SDL_BUTTON_MIDDLE) }
    sub SDL_BUTTON_RMASK ()  { SDL_BUTTON(SDL_BUTTON_RIGHT) }
    sub SDL_BUTTON_X1MASK () { SDL_BUTTON(SDL_BUTTON_X1) }
    sub SDL_BUTTON_X2MASK () { SDL_BUTTON(SDL_BUTTON_X2) }

    # https://wiki.libsdl.org/CategoryPixels
    sub SDL_ALPHA_OPAQUE()      {255}
    sub SDL_ALPHA_TRANSPARENT() {0}
    FFI::C->enum(
        pixel_type => [
            qw[
                SDL_PIXELTYPE_UNKNOWN
                SDL_PIXELTYPE_INDEX1
                SDL_PIXELTYPE_INDEX4
                SDL_PIXELTYPE_INDEX8
                SDL_PIXELTYPE_PACKED8
                SDL_PIXELTYPE_PACKED16
                SDL_PIXELTYPE_PACKED32
                SDL_PIXELTYPE_ARRAYU8
                SDL_PIXELTYPE_ARRAYU16
                SDL_PIXELTYPE_ARRAYU32
                SDL_PIXELTYPE_ARRAYF16
                SDL_PIXELTYPE_ARRAYF32
            ]
        ]
    );
    FFI::C->enum(
        bitmap_order => [
            qw[
                SDL_BITMAPORDER_NONE
                SDL_BITMAPORDER_4321
                SDL_BITMAPORDER_1234
            ]
        ]
    );
    FFI::C->enum(
        packed_order => [
            qw[
                SDL_PACKEDORDER_NONE
                SDL_PACKEDORDER_XRGB
                SDL_PACKEDORDER_RGBX
                SDL_PACKEDORDER_ARGB
                SDL_PACKEDORDER_RGBA
                SDL_PACKEDORDER_XBGR
                SDL_PACKEDORDER_BGRX
                SDL_PACKEDORDER_ABGR
                SDL_PACKEDORDER_BGRA
            ]
        ]
    );
    FFI::C->enum(
        array_order => [
            qw[
                SDL_ARRAYORDER_NONE
                SDL_ARRAYORDER_RGB
                SDL_ARRAYORDER_RGBA
                SDL_ARRAYORDER_ARGB
                SDL_ARRAYORDER_BGR
                SDL_ARRAYORDER_BGRA
                SDL_ARRAYORDER_ABGR
            ]
        ]
    );
    FFI::C->enum(
        packed_layout => [
            qw[
                SDL_PACKEDLAYOUT_NONE
                SDL_PACKEDLAYOUT_332
                SDL_PACKEDLAYOUT_4444
                SDL_PACKEDLAYOUT_1555
                SDL_PACKEDLAYOUT_5551
                SDL_PACKEDLAYOUT_565
                SDL_PACKEDLAYOUT_8888
                SDL_PACKEDLAYOUT_2101010
                SDL_PACKEDLAYOUT_1010102
            ]
        ]
    );
    sub SDL_DEFINE_PIXELFOURCC ( $A, $B, $C, $D ) { SDL_FOURCC( $A, $B, $C, $D ) }

    sub SDL_DEFINE_PIXELFORMAT ( $type, $order, $layout, $bits, $bytes ) {
        ( ( 1 << 28 ) | ( ($type) << 24 ) | ( ($order) << 20 ) | ( ($layout) << 16 )
                | ( ($bits) << 8 ) | ( ($bytes) << 0 ) )
    }
    sub SDL_PIXELFLAG    ($X) { ( ( ($X) >> 28 ) & 0x0F ) }
    sub SDL_PIXELTYPE    ($X) { ( ( ($X) >> 24 ) & 0x0F ) }
    sub SDL_PIXELORDER   ($X) { ( ( ($X) >> 20 ) & 0x0F ) }
    sub SDL_PIXELLAYOUT  ($X) { ( ( ($X) >> 16 ) & 0x0F ) }
    sub SDL_BITSPERPIXEL ($X) { ( ( ($X) >> 8 ) & 0xFF ) }

    sub SDL_BYTESPERPIXEL ($X) {
        (
            SDL_ISPIXELFORMAT_FOURCC($X) ? (
                (
                    ( ($X) == SDL_PIXELFORMAT_YUY2() )     ||
                        ( ($X) == SDL_PIXELFORMAT_UYVY() ) ||
                        ( ($X) == SDL_PIXELFORMAT_YVYU() )
                ) ? 2 : 1
                ) :
                ( ( ($X) >> 0 ) & 0xFF )
        )
    }

    sub SDL_ISPIXELFORMAT_INDEXED ($format) {
        (
            !SDL_ISPIXELFORMAT_FOURCC($format) &&
                ( ( SDL_PIXELTYPE($format) == SDL_PIXELTYPE_INDEX1() ) ||
                ( SDL_PIXELTYPE($format) == SDL_PIXELTYPE_INDEX4() ) ||
                ( SDL_PIXELTYPE($format) == SDL_PIXELTYPE_INDEX8() ) )
        )
    }

    sub SDL_ISPIXELFORMAT_PACKED ($format) {
        (
            !SDL_ISPIXELFORMAT_FOURCC($format) &&
                ( ( SDL_PIXELTYPE($format) == SDL_PIXELTYPE_PACKED8() ) ||
                ( SDL_PIXELTYPE($format) == SDL_PIXELTYPE_PACKED16() ) ||
                ( SDL_PIXELTYPE($format) == SDL_PIXELTYPE_PACKED32() ) )
        )
    }

    sub SDL_ISPIXELFORMAT_ARRAY ($format) {
        (
            !SDL_ISPIXELFORMAT_FOURCC($format) &&
                ( ( SDL_PIXELTYPE($format) == SDL_PIXELTYPE_ARRAYU8() ) ||
                ( SDL_PIXELTYPE($format) == SDL_PIXELTYPE_ARRAYU16() ) ||
                ( SDL_PIXELTYPE($format) == SDL_PIXELTYPE_ARRAYU32() ) ||
                ( SDL_PIXELTYPE($format) == SDL_PIXELTYPE_ARRAYF16() ) ||
                ( SDL_PIXELTYPE($format) == SDL_PIXELTYPE_ARRAYF32() ) )
        )
    }

    sub SDL_ISPIXELFORMAT_ALPHA ($format) {
        (
            (
                SDL_ISPIXELFORMAT_PACKED($format) &&
                    ( ( SDL_PIXELORDER($format) == SDL_PACKEDORDER_ARGB() ) ||
                    ( SDL_PIXELORDER($format) == SDL_PACKEDORDER_RGBA() ) ||
                    ( SDL_PIXELORDER($format) == SDL_PACKEDORDER_ABGR() ) ||
                    ( SDL_PIXELORDER($format) == SDL_PACKEDORDER_BGRA() ) )
            ) ||
                (
                SDL_ISPIXELFORMAT_ARRAY($format) &&
                ( ( SDL_PIXELORDER($format) == SDL_ARRAYORDER_ARGB() ) ||
                    ( SDL_PIXELORDER($format) == SDL_ARRAYORDER_RGBA() ) ||
                    ( SDL_PIXELORDER($format) == SDL_ARRAYORDER_ABGR() ) ||
                    ( SDL_PIXELORDER($format) == SDL_ARRAYORDER_BGRA() ) )
                )
        )
    }

    #/* The flag is set to 1 because 0x1? is not in the printable ASCII range */
    sub SDL_ISPIXELFORMAT_FOURCC ($format) { ( ($format) && ( SDL_PIXELFLAG($format) != 1 ) ) }
    sub SDL_PIXELFORMAT_UNKNOWN ()         {0}

    sub SDL_PIXELFORMAT_INDEX1LSB () {
        SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_INDEX1(), SDL_BITMAPORDER_4321(), 0, 1, 0 );
    }

    sub SDL_PIXELFORMAT_INDEX1MSB () {
        SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_INDEX1(), SDL_BITMAPORDER_1234(), 0, 1, 0 );
    }

    sub SDL_PIXELFORMAT_INDEX4LSB () {
        SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_INDEX4(), SDL_BITMAPORDER_4321(), 0, 4, 0 );
    }

    sub SDL_PIXELFORMAT_INDEX4MSB () {
        SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_INDEX4(), SDL_BITMAPORDER_1234(), 0, 4, 0 );
    }

    sub SDL_PIXELFORMAT_INDEX8 () {
        SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_INDEX8(), 0, 0, 8, 1 );
    }

    sub SDL_PIXELFORMAT_RGB332 () {
        SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED8(), SDL_PACKEDORDER_XRGB(),
            SDL_PACKEDLAYOUT_332(), 8, 1 );
    }

    sub SDL_PIXELFORMAT_RGB444 () {
        SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED16(), SDL_PACKEDORDER_XRGB(),
            SDL_PACKEDLAYOUT_4444(), 12, 2 );
    }

    sub SDL_PIXELFORMAT_RGB555 () {
        SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED16(), SDL_PACKEDORDER_XRGB(),
            SDL_PACKEDLAYOUT_1555(), 15, 2 );
    }

    sub SDL_PIXELFORMAT_BGR555 () {
        SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED16(), SDL_PACKEDORDER_XBGR(),
            SDL_PACKEDLAYOUT_1555(), 15, 2 );
    }

    sub SDL_PIXELFORMAT_ARGB4444 () {
        SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED16(), SDL_PACKEDORDER_ARGB(),
            SDL_PACKEDLAYOUT_4444(), 16, 2 );
    }

    sub SDL_PIXELFORMAT_RGBA4444 () {
        SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED16(), SDL_PACKEDORDER_RGBA(),
            SDL_PACKEDLAYOUT_4444(), 16, 2 );
    }

    sub SDL_PIXELFORMAT_ABGR4444 () {
        SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED16(), SDL_PACKEDORDER_ABGR(),
            SDL_PACKEDLAYOUT_4444(), 16, 2 );
    }

    sub SDL_PIXELFORMAT_BGRA4444 () {
        SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED16(), SDL_PACKEDORDER_BGRA(),
            SDL_PACKEDLAYOUT_4444(), 16, 2 );
    }

    sub SDL_PIXELFORMAT_ARGB1555 () {
        SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED16(), SDL_PACKEDORDER_ARGB(),
            SDL_PACKEDLAYOUT_1555(), 16, 2 );
    }

    sub SDL_PIXELFORMAT_RGBA5551 () {
        SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED16(), SDL_PACKEDORDER_RGBA(),
            SDL_PACKEDLAYOUT_5551(), 16, 2 );
    }

    sub SDL_PIXELFORMAT_ABGR1555 () {
        SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED16(), SDL_PACKEDORDER_ABGR(),
            SDL_PACKEDLAYOUT_1555(), 16, 2 );
    }

    sub SDL_PIXELFORMAT_BGRA5551 () {
        SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED16(), SDL_PACKEDORDER_BGRA(),
            SDL_PACKEDLAYOUT_5551(), 16, 2 );
    }

    sub SDL_PIXELFORMAT_RGB565 () {
        SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED16(), SDL_PACKEDORDER_XRGB(),
            SDL_PACKEDLAYOUT_565(), 16, 2 );
    }

    sub SDL_PIXELFORMAT_BGR565 () {
        SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED16(), SDL_PACKEDORDER_XBGR(),
            SDL_PACKEDLAYOUT_565(), 16, 2 );
    }

    sub SDL_PIXELFORMAT_RGB24 () {
        SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_ARRAYU8(), SDL_ARRAYORDER_RGB(), 0, 24, 3 );
    }

    sub SDL_PIXELFORMAT_BGR24 () {
        SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_ARRAYU8(), SDL_ARRAYORDER_BGR(), 0, 24, 3 );
    }

    sub SDL_PIXELFORMAT_RGB888 () {
        SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED32(), SDL_PACKEDORDER_XRGB(),
            SDL_PACKEDLAYOUT_8888(), 24, 4 );
    }

    sub SDL_PIXELFORMAT_RGBX8888 () {
        SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED32(), SDL_PACKEDORDER_RGBX(),
            SDL_PACKEDLAYOUT_8888(), 24, 4 );
    }

    sub SDL_PIXELFORMAT_BGR888 () {
        SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED32(), SDL_PACKEDORDER_XBGR(),
            SDL_PACKEDLAYOUT_8888(), 24, 4 );
    }

    sub SDL_PIXELFORMAT_BGRX8888 () {
        SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED32(), SDL_PACKEDORDER_BGRX(),
            SDL_PACKEDLAYOUT_8888(), 24, 4 );
    }

    sub SDL_PIXELFORMAT_ARGB8888 () {
        SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED32(), SDL_PACKEDORDER_ARGB(),
            SDL_PACKEDLAYOUT_8888(), 32, 4 );
    }

    sub SDL_PIXELFORMAT_RGBA8888 () {
        SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED32(), SDL_PACKEDORDER_RGBA(),
            SDL_PACKEDLAYOUT_8888(), 32, 4 );
    }

    sub SDL_PIXELFORMAT_ABGR8888 () {
        SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED32(), SDL_PACKEDORDER_ABGR(),
            SDL_PACKEDLAYOUT_8888(), 32, 4 );
    }

    sub SDL_PIXELFORMAT_BGRA8888 () {
        SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED32(), SDL_PACKEDORDER_BGRA(),
            SDL_PACKEDLAYOUT_8888(), 32, 4 );
    }

    sub SDL_PIXELFORMAT_ARGB2101010 () {
        SDL_DEFINE_PIXELFORMAT( SDL_PIXELTYPE_PACKED32(), SDL_PACKEDORDER_ARGB(),
            SDL_PACKEDLAYOUT_2101010(),
            32, 4 );
    }

    #    /* Aliases for RGBA byte arrays of color data, for the current platform */
    #if SDL_BYTEORDER == SDL_BIG_ENDIAN
    #    SDL_PIXELFORMAT_RGBA32 = SDL_PIXELFORMAT_RGBA8888,
    #    SDL_PIXELFORMAT_ARGB32 = SDL_PIXELFORMAT_ARGB8888,
    #    SDL_PIXELFORMAT_BGRA32 = SDL_PIXELFORMAT_BGRA8888,
    #    SDL_PIXELFORMAT_ABGR32 = SDL_PIXELFORMAT_ABGR8888,
    #else
    #    SDL_PIXELFORMAT_RGBA32 = SDL_PIXELFORMAT_ABGR8888,
    #    SDL_PIXELFORMAT_ARGB32 = SDL_PIXELFORMAT_BGRA8888,
    #    SDL_PIXELFORMAT_BGRA32 = SDL_PIXELFORMAT_ARGB8888,
    #    SDL_PIXELFORMAT_ABGR32 = SDL_PIXELFORMAT_RGBA8888,
    #endif
    sub SDL_PIXELFORMAT_YV12 () {
        SDL_DEFINE_PIXELFOURCC( 'Y', 'V', '1', '2' );
    }

    sub SDL_PIXELFORMAT_IYUV () {
        SDL_DEFINE_PIXELFOURCC( 'I', 'Y', 'U', 'V' );
    }

    sub SDL_PIXELFORMAT_YUY2 () {
        SDL_DEFINE_PIXELFOURCC( 'Y', 'U', 'Y', '2' );
    }

    sub SDL_PIXELFORMAT_UYVY () {
        SDL_DEFINE_PIXELFOURCC( 'U', 'Y', 'V', 'Y' );
    }

    sub SDL_PIXELFORMAT_YVYU () {
        SDL_DEFINE_PIXELFOURCC( 'Y', 'V', 'Y', 'U' );
    }

    sub SDL_PIXELFORMAT_NV12 () {
        SDL_DEFINE_PIXELFOURCC( 'N', 'V', '1', '2' );
    }

    sub SDL_PIXELFORMAT_NV21 () {
        SDL_DEFINE_PIXELFOURCC( 'N', 'V', '2', '1' );
    }

    sub SDL_PIXELFORMAT_EXTERNAL_OES () {
        SDL_DEFINE_PIXELFOURCC( 'O', 'E', 'S', ' ' );
    }

    # include/SDL_stdinc.h
    sub SDL_FOURCC ( $A, $B, $C, $D ) { $A << 0 | $B << 8 | $C << 16 | $D << 24 }

# Unsorted - https://github.com/libsdl-org/SDL/blob/c59d4dcd38c382a1e9b69b053756f1139a861574/include/SDL_keycode.h
#    https://github.com/libsdl-org/SDL/blob/c59d4dcd38c382a1e9b69b053756f1139a861574/include/SDL_scancode.h#L151
    sub SDLK_SCANCODE_MASK           { 1 << 30 }
    sub SDL_SCANCODE_TO_KEYCODE ($X) { $X | SDLK_SCANCODE_MASK }
    FFI::C->enum(
        'SDL_Keycode',
        [   [ SDLK_UP => SDL_SCANCODE_TO_KEYCODE(82) ],    # 82 comes from include/SDL_scancode.h

            # The following are incorrect!!!!!!!!!!!!!!!!!!!
            qw[SDLK_DOWN
                SDLK_LEFT
                SDLK_RIGHT]
        ]
    );
    attach(
        all => {

            # Unknown...
            SDL_SetMainReady => [ [] => 'void' ]
        }
    );

    #warn SDL2::SDLK_UP();
    #warn SDL2::SDLK_DOWN();
    # https://github.com/libsdl-org/SDL/blob/main/include/SDL_hints.h
    # Export symbols!
    our @EXPORT_OK = map {@$_} values %EXPORT_TAGS;
#### REMOVE THIS BEFORE STABLE RELEASE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #####
    #@EXPORT_OK = @EXPORT_OK, keys
    #    %{ { map { $_ => 1 } grep {/^SDL_/} keys %SDL2::FFI::, map {@$_} values %EXPORT_TAGS } };
####################################################################################################
    $EXPORT_TAGS{default} = [];             # Export nothing by default
    $EXPORT_TAGS{all}     = \@EXPORT_OK;    # Export everything with :all tag
}
1;

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut

# Examples:
#  - https://github.com/crust/sdl2-examples
#
