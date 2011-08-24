package Class::ConfigMgr;
use strict;
use warnings;

our $VERSION = '0.5';

use base qw( Class::ErrorHandler );

our $cfg;

sub instance {
    return $cfg if $cfg;
    $cfg = $_[0]->new;
}

sub new {
    my $mgr = bless { __var => {}, __settings => {} }, $_[0];
    $mgr->init;
    $mgr;
}

sub init { die "The 'init' method must be overloaded." }

sub define {
    my $mgr = shift;
    my ($vars);
    if ( ref $_[0] eq 'ARRAY' ) {
        $vars = shift;
    }
    elsif ( ref $_[0] eq 'HASH' ) {
        $vars = shift;
    }
    else {
        my ( $var, %param ) = @_;
        $vars = [ [ $var, \%param ] ];
    }
    if ( ref($vars) eq 'ARRAY' ) {
        foreach my $def (@$vars) {
            my ( $var, $param ) = @$def;
            my $lcvar = lc $var;
            $mgr->{__var}{$lcvar} = undef;
            $mgr->{__settings}{$lcvar} = keys %$param ? {%$param} : {};
            my $type = $mgr->{__settings}{$lcvar}->{'type'};
            if ( $type && $type !~ m{^(SCALAR|ARRAY|HASH)$} ) {
                delete $mgr->{__settings}{$lcvar};
                die "'$type' is not a valid directive type.";
            }
            $mgr->{__settings}{$lcvar}{key} = $var;
            if ( $mgr->{__settings}{$lcvar}{path} ) {
                push @{ $mgr->{__paths} }, $var;
            }
        }
    }
    elsif ( ref($vars) eq 'HASH' ) {
        foreach my $var ( keys %$vars ) {
            my $param = $vars->{$var};
            my $lcvar = lc $var;
            $mgr->{__settings}{$lcvar} = $param;
            if ( ref $param eq 'ARRAY' ) {
                $mgr->{__settings}{$lcvar} = $param->[0];
            }
            my $type = $mgr->{__settings}{$lcvar}->{'type'};
            if ( $type && $type !~ m{^(SCALAR|ARRAY|HASH)$} ) {
                delete $mgr->{__settings}{$lcvar};
                die "'$type' is not a valid directive type.";
            }
            $mgr->{__settings}{$lcvar}{key} = $var;
            if ( $mgr->{__settings}{$lcvar}{path} ) {
                push @{ $mgr->{__paths} }, $var;
            }
        }
    }
} ## end sub define

sub get {
    my $mgr = shift;
    my $var = lc shift;
    my $val;
    if ( defined( $val = $mgr->{__var}{$var} ) ) {
        $val = $val->() if ref($val) eq 'CODE';
        wantarray && ( $mgr->{__settings}{$var}{type} || '' ) eq 'ARRAY'
          ? @$val
          : ( ( ref $val ) eq 'ARRAY' && @$val ? $val->[0] : $val );
    }
    else {
        $mgr->default($var);
    }
}

sub type {
    my $mgr = shift;
    my $var = lc shift;
    return undef unless exists $mgr->{__settings}{$var};
    return $mgr->{__settings}{$var}{type} || 'SCALAR';
}

sub default {
    my $mgr = shift;
    my $var = lc shift;
    my $def = $mgr->{__settings}{$var}{default};
    return wantarray ? () : undef unless defined $def;
    if ( my $type = $mgr->{__settings}{$var}{type} ) {
        if ( $type eq 'ARRAY' ) {
            return wantarray ? ($def) : $def;
        }
        elsif ( $type eq 'HASH' ) {
            if ( ref $def ne 'HASH' ) {
                ( my ($key), my ($val) ) = split( /=/, $def );
                return { $key => $val };
            }
        }
    }
    $def;
}


sub _set_internal { 
    my $mgr = shift;
    my ( $var, $val ) = @_;
    $var = lc $var;
    my $type = $mgr->type($var);
    if ( $type eq 'ARRAY' ) {
        if ( ref $val eq 'ARRAY' ) {
            $mgr->{'__var'}{$var} = $val;
        }
        else {
            $mgr->{'__var'}{$var} ||= [];
            push @{ $mgr->{'__var'}{$var} }, $val if defined $val;
        }
        return $mgr->{'__var'}{$var};
    } ## end if ( $type eq 'ARRAY' )
    elsif ( $type eq 'HASH' ) {
        my $hash = $mgr->{'__var'}{$var};
        $hash = $mgr->default($var) unless defined $hash;
        if ( ref $val eq 'HASH' ) {
            $mgr->{'__var'}{$var} = $val;
        }
        else {
            $hash ||= {};
            ( my ($key), $val ) = split( /=/, $val );
            $mgr->{'__var'}{$var}{$key} = $val;
        }
    }
    else {
        $mgr->{'__var'}{$var} = $val;
    }
    return $val;
} ## end sub set_internal

