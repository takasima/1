package Pager::Plugin;
#use strict;

use Pager::Util qw( ceil site_path is_windows );

use File::Basename;
use File::Spec;
use MT::Template;
use MT::FileInfo;

sub _edit_template_param {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $plugin = MT->component( 'Pager' );
    my $type = $param->{ type };
    if ( ( $type eq 'archive' ) || ( $type eq 'index' ) ) {
        if ( my $pointer_field = $tmpl->getElementById( 'linked_file' ) ) {
            my $nodeset = $tmpl->createElement( 'app:setting', { id => 'pager',
                                                                 label => $plugin->translate( 'Pager' ),
                                                                 label_class => 'top-level',
                                                                 required => 0,
                                                               }
                                              );
            my $innerHTML = <<'MTML';
<__trans_section component="Pager">
<label>
    <input name="pager" id="pager" type="checkbox"<mt:if name="pager"> checked="checked"</mt:if> value="1" /> <__trans phrase="Split this archive">
    <input name="pager" type="hidden" value="0" />
</label>
</__trans_section>
MTML
            $nodeset->innerHTML( $innerHTML );
            $tmpl->insertAfter( $nodeset, $pointer_field );
        }
    }
}

sub _cb_post_delete_archive_file {
    my ( $cb, $file, $at, $entry ) = @_;
    my $orig_finfo = MT::FileInfo->load( { file_path => $file } )
        or return;
    my @finfos = MT::FileInfo->load( { original_id => $orig_finfo->id, } );
    for my $finfo ( @finfos ) {
        my $file_path = $finfo->file_path;
        if ( -f $file_path ) {
            if ( unlink $file_path ) {
                $finfo->remove;
            }
        }
    }
}

sub _cms_delete_permission_filter_template { # for index
    my ( $cb, $app, $obj ) = @_;
    if ( $obj->type eq 'index' ) {
        my @finfos = MT::FileInfo->load( { template_id => $obj->id, } );
        for my $finfo ( @finfos ) {
            my $file_path = $finfo->file_path;
            if ( -f $file_path ) {
                if ( unlink $file_path ) {
                    $finfo->remove;
                }
            }
        }
    }
    1;
}

