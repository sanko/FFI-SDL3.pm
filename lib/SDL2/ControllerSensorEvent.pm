package SDL2::ControllerSensorEvent {
    use SDL2::Utils;
    has
        type      => 'uint32',
        timestamp => 'uint32',
        which     => 'SDL_JoystickID',
        sensor    => 'sint32',
        data      => 'float[3]';

=encoding utf-8

=head1 NAME

SDL2::ControllerSensorEvent - Game controller touchpad event structure

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION



=head1 Fields

=over

=item C<type> - C<SDL_CONTROLLERSENSORUPDATE>

=item C<timestamp> - In milliseconds, populated using L<< C<SDL_GetTicks( )>|SDL2::FFI/C<SDL_GetTicks( )> >>

=item C<which> - The joystick instance id

=item C<sensor> - The type of the sneos, one of the values of C<SDL_SensorType>

=item C<data> - Up to 2 values from the sensor, as defined in C<SDL_sensor.h>

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords


=end stopwords

=cut

};
1;
