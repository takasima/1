package ArchiveType::FolderCustomObject;

use strict;
use base qw( MT::ArchiveType );
use CustomObject::Util qw( site_url site_path build_tmpl path2url );

sub name {
    return 'FolderCustomObject';
}

sub archive_label {
    my $plugin = MT->component( 'CustomObject' );
    return $plugin->translate( 'Folder-Object' );
}

sub default_archive_templates {
    return [
        {   label    => 'folder_path/customobject/index.html',
            template => '%c/customobject/%i',
            default  => 1
        },
        {   label    => 'folder_path/index.html',
            template => '%c/%i',
        },
    ];
}

sub template_params {
    return {
        archive_class         => 'folder-customobject-archive',
        customobject_class    => 'customobject',
        folder_customobject_archive => 1,
        archive_template      => 1,
    };
}

sub rebuild_archive {
    my $app = MT->instance;
    my $blog = $app->blog;
    return unless $blog;
    my $blog_id = $blog->id;
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
    $type =~ s/^Folder//;
    my $model = $type;
    $type = lc ( $type );
    my $module = $model . '::' . $model;
    eval "require $module";
    if ( my $count = MT->model( 'folder' )->count( { blog_id => $blog_id } , {
                                                  'join' => [ $module, 'category_id',
                                                              { blog_id => $blog_id, status => 2, class => $type },
                                                              { unique => 1 } ] } ) ) {
        my $offset = $app->param( 'offset' );
        if (! $offset ) {
            $offset = 0;
        }
        my $limit = $app->param( 'limit' );
        if (! $limit ) {
            $limit = $app->config( 'FolderObjectPerRebuild' ) || 5;
        }
        my @objects = MT->model( 'folder' )->load( { blog_id => $blog_id }, {
                                                     offset => $offset,
                                                     limit => $limit,
                                                     sort => 'id',
                                                     direction => 'descend',
                                                    'join' => [ $module, 'category_id',
                                                              { blog_id => $blog_id, status => 2, class => $type },
                                                              { unique => 1 } ] } );
        if ( @objects ) {
            if (! rebuild_folder( $app, $blog, $at, \@objects ) ) {
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

sub rebuild_folder {
    my ( $app, $blog, $at, $object, %param ) = @_;
    my $folders;
    if ( ref $object ne 'ARRAY' ) {
        push ( @$folders, $object );
    } else {
        $folders = $object;
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
    for my $obj ( @$folders ) {
        my $oid = $obj->id;
        unless ( $param{ Force } ) {
            next if $r->cache( 'build_folder_customobject_archive:' . $oid );
            $r->cache( 'build_folder_customobject_archive:' . $oid, 1 );
        }
        my $i = 0;
        for my $map ( @maps ) {
            my $at_lc = lc( $at );
            my $file_template = $map->file_template || '%c/%i';
            my $ctx = MT::Template::Context->new;
            $ctx->stash( 'blog', $blog );
            $ctx->stash( 'blog_id', $blog->id );
            $ctx->stash( 'category', $obj );
            my $publish_path = get_publish_path( $ctx, $file_template );
            $ctx = MT::Template::Context->new;
            $ctx->stash( 'blog', $blog );
            $ctx->stash( 'blog_id', $blog->id );
            $ctx->stash( 'category', $obj );
            my $template = $templates[$i];
            require ArchiveType::CustomObject;
            my $build = ArchiveType::CustomObject::rebuild_template( $ctx, $map, $template, $publish_path, 'Category' );
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
    my $category = $ctx->stash( 'category' );
    my %f = (
        'b'  => "<MTFolderBasename>",
        '-b' => "<MTFolderBasename separator='-'>",
        '_b' => "<MTFolderBasename separator='_'>",
        'f'  => "<MTFolderBasename>",
        '-f' => "<MTFolderBasename separator='-'>",
        'c'  => "<MTSubCategoryPath>",
        '-c' => "<MTSubCategoryPath separator='-'>",
        '_c' => "<MTSubCategoryPath separator='_'>",
        'C'  => "<MTCategoryBasename>",
        '-C' => "<MTCategoryBasename separator='-'>",
        'i'  => '<MTIndexBasename extension="1">',
        'I'  => "<MTIndexBasename>",
    );
    my $file_extension;
    my %args = ( ctx => $ctx, category => $category );
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
    }
    return $file;
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