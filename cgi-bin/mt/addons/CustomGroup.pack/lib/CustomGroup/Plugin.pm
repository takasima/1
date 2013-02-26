package CustomGroup::Plugin;

use strict;
use MT::I18N qw( substr_text length_text );
use MT::Util qw( encode_html encode_url );
use CustomGroup::Util qw( is_user_can );

sub _cb_customorder_post_save {
    my ( $cb, $obj ) = @_;
    unless ( $obj->group_class ) {
        if ( my $group_id = $obj->group_id() ) {
            if ( my $customgroup = MT->model( 'customgroup' )->load( { id => $group_id } ) ) {
                $obj->group_class( $customgroup->class );
                $obj->save or die $obj->errstr;
            }
        }
    }
    1;
}

sub _cms_post_save {
    my ( $cb, $app, $obj, $original ) = @_;
    if ( defined $original && $original->id ) {
        return 1;
    }
    if ( $obj->id < 0 ) {
        return 1;
    }
    if ( $app->param( 'orig_id' ) ) {
        return 1;
    }
    my $return_args = $app->param( 'return_args' );
    if ( $return_args && ( $return_args =~ /&is_power_edit=1/ ) ) {
        return 1;
    }
    if ( $obj->has_column( 'status' ) ) {
        # Entry Template
        if ( $obj->status == 7 ) {
            return 1;
        }
    }
    my $model;
    if ( $obj->has_column( 'class' ) ) {
        $model = $obj->class;
    } else {
        $model = $obj->datasource;
    }
    my $blog = $app->blog;
    if ( ( ref $obj ) eq 'MT::Website' ) {
        $blog = $obj;
    }
    return 1 unless $blog;
    my $custom_groups = MT->registry( 'custom_groups' );
    my @objects = keys( %$custom_groups );
    my @custom_groups;
    for my $object ( @objects ) {
        my $filter_class = $custom_groups->{ $object }->{ filter_class };
        if ( $filter_class ) {
            if ( ( ref $filter_class ) eq 'ARRAY' ) {
                if ( grep( /^$model$/, @$filter_class ) ) {
                    push ( @custom_groups, $object );
                }
            } else {
                if ( $filter_class eq $model ) {
                    push ( @custom_groups, $object );
                }
            }
        }
    }
    return 1 unless @custom_groups;
    my $class = MT->model( $model );
    my @blog_ids;
    push ( @blog_ids, $blog->id );
    if ( $blog->class eq 'website' ) {
        my $blogs = $blog->blogs;
        for my $b ( @$blogs ) {
            push ( @blog_ids, $b->id );
        }
    } else {
        push ( @blog_ids, $blog->parent_id );
    }
    push ( @blog_ids, 0 );
    for my $group_id ( @custom_groups ) {
        my $group_class = MT->model( $group_id );
        my $child_object_ds = $group_class->child_object_ds;
        my $id_column = 'blog_id';
        if ( $child_object_ds eq 'blog' ) {
            $id_column = 'parent_id';
        }
        my @groups = $group_class->load( { additem => 1, blog_id => \@blog_ids } );
        for my $group ( @groups ) {
            my $addfilter = $group->addfilter;
            if ( $addfilter ) {
                if ( $addfilter eq 'blog' ) {
                    my $addfilter_blog_id = $group->addfilter_blog_id;
                    if ( $addfilter_blog_id ) {
                        if ( $obj->$id_column != $addfilter_blog_id ) {
                            next;
                        }
                    }
                } elsif ( $addfilter eq 'tag' ) {
                    if (! $class->isa( 'MT::Taggable' ) ) {
                        next;
                    }
                    my $addfiltertag = $group->addfiltertag;
                    my @tags = $obj->get_tags;
                    if (! grep( /^$addfiltertag$/, @tags ) ) {
                        next;
                    }
                } elsif ( $addfilter eq 'category' ) {
                    my $cid = $group->addfilter_cid
                        or return;
                    require MT::Category;
                    if ( my $category = MT::Category->load( $cid ) ) {
                        if (! $obj->is_in_category( $category ) ) {
                            next;
                        }
                    }
                }
            }
            my $direction = $group->addposition ? 'descend' : 'ascend';
            require CustomGroup::GroupOrder;
            my $last = CustomGroup::GroupOrder->load( { group_id => $group->id },
                                                      { sort => 'order',
                                                        direction => $direction,
                                                        limit => 1, } );
            my $pos = 500;
            if ( $last ) {
                $pos = $last->order;
                if ( $group->addposition ) {
                    $pos++;
                } else {
                    $pos--;
                }
            }
#             my $order = CustomGroup::GroupOrder->get_by_key(
#                                                       { group_id => $group->id,
#                                                         order => $pos,
#                                                         object_id => $obj->id } );
            my $order = CustomGroup::GroupOrder->get_by_key(
                                                      { group_id => $group->id,
                                                        object_id => $obj->id } );
            $order->order( $pos );
            $order->save or die $order->errstr;
        }
    }
    1;
}

