requires 'perl', '5.02000';
requires 'strictures', 2;
requires 'FFI::Platypus';
requires 'FFI::Platypus::Lang::CPP';
requires 'FFI::C';
requires 'File::ShareDir';
requires 'File::Spec::Functions';
requires 'Exporter::Tiny';

requires 'Data::Dump';

on test => sub {
    requires 'Test::More', '0.98';
};

on configure => sub {
	requires 'Devel::CheckBin';
    requires 'Module::Build::Tiny', '0.039';
};