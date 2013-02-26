package CustomObject::CustomObject;
use strict;
use base qw( MT::Object MT::Taggable MT::Revisable );

use MT::Blog;
use MT::Author;
use MT::Request;
use MT::Log;
use MT::Tag;
use MT::Util qw( trim dirify );

use CustomObject::CustomObjectGroup;
use CustomObject::CustomObjectOrder;
use CustomObject::Util qw( is_cms current_ts valid_ts utf8_on is_oracle );

my $datasource;
if ( lc( MT->config( 'ObjectDriver' ) ) =~ /oracle/ ) {
    $datasource = 'co';
} else {
    $datasource = 'customobject';
}

my $class_type = 'customobject';
__PACKAGE__->install_properties( {
    column_defs => {
        'id'            => 'integer not null auto_increment',
        'blog_id'       => 'integer',
        'author_id'     => 'integer',
        'name'          => { type  => 'string',
                             size  => '255',
                             label => 'Name',
                             ( is_oracle() ? () : ( revisioned => 1 ) ),
                        },
        'body'          => { type  => 'text',
                             label => 'Body',
                             ( is_oracle() ? () : ( revisioned => 1 ) ),
                        },
        'keywords'      => { type  => 'string',
                             size  => '255',
                             label => 'Keywords',
                             ( is_oracle() ? () : ( revisioned => 1 ) ),
                        },
        # 'editor_select' => 'boolean',
        'authored_on'   => { type  => 'datetime',
                             label => 'Publish Date',
                             ( is_oracle() ? () : ( revisioned => 1 ) ),
                        },
        'period_on'     => { type  => 'datetime',
                             label => 'End date',
                             ( is_oracle() ? () : ( revisioned => 1 ) ),
                        },
        'set_period'    => { type  => 'boolean',
                             label => 'Set Period',
                             ( is_oracle() ? () : ( revisioned => 1 ) ),
                        },
        # 'created_on'    => 'datetime',
        # 'modified_on'   => 'datetime',
        'status'        => { type  => 'integer',
                             label => 'Status',
                             ( is_oracle() ? () : ( revisioned => 1 ) ),
                        },
        'class'         => 'string(25)',
        'template_id'   => { type  => 'integer',
                             label => 'Template',
                             ( is_oracle() ? () : ( revisioned => 1 ) ),
                        },
        'category_id'   => { type  => 'integer',
                             label => 'Folder',
                             ( is_oracle() ? () : ( revisioned => 1 ) ),
                        },
        'basename'      => { type  => 'string',
                             size  => '255',
                             label => 'Basename',
                             ( is_oracle() ? () : ( revisioned => 1 ) ),
                        },
    },
    indexes => {
        'blog_id'       => 1,
        'author_id'     => 1,
        'name'          => 1,
        'keywords'      => 1,
        'authored_on'   => 1,
        'set_period'    => 1,
        'period_on'     => 1,
        'created_on'    => 1,
        'modified_on'   => 1,
        'status'        => 1,
        'basename'      => 1,
        'category_id'   => 1,
        'tag_count'     => {
            columns => [ 'blog_id', 'id' ],
        },
    },
    child_of    => [ 'MT::Blog', 'MT::Website' ],
    datasource  => $datasource,
    primary_key => 'id',
    audit       => 1,
    class_type  => $class_type,
    meta        => 1,
} );

sub HOLD ()      { 1 }
sub DRAFT ()     { 1 }
sub RELEASE ()   { 2 }
sub PUBLISHED () { 2 }
sub PUBLISHING (){ 2 }
sub REVIEW ()    { 3 }
sub UNAPPROVED() { 3 }
sub RESERVED ()  { 4 }
sub FUTURE ()    { 4 }
sub CLOSED ()    { 5 }
sub FINISED ()   { 5 }

sub status_text {
    my $obj = shift;
    my $status = $obj;
    if ( ref $obj ) {
        $status = $obj->status;
    }
    if ( $status == HOLD() ) {
        return 'Draft';
    } elsif ( $status == RELEASE() ) {
        return 'Publishing';
    } elsif ( $status == REVIEW() ) {
        return 'Review';
    } elsif ( $status == FUTURE() ) {
        return 'Future';
    } elsif ( $status == CLOSED() ) {
        return 'Closed';
    }
}

