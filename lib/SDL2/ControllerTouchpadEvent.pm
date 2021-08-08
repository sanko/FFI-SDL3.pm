package SDL2::ControllerTouchpadEvent {
    use SDL2::Utils;
    has
        type      => 'uint32',
        timestamp => 'uint32',
        which     => 'SDL_JoystickID',
        touchpad  => 'sint32',
        finger    => 'sint32',
        x         => 'float',
        y         => 'float',
        pressure  => 'float';

=encoding utf-8

=head1 NAME

SDL2::ControllerTouchpadEvent - Game controller touchpad event structure

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION



=head1 Fields

=over

=item C<type> - C<SDL_CONTROLLERTOUCHPADDOWN> or C<SDL_CONTROLLERTOUCHPADMOTION> or C<SDL_CONTROLLERTOUCHPADUP>

=item C<timestamp> - In milliseconds, populated using L<< C<SDL_GetTicks( )>|SDL2::FFI/C<SDL_GetTicks( )> >>

=item C<which> - The joystick instance id

=item C<touchpad> - The index of the touchpad

=item C<finger> - The index of the finger on the touchpad

=item C<x> - Normalized in the range C<0...1> with C<0> being on the left

=item C<y> - Normalized in the range C<0...1> with C<0> being at the top

=item C<pressure> - Normalized in the range C<0...1>

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

touchpad

=end stopwords

=cut

};
1;