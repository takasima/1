package ArchiveType::CustomObject;

use strict;
use base qw( MT::ArchiveType );
use CustomObject::Util qw( site_url site_path build_tmpl path2url );

sub name {
    return 'CustomObject';
}

sub archive_label {
    my $plugin = MT->component( 'CustomObject' );
    return $plugin->translate( 'CustomObject' );
}

sub default_archive_templates {
    return [
        {   label    => 'folder_path/customobject/customobject_basename.html',
            template => '%c/customobject/%f',
            default  => 1
        },
        {   label    => 'customobject/customobject_basename.html',
            template => 'customobject/%f',
        },
    ];
}

sub template_params {
    return {
        archive_class         => 'customobject-archive',
        customobject_class    => 'customobject',
        customobject_archive  => 1,
        archive_template      => 1,
    };
}

sub rebuild_archive {
    my $app = MT->instance;
    my $blog = $app->blog;
    return unless $blog;
    my $perms = $app->permissions
        or return $app->error( $app->translate( 'No permissions' ) );
    return $app->permission_denied()
                unless $perms->can_do( 'rebuild' );
    my $custom_objects = MT->registry( 'custom_objects' );
    my @objects = keys( %$custom_objects );
    my $type = $app->param( 'type' );
    my $next = $app->param( 'next' );
    my @order = split( /,/, $type );
    $type = $order[ $next ];
    my $at = $type;
    $type = lc ( $type );
    if ( my $count = MT->model( $type )->count( { blog_id => $blog->id, status => 2, class => $type } ) ) {
        my $offset = $app->param( 'offset' );
        if (! $offset ) {
            $offset = 0;
        }
        my $limit = $app->param( 'limit' );
        if (! $limit ) {
            $limit = $app->config( 'CustomObjectPerRebuild' ) || 40;
        }
        my @objects = MT->model( $type )->load( { blog_id => $blog->id,
                                                  status => 2,
                                                  class => $type },
                                                { offset => $offset,
                                                  limit => $limit,
                                                  sort => 'id',
                                                  direction => 'descend', } );
        if ( @objects ) {
            if (! rebuild_customobject( $app, $blog, $at, \@objects ) ) {
                my $plugin = MT->component( 'CustomObject' );
                die $plugin->translate( 'An error occurred publishing archive \'[_1]\'.', $type );
            }
        } else {
            return;
        }
        my $next_offset = $offset + $limit;
        if ( $next_offset < $count ) {
            my $query = $app->query_string;
            my @params = split( /;/, $query );
            my $next_args;
            for my $param ( @params ) {
                my @args = split( /=/, $param );
                if ( $args[0] ne '__mode' ) {
                    if ( ( $args[0] ne 'limit' ) && ( $args[0] ne 'offset' ) ) {
                        if ( defined $args[1] ) {
                            $next_args->{ $args[0] } = MT::Util::decode_url( $args[1] );
                        }
                    }
                }
            }
            $next_args->{ limit } = $limit;
            $next_args->{ offset } = $next_offset;
            my $query_str = $app->uri( mode => 'rebuild',
                                       args => $next_args );
            $app->redirect( $app->base . $query_str );
        }
    }
    return '';
}