sub _template_param {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $r = MT::Request->instance;
    my $k = 'plugin-customgroup-cb-template-param';
    $r->cache($k)
        and return 1
        or $r->cache($k, 1);
    my $mode = $app->param( '__mode' )
        or return;
    my $type = $app->param( '_type' );
    if ( $mode eq 'view' ) {
        my $custom_groups = MT->registry( 'custom_groups' );
        if ( $custom_groups->{ $type } ) {
            my $file = $tmpl->{ __file };
            if ( $file eq "edit_$type.tmpl" ) {
                return _edit_group( $cb, $app, $param, $tmpl );
            }
        }
    }
    unless ( $mode eq 'view' || $mode eq 'list' ) {
        return;
    }
    if ( $type ne 'objectgroup' ) {
        return;
    }
    my $user = $app->user
        or return;
    if ( my $blog = $app->blog ) {
        if (! is_user_can( $blog, $user, 'manage_objectgroup' ) ) {
            $app->permission_denied();
        }
    } elsif (! $user->is_superuser && ! $user->can_manage_objectgroup ) {
        $app->permission_denied();
    }
}

sub _edit_group {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $plugin = MT->component( 'CustomGroup' );
    my $type = $app->param( '_type' );
    $param->{ _type } = $type;
    my $custom_group = MT->registry( 'custom_groups' )->{ $type };
    my $edit_permission = $custom_group->{ edit_permission };
    $edit_permission = MT->handler_to_coderef( $edit_permission );
    my $class = $app->model( $type );
    my $child_class = $class->child_class;
    my $search_class;
    my $child_object_ds = $class->child_object_ds;
    my $id_column = 'blog_id';
    if ( $child_object_ds eq 'blog' ) {
        $id_column = 'id';
    }
    my $ref = ref $child_class;
    if ( $ref && ( $ref eq 'ARRAY' ) ) {
        $search_class = $child_class;
        $child_class = $child_object_ds;
        $param->{ screen_group } = 'objectgroup';
    } else {
        $param->{ search_type } = $child_class;
        $param->{ screen_group } = $child_class;
    }
    my $child_object = MT->model( $child_class );
    unless ( $ref && ( $ref eq 'ARRAY' ) ) {
        $param->{ search_label } = $child_object->class_label;
    }
    if ( $child_object->isa( 'MT::Taggable' ) ) {
        $param->{ taggable } = 1;
    }
    $param->{ child_class } = $child_class;
    my $blog = $app->blog;
    # TODO::Permission
    my $id = $app->param( 'id' );
    my $obj;
    if ( $id ) {
        $obj = $class->load( $id );
        if (! defined $obj ) {
            $app->return_to_dashboard( permission => 1 );
        }
        if ( $obj->blog_id != $app->param( 'blog_id' ) ) {
            $app->return_to_dashboard( permission => 1 );
        }
        $param->{ group_name } = $obj->name;
    }
    my %blogs;
    my @weblog_loop;
    my $website_view;
    my $system_view;
    my $blog_view;
    my @blog_ids;
    my @cat_loop;
    my %terms;
    require MT::Blog;
    my $filter = $app->param( 'filter' );
    my $filter_container = $app->param( 'filter_container' );
    if ( $search_class ) {
        $terms{ class } = $search_class;
    }
    if ( $filter ) {
        # asset
        if ( $filter ne 'tag' ) {
            # %terms = ( class => $filter );
        # } else {
            # %terms = ( class => '*' );
            if ( $app->model( $filter ) ) {
                if ( $child_object->has_column( 'class' ) ) {
                    $terms{ class } = $filter;
                }
            }
        }
    }
    my %args;
    $args{ direction } = 'descend';
    my @all_blogs;
    if (! defined $app->blog ) {
        if (! _group_permission() ) {
            $app->return_to_dashboard( redirect => 1 );
        }
        $param->{ scope_type } = 'system';
        $system_view = 1;
        @all_blogs = MT::Blog->load( { class => [ 'website', 'blog' ] } );
        for my $blog ( @all_blogs ) {
            if ( _group_permission( $blog ) ) {
                $blogs{ $blog->id } = $blog;
                push( @blog_ids, $blog->id );
                push @weblog_loop, {
                        weblog_id => $blog->id,
                        weblog_name => $blog->name, };
            }
        }
        $param->{ weblog_loop } = \@weblog_loop;
    } else {
        if (! _group_permission( $app->blog ) ) {
            $app->return_to_dashboard( redirect => 1 );
        }
        if ( $app->blog->class eq 'website' ) {
            push @weblog_loop, {
                    weblog_id => $app->blog->id,
                    weblog_name => $app->blog->name, };
            $website_view = 1;
            $blogs{ $app->blog->id } = $app->blog;
            push ( @blog_ids, $app->blog->id );
            @all_blogs = MT::Blog->load( { parent_id => $app->blog->id } );
            if ( $type eq 'blogwebsitegroup' ) {
                push ( @all_blogs, $app->blog );
            }
            for my $blog ( @all_blogs ) {
                if ( _group_permission( $blog ) ) {
                    $blogs{ $blog->id } = $blog;
                    push ( @blog_ids, $blog->id );
                    push @weblog_loop, {
                            weblog_id => $blog->id,
                            weblog_name => $blog->name, };
                }
            }
            # unshift( @all_blogs, $app->blog );
            $param->{ weblog_loop } = \@weblog_loop;
        } else {
            $blog_view = 1;
            push ( @blog_ids, $app->blog->id );
            $blogs{ $app->blog->id } = $app->blog;
        }
        if (! $blog_view ) {
            $terms{ $id_column } = \@blog_ids;
        } else {
            $terms{ $id_column } = $app->blog->id;
        }
    }
    if ( $child_object_ds eq 'entry' ) {
        require MT::Category;
        my $cat_args;
        $cat_args->{ blog_id } = \@blog_ids;
        if ( $type eq 'entrypagegroup' ) {
            $cat_args->{ class } = '*';
        } elsif ( $type eq 'entrygroup' ) {
            $cat_args->{ class } = 'category';
        } elsif ( $type eq 'pagegroup' ) {
            $cat_args->{ class } = 'folder';
        }
        my @category_loop;
        my @categories = MT::Category->load( $cat_args, { sort => 'blog_id' } );
        for my $category ( @categories ) {
            my $weblog_name = $blogs{ $category->blog_id }->name;
            $weblog_name = substr_text( $weblog_name, 0, 15 ) . ( length_text( $weblog_name ) > 15 ? '...' : '' );
            $weblog_name &&= " ($weblog_name)";
            push @category_loop, {
                    category_id => $category->id,
                    category_label => $category->label . $weblog_name,
                    class => $category->class, };
        }
        $param->{ category_loop } = \@category_loop;
    }
    my @objects;
    if ( $filter && ( $filter eq 'tag' ) ) {
        require MT::Tag;
        my $tag = MT::Tag->load( { name => $app->param( 'filter_tag' ) }, { binary => { name => 1 } } );
        if ( $tag ) {
            require MT::ObjectTag;
            $args{ 'join' } = [ 'MT::ObjectTag', 'object_id',
                       { tag_id => $tag->id,
                         blog_id => \@blog_ids,
                         object_datasource => $child_object_ds }, ];
            @objects = MT->model( $child_class )->load( \%terms, \%args );
        }
    } elsif ( $filter && ( $filter eq 'container_id' ) ) {
        require MT::Placement;
        $args{ 'join' } = [ 'MT::Placement', 'entry_id',
            { category_id => $filter_container }, { unique => 1 } ];
        @objects = MT->model( $child_class )->load( \%terms, \%args );
    } elsif ( $child_object_ds eq 'blog' ) {
        @objects = @all_blogs;
    } else {
        @objects = MT->model( $child_class )->load( \%terms, \%args );
    }
    $param->{ object_ds } = $child_object_ds;
    my @item_loop;
    for my $object ( @objects ) {
        my $add_item = 1;
        if ( $id ) {
            require CustomGroup::GroupOrder;
            my $item = CustomGroup::GroupOrder->load( { group_id => $id, object_id => $object->id } );
            $add_item = 0 if defined $item;
        }
        next unless $add_item;
        my $weblog_name = '';
        if (! $blog_view ) {
            if ( $child_object_ds eq 'blog' ) {
                next unless $blogs{ $object->$id_column };
                $weblog_name = $blogs{ $object->$id_column }->is_blog
                                                                ? $blogs{ $object->$id_column }->website->name
                                                                : '';
            } else {
                $weblog_name = $blogs{ $object->$id_column }->name;
            }
            $weblog_name = substr_text( $weblog_name, 0, 15 ) . ( length_text( $weblog_name ) > 15 ? '...' : '' );
            $weblog_name &&= " ($weblog_name)";
        }
        my ( $label, $status, $class );
        if ( $object->has_column( 'title' ) ) {
            $label = $object->title;
        } elsif ( $object->has_column( 'name' ) ) {
            $label = $object->name;
        } elsif ( $object->has_column( 'label' ) ) {
            $label = $object->label;
        }
        $label = substr_text( $label, 0, 15 ) . ( length_text( $label ) > 15 ? '...' : '' );
        if ( $object->has_column( 'status' ) ) {
            $status = $object->status;
        }
        if ( $object->has_column( 'class' ) ) {
            $class = $object->class;
        }
        if ( $custom_group->{ filter_class } &&
            ( $custom_group->{ filter_class } eq 'website' ) ) {
            if ( $class ne 'website' ) {
                next;
            }
        }
        my $can_edit = $edit_permission->( $app->user, $object );
        push @item_loop, {
            id => $object->id,
            can_edit => $can_edit,
            item_name => $label . $weblog_name,
            status => $status,
            class => $class,
            weblog_id => $object->$id_column,
        };
    }
    $param->{ item_loop } = \@item_loop;
    if ( $id ) {
        require CustomGroup::GroupOrder;
        my $args = { 'join' => [ 'CustomGroup::GroupOrder', 'object_id',
                        { group_id => $id },
                        { sort => 'order',
                          direction => 'ascend',
                        } ] };
        my @objects = MT->model( $child_class )->load( \%terms, $args );
        my @group_loop;
        for my $object ( @objects ) {
            my $weblog_name = '';
            if (! $blog_view ) {
                if ( $child_object_ds eq 'blog' ) {
                    $weblog_name = $blogs{ $object->$id_column }->is_blog
                                                                    ? $blogs{ $object->$id_column }->website->name
                                                                    : '';
                } else {
                    $weblog_name = $blogs{ $object->$id_column }->name;
                }
                $weblog_name &&= " ($weblog_name)";
            }
            my ( $label, $status, $class );
            if ( $object->has_column( 'title' ) ) {
                $label = $object->title;
            } elsif ( $object->has_column( 'name' ) ) {
                $label = $object->name;
            } elsif ( $object->has_column( 'label' ) ) {
                $label = $object->label;
            }
            $label = substr_text( $label, 0, 15 ) . ( length_text( $label ) > 15 ? '...' : '' );
            if ( $object->has_column( 'status' ) ) {
                $status = $object->status;
            }
            if ( $object->has_column( 'class' ) ) {
                $class = $object->class;
            }
            my $can_edit = $edit_permission->( $app->user, $object );
            push @group_loop, {
                    id => $object->id,
                    can_edit => $can_edit,
                    item_name => $label . $weblog_name,
                    status => $status,
                    class => $class,
                    weblog_id => $object->$id_column, };
        }
        $param->{ group_loop } = \@group_loop;
    }
    $param->{ saved } = $app->param( 'saved' );
    $param->{ filter } = $filter;
    if (! $app->param( 'id' ) ) {
        my $top_nav_loop = $param->{ top_nav_loop };
        my $mode = $app->mode;
        for my $nav ( @$top_nav_loop ) {
            my $sub_nav = $nav->{ sub_nav_loop }
                or next;
            for my $sub_sub ( @$sub_nav ) {
                if ( $sub_sub->{ id } eq $child_class . ':create_' . $type ) {
                    $sub_sub->{ current } = 1;
                    last;
                }
            }
        }
    }
    $param->{ return_args } = _force_view_mode_return_args( $app );
    if ( my $filter_tag = $app->param( 'filter_tag' ) ) {
        $param->{ filter_tag } = $filter_tag;
        $param->{ return_args } = $param->{ return_args } . '&filter_tag=' . encode_url( $filter_tag );
    }
    if ( $filter_container ) {
        $param->{ filter_container } = $filter_container;
        $param->{ return_args } = $param->{ return_args } . '&filter_container=' . encode_url( $filter_container );
    }
}

