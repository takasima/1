package CustomGroup::Tags;
use strict;
use CustomGroup::Util qw( include_exclude_blogs );

sub _hdlr_custom_group_order {
    my ( $ctx, $args, $cond ) = @_;
    return $ctx->stash( 'grouporder_order' ) || '';
}

sub _hdlr_custom_group_name {
    my ( $ctx, $args, $cond ) = @_;
    if ( my $customgroup_name = $ctx->stash( 'customgroup_name' ) ) {
        return $customgroup_name;
    }
    if ( my $customgroup_id = $ctx->stash( 'customgroup_id' ) ) {
        my $class = $ctx->stash( 'customgroup_class' );
        my $customgroup = MT->model( $class )->load( $customgroup_id );
        return $customgroup ? $customgroup->name : '';
    }
}

sub _hdlr_custom_groups {
    my ( $ctx, $args, $cond ) = @_;
    my ( %terms, %args );
    my $blog_id = $args->{ blog_id } || $ctx->stash( 'blog' )->id || 0;
    $terms{ blog_id } = $blog_id;
    $terms{ class } = $args->{ class };
    my $object_id = $args->{ object_id };
    my $object_class = $args->{ object_class };
    my $object = $ctx->stash( $object_class );
    if ( $object_id ) {
        if ( $object && $object->id != $object_id ) {
            $object = undef;
        }
        unless ( $object ) {
            $object = MT->model( $object_class )
                        ? MT->model( $object_class )->load( { id => $object_id } )
                        : undef;
        }
        return '' unless $object;
        $args{ 'join' } = MT->model( 'grouporder' )->join_on( 'group_id',
                                                              { object_id => $object->id },
                                                            );
    }
    my @customgroups = MT->model( 'customgroup' )->load( \%terms, \%args );
    if ( @customgroups ) {
        my $glue = $args->{ glue };
        my $res = ''; my $i = 0;
        my $vars = $ctx->{ __stash }{ vars } ||= {};
        my @contents;
        for my $customgroup ( @customgroups ) {
            local $vars->{ __first__ } = ! $i;
            local $vars->{ __last__ } = ! defined $customgroups[ $i + 1 ];
            local $vars->{ __odd__ } = ( $i % 2 ) == 0; # 0-based $i
            local $vars->{ __even__ } = ( $i % 2 ) == 1;
            local $vars->{ __counter__ } = $i + 1;
            local $ctx->{ __stash }{ customgroup_id } = $customgroup->id;
            local $ctx->{ __stash }{ customgroup_name } = $customgroup->name;
            local $ctx->{ __stash }{ customgroup_class } = $customgroup->class;
            local $ctx->{ __stash }{ blog } = $customgroup->blog;
            local $ctx->{ __stash }{ blog_id } = $customgroup->blog_id;
            local $ctx->{ __stash }{ object } = $object if $object;
            local $ctx->{ __stash }{ object_class } = $object_class if $object_class;
            my $grouporder;
            if ( $object ) {
                $grouporder = MT->model( 'grouporder' )->load( { group_id => $customgroup->id,
                                                                 object_id => $object->id,
                                                               },
                                                             );
            }
            local $ctx->{ __stash }{ grouporder_order } = $grouporder->order if $grouporder;
            my $out = $ctx->stash( 'builder' )->build( $ctx,
                                                       $ctx->stash( 'tokens' ),
                                                       { %$cond,
                                                         customgroupsheader => ! $i,
                                                         customgroupsfooter => ! defined $customgroups[ $i + 1 ],
                                                       },
                                                     );
            push ( @contents, $out );
            $i++;
        }
        return @contents ? join( $glue, @contents ) : '';
    }
    return $ctx->_hdlr_pass_tokens_else( @_ );
}

sub _get_object_class_label {
    my $app = MT->instance;
    my $class = $app->param( '_type' );
    if ( my $model = MT->model( $class ) ) {
        return $model->class_label;
    }
}

