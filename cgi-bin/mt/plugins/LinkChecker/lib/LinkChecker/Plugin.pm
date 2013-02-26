package LinkChecker::Plugin;
#use strict;

use File::Temp qw( tempfile );
use MT::Util qw( encode_html );

use lib qw( addons/PowerCMS.pack/lib );
use PowerCMS::Util qw( is_cms is_windows powercms_files_dir powercms_files_dir_path
                       read_from_file send_mail site_url site_path file_basename );
use LinkChecker::Util;
use LinkChecker::CMS;

sub _cb_ts_rebuild_confirm {
    my ($cb, $app, $tmpl) = @_;
    my $html = <<'MTML';
<__trans_section component="LinkChecker">
<mt:unless name="do_by_task">
        <p class="alert-warning-inline" id="multiple-linkcheck-warning" style="display:none;margin-top:.7em;color:#f90">
        <img src="<mt:var name="static_uri">/images/status_icons/warning.gif" alt="<__trans phrase="Warning">" width="9" height="9" />
            <__trans phrase="Warning: Link check to run across multiple websites/blogs can be done.">
        </p>
</mt:unless>
<p style="margin-top:1em">
    <label id="lc_file-wrapper"><input type="checkbox" id="lc_file" name="lc_file" value="<$mt:var name="lc_file" escape="url"$>" />
    <mt:if name="do_by_task"><__trans phrase="Do link check at next task."><mt:else><__trans phrase="Do link check at rebuilt."></mt:if></label>
</p>
<mt:ifplugin component="PowerCMS">
<mt:unless name="do_by_task">
        <p class="alert-warning-inline" id="linkcheck-multiple-warning" style="display:none;margin-top:.7em;color:#f90">
        <img src="<mt:var name="static_uri">/images/status_icons/warning.gif" alt="<__trans phrase="Warning">" width="9" height="9" />
            <__trans phrase="Warning: Link check can be run on a single website or blog.">
        </p>
<script type="text/javascript">
jQuery(function($) {
  $("#rebuild_all").change(function(e) {
    var $lc_file = $("#lc_file"),
        $wrapper = $("#lc_file-wrapper"),
        $warning = $("#multiple-linkcheck-warning");
    if (!e.target.checked) {
      $wrapper.css("color", "black");
      $lc_file.removeAttr("disabled");
      $warning.hide();
    } else if ($lc_file.attr("checked")) {
      $wrapper.css("color", "gray");
      $lc_file.removeAttr("checked")
              .attr("disabled", "disabled");
      $warning.show();
    }
  });
  $("#lc_file").change(function(e) {
    var $rebuild_all = $("#rebuild_all"),
        $wrapper     = $("#rebuild_all-wrapper"),
        $warning     = $("#linkcheck-multiple-warning");
    if (!e.target.checked) {
      $wrapper.css("color", "black");
      $rebuild_all.removeAttr("disabled");
      $warning.hide();
    } else if ($rebuild_all.attr("checked")) {
      $wrapper.css("color", "gray");
      $rebuild_all.removeAttr("checked")
                  .attr("disabled", "disabled");
      $warning.show();
    }
  });
});
</script>
</mt:unless>
</mt:ifplugin>
</__trans_section>
MTML
    $$tmpl =~ s{
        (<mtapp:setting(?:\s+[^=]+=\s*["'](?:(?<=")[^"]*"|[^']*'))*?
            \s+id\s*=\s*"dbtype".*?)(?=</mtapp:setting>)
    }{$1$html}xs;
}

sub _cb_tp_rebuild_confirm {
    my ( $cb, $app, $param, $tmpl ) = @_;
    return unless LinkChecker::Util::check_plugin_settings();
    my $plugin = MT->component( 'LinkChecker' );
    require File::Temp;
    $param->{ lc_file } = sprintf '%s.log', File::Temp::mktemp( 'XXXXXXXXXXXXXXXXXXXXXX' );
    $param->{ do_by_task } = $plugin->get_config_value( 'do_by_task' );
}

sub _cb_ts_rebuilding {
    my ( $cb, $app, $tmpl ) = @_;
    my $key = 'lc_file';
    $$tmpl =~ s{(?=<mt:if name="([^"]+)">&\1=<mt:var name="\1" escape="url"></mt:if>)}
               {<mt:if name="$key">&$key=<mt:var name="$key" escape="url"></mt:if>};
}

sub _cb_tp_rebuilding {
    my ( $cb, $app, $param, $tmpl ) = @_;
    return unless LinkChecker::Util::check_plugin_settings();
    my $key = 'lc_file';
    $param->{ $key } = $app->param( $key );
}

sub _cb_ts_rebuilt {
    my ( $cb, $app, $tmpl ) = @_;
    $$tmpl =~ s{(?=</mtapp:statusmsg>)}{
<mt:if name="lc_file">
<mt:unless name="do_by_task">
&nbsp;&nbsp;&nbsp;<a target="_blank" href="<mt:var name="script_url" encode_html="1">?__mode=linkcheck&amp;lc_file=<mt:var name="lc_file" encode_html="url">&amp;blog_id=<mt:var name="blog_id" encode_html="1">"><__trans_section component="LinkChecker"><__trans phrase="Do link check."></__trans_section></a>
</mt:unless>
</mt:if>
    };
}

sub _cb_tp_rebuilt {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $plugin = MT->component( 'LinkChecker' );
    $plugin->set_config_value( 'cgipath', $app->base . $app->uri );
    return unless LinkChecker::Util::check_plugin_settings();
    my $lc_file = $app->param( 'lc_file' ) or return;
    $param->{ lc_file } = $lc_file;
    $param->{ do_by_task } = $plugin->get_config_value( 'do_by_task' ) or return;
    my $log = MT->model( 'temporarylog' )->get_by_key( { logfile => $lc_file } );
    $log->blog_id( $app->blog->id );
    $log->save or die $log->errstr;
}

sub _rebuilding {
    my ( $cb, $app, $param, $tmpl ) = @_;
    if ( LinkChecker::Util::check_plugin_settings() ) {
        $param->{ 'lc_file' } = $app->param( 'lc_file' );
    }
}

sub _rebuilt {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $plugin = MT->component( 'LinkChecker' );
    $plugin->set_config_value( 'cgipath', $app->base . $app->uri );
    if ( LinkChecker::Util::check_plugin_settings() ) {
        if ( my $lc_file = $app->param( 'lc_file' ) ) {
            my $do_by_task = $plugin->get_config_value( 'do_by_task' );
            $param->{ 'lc_file' } = $app->param( 'lc_file' );
            $param->{ 'do_by_task' } = $do_by_task;
            if ( $do_by_task ) {
                my $log = MT->model( 'temporarylog' )->get_by_key( { logfile => $lc_file } );
                $log->blog_id( $app->blog->id );
                $log->save or die $log->errstr;
            }
        }
    }
}

sub _add_mail_tmpl {
    my $app = MT->instance;
    my $plugin = MT->component( 'LinkChecker' );
    my $tmpl = MT->model( 'template' )->get_by_key( { identifier => 'notify_linkcheck',
                                                      blog_id => 0,
                                                    }
                                                  );
    if ( $tmpl && $tmpl->id ) {
        return 1;
    }
    my %values;
    $values{ type } = 'email';
    $values{ rebuild_me } = 0;
    my $title = $plugin->translate( 'Movable Type Linkcheck Notification' );
    my $body1 = $plugin->translate( 'Linkcheck report has been build' );
    $body1 .= " '<MTBlogName>[ID:<MTBlogID>]'\n\n";
    $body1 .= '<$mt:var name="linkcheck_result"$>';
    my $body2 = $plugin->translate( 'To access linkcheck report, please click on or cut and paste the following URL into a web browser:' );
    my $body3 = '<$mt:var name="linkcheck_url"$>';
    my $body4 = '<$mt:Include module="' . $plugin->translate( 'Mail Footer' ) . '"$>';
    my $body = "$title\n$body1\n\n$body2\n\n$body3\n\n$body4";
    $values{ text } = $body;
    $values{ name } = $plugin->translate( 'Notify Link Check' );
    $values{ identifier } = 'notify_linkcheck';
    $tmpl->set_values( \%values );
    $tmpl->save
        or die $tmpl->errstr;
    return 1;
}

sub _link_check_task {
    my $app = MT->instance();
    my $plugin = MT->component( 'LinkChecker' );
    unless ( $plugin->get_config_value( 'do_by_task' ) ) {
        return;
    }
    my @logs = MT->model( 'temporarylog' )->load();
    my ( $res, %blogs );
    for my $log ( @logs ) {
        my $blog_id = $log->blog_id;
        my $blog;
        if ( $blogs{ $blog_id } ) {
            $blog = $blogs{ $blog_id };
        } else {
            $blog = MT::Blog->load( $blog_id );
            $blogs{ $blog_id } = $blog;
        }
        if ( defined $blog ) {
            my $lc_file = $log->logfile;
            my $tmp_dir = $app->config( 'TempDir' ) || $app->config( 'TmpDir' );
            $tmp_dir =~ s{/$}{};
            my $logfile = File::Spec->catdir( $tmp_dir, $lc_file );
            if ( -f $logfile ) {
                my $do = LinkChecker::CMS::_mode_linkcheck( $app, $blog, $lc_file, 1 );
                if ( $do ) {
                    $res ||= 1;
                    my $script = $plugin->get_config_value( 'cgipath' );
                    unless ( $script ) {
                        $script = $app->config->AdminCGIPath || $app->config->CGIPath;
                        $script = File::Spec->catdir( $script, $app->config->AdminScript );
                    }
                    $script .= '?__mode=linkcheck&lc_file=' . $lc_file . '&blog_id=' . $blog_id;
                    my $mtlog = MT->model( 'log' )->new;
                    my $msg = { message => $do . "  '$script'",
                                level => MT::Log::INFO(),
                                class => 'author',
                                category => 'new',
                                blog_id => $blog_id,
                              };
                    $mtlog->set_values( $msg );
                    $mtlog->save or die $log->errstr;
                    require MT::Template;
                    require MT::Template::Context;
                    my $tmpl = MT->model( 'template' )->load( { identifier => 'notify_linkcheck' } );
                    if ( defined $tmpl ) {
                        my $ctx = MT::Template::Context->new;
                        $ctx->stash( 'blog', $blog );
                        $ctx->stash( 'blog_id', $blog->id );
                        $ctx->{ __stash }->{ vars }->{ linkcheck_url } = $script;
                        $ctx->{ __stash }->{ vars }->{ linkcheck_result } = $do;
                        my $build = MT::Builder->new;
                        my $tokens = $build->compile( $ctx, $tmpl->text )
                                        or return $app->error( $app->translate(
                                            "Parse error: [_1]", $build->errstr) );
                        defined ( my $html = $build->build( $ctx, $tokens ) )
                                        or return $app->error( $app->translate(
                                            "Build error: [_1]", $build->errstr) );
                        my $from = $app->config->EmailAddressMain;
                        my $body; my $subject;
                        if ( $html =~ /^(.*)?\n/ ) {
                            $subject = $1;
                        }
                        if ( $html =~ /^.*?\n(.*)/s ) {
                            $body = $1;
                        }
                        my $to = $plugin->get_config_value( 'notifi_send2' );
                        my $result = send_mail( $from, $to, $subject, $body ) if $to;
                    }
                }
            }
        }
        $log->remove or die $log->errstr;
    }
    return $res;
}

sub _rebuild_confirm {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $plugin = MT->component( 'LinkChecker' );
    my ( $separater, $q_separater ) = LinkChecker::Util::separater;
    if ( LinkChecker::Util::check_plugin_settings() ) {
        my $tmp_dir = $app->config( 'TempDir' ) || $app->config( 'TmpDir' );
        $tmp_dir =~ m{/$};
        my ( $hndl, $tmp_file ) = tempfile( $tmp_dir. $separater . 'XXXXXXXXXXXXXXXXXXXXXX',
                                            SUFFIX => '.log',
                                            UNLINK => 1 );
        $param->{ 'lc_file' } = file_basename( $tmp_file );
        $param->{ 'do_by_task' } = $plugin->get_config_value( 'do_by_task' );
    }
}
sub _build_dynamic {
    my ( $cb, %args ) = @_;
    my $plugin = MT->component( 'LinkChecker' );
    my $app = MT->instance();
    if ( ! is_cms( $app ) ) {
        return 1;
    }
    my $lc_file = $app->param( 'lc_file' )
        or return;
    my $at = $args{ 'ArchiveType' };
    if ( $at eq 'Individual' || $at eq 'Page' ) {
        my $entry = $args{ 'Entry' }
            or return 1;
        my ( $content, $assets ) = MT::Plugin::PowerRevision::_build_entry_xml( $entry );
        if ( $content ) {
            MT->run_callbacks(
                'build_page',
                Context      => $args{ 'Context' },
                context      => $args{ 'Context' },
                ArchiveType  => $at,
                archive_type => $at,
                TemplateMap  => $args{ 'TemplateMap' },
                template_map => $args{ 'TemplateMap' },
                Blog         => $args{ 'Blog' },
                blog         => $args{ 'Blog' },
                Entry        => $entry,
                entry        => $entry,
                FileInfo     => $args{ 'FileInfo' },
                file_info    => $args{ 'FileInfo' },
                PeriodStart  => $args{ 'PeriodStart' },
                period_start => $args{ 'PeriodStart' },
                Category     => $args{ 'Category' },
                category     => $args{ 'Category' },
                RawContent   => \$content,
                raw_content  => \$content,
                Content      => \$content,
                content      => \$content,
                BuildResult  => \$content,
                build_result => \$content,
                Template     => $args{ 'Template' },
                template     => $args{ 'Template' },
                File         => $args{ 'File' },
                file         => $args{ 'File' },
            );
        }
    }
    return 1;
}

sub _linkcheck {
    my ( $cb, %args ) = @_;
    my $plugin = MT->component( 'LinkChecker' );
    my $app = MT->instance();
    if ( ! is_cms( $app ) ) {
        return;
    }
    my $lc_file = $app->param( 'lc_file' )
        or return;
    my $blog = $args{ 'Blog' };
    my $bid = $blog->id;
    my $site_url = site_url( $blog );
    my $site_pth = site_path( $blog );
    my ( $separater, $q_separater ) = LinkChecker::Util::separater;
    if ( is_windows() ) {
        $site_pth =~ s{/}{$separater}g;
    }
    $site_url =~ s{/*$}{/};
    unless ( $site_pth =~ /^.{1,}$q_separater$/ ) {
        $site_pth .= $separater;
    }
    my $site_bse; my $absl_bse = '';
    if ( $site_url =~ m{^((?i:https?)://[^/]+)/(.+)} ) {
        $site_bse = $1;
        $absl_bse = $2;
    } elsif ( $site_url =~ m{^((?i:https?)://[^/]+)/$} ) {
        $site_bse = $1;
    }
    my $content  = $args{ 'Content' };
    my $abs_path = $args{ 'File' };
    return 1 unless LinkChecker::Util::check_exclude( $abs_path );
    my $finfo = $args{ 'FileInfo' };
    my $org_path = $site_bse;
    $org_path =~ s{/+$}{};
    $org_path .= $finfo->url;
    my $org_base = $args{ 'File' };
    my $at = $args{ 'ArchiveType' };
    my $entry = $args{ 'Entry' };
    my $category = $args{ 'Category' };
    my $template = $args{ 'Template' };
    my $oid = 0;
    my $tid = $template->id;
    if ( defined $entry ) {
        $oid = $entry->id;
    }
    if ( defined $category ) {
        $oid = $category->id;
    }
    my $tmp_dir = $app->config( 'TempDir' ) || $app->config( 'TmpDir' );
    $org_base =~ s/(^.*$q_separater).*$/$1/;
    if ( $abs_path =~ /\.\./ ) {
        while ( $abs_path =~ /\.\./ ) {
            $abs_path =~ s/$q_separater[^$q_separater]{1,}?$q_separater\.\.//;
        }
    }
    my $log = File::Spec->catdir( $tmp_dir, $lc_file );
    my $file = file_basename( $abs_path );
    $absl_bse = LinkChecker::Util::slash2backslash( $absl_bse ) if is_windows();
    my $base_pth = $site_pth;
    my $q_absl_bse = $separater . $absl_bse;
    $q_absl_bse = LinkChecker::Util::quotebackslash( $q_absl_bse ) if is_windows();
    $base_pth =~ s/$q_absl_bse$//i;
    my $q_base_pth = $base_pth;
    $q_base_pth = LinkChecker::Util::quotebackslash( $q_base_pth ) if is_windows();
    $abs_path =~ s/$q_base_pth//;
    $abs_path = LinkChecker::Util::backslash2slash( $abs_path ) if is_windows();
    my $match = '<[^>]+\s(src|href|action)\s*=\s*\"';
    my $src = $$content;
    if ( $file =~ /\.php$/i ) {
        $src =~ s/\n<\?php.*?\n\?>//sg;
    }
    $src =~ s/($match)(.*?)(")/$1.&rel2abs($3,$abs_path,$file,$site_bse,$org_path,$org_base,$log,$bid,$oid,$tid,$at).$4/esg;
    $match = '<[^>]+\s(src|href|action)\s*=\s*\'';
    $src =~ s/($match)(.*?)(')/$1.&rel2abs($3,$abs_path,$file,$site_bse,$org_path,$org_base,$log,$bid,$oid,$tid,$at).$4/esg;
}

sub rel2abs {
    my ( $path, $base, $file, $site_bse, $org_path, $org_base, $log, $bid, $oid, $tid, $at ) = @_;
    my $plugin = MT->component( 'LinkChecker' );
    my $app = MT->instance();
    my ( $separater, $q_separater ) = LinkChecker::Util::separater;
    my $abslute_path;
    my $rel_pth;
    if ( $path =~ /^\.\/(.*$)/ ) {
        $path = $1;
    }
    if ( $path =~ /^\./ ) {
        $abslute_path = $org_base . $path;
        $rel_pth = $path;
    } else {
        $path =~ s/^$site_bse//;
        $rel_pth = $path;
        if ( $path =~/^\.\/(.*)/ ) {
            $abslute_path = $org_base . $1;
            $rel_pth = $1;
        } elsif ( $path eq $base ) {
            my @File_pathes = split( /\//,$base );
            my $count = @File_pathes;
            $rel_pth = $File_pathes[ $count-1 ];
            $abslute_path = $org_base . $rel_pth;
        } elsif ( $path =~ /^(?:#|(?:https?|mailto|javascript|tel):)/ ) {
            $rel_pth = $path;
            $abslute_path = '';
            if ( $path =~ m{^(?i:https?)://} ) {
                open ( my $out, ">>$log" ) or die "Can't open $log!";;
                print $out "$at\t$bid\t$oid\t$tid\t$org_path\t$path\tfull\n";
                close ( $out );
            }
            return $path;
        } else {
            #if ( $path =~ /^\./ ) {
            #}
            if ($path =~ m{^/}) {
                $rel_pth = File::Spec->abs2rel( $path, $base );
                my @items;
                if ( is_windows() ) {
                    @items = split( /\\/, $rel_pth );
                } else {
                    @items = split( /\//, $rel_pth );
                }
                my $len = @items; $len--; my $item = $items[ $len ];
                unless ( $item =~ /\./ && $item ne '..' ) {
                    $rel_pth .= '/';
                }
            }
            $rel_pth = LinkChecker::Util::backslash2slash( $rel_pth ) if is_windows();
            $rel_pth =~ s{^\.\./}{};
            $abslute_path = $org_base . $rel_pth if $rel_pth;
        }
        if ( $rel_pth eq '' ) {
            $rel_pth = $file;
            $abslute_path = $org_base . $rel_pth;
        }
        if ( $abslute_path =~ /'/ ) {
            $abslute_path = '';
        }
    }
    $abslute_path =~ s/(^.*)\?.*$/$1/;
    $abslute_path =~ s/(^.*)#.*$/$1/;
    if ( $abslute_path ) {
        if ( $abslute_path =~ /\.\./ ) {
            if ( is_windows() ) {
                $abslute_path =~ s{/}{$separater}g;
            }
            while ( $abslute_path =~ /\.\./ ) {
                $abslute_path =~ s/$q_separater[^$q_separater]{1,}?$q_separater\.\.//;
            }
        }
        if ( is_windows() ) {
            $abslute_path =~ s{/}{$separater}g;
        }
        ### check cgi-bin
        my $cgi_bin = $plugin->get_config_value( 'cgi_bin' );
        if ( $cgi_bin ) {
            my $cgi_rel = $plugin->get_config_value( 'cgi_rel' ) || '';
            my $doc_root = $plugin->get_config_value( 'doc_root' ) || '';
            if ( is_windows() ) {
                $doc_root =~ s/\\+$//;
                $cgi_rel =~ s/^\\+//;
            } else {
                # $cgi_bin =~ s{/+$}{};
                $doc_root =~ s{/+$}{};
                $cgi_rel =~ s{^/+}{};
            }
            my $cgi_base = File::Spec->catfile( $doc_root, $cgi_rel );
            $cgi_base .= $separater;
            unless ( $cgi_bin =~ /^.{1,}$q_separater$/ ) {
                $cgi_bin .= $separater;
            }
            $cgi_base = quotemeta( $cgi_base );
            $abslute_path =~ s/^$cgi_base/$cgi_bin/;
        }
        ### check alias
        my $path_alias = $plugin->get_config_value( 'path_alias' );
        if ( $path_alias ) {
            my @check_path = split( /\n/, $path_alias );
            for my $line ( @check_path ) {
                $line =~ s/\s+//g;
                if ( $line ) {
                    my @items = split( /:(?!\\)/, $line );
                    my $before = quotemeta( $items[ 0 ] );
                    my $after = $items[ 1 ];
                    $abslute_path =~ s/^$before/$after/;
                }
            }
        }
        open ( $out, ">>$log" ) or die "Can't open $log!";;
        print $out $at;
        print $out "\t$bid";
        print $out "\t$oid";
        print $out "\t$tid";
        print $out "\t$org_path";
        print $out "\t$abslute_path";
        print $out "\tabs\n";
        close ( $out );
    }
    return $rel_pth;
}

1;
