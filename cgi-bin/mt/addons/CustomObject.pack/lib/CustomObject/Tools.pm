package CustomObject::Tools;

use CustomObject::Util qw( current_ts );
use strict;

sub clone_object {
    my ( $cb, %param ) = @_;
    my $old_blog_id = $param{ old_blog_id };
    my $new_blog_id = $param{ new_blog_id };
    my $callback    = $param{ callback };
    my $app         = MT->instance;
    my $component = MT->component( 'CustomObject' );
    my $custom_objects = MT->registry( 'custom_objects' );
    my @objects = keys( %$custom_objects );
    require CustomObject::CustomObjectOrder;
    require MT::ObjectTag;
    my ( %customobject_map, %customobjectgroup_map, %r_customobject_map, %id_customobject );
    my @moved_objects;
    my @relation = qw( entry entry_multi page page_multi campaign campaign_multi
                       campaign_group objectgroup ); # TODO ContactForm, TemplateGroup ...
    my $custom_groups = MT->registry( 'custom_groups' );
    my @custom_group_objects = keys( %$custom_groups );
    push ( @relation, @custom_group_objects );
    for my $obj ( @objects ) {
        push ( @relation, $obj );
        push ( @relation, $obj . '_group' );
        push ( @relation, $obj . '_multi' );
        my $plugin = MT->component( 'CustomObject' );
        my $obj_label = $custom_objects->{ $obj }->{ id };
        my $group_label = $custom_objects->{ $obj }->{ id } . ' Groups';
        if (! $app->param( 'clone_prefs_' . $obj ) ) {
            my $terms = { blog_id => $old_blog_id };
            my $iter = MT->model( $obj . 'group' )->load_iter( $terms );
            my $counter = 0;
            my $state = $plugin->translate( "Cloning ${obj_label} Groups for blog..." );
            while ( my $object = $iter->() ) {
                $counter++;
                my $new_object = $object->clone_all();
                delete $new_object->{ column_values }->{ id };
                delete $new_object->{ changed_cols }->{ id };
                $new_object->blog_id( $new_blog_id );
                $new_object->save or die $new_object->errstr;
                $customobjectgroup_map{ $object->id } = $new_object->id;
            }
            $callback->(
                $state . " "
                    . $app->translate( "[_1] records processed.", $counter ),
                $group_label
            );
            $counter = 0;
            $state = $plugin->translate( "Cloning ${obj_label}s for blog..." );
            $iter = MT->model( $obj )->load_iter( $terms );
            while ( my $object = $iter->() ) {
                $counter++;
                my $new_object = $object->clone_all();
                delete $new_object->{ column_values }->{ id };
                delete $new_object->{ changed_cols }->{ id };
                $new_object->blog_id( $new_blog_id );
                if ( my $old_category_id = $object->category_id ) {
                    $new_object->category_id( $param{ category_map }->{ $old_category_id } || undef );
                }
                $new_object->save or die $new_object->errstr;
                push ( @moved_objects, $new_object );
                $customobject_map{ $object->id } = $new_object->id;
                $r_customobject_map{ $new_object->id } = $object->id;
                $id_customobject{ $new_object->id } = $new_object;
                # $id_customobject{ $object->id } = $object;
                my $order_iter = CustomObject::CustomObjectOrder->load_iter( { customobject_id => $object->id } );
                while ( my $order = $order_iter->() ) {
                    next unless $customobjectgroup_map{ $order->group_id };
                    next unless $customobject_map{ $order->customobject_id };
                    my $new_order = $order->clone_all();
                    delete $new_order->{ column_values }->{ id };
                    delete $new_order->{ changed_cols }->{ id };
                    $new_order->customobject_id( $customobject_map{ $order->customobject_id } );
                    $new_order->group_id( $customobjectgroup_map{ $order->group_id } );
                    $new_order->save or die $new_order->errstr;
                }
            }
            $callback->(
                $state . " "
                    . $app->translate( "[_1] records processed.", $counter ),
                $obj_label
            );
        }
    }
    my $state = $component->translate( 'Cloning CustomObject tags for blog...' );
    $callback->( $state, "customobject_tags" );
    my $iter
        = MT::ObjectTag->load_iter(
        { blog_id => $old_blog_id, object_datasource => 'customobject' }
        );
    my $counter = 0;
    while ( my $customobject_tag = $iter->() ) {
        next unless $customobject_map{ $customobject_tag->object_id };
        $counter++;
        my $new_customobject_tag = $customobject_tag->clone();
        delete $new_customobject_tag->{ column_values }->{ id };
        delete $new_customobject_tag->{ changed_cols }->{ id };
        $new_customobject_tag->blog_id( $new_blog_id );
        $new_customobject_tag->object_id(
            $customobject_map{ $customobject_tag->object_id } );
        $new_customobject_tag->save or die $new_customobject_tag->errstr;
    }
    $callback->(
        $state . " "
            . MT->translate( "[_1] records processed.",
            $counter ),
        'customobject_tags'
    );
    my @fields = MT->model( 'field' )->load( { blog_id => [ 0, $new_blog_id ], type => \@relation } );
    my $entry_map = $param{ entry_map };
    my $category_map = $param{ category_map };
    MT->request( 'entry_map', $entry_map );
    MT->request( 'category_map', $category_map );
    MT->request( 'customobject_map', \%customobject_map );
    MT->request( 'customobject_group_map', \%customobjectgroup_map );
    MT->request( 'id_customobject', \%id_customobject );
    $state = $component->translate( 'Restore Custom Objects Relation...' );
    $counter = 0;
    for my $obj ( @moved_objects ) {
        my $do;
        for my $field ( @fields ) {
            my $field_type = $field->type;
            my $obj_type = $field->obj_type;
            my $basename = 'field.' . $field->basename;
            # entry campaign customobjects
            if ( grep( /^$obj_type$/, @objects ) ) {
                if ( ( $field_type eq 'entry' ) || ( $field_type eq 'page' ) ) {
                    if ( $obj->$basename ) {
                        $obj->$basename( $entry_map->{ $obj->$basename } );
                        $do = 1;
                    }
                } elsif ( $field_type =~ /group$/ ) {
                    my $alias = $field_type;
                    $alias =~ s/_{0,1}group$//;
                    if ( grep( /^$alias$/, @objects ) ) {
                        $obj->$basename( $customobjectgroup_map{ $obj->$basename } );
                        $do = 1;
                    } else {
                    # other group
                        if ( my $group_map = MT->request( $field_type . '_map' ) ) {
                            $obj->$basename( $group_map->{ $obj->$basename } );
                            $do = 1;
                        }
                    }
                } elsif ( $field_type =~ /multi$/ ) {
                    # entry_multi campaign_multi customobjects
                    my $id = $obj->$basename;
                    if ( $id ) {
                        $id =~ s/^,//;
                        $id =~ s/,$//;
                        my @ids = split( /,/, $id );
                        my @new_ids;
                        if ( ( $field_type eq 'entry_multi' ) || ( $field_type eq 'page_multi' ) ) {
                            for my $num ( @ids ) {
                                push ( @new_ids, $entry_map->{ $num } );
                            }
                        } elsif ( $field_type eq 'campaign_multi' ) {
                            if ( my $campaign_map = MT->request( 'campaign_map' ) ) {
                                for my $num ( @ids ) {
                                    push ( @new_ids, $campaign_map->{ $num } );
                                }
                            }
                        } else {
                            $field_type =~ s/_{0,1}multi$//;
                            if ( grep( /^$field_type$/, @objects ) ) {
                                for my $num ( @ids ) {
                                    push ( @new_ids, $customobject_map{ $num } );
                                }
                            }
                        }
                        if ( @new_ids ) {
                            my $new_value = join( ',', @new_ids );
                            $new_value = ',' . $new_value . ',';
                            $obj->$basename( $new_value );
                            $do = 1;
                        }
                    }
                } else {
                    if ( grep( /^$field_type$/, @objects ) ) {
                        $obj->$basename( $customobject_map{ $obj->$basename } );
                        $do = 1;
                    } else {
                        if ( my $field_map = MT->request( $field_type . '_map' ) ) {
                            $obj->$basename( $field_map->{ $obj->$basename } );
                            $do = 1;
                        }
                    }
                }
            }
        }
        if ( $do ) {
            $obj->save or die $obj->errstr;
            $counter++;
        }
    }
    $callback->(
        $state . " "
            . MT->translate( "[_1] records processed.",
            $counter ),
        'object_customfield'
    );
    require MT::Entry;
    require MT::Category;
    my @e_ids = values %$entry_map;
    my @c_ids = values %$category_map;
    my @entries = MT::Entry->load( { id => \@e_ids,
                                     class => [ 'entry', 'page' ],
                                    } );
    my @categories = MT::Category->load( { id => \@c_ids,
                                           class => [ 'category', 'folder' ],
                                          } );
    my ( %id_entry, %id_category );
    for my $e ( @entries ) {
        $id_entry{ $e->id } = $e;
    }
    for my $c ( @categories ) {
        $id_category{ $c->id } = $c;
    }
    MT->request( 'id_entry', \%id_entry );
    MT->request( 'id_category', \%id_category );
    $state = $component->translate( 'Restore Custom Fields Object Relation...' );
    $counter = 0;
    my $customfield_objects = MT->registry( 'customfield_objects' );
    my @field_objects = keys( %$customfield_objects );
    for my $obj_type ( @field_objects ) {
        if (! grep( /^$obj_type$/, @objects ) ) {
            my $class = $obj_type;
            if ( $class eq 'page' ) {
                $class = 'entry';
            } elsif ( $class eq 'folder' ) {
                $class = 'category';
            }
            # $callback->('id_' . $class);
            if ( my $id_obj = MT->request( 'id_' . $class ) ) {
                # $callback->('id_' . $class);
                for my $obj ( values %$id_obj ) {
                    for my $field ( @fields ) {
                        my $field_type = $field->type;
                        my $basename = 'field.' . $field->basename;
                        if ( $field->obj_type eq $obj_type ) {
                            my $do;
                            if ( ( $field_type eq 'entry' ) || ( $field_type eq 'page' ) ) {
                                if ( $obj->$basename ) {
                                    $obj->$basename( $entry_map->{ $obj->$basename } );
                                    $do = 1;
                                }
                            } elsif ( $field_type =~ /group$/ ) {
                                # $field_type =~ s/_{0,1}group$//;
                                if ( my $group_map = MT->request( $field_type . '_map' ) ) {
                                    $obj->$basename( $group_map->{ $obj->$basename } );
                                    $do = 1;
                                }
                            } elsif ( $field_type =~ /multi$/ ) {
                                # entry_multi campaign_multi customobjects
                                my $id = $obj->$basename;
                                if ( $id ) {
                                    $id =~ s/^,//;
                                    $id =~ s/,$//;
                                    my @ids = split( /,/, $id );
                                    my @new_ids;
                                    if ( ( $field_type eq 'entry_multi' ) || ( $field_type eq 'page_multi' ) ) {
                                        for my $num ( @ids ) {
                                            push ( @new_ids, $entry_map->{ $num } );
                                        }
                                    } elsif ( $field_type eq 'campaign_multi' ) {
                                        if ( my $campaign_map = MT->request( 'campaign_map' ) ) {
                                            for my $num ( @ids ) {
                                                push ( @new_ids, $campaign_map->{ $num } );
                                            }
                                        }
                                    }
                                    if ( @new_ids ) {
                                        my $new_value = join( ',', @new_ids );
                                        $new_value = ',' . $new_value . ',';
                                        $obj->$basename( $new_value );
                                        $do = 1;
                                    }
                                }
                            } else {
                                if ( my $field_map = MT->request( $field_type . '_map' ) ) {
                                    $obj->$basename( $field_map->{ $obj->$basename } );
                                    $do = 1;
                                }
                            }
                            if ( $do ) {
                                $obj->save or die $obj->errstr;
                                $counter++;
                            }
                        }
                    }
                }
            }
        }
    }
    $callback->(
        $state . " "
            . MT->translate( "[_1] records processed.",
            $counter ),
        'customfield'
    );
    1;
}

