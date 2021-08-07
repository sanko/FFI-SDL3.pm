package SDL2::SysWMmsg
{ # https://github.com/libsdl-org/SDL/blob/37d4f003b76da3e3c91ed99da0350501d2830c79/include/SDL_syswm.h#L152
    use SDL2::Utils;

    package SDL2::Win {
        use SDL2::Utils;
        has
            HWND   => 'uint32',
            msg    => 'uint32',
            wParam => 'uint32',
            lParam => 'uint32';
    };

    package SDL2::X11 {
        use SDL2::Utils;
        has event => 'opaque';    # XEvent
    };

    package SDL2::DFB {
        use SDL2::Utils;
        has event => 'opaque';    # DFBEvent
    };

    package SDL2::Cocoa {
        use SDL2::Utils;
        has dummy => 'int';
    };

    package SDL2::UIKit {
        use SDL2::Utils;
        has dummy => 'int';
    };

    package SDL2::Vivante {
        use SDL2::Utils;
        has dummy => 'int';
    };

    package SDL2::OS2 {
        use SDL2::Utils;
        has
            fFrame => 'bool',
            hwnd   => 'uint32',
            msg    => 'ulong',
            mp1    => 'uint32',
            mp2    => 'uint32';
    };

    package SDL2::msg {
        use SDL2::Utils;
        is 'Union';
        has
            event => 'SDL_X11',
            dummy => 'int';
    };
    has
        version   => 'SDL_version',
        subsystem => 'SDL_SYSWM_TYPE',
        #
        msg => 'SDL_msg',
        #
        ;    # contents depends on driver, platform, etc.

=begin :todo

    union
    {
#if defined(SDL_VIDEO_DRIVER_WINDOWS)
        struct {
            HWND hwnd;                  /**< The window for the message */
            UINT msg;                   /**< The type of message */
            WPARAM wParam;              /**< WORD message parameter */
            LPARAM lParam;              /**< LONG message parameter */
        } win;
#endif
#if defined(SDL_VIDEO_DRIVER_X11)
        struct {
            XEvent event;
        } x11;
#endif
#if defined(SDL_VIDEO_DRIVER_DIRECTFB)
        struct {
            DFBEvent event;
        } dfb;
#endif
#if defined(SDL_VIDEO_DRIVER_COCOA)
        struct
        {
            /* Latest version of Xcode clang complains about empty structs in C v. C++:
                 error: empty struct has size 0 in C, size 1 in C++
             */
            int dummy;
            /* No Cocoa window events yet */
        } cocoa;
#endif
#if defined(SDL_VIDEO_DRIVER_UIKIT)
        struct
        {
            int dummy;
            /* No UIKit window events yet */
        } uikit;
#endif
#if defined(SDL_VIDEO_DRIVER_VIVANTE)
        struct
        {
            int dummy;
            /* No Vivante window events yet */
        } vivante;
#endif
#if defined(SDL_VIDEO_DRIVER_OS2)
        struct
        {
            BOOL fFrame;                /**< TRUE if hwnd is a frame window */
            HWND hwnd;                  /**< The window receiving the message */
            ULONG msg;                  /**< The message identifier */
            MPARAM mp1;                 /**< The first first message parameter */
            MPARAM mp2;                 /**< The second first message parameter */
        } os2;
#endif
        /* Can't have an empty union */
        int dummy;
    } msg;
};
=end :todo

=encoding utf-8

=head1 NAME

SDL2::SysWMmsg - Driver dependant data

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION


=head1 Fields

Fields in this structure depend on the driver.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords


=end stopwords

=cut

};
1;
