package Link::Plugin;

use strict;
use Link::Link;
use Link::LinkGroup;
use Link::LinkOrder;
use MT::Tag;
use MT::ObjectTag;
use File::Temp qw( tempdir );
use MT::I18N qw( substr_text length_text );
use MT::Util qw( format_ts offset_time_list encode_js );
use PowerCMS::Util qw( is_user_can build_tmpl upload utf8_on valid_ts file_extension
                       csv_new get_weblog_ids current_ts remove_item get_content
                       encode_utf8_string_to_cp932_octets );

our $plugin_link = MT->component( 'Link' );

sub _init_request {
    my $app = MT->instance;
    if ( ref $app eq 'MT::App::CMS' ) {
        if ( ( $app->param( 'dialog_view' ) ) || ( MT->version_id =~ /^5\.0/ ) ) {
            $app->add_methods( list_link => \&_list_link );
            $app->add_methods( list_linkgroup => \&_list_link );
        }
    }
    $app;
}

sub _pre_run {
    my ( $cb, $app ) = @_;

    my $menus = MT->registry( 'applications', 'cms', 'menus' );
    if ( MT->version_id =~ /^5\.0/ ) {
        $menus->{ 'link:list_link' }->{ mode } = 'list_link';
        $menus->{ 'link:list_linkgroup' }->{ mode } = 'list_linkgroup';
        $menus->{ 'link:list_link' }->{ view } = [ 'blog', 'website' ];
        $menus->{ 'link:list_linkgroup' }->{ view } = [ 'blog', 'website' ];
    }

    if ( ( $app->mode eq 'save' ) && ( $app->param( '_type' ) eq 'link' ) ) {
        my $id = $app->param( 'id' ); return unless $id;
        my $original = MT->model( 'link' )->load( $id );
        $original = $original->clone_all() if $original;
        MT::Request->instance->cache( 'link_original' . $id, $original );
    }
}

sub _link_permission {
    my ( $blog ) = @_;
    my $app = MT->instance();
    my $user = $app->user;
    if ( $blog && ( ref $blog ne 'MT::Blog' ) ) {
        $blog = undef;
    }
    $blog = $app->blog unless $blog;
    return 1 if $user->is_superuser;
    if (! $blog ) {
        my %terms1 = ( author_id => $app->user->id, blog_id => { not => 0 }, permissions => { like => "%'administer_%" } );
        my %terms2 = ( author_id => $app->user->id, blog_id => { not => 0 }, permissions => { like => "%'manage_link'%" } );
        require MT::Permission;
        my $perms = MT::Permission->count( [ \%terms1, '-or', \%terms2 ] );
        if ( $perms ) {
            return 1;
        } else {
            return 0;
        }
    }
    if ( is_user_can( $blog, $user, 'administer_blog' ) ) {
        return 1;
    }
    if ( is_user_can( $blog, $user, 'administer_website' ) ) {
        return 1;
    }
    if ( is_user_can( $blog, $user, 'manage_link' ) ) {
        return 1;
    }
    if ( $app->param( 'dialog_view' ) ) {
        return 1;
    }
    return 0;
}

sub _group_permission {
    my ( $blog ) = @_;
    my $app = MT->instance();
    my $user = $app->user;
    if ( $blog && ( ref $blog ne 'MT::Blog' ) ) {
        $blog = undef;
    }
    $blog = $app->blog unless $blog;
    return 1 if $user->is_superuser;
    if (! $blog ) {
        my %terms1 = ( author_id => $app->user->id, blog_id => { not => 0 }, permissions => { like => "%'administer_%" } );
        my %terms2 = ( author_id => $app->user->id, blog_id => { not => 0 }, permissions => { like => "%'manage_linkgroup'%" } );
        require MT::Permission;
        my $perms = MT::Permission->count( [ \%terms1, '-or', \%terms2 ] );
        if ( $perms ) {
            return 1;
        } else {
            return 0;
        }
    }
    if ( is_user_can( $blog, $user, 'administer_blog' ) ) {
        return 1;
    }
    if ( is_user_can( $blog, $user, 'administer_website' ) ) {
        return 1;
    }
    if ( is_user_can( $blog, $user, 'manage_linkgroup' ) ) {
        return 1;
    }
    if ( $app->param( 'dialog_view' ) ) {
        return 1;
    }
    return 0;
}

sub _view_link {
    my $app = shift;
    my $plugin_link = MT->component( 'Link' );
    $app->{ plugin_template_path } = File::Spec->catdir( $plugin_link->path, 'tmpl' );
    $app->mode( 'edit' );
    return $app->forward( 'edit', @_ );
}

sub _list_tag {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $plugin_link = MT->component( 'Link' );
    if ( $app->param( 'filter_key' ) eq 'link' ) {
        $param->{ filter_label } = $plugin_link->translate( 'Tags with links' );
        $param->{ screen_group } = 'link';
    }
    my $list_filters = $param->{ list_filters };
            push @$list_filters,
            {
              key   => 'link',
              label => $plugin_link->translate( 'Tags with links' ),
            };
    $param->{ list_filters } = $list_filters;
}

