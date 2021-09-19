requires 'perl',          '5.02000';
requires 'strictures',    2;
requires 'FFI::Platypus', '1.55';
requires 'FFI::C';
requires 'File::Spec::Functions';
requires 'Exporter::Tiny';
requires 'FFI::Build', '1.04';
requires 'Path::Tiny';
requires 'File::Share';
requires 'Try::Tiny';
recommends 'B::Deparse';
requires 'Devel::CheckBin';
requires 'strictures', 2;
requires 'HTTP::Tiny';
requires 'Path::Tiny';
requires 'FFI::ExtractSymbols';
requires 'Data::Dump';
on test => sub {
    requires 'Test::More', '0.98';
    requires 'Test2::V0';
    requires 'Test::NeedsDisplay', '1.07';
};
on configure => sub {
    requires 'Devel::CheckBin';
    requires 'Module::Build::Tiny', '0.039';
    requires 'strictures',          2;
    requires 'HTTP::Tiny';
    requires 'Path::Tiny';
    requires 'Archive::Extract';
    requires 'FFI::ExtractSymbols';
    requires 'Archive::Extract';
	requires 'Data::Dump';

};
on development => sub {
    requires 'Software::License::Artistic_2_0';
};

#osname 'MSWin32' => sub {
requires 'App::dumpbin' if $^O eq 'MSWin32';

#};
