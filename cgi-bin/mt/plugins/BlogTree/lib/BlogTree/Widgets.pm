package BlogTree::Widgets;
#use strict;

our $plugin_blogtree = MT->component( 'BlogTree' );

sub _blog_tree {
    my ( $app, $tmpl, $param ) = @_;
    if ( $app->blog ) {
        my $columns = $app->blog->column_names;
        for my $column ( @$columns ) {
            $param->{ $column } = $app->blog->$column;
        }
    }
}

1;