sub _list_link {
    my $app = shift;
    my $plugin_link = MT->component( 'Link' );
    my $user = $app->user;
    my $mode = $app->mode;
    my $list_id = $mode;
    $list_id =~ s/^list_//;
    my %blogs;
    my $system_view;
    my $website_view;
    my $blog_view;
    my @blog_ids;
    my $r = MT::Request->instance;
    if (! defined $app->blog ) {
        $system_view = 1;
        my @all_blogs = MT::Blog->load( { class => [ 'website', 'blog' ] } );
        for my $blog ( @all_blogs ) {
            if ( Link::Plugin::_link_permission( $blog ) ) {
                $blogs{ $blog->id } = $blog;
                push ( @blog_ids, $blog->id );
            }
        }
    } else {
        if ( $app->param( 'dialog_view' ) ) {
            if (! _post_permission( $app->blog ) ) {
                return $app->trans_error( 'Permission denied.' );
            }
        } else {
            if (! Link::Plugin::_link_permission( $app->blog ) ) {
                return $app->trans_error( 'Permission denied.' );
            }
        }
        if ( $app->blog->class eq 'website' ) {
            $website_view = 1;
            $blogs{ $app->blog->id } = $app->blog;
            push ( @blog_ids, $app->blog->id );
            my $children = $app->blog->blogs;
            for my $blog ( @$children ) {
                if ( Link::Plugin::_link_permission( $blog ) ) {
                    $blogs{ $blog->id } = $blog;
                    push ( @blog_ids, $blog->id );
                }
            }
        } else {
            $blog_view = 1;
            push ( @blog_ids, $app->blog->id );
        }
    }
    my $code = sub {
        my ( $obj, $row ) = @_;
        my $columns = $obj->column_names;
        for my $column ( @$columns ) {
            my $val = $obj->$column;
            if ( $column =~ /_on$/ ) {
                $val = format_ts( "%Y&#24180;%m&#26376;%d&#26085;", $val, undef,
                                  $app->user ? $app->user->preferred_language : undef );
            } else {
                if ( $column eq 'description' ) {
                    $val = substr_text( $val, 0, 20 ) . ( length_text( $val ) > 20 ? "..." : "" );
                } elsif ( $column eq 'url' ) {
                    my $short = substr_text( $val, 0, 40 ) . ( length_text( $val ) > 40 ? "..." : "" );
                    $row->{ 'url_short' } = $short;
                }
            }
            $row->{ $column } = $val;
        }
        if ( (! defined $app->blog ) || ( $website_view ) ) {
            if ( defined $blogs{ $obj->blog_id } ) {
                my $blog_name = $blogs{ $obj->blog_id }->name;
                $blog_name = substr_text( $blog_name, 0, 20 ) . ( length_text( $blog_name ) > 20 ? "..." : "" );
                $row->{ weblog_name } = $blog_name;
                $row->{ weblog_id } = $obj->blog_id;
                $row->{ can_edit } = Link::Plugin::_link_permission( $blogs{ $obj->blog_id } );
                if ( $list_id =~ /group$/ ) {
                    $row->{ can_edit } = Link::Plugin::_group_permission( $blogs{ $obj->blog_id } );
                    if ( defined $blogs{ $obj->addfilter_blog_id } ) {
                        $row->{ filter_blogname } = $blogs{ $obj->addfilter_blog_id }->name;
                    }
                }
            }
        } else {
            $row->{ can_edit } = 1;
        }
        if ( $list_id =~ /group$/ ) {
            my $count = Link::LinkOrder->count( { group_id => $obj->id } );
            $row->{ count } = $count;
        }
        my $obj_author = $obj->author;
        $row->{ author_name } = $obj_author->name;
    };
    my @link_admin = _load_link_admin( @blog_ids );
    my @author_loop;
    for my $admin ( @link_admin ) {
        $r->cache( 'cache_author:' . $admin->id, $admin );
        push @author_loop, {
                author_id => $admin->id,
                author_name => $admin->name,
            };
    }
    my %terms;
    my %param;
    my $sort_column;
    if ( $list_id !~ /group$/ ) {
        my @tag_loop;
        my @tags = MT::Tag->load( undef,
                                  { join => MT::ObjectTag->join_on( 'tag_id',
                                  { blog_id => \@blog_ids, object_datasource => 'link' },
                                  { unique => 1 } ) } );
        for my $tag ( @tags ) {
            push @tag_loop, { tag_name => $tag->name };
        }
        $param{ tag_loop } = \@tag_loop;
        $sort_column = 'authored_on';
    } else {
        $sort_column = 'modified_on';
    }
    $param{ list_id } = $list_id;
    $param{ dialog_view }  = $app->param( 'dialog_view' );
    $param{ edit_field }   = $app->param( 'edit_field' );
    $param{ author_loop }  = \@author_loop;
    $param{ system_view }  = $system_view;
    $param{ website_view } = $website_view;
    $param{ filter } = $app->param( 'filter' );
    $param{ filter_val } = $app->param( 'filter_val' );
    $param{ blog_view }    = $blog_view;
    $param{ LIST_NONCRON } = 1;
    $param{ saved_deleted }  = 1 if $app->param( 'saved_deleted' );
    $param{ published }      = 1 if $app->param( 'published' );
    $param{ not_published }  = 1 if $app->param( 'not_published' );
    $param{ unpublished }    = 1 if $app->param( 'unpublished' );
    $param{ not_unpublished }= 1 if $app->param( 'not_published' );
    $param{ imported } = 1 if $app->param( 'imported' );
    $param{ not_imported } = 1 if $app->param( 'not_imported' );
    $param{ broken_links } = $app->param( 'broken_links' );
    $param{ broken_rsses } = $app->param( 'broken_rsses' );
    $param{ broken_images }= $app->param( 'broken_images' );
    $param{ broken } = $app->param( 'broken' );
    $param{ not_broken } = $app->param( 'not_broken' );
    $param{ link_checked } = $app->param( 'link_checked' );
    $param{ not_link_checked } = $app->param( 'not_link_checked' );
    if ( $website_view ) {
        $terms{ blog_id } = \@blog_ids;
    }
    if ( $app->param( 'filter' ) eq 'rating' ) {
        if ( $app->param( 'filter_val' ) == '0' ) {
            $terms{ rating } = 0;
        }
    }
    $app->{ plugin_template_path } = File::Spec->catdir( $plugin_link->path, 'tmpl' );
    if ( my $query = $app->param( 'query' ) ) {
        my $search_col = $app->param( 'search_col' );
        $param{ query } = $query;
        $param{ search_col_label } = $plugin_link->translate( $search_col );
        $param{ search_col } = $search_col;
        my %terms1 = ( blog_id => \@blog_ids,
                       $search_col => { like => "%$query%" }, );
        return $app->listing (
            {
                type   => $list_id,
                code   => $code,
                args   => { sort => $sort_column, direction => 'descend' },
                params => \%param,
                terms  => \%terms1,
            }
        );
    }
    return $app->listing (
        {
            type   => $list_id,
            code   => $code,
            args   => { sort => $sort_column, direction => 'descend' },
            params => \%param,
            terms  => \%terms,
        }
    );
}

