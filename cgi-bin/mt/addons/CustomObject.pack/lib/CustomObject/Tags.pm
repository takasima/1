package CustomObject::Tags;

use strict;

use CustomObject::Util qw( include_exclude_blogs );

sub _hdlr_customobject_column_name {
    my ( $ctx, $args ) = @_;
    return $ctx->stash( 'customobject_column_name' ) || '';
}

sub _hdlr_customobject_column_value {
    my ( $ctx, $args ) = @_;
    return $ctx->stash( 'customobject_column_value' ) || '';
}

sub _hdlr_customobject_columns {
    my ( $ctx, $args, $cond ) = @_;
    my $tokens  = $ctx->stash( 'tokens' );
    my $builder = $ctx->stash( 'builder' );
    my $class  = $args->{ class };
    $class = 'customobject' if (! $class );
    my $obj;
    if ( my $obj_id = $args->{ id } ) {
        $obj = MT->model( $class )->load( $obj_id );
    } else {
        $obj = $ctx->stash( 'customobject' );
    }
    return '' unless $obj;
    my $blog = $obj->blog;
    my $blog_id = $blog->id;
    my $column_names = $obj->column_names;
    my $i = 0; my $res = '';
    my $odd = 1; my $even = 0;
    for my $column_name ( @$column_names ) {
        local $ctx->{ __stash }{ 'customobject' } = $obj;
        local $ctx->{ __stash }{ 'blog' } = $blog;
        local $ctx->{ __stash }{ 'blog_id' } = $blog_id;
        local $ctx->{ __stash }{ 'customobject_column_name' } = $column_name;
        local $ctx->{ __stash }{ 'customobject_column_value' } = $obj->$column_name;
        local $ctx->{ __stash }->{ vars }->{ __name__ } = $column_name;
        local $ctx->{ __stash }->{ vars }->{ __key__ } = $column_name;
        local $ctx->{ __stash }->{ vars }->{ __value__ } = $obj->$column_name;
        local $ctx->{ __stash }->{ vars }->{ __first__ } = 1 if ( $i == 0 );
        local $ctx->{ __stash }->{ vars }->{ __counter__ } = $i + 1;
        local $ctx->{ __stash }->{ vars }->{ __odd__ } = $odd;
        local $ctx->{ __stash }->{ vars }->{ __even__ } = $even;
        local $ctx->{ __stash }->{ vars }->{ __last__ } = 1 if ( !defined( $$column_names[ $i + 1 ] ) );
        my $out = $builder->build( $ctx, $tokens, {
            %$cond,
            'customobjectcolumnsheader' => $i == 0,
            'customobjectcolumnsfooter' => !defined( $$column_names[ $i + 1 ] ),
        } );
        if ( !defined( $out ) ) { return $ctx->error( $builder->errstr ) };
        $res .= $out;
        if ( $odd == 1 ) { $odd = 0 } else { $odd = 1 };
        if ( $even == 1 ) { $even = 0 } else { $even = 1 };
        $i++;
    }
    return $res;
}

sub _hdlr_customobject {
    my ( $ctx, $args, $cond ) = @_;
    require CustomObject::CustomObject;
    my $blog = $ctx->stash( 'blog' );
    my $blog_id = $args->{ blog_id };
    if ( $blog_id && ( $blog_id != $blog->id ) ) {
        require MT::Blog;
        $blog = MT::Blog->load( $blog_id );
    }
    $blog_id = $blog->id if (! $blog_id );
    my $id = $args->{ id };
    my %terms;
    my $class  = $args->{ class };
    $class = 'customobject' if (! $class );
    $terms{ blog_id } = $blog_id if $blog_id;
    unless ( $args->{ include_draft } ) {
        $terms{ status } = CustomObject::CustomObject::RELEASE();
    }
    $terms{ id } = $id;
    require CustomObject::CustomObject;
    $terms{ status } = CustomObject::CustomObject::RELEASE();
    my $obj;
    if ( $id ) {
        if ( $args->{ include_draft } ) {
            $obj = MT->model( $class )->load( $id );
        } else {
            $obj = MT->model( $class )->load( { id => $id, status => CustomObject::CustomObject::RELEASE() } );
        }
    } else {
        $obj = MT->model( $class )->load( \%terms, { limit => 1 } );
    }
    return '' unless defined $obj;
    if ( $blog->id ne $obj->blog_id ) {
        $blog = $obj->blog;
        $blog_id = $blog->id;
    }
    local $ctx->{ __stash }{ 'local_blog_id' } = $blog_id;
    local $ctx->{ __stash }{ 'blog_id' } = $blog_id;
    local $ctx->{ __stash }{ 'blog' } = $blog;
    local $ctx->{ __stash }{ 'customobject' } = $obj;
    my $tokens  = $ctx->stash( 'tokens' );
    my $builder = $ctx->stash( 'builder' );
    my $content = $builder->build( $ctx, $tokens, $cond );
    return $content;
}