sub read_config {
    my $class      = shift;
    my ($cfg_file) = @_;
    my $mgr        = $class->instance;
    $mgr->{__var} = {};
    local ( *FH, $_, $/ );
    $/ = "\n";
    die "Can't read config without config file name" if !$cfg_file;
    open FH, $cfg_file
      or die "Error opening file '$cfg_file': $!";
    my $line;
    while (<FH>) {
        chomp;
        $line++;
        next if !/\S/ || /^\s*#/;
        my ( $var, $val ) = $_ =~ /^\s*(\S+)\s+(.*)$/;
        return
                die "Config directive $var without value at $cfg_file line $line",
          unless defined($val) && $val ne '';
        $val =~ s/\s*$// if defined($val);
        next unless $var && defined($val);
        $mgr->_set_internal( $var, $val );
    }
    close FH;
    1;
} ## end sub read_config


sub DESTROY { }

use vars qw( $AUTOLOAD );

sub AUTOLOAD {
    my $mgr = $_[0];
    ( my $dir = $AUTOLOAD ) =~ s!.+::!!;
    die "No such configuration directive '$dir'"
      unless exists $mgr->{__directive}->{$dir};
    no strict 'refs';
    *$AUTOLOAD = sub {
        my $mgr = shift;
        $mgr->get($dir);
    };
    goto &$AUTOLOAD;
}

1;

__END__

=head1 NAME

Class::ConfigMgr is a base class for implementing a singleton object
configuration manager.

=head1 SYNOPSIS

    # a basic subclass
    package Foo::ConfigMgr; 
    use base 'Class::ConfigMgr';

    sub init { 
        my $cfg = shift; 
        $cfg->define('Foo', { Default => 1 });
        $cfg->define('Bar', { Default => 1 }); 
        $cfg->define('Baz'); 
        $cfg->define('Fred'); 
    }

    # example config file foo.cfg
    Bar 0 
    Fred RightSaid
    # Foo 40

    # application code
    Foo::ConfigMgr->read_config('foo.cfg') 
    my $cfg = Foo::ConfigMgr->instance; 
    print $cfg->Foo;    # 1 (default. 40 was commented out.) 
    print $cfg->Bar;    # 0 
    print $cfg->Fred;   # RightSaid 
    print $cfg->Baz;    # (undefined)
    # print $cfg->Quux; # ERROR!

=head1 DESCRIPTION

Class::ConfigMgr is a base class for implementing a singleton object
configuration manager. This module is based off of the configuration
manager found in Melody/Movable Type and a limited subset of
L<AppConfig> configuration files.

=head1 METHODS

=head2 Class::ConfigMgr->read_config($file)

Initializes the configuration manager by reads the configuration file
specified by $file. Returns undefined if the configuration file could
not be read. This
method should only be called once and before any use of the C<instance>
method.

=head2 Class::ConfigMgr->new

Creates a new instance of L<Class::ConfigMgr> and initializes it. It
does not read any configuration file data. This is done using the
L<read_config> method.

=head2 Class::ConfigMgr->instance

C<instance> returns a reference to the singleton object that is managing
the configuration. As a singleton object, developers should B<ALWAYS>
call this method rather the call than C<new>.

=head2 $cfg->define($directive[, %arg ])

This method defines which directives are recognized by the application
and optionally a default value if the directive is not explicted defined
in the configuration file. For special configuration directives (HASH or
ARRAY types), you must define them B<before> the configuration file is
read.

C<define> is most commonly used within the C<init> method all subclasses
must implement.

=head2 $cfg->type($directive)

Returns the type of the configuration directive: 'SCALAR', 'ARRAY' or
'HASH'. If the directive is unregistered, this method will return undef.

=head2 $cfg->default($directive)

Returns the default setting for the specified directive, if one exists.
The return value is always scalar.  See L<RETURN VALUES> below for more.

=head2 $cfg->get($directive)

Retrieves the value for C<$directive> from the first of the following
locations where it is defined, if any.

This method provides contextual return values. See L<RETURN VALUES>
below for more.

For ARRAY and HASH directives, there is a special value, __DEFAULT__,
one can use in the C<config.cgi> to apply the default settings of the
directive in addition to your settings.

