package ConfigMgr::Basic;
use strict;

use base 'Class::ConfigMgr';

sub init {
    my $self = shift;
    $self->define('Directive1');
    $self->define( { 'Directive2' => { type => 'SCALAR' } } );
    $self->define( { 'Default' => { 'default' => 'Hello World' } } );
    $self->define( { 'AltPath' => { type => 'ARRAY' } } );
    $self->define( { 'Path' => { type => 'ARRAY' } } );
    $self->define( { 'Preferences' => { type => 'HASH' } } );
}

1;