sub _get_object_child_label {
    my $app = MT->instance;
    my $class = $app->param( '_type' );
    my $model = MT->model( $class );
    if ( $model ) {
        my $child_class = $model->child_class;
        if ( ( ref $child_class ) eq 'ARRAY' ) {
            return $model->child_class_label;
        }
        if ( my $child = MT->model( $child_class ) ) {
            return $child->class_label;
        }
    }
}

sub _hdlr_field_scope {
    my ( $ctx, $args, $cond ) = @_;
    my $scope_type = $args->{ scope_type };
    if (! $scope_type ) {
        return MT->config( 'CustomGroupFieldScope' ) || 'blog';
    }
    if ( $scope_type eq 'objectgroup' ) {
        return MT->config( 'ObjectGroupFieldScope' ) || 'blog';
    }
    my $custom_groups = MT->registry( 'custom_groups' );
    my $id = $custom_groups->{ $scope_type }->{ id }
        or return 'blog';
    return MT->config( $id . 'FieldScope' ) || 'blog';
}

sub _hdlr_if_not_sent {
    my ( $ctx, $args, $cond ) = @_;
    require MT::Request;
    my $r = MT::Request->instance;
    my $key = $args->{ key };
    if ( $r->cache( $key ) ) {
        return 0;
    }
    $r->cache( $key, 1 );
    return 1;
}

