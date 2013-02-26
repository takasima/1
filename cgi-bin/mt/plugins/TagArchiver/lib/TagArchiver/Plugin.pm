package TagArchiver::Plugin;

use File::Basename qw( dirname );
use strict;

sub _init_request {
    my $app = MT->instance();
    return unless ( ref $app eq 'MT::App::CMS' );
    return unless $app->blog;
    if ( ( $app->blog->has_column( 'class' ) ) && ( $app->blog->class eq 'website' ) ) {
        if ( $app->mode eq 'rebuild' ) {
            require MT::Request;
            my $r = MT::Request->instance;
            my $rebuild_tag = $r->cache( 'rebuild_tag' );
            return if $rebuild_tag;
            my $at = $app->param( 'type' );
            my $next = $app->param( 'next' );
            if ( ( $at =~ /,{0,1}Tag,{0,1}/ ) && ( $next eq '0' ) ) {
                require MT::Tag; require MT::ObjectTag;
                my @tags = MT::Tag->load( { is_private => 0 },
                 { join => MT::ObjectTag->join_on( 'tag_id',
                 { blog_id => $app->blog->id, object_datasource => 'entry', }, { unique => 1, } ) } );
                if ( scalar @tags ) {
                   _rebuild_tag_archives( $app->blog, \@tags );
                   $r->cache( 'rebuild_tag', 1 );
                }
            }
        }
    }
}

sub _pre_run {
    my $app = MT->instance;
    return unless ( ref $app eq 'MT::App::CMS' );
    if ( ( $app->mode eq 'delete' ) || ( $app->mode eq 'itemset_action' ) ) {
        my $type = $app->param( '_type' ) || '';
        if ( ( $type eq 'entry' ) || ( $type eq 'page' ) ) {
            require MT::Request;
            my $r = MT::Request->instance;
            if ( my $action_name = $app->param( 'action_name' ) ) {
                if ( ( $action_name eq 'remove_tags' ) || ( $action_name eq 'add_tags' ) ) {
                    my $tags      = $app->param( 'itemset_action_input' );
                    my $tag_delim = chr( $app->user->entry_prefs->{ tag_delim } );
                    require MT::Tag;
                    my @tags = MT::Tag->split( $tag_delim, $tags );
                    my @tag_obj;
                    my @blogs;
                    my @blog_ids;
                    for my $tag_name ( @tags ) {
                        my $tag = MT::Tag->load( { name => $tag_name },
                            { binary => { name => 1 } } );
                        if ( $tag ) {
                            push ( @tag_obj, $tag );
                        } else {
                            if ( $action_name eq 'add_tags' ) {
                                $tag = new MT::Tag;
                                $tag->name( $tag_name );
                                $tag->save or next;
                                push ( @tag_obj, $tag );
                            }
                        }
                    }
                    $r->cache( 'post_run_rebuild_tags', \@tag_obj );
                    if ( @tag_obj ) {
                        my @ids = $app->param( 'id' );
                        if ( ( $app->blog ) && $app->blog->is_blog ) {
                            push ( @blogs, $app->blog );
                            push ( @blog_ids, $app->blog->id );
                        } else {
                            for my $id ( @ids ) {
                                my $obj = MT->model( $type )->load( $id );
                                next unless defined $obj;
                                my $bid = $obj->blog_id;
                                if (! grep( /^$bid$/, @blog_ids ) ) {
                                    push ( @blog_ids, $obj->blog->id );
                                    push ( @blogs, $obj->blog );
                                }
                            }
                        }
                        $r->cache( 'post_run_rebuild_tags_blogs', \@blogs );
                    }
                }
                if ( $action_name eq 'delete' ) {
                    my @ids = $app->param( 'id' );
                    for my $id ( @ids ) {
                        my $self = $r->cache( 'pre_delete_entry_original:' . $id );
                        return if $self;
                        $r->cache( 'pre_delete_entry_original:' . $id, 1 );
                        my $obj = MT->model( $type )->load( $id );
                        next unless defined $obj;
                        my $original = $obj->clone_all;
                        my $tags = $obj->get_tag_objects;
                        if ( defined $tags ) {
                            $r->cache( 'delete_entry_tags:' . $obj->id, $tags );
                        }
                    }
                }
            }
        }
    }
}

