package PowerImporter::HTML;
use strict;

use base qw( MT::App );
use lib 'addons/PowerCMS.pack/lib';

use File::Temp qw( tempfile );
use File::Find;
use File::Basename;
use Unicode::Japanese;
use Cwd;

use MT::I18N qw( encode_text );
use MT::Util qw( encode_html );
use PowerCMS::Util qw( site_path site_url save_asset get_utf is_windows current_user
                       current_blog
                     );

sub import_contents {
    my $app = MT->instance();
    unless ( $app->validate_magic ) {
        return $app->trans_error( 'Permission denied.' );
    }
    my $user = current_user( $app );
    unless ( $user->is_superuser ) {
        return $app->trans_error( 'Permission denied.' );
    }
    my $user_id = $user->id;
    my $q = $app->param;
    my $fh = $q->upload( 'file' );
    my $blog = current_blog( $app );
    my $blog_id = $blog->id;
    my $plugin = MT->component( 'PowerImporter' );
    my $import_dir = $app->config( 'ImportPath' );
    my $tmp_dir = $app->config( 'TempDir' ) || $app->config( 'TmpDir' ) || $import_dir;
    my $tmp_path = File::Spec->catdir( $tmp_dir,  $blog_id . '_' . $user_id . '_XXXXXXXXXXX' );
    my $import_path = File::Spec->catdir( $import_dir,  $blog_id . '_' . $user_id . '_XXXXXXXXXXX' );
    my ( $hndl, $tmp_file ) = tempfile( $tmp_path, SUFFIX => '.pimpt' );
    my $import_ext =  $q->param( 'html_extensions' );
    my @extensions = split( /,/, $import_ext );
    my $import_exc = $q->param( 'html_exclude_root' );
    my @excludes = split( /,/, $import_exc );
    my $import_root = $q->param( 'html_import_root' );
    $import_root = _chopath( $import_root );
    if ( $fh ) {
        local *OUT;
        open OUT, ">>$tmp_file";
        while ( read( $fh, my $buffer, 2048 ) ){
            $buffer =~ s/\r\n/\n/g;
            $buffer =~ s/\r/\n/g;
            print OUT $buffer;
        }
        close OUT;
    } else {
        if ( $import_root && -d $import_root ) {
            my $getcwd = getcwd();
            my $abs_path = File::Spec->abs2rel( $import_root, $getcwd );
            my @directories_to_search = ( $abs_path );
            my @wantedFiles;
            find ( sub { push ( @wantedFiles, $File::Find::name ) unless ( /^\./ ); }, @directories_to_search );
            my $qabs = quotemeta( $abs_path );
            open OUT, ">>$tmp_file";
            for my $f ( @wantedFiles ) {
                $f =~ s/$qabs//;
                my $ext = ( File::Basename::fileparse( $f, qr/[A-Za-z]+$/) )[ 2 ];
                if ( grep( /$ext$/, @extensions ) ) {
                    my $file = $import_root . $f;
                    my $q_file = quotemeta( $file );
                    unless ( grep{ my $search = quotemeta( $_ ); $file =~ /$search/; } @excludes ) {
                        print OUT "$file\n";
                    }
                }
            }
            close OUT;
        } else {
            error( $plugin->translate( 'Import root was not found.' ) );
            return 0;
        }
    }
    unless ( -f $tmp_file ) {
        return 0;
    }
    my $html_save_settings = $q->param( 'html_save_settings' );
    my $html_do_realtime = $q->param( 'html_do_realtime' );
    if ( $html_save_settings || ! $html_do_realtime ) {
        my $html_title_field = $q->param( 'html_title_field' );
        my $html_text_field = $q->param( 'html_text_field' );
        my $html_more_field = $q->param( 'html_more_field' );
        my $html_expt_field = $q->param( 'html_expt_field' );
        my $html_kywd_field = $q->param( 'html_kywd_field' );
        my $title_regex = $q->param( 'title_regex' );
        my $text_regex = $q->param( 'text_regex' );
        my $more_regex = $q->param( 'more_regex' );
        my $expt_regex = $q->param( 'expt_regex' );
        my $kywd_regex = $q->param( 'kywd_regex' );
        my $html_extensions = $q->param( 'html_extensions' );
        my $start_end_separator = $q->param( 'start_end_separator' );
        my $html_overwrite = $q->param( 'html_overwrite' );
        my $html_import_root = $q->param( 'html_import_root' );
        my $html_exclude_root = $q->param( 'html_exclude_root' );
        my $entry_class = $q->param( 'entry_class' );
        my $create_folder = $q->param( 'create_folder' );
        my $all_cats = $q->param( 'all_cats' );
        my $encoding = $q->param( 'encoding' );
        $plugin->set_config_value( 'html_save_settings', 1, 'blog:' . $blog_id );
        $plugin->set_config_value( 'html_title_field', $html_title_field, 'blog:' . $blog_id );
        $plugin->set_config_value( 'html_text_field', $html_text_field, 'blog:' . $blog_id );
        $plugin->set_config_value( 'html_more_field', $html_more_field, 'blog:' . $blog_id );
        $plugin->set_config_value( 'html_expt_field', $html_expt_field, 'blog:' . $blog_id );
        $plugin->set_config_value( 'html_kywd_field', $html_kywd_field, 'blog:' . $blog_id );
        $plugin->set_config_value( 'title_regex', $title_regex, 'blog:' . $blog_id );
        $plugin->set_config_value( 'text_regex', $text_regex, 'blog:' . $blog_id );
        $plugin->set_config_value( 'more_regex', $more_regex, 'blog:' . $blog_id );
        $plugin->set_config_value( 'expt_regex', $expt_regex, 'blog:' . $blog_id );
        $plugin->set_config_value( 'kywd_regex', $kywd_regex, 'blog:' . $blog_id );
        $plugin->set_config_value( 'start_end_separator', $start_end_separator, 'blog:' . $blog_id );
        $plugin->set_config_value( 'html_extensions', $html_extensions, 'blog:' . $blog_id );
        $plugin->set_config_value( 'html_overwrite', $html_overwrite, 'blog:' . $blog_id );
        $plugin->set_config_value( 'html_import_root', $html_import_root, 'blog:' . $blog_id );
        $plugin->set_config_value( 'html_exclude_root', $html_exclude_root, 'blog:' . $blog_id );
        $plugin->set_config_value( 'entry_class', $entry_class, 'blog:' . $blog_id );
        $plugin->set_config_value( 'create_folder', $create_folder, 'blog:' . $blog_id );
        $plugin->set_config_value( 'all_cats', $all_cats, 'blog:' . $blog_id );
        $plugin->set_config_value( 'encoding', $encoding, 'blog:' . $blog_id );
    }
    if ( $html_do_realtime ) {
        my $do = do_import( $app, $tmp_file, 0, $import_root );
        return $do;
    } else {
        print $plugin->translate( 'Import settings saved, Do import when run-periodic-tasks.' );
        return 1;
    }
}

