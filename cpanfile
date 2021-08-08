requires 'perl', '5.02000';
requires 'strictures', 2;
requires 'FFI::Platypus', '1.55';
requires 'FFI::C';
requires 'File::ShareDir';
requires 'File::Spec::Functions';
requires 'Exporter::Tiny';
requires 'Alien::libsdl2', '1.03';

requires 'Data::Dump';

on test => sub {
    requires 'Test::More', '0.98';
    requires 'Test2::V0';
};

on configure => sub {
    requires 'Devel::CheckBin';
    requires 'Module::Build::Tiny', '0.039';
    requires 'Alien::libsdl2', '1.03';
};

on development => sub {
    requires 'Software::License::Artistic_2_0'
};