package LinkChecker::CMS;
use strict;

use lib qw( addons/PowerCMS.pack/lib );
use PowerCMS::Util qw( powercms_files_dir powercms_files_dir_path 
                       site_url site_path current_blog current_user is_windows
                     );
use MT::I18N qw( substr_text length_text );
use MT::Util qw( encode_html decode_url );
use LinkChecker::Util;

sub _mode_linkcheck {
    my ( $app, $blog, $lc_file, $is_task ) = @_;
    my $plugin = MT->component( 'LinkChecker' );
    require LWP::Simple;
    require MT::FileInfo;
    require MT::FileMgr;
    my $user = current_user( $app );
    unless ( $lc_file ) {
        unless ( defined $app->blog ) {
            return $app->redirect( $app->base . $app->uri );
        }
        unless ( LinkChecker::Util::can_link_check( $app->blog, $user ) ) {
            return $app->error( $app->translate( "Permission denied." ) );
        }
        $lc_file = $app->param( 'lc_file' );
    }
    $lc_file =~ s/\///g;
    $lc_file =~ s/\.//g;
    $lc_file =~ s/log$/.log/;
    my $cms_blog_id;
    unless ( defined $blog ) {
        $blog = current_blog( $app );
        $cms_blog_id = $blog->id;
    }
    if ( ! $lc_file && ! $is_task ) {
        $app->redirect( $app->base . $app->uri( args => { blog_id => $cms_blog_id } ) );
    }
    my $innerlink = $plugin->get_config_value( 'innerlink' );
    my $outlink = $plugin->get_config_value( 'outlink' );
    my $index = $plugin->get_config_value( 'index' );
    my $is_error = $plugin->get_config_value( 'is_error' );
    my @indexes = split( /\s*,\s*/, $index );
    my $site_pth = site_path( $blog );
    my $site_url = site_url( $blog );
    my ( $separater, $q_separater ) = LinkChecker::Util::separater;
    if ( is_windows() ) {
        $site_pth =~ s/\//$separater/g;
    }
    if ( $site_pth =~ /(^.{1,})$q_separater$/ ) {
        $site_pth = $1;
    }
    if ( $site_url =~ /(^.{1,})$q_separater$/ ) {
        $site_url = $1;
    }
    my $q_site_pth = quotemeta( $site_pth );
    my $doc_root = $plugin->get_config_value( 'doc_root' );
    my $q_doc_root = quotemeta( $doc_root );
    my $doc_root_url = site_url( $blog );
    $doc_root_url =~ s!(https?://.*?)/.*!$1!;
    my %param;
    $app->{ plugin_template_path } = File::Spec->catdir( $plugin->path, 'tmpl' );
    my $ltmpl = 'linkchecker.tmpl';
    if ( my $powercms_files_dir = powercms_files_dir() ) {
        my $fmgr = MT::FileMgr->new( 'Local' ) or die MT::FileMgr->errstr;
        my $report_dir = File::Spec->catdir( $powercms_files_dir, 'report' );
        unless ( $fmgr->exists( $report_dir ) ) {
            $fmgr->mkpath( $report_dir );
        }
        my $outfile = File::Spec->catfile( $report_dir, $lc_file );
        if ( -f $outfile ) {
            return 1 if $is_task;
            my $html = $fmgr->get_data( $outfile );
            my $mt_script = quotemeta( '<mt:var name="script_url">' );
            my $appurl = $app->uri;
            $html =~ s/$mt_script/$appurl/g;
            $param{ 'page_title' } = $plugin->translate( 'Link Check' );
            $param{ 'build_report' } = $html;
            return $app->build_page( $ltmpl, \%param );
        }
        my $tmp_dir = $app->config( 'TempDir' ) || $app->config( 'TmpDir' );
        $tmp_dir =~ s/\/$//;
        my $log = File::Spec->catdir( $tmp_dir, $lc_file );
        my $err = 0;
        my $err_file = 0;
        my @tmpl_loop; my $odd = 1;
        my $table_open = '<table><tr class=""><th colspan="2" class="primary" style="padding:7px;">';
        my $table_close = '</td></tr></table>';
        my $file_err;
        my $err_in_file;
        my $files;
        my $checked;
        my %outlink;
        if ( -f $log ) {
            local *FH;
            open( FH, $log );
            my $org_url = '';
            my $url_rep;
            my $status_line;
            while( <FH> ){
                my $line = $_;
                chomp $line;
                my @items = split( /\t/,  $line );
                my $at = $items[ 0 ];
                my $blog_id = $items[ 1 ];
                my $object_id = $items[ 2 ];
                my $template_id = $items[ 3 ];
                my $class = $items[ 6 ];
                my $url = $items[ 4 ];
                my $sub_url = $url;
                my $line_err;
                $sub_url = substr_text( $sub_url, 0, 77 ) . ( length_text( $sub_url ) > 77 ? "..." : "" );
                my $url_encoded = encode_html( $url );
                my $url_link = "<a href=\"$url_encoded\" target=\"_blank\">$sub_url</a>";
                my $edit_link = '<mt:var name="script_url">?__mode=view&amp;_type=';
                if ( $at eq 'Individual' ) {
                    $at = $plugin->translate( $at );
                    $edit_link .= 'entry&amp;id=' . $object_id . '&amp;blog_id=' . $blog_id;
                    $edit_link = " <a href=\"$edit_link\" target=\"_blank\">($at)</a> <MSG>";
                    $url_link .= $edit_link;
                } elsif ( $at eq 'Page' ) {
                    $at = $plugin->translate( $at );
                    $edit_link .= 'page&amp;id=' . $object_id . '&amp;blog_id=' . $blog_id;
                    $edit_link = " <a href=\"$edit_link\" target=\"_blank\">($at)</a> <MSG>";
                    $url_link .= $edit_link;
                } else {
                    $at = $plugin->translate( $at );
                    $edit_link .= 'template&amp;id=' . $template_id . '&amp;blog_id=' . $blog_id;
                    $edit_link = " <a href=\"$edit_link\" target=\"_blank\">($at)</a> <MSG>";
                    $url_link .= $edit_link;
                }
                my $link = $items[ 5 ];
                my $path = $link;
                $path =~ s/^$q_site_pth/$site_url/;
                if ( $path =~ /^$q_separater/ ) {
                    $path =~ s/$q_doc_root/$doc_root_url/;
                }
                my $sub_path = $path;
                $sub_path = substr_text( $sub_path, 0, 88 ) . ( length_text( $sub_path ) > 88 ? "..." : "" );
                my $path_encoded = encode_html( $path );
                $path = "<a href=\"$path_encoded\" target=\"_blank\">$sub_path</a>";
                if ( $org_url ne $url ) {
                    if ( $url_rep ) {
                        my $msg;
                        if ( $err_in_file ) {
                            $msg = $plugin->translate( '([_1] error found in a file.)', $err_in_file );
                            $msg = "<strong style=\"color:red\">$msg</strong>";
                        } else {
                            $msg = $plugin->translate( '(No error found in a file.)' );
                        }
                        $url_rep =~ s/<MSG>/$msg/;
                        $url_rep .= $table_close;
                        if ( ( $is_error && $err_in_file ) || ! $is_error ) {
                            push( @tmpl_loop, { url_report => $url_rep,
                                                odd => $odd,
                                              },
                                );
                            $odd = $odd ? 0 : 1;
                        }
                        $param{ 'report' } = 1;
                    }
                    my $to = $table_open;
                    my $style = $odd ? 'odd' : 'even';
                    $to =~ s/""/"$style"/;
                    $url_rep = $to . $url_link . '</th></tr>';
                    if ( $file_err ) {
                        $err_file++;
                    }
                    $file_err = 0;
                    $err_in_file = 0;
                    $files++;
                }
                my $check = '<strong style="color:red">' . $plugin->translate( 'Not Found.' ) .'</strong>';
                if ( $class eq 'abs' && $innerlink ) {
                    my $exist;
                    if ( -f $link ) {
                        $exist = 1;
                    } elsif ( $link =~ /^.*$q_separater(.*%+.*)$/ ) {
                        my $filename = $1;
                        if ( $filename = decode_url( $filename ) ) {
                            $link =~ s/^(.*$q_separater).*%+.*$/$1$filename/;
                            if ( -f $link ) {
                                $exist = 1;
                            }
                        }
                    } else {
                        if ( $link =~ /\/$/ || $link =~ /\\$/ ) {
                            for my $idx ( @indexes ) {
                                my $tmp = $link;
                                $tmp .= $idx;
                                if ( -f $tmp ) {
                                    $exist = 1;
                                    last;
                                }
                            }
                        }
                    }
                    if ( $exist ) {
                        $check = 'OK';
                    } else {
                        my $fi = MT::FileInfo->load( { file_path => $link,
                                                       virtual => 1,
                                                     }
                                                   );
                        if ( defined $fi ) {
                            $check = $plugin->translate( 'OK (dynamic)' );
                        } else {
                            $err++;
                            $file_err = 1;
                            $err_in_file++;
                            $path = "<strong style=\"color:red\">$path</strong>";
                            $line_err = 1;
                        }
                    }
                } elsif ( $class eq 'full' && $outlink )  {
                    if ( $outlink{ $link } ) {
                        if ( $outlink{ $link } eq 'OK' ) {
                            $check = 'OK';
                        } elsif ( $outlink{ $link } eq 'BAD' ) {
                            $err++;
                            $file_err = 1;
                            $err_in_file++;
                            $path = "<strong style=\"color:red\">$path</strong>";
                            $line_err = 1;
                        }
                    } else {
                        if ( $is_task ) {
                            sleep 1;
                        }
                        if ( LWP::Simple::head( $link ) ) {
                            $outlink{ $link } = 'OK';
                            $check = 'OK';
                        } else {
                            my $ua = MT->new_ua( { agent => ( MT->config->LinkCheckerUserAgent || 'Mozilla/5.0 (LinkChecker 1.0 X_FORWARDED_FOR:)' ) } );
                            my $response = $ua->head( $link );
                            if ( $response->is_success ) {
                                $outlink{ $link } = 'OK';
                                $check = 'OK';
                            } else {
                                $status_line = $response->status_line if defined $response;
                                $err++;
                                $file_err = 1;
                                $err_in_file++;
                                $outlink{ $link } = 'BAD';
                                $path = "<strong style=\"color:red\">$path</strong> ($status_line)";
                                $line_err = 1;
                            }
                        }
                    }
                }
                if ( ( $class eq 'abs' && $innerlink ) || ( $class eq 'full' && $outlink ) ) {
                    $checked++;
                    if ( ( $is_error && $line_err ) || ! $is_error ) {
                        my $lstyle = $odd ? 'odd' : 'even';
                        $url_rep .= "<tr class=\"$lstyle\"><td class=\"primary\" style=\"padding:7px;\">&nbsp;&nbsp;&nbsp;&nbsp; $path</td><td width=\"130\" style=\"padding:7px;\">$check</td></tr>\n";
                    }
                }
                $org_url = $url;
            }
            if ( $url_rep ) {
                my $lmsg;
                if ( $err_in_file ) {
                    $lmsg = $plugin->translate( '([_1] error found in a file.)', $err_in_file );
                    $lmsg = "<strong style=\"color:red\">$lmsg</strong>";
                } else {
                    $lmsg = $plugin->translate( '(No error found in a file.)' );
                }
                $url_rep =~ s/<MSG>/$lmsg/;
                $url_rep .= $table_close;
                if ( ( $is_error && $err_in_file ) || ! $is_error ) {
                    push( @tmpl_loop, { url_report => $url_rep,
                                       odd => $odd,
                                      },
                        );
                    $odd = $odd ? 0 : 1;
                }
                if ( $file_err ) {
                    $err_file++;
                }
            }
        } else {
            $param{ 'error' } = $plugin->translate( 'Log file was not found.' );
        }
        unless ( $param{ 'error' } ) {
            unless ( $err ) {
                $param{ 'page_msg' } = $plugin->translate( 'Check [_1] files ([_2] links). ', $files, $checked );
                $param{ 'page_msg' } .= $plugin->translate( 'No error found.' );
                if ( $is_error ) {
                    $param{ 'report' } = 0;
                }
            } else {
                $param{ 'error' } = $plugin->translate( 'Check [_1] files ([_2] links). ', $files, $checked );
                $param{ 'error' } .= $plugin->translate( '[_1] error found in [_2] files.', $err, $err_file );
            }
        }
        unless ( $is_task ) {
            $param{ 'tmpl_loop' } = \@tmpl_loop;
            if ( ! $param{ 'report' } && @tmpl_loop ) {
                $param{ 'report' } = 1;
            }
            $param{ 'page_title' } = $plugin->translate( 'Link Check' );
            $param{ 'result_label' } = $plugin->translate( 'Link check result' );
            my $tmpl = 'linkchecker_table.tmpl';
            my $data = $app->build_page( $tmpl, \%param );
            my $old = quotemeta( '<mt:var name="script_url">' );
            my $surl = $app->uri;
            $data =~ s/$old/$surl/g;
            if ( -f $log ) {
                $data =~ s/\n{1,}/\n/g;
                $fmgr->put_data( $data, "$outfile.new" );
                $fmgr->rename( "$outfile.new", $outfile );
                unlink $log;
            }
            $tmpl = 'linkchecker.tmpl';
            $param{ 'build_report' } = $data;
            return $app->build_page( $tmpl, \%param );
        } else {
            my $res = '';
            my $task_tmpl = File::Spec->catdir( $plugin->path, 'tmpl', 'linkchecker_table_task.tmpl' );
            my $thtml = $fmgr->get_data( $task_tmpl );
            for my $tmpl_line ( @tmpl_loop ) {
                my $url_report = $tmpl_line->{ url_report };
                my $cell = $tmpl_line->{ odd };
                my $cstyle = $cell ? 'odd' : 'even';
                $res .= <<MTML;
            <tr class="$cstyle">
                <td>$url_report</td>
            </tr>
MTML
            }
            my $page_msg = '';
            my $check_result;
            if ( $param{ 'page_msg' } ) {
                $page_msg = '<div id="saved-changes" class="msg msg-success">';
                $page_msg .= $param{ 'page_msg' } . '</div>';
                $check_result = $param{ 'page_msg' };
            }
            my $tag = quotemeta( '<$mt:var name="page_msg"$>' );
            $thtml =~ s/$tag/$page_msg/g;
            my $error = '';
            if ( $param{ 'error' } ) {
                $error = '<div id="generic-error" class="msg msg-error">';
                $error .= $param{ 'error' } . '</div>';
                $check_result = $param{ 'error' };
            } else {
                if ( $is_error ) {
                    $tag = quotemeta( '<div id="main-content"><div id="main-content-inner" class="inner pkg">' );
                    my $tag_end = quotemeta( '</div></div>' );
                    $thtml =~ s/$tag.*$tag_end//s;
                }
            }
            $tag = quotemeta( '<$mt:var name="error"$>' );
            $thtml =~ s/$tag/$error/g;
            my $result_label = $plugin->translate( 'Link check result' );
            $tag = quotemeta( '<$mt:var name="result_label"$>' );
            $thtml =~ s/$tag/$result_label/g;
            $tag = quotemeta( '<$mt:var name="result_table"$>' );
            $thtml =~ s/$tag/$res/g;
            return $check_result;
        }
    } else {
        $param{ 'page_title' } = $plugin->translate( 'PowerCMS directory was not found.' );
        $param{ 'error' } = $plugin->translate( 'Files for PowerCMS Directory unexists. Please make directory [_1], and give enough permission to write from web server.', powercms_files_dir_path() );
        return $app->build_page( $ltmpl, \%param );
    }
}

1;
