package BlogTree::Plugin;
use strict;
use lib qw( addons/PowerCMS.pack/lib );
use PowerCMS::Util qw( is_user_can is_cms );

#our $plugin_blogtree = MT->component( 'BlogTree' );

sub _cb_cms_upload_file {
    my ( $cb, %param ) = @_;
    my $asset = $param{ asset };
    return unless $asset;
    my $cache_key = 'objectfolder_related_' . $asset->id;
    my $r = MT::Request->instance();
    return 1 if $r->cache( $cache_key );
    my $app = MT->instance();
    return _cb_cms_post_save_asset( $cb, $app, $asset );
}

sub _cb_cms_post_save_asset {
    my ( $cb, $app, $asset, $original ) = @_;
    my $blog = $asset->blog;
    my $blog_id = $blog->id;
#    if ( my $middle_path = $app->param( 'middle_path' ) ) {
    my $middle_path = $app->param( 'extra_path' );
    unless ( $middle_path ) {
        $middle_path = $asset->{ column_values }->{ url };
        unless ( $middle_path =~ s!^%r/(.*)/.*?$!$1! ) {
            return 1;
        }
    }
    if ( $middle_path ) {
        my @folders = MT->model( 'folder' )->load( { blog_id => $blog_id } );
        my $folder_exists = 0;
        $middle_path =~ s/\/$//;

        my $cache_key = 'objectfolder_related_' . $asset->id;
        my $r = MT::Request->instance();
        return 1 if $r->cache( $cache_key );

        for my $folder ( @folders ) {
            my $publish_path = $folder->publish_path;
            if ( $publish_path eq $middle_path ) {
                my $objectfolder = MT->model( 'objectfolder' )->get_by_key( { blog_id => $blog_id,
                                                                              object_ds => $asset->datasource,
                                                                              object_id => $asset->id,
                                                                            }
                                                                          );
                $objectfolder->folder_id( $folder->id );
                $objectfolder->save or die $objectfolder->errstr;
                $folder_exists++;
                $r->cache( $cache_key, 1 );
                last;
            }
        }
        unless ( $folder_exists ) {
            my @folder_basenames = split( /\//, $middle_path );
            my $parent_folder;
            my $i = 0;
            for my $basename ( @folder_basenames ) {
                my $folder = MT->model( 'folder' )->get_by_key( { blog_id => $blog_id,
                                                                  basename => $basename,
                                                                  ( $parent_folder ? ( parent => $parent_folder->id ) : () ),
                                                                }
                                                              );
                unless ( $folder->id ) {
                    $folder->label( $basename );
                    $folder->author_id( is_cms( $app ) ? $app->user->id : 0 );
                    $folder->save or die $folder->errstr;
                }
                $parent_folder = $folder;
                $i++;
                if ( scalar @folder_basenames == $i ) {                
                    my $objectfolder = MT->model( 'objectfolder' )->get_by_key( { blog_id => $blog_id,
                                                                                  object_ds => $asset->datasource,
                                                                                  object_id => $asset->id,
                                                                                }
                                                                              );
                    $objectfolder->folder_id( $folder->id );
                    $objectfolder->save or die $objectfolder->errstr;
                    $r->cache( $cache_key, 1 );
                }
            }
        }
    }
    if ( $app->param( 'blogtree' ) ) {
        my $redirect_url = $app->base . $app->uri( mode => 'blogtree_uploaded',
                                                   args => {
                                                        blog_id => $blog_id,
                                                   },
                                                 );
        return $app->redirect( $redirect_url );
    }
    return 1;
}

sub _blog_stats_entry {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $publish_post = is_user_can( $app->blog, $app->user, 'publish_post' );
    my $edit_all_posts = is_user_can( $app->blog, $app->user, 'edit_all_posts' );
    if ( $edit_all_posts && ! $publish_post ) {
        $param->{ can_edit_only } = 1;
        $param->{ editable } = 0;
    }
}

sub _set_alt_css {
    my ( $cb, $app, $tmpl ) = @_;
    my $old = quotemeta(q{<script type="text/javascript" src="<$mt:var name="static_uri"$>jquery/jquery.validate.js?v=<mt:var name="mt_version_id" escape="URL">"></script>});
    my $new = '<script type="text/javascript" src="<$mt:var name="static_uri"$>plugins/BlogTree/lib/jquery.validate.js?v=<mt:var name="mt_version_id" escape="URL">"></script>';
    $$tmpl =~ s/$old/$new/;
    
    my $old2 = quotemeta(q{<script type="text/javascript" src="<$mt:var name="static_uri"$>jquery/jquery.validate.min.js?v=<mt:var name="mt_version_id" escape="URL">"></script>});
    my $new2 = '<script type="text/javascript" src="<$mt:var name="static_uri"$>plugins/BlogTree/lib/jquery.validate.js?v=<mt:var name="mt_version_id" escape="URL">"></script>';
    $$tmpl =~ s/$old2/$new2/;
}

sub _blogtree_upload {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $q = $app->param;
    #my $from_blogtree = $q->param( 'blogtree' );
    if($q->param( 'blogtree' )){
        $param->{ 'extra_path' } = $q->param( 'extra_path' );
        $param->{ 'enable_destination' } = '';
        #$param->{ 'enable_destination' } = '';
        if ( my $pointer_node = $tmpl->getElementById('file') ) {
            my $nodeset = $tmpl->createElement(
                'app:setting',
                {
                    id    => 'blogtree',
                    label_class => 'top-label',
                    label => '<__trans phrase="Upload Destination">',
                }
            );
            my $inner_html = '&#60;<__trans phrase="Site Root">&#62; / <input readonly="readonly" type="text" name="extra_path" id="extra_path" class="text path" value="<mt:var name="extra_path" escape="html">" /><input type="hidden" name="blogtree" value="1" /><input type="hidden" name="site_path" value="1" />';
            $nodeset->innerHTML($inner_html);
            $tmpl->insertAfter( $nodeset, $pointer_node );
        }
    }
}

sub _blogtree_upload_replace {
    my ( $cb, $app, $tmpl ) = @_;
    if($app->param->param( 'blogtree' )){
        my $search = quotemeta(q{<input type="hidden" name="__mode" value="upload_file" />});
        my $inseart = '<input type="hidden" name="blogtree" value="1" />';
        $$tmpl =~ s/($search)/$1$inseart/;
    }
}

1;
