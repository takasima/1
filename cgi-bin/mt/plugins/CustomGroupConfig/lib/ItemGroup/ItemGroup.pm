package ItemGroup::ItemGroup;
use strict;
use base qw( MT::Object );

__PACKAGE__->install_properties( {
    column_defs => {
        'id' => 'integer not null auto_increment',
        'blog_id' => 'integer',
        'name' => 'string(255)',
        'class' => 'string(25)',
        'object_ds' => 'string(25)',
        'additem' => 'boolean',
        'addclass' => 'string(25)',
        'addposition' => 'boolean',
        'addfilter' => 'string(255)',
        'filter_val' => 'string(255)',
        'template_id' => 'integer',
    },
    indexes => {
        'blog_id' => 1,
        'name' => 1,
        'class' => 1,
        'object_ds' => 1,
    },
    datasource =>  'itemgroup',
    primary_key => 'id',
    child_of =>    'MT::Blog',
    child_classes => [ 'ItemGroup::ItemOrder' ],
} );

1;
