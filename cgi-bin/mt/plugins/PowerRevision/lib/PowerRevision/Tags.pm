package PowerRevision::Tags;
use strict;

my $plugin = MT->component( 'PowerRevision' );

sub _hdlr_latest_revision_value {
    my ( $ctx, $args ) = @_;
    unless ( $args->{ 'id' } || $args->{ 'name' } ) {
        return;
    }
    my $name = $args->{ 'name' };
    require MT::Request;
    my $r = MT::Request->instance;
    my $revision = $r->cache( 'loaded_revision:' . $args->{ 'id' } );
    $revision = MT->model( 'powerrevision' )->load( { object_id => $args->{ 'id' },
                                                      class => 'workflow',
                                                    }, { 
                                                      limit => 1,
                                                      'sort' => 'created_on',
                                                      direction => 'descend',
                                                    }
                                                  ) unless $revision;
    if ( $revision ) {
        $r->cache( 'loaded_revision:' . $args->{ 'id' }, $revision );
        return $revision->$name;
    }
}

sub _hdlr_revision_count {
    my ( $ctx, $args ) = @_;
    unless ( $args->{ 'id' } ) {
        return;
    }
    my $count = MT->model( 'powerrevision' )->count( { object_id => $args->{ 'id' },
                                                       class => 'workflow'
                                                     }
                                                   );
    if ( $count ) {
        return $count;
    }
}

1;