sub _edit_template_param {
    my ( $cb, $app, $param, $tmpl ) = @_;
    if ( $app->param( 'id' ) ) {
        return;
    }
    my $blog = $app->blog;
    my $group_id = $app->param( 'group_id' )
        or return;
    require CustomGroup::CustomGroup;
    my $group = CustomGroup::CustomGroup->load( $group_id )
        or return;
    my $group_class = $app->param( 'group_class' );
    my $plugin = $app->model( $group_class )->plugin
        or return;
    my $custom_groups = MT->registry( 'custom_groups' );
    my $custom_group = $custom_groups->{ $group_class };
    my $group_name = $group->name;
    $group_id = $group->id;
    my $tmplate = $plugin->get_config_value( 'default_module_' . $group_class, $blog ? 'blog:'. $blog->id : undef ) ||
                  $app->model( $group_class )->default_module_mtml;
    $tmplate =~ s/\$group_id/$group_id/ig;
    $tmplate =~ s/\$group_name/$group_name/ig;
    my $hidden_field = '<input type="hidden" name="group_id" value="' . $group->id . '" />';
    $hidden_field .= '<input type="hidden" name="group_class" value="' . $group->class . '" />';
    $param->{ name } = $plugin->translate( $custom_group->{ name } ) . ' : ' . $group_name;
    $param->{ text } = $tmplate;
    my $pointer_field = $tmpl->getElementById( 'title' );
    my $innerHTML = $pointer_field->innerHTML;
    $pointer_field->innerHTML( $innerHTML . $hidden_field );
}