sub _upload_link {
    my $app = shift;
    my $plugin_link = MT->component( 'Link' );
    my $user = $app->user;
    my $blog = $app->blog;
    if (! defined $blog ) {
        $app->return_to_dashboard();
    }
    if (! Link::Plugin::_link_permission( $blog ) ) {
        return $app->trans_error( 'Permission denied.' );
    }
    $app->validate_magic or return $app->trans_error( 'Permission denied.' );
    my $tempdir = $app->config( 'TempDir' );
    my $workdir = tempdir ( DIR => $tempdir );
    my %params = ( format_LF => 1,
                   singler => 1,
                   no_asset => 1,
                  );
    my $upload = upload( $app, $blog, 'file', $workdir, \%params );
    my $do;
    my $model = $app->model( 'link' );
    my $ts = current_ts( $blog );
    if ( file_extension ( $upload ) eq 'csv' ) {
        my $csv = csv_new();
        require MT::Blog;
        require MT::Website;
        require MT::Author;
        my $i = 0;
        my @clumn_names;
        open my $fh, "<", $upload;
        my $weblog_ids = get_weblog_ids( $blog );
        while ( my $columns = $csv->getline ( $fh ) ) {
            if (! $i ) {
                for my $cell ( @$columns ) {
                    push ( @clumn_names, $cell );
                }
            } else {
                my $j = 0;
                my $perm = 1;
                my $blog_id;
                my $weblog;
                my $id;
                my $url;
                my %values;
                for my $cell ( @$columns ) {
                    if ( ( $model->has_column( $clumn_names[$j] ) ) || ( $clumn_names[$j] eq 'tags' ) ) {
                        my $guess_encoding = MT::I18N::guess_encoding( $cell );
                        unless ( $guess_encoding =~ /^utf-?8$/i ) {
                            $cell = utf8_on( MT::I18N::encode_text( $cell, 'cp932', 'utf8' ) );
                        }
                        if ( $clumn_names[ $j ] eq 'blog_id' ) {
                            if ( grep( /^$cell$/, @$weblog_ids ) ) {
                                $perm = 1;
                                $blog_id = $cell;
                            } else {
                                $perm = 0;
                            }
                        } elsif ( $clumn_names[$j] eq 'id' ) {
                            $id = $cell;
                        } elsif ( $clumn_names[$j] eq 'url' ) {
                            $url = $cell;
                        } else {
                            $values{ $clumn_names[$j] } = $cell;
                        }
                    }
                    $j++;
                }
                my $link;
                if ( $id ) {
                    $link = $model->get_by_key( { id => $id } );
                    if ( my $obj_blog_id = $link->blog_id ) {
                        if (! grep( /^$obj_blog_id$/, @$weblog_ids ) ) {
                            $perm = 0;
                        }
                    }
                } else {
                    if ( $url ) {
                        $blog_id = $app->blog->id unless $blog_id;
                        $link = $model->get_by_key( { url => $url, blog_id => $blog_id } );
                    } else {
                        $link = $model->new;
                    }
                }
                if (! $blog_id ) {
                    $blog_id = $blog->id;
                }
                $weblog = MT::Blog->load( $blog_id );
                if (! defined $weblog ) {
                    $weblog = MT::Website->load( $blog_id );
                }
                if (! defined $weblog ) {
                    $perm = 0;
                }
                if ( $perm ) {
                    for my $key ( keys %values ) {
                        if ( $key eq 'tags' ) {
                            my @tags = split( /,/, $values{ $key } );
                            $link->set_tags( @tags );
                        } else {
                            $link->$key( $values{ $key } );
                        }
                    }
                }
                $link->authored_on( $ts );
                $link->created_on( $ts );
                $link->modified_on( $ts );
                if ( $link->author_id ) {
                    my $author = MT::Author->load( $link->author_id );
                    if (! defined $author ) {
                        $perm = 0;
                    }
                    if (! Link::Plugin::_link_permission( $weblog, $author ) ) {
                        $perm = 0;
                    }
                } else {
                    $link->author_id( $app->user->id );
                }
                if (! $link->name ) {
                    $perm = 0;
                }
                if ( $perm ) {
                    $link->blog_id( $blog_id );
                    $link->save or $link->errstr;
                    $do = 1;
                }
            }
            $i++;
        }
        close $fh;
    } elsif ( file_extension ( $upload ) eq 'xml' ) {
        require XML::Simple;
        eval {
            local( $^W ) = 0;
            require XML::Parser;
        };
        unless ( $@ ) {
            $XML::Simple::PREFERRED_PARSER = 'XML::Parser';
        }
        my $xml = XML::Simple->new();
        my $opml = $xml->XMLin( $upload );
        my $body = $opml->{ body };
        my $outline = $body->{ outline };
        if ( ref $outline eq 'HASH' ) { # for Livedoor Reader(In case of Google Reader, this is unnecessary)
            $outline = $outline->{ outline };
        }
        for my $item ( @$outline ) {
            if ( $item->{ htmlUrl } ) {
                my $url = utf8_on( $item->{ htmlUrl } );
                my $link = $model->get_by_key( { url => $url, blog_id => $blog->id } );
                $link->name( utf8_on( $item->{ title } ) );
                $link->url ( $url );
                $link->rss_address( utf8_on( $item->{ xmlUrl } ) );
                $link->author_id( $app->user->id );
                $link->blog_id( $blog->id );
                $link->authored_on( $ts );
                $link->created_on( $ts );
                $link->modified_on( $ts );
                $link->status( 1 );
                $link->rating( 0 );
                $link->save or die $link->errstr;
                $do = 1;
            }
        }
    }
    remove_item( $workdir );
    if ( $do ) {
        $app->add_return_arg( imported => 1 );
    } else {
        $app->add_return_arg( not_imported => 1 );
    }
    $app->call_return;
}

sub _download_link_csv {
    my $app = shift;
    my $blog = $app->blog;
    if (! defined $blog ) {
        $app->return_to_dashboard();
    }
    if (! Link::Plugin::_link_permission( $blog ) ) {
        return $app->trans_error( 'Permission denied.' );
    }
    $app->validate_magic or return $app->trans_error( 'Permission denied.' );
    my $csv = csv_new();
    $app->{ no_print_body } = 1;
    my $ts = current_ts();
    my $model = $app->model( 'link' );
    $app->set_header( "Content-Disposition" => "attachment; filename=csv_$ts.csv" );
    $app->set_header( "pragma" => '' );
    $app->send_http_header( 'text/csv' );
    my $column_names = $model->column_names;
    push ( @$column_names, 'tags' );
    if ( $csv->combine( @$column_names ) ) {
        my $string = $csv->string;
        print $string;
    }
    my $weblog_ids = get_weblog_ids( $blog );
    my $iter = $model->load_iter( { blog_id => $weblog_ids } );
    while ( my $item = $iter->() ) {
        my @fields;
        for my $c ( @$column_names ) {
            if ( $c eq 'tags' ) {
                my @tags = $item->get_tags;
                my $tag = join( ',', @tags );
                push ( @fields, $tag );
            } else {
                push ( @fields, $item->$c );
            }
        }
        if ( $csv->combine( @fields ) ) {
            my $string = $csv->string;
            $string = encode_utf8_string_to_cp932_octets( $string );
            print "\n$string";
        }
    }
}

sub _publish_links {
    _status_change( 'published', Link::Link::RELEASE() );
}

sub _unpublish_links {
    _status_change( 'unpublished', Link::Link::HOLD() );
}

sub _status_change {
    my ( $param, $status ) = @_;
    $plugin_link = MT->component( 'Link' );
    my $app = MT::instance();
    if ( $app->param( 'all_selected' ) ) {
        $app->setup_filtered_ids;
    }
    my @id = $app->param( 'id' );
    my $do;
    for my $link_id ( @id ) {
        my $link = $app->model( 'link' )->load( $link_id );
        return $app->errtrans( 'Invalid request.' ) unless $link;
        if (! Link::Plugin::_link_permission( $link->blog ) ) {
            return $app->trans_error( 'Permission denied.' );
        }
        if ( $link->status != $status ) {
            my $original = $link->clone_all();
            my $before = $plugin_link->translate( $original->status_text );
            $link->status( $status );
            $link->save or die $link->errstr;
            if ( $status == Link::Link::HOLD() ) {
                $app->run_callbacks( 'post_unpublish.link', $app, $link, $original );
            } elsif ( $status == Link::Link::RELEASE() ) {
                $app->run_callbacks( 'post_publish.link', $app, $link, $original );
            }
            my $after = $plugin_link->translate( $link->status_text );
            $app->log( {
                message => $plugin_link->translate( 'Link \'[_1]\' (ID:[_2]) edited and its status changed from [_3] to [_4] by user \'[_5]\'', $link->name, $link->id, $before, $after, $app->user->name ),
                blog_id => $link->blog_id,
                author_id => $app->user->id,
                class => 'link',
                level => MT::Log::INFO(),
            } );
            $do = 1;
        }
    }
    if ( $do ) {
        $app->add_return_arg( $param => 1 );
    } else {
        $app->add_return_arg( 'not_' . $param => 1 );
    }
    $app->call_return;
}

