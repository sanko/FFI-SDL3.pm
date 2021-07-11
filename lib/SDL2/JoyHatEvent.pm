package SDL2::JoyHatEvent {
    use SDL2::Utils;
    has
        type      => 'uint32',
        timestamp => 'uint32',
        which     => 'opaque',    # SDL_JoystickID
        hat       => 'uint8',
        value     => 'uint8',
        padding1  => 'uint8',
        padding2  => 'uint8';

=encoding utf-8

=head1 NAME

SDL2::JoyHatEvent - Joystick hat position change event structure

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION
 

=head1 Fields

=over

=item C<type> - C<SDL_JOYHATMOTION>

=item C<timestamp> - In milliseconds, populated using L<< C<SDL_GetTicks( )>|SDL2::FFI/C<SDL_GetTicks( )> >>

=item C<which> - The joystick instance id

=item C<hat> - The joystick trackball index

=item C<value> - The hat position value such as: C<SDL_HAT_LEFTUP>, C<SDL_HAT_UP>, C<SDL_HAT_RIGHTUP>, C<SDL_HAT_LEFT>, C<SDL_HAT_CENTERED>, C<SDL_HAT_RIGHT>, C<SDL_HAT_LEFTDOWN>, C<SDL_HAT_DOWN>, or C<SDL_HAT_RIGHTDOWN>

Note that zero means the POV is centered.

=item C<padding1>

=item C<padding2>

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords


=end stopwords

=cut

};
1;