sub _hdlr_customobjects {
    my ( $ctx, $args, $cond ) = @_;
    my $datasource;
    if ( lc( MT->config( 'ObjectDriver' ) ) =~ /oracle/ ) {
        $datasource = 'co';
    } else {
        $datasource = 'customobject';
    }
    require CustomObject::CustomObject;
    my $tokens = $ctx->stash( 'tokens' );
    my $builder = $ctx->stash( 'builder' );
    my $blog = $ctx->stash( 'blog' );
    my $blog_id = $args->{ blog_id };
    if ( $blog_id && ( $blog_id != $blog->id ) ) {
        require MT::Blog;
        $blog = MT::Blog->load( $blog_id );
    }
    $blog_id = $blog->id if (! $blog_id );
    my $class = $args->{ class };
    $class = 'customobject' if (! $class );
    my @ids;
    if ( my $idstr  = $args->{ ids } ) {
        $idstr =~ s/^,//;
        $idstr =~ s/,$//;
        @ids = split( /,/, $idstr );
    }
    my $lastn  = $args->{ lastn };
    my $limit  = $args->{ limit };
    $limit = $lastn if $lastn;
    my $offset = $args->{ offset };
    my $sort_order = $args->{ sort_order };
    $sort_order = 'ascend' unless $sort_order;
    $limit = 9999 unless $limit;
    my $sort_by = $args->{ sort_by };
    $sort_by = 'id' unless $sort_by;
    $offset = 0 unless $offset;
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
        $terms{ status } = CustomObject::CustomObject::RELEASE();
    }
    if ( $group || $group_id ) {
        require CustomObject::CustomObjectGroup;
        require CustomObject::CustomObjectOrder;
        if (! $group_id ) {
            my $g = CustomObject::CustomObjectGroup->load( { name => $group, blog_id => $blog_id, class => $class . 'group' } );
            return '' unless $g;
            $group_id = $g->id;
        }
        $params { 'join' } = [ 'CustomObject::CustomObjectOrder', 'customobject_id',
                   { group_id => $group_id, },
                   { sort   => 'order',
                     limit  => $limit,
                     offset => $offset,
                     direction => $sort_order,
                   } ];
    } elsif ( $tag_name ) {
        require MT::Tag;
        my $tag = MT::Tag->load( { name => $tag_name }, { binary => { name => 1 } } );
        return '' unless $tag;
        $params{ limit }     = $limit;
        $params{ offset }    = $offset;
        $params{ direction } = $sort_order;
        $params{ 'sort' }    = $sort_by;
        require MT::ObjectTag;
        $params { 'join' } = [ 'MT::ObjectTag', 'object_id',
                   { tag_id  => $tag->id,
                     # blog_id => $blog_id,
                     object_datasource => $datasource }, ];
    } else {
        $params{ limit }     = $limit;
        $params{ offset }    = $offset;
        $params{ direction } = $sort_order;
        $params{ sort }      = $sort_by;
        if (! @ids ) {
            my $vars = $ctx->{ __stash }{ vars } ||= {};
            if ( $vars->{ folder_customobject_archive } ) {
                if ( my $category = $ctx->stash( 'category' ) ) {
                    $terms{ category_id } = $category->id;
                }
            }
        }
    }
    my @terms;
    push( @terms, \%terms );
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
    my @customobjects;
    if ( lc $ctx->stash( 'tag' ) eq 'customobjectscount' ) {
        if ( @ids ) {
            if (! $args->{ include_draft } ) {
                return MT->model( $class )->count( { id => \@ids, status => CustomObject::CustomObject::RELEASE() } );
            } else {
                return MT->model( $class )->count( { id => \@ids } );
            }
        } else {
            return MT->model( $class )->count( \@terms, \%params );
        }
    } else {
        if ( @ids ) {
            if ( $args->{ include_draft } ) {
                @customobjects = MT->model( $class )->load( { id => \@ids } );
            } else {
                @customobjects = MT->model( $class )->load( { id => \@ids, status => CustomObject::CustomObject::RELEASE() } );
            }
        } else {
            @customobjects = MT->model( $class )->load( \@terms, \%params );
        }
    }
    if (! $args->{ sort_by } ) {
        if ( @ids ) {
            my %loaded_objects;
            for my $customobject ( @customobjects ) {
                $loaded_objects{ $customobject->id } = $customobject;
            }
            if ( $sort_order eq 'descend' ) {
                @ids = reverse( @ids );
            }
            @customobjects = ();
            for my $object_id ( @ids ) {
                if ( my $object = $loaded_objects{ $object_id } ) {
                    push ( @customobjects, $object );
                }
            }
        }
    }
    my $i = 0; my $res = '';
    my $odd = 1; my $even = 0;
    for my $customobject ( @customobjects ) {
        local $ctx->{ __stash }{ 'customobject' } = $customobject;
        my $othor_blog;
        if ( $blog->id != $customobject->blog_id ) {
            $othor_blog = $customobject->blog;
        }
        local $ctx->{ __stash }{ blog } = $othor_blog || $blog;
        local $ctx->{ __stash }{ blog_id } = $othor_blog ? $othor_blog->id : $blog->id;
        local $ctx->{ __stash }->{ vars }->{ __first__ } = 1 if ( $i == 0 );
        local $ctx->{ __stash }->{ vars }->{ __counter__ } = $i + 1;
        local $ctx->{ __stash }->{ vars }->{ __odd__ } = $odd;
        local $ctx->{ __stash }->{ vars }->{ __even__ } = $even;
        local $ctx->{ __stash }->{ vars }->{ __last__ } = 1 if ( !defined( $customobjects[ $i + 1 ] ) );
        my $out = $builder->build( $ctx, $tokens, {
            %$cond,
            'customobjectsheader' => $i == 0,
            'customobjectsfooter' => !defined( $customobjects[ $i + 1 ] ),
        } );
        if ( !defined( $out ) ) { return $ctx->error( $builder->errstr ) };
        $res .= $out;
        if ( $odd == 1 ) { $odd = 0 } else { $odd = 1 };
        if ( $even == 1 ) { $even = 0 } else { $even = 1 };
        $i++;
    }
    return $res;
}

