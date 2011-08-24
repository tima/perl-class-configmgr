use strict;
use Test::More tests => 16;

use File::Spec;
use lib 'lib';
use lib File::Spec->rel2abs( File::Spec->catdir( 't', 'inc' ) );

use ConfigMgr::Basic;
my $testdir = File::Spec->rel2abs( File::Spec->catdir( 't', 'inc' ) );

# we're screwed if this fails.
eval { ConfigMgr::Basic->read_config(File::Spec->catfile($testdir,'simple.cfg') ) };
ok(!$@,'Read simple config file');

my $c = ConfigMgr::Basic->instance;

ok($c->get('Directive1') eq 'Foo', 'get of SCALAR');
ok($c->Directive1() eq 'Foo', 'Get using autoaccessor (SCALAR)');
ok($c->get('Directive1') eq $c->Directive1(), 
    'Sanity check of SCALAR get and autoaccessor');

ok($c->get('Directive2') eq 'Bar', 'get of SCALAR 2');
ok($c->Directive2() eq 'Bar', 'Get using autoaccessor (SCALAR) 2');
ok($c->get('Directive2') eq $c->Directive2(), 
    'Sanity check of SCALAR get and autoaccessor 2');

# order matter to is_deeply ARRAY tests
my @paths = sort qw( here /abs/path/ relative/path );
is_deeply([sort $c->get('Path')], \@paths, 'get of ARRAY');
is_deeply([sort $c->Path()], \@paths, 'Get using autoaccessor (ARRAY)');
is_deeply([sort $c->Path()],[sort $c->get('Path')],
    'Sanity check of ARRAY get and autoaccessor');

my $altpath = [ 'Fred' ];
is_deeply([$c->get('AltPath')], $altpath, 'get of ARRAY (single value)');
is_deeply([$c->AltPath()], $altpath, 
    'Get using autoaccessor (ARRAY single value)');
is_deeply([$c->AltPath()], [$c->get('AltPath')],
    'Sanity check of ARRAY get and autoaccessor (single value)');

my $pref = {
    'cake' => 'please',
    'death' => 0,
};
is_deeply($c->get('Preferences'),$pref, 'get of HASH');
is_deeply($c->Preferences,$pref, 'Get using autoaccesor (HASH)');
is_deeply($c->Preferences,$c->get('Preferences'),
    'Sanity check of HASH get and autoaccessor');

# need to resolve what the right behavior should be here.
# my $a = $c->Path();
# is_deeply(scalar $c->Path(), $a, 
#    'ARRAY accessor returns reference in SCALAR context');
# my @b = $c->Path();
# use Data::Dumper;
# diag(Dumper($a,\@b,));
# is_deeply(\@b, $a, 'ARRAY accessor returns plain ARRAY in that context');

