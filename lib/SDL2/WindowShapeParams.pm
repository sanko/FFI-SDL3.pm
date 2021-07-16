package SDL2::WindowShapeParams {
    use SDL2::Utils;
    use FFI::C::UnionDef;
    FFI::C::UnionDef->new( ffi,
        name    => 'SDL_WindowShapeParams',
        class   => 'SDL2::WindowShapeParams',
        members => [ binarizationCutoff => 'uint8', colorKey => 'SDL_Color' ]
    );

=encoding utf-8

=head1 NAME

SDL2::WindowShapeParams - A union containing parameters for shaped windows

=head1 SYNOPSIS

    use SDL2 qw[:all];

=head1 DESCRIPTION

SDL2::WindowShapeParams is a union.

=head2 Fields

=over

=item C<binarizationCutoff> - A cutoff alpha value for binarization of the window shape's alpha channel

=item C<colorKey> - L<SDL2::Color>

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

binarization

=end stopwords

=cut

};
1;