sub clone_blog {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $custom_objects = MT->registry( 'custom_objects' );
    my @objects = keys( %$custom_objects );
    for my $obj ( @objects ) {
        my $plugin = MT->component( $obj );
        my $elements = $tmpl->getElementsByTagName( 'unless' );
        my $obj_label = $custom_objects->{ $obj }->{ id };
        my ( $element )
            = grep { 'clone_prefs_input' eq $_->getAttribute( 'name' ) } @$elements;
        if ( $element ) {
            my $contents = $element->innerHTML;
            my $text     = <<EOT;
        <input type="hidden" name="clone_prefs_${obj}" value="<mt:var name="clone_prefs_${obj}">" />
EOT
            $element->innerHTML( $contents . $text );
        }
        ( $element )
            = grep { 'clone_prefs_checkbox' eq $_->getAttribute( 'name' ) }
            @$elements;
        if ( $element ) {
            my $contents = $element->innerHTML;
            my $text     = <<EOT;
                <li>
                    <input type="checkbox" name="clone_prefs_${obj}" id="clone-prefs-${obj}"<mt:if name="clone_prefs_${obj}"> checked="<mt:var name="clone_prefs_${obj}">"</mt:if> class="cb" />
                    <label for="clone-prefs-${obj}"><__trans_section component="${obj_label}"><__trans phrase="${obj_label}s"></__trans_section></label>
                </li>
EOT
            $element->innerHTML( $contents . $text );
        }
        ( $element )
            = grep { 'clone_prefs_exclude' eq $_->getAttribute( 'name' ) }
            @$elements;
        if ( $element ) {
            my $contents = $element->innerHTML;
            my $text     = <<EOT;
    <mt:if name="clone_prefs_${obj}" eq="on">
                <li><__trans_section component="${obj}"><__trans phrase="Exclude ${obj_label}s"></__trans_section></li>
    </mt:if>
EOT
            $element->innerHTML( $contents . $text );
        }
    }
}

