package SDL2::Finger {
    use SDL2::Utils;
    ffi->type( 'sint64' => 'SDL_FingerID' );
    has
        id       => 'SDL_FingerID',
        x        => 'float',
        y        => 'float',
        pressure => 'float';

=encoding utf-8

=head1 NAME

SDL2::Finger - The Structure that defines a touch point

=head1 SYNOPSIS

    use SDL2 qw[:all];

=head1 DESCRIPTION

SDL2::Finger

=head1 Fields

=over

=item C<finger>

=item C<x>

=item C<y>

=item C<pressure>

=back


=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

=end stopwords

=cut

};
1