sub _cms_pre_save_field {
    my ( $cb, $app, $obj, $original ) = @_;
    my $custom_groups = MT->registry( 'custom_groups' );
    my @objects = keys( %$custom_groups );
    my $is_custom_group = 0;
    for my $object ( @objects ) {
        if ( $obj->type eq $object ) {
            $is_custom_group = 1;
            last;
        }
    }
    $obj->customgroup( $is_custom_group );
    return 1;
}

sub _cms_post_save_template {
    my ( $cb, $app, $obj, $original ) = @_;
    if (! $original->id ) {
        my $type = $obj->type;
        if ( $type ne 'custom' ) {
            return 1;
        }
        my $group_id = $app->param( 'group_id' );
        if ( $group_id ) {
            require CustomGroup::CustomGroup;
            my $group = CustomGroup::CustomGroup->load( $group_id );
            if ( $group ) {
                $group->template_id( $obj->id );
                $group->save or die $group->errstr;
            }
        }
    }
    return 1;
}

sub _cms_post_delete_template {
    my ( $cb, $app, $obj, $original ) = @_;
    my $type = $obj->type;
    if ( $type ne 'custom' ) {
        return 1;
    }
    require CustomGroup::CustomGroup;
    if ( my $group = CustomGroup::CustomGroup->load( { template_id => $obj->id, class => $obj->group_class } ) ) {
        $group->template_id( undef );
        $group->save or die $group->errstr;
    }
    return 1;
}

