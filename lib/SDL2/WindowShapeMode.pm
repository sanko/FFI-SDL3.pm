package SDL2::WindowShapeMode {
    use SDL2::Utils;
    use SDL2::WindowShapeParams;
    has
        mode       => 'WindowShapeMode',
        parameters => 'SDL_WindowShapeParams';

=encoding utf-8

=head1 NAME

SDL2::WindowShapeMode - SDL Window-shaper union

=head1 SYNOPSIS

    use SDL2 qw[:all];

=head1 DESCRIPTION

SDL2::WindowShaper is a struct that tags the SDL_WindowShapeParams union with
an enum describing the type of its contents.

=head2 Fields

=over

=item C<mode> - The mode of these window-shape parameters

=item C<parameters> - Window-shape parameters

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

=end stopwords

=cut

};
1;