sub _build_file_filter {
    my ( $eh, %args ) = @_;
    my $template = $args{ 'Template' };
    my $org_template = $args{ 'Template' };
    my $pager = $template->pager;
    my $tag = '';
    if ( $pager ) {
        my $app   = MT->instance();
        my $tmpl_id = $template->id;
        my $ctx   = $args{ 'Context' };
        my $file  = $args{ 'File' };
        my $blog  = $args{ 'Blog' };
        my $map   = $args{ 'TemplateMap' };
        my $at    = $args{ 'ArchiveType' };
        my $start = $args{ 'PeriodStart' };
        my $category = $args{ 'Category' };
        my $orig_finfo = $args{ 'FileInfo' };
        require MT::WeblogPublisher;
        my $mt = MT::WeblogPublisher->new;
        my $archiver = $mt->archiver( $at );
        if ( $at ne 'index' ) {
            if ( $archiver->group_based ) {
                require MT::Promise;
                my $entries = sub { $archiver->archive_group_entries( $ctx ) };
                $ctx->stash( 'entries', MT::Promise::delay( $entries ) );
            }
        }
        $ctx->stash( 'blog', $blog );
        my $arch_root = ( $at eq 'Page' ) ? $blog->site_path : $blog->archive_path;
        if ( is_windows() ) {
            if ( $arch_root !~ /(.*)\\$/ ) {
                $arch_root .= '\\';
            }
        } else {
            if ( $arch_root !~ /(.*)\/$/ ) {
                $arch_root .= '/';
            }
        }
        my $q_arch_root = quotemeta( $arch_root );
        my $build = MT::Builder->new;
        my $count;
        if ( $at ne 'index' ) {
            require Pager::Tags;
            $count = Pager::Tags::_hdlr_archive_count( $ctx );
        } else {
            $count = MT::Entry->count( { blog_id => $blog->id,
                                         status  => MT::Entry::RELEASE(),
                                       }
                                     );
            $ctx->stash( 'at_index', 1 );
        }
        $ctx->stash( 'total', $count );
        my $tmpl_src = $template->text;
        $tag = 'entry';
        my $limit;
        $limit = $1 if $tmpl_src =~ /<(?i:mt:?entries)(?=\s).*?\slimit\s*=\s*["']?([0-9]+)[^>]*>/s;
        return 1 unless $limit;
        my $repeat = 1;
        if ( $limit < $count ) {
            $repeat = $count / $limit if 0 < $limit;
            $repeat = ceil( $repeat );
        }
        $repeat--;
        if ( $repeat ) {
            my $fmgr = $blog->file_mgr;
            my $template = $template->clone();
            $template->pager( 0 );
            $args{ 'Template' } = $template;
            for ( 1 .. $repeat ) {
                if ( $app->run_callbacks( 'build_file_filter', %args ) ) {
                    $ctx->{ __stash }{ 'prev' } = 1;
                    if ( $_ != $repeat ) {
                        $ctx->{ __stash }{ 'next' } = 1;
                    } else {
                        $ctx->{ __stash }{ 'next' } = 0;
                    }
                    $ctx->{ __stash }{ 'pager' } = $_ + 1;
                    my $offset = $limit * $_;
                    my $new_file = $file;
                    my $prev_url = $file;
                    my $next_url = $file;
                    if ( $tag eq 'entry' ) {
#                        $tmpl_src =~ s/(<mt:*entries.*?offset=.*?)auto(.*?>)/$1$offset$2/gis;
                        $tmpl_src =~ s/(<(?i:mt:?entries)(?=\s).*?\soffset\s*=\s*["']?)[0-9]+([^>]*>)/$1$offset$2/gs;
                    }
                    $template = $template->clone();
                    $template->text( $tmpl_src );
                    my $url = $blog->archive_url || $blog->site_url;
                    $url .= '/' unless $url =~ m|/$|;
                    my $blog_url = $url;
                    if ( $_ == 1 ) {
                        $prev_url =~ s/(.*)(\..*)/$1$2/;
                    } else {
                        $prev_url =~ s/(.*)(\..*)/$1_$_$2/;
                    }
                    $prev_url =~ s/^$q_arch_root/$blog_url/;
                    if ( is_windows() ) {
                        $prev_url =~ tr{\\}{/};
                    }
                    $ctx->{ __stash }{ 'prev_link' } = $prev_url;
                    my $next_num;
                    if ( $_ != $repeat ) {
                        $next_num = $_ + 2;
                    } else {
                        $next_num = 2;
                    }
                    $next_url =~ s/(.*)(\..*)/$1_$next_num$2/;
                    $next_url =~ s/^$q_arch_root/$blog_url/;
                    if ( is_windows() ) {
                        $next_url =~ tr{\\}{/};
                    }
                    $ctx->{ __stash }{ 'next_link' } = $next_url;
                    my $file_num = $_ + 1;
                    $new_file =~ s/(.*)(\..*)/$1_$file_num$2/;
                    my ( $cond );
                    my $html = $template->build( $ctx, $cond );
                    $url .= $map->{ __saved_output_file } if $map->{ __saved_output_file };
                    $url =~ s/(.*)(\..*)/$1_$file_num$2/;
                    my ( $rel_url ) = ( $url =~ m|^(?:[^:]*\:\/\/)?[^/]*(.*)| );
                    $rel_url =~ s|//+|/|g;
                    my %terms;
                    $terms{ blog_id }     = $blog->id;
                    $terms{ startdate }   = $start;
                    $terms{ archive_type } = $at;
                    my ( $map_id, $category_id, $author_id );
                    if ( $at ne 'index' ) {
                        $map_id = $map->id;
                        $category_id = $category->id if defined $category;
                        $author_id = $orig_finfo->author_id;
                        $terms{ templatemap_id } = $map_id;
                        $terms{ category_id } = $category_id;
                        $terms{ author_id }   = $author_id;
                    }
                    my @finfos = MT::FileInfo->load( \%terms );
                    my $finfo;
                    if ( ( scalar @finfos == 1 )
                        && ( $finfos[ 0 ]->file_path eq $new_file )
                        && ( ( $finfos[ 0 ]->url || '' ) eq $rel_url )
                        && ( $finfos[ 0 ]->template_id == $tmpl_id ) ) {
                        $finfo = $finfos[ 0 ];
                    } else {
                        foreach ( @finfos ) { $_->remove(); }
                        $finfo = MT::FileInfo->set_info_for_url(
                            $rel_url, $new_file, $at,
                            {
                                Blog        => $blog->id,
                                TemplateMap => $map_id,
                                Template    => $tmpl_id,
                                StartDate   => $start,
                                Category    => $category_id,
                                Author      => $author_id,
                            }
                        )
                            or die "Couldn't create FileInfo because " . MT::FileInfo->errstr();
                        if ( $finfo ) {
                            $finfo->original_id( $orig_finfo->id );
                            $finfo->save;
                            my @duplicates = MT->model( 'fileinfo' )->load( { id => { 'not' => $finfo->id },
                                                                              blog_id => $finfo->blog_id,
                                                                              archive_type => $finfo->archive_type,
                                                                              original_id => $finfo->original_id,
                                                                              template_id => $finfo->template_id,
                                                                              templatemap_id => $finfo->templatemap_id,
                                                                              file_path => $finfo->file_path,
                                                                              url => $finfo->url,
                                                                            }
                                                                          );
                            for my $duplicate ( @duplicates ) {
                                $duplicate->remove;
                            }
                        }
                        if ( $org_template ) {
                            my $file_path = $finfo->file_path;
                            my $site_path = site_path( $blog );
                            my $search = quotemeta( $site_path );
                            $file_path =~ s/$search/%r/;
                            my $org_file_path = $org_template->pager_file_path || '';
                            my @file_paths = split( "\n", $org_file_path );
                            push ( @file_paths, $file_path );
                            my %tmp;
                            @file_paths = grep( ! $tmp{ $_ }++, @file_paths );
                            my $file_path_list = join( "\n", @file_paths );
                            $org_template->pager_file_path( $file_path_list );
                            $org_template->save or $org_template->errstr;
                        }
                    }
                    my $orig_html = $html;
                    $args{ 'File' } = $new_file;
                    $args{ 'file' } = $new_file;
                    $args{ 'FileInfo' } = $finfo;
                    $args{ 'file_info' } = $finfo;
                    $args{ 'Content' } = \$html;
                    $args{ 'content' } = \$html;
                    $args{ 'BuildResult' } = \$orig_html;
                    $args{ 'build_result' } = \$orig_html;
                    $args{ 'RawContent' } = \$orig_html;
                    $args{ 'raw_content' } = \$orig_html;
                    $app->run_callbacks( 'build_page', %args );
                    if ( $fmgr->content_is_updated( $new_file, \$html ) ) {
                        require File::Spec;
                        my $path = dirname( $new_file );
                        $path =~ s!/$!!
                          if $path ne '/';
                        unless ( $fmgr->exists( $path ) ) {
                            $fmgr->mkpath( $path )
                              or return $mt->trans_error( "Error making path '[_1]': [_2]",
                                $path, $fmgr->errstr );
                        }
                        $fmgr->put_data( $html, "$new_file.new" );
                        $fmgr->rename( "$new_file.new", $new_file );
                        $app->run_callbacks( 'build_file', %args );
                    }
                }
            }
        }
        $ctx->{ __stash }{ 'pager' } = 0;
        $ctx->{ __stash }{ 'prev' } = 0;
        $ctx->{ __stash }{ 'next' } = 1 if $repeat;
    } else {
        if ( my $blog = $args{ 'Blog' } ) {
            my $site_path = site_path( $blog );
            my $file_path_list = $template->pager_file_path() || '';
            my @file_paths = split( "\n", $file_path_list );
            for my $file_path ( @file_paths ) {
                $file_path =~ s/%r/$site_path/;
                if ( -f $file_path ) {
                    unlink $file_path;
                }
            }
            $template->pager_file_path( undef );
            $template->text( $template->text ); # needed porocess for linkfile!
            $template->save or die $template->errstr;
        }
    }
    my $tmpl_src = $template->text;
    my $offset = '0';
#    if ( $tag eq 'entry' ) {
#        $tmpl_src =~ s/(<mt:*entries.*?offset=.*?)auto(.*?>)/$1$offset$2/gis;
#    }
    $template->text( $tmpl_src );
    $args{ 'Template' } = $template;
    return 1;
}

sub _cb_restore {
    my $self = shift;
    my ( $all_objects, $callback, $errors ) = @_;

    my $error_object_count = 0;

    for my $key ( keys %$all_objects ) {
        if ( $key =~ /^MT::FileInfo#(\d+)$/ ) {
            my $fileinfo = $all_objects->{$key};
            if ( my $original_id = $fileinfo->original_id ) {
                my $new_fileinfo = $all_objects->{ 'MT::FileInfo#' . $original_id };
                if ( $new_fileinfo ) {
                    $fileinfo->original_id( $new_fileinfo->id );
                } else {
                    $fileinfo->original_id( 0 );
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