sub _action_link_check {
    my $app = shift;
    if (! defined $app->blog ) {
        $app->return_to_dashboard( redirect => 1 );
    } else {
        if (! Link::Plugin::_link_permission( $app->blog ) ) {
            return $app->trans_error( 'Permission denied.' );
        }
    }
    if ( $app->param( 'all_selected' ) ) {
        $app->setup_filtered_ids;
    }
    my @id = $app->param( 'id' );
    my $do;
    my $broken_links = 0;
    my $broken_rsses = 0;
    my $broken_images = 0;
    require HTTP::Date;
    my $remote_ip = $app->remote_ip;
    my $agent = "Mozilla/5.0 (Movable Type Link plugin X_FORWARDED_FOR:$remote_ip)";
    my $ua = MT->new_ua( { agent => $agent } );
    for my $link_id ( @id ) {
        my $obj = MT->model( 'link' )->load( $link_id );
        my $change;
        if ( $obj->url ) {
            my $response = $ua->head( $obj->url );
            if (! $response->is_success ) {
                $change = 1 if (! $obj->broken_link );
                $obj->broken_link( 1 );
                $obj->urlupdated_on( undef );
                $broken_links++;
            } else {
                my $content = get_content( $obj->url );
                if ( $content ) {
                    require Digest::MD5;
                    $content = Digest::MD5::md5_hex( $content );
                    if ( (! $obj->digest ) || ( $obj->digest ne $content ) ) {
                        my ( $year, $mon, $day, $hour, $min, $sec, $tz ) = HTTP::Date::parse_date( $response->header( "Last-Modified" ) );
                        my $modified = sprintf( "%04d%02d%02d%02d%02d%02d", $year, $mon, $day, $hour, $min, $sec );
                        if (! valid_ts( $modified ) ) {
                            $modified = current_ts( $obj->blog );
                        }
                        $obj->urlupdated_on( $modified );
                        $obj->digest( $content );
                        $change = 1;
                    }
                }
                $change = 1 if ( $obj->broken_link );
                $obj->broken_link( 0 );
            }
        } else {
            $change = 1 if (! $obj->broken_link );
            $obj->broken_link( 1 );
            $obj->urlupdated_on( undef );
        }
        if ( $obj->rss_address ) {
            my $response = $ua->head( $obj->rss_address );
            if (! $response->is_success ) {
                $change = 1 if (! $obj->broken_rss );
                $obj->broken_rss( 1 );
                $obj->rssupdated_on( undef );
                $broken_rsses++;
            } else {
                my $content = get_content( $obj->rss_address );
                my $modified;
                if ( ( $content ) && ( $content =~ m!^.*?<.*?date.*?>(.*?)</.*?date.*?>!si ) ) {
                    $modified = $1;
                } else {
                    $modified = $response->header( "Last-Modified" );
                }
                my ( $year, $mon, $day, $hour, $min, $sec, $tz ) = HTTP::Date::parse_date( $modified );
                $modified = sprintf( "%04d%02d%02d%02d%02d%02d", $year, $mon, $day, $hour, $min, $sec );
                if (! valid_ts( $modified ) ) {
                    $modified = current_ts( $obj->blog );
                }
                if ( ( ! $obj->rssupdated_on ) || ( $obj->rssupdated_on ne $modified ) ) {
                    $obj->rssupdated_on( $modified );
                    $change = 1;
                }
                $change = 1 if ( $obj->broken_rss );
                $obj->broken_rss( 0 );
            }
        } else {
            $change = 1 if ( $obj->broken_rss );
            $obj->broken_rss( 0 );
        }
        if ( $obj->image_address ) {
            my $response = $ua->head( $obj->image_address );
            if (! $response->is_success ) {
                $change = 1 if (! $obj->broken_image );
                $obj->broken_image( 1 );
                $broken_images++;
            } else {
                $change = 1 if ( $obj->broken_image );
                $obj->broken_image( 0 );
            }
        } else {
            $change = 1 if ( $obj->broken_image );
            $obj->broken_image( 0 );
        }
        if ( $change ) {
            $obj->save or die $obj->errstr;
        }
        $do = 1;
    }
    if ( $do ) {
        $app->add_return_arg( link_checked => 1 );
        $app->add_return_arg( broken_links => $broken_links );
        $app->add_return_arg( broken_rsses => $broken_rsses );
        $app->add_return_arg( broken_images => $broken_images );
        if ( $broken_links || $broken_rsses || $broken_images ) {
            $app->add_return_arg( broken => 1 );
        } else {
            $app->add_return_arg( not_broken => 1 );
        }
    } else {
        $app->add_return_arg( not_link_checked => 1 );
    }
    $app->call_return;
}

sub _task_link_check {
    my $app = MT->instance();
    my $plugin_link = MT->component( 'Link' );

    require MT::ConfigMgr;
    my $cfg = MT::ConfigMgr->instance;
    return 0 unless $cfg->DoScheduledLinkCheck;

    my $iter = MT::Blog->load_iter( { class => '*' } );
    require HTTP::Date;
    my $agent = "Mozilla/5.0 (Movable Type Link plugin)";
    my $ua = MT->new_ua( { agent => $agent } );
    my $do;
    while ( my $blog = $iter->() ) {
        my $blog_do;
        my $error;
        my $check_outlink = $plugin_link->get_config_value( 'check_outlink', 'blog:'. $blog->id );
        next unless $check_outlink;
        my @links = MT->model( 'link' )->load( { blog_id => $blog->id } );
        for my $obj ( @links ) {
            my $original = $obj->clone_all;
            my $change;
            if ( $obj->url ) {
                $do = 1; $blog_do = 1;
                my $response = $ua->head( $obj->url );
                if (! $response->is_success ) {
                    $change = 1 if (! $obj->broken_link );
                    $obj->broken_link( 1 );
                    $obj->urlupdated_on( undef );
                    $app->log( {
                        message => $plugin_link->translate( 'This URL \'[_1]\' is broken.', $obj->url ),
                        blog_id => $obj->blog_id,
                        class => 'link',
                        level => MT::Log::ERROR(),
                    } );
                    $error = 1;
                    $app->run_callbacks( 'post_broken_url.link', $app, $obj, $original );
                } else {
                    my $content = get_content( $obj->url );
                    if ( $content ) {
                        require Digest::MD5;
                        $content = Digest::MD5::md5_hex( $content );
                        if ( (! $obj->digest ) || ( $obj->digest ne $content ) ) {
                            my ( $year, $mon, $day, $hour, $min, $sec, $tz ) = HTTP::Date::parse_date( $response->header( "Last-Modified" ) );
                            my $modified = sprintf( "%04d%02d%02d%02d%02d%02d", $year, $mon, $day, $hour, $min, $sec );
                            if (! valid_ts( $modified ) ) {
                                $modified = current_ts( $obj->blog );
                            }
                            $obj->urlupdated_on( $modified );
                            $obj->digest( $content );
                            $change = 1;
                        }
                    }
                    $change = 1 if ( $obj->broken_link );
                    $obj->broken_link( 0 );
                }
            } else {
                $change = 1 if (! $obj->broken_link );
                $obj->broken_link( 1 );
                $obj->urlupdated_on( undef );
            }
            if ( $obj->rss_address ) {
                $do = 1; $blog_do = 1;
                my $response = $ua->head( $obj->rss_address );
                if (! $response->is_success ) {
                    $change = 1 if (! $obj->broken_rss );
                    $obj->broken_rss( 1 );
                    $obj->rssupdated_on( undef );
                    $app->log( {
                        message => $plugin_link->translate( 'This RSS \'[_1]\' is broken.', $obj->rss_address ),
                        blog_id => $obj->blog_id,
                        class => 'link',
                        level => MT::Log::ERROR(),
                    } );
                    $error = 1;
                    $app->run_callbacks( 'post_broken_rss.link', $app, $obj, $original );
                } else {
                    my $content = get_content( $obj->rss_address );
                    my $modified;
                    if ( ( $content ) && ( $content =~ m!^.*?<.*?date.*?>(.*?)</.*?date.*?>!si ) ) {
                        $modified = $1;
                    } else {
                        $modified = $response->header( "Last-Modified" );
                    }
                    my ( $year, $mon, $day, $hour, $min, $sec, $tz ) = HTTP::Date::parse_date( $modified );
                    $modified = sprintf( "%04d%02d%02d%02d%02d%02d", $year, $mon, $day, $hour, $min, $sec );
                    if (! valid_ts( $modified ) ) {
                        $modified = current_ts( $obj->blog );
                    }
                    if ( ( ! $obj->rssupdated_on ) || ( $obj->rssupdated_on ne $modified ) ) {
                        $obj->rssupdated_on( $modified );
                        $change = 1;
                    }
                    $change = 1 if ( $obj->broken_rss );
                    $obj->broken_rss( 0 );
                }
            } else {
                $change = 1 if ( $obj->broken_rss );
                $obj->broken_rss( 0 );
            }
            if ( $obj->image_address ) {
                $do = 1; $blog_do = 1;
                my $response = $ua->head( $obj->image_address );
                if (! $response->is_success ) {
                    $change = 1 if (! $obj->broken_image );
                    $obj->broken_image( 1 );
                    $app->log( {
                        message => $plugin_link->translate( 'This image \'[_1]\' is broken.', $obj->image_address ),
                        blog_id => $obj->blog_id,
                        class => 'link',
                        level => MT::Log::ERROR(),
                    } );
                    $error = 1;
                    $app->run_callbacks( 'post_broken_image.link', $app, $obj, $original );
                } else {
                    $change = 1 if ( $obj->broken_image );
                    $obj->broken_image( 0 );
                }
            } else {
                $change = 1 if ( $obj->broken_image );
                $obj->broken_image( 0 );
            }
            if ( $change ) {
                $obj->save or die $obj->errstr;
            }
        }
        if ( $blog_do ) {
            $app->run_callbacks( 'post_task_blog_linkcheck', $app, $blog, $error );
        }
    }
    if ( $do ) {
        return 1;
    } else {
        return 0;
    }
}