sub _post_run {
    require MT::Request;
    my $r = MT::Request->instance;
    if ( my $tags = $r->cache( 'post_run_rebuild_tags' ) ) {
        if ( my $blogs = $r->cache( 'post_run_rebuild_tags_blogs' ) ) {
            for my $blog ( @$blogs ) {
                _rebuild_tag_archives( $blog, $tags );
            }
        }
    }
    return 1;
}

sub _cms_pre_preview {
    my ( $cb, $app, $preview_tmpl, $data ) = @_;
    if ( my $id = $preview_tmpl->id ) {
        my $ctx = $preview_tmpl->context;
        my $at = $ctx->{ current_archive_type };
        if ( $at && ( $at eq 'Tag' ) ) {
            require MT::TemplateMap;
            my $map = MT::TemplateMap->load( { template_id => $id, is_preferred => 1 } );
            if ( $map && ( $map->archive_type eq 'Tag' ) ) {
                require MT::Tag;
                my $blog_id = $app->blog->id;
                require MT::ObjectTag;
                my $tag = MT::Tag->load( { is_private => 0 },
                                    { limit => 1,
                                      join => MT::ObjectTag->join_on( 'tag_id',
                                    { blog_id => $blog_id, object_datasource => 'entry', },
                                    { unique => 1, } ) } );
                if (! defined $tag ) {
                    $tag = MT::Tag->new;
                    $tag->id( 0 );
                    $tag->name( $app->translate( 'Tag' ) );
                    $tag->n8d_id( 0 );
                    $tag->is_private( 0 );
                }
                $ctx->{ __stash }{ 'tag' } = $tag;
                $ctx->stash( 'tag', $tag );
                $ctx->stash( 'Tag', $tag );
            }
        }
    }
}

sub _edit_template_param {
    my ( $cb, $app, $param ) = @_;
    if ( $app->blog ) {
        if ( $app->blog->class eq 'website' ) {
            if ( $app->param( 'id' ) ) {
                if ( $param->{ type } eq 'page' ) {
                    push( @{ $param->{ 'archive_types' } }, {
                        'archive_type' => 'Tag',
                        'archive_type_translated' => MT->translate( 'Tag' ),
                    } );
                }
            }
        }
    }
}

sub _post_save_file_info {
    my ( $cb, $obj, $original ) = @_;
    if ( ( $obj->archive_type eq 'Tag' ) &&
        (! $obj->tag_id ) ) {
        $obj->remove or die $obj->errstr;
    }
}

sub _tag_context {
    my ( $ctx, $args, $cond ) = @_;
    my $app = MT->instance();
    my $tag = $ctx->stash( 'Tag' );
    my $tag_id = $ctx->{__stash}{ vars }{ 'tag_id' };
    if ( ( $tag_id ) && ( $tag ) ) {
        $tag = MT::Tag->load( $tag_id );
    }
    if ( ( ref $app eq 'MT::App::CMS' ) && ( $app->mode eq 'preview_template' ) ) {
        $tag = MT::Tag->load( { name => { not_like => '@%' } },
                              { limit => 1, direction => 'descend' } );
        if ( $tag ) {
            my $tid = $tag->id;
            my $orig_tag = MT::Tag->load( { n8d_id => $tid } );
            if ( defined $orig_tag ) {
                $tag = $orig_tag;
            }
            $ctx->var( 'tag_id', $tag->id );
            $ctx->var( 'tag_name', $tag->name );
            $ctx->{__stash}{ 'blog' } = $app->blog;
            $ctx->{__stash}{ 'blog_id' } = $app->blog->id;
            $ctx->{ current_timestamp }     = '18000101000000';
            $ctx->{ current_timestamp_end } = '29991231235959';
        }
    }
    $ctx->{__stash}{ 'Tag' } = $tag if $tag;
    $ctx->stash( 'builder' )->build( $ctx, $ctx->stash( 'tokens' ), $cond );
}

