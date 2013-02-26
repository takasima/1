package ItemGroup::ItemOrder;
use strict;
use base qw( MT::Object );

__PACKAGE__->install_properties( {
    column_defs => {
        'id' => 'integer not null auto_increment',
        'blog_id' => 'integer',
        'number' => 'integer',
        'object_id' => 'integer',
        'object_ds' => 'string(25)',
        'class' => 'string(25)',
        'itemgroup_id' => 'integer',
    },
    indexes => {
        'blog_id' => 1,
        'number' => 1,
        'object_ds' => 1,
        'class' => 1,
        'itemgroup_id' => 1,
    },
    child_of => 'MT::Blog',
    datasource => 'itemorder',
    primary_key => 'id',
} );

1;