# TODO::Init Plugin and Save Log.
sub _scheduled_task {
    my $plugin = MT->component( 'CustomObject' );
    my $app = MT->instance();
    require CustomObject::CustomObject;
    my $custom_objects = MT->registry( 'custom_objects' );
    require ArchiveType::CustomObject;
    require ArchiveType::FolderCustomObject;
    my @blogs = MT::Blog->load( { class => [ 'website', 'blog' ] } );
    for my $blog ( @blogs ) {
        my $fmgr = $blog->file_mgr;
        my $ts = current_ts( $blog );
        my @customobjects = CustomObject::CustomObject->load( { blog_id => $blog->id,
                                                                status => CustomObject::CustomObject::FUTURE(),
                                                                class => '*' },
                                                              { sort      => 'authored_on',
                                                                start_val => $ts - 1,
                                                                direction => 'descend', } );

        my %rebuild_queue;
        for my $customobject ( @customobjects ) {
            my $original = $customobject->clone_all();
            $customobject->status( $customobject->RELEASE );
            $customobject->save or die $customobject->errstr;
            $rebuild_queue{$customobject->id} = $customobject;
            $app->run_callbacks( 'post_publish.' . $customobject->class, $app, $customobject, $original );
        }

        @customobjects = CustomObject::CustomObject->load( { blog_id => $blog->id,
                                                             status => CustomObject::CustomObject::RELEASE(),
                                                             class => '*',
                                                             set_period => 1 },
                                                           { sort      => 'period_on',
                                                             start_val => $ts - 1,
                                                             direction => 'descend', } );
        for my $customobject ( @customobjects ) {
            my $original = $customobject->clone_all();
            my $publisher;
            if ( $original->status == 2 ) {
                $publisher = 1;
            }
            $customobject->status( CustomObject::CustomObject::CLOSED() );
            $customobject->save or die $customobject->errstr;
            $rebuild_queue{$customobject->id} = $customobject if ( $publisher );
            $app->run_callbacks( 'post_close.' . $customobject->class, $app, $customobject, $original );
        }

        foreach my $id ( keys %rebuild_queue ) {
            my $customobject = $rebuild_queue{$id};
            my $at = $custom_objects->{ $customobject->class }->{ id };
            ArchiveType::CustomObject::rebuild_customobject( $app, $customobject->blog, $at, $customobject );
            $at = 'Folder' . $at;
            if ( my $folder = $customobject->folder ) {
                my $count = CustomObject::CustomObject->count( { blog_id => $customobject->blog_id,
                                                                 status => CustomObject::CustomObject::RELEASE(),
                                                                 category_id => $folder->id,
                                                                 class => '*' } );
                if ( $count ) {
                    ArchiveType::FolderCustomObject::rebuild_folder( $app, $customobject->blog, $at, $folder );
                } else {
                    my @finfo = MT->model( 'fileinfo' )->load(
                        { archive_type => $at,
                          blog_id => $customobject->blog_id,
                          category_id => $folder->id,
                        }
                    );
                    for my $f ( @finfo ) {
                        $fmgr->delete( $f->file_path );
                        $f->remove;
                    }
                }
            }
        }
    }
    return 1;
}

sub _task_adjust_order {
    my $updated = 0;
    my @groups = MT->model( 'customobjectgroup' )->load( { class => '*' } );
    for my $group ( @groups ) {
        my $blog_id = $group->blog_id;
        my $exists = MT::Blog->count( { id => $blog_id } );
        unless ( $exists ) {
            $group->remove();
            $updated++;
        }
    }
    my @orders = MT->model( 'customobjectorder' )->load();
    for my $order ( @orders ) {
        my $remove = 0;
        if ( my $group_id = $order->group_id ) {
            my $group = MT->model( 'customobjectgroup' )->load( { id => $group_id } );
            if ( $group ) {
                if ( ! $order->blog_id ) {
                    $order->blog_id( $group->blog_id );
                    $order->save or die $order->errstr;
                    $updated++;
                }
                if ( ! $order->group_class ) {
                    $order->group_class( $group->class );
                    $order->save or die $order->errstr;
                    $updated++;
                }
            } else {
                $remove = 1;
            }
        } else {
            $remove = 1;
        }
        if ( $remove ) {
            $order->remove();
            $updated++;
        }
    }
    return $updated;
}

1;
