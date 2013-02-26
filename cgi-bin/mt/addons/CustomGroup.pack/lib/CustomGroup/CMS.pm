package CustomGroup::CMS;

use strict;
use File::Spec;

use MT::Util qw( format_ts );
use MT::I18N qw( substr_text length_text );

sub _init_request {
    my $app = MT->instance;
    if ( ref $app eq 'MT::App::CMS' ) {
        my $custom_groups = MT->registry( 'custom_groups' );
        my @groups = keys( %$custom_groups );
        if ( ( $app->param( 'dialog_view' ) ) || ( MT->version_id =~ /^5\.0/ ) ) {
            for my $group ( @groups ) {
                $app->add_methods( 'list_' . $group => \&_list_group );
            }
            $app->add_methods( 'list_objectgroup' => \&_list_object_group );
        }
    }
    $app;
}

sub _list_group {
    my $app = shift;
    require CustomGroup::Plugin;
    my $perms = $app->permissions;
    my $user  = $app->user;
    my $list_id = $app->param( '_type' );
    my $custom_groups = MT->registry( 'custom_groups' );
    my $component = $custom_groups->{ $list_id }->{ component } || 'CustomGroup';
    my $plugin = MT->component( $component );
    $app->{ plugin_template_path } = File::Spec->catdir( $plugin->path, 'tmpl' );
    my $model = MT->model( $list_id );
    my %blogs;
    my $system_view;
    my $website_view;
    my $blog_view;
    my @blog_ids;
    my $r = MT::Request->instance;
    my %param;
    if (! defined $app->blog ) {
        $system_view = 1;
        my @all_blogs = MT::Blog->load( { class => [ 'website', 'blog' ] } );
        for my $blog ( @all_blogs ) {
            if ( CustomGroup::Plugin::_group_permission( $blog ) ) {
                $blogs{ $blog->id } = $blog;
                push( @blog_ids, $blog->id );
            }
        }
        push ( @blog_ids, 0 );
        require MT::Blog;
        my $system = MT::Blog->new;
        $system->name( MT->translate( 'System' ) );
        $blogs{ 0 } = $system;
    } else {
        if (! CustomGroup::Plugin::_group_permission( $app->blog ) ) {
            return $app->trans_error( 'Permission denied.' );
        }
        if ( $app->blog->class eq 'website' ) {
            $website_view = 1;
            $blogs{ $app->blog->id } = $app->blog;
            push ( @blog_ids, $app->blog->id );
            my @all_blogs = MT::Blog->load( { parent_id => $app->blog->id } );
            for my $blog ( @all_blogs ) {
                if ( CustomGroup::Plugin::_group_permission( $blog ) ) {
                    $blogs{ $blog->id } = $blog;
                    push ( @blog_ids, $blog->id );
                }
            }
        } else {
            $blog_view = 1;
            push ( @blog_ids, $app->blog->id );
        }
        $param{ screen_blog_id } = $app->blog->id;
    }
    my $code = sub {
        my ( $obj, $row ) = @_;
        my $columns = $obj->column_names;
        for my $column ( @$columns ) {
            my $val = $obj->$column;
            if ( $column =~ /_on$/ ) {
                $val = format_ts( '%Y&#24180;%m&#26376;%d&#26085;', $val, undef,
                                  $app->user ? $app->user->preferred_language : undef );
            } else {
                $val = substr_text( $val, 0, 15 ) . ( length_text( $val ) > 15 ? '...' : '' );
            }
            $row->{ $column } = $val;
        }
        if ( (! defined $app->blog ) || ( $website_view ) ) {
            if ( defined $blogs{ $obj->blog_id } ) {
                my $blog_name = $blogs{ $obj->blog_id }->name;
                $blog_name = substr_text( $blog_name, 0, 20 ) . ( length_text( $blog_name ) > 20 ? '...' : '' );
                $row->{ weblog_name } = $blog_name;
                $row->{ weblog_id } = $obj->blog_id;
                $row->{ can_edit } = 1;
                if ( defined $blogs{ $obj->addfilter_blog_id } ) {
                    $row->{ filter_blogname } = $blogs{ $obj->addfilter_blog_id }->name;
                }
            }
        } else {
            $row->{ can_edit } = 1;
        }
        require CustomGroup::GroupOrder;
        my $count = CustomGroup::GroupOrder->count( { group_id => $obj->id } );
        $row->{ count } = $count;
        if ( $obj->has_column( 'author_id' ) ) {
            my $obj_author = $obj->author;
            $row->{ author_name } = $obj_author->name if $obj_author;
        }
    };
    my @group_admin = _load_group_admin( \@blog_ids, $list_id );
    my @author_loop;
    for my $admin ( @group_admin ) {
        $r->cache( 'cache_author:' . $admin->id, $admin );
        push @author_loop, {
                author_id => $admin->id,
                author_name => $admin->name, };
    }
    my %terms;
    $param{ list_id } = $list_id;
    $param{ dialog_view } = $app->param( 'dialog_view' );
    $param{ author_loop }  = \@author_loop;
    $param{ system_view }  = $system_view;
    $param{ website_view } = $website_view;
    $param{ blog_view }    = $blog_view;
    $param{ LIST_NONCRON } = 1;
    $param{ saved_deleted } = 1 if $app->param ( 'saved_deleted' );
    # $param{ search_label } = $plugin->translate();
    # $param{ search_type } = ;
    $param{ edit_field } = $app->param( 'edit_field' );
    if ( $website_view ) {
        $terms{ 'blog_id' } = \@blog_ids
    }
    return $app->listing (
        {
            type   => $list_id,
            code   => $code,
            args   => { sort => 'created_on', direction => 'ascend' },
            params => \%param,
            terms  => \%terms,
        }
    );
}