sub _hdlr_group_objects {
    my ( $ctx, $args, $cond ) = @_;
    require MT::Blog;
    my $child_object_ds = $args->{ child_object_ds };
    my $child_class = $args->{ child_class };
    my $search_class;
    if ( ( ref $child_class ) eq 'ARRAY' ) {
        $search_class = $child_class;
        $child_class = $args->{ child_object_ds };
    }
    my $child_model = MT->model( $child_class );
    my $class = $args->{ class };
    my $stash = $args->{ stash };
    if (! $stash ) {
        if ( $class =~ /blog/ ) {
            $stash = 'blog';
        } elsif ( $class =~ /category/ ) {
            $stash = 'category';
        } elsif ( $class =~ /entry/ ) {
            $stash = 'entry';
        }
    }
    my $tokens = $ctx->stash( 'tokens' );
    my $builder = $ctx->stash( 'builder' );
    my $blog = $ctx->stash( 'blog' );
    my $blog_id = $args->{ blog_id };
    if ( $blog_id && ( $blog_id != $blog->id ) ) {
        $blog = MT::Blog->load( $blog_id );
    }
    $blog_id ||= $blog->id;
    my $lastn = $args->{ lastn };
    my $limit = $lastn || $args->{ limit } || 9999;
    my $offset = $args->{ offset } || 0;
    my $sort_order = $args->{ sort_order } || 'ascend';
    my $sort_by = $args->{ sort_by } || 'id';
    my $group = $args->{ group };
    my $group_id = $args->{ group_id };
    my $tag_name = $args->{ tag };
    my %terms;
    my %params;
    if ( (! $group ) && (! $group_id ) ) {
        if ( my $args_blog_id = $args->{ blog_id } ) {
            $terms{ blog_id } = $args_blog_id;
        } else {
            my @blog_ids = include_exclude_blogs( $ctx, $args );
            if ( scalar @blog_ids ) {
                if ( ( scalar @blog_ids ) == 1 ) {
                    if ( defined $blog_ids[ 0 ] ) {
                        $terms{ blog_id } = \@blog_ids;
                    }
                } else {
                    $terms{ blog_id } = \@blog_ids;
                }
            }
        }
    }
    unless ( $args->{ include_draft } ) {
        if ( $child_model->has_column( 'status' ) ) {
            $terms{ status } = 2;
        }
    }
    if ( $search_class ) {
        $terms{ class } = $search_class;
    }
    if ( $group || $group_id ) {
        if (! $group_id ) {
#            my $g = MT->model( $class )->load( { name => $group, blog_id => $blog_id, class => $class } );
            my $g = MT->model( $class )->load( { name => $group,
                                                 ( $class eq 'websitegroup' ? ( blog_id => 0 ) : ( blog_id => $blog_id ) ),
                                                 class => $class,
                                               }
                                             )
                or return '';
            $group_id = $g->id;
        }
        require CustomGroup::GroupOrder;
        $params { 'join' } = [ 'CustomGroup::GroupOrder', 'object_id',
                   { group_id => $group_id, },
                   { sort   => 'order',
                     limit  => $limit,
                     offset => $offset,
                     direction => $sort_order,
                   } ];
    } elsif ( $tag_name ) {
        require MT::Tag;
        my $tag = MT::Tag->load( { name => $tag_name }, { binary => { name => 1 } } )
            or return '';
        $params{ limit }     = $limit;
        $params{ offset }    = $offset;
        $params{ direction } = $sort_order;
        $params{ 'sort' }    = $sort_by;
        require MT::ObjectTag;
        $params { 'join' } = [ 'MT::ObjectTag', 'object_id',
                   { tag_id  => $tag->id,
                     # blog_id => $blog_id,
                     object_datasource => $child_object_ds }, ];
    } else {
        $params{ limit }     = $limit;
        $params{ offset }    = $offset;
        $params{ direction } = $sort_order;
        $params{ sort }      = $sort_by;
    }
    my @terms;
    if ( %terms ) {
        push( @terms, \%terms );
    }
    if ( my $filter_val = $args->{ filter_val } ) {
        my $search_like = $args->{ search_like } || 0;
        my $search_cond = $args->{ search_cond } || 'or';
        if ( my $filter = $args->{ filter } ) {
            if ( $search_like ) {
                push ( @terms, { $filter => { like => '%' . $filter_val . '%' } } );
            } else {
                push ( @terms, { $filter => $filter_val } );
            }
        } else {
            my @column_terms;
            my $column_names = MT->model( $class )->column_names;
            for my $column_name ( @$column_names ) {
                next if grep { $_ eq $column_name } qw( id author_id blog_id status );
                if ( $search_like ) {
                    push( @column_terms, { $column_name => { like => '%' . $filter_val . '%' } }, '-' . $search_cond );
                } else {
                    push( @column_terms, { $column_name => $filter_val }, '-' . $search_cond );
                }
            }
            delete $column_terms[ $#column_terms ];
            push( @terms, \@column_terms );
        }
    }
    # FIXME: in case of no 'group' or 'group_id' modifiers, following should be better process...
    if ( $child_class =~ /^(?:blog|website)$/ ) {
    #    @terms = map { delete( $$_{ blog_id } ) } @terms;
        my @new_terms;
        for my $term ( @terms ) {
            delete( $$term{ blog_id } );
            if ( %$term ) {
                push( @new_terms, $term );
            }
        }
        @terms = @new_terms;
    }
    my @ids;
    if ( my $idstr  = $args->{ ids } ) {
        $idstr =~ s/^,+//;
        $idstr =~ s/,+$//;
        @ids = split( /,/, $idstr );
    }
    my @groupobjects;
    my $this_tag = $ctx->stash( 'tag' );
    if ( $this_tag =~ m/count$/ ) {
        if ( @ids ) {
            if ( $args->{ include_draft } || (! $child_model->has_column( 'status' ) ) ) {
                return MT->model( $child_class )->count( { id => \@ids } );
            }
            return MT->model( $child_class )->count( { id => \@ids, status => CustomObject::CustomObject::RELEASE() } );
        }
        return MT->model( $child_class )->count( ( @terms ? \@terms : undef ), \%params );
    }
    if ( @ids ) {
        if ( $args->{ include_draft } || (! $child_model->has_column( 'status' ) ) ) {
            @groupobjects = MT->model( $child_class )->load( { id => \@ids } );
        } else {
            @groupobjects = MT->model( $child_class )->load( { id => \@ids, status => CustomObject::CustomObject::RELEASE() } );
        }
    } else {
        @groupobjects = MT->model( $child_class )->load( ( @terms ? \@terms : undef ), \%params );
    }
    if (! $args->{ sort_by } ) {
        if ( @ids ) {
            my %loaded_objects;
            for my $customobject ( @groupobjects ) {
                $loaded_objects{ $customobject->id } = $customobject;
            }
            if ( $sort_order eq 'descend' ) {
                @ids = reverse( @ids );
            }
            @groupobjects = ();
            for my $object_id ( @ids ) {
                if ( my $object = $loaded_objects{ $object_id } ) {
                    push ( @groupobjects, $object );
                }
            }
        }
    }
    my $i = 0; my $res = '';
    my $odd = 1; my $even = 0;
    if ( $args->{ count } ) {
        return scalar( @groupobjects );
    }
    for my $object ( @groupobjects ) {
        local $ctx->{ __stash }{ 'customobject' } = $object;
        my $othor_blog;
        if ( $object->has_column( 'blog_id' ) ) {
            if ( $blog->id != $object->blog_id ) {
                $othor_blog = MT::Blog->load( $object->blog_id );
            }
        }
        if ( $child_class =~ /^(?:website|blog)$/ ) {
            if ( $blog->id != $object->id ) {
                $othor_blog = MT::Blog->load( $object->id );
            }
        }
        local $ctx->{ __stash }{ blog } = $othor_blog if $othor_blog;
        local $ctx->{ __stash }{ blog_id } = $othor_blog->id if $othor_blog;
        local $ctx->{ __stash }{ $stash } = $object;
        local $ctx->{ __stash }{ customgroup_id } = $group_id;
        local $ctx->{ __stash }{ customgroup_class } = $class;
        local $ctx->{ __stash }{ vars }{ __first__ } = 1 if ( $i == 0 );
        local $ctx->{ __stash }{ vars }{ __counter__ } = $i + 1;
        local $ctx->{ __stash }{ vars }{ __odd__ } = $odd;
        local $ctx->{ __stash }{ vars }{ __even__ } = $even;
        local $ctx->{ __stash }{ vars }{ __last__ } = 1 if ( !defined( $groupobjects[ $i + 1 ] ) );
        my $out = $builder->build( $ctx, $tokens, {
            %$cond,
            'groupobjectsheader' => $i == 0,
            'groupobjectsfooter' => !defined( $groupobjects[ $i + 1 ] ),
            ( $args->{ template_tag_name }
                ? ( $args->{ template_tag_name } . 'header' => $i == 0 )
                : ()
            ),
            ( $args->{ template_tag_name }
                ? ( $args->{ template_tag_name } . 'footer' => !defined( $groupobjects[ $i + 1 ] ) )
                : ()
            ),
        } );
        if ( !defined( $out ) ) { return $ctx->error( $builder->errstr ) };
        $res .= $out;
        if ( $odd == 1 ) { $odd = 0 } else { $odd = 1 };
        if ( $even == 1 ) { $even = 0 } else { $even = 1 };
        $i++;
    }
    return $res;
}

sub _hdlr_category_class {
    my ( $ctx, $args, $cond ) = @_;
    my $cat = ( $ctx->stash( 'category' ) || $ctx->stash( 'archive_category' ) )
        or return '';
    return $cat->class;
}

sub _hdlr_if_website {
    my ( $ctx, $args, $cond ) = @_;
    my $app = MT->instance();
    if ( $app->blog ) {
        if ( $app->blog->class eq 'website' ) {
            return 1;
        }
    }
    return 0;
}

sub _hdlr_pass_tokens {
    my ( $ctx, $args, $cond ) = @_;
    $ctx->stash( 'builder' )->build( $ctx, $ctx->stash( 'tokens' ), $cond );
}

1;