sub _search_link {
    my $app = shift;
    my ( %args ) = @_;
    my %blogs;
    my $system_view;
    my $website_view;
    my $blog_view;
    my @blog_ids;
    my $r = MT::Request->instance;
    if ( defined $app->blog ) {
        if (! Link::Plugin::_link_permission( $app->blog ) ) {
            return $app->trans_error( 'Permission denied.' );
        }
        if ( $app->blog->class eq 'website' ) {
            $website_view = 1;
        } else {
            $blog_view = 1;
        }
    }
    my $iter;
    if ( $args{ iter } ) {
        $iter = $args{ iter };
    } elsif ( $args{ items } ) {
        $iter = sub { pop @{ $args{ items } } };
    }
    return [] unless $iter;
    my $limit = $args{ limit };
    my $param = $args{ param } || {};
    my @data;
    while ( my $obj = $iter->() ) {
        my $row = $obj->column_values;
        $row->{ object } = $obj;
        my $columns = $obj->column_names;
        for my $column ( @$columns ) {
            my $val = $obj->$column;
            if ( $column =~ /_on$/ ) {
                $val = format_ts( "%Y&#24180;%m&#26376;%d&#26085;", $val, undef,
                                  $app->user ? $app->user->preferred_language : undef );
            }
            $row->{ $column } = $val;
        }
        if ( (! defined $app->blog ) || ( $website_view ) ) {
            if ( $obj->blog ) {
                my $blog_name = $obj->blog->name;
                $blog_name = substr_text( $blog_name, 0, 20 ) . ( length_text( $blog_name ) > 20 ? "..." : "" );
                $row->{ weblog_name } = $blog_name;
                $row->{ weblog_id } = $obj->blog_id;
                $row->{ can_edit } = Link::Plugin::_link_permission( $obj->blog );
            }
        } else {
            $row->{ can_edit } = 1;
        }
        if ( $app->param( '_type' ) =~ /group$/ ) {
            my $count = Link::LinkOrder->count( { group_id => $obj->id } );
            $row->{ count } = $count;
        }
        my $link_author = $obj->author;
        $row->{ author_name } = $link_author->name;
        push @data, $row;
        last if $limit and @data > $limit;
    }
    if ( $app->param( '_type' ) =~ /group$/ ) {
        $param->{ search_label } = $plugin_link->translate( 'Link Group' );
    } else {
        $param->{ search_label } = $plugin_link->translate( 'Link' );
    }
    return [] unless @data;
    #$app->config( 'TemplatePath', File::Spec->catdir( $plugin_link->path, 'tmpl' ) );
    $param->{ system_view } = 1 unless $app->param( 'blog_id' );
    $param->{ search_replace } = 1;
    $param->{ object_loop } = \@data;
    \@data;
}

sub _edit_link {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $plugin_link = MT->component( 'Link' );
    my $type  = $app->param( '_type' );
    my $class = $app->model( $type );
    my $blog  = $app->blog;
    if (! $blog ) {
        $app->return_to_dashboard();
    }
    if (! Link::Plugin::_link_permission( $app->blog ) ) {
        $app->return_to_dashboard( permission => 1 );
    }
    my $id = $app->param( 'id' );
    if ( $id ) {
        my $obj = $class->load( $id );
        if (! defined $obj ) {
            $app->return_to_dashboard( permission => 1 );
        }
        if ( $obj->blog_id != $blog->id ) {
            $app->return_to_dashboard( permission => 1 );
        }
        my @tags = $obj->tags;
        my $tag = join( ',', @tags );
        $param->{ tags } = $tag;
        my $next = $obj->_nextprev( 'next' );
        if ( $next ) {
            $param->{ next_link_id } = $next->id;
        }
        my $previous = $obj->_nextprev( 'previous' );
        if ( $previous ) {
            $param->{ previous_link_id } = $previous->id;
        }
        my $columns = $obj->column_names;
        if (! $app->param( 'saved' ) ) {
            my $check_outlink = $plugin_link->get_config_value( 'check_outlink', 'blog:'. $app->blog->id );
            my $ua;
            if ( $check_outlink ) {
                my $remote_ip = $app->remote_ip;
                my $agent = "Mozilla/5.0 (Movable Type Link plugin X_FORWARDED_FOR:$remote_ip)";
                $ua = MT->new_ua( { agent => $agent } );
                my $change;
                if ( $obj->url ) {
                    my $response = $ua->head( $obj->url );
                    if (! $response->is_success ) {
                        $change = 1 if (! $obj->broken_link );
                        $obj->broken_link( 1 );
                    } else {
                        $change = 1 if ( $obj->broken_link );
                        $obj->broken_link( 0 );
                    }
                } else {
                    $change = 1 if (! $obj->broken_link );
                    $obj->broken_link( 1 );
                }
                if ( $obj->rss_address ) {
                    my $response = $ua->head( $obj->rss_address );
                    if (! $response->is_success ) {
                        $change = 1 if (! $obj->broken_rss );
                        $obj->broken_rss( 1 );
                    } else {
                        $change = 1 if ( $obj->broken_rss );
                        $obj->broken_rss( 0 );
                    }
                } else {
                    $change = 1 if ( $obj->broken_rss );
                    $obj->broken_rss( 0 );
                }
                if ( $obj->image_address ) {
                    my $response = $ua->head( $obj->image_address );
                    if (! $response->is_success ) {
                        $change = 1 if (! $obj->broken_image );
                        $obj->broken_image( 1 );
                    } else {
                        $change = 1 if ( $obj->broken_image );
                        $obj->broken_image( 0 );
                    }
                } else {
                    $change = 1 if ( $obj->broken_image );
                    $obj->broken_image( 0 );
                }
                if ( $change ) {
                    $obj->save or die $obj->errstr;
                }
            }
        }
        for my $column ( @$columns ) {
            if ( $column =~ /_on$/ ) {
                my $column_ts = $obj->$column;
                $param->{ $column . '_date' } = format_ts( '%Y-%m-%d', $column_ts );
                $param->{ $column . '_time' } = format_ts( '%H:%M:%S', $column_ts );
            }
        }
    } else {
        my $columns = $class->column_names;
        my @tl = offset_time_list( time, $app->blog );
        my $ts_date = sprintf "%04d-%02d-%02d", $tl[5]+1900, $tl[4]+1, $tl[3];
        my $ts_time = sprintf "%02d:%02d:%02d",  @tl[2,1,0];
        for my $column ( @$columns ) {
            if ( $column =~ /_on$/ ) {
                $param->{ $column . '_date' } = $ts_date;
                $param->{ $column . '_time' } = $ts_time;
            }
        }
    }
    my $editor_style_css = $plugin_link->get_config_value( 'editor_style_css', 'blog:'. $blog->id );
    my %args = ( blog => $app->blog );
    $editor_style_css = build_tmpl( $app, $editor_style_css, \%args );
    $param->{ editor_style_css } = $editor_style_css;
    $param->{ theme_advanced_buttons1 } = $plugin_link->get_config_value( 'theme_advanced_buttons1', 'blog:'. $blog->id );
    $param->{ theme_advanced_buttons2 } = $plugin_link->get_config_value( 'theme_advanced_buttons2', 'blog:'. $blog->id );
    $param->{ theme_advanced_buttons3 } = $plugin_link->get_config_value( 'theme_advanced_buttons3', 'blog:'. $blog->id );
    $param->{ theme_advanced_buttons4 } = $plugin_link->get_config_value( 'theme_advanced_buttons4', 'blog:'. $blog->id );
    $param->{ theme_advanced_buttons5 } = $plugin_link->get_config_value( 'theme_advanced_buttons5', 'blog:'. $blog->id );
    $param->{ use_wysiwyg } = $plugin_link->get_config_value( 'use_wysiwyg', 'blog:'. $blog->id );
    $param->{ lang } = $app->user->preferred_language;
    $param->{ saved } = $app->param( 'saved' );
    $param->{ search_label } = $plugin_link->translate( 'Link' );
    $param->{ screen_group } = 'link';
    $param->{ return_args } = _force_view_mode_return_args( $app );
}