sub _list_object_group {
    my $app = shift;
    my $perms = $app->permissions;
    my $user  = $app->user;
    my $list_id = $app->param( '_type' );
    my $plugin = MT->component( 'CustomGroup' );
    $app->{ plugin_template_path } = File::Spec->catdir( $plugin->path, 'tmpl' );
    my $model = MT->model( $list_id );
    my %blogs;
    my $system_view;
    my $website_view;
    my $blog_view;
    my @blog_ids;
    my $r = MT::Request->instance;
    require ObjectGroup::Plugin;
    my %param;
    if (! defined $app->blog ) {
        $system_view = 1;
        my @all_blogs = MT::Blog->load( { class => [ 'website', 'blog' ] } );
        for my $blog ( @all_blogs ) {
            if ( ObjectGroup::Plugin::_group_permission( $blog ) ) {
                $blogs{ $blog->id } = $blog;
                push( @blog_ids, $blog->id );
            }
        }
        push ( @blog_ids, 0 );
        require MT::Blog;
        my $system = MT::Blog->new;
        $system->name( MT->translate( 'System' ) );
        $blogs{ 0 } = $system;
    } else {
        if (! ObjectGroup::Plugin::_group_permission( $app->blog ) ) {
            return $app->trans_error( 'Permission denied.' );
        }
        if ( $app->blog->class eq 'website' ) {
            $website_view = 1;
            $blogs{ $app->blog->id } = $app->blog;
            push ( @blog_ids, $app->blog->id );
            my @all_blogs = MT::Blog->load( { parent_id => $app->blog->id } );
            for my $blog ( @all_blogs ) {
                if ( ObjectGroup::Plugin::_group_permission( $blog ) ) {
                    $blogs{ $blog->id } = $blog;
                    push ( @blog_ids, $blog->id );
                }
            }
        } else {
            $blog_view = 1;
            push ( @blog_ids, $app->blog->id );
        }
        $param{ screen_blog_id } = $app->blog->id;
    }
    my $code = sub {
        my ( $obj, $row ) = @_;
        my $columns = $obj->column_names;
        for my $column ( @$columns ) {
            my $val = $obj->$column;
            if ( $column =~ /_on$/ ) {
                $val = format_ts( '%Y&#24180;%m&#26376;%d&#26085;', $val, undef,
                                  $app->user ? $app->user->preferred_language : undef );
            } else {
                $val = substr_text( $val, 0, 15 ) . ( length_text( $val ) > 15 ? '...' : '' ) if $val;
            }
            $row->{ $column } = $val;
        }
        if ( (! defined $app->blog ) || ( $website_view ) ) {
            if ( defined $blogs{ $obj->blog_id } ) {
                my $blog_name = $blogs{ $obj->blog_id }->name;
                $blog_name = substr_text( $blog_name, 0, 20 ) . ( length_text( $blog_name ) > 20 ? '...' : '' ) if $blog_name;
                $row->{ weblog_name } = $blog_name;
                $row->{ weblog_id } = $obj->blog_id;
                $row->{ can_edit } = 1;
                if ( defined $blogs{ $obj->addfilter_blog_id } ) {
                    $row->{ filter_blogname } = $blogs{ $obj->addfilter_blog_id }->name;
                }
            }
        } else {
            $row->{ can_edit } = 1;
        }
        my $count = $obj->children_count;
        $row->{ count } = $count;
        if ( $obj->has_column( 'author_id' ) ) {
            my $obj_author = $obj->author;
            $row->{ author_name } = $obj_author->name if $obj_author;
        }
    };
    my @group_admin = _load_group_admin( \@blog_ids, $list_id );
    my @author_loop;
    for my $admin ( @group_admin ) {
        $r->cache( 'cache_author:' . $admin->id, $admin );
        push @author_loop, {
                author_id => $admin->id,
                author_name => $admin->name, };
    }
    my %terms;
    $param{ list_id } = $list_id;
    $param{ dialog_view } = $app->param( 'dialog_view' );
    $param{ author_loop }  = \@author_loop;
    $param{ system_view }  = $system_view;
    $param{ website_view } = $website_view;
    $param{ blog_view }    = $blog_view;
    $param{ LIST_NONCRON } = 1;
    $param{ saved_deleted } = 1 if $app->param ( 'saved_deleted' );
    # $param{ search_label } = $plugin->translate();
    # $param{ search_type } = ;
    $param{ edit_field } = $app->param( 'edit_field' );
    if ( $website_view ) {
        $terms{ 'blog_id' } = \@blog_ids
    }
    return $app->listing (
        {
            type   => $list_id,
            code   => $code,
            args   => { sort => 'created_on', direction => 'ascend' },
            params => \%param,
            terms  => \%terms,
        }
    );
}

sub _load_group_admin {
    my $blog_id = shift;
    my $list_id = shift;
    require MT::Author;
    push ( @$blog_id, 0 );
    my $author_class = MT->model( 'author' );
    my %terms1 = ( blog_id => $blog_id, permissions => { like => "%'administer%" } );
    my @admin = $author_class->load(
        { type => MT::Author::AUTHOR(), },
        { join => [ 'MT::Permission', 'author_id',
            \%terms1,
            { unique => 1 } ],
        }
    );
    my @author_id;
    for my $author ( @admin ) {
        push ( @author_id, $author->id );
    }
    my %terms2 = ( blog_id => $blog_id, permissions => { like => "%'manage_$list_id'%" } );
    my @group_admin = $author_class->load(
        { type => MT::Author::AUTHOR(),
          id => { not => \@author_id } },
        { join => [ 'MT::Permission', 'author_id',
            \%terms2,
            { unique => 1 } ],
        }
    );
    push ( @admin, @group_admin );
    return @admin;
}

1;