sub _group_permission {
    my ( $blog, $class ) = @_;
    my $app = MT->instance();
    if ($app->param( 'dialog_view' )) {
        return 1;
    }
    my $user = $app->user;
    return 1 if $user->is_superuser;
    $class ||= $app->param( '_type' ) || $app->param( 'datasource' )
        or return 0;
    # $class =~ s/groupgroup$/group/;
    if ( $blog && ( ref $blog ne 'MT::Blog' ) ) {
        $blog = undef;
    }
    $blog ||= $app->blog;
    if (! $blog ) {
        my %terms1 = ( author_id => $app->user->id, blog_id => { not => 0 }, permissions => { like => "%'administer_%" } );
        my %terms2 = ( author_id => $app->user->id, blog_id => { not => 0 }, permissions => { like => "%'manage_$class'%" } );
        require MT::Permission;
        if ( my $perms = MT::Permission->count( [ \%terms1, '-or', \%terms2 ] ) ) {
            return 1;
        }
        return 0;
    }
    if ( is_user_can( $blog, $user, 'administer_blog' ) ||
         is_user_can( $blog, $user, 'administer_website' ) ||
         is_user_can( $blog, $user, "manage_$class" ) ) {
        return 1;
    }
    return 0;
}

sub _force_view_mode_return_args {
    my $app = shift;
    my $return = $app->make_return_args;
    $return =~ s/edit/view/;
    return $return;
}