sub _edit_linkgroup {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $plugin_link = MT->component( 'Link' );
    my $type  = $app->param( '_type' );
    my $class = $app->model( $type );
    my $filter  = $app->param( 'filter' );
    my $blog  = $app->blog;
    if (! $blog ) {
        $app->return_to_dashboard();
    }
    if (! Link::Plugin::_group_permission( $app->blog ) ) {
        $app->return_to_dashboard( permission => 1 );
    }
    my $id = $app->param( 'id' );
    my $obj;
    if ( $id ) {
        $obj = $class->load( $id );
        if (! defined $obj ) {
            $app->return_to_dashboard( permission => 1 );
        }
        if ( $obj->blog_id != $blog->id ) {
            $app->return_to_dashboard( permission => 1 );
        }
    }
    my %blogs;
    my @weblog_loop;
    my $website_view;
    my $blog_view;
    my @blog_ids;
    my %terms;
    my %args;
    if (! defined $app->blog ) {
        $app->return_to_dashboard( redirect => 1 );
    } else {
        if (! Link::Plugin::_group_permission( $app->blog ) ) {
            $app->return_to_dashboard( redirect => 1 );
        }
        if ( $app->blog->class eq 'website' ) {
            push @weblog_loop, {
                    weblog_id => $app->blog->id,
                    weblog_name => $app->blog->name, };
            $website_view = 1;
            $blogs{ $app->blog->id } = $app->blog;
            push ( @blog_ids, $app->blog->id );
            # my @all_blogs = MT::Blog->load( { parent_id => $app->blog->id } );
            my $children = $app->blog->blogs;
            for my $blog ( @$children ) {
                if ( Link::Plugin::_group_permission( $blog ) ) {
                    $blogs{ $blog->id } = $blog;
                    push ( @blog_ids, $blog->id );
                    push @weblog_loop, {
                            weblog_id => $blog->id,
                            weblog_name => $blog->name, };
                }
            }
            $param->{ weblog_loop } = \@weblog_loop;
        } else {
            $blog_view = 1;
            push ( @blog_ids, $app->blog->id );
        }
        if (! $blog_view ) {
            $terms{ blog_id } = \@blog_ids;
        } else {
            $terms{ blog_id } = $app->blog->id;
        }
        if ( $filter && ( $filter eq 'rating' ) ) {
            $terms{ rating } = { '>' => 0 };
        }
        if ( $filter && ( $filter =~ /^rating-(.*)$/ ) ) {
            $terms{ rating } = $1;
        }
        my @links;
        if ( $app->param( 'filter' ) && ( $app->param( 'filter' ) eq 'tag' ) ) {
            require MT::Tag;
            my $tag = MT::Tag->load( { name => $app->param( 'filter_tag' ) }, { binary => { name => 1 } } );
            if ( $tag ) {
                require MT::ObjectTag;
                $args { 'join' } = [ 'MT::ObjectTag', 'object_id',
                           { tag_id  => $tag->id,
                             blog_id => \@blog_ids,
                             object_datasource => 'link' }, ];
                @links = MT->model( 'link' )->load( \%terms, \%args );
            }
        } else {
            @links = MT->model( 'link' )->load( \%terms, \%args );
        }
        my @item_loop;
        for my $link ( @links ) {
            my $add_item = 1;
            if ( $id ) {
                my $item = MT->model( 'linkorder' )->load( { group_id => $id, link_id => $link->id } );
                $add_item = 0 if defined $item;
            }
            if ( $add_item ) {
                my $weblog_name = '';
                if (! $blog_view ) {
                    $weblog_name = $blogs{ $link->blog_id }->name;
                    $weblog_name = " ($weblog_name)";
                }
                push @item_loop, {
                        id => $link->id,
                        item_name => $link->name . $weblog_name,
                        weblog_id => $link->blog_id,
                        can_edit => _link_permission( $link->blog ),
                    };
            }
        }
        $param->{ item_loop } = \@item_loop;
        if ( $id ) {
            my $args =  { 'join' => [ 'Link::LinkOrder', 'link_id',
                        { group_id => $id },
                        { sort => 'order',
                          direction => 'ascend',
                        } ] };
            my @links = MT->model( 'link' )->load( \%terms, $args );
            my @group_loop;
            for my $link ( @links ) {
                my $weblog_name = '';
                if (! $blog_view ) {
                    $weblog_name = $blogs{ $link->blog_id }->name;
                    $weblog_name = " ($weblog_name)";
                }
                push @group_loop, {
                        id => $link->id,
                        item_name => $link->name . $weblog_name,
                        weblog_id => $link->blog_id,
                        can_edit => _link_permission( $link->blog ),
                    };
            }
            $param->{ group_loop } = \@group_loop;
        }
    }
    my @groups = Link::LinkGroup->load( { blog_id => $blog->id } );
    if ( @groups ) {
        my @names;
        for my $g ( @groups ) {
            if ( $id != $g->id ) {
                push ( @names, "'" . encode_js ( $g->name ) . "'" );
            }
        }
        my $names_array = join( ' , ', @names );
        $param->{ names_array } = $names_array if $names_array;
    }

    $param->{ filter } = $filter;
    $param->{ filter_tag } = $app->param( 'filter_tag' );
    $param->{ saved }  = $app->param( 'saved' );
    $param->{ search_label } = $plugin_link->translate( 'Link Group' );
    $param->{ screen_group } = 'link';
    $param->{ search_type } = 'link';
    $param->{ return_args } = _force_view_mode_return_args( $app );
}