B<Examples:>

The following config file snippet replaces the built-in defined default
of C<['plugins']> with C<['extensions']>:

    PluginPath  extensions

This next example I<appends> 'extensions' onto the PluginPath array
default yielding C<[qw( plugins extensions )]>

    PluginPath  __DEFAULT__ PluginPath  extensions

Order is important with ARRAY directives. The following I<prepends> the
values yielding C<[qw( extensions plugins )]>:

    PluginPath  extensions PluginPath  __DEFAULT__

Conversely, with HASH directives, the default values are always applied
first so that you can override them with your config settings:

    DefaultEntryPrefs   __DEFAULT__=1 DefaultEntryPrefs   height=201

=head1 RETURN VALUES

All but two accessor methods in the class B<return only a SCALAR value>.
This is because either the value is always a SCALAR (as with C<type>) or
reference to a HASH or ARRAY like with C<default> and C<get>.

In the case of an undefined value for a type ARRAY or HASH directive,
the referenced data structure will be an empty list:

    my $hashref  = $cfg->default('SomeHASHDirective');   # Yields {} my
    $arrayref = $cfg->get('SomeARRAYDirective');      # Yields []

=head2 Contextual return values from C<get>.

The C<get> method (as well as its shorthand variant; see L<SHORTHAND
ACCESSOR FORM> below), are sensitive to the context of the method call
and return the appropriate value for that context. If you aren't
familiar with the vagaries of scalar vs list context, you may want to
first review the section on it in the L<perldata> perldoc:
L<http://perldoc.perl.org/perldata.html#Context>

The return value of the C<get> method and shorthand equivalent
C<$cfg-E<gt>SomeDirective> works similarly for ARRAY and HASH values.

B<SCALAR Directives>

B<For SCALAR directives>, C<get> will always return a SCALAR or
C<undef>.

    my $csspath = $cfg->get('CSSPath'); my $same    = $cfg->CSSPath;

B<ARRAY Directives>

For ARRAY directives, C<get> will return an ARRAY in list context or a
reference to that array in scalar context. If the directive is
undefined, the ARRAY reference will be an empty list as in the example
above using C<SomeARRAYDirective>.

    # Returns array: ('value')
    my @values   = $cfg->get('SomeARRAYDirective');

    # Returns arrayref: ['value']
    my $values    = $cfg->get('SomeARRAYDirective');     #
    Case-insensitive

    # Careful! Returns string "value" due to list context!
    my ($value)  = $cfg->SomeARRAYDirective;             # Shorthand
    form

B<HASH Directives>

For HASH directives, C<get> will return a HASH in list context or a
reference to that HASH in SCALAR context. If the directive is undefined,
the referenced HASH will be an empty list as in the example above using
C<SomeHASHDirective>.

=head1 SHORTHAND ACCESSOR FORM

Once the I<ConfigMgr> object has been constructed, you can use it to
obtain the configuration settings. Any of the defined settings may be
gathered using a dynamic method invoked directly from the object:

    my $path = $cfg->CGIPath

To set the value of a directive, do the same as the above, but pass in a
value to the method:

    $cfg->CGIPath('http://www.foo.com/mt/');

If you wish to progammatically assign a configuration setting that will
persist, add an extra parameter when doing an assignment, passing '1'
(this second parameter is a boolean that will cause the value to
persist, using the L<MT::Config> class to store the settings into the
datatbase):

    $cfg->EmailAddressMain('user@example.com', 1); $cfg->save_config;

=head1 SUBCLASSING

Subclassing Class::ConfigMgr is easy and only requires one method,
C<init>, to be implemented.

=head2 $cfg->init

Initialization method called by the L<new> constructor prior to
returning a new instance of L<Class::ConfigMgr>.

All subclasses of Class::ConfigMgr must implement an C<init> method that
defines which directives are recognized and any associated default
values. This method is automatically called by C<read_config> before the
actual configuration file is read. It is passed a reference to the
singleton and the return value is ignored. See the example subclass in
the L<SYNOPSIS>.

=head1 DEPENDENCIES

L<Class::ErrorHandler>

=head1 LICENSE

The software is released under the Artistic License. The terms of the
Artistic License are described at
L<http://www.perl.com/language/misc/Artistic.html>.

=head1 AUTHOR & COPYRIGHT

Except where otherwise noted, Class::ConfigMgr is Copyright 2005-2011,
Timothy Appnel, tima@cpan.org. All rights reserved.

=cut