sub _build_file_filter {
    my ( $eh, %args ) = @_;
    my $at  = $args{ 'ArchiveType' };
    my $ctx  = $args{ 'Context' };
    if ( $at eq 'Tag' ) {
        if (! $ctx->stash( 'Tag' ) ) {
            return 0;
        }
    }
    return 1;
}

sub _post_save_entry {
    my ( $cb, $app, $obj, $original ) = @_;
    return 1 if ( $obj->id < 0 );
    my $change;
    my $orig_tags;
    if ( defined $original ) {
        $orig_tags = $original->get_tag_objects;
        if ( $original->status != $obj->status ) {
            $change = 1;
        }
    }
    if ( $obj->status == MT::Entry::RELEASE() ) {
        $change = 1;
    }
    return unless $change;
    my $tags = $obj->get_tag_objects;
    push ( @$tags, @$orig_tags ) if $orig_tags;
    if ( defined $tags ) {
        $obj->save or die $obj->errstr;
        _rebuild_tag_archives( $app->blog, \@$tags, $obj );
    }
}

sub _post_recover_entry {
    my ( $cb, $app, $obj, $original, $revision ) = @_;
    return if ( $obj->status != MT::Entry::RELEASE() );
    my $orig_tags;
    if ( defined $original ) {
        $orig_tags = $original->get_tag_objects;
    }
    my $tags = $obj->get_tag_objects;
    push ( @$tags, @$orig_tags ) if $orig_tags;
    if ( defined $tags ) {
        _rebuild_tag_archives( $obj->blog, \@$tags, $obj );
    }
}

sub _post_save_tag {
    my ( $cb, $tag, $obj ) = @_;
    my $app = MT->instance;
    if ( ref $app eq 'MT::App::CMS' ) {
        if ( my $blog = $app->blog ) {
            my @tags;
            push ( @tags, $obj );
            _rebuild_tag_archives( $blog, \@tags, $obj );
        }
    }
}

sub _post_recover_page {
    my ( $cb, $app, $obj, $original, $revision ) = @_;
    return if ( $obj->status != MT::Entry::RELEASE() );
    my $orig_tags;
    if ( defined $original ) {
        $orig_tags = $original->get_tag_objects;
    }
    my $tags = $obj->get_tag_objects;
    push ( @$tags, @$orig_tags ) if $orig_tags;
    if ( defined $tags ) {
        _rebuild_tag_archives( $obj->blog, \@$tags, $obj );
    }
}

sub _post_published_entry {
    my ( $cb, $app, $obj ) = @_;
    return 1 if ( $obj->id < 0 );
    my $tags = $obj->get_tag_objects;
    if ( defined $tags ) {
        _rebuild_tag_archives( $obj->blog, \@$tags, $obj );
    }
    return 1;
}

sub _pre_delete_entry {
    my ( $cb, $app, $obj ) = @_;
    if ( $obj->status != MT::Entry::RELEASE() ) {
        return 1;
    }
    my $tags = $obj->get_tag_objects;
    if ( defined $tags ) {
        require MT::Request;
        my $r = MT::Request->instance();
        $r->cache( 'delete_entry_tags:' . $obj->id, $tags );
    }
    return 1;
}

sub _pre_delete_page {
    my ( $cb, $app, $obj ) = @_;
    return 1 if ( $obj->id < 0 );
    if ( $obj->status != MT::Entry::RELEASE() ) {
        return 1;
    }
    my $tags = $obj->get_tag_objects;
    if ( defined $tags ) {
        require MT::Request;
        my $r = MT::Request->instance();
        $r->cache( 'delete_entry_tags:' . $obj->id, $tags );
    }
    return 1;
}

sub _post_delete_entry {
    my ( $cb, $app, $obj, $original ) = @_;
    return 1 if ( $obj->id < 0 );
    require MT::Request;
    my $r = MT::Request->instance();
    if ( my $tags = $r->cache( 'delete_entry_tags:' . $obj->id ) ) {
        _rebuild_tag_archives( $app->blog, \@$tags, $obj );
    }
}

