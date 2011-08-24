use Test::More tests => 3;

use File::Spec;
use lib 'lib';
use lib File::Spec->rel2abs( File::Spec->catdir( 't', 'inc' ) );

use ConfigMgr::Basic;

my $testdir = File::Spec->rel2abs( File::Spec->catdir( 't', 'inc' ) );

eval { ConfigMgr::Basic->read_config(File::Spec->catfile($testdir,'simple.cfg') ) };
ok(!$@,'Read simple config file');

eval { ConfigMgr::Basic->read_config(File::Spec->catfile($testdir,'invalid.cfg') ) };
ok($@,'Reading config file with an invalid directive');

eval { ConfigMgr::Basic->read_config('/path/to/nowhere.cfg') };
ok($@,'Reading a missing config file');