sub rebuild_customobject {
    my ( $app, $blog, $at, $object ) = @_;
    my $custom_objects;
    if ( ref $object ne 'ARRAY' ) {
        push ( @$custom_objects, $object );
    } else {
        $custom_objects = $object;
    }
    require MT::TemplateMap;
    require MT::Template;
    require MT::FileInfo;
    require File::Spec;
    my @maps = MT::TemplateMap->load( { blog_id => $blog->id, archive_type => $at } );
    return unless scalar @maps;
    my @templates;
    for my $map ( @maps ) {
        my $template = MT::Template->load( $map->template_id );
        push ( @templates, $template );
    }
    my $fmgr = $blog->file_mgr;
    require MT::Request;
    my $r = MT::Request->instance();
    require MT::Template::Context;
    for my $obj ( @$custom_objects ) {
        my $oid = $obj->id;
        next if $r->cache( 'build_customobject_archive:' . $oid );
        $r->cache( 'build_customobject_archive:' . $oid, 1 );
        if ( $obj->status != 2 ) {
            my @finfos = MT::FileInfo->load( { archive_type => $at, customobject_id => $oid } );
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
            my $at_lc = lc( $at );
            my $file_template = $map->file_template || $at_lc . '/%f';
            my $ctx = MT::Template::Context->new;
            $ctx->stash( 'blog', $blog );
            $ctx->stash( 'blog_id', $blog->id );
            $ctx->stash( 'customobject', $obj );
            my $publish_path = get_publish_path( $ctx, $file_template );
            $ctx = MT::Template::Context->new;
            $ctx->stash( 'blog', $blog );
            $ctx->stash( 'blog_id', $blog->id );
            $ctx->stash( 'customobject', $obj );
            my $template = $templates[$i];
            my $build = rebuild_template( $ctx, $map, $template, $publish_path, 'CustomObject' );
            $i++;
        }
    }
    return 1;
}

sub get_publish_path {
    my ( $ctx, $file_template, $url_or_path ) = @_;
    $url_or_path = 'path' unless $url_or_path;
    my $blog = $ctx->stash( 'blog' );
    my $site_path;
    if ( $url_or_path eq 'path' ) {
        $site_path = site_path( $blog );
    } else {
        $site_path = site_url( $blog );
    }
    my %f = (
        'b'  => "<MTCustomObjectBasename>",
        '-b' => "<MTCustomObjectBasename separator='-'>",
        '_b' => "<MTCustomObjectBasename separator='_'>",
        'd'  => "<CustomObjectAuthoredOn format='%d'>",
        'D'  => "<CustomObjectAuthoredOn format='%e' trim='1'>",
        'f'  => "<MTCustomObjectBasename>",
        '-f' => "<MTCustomObjectBasename separator='-'>",
        'c'  => "<MTCustomObjectFolder><MTSubCategoryPath></MTCustomObjectFolder>",
        '-c' => "<MTCustomObjectFolder><MTSubCategoryPath separator='-'></MTCustomObjectFolder>",
        '_c' => "<MTCustomObjectFolder><MTSubCategoryPath separator='_'></MTCustomObjectFolder>",
        'C'  => "<MTCustomObjectFolder><MTCategoryBasename></MTCustomObjectFolder>",
        '-C' => "<MTCustomObjectFolder><MTCategoryBasename separator='-'></MTCustomObjectFolder>",
        'i'  => '<MTIndexBasename extension="1">',
        'I'  => "<MTIndexBasename>",
    );
    my $file_extension;
    my %args = ( ctx => $ctx );
    $file_template =~ s!%([_-]?[A-Za-z])!$f{$1}!g;
    if ( $file_template =~ />$/ ) {
        $file_extension = 1;
    }
    my $file = build_tmpl( MT->instance, $file_template, \%args );
    $file =~ s!/{2,}!/!g;
    $file =~ s!(^/|/$)!!g;
    if ( $file_extension ) {
        my $ext = $blog->file_extension;
        if ( $file !~ /\.$ext$/ ) {
            $file .= '.' . $ext if $ext;
        }
    }
    $file =~ s/\-+/-/g;
    if ( $url_or_path eq 'path' ) {
        require File::Spec;
        $file = File::Spec->catfile( $site_path, $file );
    } else {
        if ( $file !~ m!^/! ) {
            $file = '/' . $file;
        }
        $file = $site_path . $file;
        if ( $^O eq 'MSWin32' ) {
            $file =~ s/\\/\//g;
        }
    }
    return $file;
}

