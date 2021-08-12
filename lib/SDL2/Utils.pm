package SDL2::Utils {

    # FFI utilities
    use strictures 2;
    use experimental 'signatures';
    use base 'Exporter::Tiny';
    our @EXPORT = qw[attach define deprecate has enum ffi is];
    use Alien::libsdl2;
    use FFI::CheckLib;
    use FFI::Platypus 1.46;
    use FFI::Platypus::Memory qw[malloc strcpy free];
    use FFI::C;
    use FFI::C::Def;
    use FFI::C::ArrayDef;
    use FFI::C::StructDef;
    use FFI::C::UnionDef;
    use FFI::Platypus::Closure;
    use File::Spec::Functions qw[catdir canonpath rel2abs];
    use Path::Tiny qw[path];
    use File::Share qw[dist_dir];

    sub deprecate ($str) {
        warnings::warn( 'deprecated', $str ) if warnings::enabled('deprecated');
    }

    #ddx( Alien::libsdl2->dynamic_libs );
    sub ffi () {
        CORE::state $ffi;
        if ( !defined $ffi ) {
            use FFI::Build;
            use FFI::Build::File::C;
            my $lib = undef;
            if (1) {
                my $root = path(__FILE__)->absolute->parent(2);
                my $dir  = eval { dist_dir('SDL2-FFI') };
                $dir //= $root->child('share');
                #warn $dir;
                my $build = FFI::Build->new(
                    'bundle',
                    dir     => $dir,
                    alien   => ['Alien::libsdl2'],
                    source  => ["ffi/*.c"],
                    libs    => [ Alien::libsdl2->libs_static() ],
                    verbose => 2
                );
                $lib
                    = -f $build->file->path &&
                    -f $root->child('ffi/sdl2.c') &&
                    [ stat $build->file->path ]->[9]
                    >= [ stat( $root->child('ffi/sdl2.c') ) ]->[9] ? $build->file : $build->build;
            }
            $ffi = FFI::Platypus->new(
                api          => 2,
                experimental => 2,
                lib          => [ Alien::libsdl2->dynamic_libs, $lib ]
            );
            FFI::C->ffi($ffi);
            $lib // $ffi->bundle;
        }
        $ffi;
    }

    sub enum (%args) {
        my ($package) = caller();
        $package = 'SDL2::FFI';
        for my $tag ( keys %args ) {

            #use Data::Dump;
            #ddx $args{$tag} if $tag eq 'WindowShapeMode';
            use Data::Dump;

            #ddx $args{$tag};
            #ddx @{$args{$tag}};
            #my $enum =
            #FFI::C->enum( $tag => $args{$tag}, { package => $package } );
            #ffi->load_custom_type('::Enum', $tag => { package => $package } => [$args{$tag}] );
            FFI::C->enum( $tag => $args{$tag}, { package => $package } );

            #ffi->load_custom_type(
            #    '::Enum',
            #    $tag,
            #    {ref => 'int', package => $package },
            #    @{$args{$tag}}
            #  #{ rev => 'int', package => 'Foo', prefix => 'FOO_' },
            #);
            my $_tag = $tag;                                     # Simple rules:
            $_tag =~ s[^SDL_][];                                 # No SDL_XXXXX
            $_tag = lcfirst $_tag unless $_tag =~ m[^.[A-Z]];    # Save GLattr

            #ddx $enum if  $tag eq 'WindowShapeMode';
            #            warn $_tag if $tag eq 'WindowShapeMode';
            push @{ $SDL2::FFI::EXPORT_TAGS{$_tag} },
                sort map { ref $_ ? ref $_ eq 'CODE' ? $_->() : $_->[0] : $_ } @{ $args{$tag} };
        }
    }

    sub attach (%args) {
        my ($package) = caller();
        $package = 'SDL2::FFI';
        for my $tag ( sort keys %args ) {
            for my $func ( sort keys %{ $args{$tag} } ) {

                #warn sprintf 'ffi->attach( %s => %s);', $func,
                #    Data::Dump::dump( @{ $args{$tag}{$func} } )
                #    if ref $args{$tag}{$func}[1] && ref $args{$tag}{$func}[1] eq 'ARRAY';
                my $perl = $func;
                $perl =~ s[^Bundle_][];
                ffi->attach( [ $func => $package . '::' . $perl ] => @{ $args{$tag}{$func} } );
                push @{ $SDL2::FFI::EXPORT_TAGS{$tag} }, $perl;
            }
        }
    }
    my %is;

    sub is ($is) {
        my ($package) = caller;
        $is{$package} = $is;
    }
    sub get_is ($package) { $is{$package} // '' }

    sub has (%args) {    # Should be hash-like
        my ($package) = caller;
        my $type = $package;
        $type =~ s[^SDL2::][SDL_];
        $type =~ s[::][_]g;

        #$class =~ s[^SDL_(.+)$]['SDL2::' . ucfirst $1]e;
        #warn sprintf '%-20s => %-20s%s', $name, $class, (
        #   -f sub ($package) { $package =~ m[::(.+)]; './lib/SDL2/' . $1 . '.pod' }
        #        ->($class) ? '' : ' (undocumented)'
        #);
        my @args = (
            ffi,
            name     => $type,       # C type
            class    => $package,    # package
            nullable => 1,
            members  => \@_          # Keep order rather than use %args
        );
        get_is($package) eq 'Union' ? FFI::C::UnionDef->new(@args) : FFI::C::StructDef->new(@args);
    }

    sub define (%args) {
        my ($package) = caller();
        $package = 'SDL2::FFI';
        for my $tag ( keys %args ) {

            #print $_->[0] . ' ' for sort { $a->[0] cmp $b->[0] } @{ $Defines{$tag} };
            #no strict 'refs';
            ref $_->[1] eq 'CODE' ?

                #constant->import( $package . '::' .$_->[0] => $_->[1]->() ) : #
                sub { no strict 'refs'; *{ $package . '::' . $_->[0] } = $_->[1] }
                ->() :
                constant->import( $package . '::' . $_->[0] => $_->[1] )
                for @{ $args{$tag} };
            push @{ $SDL2::FFI::EXPORT_TAGS{$tag} },
                sort map { ref $_ ? $_->[0] : $_ } @{ $args{$tag} };
        }
    }
};
1;
