package FastPlugin::PluginSetting;
use strict;

use MT::Serialize;
use base qw( MT::Object );

__PACKAGE__->install_properties(
    {   column_defs => {
            'id'     => 'integer not null auto_increment',
            'plugin' => 'string(50) not null',
            'key'    => 'string(255) not null',
            'data'   => 'blob',
        },
        indexes => {
            plugin => 1,
            key    => 1,
        },
        child_of    => 'MT::Blog',
        datasource  => 'plugindata',
        primary_key => 'id',
    }
);

sub class_label {
    MT->translate( "Plugin Data" );
}

sub data {
    my $self = shift;
    my $ser ||= MT::Serialize->new( 'MT' );
    if ( @_ ) {
        my $data = shift;
        if ( ref( $data ) ) {
            $self->column( 'data', $ser->serialize( \$data ) );
        }
        else {
            $self->column( 'data', $data );
        }
        $data;
    } else {
        my $data = $self->column('data');
        return undef unless defined $data;
        if ( substr( $data, 0, 4 ) eq 'SERG' ) {
            my $thawed = $ser->unserialize( $data );
            my $ret = defined $thawed ? $$thawed : undef;
            return $ret;
        } else {
            require Storable;
            my $thawed = eval { Storable::thaw( $data ) };
            if ( $@ =~ m/byte order/i ) {
                $Storable::interwork_56_64bit = 1;
                $thawed = eval { Storable::thaw( $data ) };
            }
            return undef if $@;
            return $thawed;
        }
    }
}

1;