sub _post_save_page {
    my ( $cb, $app, $obj, $original ) = @_;
    return 1 if ( $obj->id < 0 );
    my $change;
    my $orig_tags;
    if ( defined $original ) {
        $orig_tags = $original->get_tag_objects;
        if ( $original->status != $obj->status ) {
            $change = 1;
        }
    }
    if ( $obj->status == MT::Entry::RELEASE() ) {
        $change = 1;
    }
    return unless $change;
    my $tags = $obj->get_tag_objects;
    push ( @$tags, @$orig_tags ) if $orig_tags;
    if ( defined $tags ) {
        $obj->save or die $obj->errstr;
        _rebuild_tag_archives( $app->blog, \@$tags, $obj );
    }
}

sub _rebuild_tag_archives {
    my ( $blog, $tags, $entry ) = @_;
    my $app = MT->instance();
    my $site_path = _site_path( $blog );
    require MT::TemplateMap;
    require MT::Template;
    require MT::Tag;
    require MT::ObjectTag;
    require MT::Entry;
    require MT::FileInfo;
    require File::Spec;
    my @maps = MT::TemplateMap->load( { blog_id => $blog->id, archive_type => 'Tag' } );
    return unless scalar @maps;
    my @templates;
    for my $map ( @maps ) {
        my $template = MT::Template->load( $map->template_id );
        push ( @templates, $template );
    }
    my $fmgr = $blog->file_mgr;
    require MT::Request;
    my $r = MT::Request->instance();
    for my $t ( @$tags ) {
        my $tid = $t->id;
        if ( MT::Tag->exist( { n8d_id => $tid } ) ) {
            next;
        }
        if (! $entry ) {
            next if $r->cache( 'build_tag_archive:' . $tid );
            $r->cache( 'build_tag_archive:' . $tid, 1 );
        } else {
            my $entry_id = $entry->id;
            next if $r->cache( 'build_tag_archive_by_entry:' . $entry_id . ':' . $tid );
            $r->cache( 'build_tag_archive_by_entry:' . $entry_id . ':' . $tid, 1 );
        }
        my $count = MT::Entry->count( { blog_id => $blog->id, class => '*', status => MT::Entry::RELEASE() },
                                        {
                                            join => [
                                                'MT::ObjectTag', 'object_id',
                                                { tag_id => $tid,
                                                  object_datasource => 'entry' },
                                            ],
                                        }
                                    );
        if (! $count ) {
            my @finfos = MT::FileInfo->load( { archive_type => 'Tag', tag_id => $tid } );
            for my $finfo ( @finfos ) {
                my $file = $finfo->file_path;
                if ( $fmgr->exists( $file ) ) {
                    $fmgr->delete( $file );
                }
                $finfo->remove or die $finfo->finfo;
            }
            next;
        }
        my $i = 0;
        for my $map ( @maps ) {
            my $file_template = $map->file_template;
            my $publish_path = _build_tmpl( $app, $file_template, $blog, $t );
            my $file = File::Spec->catfile( $site_path, $publish_path );
            my $template = $templates[$i];
            my $build = _build_tmpl( $app, $template->text, $blog, $t,
                                        'Tag', $file, $map, $template );
            $i++;
        }
    }
}

sub _post_delete_tag {
    my ( $cb, $app, $obj, $original ) = @_;
    my $blog = $app->blog;
    return 1 unless defined $blog;
    my $blog_id = $blog->id;
    my $site_path = _site_path ( $blog );
    require MT::TemplateMap;
    require MT::FileInfo;
    require File::Spec;
    my @maps = MT::TemplateMap->load( { blog_id => $blog->id, archive_type => 'Tag' } );
    return 1 unless scalar @maps;
    my $fmgr = $blog->file_mgr;
    for my $map ( @maps ) {
        my $file_template = $map->file_template;
        my $publish_path = _build_tmpl( $app, $file_template, $blog, $obj );
        my $file = File::Spec->catfile( $site_path, $publish_path );
        # if ( $fmgr->exists( $file ) ) {
        my $finfo = MT::FileInfo->get_by_key( { file_path => $file,
                                                blog_id => $blog->id,
                                                templatemap_id => $map->id,
                                                tag_id => $obj->id,
                                                archive_type => 'Tag',
                                                } );
        if ( $finfo->id ) {
            $finfo->remove or die $finfo->errstr;
        }
        if ( $fmgr->exists( $file ) ) {
            $fmgr->delete( $file );
        }
        # }
    }
    return 1;
}

