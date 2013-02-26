package ObjectGroup::Plugin;

use strict;
# use ObjectGroup::ObjectGroup;
# use ObjectGroup::ObjectOrder;
use CustomGroup::Util qw( is_user_can );

sub _group_permission {
    my ( $blog ) = @_;
    my $app = MT->instance();
    my $user = $app->user;
    if ( $user->is_superuser || $app->param( 'dialog_view' ) ) {
        return 1;
    }
    if ( $blog && ( ref $blog ne 'MT::Blog' ) ) {
        $blog = undef;
    }
    $blog ||= $app->blog;
    if (! $blog ) {
        return 1 if $user->can_manage_objectgroup;
        my %terms1 = ( author_id => $app->user->id, blog_id => { not => 0 }, permissions => { like => "%'administer_%" } );
        my %terms2 = ( author_id => $app->user->id, blog_id => { not => 0 }, permissions => { like => "%'manage_objectgroup'%" } );
        require MT::Permission;
        if ( my $perms = MT::Permission->count( [ \%terms1, '-or', \%terms2 ] ) ) {
            return 1;
        }
        return 0;
    }
    if ( is_user_can( $blog, $user, 'administer_blog' ) ||
         is_user_can( $blog, $user, 'administer_website' ) ||
         is_user_can( $blog, $user, 'manage_objectgroup' ) ) {
        return 1;
    }
    return 0;
}

sub _edit_author {
    my ( $cb, $app, $param, $tmpl ) = @_;
    if ( my $id = $app->param( 'id' ) ) {
        my $author = MT->model( 'author' )->load( $id );
        my $loaded_permissions = $param->{ loaded_permissions };
        my @new_perms;
        for my $perm ( @$loaded_permissions ) {
            if ( $perm->{ id } eq 'can_manage_objectgroup' ) {
                if ( $author->is_superuser ) {
                    $perm->{ can_do } = 1;
                } else {
                    $perm->{ can_do } = $author->can_manage_objectgroup;
                }
            }
            push ( @new_perms, $perm );
        }
        $param->{ loaded_permissions } = \@new_perms;
    }
}

sub _delete_entry {
    my ( $eh, $app, $obj, $original ) = @_;
    require ObjectGroup::ObjectOrder;
    my @groups = ObjectGroup::ObjectOrder->load( { object_ds => 'entry',
                                                   object_id => $obj->id } );
    for my $group ( @groups ) {
        $group->remove or die $group->errstr;
    }
}

sub _delete_category {
    my ( $eh, $app, $obj, $original ) = @_;
    require ObjectGroup::ObjectOrder;
    my @groups = ObjectGroup::ObjectOrder->load( { object_ds => 'category',
                                                   object_id => $obj->id } );
    for my $group ( @groups ) {
        $group->remove or die $group->errstr;
    }
}

sub _edit_objectgroup_param {
    my($cb, $app, $param, $tmpl) = @_;
    my $entries_limit = 1000;
    my $cfg_plugin = $app->component( 'ObjectGroupConfig' );
    if ( $app->blog ) {
        $entries_limit = $cfg_plugin->get_config_value( 'og_entries_limit', 'blog:'. $app->blog->id );
    } else {
        $entries_limit = $cfg_plugin->get_config_value( 'og_entries_limit' );
    }
    $entries_limit = 1000 unless $entries_limit =~ /^\d+$/;
    $param->{ entries_limit } = $entries_limit;
}

sub _edit_template_param {
    my ( $cb, $app, $param, $tmpl ) = @_;
    if ( $app->param( 'id' ) ) {
        return;
    }
    my $group_id = $app->param( 'objectgroup_id' )
        or return;
    require ObjectGroup::ObjectGroup;
    my $plugin = MT->component( 'CustomGroup' );
    my $cfg_plugin = MT->component( 'ObjectGroupConfig' );
    my $group = ObjectGroup::ObjectGroup->load( $group_id )
        or return;
    my $group_name = $group->name;
    my $template;
    if ( $app->blog ) {
        $template = $cfg_plugin->get_config_value( 'default_module_mtml', 'blog:'. $app->blog->id );
    } else {
        $template = $cfg_plugin->get_config_value( 'default_module_mtml' );
    }
    $template ||= _default_module_mtml();
    $template =~ s/\$group_name/$group_name/ig;
    $template =~ s/\$group_id/$group_id/ig;
    my $hidden_field = qq{<input type="hidden" name="objectgroup_id" value="$group_id" />};
    $param->{ name } = $plugin->translate( 'Object Group' ) . ' : ' . $group_name;
    $param->{ text } = $template;
    my $pointer_field = $tmpl->getElementById( 'title' );
    my $innerHTML = $pointer_field->innerHTML;
    $pointer_field->innerHTML( $innerHTML . $hidden_field );
}