sub _hdlr_customobjects_header {
    my ( $ctx, $args, $cond ) = @_;
    if ( $ctx->{ __stash }->{ vars }->{ __first__ } ) {
        return _hdlr_pass_tokens( $ctx, $args, $cond );
    } else {
        return '';
    }
}

sub _hdlr_customobjects_footer {
    my ( $ctx, $args, $cond ) = @_;
    if ( $ctx->{ __stash }->{ vars }->{ __last__ } ) {
        return _hdlr_pass_tokens( $ctx, $args, $cond );
    } else {
        return '';
    }
}

sub _hdlr_pass_tokens {
    my ( $ctx, $args, $cond ) = @_;
    $ctx->stash( 'builder' )->build( $ctx, $ctx->stash( 'tokens' ), $cond );
}

sub _hdlr_customfield_column {
    my ( $ctx, $args ) = @_;
    my $field = $ctx->stash( 'field' ) or return $ctx->error();
    my $col = $args->{ column };
    if (! $field->has_column( $col ) ) {
        if ( $col =~ m/on$/i ) {
            $col =~ s/on$/_on/i;
            if (! $field->has_column( $col ) ) {
                return '';
            }
        } else {
            return '';
        }
    }
    if ( $col =~ /_on$/ ) {
        if ( my $datetime = $field->$col ) {
            $args->{ ts } = $datetime;
            return $ctx->build_date( $args );
        }
    }
    return $field->$col || '';
}