sub _pre_delete_tag {
    _post_delete_tag( @_ );
}

sub _object_tag_remove {
    my ( $cb, $obj ) = @_;
    my $app = MT->instance();
    return unless ( ref $app eq 'MT::App::CMS' );
    return unless $obj->object_datasource eq 'entry';
    require MT::ObjectTag;
    require MT::Tag;
    my $count = MT::ObjectTag->count( { object_datasource => 'entry', tag_id => $obj->tag_id } );
    unless ( $count ) {
        my $tag = MT::Tag->load( $obj->tag_id );
        _post_delete_tag( $cb, $app, $tag, $tag );
    }
}

sub _build_tmpl {
    my ( $app, $template, $blog, $tag,
         $at, $file, $map, $tmpl ) = @_;
    require MT::Template::Context;
    require MT::FileInfo;
    my $ctx = MT::Template::Context->new;
    $ctx->stash( 'blog', $blog );
    $ctx->stash( 'blog_id', $blog->id );
    $ctx->stash( 'Tag', $tag ) if $tag;
    $ctx->stash( 'tag', $tag ) if $tag;
    my $orig_tag;
    if ( $tag ) {
        unless ( $file ) {
            my $tag_id = $tag->id;
            $template =~ s/<MT:*TagID>/$tag_id/i;
        }
    }
    $ctx->var( 'tag_id', $tag->id ) if $tag;
    $ctx->var( 'tag_name', $tag->name ) if $tag;
    $ctx->stash( 'blog_id', $blog->id );
    $ctx->stash( 'local_blog_id', $blog->id );
    my $finfo = MT::FileInfo->new;
    if ( $file ) {
        $finfo = MT::FileInfo->get_by_key( { file_path => $file, blog_id => $blog->id, } );
        $finfo->url( path2url( $file, $blog ) );
        $finfo->archive_type( $at );
        $finfo->template_id( $tmpl->id );
        $finfo->author_id( undef );
        $finfo->templatemap_id( $map->id );
        if ( $tag ) {
            $finfo->tag_id( $tag->id );
        } else {
            $finfo->tag_id( undef );
        }
        # $finfo->save or die $finfo->errstr;
        if ( $map && $map->build_type == 3 ) {
            if (! $finfo->virtual ) {
                $finfo->virtual( 1 );
            }
        }
        $finfo->save or die $finfo->errstr;
        if ( $map && $map->build_type == 3 ) {
            MT->run_callbacks(
                'build_dynamic',
                Context      => $ctx,
                context      => $ctx,
                ArchiveType  => $at,
                archive_type => $at,
                TemplateMap  => $map,
                template_map => $map,
                Blog         => $blog,
                blog         => $blog,
                # Entry        => $entry,
                # entry        => $entry,
                FileInfo     => $finfo,
                file_info    => $finfo,
                File         => $file,
                file         => $file,
                Template     => $tmpl,
                template     => $tmpl,
                Tag          => $tag,
                tag          => $tag,
                # PeriodStart  => $start,
                # period_start => $start,
                # Category     => $category,
                # category     => $category,
                force        => 0
            );
            rename( $file, $file . ".static" ) if (-f $file );
            return;
        }
        my $filter = MT->run_callbacks(
            'build_file_filter',
            Context      => $ctx,
            context      => $ctx,
            ArchiveType  => $at,
            archive_type => $at,
            TemplateMap  => $map,
            template_map => $map,
            Blog         => $blog,
            blog         => $blog,
            # Entry        => $entry,
            # entry        => $entry,
            FileInfo     => $finfo,
            file_info    => $finfo,
            File         => $file,
            file         => $file,
            Template     => $tmpl,
            template     => $tmpl,
            # PeriodStart  => $start,
            # period_start => $start,
            # Category     => $category,
            # category     => $category,
            force        => 0
        );
        return 0 unless $filter;
    }
    require MT::Builder;
    my $build = MT::Builder->new;
    my $tokens = $build->compile( $ctx, $template )
        or return $app->error( $app->translate(
            "Parse error: [_1]", $build->errstr) );
    defined( my $html = $build->build( $ctx, $tokens ) )
        or return $app->error( $app->translate(
            "Build error: [_1]", $build->errstr ) );
    return $html unless $file;
    if ( $file ) {
        MT->run_callbacks(
            'build_page',
            Context      => $ctx,
            context      => $ctx,
            ArchiveType  => $at,
            archive_type => $at,
            TemplateMap  => $map,
            template_map => $map,
            Blog         => $blog,
            blog         => $blog,
            # Entry        => $entry,
            # entry        => $entry,
            FileInfo     => $finfo,
            file_info    => $finfo,
            # PeriodStart  => $start,
            # period_start => $start,
            # Category     => $category,
            # category     => $category,
            RawContent   => \$html,
            raw_content  => \$html,
            Content      => \$html,
            content      => \$html,
            BuildResult  => \$html,
            build_result => \$html,
            Template     => $tmpl,
            template     => $tmpl,
            File         => $file,
            file         => $file
        );
        require File::Basename;
        my $dir = File::Basename::dirname( $file );
        my $fmgr = $blog->file_mgr;
        $dir =~ s!/$!! unless $dir eq '/';
        unless ( $fmgr->exists( $dir ) ) {
            $fmgr->mkpath( $dir );
        }
        unless ( $fmgr->content_is_updated( $file, \$html ) ) {
            return 1;
        }
        my $temp_file = "$file.new";
        $fmgr->put_data( $html, $temp_file );
        $fmgr->rename( $temp_file, $file );
        MT->run_callbacks(
            'build_file',
            Context      => $ctx,
            context      => $ctx,
            ArchiveType  => $at,
            archive_type => $at,
            TemplateMap  => $map,
            template_map => $map,
            Blog         => $blog,
            blog         => $blog,
            # Entry        => $entry,
            # entry        => $entry,
            FileInfo     => $finfo,
            file_info    => $finfo,
            # PeriodStart  => $start,
            # period_start => $start,
            # Category     => $category,
            # category     => $category,
            RawContent   => \$html,
            raw_content  => \$html,
            Content      => \$html,
            content      => \$html,
            BuildResult  => \$html,
            build_result => \$html,
            Template     => $tmpl,
            template     => $tmpl,
            File         => $file,
            file         => $file
        );
        return 1;
    }
}

