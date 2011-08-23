use Test::More tests => 2;

use File::Spec;
use lib 'lib';
use lib File::Spec->rel2abs( File::Spec->catdir( 't', 'inc' ) );

use ConfigMgr::Basic;

my $testdir = File::Spec->rel2abs( File::Spec->catdir( 't', 'inc' ) );

my $c1 = ConfigMgr::Basic->instance;
$c1->read_config( File::Spec->catfile($testdir,'simple.cfg') );
ok(1);

my $c2 = ConfigMgr::Basic->instance;
$c2->read_config( File::Spec->catfile($testdir,'invalid.cfg') );
ok(1);

