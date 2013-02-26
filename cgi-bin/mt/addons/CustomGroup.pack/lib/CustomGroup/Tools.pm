package CustomGroup::Tools;

use strict;

sub clone_object {
    my ( $cb, %param ) = @_;
    my $old_blog_id = $param{ old_blog_id };
    my $new_blog_id = $param{ new_blog_id };
    my $callback    = $param{ callback };
    my $app         = MT->instance;
    my $component   = MT->component( 'CustomGroup' );
    my $custom_groups = MT->registry( 'custom_groups' );
    my @objects = keys( %$custom_groups );
    require CustomGroup::GroupOrder;
    my $entry_map = $param{ entry_map };
    my $category_map = $param{ category_map };
    for my $obj ( @objects ) {
        my $filter_class = $custom_groups->{ $obj }->{ stash };
        if ( ( $filter_class eq 'blog' ) || ( $filter_class eq 'website' ) ) {
            next;
        }
        if ( $custom_groups->{ $obj }->{ component } eq 'BlogGroup' ) {
            next;
        }
        my %group_map;
        my $group_label = $custom_groups->{ $obj }->{ name };
        my $plugin = MT->component( $custom_groups->{ $obj }->{ component } );
        if (! $app->param( 'clone_prefs_' . $obj ) ) {
            my $terms = { blog_id => $old_blog_id };
            my $iter = MT->model( $obj )->load_iter( $terms );
            my $counter = 0;
            my $state = $plugin->translate( "Cloning ${group_label}s for blog..." );
            while ( my $object = $iter->() ) {
                $counter++;
                my $new_object = $object->clone_all();
                delete $new_object->{ column_values }->{ id };
                delete $new_object->{ changed_cols }->{ id };
                $new_object->blog_id( $new_blog_id );
                $new_object->save or die $new_object->errstr;
                $group_map{ $object->id } = $new_object->id;
                my $iter_ord = CustomGroup::GroupOrder->load_iter( { group_id => $object->id } );
                while ( my $order = $iter_ord->() ) {
                    my $new_order = $order->clone_all();
                    delete $new_order->{ column_values }->{ id };
                    delete $new_order->{ changed_cols }->{ id };
                    $new_order->group_id( $new_object->id );
                    if ( $filter_class eq 'entry' ) {
                        $new_order->object_id( $entry_map->{ $order->object_id } );
                    } elsif ( $filter_class eq 'category' ) {
                        $new_order->object_id( $category_map->{ $order->object_id } );
                    }
                    $new_order->save or die $new_order->errstr;
                }
            }
            $callback->(
                $state . ' '
                    . $app->translate( '[_1] records processed.', $counter ),
                $group_label
            );
            MT->request( $obj . '_map', \%group_map );
        }
    }
    if (! $app->param( 'clone_prefs_objectgroup' ) ) {
        require ObjectGroup::ObjectOrder;
        my $terms = { blog_id => $old_blog_id };
        my $iter = MT->model( 'objectgroup' )->load_iter( $terms );
        my $counter = 0;
        my $state = $component->translate( 'Cloning Object Groups for blog...' );
        my $group_label = $component->translate( 'Object Group' );
        my %group_map;
        while ( my $object = $iter->() ) {
            $counter++;
            my $new_object = $object->clone_all();
            delete $new_object->{ column_values }->{ id };
            delete $new_object->{ changed_cols }->{ id };
            $new_object->blog_id( $new_blog_id );
            $new_object->save or die $new_object->errstr;
            $group_map{ $object->id } = $new_object->id;
            my $iter_ord = ObjectGroup::ObjectOrder->load( objectgroup_id => $object->id );
            while ( my $order = $iter->() ) {
                my $new_order = $object->clone_all();
                delete $new_order->{ column_values }->{ id };
                delete $new_order->{ changed_cols }->{ id };
                $new_order->group_id( $new_object->id );
                if ( $object->object_ds eq 'entry' ) {
                    $new_order->object_id( $entry_map->{ $order->id } );
                } elsif ( $object->object_ds eq 'category' ) {
                    $new_order->object_id( $category_map->{ $order->id } );
                }
                $new_order->save or die $new_order->errstr;
            }
        }
        $callback->(
            $state . ' '
                . $app->translate( '[_1] records processed.', $counter ),
            $group_label
        );
        MT->request( 'objectgroup_map', \%group_map );
    }
    1;
}