sub _cms_post_save_template {
    my ( $cb, $app, $obj, $original ) = @_;
    if ( $original->id ) {
        return 1;
    }
    my $type = $obj->type;
    if ( $type ne 'custom' ) {
        return 1;
    }
    if ( my $group_id = $app->param( 'objectgroup_id' ) ) {
        require ObjectGroup::ObjectGroup;
        if ( my $group = ObjectGroup::ObjectGroup->load( $group_id ) ) {
            $group->template_id( $obj->id );
            $group->save or die $group->errstr;
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
    require ObjectGroup::ObjectGroup;
    if ( my $group = ObjectGroup::ObjectGroup->load( { template_id => $obj->id } ) ) {
        $group->template_id( undef );
        $group->save or die $group->errstr;
    }
    return 1;
}

sub _delete_blog {
    my ( $eh, $app, $obj, $original ) = @_;
    require ObjectGroup::ObjectOrder;
    my @groups = ObjectGroup::ObjectOrder->load( { object_ds => 'blog',
                                                   object_id => $obj->id } );
    for my $group ( @groups ) {
        $group->remove or die $group->errstr;
    }
}

sub _default_module_mtml {
    my $tmplate = <<'MTML';
<MTObjectGroupItems id="$group_id">
<MTIf name="__first__"><ul></MTIf>
    <MTObjectGroupItemClass setvar="item_class">
    <MTIfObjectGroupItemIsEntry>
        <MTIf name="item_class" eq="entry">
            <li class="entry"><a href="<MTEntryPermalink>"><MTEntryTitle escape="html"></a></li>
        <MTElseIf name="item_class" eq="page">
            <li class="page"><a href="<MTPagePermalink>"><MTPageTitle escape="html"></a></li>
        </MTIf>
    <MTElse>
    <MTIfObjectGroupItemIsCategory>
        <MTIf name="item_class" eq="category">
            <li class="category"><a href="<MTCategoryArchiveLink>"><MTCategoryLabel escape="html"></a></li>
        <MTElseIf name="item_class" eq="folder">
            <li class="folder"><MTFolderLabel escape="html"></li>
        </MTIf>
    <MTElse>
    <MTIfObjectGroupItemIsBlog>
        <MTIf name="item_class" eq="blog">
            <li class="blog"><a href="<MTBlogURL>"><MTBlogName escape="html"></a></li>
        <MTElseIf name="item_class" eq="website">
            <li class="blog"><a href="<MTWebsiteURL>"><MTWebsiteName escape="html"></a></li>
        </MTIf>
    </MTIfObjectGroupItemIsBlog>
    </MTElse>
    </MTIfObjectGroupItemIsCategory>
    </MTElse>
    </MTIfObjectGroupItemIsEntry>
<MTIf name="__last__"></ul></MTIf>
</MTObjectGroupItems>
MTML
    return $tmplate;
}

sub _cb_restore {
    my ( $cb, $objects, $deferred, $errors, $callback ) = @_;

    my %restored_objects;
    for my $key ( keys %$objects ) {
        if ( $key =~ /^ObjectGroup::ObjectGroup#(\d+)$/ ) {
            $restored_objects{ $1 } = $objects->{ $key };
        }
    }

    require CustomFields::Field;

    my %class_fields;
    $callback->(
        MT->translate(
            "Restoring objectgroup associations found in custom fields ...",
        ),
        'cf-restore-object-objectgroup'
    );

    my $r = MT::Request->instance();
    for my $restored_object ( values %restored_objects ) {
        my $iter = CustomFields::Field->load_iter( { blog_id  => [ $restored_object->blog_id, 0 ],
                                                     type => [ 'objectgroup' ],
                                                   }
                                                 );
        while ( my $field = $iter->() ) {
            my $class = MT->model( $field->obj_type )
                or next;
            my @related_objects = $class->load( { blog_id => $restored_object->blog_id } );
            my $column_name = 'field.' . $field->basename;
            for my $related_object ( @related_objects ) {
                my $cache_key = $class . ':' . $related_object->id . ':' . $column_name;
                next if $r->cache( $cache_key );
                my $value = $related_object->$column_name;
                my $restored_value;
                if ( $field->type eq 'objectgroup' ) {
                    my $restored = $objects->{ 'ObjectGroup::ObjectGroup#' . $value };
                    if ( $restored ) {
                        $restored_value = $restored->id;
                    }
                }
                $related_object->$column_name( $restored_value );
                $related_object->save or die $related_object->errstr;
                $r->cache( $cache_key, 1 );
            }
        }
    }
    $callback->( MT->translate( "Done." ) . "\n" );

    # Restore template_id
    for my $key ( keys %$objects ) {
        next unless $key =~ /^ObjectGroup::ObjectGroup#\d+$/;
        my $new_group = $objects->{$key};
        my $template_id = $new_group->template_id
            or next;
        my $new_template = $objects->{ 'MT::Template#'.$template_id };
        $new_group->template_id( $new_template ? $new_template->id : undef );
        $new_group->update();
    }

    1;
}

1;