sub status_int {
    my ( $obj, $status ) = @_;
    $status = uc( $status );
    if ( ( $status eq 'DRAFT' ) || ( $status eq 'HOLD' ) ) {
        return 1;
    } elsif ( ( $status eq 'PUBLISHED' ) || ( $status eq 'PUBLISHING' ) || ( $status eq 'RELEASE' ) ) {
        return 2;
    } elsif ( ( $status eq 'UNAPPROVED' ) || ( $status eq 'REVIEW' ) ) {
        return 3;
    } elsif ( ( $status eq 'RESERVED' ) || ( $status eq 'FUTURE' ) ) {
        return 4;
    } elsif ( ( $status eq 'FINISED' ) || ( $status eq 'CLOSED' ) ) {
        return 5;
    }
    return 0;
}

sub plugin {
    return MT->component( 'CustomObject' );
}

sub config_plugin {
    return MT->component( 'CustomObjectConfig' );
}

sub group_label {
    my $plugin = MT->component( 'CustomObject' );
    return $plugin->translate( 'CustomObject Group' );
}

sub group_label_plural {
    my $plugin = MT->component( 'CustomObject' );
    return $plugin->translate( 'CustomObject Groups' );
}

sub class_label {
    my $app = MT->instance;
    if ( is_cms( $app ) ) {
        my $model = $app->param( 'class' );
        if ( $model && $model ne 'customobject' ) {
            $model =~ s/group$//;
            my $custom_objects = MT->registry( 'custom_objects' );
            my @objects = keys( %$custom_objects );
            if ( grep( /^$model$/, @objects ) ) {
                if ( my $class = MT->model( $model ) ) {
                    return $class->class_label;
                }
            }
        }
    }
    my $plugin = MT->component( 'CustomObject' );
    return $plugin->translate( 'CustomObject' );
}

sub class_label_plural {
    my $app = MT->instance;
    if ( is_cms( $app ) ) {
        my $model = $app->param( 'class' );
        if ( $model && $model ne 'customobject' ) {
            $model =~ s/group$//;
            my $custom_objects = MT->registry( 'custom_objects' );
            my @objects = keys( %$custom_objects );
            if ( grep( /^$model$/, @objects ) ) {
                if ( my $class = MT->model( $model ) ) {
                    return $class->class_label_plural;
                }
            }
        }
    }
    my $plugin = MT->component( 'CustomObject' );
    return $plugin->translate( 'CustomObjects' );
}

sub class_plural {
    return 'CustomObjects';
}

sub folder {
    my $obj = shift;
    if ( $obj->category_id && $obj->category_id != -1 ) {
        my $folder = MT->model( 'folder' )->load( $obj->category_id );
        return $folder if $folder;
    }
    return undef;
}

sub folder_path {
    my $obj = shift;
    my $r = MT::Request->instance;
    my $folders = $r->cache( 'customobject_folder:' . $obj->id );
    if (! $folders ) {
        if ( my $folder = $obj->folder ) {
            while ( $folder ) {
                unshift ( @$folders, $folder );
                $folder = $folder->parent_category;
            }
        }
    }
    $r->cache( 'customobject_folder:' . $obj->id, $folders );
    return wantarray ? @$folders : $folders;
}

sub category {
    my $obj = shift;
    return $obj->folder;
}

