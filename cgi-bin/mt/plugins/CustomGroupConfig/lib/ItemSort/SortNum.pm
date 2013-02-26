package ItemSort::SortNum;
use strict;
use base qw( MT::Object );

__PACKAGE__->install_properties( {
    column_defs => {
        'id' => 'integer not null auto_increment',
        'blog_id' => 'integer',
        'number' => 'integer',
        'entry_id' => 'integer',
        'type' => 'string(25)',
        'sortgroup_id' => 'integer',
    },
    indexes => {
        'blog_id' => 1,
        'number' => 1,
        'type' => 1,
        'sortgroup_id' => 1,
    },
    child_of => 'MT::Blog',
    datasource => 'sortnum',
    primary_key => 'id',
} );

1;