sub _hdlr_customobject_label {
    my ( $ctx, $args ) = @_;
    my $app = MT->instance();
    my $blog = $ctx->stash( 'blog' );
    $blog = $app->blog unless $blog;
    my $blog_id = $args->{ blog_id };
    if ( $blog_id && ( $blog->id != $blog_id ) ) {
        require MT::Blog;
        $blog = MT::Blog->load( $blog_id );
    }
    my $component = $args->{ component };
    if (! $component ) {
        $component = 'CustomObjectConfig';
    }
    my $language = $args->{ language };
    $language = $args->{ lang } unless $language;
    $language = '' unless $language;
    my $plural = $args->{ plural };
    my ( $label_en, $label_ja, $label_plural ) = CustomObject::Plugin::__get_settings( $app, $blog, $component );
    if ( $language eq 'ja' ) {
        return $label_ja;
    } else {
        if ( $plural ) {
            return $label_plural;
        } else {
            return $label_en;
        }
    }
    my $plugin = MT->component( 'CustomObject' );
    return $plugin->translate( 'CustomObject' );
}

sub _hdlr_customobject_author {
    my ( $ctx, $args, $cond ) = @_;
    my $customobject = $ctx->stash( 'customobject' );
    return $ctx->error() unless defined $customobject;
    $ctx->stash( 'author', $customobject->author );
    $ctx->stash( 'builder' )->build( $ctx, $ctx->stash( 'tokens' ), $cond );
}

sub _hdlr_customobject_folder {
    my ( $ctx, $args, $cond ) = @_;
    my $customobject = $ctx->stash( 'customobject' );
    return $ctx->error() unless defined $customobject;
    if ( my $folder = $customobject->folder ) {
        $ctx->stash( 'category', $folder );
        return $ctx->stash( 'builder' )->build( $ctx, $ctx->stash( 'tokens' ), $cond );
    }
    return '';
}

sub _hdlr_if_customobject_tagged {
    my ( $ctx, $args, $cond ) = @_;
    return unless $ctx;
    my $customobject = $ctx->stash( 'customobject' );
    return $ctx->error() unless defined $customobject;
    my $tag = defined $args->{ name } ? $args->{ name } : ( defined $args->{ tag } ? $args->{ tag } : '' );
    if ( $tag ne '' ) {
        $customobject->has_tag( $tag );
    } else {
        my @tags = $customobject->tags;
        @tags = grep /^[^@]/, @tags
            if !$args->{ include_private };
        return @tags ? 1 : 0;
    }
}

sub _hdlr_customobject_tags {
    my ( $ctx, $args, $cond ) = @_;
    my $datasource;
    if ( lc( MT->config( 'ObjectDriver' ) ) =~ /oracle/ ) {
        $datasource = 'co';
    } else {
        $datasource = 'customobject';
    }
    my $tokens = $ctx->stash( 'tokens' );
    my $builder = $ctx->stash( 'builder' );
    my $customobject = $ctx->stash( 'customobject' );
    return $ctx->error() unless defined $customobject;
    require MT::ObjectTag;
    require MT::Tag;
    my $glue = $args->{ glue };
    local $ctx->{ __stash }{ tag_max_count } = undef;
    local $ctx->{ __stash }{ tag_min_count } = undef;
    local $ctx->{ __stash }{ all_tag_count } = undef;
    local $ctx->{ __stash }{ class_type } = 'customobject';
    # my @tags = MT::Tag->load( undef, { 'sort' => 'name',
    #                                    'join' => MT::ObjectTag->join_on( 'tag_id',
    #                                             { object_id => $customobject->id,
    #                                               blog_id => $customobject->blog_id,
    #                                               object_datasource => $datasource },
    #                                             { unique => 1 } ) } );
    my $tags = $customobject->get_tag_objects;
    my $res = '';
    for my $tag ( @$tags ) {
        next if $tag->is_private && !$args->{ include_private };
        local $ctx->{ __stash }{ Tag } = $tag;
        local $ctx->{ __stash }{ tag_count } = undef;
        local $ctx->{ __stash }{ tag_customobject_count } = undef;
        defined( my $out = $builder->build( $ctx, $tokens, $cond ) )
            or return $ctx->error( $builder->errstr );
        $res .= $glue if defined $glue && length( $res ) && length( $out );
        $res .= $out;
    }
    return $res;
}