sub _edit_template_param {
    my ( $cb, $app, $param, $tmpl ) = @_;
    if (! $app->param( 'id' ) ) {
        if ( my $blog = $app->blog ) {
            if ( my $group_id = $app->param( 'linkgroup_id' ) ) {
                my $plugin_link = MT->component( 'Link' );
                require Link::LinkGroup;
                my $group = Link::LinkGroup->load( $group_id );
                if ( $group ) {
                    my $group_name = $group->name;
                    my $template = $plugin_link->get_config_value( 'default_module_mtml', 'blog:'. $blog->id );
                    if (! $template ) {
                        $template = _default_module_mtml();
                    }
                    $template =~ s/\$group_name/$group_name/isg;
                    $template =~ s/\$group_id/$group_id/isg;
                    my $hidden_field = '<input type="hidden" name="linkgroup_id" value="' . $group_id . '" />';
                    $param->{ name } = $plugin_link->translate( 'Link Group' ) . ' : ' . $group_name;
                    $param->{ text } = $template;
                    my $pointer_field = $tmpl->getElementById( 'title' );
                    my $innerHTML = $pointer_field->innerHTML;
                    $pointer_field->innerHTML( $innerHTML . $hidden_field );
                }
            }
        }
    }
}

sub _add_tags_to_link {
    my $app = MT::instance();
    my $itemset_action_input = $app->param( 'itemset_action_input' );
    my $do;
    if ( $itemset_action_input ) {
        require MT::Tag;
        my $tag_delim = chr( $app->user->entry_prefs->{ tag_delim } ) || ',';
        my @tag_names = MT::Tag->split( $tag_delim, $itemset_action_input );
        my $plugin = MT->component( 'Link' );
        if ( $app->param( 'all_selected' ) ) {
            $app->setup_filtered_ids;
        }
        my @id = $app->param( 'id' );
        require Link::Link;
        for my $link_id ( @id ) {
            my $link = $app->model( 'link' )->load( $link_id );
            return $app->errtrans( 'Invalid request.' ) unless $link;
            if (! _link_permission( $link->blog ) ) {
                return $app->trans_error( 'Permission denied.' );
            }
            $link->add_tags( @tag_names );
            $link->save or die $link->errstr;
            $do = 1;
        }
    }
    if ( $do ) {
        $app->add_return_arg( 'add_tags_to_link' => 1 );
    } else {
        $app->add_return_arg( 'not_add_tags_to_link' => 1 );
    }
    $app->call_return;
}

sub _remove_tags_to_link {
    my $app = MT::instance();
    my $itemset_action_input = $app->param( 'itemset_action_input' );
    my $do;
    if ( $itemset_action_input ) {
        require MT::Tag;
        my $tag_delim = chr( $app->user->entry_prefs->{ tag_delim } ) || ',';
        my @tag_names = MT::Tag->split( $tag_delim, $itemset_action_input );
        my $plugin = MT->component( 'Link' );
        if ( $app->param( 'all_selected' ) ) {
            $app->setup_filtered_ids;
        }
        my @id = $app->param( 'id' );
        require Link::Link;
        for my $link_id ( @id ) {
            my $link = $app->model( 'link' )->load( $link_id );
            return $app->errtrans( 'Invalid request.' ) unless $link;
            if (! _link_permission( $link->blog ) ) {
                return $app->trans_error( 'Permission denied.' );
            }
            $link->remove_tags( @tag_names );
            $link->save or die $link->errstr;
            $do = 1;
        }
    }
    if ( $do ) {
        $app->add_return_arg( 'remove_tags_to_link' => 1 );
    } else {
        $app->add_return_arg( 'not_remove_tags_to_link' => 1 );
    }
    $app->call_return;
}

sub _cms_post_save_template {
    my ( $cb, $app, $obj, $original ) = @_;
    if (! $original->id ) {
        my $blog = $app->blog;
        if ( defined $blog ) {
            my $type = $obj->type;
            if ( $type ne 'custom' ) {
                return 1;
            }
            my $group_id = $app->param( 'linkgroup_id' );
            if ( $group_id ) {
                my $group = Link::LinkGroup->load( $group_id );
                if ( $group ) {
                    $group->template_id( $obj->id );
                    $group->save or die $group->errstr;
                }
            }
        }
    }
    return 1;
}

sub _cms_post_delete_template {
    my ( $cb, $app, $obj, $original ) = @_;
    my $type = $obj->type;
    if ( $type ne 'custom' ) {
        return 1;
    } else {
        my $group = Link::LinkGroup->load( { template_id => $obj->id } );
        if ( $group ) {
            $group->template_id( undef );
            $group->save or die $group->errstr;
        }
    }
    return 1;
}

sub _asset_insert {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $edit_field = $app->param( 'edit_field' );
    return unless $edit_field;
    if ( $edit_field =~ /^link_(.*$)/ ) {
        $edit_field = $1;
        my $pointer_field = $tmpl->getElementById( 'insert_script' );
        $pointer_field->innerHTML( "window.parent.custom_insertHTML( '<mt:var name=\"upload_html\" escape=\"js\">', '" . $edit_field . "' );" );
    }
}

sub _load_link_admin {
    my @blog_id = @_;
    push ( @blog_id, 0 );
    my $author_class = MT->model( 'author' );
    my %terms1 = ( blog_id => \@blog_id, permissions => { like => "\%'administer\%" } );
    my @admin = $author_class->load(
        { type => MT::Author::AUTHOR() },
        { join => [ 'MT::Permission', 'author_id',
            \%terms1,
            { unique => 1 } ],
        }
    );
    my @author_id;
    for my $author ( @admin ) {
        push ( @author_id, $author->id );
    }
    my %terms2 = ( blog_id => \@blog_id, permissions => { like => "\%'manage_link'\%" } );
    my @link_admin = $author_class->load(
        { type => MT::Author::AUTHOR(),
          id => { not => \@author_id } },
        { join => [ 'MT::Permission', 'author_id',
            \%terms2,
            { unique => 1 } ],
        }
    );
    push ( @admin, @link_admin );
    return @admin;
}

sub _post_permission {
    my $blog = shift;
    my $app = MT->instance();
    my $user = $app->user;
    return 1 if $user->is_superuser;
    $blog = $app->blog unless $blog;
    if ( is_user_can( $blog, $user, 'administer_blog' ) ) {
        return 1;
    }
    if ( is_user_can( $blog, $user, 'manage_pages' ) ) {
        return 1;
    }
    if ( is_user_can( $blog, $user, 'create_post' ) ) {
        return 1;
    }
    return 0;
}

sub _install_role {
    my $app = MT->instance();
    require MT::Role;
    my $plugin_link = MT->component( 'Link' );
    my $role = MT::Role->get_by_key( { name => $plugin_link->translate( 'Link Administrator' ) } );
    if (! $role->id ) {
        my $role_en = MT::Role->load( { name => 'Link Administrator' } );
        if (! $role_en ) {
            my %values;
            $values{ created_by }  = $app->user->id if $app->user;
            $values{ description } = $plugin_link->translate( 'Can create Link, edit Link.' );
            $values{ is_system }   = 0;
            $values{ permissions } = "'manage_link','manage_linkgroup'";
            $role->set_values( \%values );
            $role->save
                or return $app->trans_error( 'Error saving role: [_1]', $role->errstr );
        }
    }
    return 1;
}

