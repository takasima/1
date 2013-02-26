package AdditionalFields::Plugin;
use strict;

use lib qw( addons/Commercial.pack/lib );
use CustomFields::Util qw( get_meta );

use MT::Util qw( format_ts );
use MT::I18N qw( substr_text length_text );

sub _entries_dialog {
    my $app = shift;
    my $plugin = MT->component( 'AdditionalFields' );
    require MT::Request;
    require MT::Entry;
    my $r = MT::Request->instance;
    my $user = $app->user;
    my $list_id = 'entry';
    my %blogs;
    my @blog_ids;
    my $blog = $app->blog;
    my @all_blogs;
    my @blog_loop;
    my $filter = $app->param( 'filter' );
    my $filter_val = $app->param( 'filter_val' );
    my $class = $app->param( 'class' );
    if (! $blog ) {
        $app->return_to_dashboard();
    } else {
        $blogs{ $app->blog->id } = $app->blog;
        push ( @blog_ids, $app->blog->id );
        if ( $blog->class eq 'website' ) {
            my $all_blogs = $blog->blogs;
            for my $blog ( @$all_blogs ) {
                if ( __can_post( $user, $blog ) ) {
                    $blogs{ $blog->id } = $blog;
                    push ( @blog_ids, $blog->id );
                    my $blog_name = substr_text( $blog->name, 0, 20 ) . ( length_text( $blog->name ) > 20 ? "..." : "" );
                    push @blog_loop, {
                            weblog_id => $blog->id,
                            weblog_name => $blog_name, };
                }
            }
        } else {
            if (! __can_post( $user, $blog ) ) {
                return $app->trans_error( 'Permission denied.' );
            }
            push @blog_loop, {
                    weblog_id => $app->blog->id,
                    weblog_name => $app->blog->name, };
        }
    }
    my $code = sub {
        my ( $obj, $row ) = @_;
        my $category = $obj->category;
        if ( $category ) {
            $row->{ category_label } = $category->label;
            $row->{ entry_category_id } = $category->id;
        }
        my $columns = $obj->column_names;
        my $meta = get_meta( $obj );
        for my $column ( @$columns ) {
            my $val = $obj->$column;
            $row->{ $column . '_raw' } = $val;
            if ( $column =~ /_on$/ ) {
                $val = format_ts( "%Y&#24180;%m&#26376;%d&#26085;", $val, undef,
                                  $user ? $user->preferred_language : undef );
            }
            if ( $column eq 'title' ) {
                $val = substr_text( $val, 0, 30 ) . ( length_text( $val ) > 30 ? "..." : "" );
            }
            if ( ( $column eq 'text' ) || ( $column eq 'text_more' ) || ( $column eq 'excerpt' ) ) {
                $val = substr_text( $val, 0, 33 ) . ( length_text( $val ) > 33 ? "..." : "" );
            }
            $row->{ $column } = $val;
            $row->{ entry_permalink } = $obj->permalink;
        }
        foreach my $field ( keys %$meta ) {
            my $column_name = 'field.' . $field;
            if ( $obj->has_column( $column_name ) ) {
                $row->{ $column_name } = $obj->$column_name;
            }
        }
        $row->{ entry_permalink } = $obj->permalink;
        my $obj_author = $obj->author;
        if ( $obj_author ) {
            $row->{ author_name } = $obj_author->name;
        }
        if ( defined $blogs{ $obj->blog_id } ) {
            my $blog_name = $blogs{ $obj->blog_id }->name;
            $blog_name = substr_text( $blog_name, 0, 20 ) . ( length_text( $blog_name ) > 20 ? "..." : "" );
            $row->{ weblog_name } = $blog_name;
            $row->{ weblog_id } = $obj->blog_id;
        }
    };
    my @contributers = __load_contributer( @blog_ids );
    my @author_loop;
    for my $contributer ( @contributers ) {
        $r->cache( 'cache_author:' . $contributer->id, $contributer );
        push @author_loop, {
                author_id => $contributer->id,
                author_name => $contributer->name, };
    }
    my %terms;
    my %param;
    my @tag_loop;
    require MT::Tag;
    require MT::ObjectTag;
    my @tags = MT::Tag->load( undef,
                              { join => MT::ObjectTag->join_on( 'tag_id',
                              { blog_id => \@blog_ids, object_datasource => 'entry' },
                              { unique => 1 } ) } );
    for my $tag ( @tags ) {
        push @tag_loop, { tag_name => $tag->name };
    }
    $param{ tag_loop } = \@tag_loop;
    $param{ blog_loop } = \@blog_loop;
    $param{ list_id } = $list_id;
    $param{ blog_id } = $blog->id;
    $param{ dialog_view } = 1;
    $param{ edit_field } = $app->param( 'edit_field' );
    $param{ author_loop } = \@author_loop;
    $param{ class } = $class;
    if ( $class eq 'entry' ) {
        $param{ class_label } = $app->translate( 'Entry' );
    } else {
        $param{ class_label } = $app->translate( 'Page' );
    }
    $param{ has_list_actions } = 0;
    $param{ filter } = $filter;
    $param{ filter_val } = $filter_val;
    $param{ blog_view } = 1;
    $param{ LIST_NONCRON } = 1;
    $app->{ plugin_template_path } = File::Spec->catdir( $plugin->path, 'tmpl' );
    my %args;
    $args{ sort } = 'authored_on';
    $args{ direction } = 'descend';
    $args{ limit } = 25;
    if ( my $query = $app->param( 'query' ) ) {
        my $search_col = $app->param( 'search_col' );
        $param{ query } = $query;
        $param{ filter } = $query;
        $param{ search_col } = $search_col;
        my $search_col_label;
        if ( $search_col eq 'title' ) {
            $search_col_label = $app->translate( 'Title' );
        } elsif ( $search_col eq 'text' ) {
            $search_col_label = $app->translate( 'Entry Body' );
        } elsif ( $search_col eq 'text_more' ) {
            $search_col_label = $app->translate( 'Extended Entry' );
        } elsif ( $search_col eq 'excerpt' ) {
            $search_col_label = $app->translate( 'Excerpt' );
        } elsif ( $search_col eq 'keywords' ) {
            $search_col_label = $app->translate( 'Keywords' );
        }
        $param{ search_col_label } = $search_col_label;
        my %terms1 = ( blog_id => \@blog_ids,
                       class => $class,
                       $search_col => { like => "%$query%" },
                       status => [ 1,2,3,4,5 ] );
        return $app->listing (
            {
                type   => $list_id,
                code   => $code,
                args   => \%args,
                params => \%param,
                terms  => \%terms1,
            }
        );
    }
    if ( $filter && ( $filter eq 'status' ) ) {
        $terms{ status } = $filter_val;
    } else {
        $terms{ status } = [ 1,2,3,4,5 ];
    }
    $terms{ class } = $class;
    $terms{ blog_id } = \@blog_ids;
    if ( $filter  && ( $filter eq 'category_id' ) ) {
        $app->delete_param( 'filter' );
        $app->delete_param( 'filter_val' );
        require MT::Placement;
        $args{ join } = MT::Placement->join_on(
            'entry_id',
            { category_id => $filter_val },
            { unique      => 1 }
        );
    }
    return $app->listing (
        {
            type   => $list_id,
            code   => $code,
            args   => \%args,
            params => \%param,
            terms  => \%terms,
        }
    );
}

