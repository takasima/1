package MT::Plugin::DBPatch;
use strict;
use MT;
use MT::Plugin;
use base qw( MT::Plugin );

use lib 'addons/PowerCMS.pack/lib';
use PowerCMS::Util qw( current_ts );

our $VERSION = '0.3';
my $plugin = __PACKAGE__->new( {
 id => 'DBPatch',
 key => 'dbpatch',
 name => 'DBPatch',
 author_name => 'Alfasado Inc.',
 author_link => 'http://alfasado.net/',
} );
MT->add_plugin( $plugin );

sub init_registry {
    my $plugin = shift;
    $plugin->registry( {
            callbacks    => {
                'MT::App::CMS::take_down' => \&__take_down,

            },
        }
    );
}


if ( my @models = __models() ) {
for my $model ( @models ) {
    next if $model eq 'log';
    if ( my $class = MT->model( $model ) ) {
        $class->add_trigger(
        pre_save => sub {
            my $obj = shift; my $obj_id = ''; $obj_id = $obj->id;
            my $r = MT::Request->instance();
            if ( $obj_id ) {
                my $key = 'check_pre_save:' . ref ( $obj ) . ':' . $obj_id;
                return 1 if $r->cache( $key ); $r->cache( $key, 1 );
            }
            my $column_names = $obj->column_names; my $column_defs = $obj->column_defs;
            for my $column_name ( @$column_names ) {
                my $type = $column_defs->{ $column_name }->{ type };
                my $not_null = $column_defs->{ $column_name }->{ not_null };
                if ( ( $type eq 'integer' ) || ( $type eq 'boolean' ) ) {
                    next if $column_name eq 'id';
                    if ( ( defined ( $obj->$column_name ) ) && ( $obj->$column_name eq '' ) ) {
                        $obj->$column_name( 0 );
                    } elsif ( ( $not_null ) && (! defined ( $obj->$column_name ) ) ) {
                        $obj->$column_name( 0 );
                    }
                } elsif ( $type eq 'datetime' ) {
                    if (! $obj->$column_name ) {
                        $obj->$column_name( current_ts() );
                    }
                }
            }
            return 1;
        });
    }
} }

sub __models {
    my @matches; my $model = MT->registry( 'object_types' );
    for my $m ( keys %$model ) { if ( $m !~ /\Q.\E/ ) { push @matches, $m; } }
    return @matches;
}

sub __take_down {
    my $app = MT->instance;
    return 1 unless $app->mode eq 'plugin_control';
    my $plugin = MT->component( 'DBPatch' );
    my $switch = MT->config( 'PluginSwitch' ) || {};
    $switch->{ $plugin->{ plugin_sig } } = 1;
    MT->config( 'PluginSwitch', $switch, 1 );
    MT->config->save_config();
}

1;