sub _site_path {
    my $blog = shift;
    my $site_path = $blog->archive_path;
    $site_path = $blog->site_path unless $site_path;
    require File::Spec;
    my @path = File::Spec->splitdir( $site_path );
    $site_path = File::Spec->catdir( @path );
    return $site_path;
}

sub _site_url {
    my $blog = shift;
    my $site_url = $blog->site_url;
    if ( $site_url =~ /(.*)\/$/ ) {
        $site_url = $1;
    }
    return $site_url;
}

sub path2url {
    my ( $path, $blog ) = @_;
    my $site_path = quotemeta ( _site_path( $blog ) );
    my $site_url = _site_url( $blog );
    $path =~ s/^$site_path/$site_url/;
    $path =~ s!^https*://.*?/!/!;
    return $path;
}

sub _cb_restore {
    my $self = shift;
    my ( $all_objects, $callback, $errors ) = @_;

    my $error_object_count = 0;

    for my $key ( keys %$all_objects ) {
        if ( $key =~ /^MT::FileInfo#(\d+)$/ ) {
            my $fileinfo = $all_objects->{$key};
            if ( my $tag_id = $fileinfo->tag_id ) {
                my $new_tag = $all_objects->{ 'MT::Tag#' . $tag_id };
                if ( $new_tag ) {
                    $fileinfo->tag_id( $new_tag->id );
                } else {
                    $fileinfo->tag_id( undef );
                    $error_object_count = $error_object_count + 1;
                }
                $fileinfo->update();
            }
        }
    }
    if ( $error_object_count ) {
        push( @$errors,
            MT->translate( 'Some [_1] were not restored because their parent objects were not restored.', 'MT::FileInfo' ) );
    }
    
    1;
}

1;