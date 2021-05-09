package SDL2 1.0 {
    use strictures 2;
    $|++;
    #
    use File::ShareDir qw[dist_dir];
    use File::Spec::Functions qw[catdir canonpath rel2abs];

    #use Carp::Always;
    #
    use FFI::CheckLib;
    use FFI::Platypus 1.00;
    use FFI::C;
    use FFI::Platypus::Memory qw[malloc free];
    use experimental 'signatures';
    use base 'Exporter::Tiny';
    #
    use Data::Dump;
    $ENV{FFI_PLATYPUS_DLERROR} = 1;

=encoding utf-8

=head1 NAME

SDL2 - FFI Wrapper for SDL (Simple DirectMedia Layer) Development Library

=head1 SYNOPSIS

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

=head1 DESCRIPTION

SDL2 is ...

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut

    #warn `pkg-config --libs sdl2`;
    #warn `pkg-config --cflags sdl2`;
    my $ffi = FFI::Platypus->new(
        api          => 1,
        experimental => 2,
        lang         => 'CPP',
        lib          => find_lib_or_exit(
            lib       => 'SDL2',
            recursive => 1,
            libpath   => [
                qw[. ./share/lib ../share/lib],
                eval { canonpath( catdir( dist_dir(__PACKAGE__), 'lib' ) ) }
            ]
        )
    );

    #$ffi->bundle;
    FFI::C->ffi($ffi);
    use Data::Dump;

    #ddx($ffi);
    # See https://wiki.libsdl.org/APIByCategory
    # Basics
    ## https://wiki.libsdl.org/CategoryInit
    $ffi->attach( SDL_Init          => ['uint32'] => 'int' );
    $ffi->attach( SDL_InitSubSystem => ['uint32'] => 'int' );
    $ffi->attach( SDL_Quit          => []         => 'void' );
    $ffi->attach( SDL_QuitSubSystem => ['uint32'] => 'void' );
    $ffi->attach( SDL_SetMainReady  => []         => 'void' );
    $ffi->attach( SDL_WasInit       => ['uint32'] => 'uint32' );

    # Only on windows
    # https://wiki.libsdl.org/SDL_WinRTRunApp
    #$ffi->attach( SDL_WinRTRunApp => ['opaque', 'opaque'] => 'int' );
    # https://wiki.libsdl.org/CategoryHints
    #$ffi->attach( SDL_AddHintCallback => ['string', 'sdl_HintCallback', 'opaque'] => 'void' );
    $ffi->attach( SDL_ClearHints => [] => 'void' );

    #$ffi->attach( SDL_DelHintCallback => ['string', 'sdl_HintCallback', 'opaque'] => 'void' );
    $ffi->attach( SDL_GetHint             => ['string']                    => 'string' );
    $ffi->attach( SDL_GetHintBoolean      => [ 'string', 'bool' ]          => 'bool' );
    $ffi->attach( SDL_SetHint             => [ 'string', 'string' ]        => 'bool' );
    $ffi->attach( SDL_SetHintWithPriority => [ 'string', 'string', 'int' ] => 'bool' );

    # https://wiki.libsdl.org/CategoryVersion
    use FFI::C::StructDef;
    FFI::C::StructDef->new(
        $ffi,
        name    => 'SDL_version',
        class   => 'SDL2::version',
        members => [ major => 'uint8', minor => 'uint8', patch => 'uint8' ]
    );
    $ffi->attach( SDL_GetRevision       => [] => 'string' );
    $ffi->attach( SDL_GetRevisionNumber => [] => 'int' );
    $ffi->attach( SDL_GetVersion        => ['SDL_version'] );

    # https://wiki.libsdl.org/CategoryLog
    FFI::C->enum(
        'SDL_LOG_CATEGORY',
        [   qw[
                SDL_LOG_CATEGORY_OFFSET
                SDL_LOG_CATEGORY_APPLICATION SDL_LOG_CATEGORY_ERROR
                SDL_LOG_CATEGORY_ASSERT 	 SDL_LOG_CATEGORY_SYSTEM
                SDL_LOG_CATEGORY_AUDIO 		 SDL_LOG_CATEGORY_VIDEO
                SDL_LOG_CATEGORY_RENDER		 SDL_LOG_CATEGORY_INPUT
                SDL_LOG_CATEGORY_TEST		 SDL_LOG_CATEGORY_RESERVED
                SDL_LOG_CATEGORY_CUSTOM]
        ]
    );
    FFI::C->enum(
        'SDL_LogPriority',
        [   qw[
                SDL_LOG_OFFSET
                SDL_LOG_PRIORITY_VERBOSE	SDL_LOG_PRIORITY_DEBUG
                SDL_LOG_PRIORITY_INFO		SDL_LOG_PRIORITY_WARN
                SDL_LOG_PRIORITY_ERROR		SDL_LOG_PRIORITY_CRITICAL
                SDL_NUM_LOG_PRIORITIES]
        ]
    );
    $ffi->attach( SDL_Log => ['string'] => ['string'] =>
            sub ( $inner, $fmt, @args ) { $inner->( sprintf( $fmt, @args ) ) } );
    $ffi->attach( $_ => [ 'SDL_LOG_CATEGORY', 'string' ] =>
            sub ( $inner, $category, $fmt, @args ) { $inner->( $category, sprintf( $fmt, @args ) ) }
    ) for qw[SDL_LogCritical SDL_LogDebug SDL_LogError SDL_LogInfo SDL_LogVerbose SDL_LogWarn];
    $ffi->attach(
        SDL_LogMessage => [ 'SDL_LOG_CATEGORY', 'SDL_LogPriority', 'string' ] =>
            sub ( $inner, $category, $priority, $fmt, @args ) {
            $inner->( $category, $priority, sprintf( $fmt, @args ) );
        }
    );
    $ffi->attach( SDL_LogResetPriorities => [] );
    $ffi->attach( SDL_LogSetAllPriority  => ['SDL_LogPriority'] );
    $ffi->attach( SDL_LogSetPriority     => [ 'SDL_LOG_CATEGORY', 'SDL_LogPriority' ] );
    $ffi->attach( SDL_LogGetPriority     => ['SDL_LOG_CATEGORY'] => 'SDL_LogPriority' );
    $ffi->type( '(opaque, int, int, string)->void' => 'SDL_LogOutputFunction' );
    $ffi->attach(
        SDL_LogSetOutputFunction => [ 'SDL_LogOutputFunction', 'opaque' ],
        sub ( $inner, $callback, $userdata = {} ) {
            my $closure = $ffi->closure($callback);
            $closure->sticky;
            $inner->( $closure, $userdata );
        }
    );

    # https://wiki.libsdl.org/CategoryError
    $ffi->attach(
        SDL_SetError => ['string'] => ['int'] => sub ( $inner, $fmt, @args ) {
            $inner->( sprintf( $fmt, @args ) );
        }
    );
    $ffi->attach( SDL_GetError   => [] => 'string' );
    $ffi->attach( SDL_ClearError => [] );

    # Platform and CPU Information
    # https://wiki.libsdl.org/CategoryPlatform
    $ffi->attach( SDL_GetPlatform => [] => 'string' );

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
    FFI::C::StructDef->new(
        $ffi,
        name    => 'SDL_Surface',
        class   => 'SDL2::Surface',
        members => [
            flags     => 'uint32',
            format    => 'opaque',                         # SDL_PixelFormat*
            w         => 'int',
            h         => 'int',
            pitch     => 'int',
            pixels    => 'opaque',                         # void*
            userdata  => 'opaque',                         # void*
            locked    => 'int',
            lock_data => 'opaque',                         # void*
            clip_rect => 'opaque',                         # SDL_Rect
            map       => 'opaque',                         # SDL_BlitMap*
            refcount  => 'int'
        ]
    );

    #FFI::C::StructDef->new(                                # INCOMPLETE
    #    $ffi,
    #    name    => 'SDL_Renderer',
    #    class   => 'SDL2::Renderer',
    #    members => [
    #		magic => 'opaque',
    #		viewport_queued => 'bool'
    #	]
    #);
    # src/render/SDL_sysrender.h
    $ffi->type( 'opaque' => 'SDL_Renderer' );
    $ffi->type( 'opaque' => 'SDL_Texture' );

    #FFI::C::StructDef->new(
    #    $ffi,
    #    name    => 'SDL_Renderer',
    #    class   => 'SDL2::Renderer',
    #    members => [
    #]);
    FFI::C::StructDef->new(
        $ffi,
        name    => 'SDL_Window',
        class   => 'SDL2::Window',
        members => [
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
            windowed              => 'opaque',         # SDL_Rect
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
        ]
    );
    $ffi->attach(
        SDL_CreateWindowAndRenderer => [ 'int', 'int', 'uint32', 'SDL_Window', 'SDL_Renderer' ] =>
            'int'                   => sub (
            $inner, $width, $height, $window_flags,
            $window = SDL2::Window->new,
            $renderer = SDL2::Renderer->new
            ) {
            $inner->( $width, $height, $window_flags, $window, $renderer );
        }
    );
    $ffi->attach(
        SDL_CreateWindow => [ 'string', 'int', 'int', 'int', 'int', 'uint32' ] => 'SDL_Window' );
    $ffi->attach( SDL_GetWindowSurface    => ['SDL_Window'] => 'SDL_Surface' );
    $ffi->attach( SDL_UpdateWindowSurface => ['SDL_Window'] => 'int' );
    $ffi->attach( SDL_DestroyWindow       => ['SDL_Window'] );

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
    #
    sub SDL_WINDOW_FULLSCREEN ()         {0x00000001}
    sub SDL_WINDOW_OPENGL ()             {0x00000002}
    sub SDL_WINDOW_SHOWN ()              {0x00000004}
    sub SDL_WINDOW_HIDDEN ()             {0x00000008}
    sub SDL_WINDOW_BORDERLESS ()         {0x00000010}
    sub SDL_WINDOW_RESIZABLE ()          {0x00000020}
    sub SDL_WINDOW_MINIMIZED ()          {0x00000040}
    sub SDL_WINDOW_MAXIMIZED ()          {0x00000080}
    sub SDL_WINDOW_INPUT_GRABBED ()      {0x00000100}
    sub SDL_WINDOW_INPUT_FOCUS ()        {0x00000200}
    sub SDL_WINDOW_MOUSE_FOCUS ()        {0x00000400}
    sub SDL_WINDOW_FULLSCREEN_DESKTOP () { ( SDL_WINDOW_FULLSCREEN | 0x00001000 ) }
    sub SDL_WINDOW_FOREIGN ()            {0x00000800}
    sub SDL_WINDOW_ALLOW_HIGHDPI ()      {0x00002000}
    sub SDL_WINDOW_MOUSE_CAPTURE ()      {0x00004000}
    sub SDL_WINDOW_ALWAYS_ON_TOP ()      {0x00008000}
    sub SDL_WINDOW_SKIP_TASKBAR ()       {0x00010000}
    sub SDL_WINDOW_UTILITY ()            {0x00020000}
    sub SDL_WINDOW_TOOLTIP ()            {0x00040000}
    sub SDL_WINDOW_POPUP_MENU ()         {0x00080000}
    sub SDL_WINDOW_VULKAN ()             {0x10000000}

    # Macros defined in SDL_render.h
    sub SDL_RENDERER_SOFTWARE ()      {0x00000001}
    sub SDL_RENDERER_ACCELERATED ()   {0x00000002}
    sub SDL_RENDERER_PRESENTVSYNC ()  {0x00000004}
    sub SDL_RENDERER_TARGETTEXTURE () {0x00000008}

    # SDL_TextureAccess
    sub SDL_TEXTUREACCESS_STATIC ()   {0}
    sub SDL_TEXTUREACCESS_STREAMING() {1}
    sub SDL_TEXTUREACCESS_TARGET()    {1}
    #
    $ffi->attach(
        SDL_CreateTexture => [ 'SDL_Renderer', 'uint32', 'int', 'int', 'int' ] => 'SDL_Texture' );

    # Macros defined in SDL.h
    sub SDL_INIT_TIMER ()          {0x00000001}
    sub SDL_INIT_AUDIO ()          {0x00000010}
    sub SDL_INIT_VIDEO ()          {0x00000020}
    sub SDL_INIT_JOYSTICK ()       {0x00000200}
    sub SDL_INIT_HAPTIC ()         {0x00001000}
    sub SDL_INIT_GAMECONTROLLER () {0x00002000}
    sub SDL_INIT_EVENTS ()         {0x00004000}
    sub SDL_INIT_SENSOR ()         {0x00008000}
    sub SDL_INIT_NOPARACHUTE ()    {0x00100000}

    sub SDL_INIT_EVERYTHING () {
        SDL_INIT_TIMER | SDL_INIT_AUDIO | SDL_INIT_VIDEO | SDL_INIT_EVENTS | SDL_INIT_JOYSTICK
            | SDL_INIT_HAPTIC | SDL_INIT_GAMECONTROLLER | SDL_INIT_SENSOR;
    }

    # SDL_rect.h
    FFI::C::StructDef->new(
        $ffi,
        name    => 'SDL_Point',
        class   => 'SDL2::Point',
        members => [ x => 'int', y => 'int', ]
    );
    FFI::C::StructDef->new(
        $ffi,
        name    => 'SDL_FPoint',
        class   => 'SDL2::FPoint',
        members => [ x => 'float', y => 'float', ]
    );
    FFI::C::StructDef->new(
        $ffi,
        name    => 'SDL_Rect',
        class   => 'SDL2::Rect',
        members => [ x => 'int', y => 'int', w => 'int', h => 'int' ]
    );
    FFI::C::StructDef->new(
        $ffi,
        name    => 'SDL_FRect',
        class   => 'SDL2::FRect',
        members => [ x => 'float', y => 'float', w => 'float', h => 'float', ]
    );

    # https://wiki.libsdl.org/CategoryRender
    $ffi->attach( SDL_CreateRenderer  => [ 'SDL_Window', 'int', 'uint32' ] => 'SDL_Renderer' );
    $ffi->attach( SDL_DestroyRenderer => ['SDL_Renderer'] );
    $ffi->attach(
        SDL_SetRenderDrawColor => [ 'SDL_Renderer', 'uint8', 'uint8', 'uint8', 'uint8' ] => 'int' );
    $ffi->attach( SDL_RenderClear     => ['SDL_Renderer']               => 'int' );
    $ffi->attach( SDL_RenderFillRect  => [ 'SDL_Renderer', 'SDL_Rect' ] => 'int' );
    $ffi->attach( SDL_RenderPresent   => ['SDL_Renderer'] );
    $ffi->attach( SDL_RenderDrawLine  => [ 'SDL_Renderer', 'int', 'int', 'int', 'int' ] => 'int' );
    $ffi->attach( SDL_RenderDrawLines => [ 'SDL_Renderer', 'opaque[]', 'int' ]          => 'int' );
    $ffi->attach( SDL_RenderDrawRect  => [ 'SDL_Renderer', 'SDL_Rect' ]                 => 'int' );

    # https://wiki.libsdl.org/CategoryTimer
    $ffi->attach( SDL_Delay => ['uint32'] );

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
    $ffi->attach(
        SDL_MapRGB => [ 'SDL_PixelFormat', 'uint8', 'uint8', 'uint8' ] => 'uint32' =>
            sub ( $inner, $format, $r, $g, $b ) {
            $format = $ffi->cast( 'opaque', 'SDL_PixelFormat', $format ) if !ref $format;
            $inner->( $format, $r, $g, $b );
        }
    );

    # https://wiki.libsdl.org/CategorySurface
    $ffi->attach(
        SDL_FillRect => [ 'SDL_Surface', 'opaque', 'uint32' ] => 'int' =>
            sub ( $inner, $dst, $rect, $color ) {

            #$dst //= SDL2::Surface->new;
            #$dst = $ffi->cast( 'opaque', 'SDL_Surface', $dst ) if !ref $dst;
            #$rect //= SDL2::Rect->new( );
            #$rect = $ffi->cast( 'opaque', 'SDL_Rect', $rect ) if !ref $rect;
            $inner->( $dst, $rect, $color );
        }
    );

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
            ) || (
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

    # Export symbols!
    our @EXPORT =    # A start;
        grep {/^SDL_/} keys %SDL2::;
}