sub _footer_source {
    my ( $cb, $app, $tmpl ) = @_;
    my $id = MT->component(__PACKAGE__ =~ /^([^:]+)/)->id;
    $$tmpl =~ s{(<__trans phrase="http://www\.sixapart\.com/movabletype/">)}
               {<mt:if name="id" eq="$id"><__trans phrase="http://alfasado.net/"><mt:else>$1</mt:if>};
}

sub _cb_restore {
    my ( $cb, $objects, $deferred, $errors, $callback ) = @_;

    my $plugin = MT->component( 'CustomGroup' );

    my $custom_groups = MT->registry( 'custom_groups' );
    my @custom_group_models = keys %$custom_groups;
    my @custom_group_classes = map { MT->model( $_ ) } @custom_group_models;

    my %restored_objects;
    for my $key ( keys %$objects ) {
        if ( grep { $key =~ /^\Q$_\E#(\d+)$/ } @custom_group_classes ) {
                $restored_objects{ $key } = $objects->{ $key };
        }
    }

    require CustomFields::Field;

    my %class_fields;
    $callback->(
        $plugin->translate(
            "Restoring customgroup associations found in custom fields ...",
        ),
        'cf-restore-object-customgroup'
    );

    my $r = MT::Request->instance();
    if ( %restored_objects ) {
        for my $restored_object ( values %restored_objects ) {
            my $iter = CustomFields::Field->load_iter( { blog_id => [ $restored_object->blog_id, 0 ],
                                                         type => \@custom_group_models,
                                                       }
                                                     );
            while ( my $field = $iter->() ) {
                my $class = MT->model( $field->obj_type )
                    or next;
                my @related_objects = $class->load( $class->has_column( 'blog_id' ) ? { blog_id => $restored_object->blog_id } : undef );
                my $column_name = 'field.' . $field->basename;
                for my $related_object ( @related_objects ) {
                    my $cache_key = $class . ':' . $related_object->id . ':' . $column_name;
                    next if $r->cache( $cache_key );
                    my $value = $related_object->$column_name;
                    my $restored = $objects->{ MT->model( $field->type ) . '#' . $value };
                    my $restored_value = $restored ? $restored->id : undef;
                    $related_object->$column_name( $restored_value );
                    $related_object->save or die $related_object->errstr;
                    $r->cache( $cache_key, 1 );
                }
            }
        }
    } else {
        my @target_classes;
        for my $custom_group_class ( @custom_group_classes ) {
            my $custom_group_child_classes = $custom_group_class->child_class()
                or next;
            unless ( ref ( $custom_group_child_classes ) eq 'ARRAY' ) {
                $custom_group_child_classes = [ $custom_group_child_classes ];
            }
            for my $custom_group_child_class ( @$custom_group_child_classes ) {
                my $class = MT->model( $custom_group_child_class );
                push( @target_classes, $class );
            }
        }
        for my $key ( keys %$objects ) {
            next unless grep { $key =~ /^\Q$_\E#\d+$/ } @target_classes;
            my $restored_object = $objects->{ $key };
            my $blog_id;
            if ( ( ref $restored_object ) =~ /^MT::(?:Website|Blog)$/ ) {
                $blog_id = $restored_object->id;
            } else {
                $blog_id = $restored_object->blog_id;
            }
            my $iter = CustomFields::Field->load_iter( { blog_id => [ $blog_id, 0 ],
                                                         type => \@custom_group_models,
                                                       }
                                                     );
            while ( my $field = $iter->() ) {
                my $column_name = 'field.' . $field->basename;
                next unless $restored_object->has_column( $column_name );
                my $cache_key = $key . ':' . $restored_object->id . ':' . $column_name;
                next if $r->cache( $cache_key );
                $restored_object->$column_name( undef );
                $restored_object->save or die $restored_object->errstr;
                $r->cache( $cache_key, 1 );
            }
        }
    }
    $callback->( MT->translate( "Done." ) . "\n" );

    # Restore template_id and addfilter_cid
    my @category_classes = ( MT->model( 'category' ), MT->model( 'folder' ) );
    for my $key ( keys %$objects ) {
        next unless grep { $key =~ /^\Q$_\E#\d+$/ } @custom_group_classes;
        my $new_group = $objects->{$key};
        my $change = 0;
        if ( my $template_id = $new_group->template_id ) {
            my $new_template = $objects->{ 'MT::Template#'.$template_id };
            $new_group->template_id( $new_template ? $new_template->id : undef );
            $change = 1;
        }

        if ( my $addfilter_cid = $new_group->addfilter_cid ) {
            $new_group->addfilter_cid( undef );
            $change = 1;

            foreach my $category_class ( @category_classes ) {
                my $new_category = $objects->{ $category_class.'#'.$addfilter_cid };
                if ( $new_category ) {
                    $new_group->addfilter_cid( $new_category->id );
                    last;
                }
            }
        }

        $new_group->update() if $change;
    }
    1;
}

sub _cb_blog_post_delete { # especially for 'customgroup'
    my ( $cb, $app, $obj ) = @_;
    my $blog_id = $obj->id;
    my @object_models = ( 'customgroup', 'grouporder' );
    for my $model ( @object_models ) {
        my @objects = MT->model( $model )->load( { blog_id => $blog_id,
                                                   class => '*',
                                                 }
                                               );
        for my $object ( @objects ) {
           $object->remove;
        }
    }
    1;
}

sub _cb_post_delete_object {
    my ( $cb, $app, $obj ) = @_;
    my @objects = MT->model( 'grouporder' )->load( { object_class => $obj->class,
                                                     object_id => $obj->id,
                                                   }
                                           );
    for my $object ( @objects ) {
       $object->remove;
    }
    1;
}

1;