sub __load_contributer {
    my @blog_id = @_;
    require MT::Author;
    require MT::Permission;
    push ( @blog_id, 0 );
    my %terms1 = ( blog_id => \@blog_id, permissions => { like => "\%'administer\%" } );
    my @user = MT::Author->load(
        { type => MT::Author::AUTHOR() },
        { join => [ 'MT::Permission', 'author_id',
            \%terms1,
            { unique => 1 } ],
        }
    );
    my @author_id;
    for my $author ( @user ) {
        push ( @author_id, $author->id );
    }
    my %terms2 = ( blog_id => \@blog_id, permissions => { like => "\%'create_post'\%" } );
    # TODO::Page Permission
    my @contributer = MT::Author->load(
        { type => MT::Author::AUTHOR(),
          id => { not => \@author_id } },
        { join => [ 'MT::Permission', 'author_id',
            \%terms2,
            { unique => 1 } ],
        }
    );
    push ( @user, @contributer );
    return @user;
}

sub __can_post {
    my ( $user, $blog ) = @_;
    my $perm = $user->is_superuser;
    if (! $perm ) {
        $perm = $user->permissions( $blog->id )->can_administer_blog;
        $perm = $user->permissions( $blog->id )->can_create_post unless $perm;
    }
    return $perm;
}

