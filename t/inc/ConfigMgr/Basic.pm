package ConfigMgr::Basic;
use strict;

use base 'Class::ConfigMgr';

sub init {
    my $self = shift;
    $self->define('Test');
    $self->define( 'TestDefault', 'default' => 'Foo' );
    $self->define( 'TestList',    'type'    => 'ARRAY' );
    $self->define( 'TestDict',    'type'    => 'HASH' );
}

1;
