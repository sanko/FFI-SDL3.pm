package SDL2::MouseMotionEvent {
    use SDL2::Utils;
    has
        type      => 'uint32',
        timestamp => 'uint32',
        windowId  => 'uint32',
        which     => 'uint32',
        state     => 'uint32',
        x         => 'sint32',
        y         => 'sint32',
        xrel      => 'sint32',
        yrel      => 'sint32';

=encoding utf-8

=head1 NAME

SDL2::MouseMotionEvent - Mouse motion event structure

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION
 

=head1 Fields

=over

=item C<type> - C<SDL_MOUSEMOTION>

=item C<timestamp> - In milliseconds, populated using L<< C<SDL_GetTicks( )>|SDL2::FFI/C<SDL_GetTicks( )> >>

=item C<windowID> - The window with mouse focus, if any

=item C<which> - The mouse instance id, or C<SDL_TOUCH_MOUSEID>

=item C<state> - The current button state

=item C<x> - X coordinate, relative to window

=item C<y> - Y coordinate, relative to window

=item C<xrel> - The relative motion in the X direction

=item C<yrel> - The relative motion in the Y direction

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords


=end stopwords

=cut

};
1;