sub do_import {
    my ( $app, $file, $is_task, $import_root ) = @_;
    my $plugin = MT->component( 'PowerImporter' );
    my ( $blog, $blog_id, $author_id );
    if ( $file =~ /([0-9]{1,})_([0-9]{1,})_.*pimpt/ ) {
        $blog_id   = $1;
        $author_id = $2;
    } else {
        return 0;
    }
    if ( $is_task ) {
        $blog = MT::Blog->load( { id => $blog_id } );
    } else {
        $blog = current_blog( $app );
    }
    my $scope = 'blog:' . $blog_id;
    my $title_field = $is_task ? $plugin->get_config_value( 'html_title_field', $scope ) : $app->param( 'html_title_field' );
    my $text_field = $is_task ? $plugin->get_config_value( 'html_text_field', $scope ) : $app->param( 'html_text_field' );
    my $more_field = $is_task ? $plugin->get_config_value( 'html_more_field', $scope ) : $app->param( 'html_more_field' );
    my $expt_field = $is_task ? $plugin->get_config_value( 'html_expt_field', $scope ) : $app->param( 'html_expt_field' );
    my $kywd_field = $is_task ? $plugin->get_config_value( 'html_kywd_field', $scope ) : $app->param( 'html_kywd_field' );
    my $entry_class = $is_task ? $plugin->get_config_value( 'entry_class', $scope ) : $app->param( 'entry_class' );
    my $overwrite = $is_task ? $plugin->get_config_value( 'html_overwrite', $scope ) : $app->param( 'html_overwrite' );
    my $create_folder = $is_task ? $plugin->get_config_value( 'create_folder', $scope ) : $app->param( 'create_folder' );
    my $all_cats = $is_task ? $plugin->get_config_value( 'all_cats', $scope ) : $app->param( 'all_cats' );
    my $encoding = $is_task ? $plugin->get_config_value( 'encoding', $scope ) : $app->param( 'encoding' );
    my $title_regex = $is_task ? $plugin->get_config_value( 'title_regex', $scope ) : $app->param( 'title_regex' );
    my $text_regex = $is_task ? $plugin->get_config_value( 'text_regex', $scope ) : $app->param( 'text_regex' );
    my $more_regex = $is_task ? $plugin->get_config_value( 'more_regex', $scope ) : $app->param( 'more_regex' );
    my $expt_regex = $is_task ? $plugin->get_config_value( 'expt_regex', $scope ) : $app->param( 'expt_regex' );
    my $kywd_regex = $is_task ? $plugin->get_config_value( 'kywd_regex', $scope ) : $app->param( 'kywd_regex' );
    my $start_end_separator = $is_task ? $plugin->get_config_value( 'start_end_separator', $scope ) : $app->param( 'start_end_separator' );
    $entry_class = 'page' unless $entry_class;
    my $cat_class = $entry_class eq 'page' ? 'folder' : 'category';
    my $site_path = site_path( $blog );
    my $site_url = site_url( $blog );
    my $sep = '/';
    if ( is_windows() ) {
        $sep = '\\';
        if ( $site_path !~ m/\\$/ ) {
            $site_path .= '\\';
        }
    }
    my $q_site_path = quotemeta( $site_path );
    my $fmgr = MT::FileMgr->new( 'Local' ) or die MT::FileMgr->errstr;
    local *FH;
    open ( FH, $file );
    while ( <FH> ) {
        my $path = $_;
        chomp $path;
        if ( -f $path ) {
            my $permalink = $path;
            $permalink =~ s/^$q_site_path/$site_url/;
            my $data = $fmgr->get_data( $path, 'upload' );
            if ( $encoding ) {
                my $guessed_encoding = $encoding eq 'guess' ? MT::I18N::guess_encoding( $data ) : $encoding;
                $data = MT::I18N::encode_text( $data, $guessed_encoding, undef );
            }
            my $title = get_field( $data, $title_field, $title_regex, $start_end_separator );
            my $text = get_field( $data, $text_field, $text_regex, $start_end_separator );
            my $text_more = get_field( $data, $more_field, $more_regex, $start_end_separator );
            my $excerpt = get_field( $data, $expt_field, $expt_regex, $start_end_separator );
            my $keywords = get_field( $data, $kywd_field, $kywd_regex, $start_end_separator );
            my $rel_path = $path;
            $rel_path =~ s/^$q_site_path//;
            if ( is_windows() ) {
                $rel_path =~ s/\//\\/g;
            }
            my ( $name, $dir, $ext ) = fileparse( $rel_path, qr/[A-Za-z]+$/ );
            my $ebasename = $name;
            $ebasename =~ s/\.$//;
            my $regex = quotemeta( $sep );
            my @dirs = split( m!$regex!, $dir );
            my $parent = 0;
            my @cats;
            if ( $create_folder ) {
                for my $basename ( @dirs ) {
                    if ( $basename ) {
                        my $c = MT->model( $cat_class )->get_by_key( { basename => $basename,
                                                                       blog_id => $blog_id,
                                                                       class => $cat_class,
                                                                       parent => $parent,
                                                                      }
                                                                   );
                        unless ( $c->id ) {
                            $c->label( $basename );
                            if ( $entry_class eq 'page' ) {
                                print $plugin->translate( 'Creating new folder (\'[_1]\')...', pre_print( $basename ) );
                            } else {
                                print $plugin->translate( 'Creating new category (\'[_1]\')...', pre_print( $basename ) );
                            }
                            $c->save or die $c->errstr;
                            $app->run_callbacks( 'cms_post_save.' . $cat_class, $app, $c, $c );
                            my $c_id = $c->id;
                            print $plugin->translate( 'ok (ID [_1])', $c_id );
                            print "\n";
                        }
                        push @cats, $c;
                        $parent = $c->id;
                    }
                }
            }
            my @entries = MT::Entry->load( { basename => $ebasename,
                                             blog_id  => $blog_id,
                                             class    => '*',
                                           }
                                         );
            my $entry;
            if ( $overwrite ) {
                if ( @entries ) {
                    for my $e ( @entries ) {
                        if ( $e->permalink eq $permalink ) {
                            if ( $e->class eq $entry_class ) {
                                $entry = $e;
                            }
                        }
                    }
                }
            }
            my $original;
            unless ( defined $entry ) {
                my $class = $entry_class eq 'page' ? MT->model( 'page' ) : MT->model( 'entry' );
                @entries = $class->load( { basename => $ebasename,
                                           blog_id => $blog_id,
                                         }
                                       );
                if ( @entries ) {
                    $entry = grep { $permalink eq $_->permalink } @entries;
                }
                unless ( $entry ) {
                    $entry = $class->new;
                    $entry->basename( $ebasename );
                    $entry->blog_id( $blog_id );
                }
                $entry->convert_breaks( $blog->convert_paras );
                $entry->allow_pings( $blog->allow_pings_default );
                $entry->allow_comments( $blog->allow_comments_default );
            } else {
                $original = $entry->clone;
            }
            $entry->author_id( $author_id );
            unless ( $title ) {
                $plugin->translate( 'Untitled document' );
            }
            $title = get_utf( $title );
            $text = get_utf( $text );
            $text_more = get_utf( $text_more );
            $excerpt = get_utf( $excerpt );
            $keywords = get_utf( $keywords );
            $entry->title( $title );
            $entry->text( $text );
            $entry->text_more( $text_more );
            $entry->excerpt( $excerpt );
            $entry->keywords( $keywords );
            $entry->status( MT::Entry->HOLD() );
            $entry->class( $entry_class );
            $title = encode_html( $title );
            if ( $entry_class eq 'page' ) {
                print $plugin->translate( 'Saving page (\'[_1]\')...', pre_print( $title ) );
            } else {
                print $plugin->translate( 'Saving entry (\'[_1]\')...', pre_print( $title ) );
            }
            unless ( $entry->id ) {
                $entry->atom_id( $entry->make_atom_id() );
            }
            $entry->save or die $entry->errstr;
            my $entry_id = $entry->id;
            print $plugin->translate( 'ok (ID [_1])', $entry_id );
            print "\n";
            if ( $create_folder ) {
                if ( $all_cats && $entry_class eq 'entry' ) {
                    for my $category ( @cats ) {
                        my $p = MT->model( 'placement' )->get_by_key( { category_id => $category->id,
                                                                        entry_id => $entry->id,
                                                                        blog_id => $blog_id,
                                                                      }
                                                                    );
                        $parent == $category->id
                            ? $p->is_primary( 1 )
                            : $p->is_primary( 0 );
                        $p->save or die $p->errstr;
                    }
                } elsif ( $parent ) {
                    my $p = MT->model( 'placement' )->get_by_key( { category_id => $parent,
                                                                    entry_id => $entry->id,
                                                                    blog_id => $blog_id,
                                                                    is_primary => 1,
                                                                  }
                                                                );
                    $p->save or die $p->errstr;
                }
            }
            $app->run_callbacks( 'cms_post_save.' . $entry_class, $app, $entry, $original );
            $app->run_callbacks( 'cms_post_import.' . $entry_class, $app, $entry, $path, $data );
        }
    }
    $fmgr->delete( $file );
    return 1;
}

sub get_field {
    my ( $data, $pattern, $regex, $separator ) = @_;
    my $field;
    if ( $regex ) {
        if ( $data =~ m!$pattern!si ) {
            $field = $1;
        }
    } else {
        $separator = quotemeta( $separator );
        my ( $start, $end ) = split( /$separator/, $pattern );
        if ( $data =~ /$start(.*?)$end/si ) {
            $field = $1;
        }
    }
    return $field;
}

sub error {
    my $msg = shift;
    print "$msg\n";
    print <<JS
    <script type="text/javascript">
        var pbar = document.getElementById('progress-bar');
        pbar.style.display = 'none';
    </script>
JS
}

sub _chopath {
    my $path = shift;
    if ( $path =~ /(.*)\/$/ ) {
        $path = $1;
    }
    if ( is_windows() ) {
        if ( $path =~ /(.*)\\$/ ) {
            $path = $1;
        }
    }
    return $path;
}

sub pre_print {
    my $text = shift;
    my $t = Unicode::Japanese->new( $text, 'utf8' );
    $text = $t->getu();
    return $text;
}

1;