sub _hdlr_folder_link {
    my ( $ctx, $args ) = @_;
    return unless $ctx;
    my $r = MT::Request->instance;
    my $key = $args->{ class };
    $key = 'customobject' unless $key;
    my $category = $ctx->stash( 'category' );
    return '' unless $category;
    if ( my $permalink = $r->cache( $key . '_folder_link:' . $category->id ) ) {
        return $permalink;
    }
    my $custom_objects = MT->registry( 'custom_objects' );
    my $at = $custom_objects->{ $key }->{ id };
    $at = 'Folder' . $at;
    require MT::TemplateMap;
    my $map = MT::TemplateMap->load( { archive_type => $at,
                                       is_preferred => 1,
                                       blog_id => $category->blog_id } );
    return '' unless $map;
    my $file_template = $map->file_template || '%c/' . $key . '/%i';
    require ArchiveType::FolderCustomObject;
    require MT::Template::Context;
    require MT::Blog;
    my $blog = MT::Blog->load( $category->blog_id );
    $ctx->stash( 'blog', $blog );
    $ctx->stash( 'blog_id', $category->blog_id );
    $ctx->stash( 'category', $category );
    my $permalink = ArchiveType::FolderCustomObject::get_publish_path( $ctx, $file_template, 'url' );
    $r->cache( $key . '_folder_link:' . $category->id, $permalink );
}

sub _hdlr_customobject_permalink {
    my ( $ctx, $args ) = @_;
    return unless $ctx;
    my $customobject = $ctx->stash( 'customobject' );
    return $ctx->error() unless defined $customobject;
    return $customobject->permalink;
    # require MT::Request;
    # my $r = MT::Request->instance;
    # my $customobject = $ctx->stash( 'customobject' );
    # return $ctx->error() unless defined $customobject;
    # if ( my $permalink = $r->cache( 'customobject_permalink:' . $customobject->id ) ) {
    #     return $permalink;
    # }
    # my $custom_objects = MT->registry( 'custom_objects' );
    # my $key = $customobject->class;
    # my $at = $custom_objects->{ $key }->{ id };
    # require MT::TemplateMap;
    # my $map = MT::TemplateMap->load( { archive_type => $at,
    #                                    is_preferred => 1,
    #                                    blog_id => $customobject->blog_id } );
    # return '' unless $map;
    # my $file_template = $map->file_template || $customobject->class . '/%f';
    # require ArchiveType::CustomObject;
    # $ctx->stash( 'blog', $customobject->blog );
    # my $permalink = ArchiveType::CustomObject::get_publish_path( $ctx, $file_template, 'url' );
    # $r->cache( 'customobject_permalink:' . $customobject->id, $permalink );
    # return $permalink;
}

sub _hdlr_customobject_basename {
    my ( $ctx, $args ) = @_;
    return unless $ctx;
    my $customobject = $ctx->stash( 'customobject' );
    return $ctx->error() unless defined $customobject;
    my $basename = $customobject->basename;
    if ( my $sep = $args->{ separator } ) {
        if ( $sep eq '-' ) {
            $basename =~ s/_/-/g;
        } elsif ( $sep eq '_' ) {
            $basename =~ s/-/_/g;
        }
    }
    return $basename;
}

sub _hdlr_customobject_column {
    my ( $ctx, $args ) = @_;
    return unless $ctx;
    my $tag = $ctx->stash( 'tag' );
    $tag = lc( $tag );
    $tag =~ s/^customobject//i;
    if ( $tag eq 'column' ) {
        $tag = $args->{ column };
    }
    $tag = 'blog_id' if $tag eq 'blogid';
    my $customobject = $ctx->stash( 'customobject' );
    return $ctx->error() unless defined $customobject;
    if ( $tag =~ /on$/ && ! $customobject->has_column( $tag ) ) {
        $tag =~ s/on$/_on/;
    }
    if ( $customobject->has_column( $tag ) ) {
        if ( $tag =~ /_on$/ ) {
            if ( my $datetime = $customobject->$tag ) {
                $args->{ ts } = $datetime;
                return $ctx->build_date( $args );
            }
        }
        return $customobject->$tag || '';
    }
    return '';
}

