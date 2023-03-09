package SDL3::atomic_t {
    use SDL3::Utils;
    has value => 'int';

=encoding utf-8

=head1 NAME

SDL3::atomic_t - A type representing an atomic integer value

=head1 SYNOPSIS

    use SDL3 qw[:all];

=head1 DESCRIPTION

SDL3::atomic_t is a struct so people don't accidentally use numeric operations
on it.

=head1 Fields

=over

=item C<value>

=back


=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

struct

=end stopwords

=cut

};
1
