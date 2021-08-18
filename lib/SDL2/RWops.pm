package SDL2::RWops {
    use SDL2::Utils;
    has type => 'uint32';

    #    union
    #    {
##if defined(__ANDROID__)
    #        struct
    #        {
    #            void *asset;
    #        } androidio;
##elif defined(__WIN32__)
    #        struct
    #        {
    #            SDL_bool append;
    #            void *h;
    #            struct
    #            {
    #                void *data;
    #                size_t size;
    #                size_t left;
    #            } buffer;
    #        } windowsio;
##elif defined(__VITA__)
    #        struct
    #        {
    #            int h;
    #            struct
    #            {
    #                void *data;
    #                size_t size;
    #                size_t left;
    #            } buffer;
    #        } vitaio;
##endif
    #
##ifdef HAVE_STDIO_H         struct         {             SDL_bool autoclose;
    #         FILE *fp;         } stdio; #endif         struct         {
    #Uint8 *base;             Uint8 *here;             Uint8 *stop;         } mem;
    #      struct         {             void *data1;             void *data2;
    # } unknown;     } hidden;
    #
    #} SDL_RWops;

=encoding utf-8

=head1 NAME

SDL2::RWops - Very basic read/write operation structure

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION


=head1 Fields

=over

=item C<type>

=back

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