sub _cb_restore {
    my ( $cb, $objects, $deferred, $errors, $callback ) = @_;

    my %restored_objects;
    for my $key ( keys %$objects ) {
        if ( $key =~ /^MT::(:?Entry|Page)#(\d+)$/ ) {
            $restored_objects{ $1 } = $objects->{ $key };
        }
    }

    require CustomFields::Field;

    my %class_fields;
    $callback->(
        MT->translate(
            "Restoring entry/page associations found in custom fields ...",
        ),
        'cf-restore-object-entrypage'
    );

    my $r = MT::Request->instance();
    for my $restored_object ( values %restored_objects ) {
        my $iter = CustomFields::Field->load_iter( { blog_id  => [ $restored_object->blog_id, 0 ],
                                                     type => [ 'entry', 'entry_multi', 'page', 'page_multi' ],
                                                   }
                                                 );
        while ( my $field = $iter->() ) {
            my $class = MT->model( $field->obj_type );
            next unless $class;
            my @related_objects = $class->load( { blog_id => $restored_object->blog_id } );
            my $column_name = 'field.' . $field->basename;
            for my $related_object ( @related_objects ) {
                my $cache_key = $class . ':' . $related_object->id . ':' . $column_name;
                next if $r->cache( $cache_key );
                my $value = $related_object->$column_name;
                my $restored_value;
                if ( $field->type eq 'entry' ) {
                    my $restored = $objects->{ 'MT::Entry#' . $value };
                    if ( $restored ) {
                        $restored_value = $restored->id;
                    }
                } elsif ( $field->type eq 'page' ) {
                    my $restored = $objects->{ 'MT::Page#' . $value };
                    if ( $restored ) {
                        $restored_value = $restored->id;
                    }
                } elsif ( $field->type eq 'entry_multi' ) {
                    my @values = split( /,/, $value );
                    my @new_values;
                    for my $backup_id ( @values ) {
                        next unless $backup_id;
                        next unless $objects->{ 'MT::Entry#' . $backup_id };
                        my $restored_obj = $objects->{ 'MT::Entry#' . $backup_id };
                        push( @new_values, $restored_obj->id );
                    }
                    if ( @new_values ) {
                        $restored_value = ',' . join( ',', @new_values ) . ',';
                    }
                } elsif ( $field->type eq 'page_multi' ) {
                    my @values = split( /,/, $value );
                    my @new_values;
                    for my $backup_id ( @values ) {
                        next unless $backup_id;
                        next unless $objects->{ 'MT::Page#' . $backup_id };
                        my $restored_obj = $objects->{ 'MT::Page#' . $backup_id };
                        push( @new_values, $restored_obj->id );
                    }
                    if ( @new_values ) {
                        $restored_value = ',' . join( ',', @new_values ) . ',';
                    }
                }
                $related_object->$column_name( $restored_value );
                $related_object->save or die $related_object->errstr;
                $r->cache( $cache_key, 1 );
            }
        }
    }
    $callback->( MT->translate( "Done." ) . "\n" );
}

1;
