use Test::More tests => 10;
use File::Spec;

use lib 'lib';
use lib File::Spec->rel2abs( File::Spec->catdir( 't', 'inc' ) );

my $c = ConfigMgr::Inline->instance;

eval { $c->define('Directive1') };    # default to scalar
ok( !$@, 'define SCALAR type directive (default)' );

eval { $c->define( { 'Directive2' => { type => 'SCALAR' } } ) };
ok( !$@, 'define SCALAR type directive (explicit)' );

eval { $c->define( { 'Path' => { type => 'ARRAY' } } ) };
ok( !$@, 'define ARRAY type directive' );

eval { $c->define( { 'Preferences' => { type => 'HASH' } } ) };
ok( !$@, 'define HASH type directive' );

# unknown type
eval { $c->define( { 'Mystery' => { type => 'FOO' } } ) };
ok( $@, 'define unknown type directive FAILS' );

is( $c->type('Directive1'),  'SCALAR', 'Type SCALAR returned (default)' );
is( $c->type('Directive2'),  'SCALAR', 'Type SCALAR returned (explicit)' );
is( $c->type('Path'),        'ARRAY',  'Type ARRAY returned' );
is( $c->type('Preferences'), 'HASH',   'Type HASH returned' );
is( $c->type('Mystery'),     undef,    'Unknown type returned as SCALAR' );

package ConfigMgr::Inline;
use base 'Class::ConfigMgr';
sub init { }