sub rebuild_template {
    my ( $ctx, $map, $template, $publish_path, $cb ) = @_;
    my $lc_cb = lc( $cb );
    my $id_key = $lc_cb . '_id';
    my $obj = $ctx->stash( $lc_cb );
    # my $blog = $obj->blog;
    require MT::Blog;
    my $blog = MT::Blog->load( $obj->blog_id );
    $ctx->stash( 'blog', $blog );
    require MT::FileInfo;
    my $at = $map->archive_type;
    my $finfo = MT::FileInfo->get_by_key( { archive_type => $map->archive_type,
                                            $id_key => $obj->id,
                                            templatemap_id => $map->id,
                                            template_id => $template->id,
                                            blog_id => $blog->id,
                                            } );
    my $changed;
    if (! $finfo->id ) {
        $changed = 1;
    }
    if (! $map->build_type ) {
        if ( my $file = $finfo->file_path ) {
            my $fmgr = $blog->file_mgr;
            if ( $fmgr->exists( $file ) ) {
                $fmgr->delete( $file );
            }
        }
        return;
    }
    if ( (! $finfo->file_path ) || ( $finfo->file_path ne $publish_path ) ) {
        if ( my $file = $finfo->file_path ) {
            if ( $map->build_type != 3 ) {
                my $other = MT::FileInfo->exist( { id => { not => $finfo->id }, file_path => $file } );
                if (! $other ) {
                    my $fmgr = $blog->file_mgr;
                    if ( $fmgr->exists( $file ) ) {
                        $fmgr->delete( $file );
                    }
                }
            }
        }
        $finfo->file_path( $publish_path );
        my $publish_url = path2url( $publish_path, $blog );
        $publish_url =~ s!^https{0,1}://.*?/!/!;
        $finfo->url( $publish_url );
        $changed = 1;
    }
    my $app = MT->instance;
    my $params;
    my $module = 'ArchiveType::' . $at;
    eval "require $module";
    my $get_param = '$params = ' . $module . '::template_params();';
    eval $get_param;
    my %args = (
        ctx => $ctx,
        blog => $blog,
    );
    if ( $cb eq 'Category' ) {
        $args{ category } = $obj;
    }
    if ( $map->build_type == 3 ) {
        if (! $finfo->virtual ) {
            $finfo->virtual( 1 );
            $changed = 1;
        }
        if ( $changed ) {
            $finfo->save or die $finfo->errstr;
        }
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
            FileInfo     => $finfo,
            file_info    => $finfo,
            File         => $publish_path,
            file         => $publish_path,
            Template     => $template,
            template     => $template,
            $cb          => $obj,
            $lc_cb       => $obj,
            force        => 0
        );
        rename( $publish_path, $publish_path . ".static" ) if (-f $publish_path );
        return;
    }
    if ( $changed ) {
        $finfo->save or die $finfo->errstr;
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
        FileInfo     => $finfo,
        file_info    => $finfo,
        File         => $publish_path,
        file         => $publish_path,
        Template     => $template,
        template     => $template,
        $cb          => $obj,
        $lc_cb       => $obj,
        force        => 0
    );
    return 0 unless $filter;
    my $html = build_tmpl( $app, $template, \%args, $params );
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
        FileInfo     => $finfo,
        file_info    => $finfo,
        File         => $publish_path,
        file         => $publish_path,
        Template     => $template,
        template     => $template,
        $cb          => $obj,
        $lc_cb       => $obj,
        RawContent   => \$html,
        raw_content  => \$html,
        Content      => \$html,
        content      => \$html,
        BuildResult  => \$html,
        build_result => \$html,
    );
    my $file = $publish_path;
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
        FileInfo     => $finfo,
        file_info    => $finfo,
        File         => $publish_path,
        file         => $publish_path,
        Template     => $template,
        template     => $template,
        $cb          => $obj,
        $lc_cb       => $obj,
        RawContent   => \$html,
        raw_content  => \$html,
        Content      => \$html,
        content      => \$html,
        BuildResult  => \$html,
        build_result => \$html,
    );
    return 1;
}

sub archive_group_iter {}
sub archive_group_entries {}
sub archive_entries_count { return 0; }
sub entry_class {
    my $archiver = shift;
    my $app = MT->instance;
    if ( $app->can('mode') && $app->mode eq 'preview_template' &&
        $app->param( 'type' ) eq 'archive' ) {
        return 'entry';
    } else {
        return;
    }
}

1;