sub save {
    my $obj = shift;
    my $app = MT->instance();
    my $plugin = MT->component( 'CustomObject' );
    my $original;
    my $orig_folder;
    my $new_folder;
    my $is_new;
    my $r = MT::Request->instance;
    if (! $obj->class ) {
        $obj->class( 'customobject' );
    }
    if ( $obj->category_id && $obj->category_id == -1 ) {
        $obj->category_id( undef );
    }
    # if ( is_cms( $app ) ) { # to cms_pre_save.foo
    #     if (! $app->validate_magic ) {
    #         $app->return_to_dashboard();
    #         return 0;
    #     } else {
    #         if (! CustomObject::Plugin::_customobject_permission( $obj->blog ) ) {
    #             $app->return_to_dashboard( permission => 1 );
    #             return 0;
    #         }
    #     }
    # }
    if (! defined( $obj->basename ) || ( $obj->basename eq '' ) ) {
        my $name = make_unique_basename( $obj );
        $obj->basename( $name );
    }
    if ( is_cms( $app ) ) {
        if ( $obj->id ) {
            if ( $r->cache( 'saved_customobject:' . $obj->id ) ) {
                $obj->SUPER::save( @_ );
                return 1;
            }
        }
    }
    if ( is_cms( $app ) ) {
        my $ts = current_ts( $obj->blog );
        my $columns = $obj->column_names;
        for my $column ( @$columns ) {
            if ( $column =~ /_on$/ ) {
                my $date = trim( $app->param( $column . '_date' ) ) if $app->param( $column . '_date' );
                my $time = trim( $app->param( $column . '_time' ) ) if $app->param( $column . '_time' );
                if ( $date && $time ) {
                    $date =~ s/\-//g;
                    $time =~ s/://g;
                    my $ts_on = $date . $time;
                    if ( valid_ts( $ts_on ) ) {
                        $obj->$column( $ts_on );
                    }
                }
            }
        }
        if (! $obj->created_on ) {
            $obj->created_on( $ts );
        }
        $obj->modified_on( $ts );
        if ( $obj->id ) {
            my $author = MT::Author->load( $obj->author_id );
            if (! defined $author ) {
                $obj->author_id( $app->user->id );
            }
        } else {
            $obj->author_id( $app->user->id );
        }
        if (! $obj->status ) {
            $obj->status( HOLD() );
        }
        if ( $app->mode eq 'save' ) {
            if ( my $tags  = $app->param( 'tags' ) ) {
                my @t = split( /,/, $tags );
                $obj->set_tags( @t );
            } else {
                $obj->remove_tags();
            }
        }
        # if ( $obj->id ) {
        #     $original = $r->cache( 'customobject_original' . $obj->id );
        #     if (! $original ) {
        #         $original = $obj->clone_all();
        #     }
        # }
        # if ( $app->mode eq 'save' ) {
        #     $app->run_callbacks( 'cms_pre_save.customobject', $app, $obj, $original ) || return 0;
        # }
        # TODO::Revision
        # See MT::CMS::Common::save_snapshot;
    }
    # for other CMS, Viewer or etc.
    my $columns = $obj->column_names;
    for my $column ( @$columns ) {
        if ( $column =~ /_check$/ ) {
            my @checks = $app->param( $column );
            $obj->$column( join( ',', @checks ) );
        }
        if ( $column =~ /_img_bin$/ ) {
            my $q = $app->param;
            if ( my $file = $q->upload( $column ) ) {
                my $img;
                while( read ( $file, my $buffer, 1024 ) ) {
                    $img .= $buffer;
                }
                $obj->$column( $img );
            } else {
                $obj->$column( undef );
            }
        }
    }
    my $blog = $obj->blog;
    if (! $obj->id ) {
        $is_new = 1;
    }
    $obj->SUPER::save( @_ );
    # if ( is_cms( $app ) ) {
    #     return 1 if $r->cache( 'saved_customobject:' . $obj->id );
    #     $r->cache( 'saved_customobject:' . $obj->id, $obj );
    # }
    $r->cache( 'saved_customobject:' . $obj->id, $obj );
    if ( $is_new ) {
        if ( $app->mode eq 'save' ) {
            $app->log( {
                message => $plugin->translate( '[_1] \'[_2]\' (ID:[_3]) created by \'[_4]\'', $obj->class_label, utf8_on( $obj->name ), $obj->id, $app->user->name ),
                blog_id => $obj->blog_id,
                author_id => $app->user->id,
                class => $obj->class,
                level => MT::Log::INFO(),
            } );
        }
        my @blog_ids;
        if ( $blog->class eq 'blog' ) {
            @blog_ids = ( $blog->id, $blog->parent_id );
        } else {
            push ( @blog_ids, $blog->id );
        }
        my @groups = CustomObject::CustomObjectGroup->load( { additem => 1,
                                                              blog_id => \@blog_ids,
                                                              class => $obj->class . 'group' } );
        for my $group ( @groups ) {
            my $addfilter = $group->addfilter;
            if ( $addfilter ) {
                if ( $addfilter eq 'blog' ) {
                    my $addfilter_blog_id = $group->addfilter_blog_id;
                    if ( $addfilter_blog_id ) {
                        if ( $obj->blog_id != $addfilter_blog_id ) {
                            next;
                        }
                    }
                } elsif ( $addfilter eq 'tag' ) {
                    my $addfiltertag = $group->addfiltertag;
                    my @tags = $obj->get_tags;
                    if (! grep( /^$addfiltertag$/, @tags ) ) {
                        next;
                    }
                }
            }
            my $direction;
            if ( $group->addposition ) {
                $direction = 'descend';
            } else {
                $direction = 'ascend';
            }
            my $last = CustomObject::CustomObjectOrder->load(
                                                      { group_id => $group->id },
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
            my $order = CustomObject::CustomObjectOrder->get_by_key(
                                                      { group_id => $group->id,
                                                        order => $pos,
                                                        customobject_id => $obj->id } );
            $order->save or die $order->errstr;
        }
    }
    if ( is_cms( $app ) ) {
        if ( $app->mode eq 'save' ) {
            $app->remove_preview_file;
            if (! $is_new ) {
                $app->log( {
                    message => $plugin->translate( '[_1] \'[_2]\' (ID:[_3]) edited by \'[_4]\'', $obj->class_label, $obj->name, $obj->id, $app->user->name ),
                    blog_id => $obj->blog_id,
                    author_id => $app->user->id,
                    class => $obj->class,
                    level => MT::Log::INFO(),
                } );
            }
            my $publisher; my $both_folder;
            $original = $r->cache( 'customobject_original' . $obj->id );
            if ( $original ) {
                if ( $original->status == PUBLISHED () ) {
                    $publisher = 1;
                }
                $orig_folder = $original->folder;
            }
            if ( $obj->status == PUBLISHED () ) {
                $publisher = 1;
            }
            $new_folder = $obj->folder;
            if ( $orig_folder && (! $new_folder ) ) {
                $publisher = 1;
                $both_folder = 1;
            } elsif ( $new_folder && (! $orig_folder ) ) {
                $publisher = 1;
                $both_folder = 1;
            } elsif ( $new_folder && $orig_folder ) {
                if ( $new_folder->id != $orig_folder->id ) {
                    $publisher = 1;
                    $both_folder = 1;
                } else {
                    $both_folder = 0;
                }
            }
            # if ( $app->param( '_preview_file' ) ) {
            #     $app->run_callbacks( 'cms_post_save.' . $obj->class, $app, $obj, $original )
            #         or return $app->error( $app->errstr() );
            # }
            if ( $publisher ) {
                require ArchiveType::CustomObject;
                my $custom_objects = MT->registry( 'custom_objects' );
                my $at = $custom_objects->{ $obj->class }->{ id };
                ArchiveType::CustomObject::rebuild_customobject( $app, $obj->blog, $at, $obj );
                require ArchiveType::FolderCustomObject;
                $at = 'Folder' . $at;
                if ( $new_folder ) {
                    ArchiveType::FolderCustomObject::rebuild_folder( $app, $obj->blog, $at, $new_folder );
                }
                if ( $orig_folder ) {
                    if ( $both_folder ) {
                        ArchiveType::FolderCustomObject::rebuild_folder( $app, $obj->blog, $at, $orig_folder );
                    }
                }
            }
            if ( $app->param( '_preview_file' ) ) {
                my $query_str = $app->uri( mode => 'view',
                                           args => {
                                               _type => 'customobject',
                                               class => $obj->class,
                                               id => $obj->id,
                                               blog_id => $obj->blog_id,
                                               saved => 1,
                                           } );
                my $return_url = $app->base . $query_str;
                $app->print( 'location: ' . "$return_url\n\n" );
                # return $app->redirect( $app->base . $query_str );
            }
        }
    }
    return 1;
}

sub remove {
    my $obj = shift;
    if ( ref $obj ) {
        my $app = MT->instance();
        my $plugin = MT->component( 'CustomObject' );
        # my $original = $obj->clone_all();
        if ( is_cms( $app ) ) {
            if (! $app->validate_magic ) {
                $app->return_to_dashboard();
                return 0;
            } else {
                if (! CustomObject::Plugin::_customobject_permission( $obj->blog ) ) {
                    $app->return_to_dashboard( permission => 1 );
                    return 0;
                }
            }
        }
        if ( $obj->status == RELEASE() ) {
            $obj->status( HOLD() );
            $obj->save;
            require ArchiveType::CustomObject;
            my $custom_objects = MT->registry( 'custom_objects' );
            my $at = $custom_objects->{ $obj->class }->{ id };
            ArchiveType::CustomObject::rebuild_customobject( $app, $obj->blog, $at, $obj );
            require ArchiveType::FolderCustomObject;
            $at = 'Folder' . $at;
            if ( my $folder = $obj->folder ) {
                ArchiveType::FolderCustomObject::rebuild_folder( $app, $obj->blog, $at, $folder );
            }
        }
        $obj->remove_tags();
        $obj->SUPER::remove( @_ );
        if ( is_cms( $app ) ) {
            $app->log( {
                message => $plugin->translate( '[_1] \'[_2]\' (ID:[_3]) deleted by \'[_4]\'', $obj->class_label, $obj->name, $obj->id, $app->user->name ),
                blog_id => $obj->blog_id,
                author_id => $app->user->id,
                class => $obj->class,
                level => MT::Log::INFO(),
            } );
            # $app->run_callbacks( 'cms_post_delete.customobject', $app, $obj, $original );
        }
        my @order = CustomObject::CustomObjectOrder->load( { customobject_id => $obj->id } );
        for my $ord ( @order ) {
            $ord->remove or die $ord->errstr;
        }
        return 1;
        $obj->remove_tags();
    }
    $obj->SUPER::remove( @_ );
}

sub author {
    my $obj = shift;
    my $r = MT::Request->instance;
    my $author = $r->cache( 'cache_author:' . $obj->author_id );
    return $author if defined $author;
    $author = MT::Author->load( $obj->author_id ) if $obj->author_id;
    unless ( defined $author ) {
        $author = MT::Author->new;
        my $plugin = MT->component( 'CustomObject' );
        $author->name( $plugin->translate( '(Unknown)' ) );
        $author->nickname( $plugin->translate( '(Unknown)' ) );
    }
    $r->cache( 'cache_author:' . $obj->author_id, $author );
    return $author;
}

sub blog {
    my $obj = shift;
    my $r = MT::Request->instance;
    my $blog = $r->cache( 'cache_blog:' . $obj->blog_id );
    return $blog if defined $blog;
    $blog = MT::Blog->load( $obj->blog_id );
    $r->cache( 'cache_blog:' . $obj->blog_id, $blog );
    return $blog;
}

sub _nextprev {
    my ( $obj, $direction ) = @_;
    my $r = MT::Request->instance;
    my $nextprev = $r->cache( "customobject_$direction:" . $obj->id );
    return $nextprev if defined $nextprev;
    $nextprev = $obj->nextprev(
        direction => $direction,
        terms     => { blog_id => $obj->blog_id },
        by        => 'created_on',
    );
    $r->cache( "customobject_$direction:" . $obj->id, $nextprev );
    return $nextprev;
}

# sub default_module_mtml {
#     my $template = <<MTML;
# <MTCustomObjects group_id="\$group_id">
# <MTCustomObjectsHeader><ul></MTCustomObjectsHeader>
#     <li><MTCustomObjectName escape="html"></li>
# <MTCustomObjectsFooter></ul></MTCustomObjectsFooter>
# </MTCustomObjects>
# MTML
#     return $template;
# }

sub make_unique_basename {
    my $obj = shift;
    my $blog = $obj->blog;
    my $name = $obj->name;
    my $class = $obj->class;
    $name = '' if !defined $name;
    $name =~ s/^\s+|\s+$//gs;
    $name = $class if $name eq '';
    my $limit = $blog->basename_limit || 30;
    $limit = 15 if $limit < 15; $limit = 250 if $limit > 250;
    my $base = substr( dirify( $name ), 0, $limit );
    $base =~ s/_+$//;
    $base = $class if $base eq '';
    my $i = 1;
    my $base_copy = $base;
    $class = MT->model( $class );
    return MT::Util::_get_basename( $class, $base, $blog );
}

sub gather_changed_cols {
    my $obj = shift;
    my ( $orig, $app ) = @_;
    MT::Revisable::gather_changed_cols( $obj, @_ );
    my $changed_cols = $obj->{ changed_revisioned_cols } || [];
    return 1 unless $obj->id;
    #return 1 if @$changed_cols;
    my $tag_changed = 0;
    my @objecttags  = MT->model( 'objecttag' )->load(
        {   object_id         => $obj->id,
            object_datasource => $obj->datasource,
            blog_id           => $obj->blog_id
        }
    );
    my @tag_names = $obj->get_tags;
    # the number of tags have changed
    $tag_changed = 1 if scalar( @tag_names ) != scalar( @objecttags );
    unless ( $tag_changed ) {
        if ( @tag_names ) {
            my @tags = MT::Tag->load( { name => \@tag_names },
                { binary => { name => 1 } } );
            $tag_changed = 1 if scalar(@tags) != scalar( @objecttags );
            my %tags = map { $_->id => 1 } @tags;
            foreach my $objecttag ( @objecttags ) {
                delete $tags{ $objecttag->tag_id };
            }
            $tag_changed = 1 if keys( %tags );
        }
    }
    push @$changed_cols, 'tags' if $tag_changed;
    $obj->{ changed_revisioned_cols } = $changed_cols
        if $tag_changed;
    1;
}

sub pack_revision {
    my $obj    = shift;
    my $values = MT::Revisable::pack_revision( $obj );
    my ( @tags );
    if ( my $tags = $obj->get_tag_objects ) {
        @tags = map { $_->id } @$tags
            if @$tags;
    }
    $values->{ __rev_tags } = \@tags;
    $values;
}

sub unpack_revision {
    my $obj = shift;
    my ( $packed_obj ) = @_;
    MT::Revisable::unpack_revision( $obj, @_ );
    if ( my $rev_tags = delete $packed_obj->{ __rev_tags } ) {
        delete $obj->{ __tags };
        delete $obj->{ __tag_objects };
        require MT::Tag;
        MT::Tag->clear_cache(
            datasource => $obj->datasource,
            ( $obj->blog_id ? ( blog_id => $obj->blog_id ) : () )
        );
        require MT::Memcached;
        MT::Memcached->instance->delete( $obj->tag_cache_key );
        if ( @$rev_tags ) {
            my $lookups = MT::Tag->lookup_multi( $rev_tags );
            my @tags = grep { defined } @$lookups;
            $obj->{ __tags }             = [ map { $_->name } @tags ];
            $obj->{ __tag_objects }      = \@tags;
            $obj->{ __missing_tags_rev } = 1
                if scalar( @tags ) != scalar( @$lookups );
        } else {
            $obj->{ __tags }        = [];
            $obj->{ __tag_objects } = [];
        }
    }
}

sub permalink {
    my $obj = shift;
    require MT::Request;
    my $r = MT::Request->instance;
    if ( my $permalink = $r->cache( 'customobject_permalink:' . $obj->id ) ) {
        return $permalink;
    }
    my $custom_objects = MT->registry( 'custom_objects' );
    my $key = $obj->class;
    my $at = $custom_objects->{ $key }->{ id };
    require MT::TemplateMap;
    my $map = MT::TemplateMap->load( { archive_type => $at,
                                       is_preferred => 1,
                                       blog_id => $obj->blog_id } );
    return '' unless $map;
    my $file_template = $map->file_template || $obj->class . '/%f';
    require ArchiveType::CustomObject;
    require MT::Template::Context;
    my $ctx = MT::Template::Context->new;
    $ctx->stash( 'blog', $obj->blog );
    $ctx->stash( 'blog_id', $obj->blog_id );
    $ctx->stash( 'customobject', $obj );
    my $permalink = ArchiveType::CustomObject::get_publish_path( $ctx, $file_template, 'url' );
    $r->cache( 'customobject_permalink:' . $obj->id, $permalink );
    return $permalink;
}

sub parents {
    my $obj = shift;
    {   blog_id => {
            class    => [ MT->model( 'blog' ), MT->model( 'website' ) ],
            optional => 1
        },
        template_id => MT->model( 'template' ),
        category_id => [ MT->model( 'category' ), MT->model( 'folder' ) ],
#         author_id => MT->model( 'author' ),
    };
}

sub tag_count {
    my $obj = shift;
    my ( $terms ) = @_;
    my $pkg = ref $obj ? ref $obj : $obj;
    $terms ||= {};
    my $jterms = {};
    if ( ref $obj ) {
        $terms->{ object_id } = $obj->id if $obj->id;
        $jterms->{ blog_id } = $obj->blog_id if $obj->column( 'blog_id' );
    }
    if ( $terms->{ blog_id } ) {
        $jterms->{ blog_id } = $terms->{ blog_id };
        delete $terms->{ blog_id };
    }
    $jterms->{ object_datasource } = $obj->datasource;
    my $pkg_terms = {};
    $pkg_terms->{ id } = \'=objecttag_object_id';
    $pkg_terms->{ class } = $pkg->class_type;
    require MT::ObjectTag;
    MT::Tag->count(
        undef,
        {
            join => MT::ObjectTag->join_on(
                'tag_id', $jterms,
                { unique => 1, join => $pkg->join_on( undef, $pkg_terms ) }
            )
        }
    );
}

# following for datasource,
# original is from MT::Object::to_xml written in MT::BackupRestore.
sub to_xml {
    my $obj = shift;
    my ( $namespace, $metacolumns ) = @_;

    my $coldefs  = $obj->column_defs;
    my $colnames = $obj->column_names;
    my $xml;

    my $elem = $obj->datasource;

    # PATCH
    $elem = 'customobject';
    # /PATCH

    unless ( UNIVERSAL::isa( $obj, 'MT::Log' ) ) {
        if ( $obj->properties
            && ( my $ccol = $obj->properties->{class_column} ) )
        {
            if ( my $class = $obj->$ccol ) {

                # use class_type value instead if
                # the value resolves to a Perl package
                $elem = $class
                    if defined( MT->model($class) );
            }
        }
    }

    $xml = '<' . $elem;
    $xml .= " xmlns='$namespace'" if defined($namespace) && $namespace;

    my ( @elements, @blobs, @meta );
    for my $name (@$colnames) {
        if ($obj->column($name)
            || ( defined( $obj->column($name) )
                && ( '0' eq $obj->column($name) ) )
            )
        {
            if ( ( $obj->properties->{meta_column} || '' ) eq $name ) {
                push @meta, $name;
                next;
            }
            elsif ( $obj->_is_element( $coldefs->{$name} ) ) {
                push @elements, $name;
                next;
            }
            elsif ( 'blob' eq $coldefs->{$name}->{type} ) {
                push @blobs, $name;
                next;
            }
            $xml .= " $name='"
                . MT::Util::encode_xml( $obj->column($name), 1 ) . "'";
        }
    }
    my ( @meta_elements, @meta_blobs );
    if ( defined($metacolumns) && @$metacolumns ) {
        foreach my $metacolumn (@$metacolumns) {
            my $name = $metacolumn->{name};
            if ( $obj->$name
                || ( defined( $obj->$name ) && ( '0' eq $obj->$name ) ) )
            {
                if ( 'vclob' eq $metacolumn->{type} ) {
                    push @meta_elements, $name;
                }
                elsif ( 'vblob' eq $metacolumn->{type} ) {
                    push @meta_blobs, $name;
                }
                else {
                    $xml .= " $name='"
                        . MT::Util::encode_xml( $obj->$name, 1 ) . "'";
                }
            }
        }
    }
    $xml .= '>';
    $xml .= "<$_>" . MT::Util::encode_xml( $obj->column($_), 1 ) . "</$_>"
        foreach @elements;
    require MIME::Base64;
    foreach my $blob_col (@blobs) {
        my $val = $obj->column($blob_col);
        if ( substr( $val, 0, 4 ) eq 'SERG' ) {
            $xml
                .= "<$blob_col>"
                . MIME::Base64::encode_base64( $val, '' )
                . "</$blob_col>";
        }
        else {
            $xml .= "<$blob_col>"
                . MIME::Base64::encode_base64(
                Encode::encode( MT->config->PublishCharset, $val ), '' )
                . "</$blob_col>";
        }
    }
    foreach my $meta_col (@meta) {
        my $hashref = $obj->$meta_col;
        $xml .= "<$meta_col>"
            . MIME::Base64::encode_base64(
            MT::Serialize->serialize( \$hashref ), '' )
            . "</$meta_col>";
    }
    $xml .= "<$_>" . MT::Util::encode_xml( $obj->$_, 1 ) . "</$_>"
        foreach @meta_elements;
    foreach my $vblob_col (@meta_blobs) {
        my $vblob = $obj->$vblob_col;
        $xml .= "<$vblob_col>"
            . MIME::Base64::encode_base64(
            MT::Serialize->serialize( \$vblob ), '' )
            . "</$vblob_col>";
    }
    $xml .= '</' . $elem . '>';
    $xml;
}

1;
