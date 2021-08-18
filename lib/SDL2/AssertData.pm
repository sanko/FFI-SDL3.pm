package SDL2::AssertData {
    use SDL2::Utils;
    has
        always_ignore => 'int',
        trigger_count => 'uint',
        _condition    => 'opaque',    # string
        _filename     => 'opaque',    # string
        linenum       => 'int',
        _function     => 'opaque',    # string
        _next         => 'opaque';    # const struct SDL_AssertData *next
    ffi->attach_cast( '_cast' => 'opaque' => 'SDL_AssertData' );

    sub next {                        # TODO: Broken.
        my ($self) = @_;
        defined $self->_next ? _cast( $self->_next ) : undef;
    }

    sub condition {
        defined $_[1] ? $_[0]->_condition( ffi->cast( 'string', 'opaque', $_[1] ) ) :
            ffi->cast( 'opaque', 'string', $_[0]->_condition );
    }

    sub filename {
        ffi->cast( 'opaque', 'string', $_[0]->_filename );
    }

    sub function {
        ffi->cast( 'opaque', 'string', $_[0]->_function );
    }
};
