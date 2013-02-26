package LinkChecker::TemporaryLog;
use strict;
use base qw/MT::Object/;

__PACKAGE__->install_properties( {
    column_defs => {
        'id'            => 'integer not null auto_increment',
        'blog_id'       => 'integer',
        'logfile'       => 'string(255)',
    },
    indexes     => {
        'blog_id'       => 1,
        'logfile'       => 1,
    },
    child_of    => 'MT::Blog',
    datasource  => 'temporarylog',
    primary_key => 'id',
} );

sub class_label {
    my $plugin = MT->component( 'LinkChecker' );
    return $plugin->translate( 'Temporary log' );
}

sub class_label_plural { goto &class_label }

1;
