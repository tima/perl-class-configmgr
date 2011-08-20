use Test::More no_plan;
use File::Spec;

use lib File::Spec->rel2abs( File::Spec->catdir( 't', 'inc' ) );

use ConfigMgr::Basic;

my $c1 = ConfigMgr::Basic->instance;
my $c2 = ConfigMgr::Basic->instance;

ok( $c1 = $c2 );