sub _force_view_mode_return_args {
    my $app = shift;
    my $return = $app->make_return_args;
    $return =~ s/edit/view/;
    return $return;
}

sub _default_module_mtml {
    my $tmplate = <<MTML;
<MTLinks group="\$group_name">
<MTLinksHeader><ul></MTLinksHeader>
<li><a href="<MTLinkURL>"><MTLinkName escape="html"></a></li>
<MTLinksFooter></ul></MTLinksFooter>
</MTLinks>
MTML
    return $tmplate;
}

sub clone_object {
    my ( $cb, %param ) = @_;
    my $old_blog_id = $param{ old_blog_id };
    my $new_blog_id = $param{ new_blog_id };
    my $callback    = $param{ callback };
    my $app         = MT->instance;
    my $component = MT->component( 'Link' );
    my ( %linkgroup_map, %link_map, %id_link, @moved_objects );
    require Link::LinkOrder;
    if (! $app->param( 'clone_prefs_link' ) ) {
        my $terms = { blog_id => $old_blog_id };
        my $iter = MT->model( 'linkgroup' )->load_iter( $terms );
        my $counter = 0;
        my $state = $component->translate( 'Cloning Link Groups for blog...' );
        my $group_label = $component->translate( 'Link Groups' );
        my $obj_label = $component->translate( 'Link' );
        while ( my $object = $iter->() ) {
            $counter++;
            my $new_object = $object->clone_all();
            delete $new_object->{ column_values }->{ id };
            delete $new_object->{ changed_cols }->{ id };
            $new_object->blog_id( $new_blog_id );
            $new_object->save or die $new_object->errstr;
            $linkgroup_map{ $object->id } = $new_object->id;
        }
        $callback->(
            $state . " "
                . $app->translate( "[_1] records processed.", $counter ),
            $group_label
        );
        $counter = 0;
        $state = $component->translate( 'Cloning Links for blog...' );
        $iter = MT->model( 'link' )->load_iter( $terms );
        while ( my $object = $iter->() ) {
            $counter++;
            my $new_object = $object->clone_all();
            delete $new_object->{ column_values }->{ id };
            delete $new_object->{ changed_cols }->{ id };
            $new_object->blog_id( $new_blog_id );
            # TODO::Assets
            $new_object->save or die $new_object->errstr;
            push ( @moved_objects, $new_object );
            $link_map{ $object->id } = $new_object->id;
            $id_link{ $new_object->id } = $new_object;
            # $id_link{ $object->id } = $object;
            my $order_iter = Link::LinkOrder->load_iter( { link_id => $object->id } );
            while ( my $order = $order_iter->() ) {
                next unless $linkgroup_map{ $order->group_id };
                my $new_order = $order->clone_all();
                delete $new_order->{ column_values }->{ id };
                delete $new_order->{ changed_cols }->{ id };
                $new_order->link_id( $link_map{ $order->link_id } );
                $new_order->group_id( $linkgroup_map{ $order->group_id } );
                $new_order->save or die $new_order->errstr;
            }
        }
        $callback->(
            $state . " "
                . $app->translate( "[_1] records processed.", $counter ),
            $obj_label
        );
    }
    my $state = $component->translate( 'Cloning Link tags for blog...' );
    $callback->( $state, "link_tags" );
    my $iter
        = MT::ObjectTag->load_iter(
        { blog_id => $old_blog_id, object_datasource => 'link' }
        );
    my $counter = 0;
    while ( my $link_tag = $iter->() ) {
        next unless $link_map{ $link_tag->object_id };
        $counter++;
        my $new_link_tag = $link_tag->clone();
        delete $new_link_tag->{ column_values }->{ id };
        delete $new_link_tag->{ changed_cols }->{ id };
        $new_link_tag->blog_id( $new_blog_id );
        $new_link_tag->object_id(
            $link_map{ $link_tag->object_id } );
        $new_link_tag->save or die $new_link_tag->errstr;
    }
    $callback->(
        $state . " "
            . MT->translate( "[_1] records processed.",
            $counter ),
        'link_tags'
    );
    MT->request( 'linkgroup_map', \%linkgroup_map );
    MT->request( 'link_map', \%link_map );
    MT->request( 'id_link', \%id_link );
    # TODO:: Assets
    1;
}

sub clone_blog {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $plugin = MT->component( 'Link' );
    my $elements = $tmpl->getElementsByTagName( 'unless' );
    my $obj_label = 'Link';
    my $obj = 'link';
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

sub _upgrader_post_run {
    my $app = MT->instance();
    my $install;
    if ( ( ref $app ) eq 'MT::App::Upgrader' ) {
        if ( $app->mode eq 'run_actions' ) {
            if ( $app->param( 'installing' ) ) {
                $install = 1;
            }
        }
    }
    if ( $install ) {
        _install_role();
    }
    return 1;
}

sub _cb_restore {
    my ( $cb, $objects, $deferred, $errors, $callback ) = @_;

    my %restored_objects;
    for my $key ( keys %$objects ) {
        if ( $key =~ /^Link::Link#(\d+)$/ ) {
            $restored_objects{ $1 } = $objects->{ $key };
        }
    }

    require CustomFields::Field;

    my %class_fields;
    $callback->(
        MT->translate(
            "Restoring link associations found in custom fields ...",
        ),
        'cf-restore-object-link'
    );

    my $r = MT::Request->instance();
    for my $restored_object ( values %restored_objects ) {
        my $iter = CustomFields::Field->load_iter( { blog_id  => [ $restored_object->blog_id, 0 ],
                                                     type => [ 'link', 'link_multi', 'link_group' ],
                                                   }
                                                 );
        while ( my $field = $iter->() ) {
            my $class = MT->model( $field->obj_type );
            next unless $class;
            my @related_objects = $class->load( $class->has_column( 'blog_id' ) ? { blog_id => $restored_object->blog_id } : undef );
            my $column_name = 'field.' . $field->basename;
            for my $related_object ( @related_objects ) {
                my $cache_key = $class . ':' . $related_object->id . ':' . $column_name;
                next if $r->cache( $cache_key );
                my $value = $related_object->$column_name;
                my $restored_value;
                if ( $field->type eq 'link' ) {
                    my $restored = $objects->{ 'Link::Link#' . $value };
                    if ( $restored ) {
                        $restored_value = $restored->id;
                    }
                } elsif ( $field->type eq 'link_multi' ) {
                    my @values = split( /,/, $value );
                    my @new_values;
                    for my $backup_id ( @values ) {
                        next unless $backup_id;
                        next unless $objects->{ 'Link::Link#' . $backup_id };
                        my $restored_obj = $objects->{ 'Link::Link#' . $backup_id };
                        push( @new_values, $restored_obj->id );
                    }
                    if ( @new_values ) {
                        $restored_value = ',' . join( ',', @new_values ) . ',';
                    }
                } elsif ( $field->type eq 'link_group' ) {
                    my $restored = $objects->{ 'Link::LinkGroup#' . $value };
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
}

sub _task_adjust_order {
    my $updated = 0;
    my @orders = MT->model( 'linkorder' )->load();
    for my $order ( @orders ) {
        my $remove = 0;
        if ( my $group_id = $order->group_id ) {
            my $group = MT->model( 'linkgroup' )->load( { id => $group_id } );
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