sub _hdlr_customobject_date {
    my ( $ctx, $args ) = @_;
    return unless $ctx;
    my $tag = $ctx->stash( 'tag' );
    $tag =~ s/^customobject//i;
    $tag =~ s/on$//i;
    $tag =lc( $tag ) . '_on';
    my $customobject = $ctx->stash( 'customobject' );
    return $ctx->error() unless defined $customobject;
    return '' unless $customobject->has_column( $tag );
    my $date = $customobject->$tag;
    $args->{ ts } = $date;
    $date = $ctx->build_date( $args );
    return $date || '';
}

sub _hdlr_if_customobject_bool {
    my ( $ctx, $args, $cond ) = @_;
    return unless $ctx;
    my $tag = $ctx->stash( 'tag' );
    $tag =lc( $tag );
    $tag =~ s/^ifcustomobject//i;
    my $customobject = $ctx->stash( 'customobject' );
    return $ctx->error() unless defined $customobject;
    return 0 unless $customobject->has_column( $tag );
    my $bool = $customobject->$tag;
    return 1 if $bool;
    return 0;
}

sub _hdlr_author_displayname {
    my ( $ctx, $args ) = @_;
    my $customobject = $ctx->stash( 'customobject' );
    return $ctx->error() unless defined $customobject;
    my $author_name = $customobject->author->nickname;
    $author_name = $customobject->author->name unless $author_name;
    return $author_name;
}

sub _hdlr_customobjectfieldscope {
    my ( $ctx, $args ) = @_;
    my $class = $args->{ class };
    if ( $class ) {
        $class =~ s/group$//;
        return MT->config( $class . 'FieldScope' ) || 'blog';
    }
    return MT->config( 'CustomObjectFieldScope' ) || 'blog';
}

sub _hdlr_if_not_sent {
    my ( $ctx, $args, $cond ) = @_;
    require MT::Request;
    my $r = MT::Request->instance;
    my $key = $args->{ key };
    if ( $r->cache( $key ) ) {
        return 0;
    } else {
        $r->cache( $key, 1 );
        return 1;
    }
}

sub _hdlr_if_hyperion {
    if ( MT->version_id =~ /^5\.0/ ) {
        return 1;
    }
    return 0;
}

sub _hdlr_if_not_system {
    my ( $ctx, $args, $cond ) = @_;
    my $app = MT->instance();
    if ( $app->blog ) {
        return 1;
    }
    return 0;
}

sub _hdlr_setcontext {
    my ( $ctx, $args, $cond ) = @_;
    for my $key ( keys %$args ) {
        if ( $key ne '@' ) {
            $ctx->stash( $key, $args->{ $key } );
        }
    }
    $ctx->stash( 'builder' )->build( $ctx, $ctx->stash( 'tokens' ), $cond );
}

sub _hdlr_trans {
    my ( $ctx, $args, $cond ) = @_;
    my $phrase = $args->{ phrase };
    my $component = $args->{ component };
    my @params;
    my $param = $args->{ params };
    if ( $param && $param =~ /\%\%/ ) {
        @params = split( /\%\%/, $param );
    } else {
        push ( @params, $param );
    }
    if ( $component ) {
        my $plugin = MT->component( $component );
        if ( $plugin ) {
            return $plugin->translate( $phrase, @params );
        }
    }
    return MT->translate( $phrase, @params );
}

sub _hdlr_component_path {
    my ( $ctx, $args, $cond ) = @_;
    my $component = $args->{ component };
    $component = $args->{ plugin } unless $component;
    $component = MT->component( $component );
    my $component_path = $component->path;
    $component_path =~ s!\\!/!g;
    return $component_path;
}

sub _hdlr_if_component {
    my ( $ctx, $args, $cond ) = @_;
    my $component = $args->{ component };
    $component = $args->{ plugin } unless $component;
    if ( $component ) {
        my $plugin = MT->component( $component );
        return 1 if $plugin;
    }
    return 0;
}

1;