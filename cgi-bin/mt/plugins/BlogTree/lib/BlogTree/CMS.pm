package BlogTree::CMS;
use strict;

sub _blogtree_menu {
    my $app = shift;
    my $plugin = MT->component( 'BlogTree' );
    $app->{ plugin_template_path } = File::Spec->catdir( $plugin->path,'tmpl' );
    my $type = $app->param( '_type' );
    my %param;
    if ( $app->blog ) {
        my $columns = $app->blog->column_names;
        for my $column ( @$columns ) {
            $param{ $column } = $app->blog->$column;
        }
        $param{ blog_id } = $app->blog->id;
        $param{ class } = $app->param( 'class' );
    }
    my $tmpl;
    if ( $type eq 'open_directory' ) {
        $tmpl = 'BlogTree_open_directory.tmpl';
        my $cid = $app->param( 'id' );
        $param{ category_id } = $cid;
        $param{ id } = $cid;
        $param{ offset } = $app->param( 'offset' );
        $param{ isolation } = $app->param( 'isolation' );
        $param{ hide_assets } = $plugin->get_config_value( 'hide_assets' );
    } else {
        $tmpl = 'BlogTree_sidebar.tmpl';
    }
    return $app->build_page( $tmpl, \%param );
}

sub _mode_blogtree_uploaded {
    my $app = shift;
    my $plugin = MT->component( 'BlogTree' );
    $app->{ plugin_template_path } = File::Spec->catdir( $plugin->path,'tmpl' );
    my $tmpl = 'BlogTree_uploaded.tmpl';
    my %param;
    return $app->build_page( $tmpl, \%param );
}


1;