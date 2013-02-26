package PowerCMS::Listing;
use strict;

use MT::Util qw( encode_html remove_html trim );
use PowerCMS::Util qw( is_cms plugin_template_path is_user_can write2file
                       build_tmpl chomp_dir current_user can_edit_entry );

sub _html_filename {
    my ( $prop, $obj, $app ) = @_;
    return $obj->basename || '';
}

sub _html_tags {
    my ( $prop, $obj, $app ) = @_;
    if ( my @tags = $obj->tags ) {
        my $tag_delim = chr( $app->user->entry_prefs->{tag_delim} );
        return join( $tag_delim, @tags );
    }
    return '';
}

sub _html_entry { # override 'html' in MT::Entry::list_props
                my $prop        = shift;
                my ($obj)       = @_;
                my $class       = $obj->class;
                my $class_label = $obj->class_label;
                my $title       = $prop->super(@_);
                my $excerpt     = remove_html( $obj->excerpt )
                    || remove_html( $obj->text );
                ## FIXME: Hard coded
                my $len = 40;
                if ( length $excerpt > $len ) {
                    $excerpt = substr( $excerpt, 0, $len );
                    $excerpt .= '...';
                }
                my $id        = $obj->id;
                my $permalink = $obj->permalink;
                my $edit_url  = MT->app->uri(
                    mode => 'view',
                    args => {
                        _type   => $class,
                        id      => $obj->id,
                        blog_id => $obj->blog_id,
                    }
                );
                my $status = $obj->status;
                my $status_class
                    = $status == MT::Entry::HOLD()    ? 'Draft'
                    : $status == MT::Entry::RELEASE() ? 'Published'
                    : $status == MT::Entry::REVIEW()  ? 'Review'
                    : $status == MT::Entry::FUTURE()  ? 'Future'
                    : $status == MT::Entry::JUNK()    ? 'Junk'
                    :                                   '';
                my $lc_status_class = lc $status_class;
                require MT::Entry;
                my $status_file
                    = $status == MT::Entry::HOLD()    ? 'draft.gif'
                    : $status == MT::Entry::RELEASE() ? 'success.gif'
                    : $status == MT::Entry::REVIEW()  ? 'warning.gif'
                    : $status == MT::Entry::FUTURE()  ? 'future.gif'
                    : $status == MT::Entry::JUNK()    ? 'warning.gif'
                    :                                   '';
                my $status_img
                    = MT->static_path . 'images/status_icons/' . $status_file;

                # ADD for TemplateSelector
                if ( $status == 7 ) {
                    $status_img = MT->static_path . 'addons/PowerCMS.pack/images/status_template.gif'
                }
                # /ADD
                
                my $view_img
                    = MT->static_path . 'images/status_icons/view.gif';
                my $view_link = $obj->status == MT::Entry::RELEASE()
                    ? qq{
                    <span class="view-link">
                      <a href="$permalink" target="_blank">
                        <img alt="View $class_label" src="$view_img" />
                      </a>
                    </span>
                }
                    : '';

                my $out = qq{
                    <span class="icon status $lc_status_class">
                      <a href="$edit_url"><img alt="$status_class" src="$status_img" /></a>
                    </span>
                    <span class="title">
                      $title
                    </span>
                    $view_link
                };

                # ADD for override $out
                $out = '';
                my $app = MT->instance();
                my $user = current_user( $app );
                my $can_edit_entry = can_edit_entry( $obj, $user );
                my $icon_src = qq{<img alt="$status_class" src="$status_img" />};
                $out .= qq{<span class="icon status $lc_status_class">};
                if ( $can_edit_entry ) {
                    $out .= qq{<a href="$edit_url">$icon_src</a>};
                } else {
                    $out .= $icon_src;
                }
                $out .= "</span>";
                $out .= qq{<span class="title">};
                $title = make_entry_label( $obj, $app, 'title' );
                if ( $can_edit_entry ) {
                    $out .= qq{<a href="$edit_url">$title</a>};
                } else {
                    $out .= $title;
                }
                $out .= "</span>";
                if ( can_duplicate( $user, $obj ) ) {
                    my $duplicate_url = MT->app->uri( mode => 'view',
                                                      args => { _type => $class,
                                                                id => $obj->id,
                                                                blog_id => $obj->blog_id,
                                                                duplicate => 1,
                                                              },
                                                    );
                    my $duplicate_icon_url = MT->static_path . 'addons/PowerCMS.pack/images/duplicate.gif';
                    my $plugin = MT->component( 'PowerCMS' );
                    my $alt = $plugin->translate( "Duplicate" );
                    $out .= <<HTML;
<span class="icon duplicate" style="margin-left:7px;">
    <a href="$duplicate_url" title="$alt"><img alt="$alt" src="$duplicate_icon_url" /></a>
</span>
HTML
                }
                $out .= $view_link;
                # /ADD

                $out .= qq{<p class="excerpt description">$excerpt</p>}
                    if trim($excerpt);
                return $out;
}

sub make_entry_label {
    my ( $obj, $app, $col, $alt_label ) = @_;
    my $id = $obj->id;
    my $label = $obj->$col;
    if ( $label ) {
        my $can_double_encode = 1;
        $label = encode_html( $label, $can_double_encode );
        return $label;
    } else {
        return $app->translate( 'No title' ) . qq{(id:$id)};
    }
}

sub _list_can_access_cms {
    my ( $prop, $obj, $app ) = @_;
    if ( $obj->can_access_cms || $obj->is_superuser ) {
        return MT->translate( 'Allow' );
    } else {
        return MT->translate( 'Disallow' );
    }
}

sub can_duplicate {
    my ( $author, $entry ) = @_;
    my $blog = $entry->blog;
    my $class = $entry->class;
    return 0 unless $author;
    return 0 unless $blog;
    return 0 unless $class;
    unless ( ref $author eq 'MT::Author' ) {
        if ( $author =~ /^[0-9]+$/ ) {
            $author = MT->model( 'author' )->load( { id => $author } );
        }
    }
    if ( ! ( ref $blog eq 'MT::WebSite' ) && ! ( ref $blog eq 'MT::Blog' ) ) {
        if ( $blog =~ /^[0-9]+$/ ) {
            $blog = MT::Blog->load( { id => $blog } );
        }
    }
    my $admin = $author->is_superuser || ( $blog && is_user_can( $blog, $author, 'administer_blog' ) );
    my $edit_all_posts = is_user_can( $blog, $author, 'edit_all_posts' );
    my $publish_post = is_user_can( $blog, $author, 'publish_post' );
    my $create_post = is_user_can( $blog, $author, 'create_post' );
    my $manage_pages = is_user_can( $blog, $author, 'manage_pages' );
    if ( $admin ) {
        return 1;
    }
    if ( $class eq 'entry' ) {
        if ( $edit_all_posts ) {
            return 1;
        }
    } else {
        if ( $manage_pages ) {
            return 1;
        }
    }
    if ( $author->id == $entry->author_id ) {
        return 1;
    }
    return 0;
}

1;
