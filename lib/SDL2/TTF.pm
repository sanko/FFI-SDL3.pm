package SDL2::TTF 0.01 {
    use strict;
    use warnings;
    use experimental 'signatures';
    use SDL2::Utils;
    #
    sub _ver() {
        CORE::state $version //= SDL2::FFI::TTF_Linked_Version();
        $version;
    }
    define ttf => [
        [ SDL_TTF_MAJOR_VERSION => sub () { SDL2::TTF::_ver()->major } ],
        [ SDL_TTF_MINOR_VERSION => sub () { SDL2::TTF::_ver()->minor } ],
        [ SDL_TTF_PATCHLEVEL    => sub () { SDL2::TTF::_ver()->patch } ],
        [   SDL_TTF_VERSION => sub ( $version = SDL2::Version->new() ) {
                my $ver = SDL2::FFI::TTF_Linked_Version();
                $version->major( $ver->major );
                $version->minor( $ver->minor );
                $version->patch( $ver->patch );
            }
        ],
        [   SDL_TTF_COMPILEDVERSION => sub () {
                SDL2::FFI::SDL_VERSIONNUM(
                    SDL2::FFI::SDL_TTF_MAJOR_VERSION(),
                    SDL2::FFI::SDL_TTF_MINOR_VERSION(),
                    SDL2::FFI::SDL_TTF_PATCHLEVEL()
                );
            }
        ],
        [   SDL_TTF_VERSION_ATLEAST => sub ( $X, $Y, $Z ) {
                ( SDL2::FFI::SDL_TTF_COMPILEDVERSION() >= SDL2::FFI::SDL_VERSIONNUM( $X, $Y, $Z ) )
            }
        ]
    ];
    attach ttf => { TTF_Linked_Version => [ [], 'SDL_Version' ] };
    define ttf => [ [ UNICODE_BOM_NATIVE => 0xFEFF ], [ UNICODE_BOM_SWAPPED => 0xFFFE ] ];

    package SDL2::TTF::Font {
        use SDL2::Utils;
        our $TYPE = has();
    };
    attach ttf => {
        TTF_Init    => [ [], 'int' ],
        TTF_WasInit => [ [], 'int' ],
        TTF_Quit    => [ [] ],
        #
        TTF_OpenFont        => [ [ 'string', 'int' ],                   'SDL_TTF_Font' ],
        TTF_OpenFontRW      => [ [ 'SDL_RWops', 'int', 'int' ],         'SDL_TTF_Font' ],
        TTF_OpenFontIndex   => [ [ 'string', 'int', 'long' ],           'SDL_TTF_Font' ],
        TTF_OpenFontIndexRW => [ [ 'SDL_RWops', 'int', 'int', 'long' ], 'SDL_TTF_Font' ],
        TTF_CloseFont       => [ ['SDL_TTF_Font'] ],
        #
        TTF_ByteSwappedUNICODE => [ ['int'] ],
        #
        TTF_RenderText_Solid   => [ [ 'SDL_TTF_Font', 'string', 'SDL_Color' ], 'SDL_Surface' ],
        TTF_SetFontStyle       => [ [ 'SDL_TTF_Font', 'int' ] ],
        TTF_SetFontOutline     => [ [ 'SDL_TTF_Font', 'int' ] ],
        TTF_SetFontKerning     => [ [ 'SDL_TTF_Font', 'int' ] ],
        TTF_SetFontHinting     => [ [ 'SDL_TTF_Font', 'int' ] ],
        TTF_RenderGlyph_Shaded =>
            [ [ 'SDL_TTF_Font', 'uint16', 'SDL_Color', 'SDL_Color' ], 'SDL_Surface' ],
        TTF_RenderText_Shaded =>
            [ [ 'SDL_TTF_Font', 'string', 'SDL_Color', 'SDL_Color' ], 'SDL_Surface' ],
        TTF_FontHeight => [ ['SDL_TTF_Font'], 'int' ],
        #
    };
    define ttf => [
        [ TTF_SetError               => \&SDL2::FFI::SDL_SetError ],
        [ TTF_GetError               => \&SDL2::FFI::SDL_GetError ],
        [ TTF_STYLE_NORMAL           => 0x00 ],
        [ TTF_STYLE_BOLD             => 0x01 ],
        [ TTF_STYLE_ITALIC           => 0x02 ],
        [ TTF_STYLE_UNDERLINE        => 0x04 ],
        [ TTF_STYLE_STRIKETHROUGH    => 0x08 ],
        [ TTF_HINTING_NORMAL         => 0 ],
        [ TTF_HINTING_LIGHT          => 1 ],
        [ TTF_HINTING_MONO           => 2 ],
        [ TTF_HINTING_NONE           => 3 ],
        [ TTF_HINTING_LIGHT_SUBPIXEL => 4 ],
    ];

=encoding utf-8

=head1 NAME

SDL2::TTF - TTF Image Loading Library

=head1 SYNOPSIS

    use SDL2 qw[:ttf];

=head1 DESCRIPTION

This extension to SDL2 can load fonts from TrueType font files, normally ending
in C<.ttf>, though some C<.fon> files are also valid for use.

=head1 General Functions

These may be imported by name or with the C<:ttf> tag.

=head2 C<SDL_TTF_VERSION( ... )>

Macro to determine compile-time version of the SDL_ttf library.

    my $compile_version = SDL2::Version->new;
    SDL_TTF_VERSION($compile_version);
    printf "compiled with SDL_ttf version: %d.%d.%d\n", $compile_version->major,
        $compile_version->minor, $compile_version->patch;

Expected parameters include:

=over

=item C<x> - a pointer to a L<SDL2::Version> struct to initialize

=back

=head2 C<SDL_IMAGE_VERSION_ATLEAST( ... )>

Evaluates to true if compiled with SDL at least C<major.minor.patch>.

	if ( SDL_TTF_VERSION_ATLEAST( 2, 0, 5 ) ) {
		# Some feature that requires 2.0.5+
	}

Expected parameters include:

=over

=item C<major>

=item C<minor>

=item C<patch>

=back

=head2 C<TTF_Linked_Version( )>

This function gets the version of the dynamically linked SDL_image library.

    my $link_version = TTF_Linked_Version();
    printf "running with SDL_ttf version: %d.%d.%d\n",
        $link_version->major, $link_version->minor, $link_version->patch;

It should NOT be used to fill a version structure, instead you should use the
L<< C<SDL_TTF_VERSION( ... )>|/C<SDL_TTF_VERSION( ... )> >> macro.

Returns a L<SDL2::Version> object.

=head2 C<TTF_Init( )>

Initialize the truetype font API.

    if ( TTF_Init( ) == -1 ) {
        printf( "could not initialize sdl_ttf: %s\n", TTF_GetError() );
        return !1;
    }

This must be called before using other functions in this library, except L<<
C<TTF_WasInit( )>|/C<TTF_WasInit( )> >>. SDL does not have to be initialized
before this call.

Returns C<0> on success or C<-1> on failure.

=head2 C<TTF_WasInit( )>

Query the initialization status of the truetype font API.

    if ( !TTF_WasInit() && TTF_Init() == -1 ) {
        printf "TTF_Init: %s\n", TTF_GetError();
        exit 1;
    }

You may, of course, use this before TTF_Init to avoid initializing twice in a
row. Or use this to determine if you need to call TTF_Quit.

Returns C<1> if already initialized, C<0> if not initialized.

=head2 C<TTF_Quit( )>

Shutdown and cleanup the truetype font API.

	TTF_Quit( );

After calling this, the C<SDL_ttf> functions should not be used, excepting L<<
C<TTF_WasInit( )>|/C<TTF_WasInit( )> >>. You may, of course, use L<<
C<TTF_Init( )>|/C<TTF_Init( )> >> to use the functionality again.

=head2 C<TTF_SetError( ... )>

This is really a defined macro for C<SDL_SetError( ... )>, which sets the error
string which may be fetched with L<< C<TTF_GetError( )>|/C<TTF_GetError( )> >>
(or C<SDL_GetError( )>).

    sub myfunc ($i) {
        TTF_SetError( 'myfunc is not implemented! %d was passed in.', $i );
        return -1;
    }

=head2 C<TTF_GetError( )>

This is really a defined macro for C<SDL_GetError( )>.

	printf 'Oh My Goodness, an error: %s', TTF_GetError();

Use this to tell the user what happened when an error status has been returned
from an C<SDL_ttf> function call.

Returns the last error set by L<< C<TTF_SetError( ... )>|/C<TTF_SetError( ...
)> >> (or C<SDL_SetError( )>) as a string.

=head1 Management Functions

These functions deal with loading and freeing a C<TTF_Font>.

=head2 C<TTF_OpenFont( ... )>

Load C<file> for use as a font, at C<ptsize> size.

    # load font.ttf at size 16 into font
    my $font = TTF_OpenFont( 'font.ttf', 16 );
    if ( !$font ) {
        printf( "TTF_OpenFont: %s\n", TTF_GetError() );
        # handle error
    }

This is actually C<TTF_OpenFontIndex( $file, $ptsize, 0 )>. This can load TTF
and FON files.

Expected parameters include:

=over

=item C<file> - file name to load font from

=item C<ptsize> - point size (based on 72 DPI) to load font as; this basically translates to pixel height

=back

Returns a new L<SDL2::TTF::Font> structure on success.

=head2 C<TTF_OpenFontRW( ... )>

Load C<src> for use as a font, at C<ptsize> size.

    # load font.ttf at size 16 into font
    my $font = TTF_OpenFontRW( SDL_RWFromFile( 'font.ttf', 'rb' ), 1, 16 );
    if ( !$font ) {
        printf( "TTF_OpenFontRW: %s\n", TTF_GetError() );

        # handle error
    }

This is actually C<TTF_OpenFontIndexRW( $src, $freesrc, $ptsize, 0 )>. This can
load TTF and FON formats.

Expected parameters include:

=over

=item C<src> - the source L<SDL::RWops>

=item C<freesrc> - a non-zero value means it will automatically close and free the C<src> for you after it finishes using the C<src>, even if a noncritical error occurred

=item C<ptsize> - point size (based on 72 DPI) to load font as; this basically translates to pixel height

=back

Returns a new L<SDL2::TTF::Font> structure on success.

=head2 C<TTF_OpenFontIndex( ... )>

Load C<file>, face C<index>, for use as a font, at C<ptsize> size.

    # load font.ttf at size 16 into font
    my $font = TTF_OpenFontIndex( 'font.ttf', 16, 0 );
    if ( !$font ) {
        printf( "TTF_OpenFontIndex: %s\n", TTF_GetError() );

        # handle error
    }

This is actually C<TTF_OpenFontIndexRW( SDL_RWFromFile($src, 'rb'), $freesrc,
$ptsize, $index )>.

Expected parameters include:

=over

=item C<src> - the source L<SDL::RWops>

=item C<ptsize> - point size (based on 72 DPI) to load font as; this basically translates to pixel height

=item C<index> - choose a font face from a file containing multiple font faces

=back

Returns a new L<SDL2::TTF::Font> structure on success.

=head2 C<TTF_OpenFontIndexRW( ... )>

Load C<src>, face C<index>, for use as a font, at C<ptsize> size.

	# load font.ttf at size 16 into font
    my $font = TTF_OpenFontIndexRW( SDL_RWFromFile( 'font.ttf', 'rb' ), 1, 16, 0 );
    if ( !$font ) {
        printf( "TTF_OpenFontIndexRW: %s\n", TTF_GetError() );

        # handle error
    }

Expected parameters include:

=over

=item C<src> - the source L<SDL::RWops>

=item C<freesrc> - a non-zero value means it will automatically close and free the C<src> for you after it finishes using the C<src>, even if a noncritical error occurred

=item C<ptsize> - point size (based on 72 DPI) to load font as; this basically translates to pixel height

=item C<index> - choose a font face from a file containing multiple font faces

=back

Returns a new L<SDL2::TTF::Font> structure on success.

=head2 C<TTF_CloseFont( ... )>

Free the memory used by C<font>, and free C<font> itself as well. Do not use
C<font> after this without loading a new font to it.

	# free the font
	TTF_CloseFont( $font );
	undef $font; # to be safe...

Expected parameters include:

=over

=item C<font> - pointer to the L<TTF_Font> to free

=back

=head1 Attribute Functions

These functions deal with L<SDL2::TTF::Font> and global attributes.

=head2 C<TTF_ByteSwappedUNICODE( ... )>

This function tells C<SDL_ttf> whether UNICODE (Uint16 per character) text is
generally byteswapped. A B<UNICODE_BOM_NATIVE> or B<UNICODE_BOM_SWAPPED>
character in a string will temporarily override this setting for the remainder
of that string, however this setting will be restored for the next one. The
default mode is non-swapped, native endianness of the CPU.

	# Turn on byte swapping for UNICODE text
	TTF_ByteSwappedUNICODE( 1 );

Expected parameters include:

=over

=item C<swapped>

=over

=item - if non-zero then UNICODE data is byte swapped relative to the CPU's native endianness

=item - if zero, then do not swap UNICODE data, use the CPU's native endianness

=back

=back









































































=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

truetype byteswapped

=end stopwords

=cut

};
1;
