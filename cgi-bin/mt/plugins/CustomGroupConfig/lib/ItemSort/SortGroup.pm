package ItemSort::SortGroup;
use strict;
use base qw( MT::Object );

__PACKAGE__->install_properties( {
    column_defs => {
        'id' => 'integer not null auto_increment',
        'blog_id' => 'integer',
        'name' => 'string(255)',
        'type' => 'string(25)',
        'add_item' => 'integer',
        'add_position' => 'string(255)',
        'add_filter' => 'string(255)',
        'filter_val' => 'string(255)',
        'filter_left' => 'string(25)',
        'filter_left_val' => 'string(255)',
        'template_id' => 'integer',
    },
    indexes => {
        'blog_id' => 1,
        'name' => 1,
    },
    datasource => 'sortgroup',
    primary_key => 'id',
    child_of => 'MT::Blog',
    child_classes => [ 'ItemSort::SortNum' ],
} );

1;