sub clone_blog {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $custom_groups = MT->registry( 'custom_groups' );
    my @objects = keys( %$custom_groups );
    push ( @objects, 'objectgroup' );
    for my $obj ( @objects ) {
        my $filter_class;
        my $component = 'CustomGroup';
        my $plugin = MT->component( 'CustomGroup' );
        my $obj_label = 'Object Group';
        if ( $custom_groups->{ $obj } ) {
        $filter_class = $custom_groups->{ $obj }->{ filter_class };
            if ( ( ref $filter_class ) eq 'ARRAY' ) {
                if ( grep( /^blog$/, @$filter_class ) ) {
                    next;
                }
                if ( grep( /^website$/, @$filter_class ) ) {
                    next;
                }
            } else {
                if ( ( $filter_class eq 'blog' ) || ( $filter_class eq 'website' ) ) {
                    next;
                }
            }
            $component = $custom_groups->{ $obj }->{ component };
            $plugin = MT->component( $component );
            $obj_label = $custom_groups->{ $obj }->{ name };
        }
        my $elements = $tmpl->getElementsByTagName( 'unless' );
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
                    <input type="checkbox" name="clone_prefs_${obj}" id="clone-prefs-${obj}" <mt:if name="clone_prefs_${obj}">checked="<mt:var name="clone_prefs_${obj}">"</mt:if> class="cb" />
                    <label for="clone-prefs-${obj}"><__trans_section component="${component}"><__trans phrase="${obj_label}s"></__trans_section></label>
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
                <li><__trans_section component="${component}"><__trans phrase="Exclude ${obj_label}s"></__trans_section></li>
    </mt:if>
EOT
            $element->innerHTML( $contents . $text );
        }
    }
}

sub _task_adjust_order {
    my $updated = 0;
    # grouporder
    my @orders = MT->model( 'grouporder' )->load();
    for my $order ( @orders ) {
        my $remove = 0;
        if ( my $group_id = $order->group_id ) {
            my $group = MT->model( 'customgroup' )->load( { id => $group_id } );
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
                if ( ! $order->object_class ) {
                    if ( $order->group_class ) {
                        if ( $order->group_class =~ /^(?:bloggroup|blogwebsitegroup|websitegroup)$/ ) {
                            my $item = MT->model( 'blog' )->load( { id => $order->object_id }, { no_class => 1 } );
                            if ( $item ) {
                                $order->object_class( $item->class );
                                $order->save or die $order->errstr;
                                $updated++;
                            } else {
                                $remove = 1;
                            }
                        } elsif ( $order->group_class =~ /^(?:categorygroup|categoryfoldergroup|foldergroup)$/ ) {
                            my $item = MT->model( 'category' )->load( { id => $order->object_id }, { no_class => 1 } );
                            if ( $item ) {
                                $order->object_class( $item->class );
                                $order->save or die $order->errstr;
                                $updated++;
                            } else {
                                $remove = 1;
                            }
                        } elsif ( $order->group_class =~ /^(?:entrygroup|entrypagegroup|pagegroup)$/ ) {
                            my $item = MT->model( 'entry' )->load( { id => $order->object_id }, { no_class => 1 } );
                            if ( $item ) {
                                $order->object_class( $item->class );
                                $order->save or die $order->errstr;
                                $updated++;
                            } else {
                                $remove = 1;
                            }
                        }
                    }
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
    # objectorder
    @orders = MT->model( 'objectorder' )->load();
    for my $order ( @orders ) {
        my $remove = 0;
        if ( my $group_id = $order->objectgroup_id ) {
            my $group = MT->model( 'objectgroup' )->load( { id => $group_id } );
            if ( $group ) {
                if ( ! $order->blog_id ) {
                    $order->blog_id( $group->blog_id );
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