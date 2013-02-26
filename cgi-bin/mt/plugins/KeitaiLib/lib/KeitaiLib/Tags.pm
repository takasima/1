package KeitaiLib::Tags;

use strict;

use KeitaiLib::EmojiUnicode qw( get_docomo get_au get_softbank get_icon emoticon2docomo_id );
use KeitaiLib::EmojiLegacy  qw( get_docomo_legacy get_au_legacy );

use MT::Util qw( trim encode_html );
use lib qw( addons/PowerCMS.pack/lib );
use PowerCMS::Util qw( site_path site_url path2url path2relative utf8_off utf8_on convert_gif_png
                       file_extension is_application write2file copy_item get_agent save_asset
                       is_ua_keitai is_ua_iPhone is_ua_iPad is_ua_mobile is_ua_Android convert2thumbnail );

our $plugin_keitailib = MT->component( 'KeitaiLib' );

sub _hdlr_emoticon_size {
    my $plugin_keitailib = MT->component( 'KeitaiLib' );
    return $plugin_keitailib->get_config_value( 'emoticon_size' );
}

sub _hdlr_get_emoji {
    my ( $ctx, $args, $cond ) = @_;
    my $charset = $args->{ charset };
    $charset = 'unicode' unless $charset;
    if ( $charset eq 'unicode' ) {
        return _hdlr_get_emoji_unicode( $ctx, $args, $cond );
    } elsif ( $charset eq 'regacy' ) {
        return _hdlr_get_emoji_legacy( $ctx, $args, $cond );
    } elsif ( $charset eq 'legacy' ) {
        return _hdlr_get_emoji_legacy( $ctx, $args, $cond );
    } elsif ( $charset eq 'emoticon' ) {
        return _hdlr_get_emoticon( $ctx, $args, $cond );
    }
}

sub _hdlr_get_emoticon {
    my ( $ctx, $args, $cond ) = @_;
    my $docomo_id = $args->{ docomo_id };
    my $require_alt = $args->{ emoticon };
    my $base = $args->{ base };
    unless ( $base ) {
        $base = MT->config->StaticWebPath . '/plugins/KeitaiLib/images/';
    }
    my $size = $args->{ size };
    $size = '12' unless $size;
    $base .= $size . '/';
    my $emoji = get_icon( $docomo_id );
    my ( $alt, $icon ) = split( /,/, $emoji );
    if ( $alt ) {
        $alt = utf8_on( $alt );
    }
    if ( $icon ) {
        if (! $require_alt ) {
            $alt = '';
        }
        return "<img alt=\"$alt\" src=\"$base$icon\" width=\"$size\" height=\"$size\" />";
    } else {
        if ( $require_alt ) {
            return "[$alt]";
        } else {
            return '';
        }
    }
    return '';
}

sub _hdlr_get_emoji_unicode {
    my ( $ctx, $args, $cond ) = @_;
    my $docomo_id = $args->{ docomo_id };
    my $app = MT->instance();
    my $emoji;
    my $agent = $app->get_header( 'User-Agent' );
    if ( $agent =~ /DoCoMo/ ) {
        $emoji = get_docomo( $docomo_id );
    } elsif ( $agent =~ /UP\.Browser/ ) {
        $emoji = get_au( $docomo_id );
    } elsif ( ( $agent =~ /SoftBank/ ) || ( $agent =~ /Vodafone/ ) ) {
        $emoji = get_softbank( $docomo_id );
    } else {
        return _hdlr_get_emoticon( $ctx, $args, $cond );
    }
    if ( $emoji =~ /^E/ ) {
        $emoji = "&#x$emoji;";
    }
    return $emoji;
}

sub _hdlr_get_emoji_legacy {
    my ( $ctx, $args, $cond ) = @_;
    my $docomo_id = $args->{ docomo_id };
    my $app = MT->instance();
    my $emoji;
    my $agent = $app->get_header( 'User-Agent' );
    if ( $agent =~ /DoCoMo/ ) {
        $emoji = get_docomo_legacy( $docomo_id );
    } elsif ( $agent =~ /UP\.Browser/ ) {
        $emoji = get_au_legacy( $docomo_id );
    } elsif ( ( $agent =~ /SoftBank/ ) || ( $agent =~ /Vodafone/ ) ) {
        $emoji = get_softbank( $docomo_id );
        if ( $emoji =~ /^E/ ) {
            $emoji = "&#x$emoji;";
        }
    } else {
        return _hdlr_get_emoticon( $ctx, $args, $cond );
    }
    return $emoji;
}

sub _hdlr_convert_sjis {
    my ( $ctx, $args, $cond ) = @_;
    my $z2h = $args->{ 'z2h' };
    my $tokens = $ctx->stash( 'tokens' );
    my $builder = $ctx->stash( 'builder' );
    my $app = MT->instance;
    my $res = $builder->build( $ctx, $tokens, $cond );
    my $charset = $app->{ cfg }->PublishCharset;
    my $encoding = lc ( $charset );
    $encoding =~ s/[\-_]//g;
    $res = _filter_z2h( $res, $encoding ) if $z2h;
    # $app->config( 'PublishCharset', 'Shift_JIS' );
    return $res;
}

sub _hdlr_strip_linefeeds {
    my ( $ctx, $args, $cond ) = @_;
    my $tokens = $ctx->stash( 'tokens' );
    my $builder = $ctx->stash( 'builder' );
    my $res = $builder->build( $ctx, $tokens, $cond );
    $res =~ tr(\r\n)()d;
    return $res;
}

sub _hdlr_if_keitai {
    my ( $ctx, $args, $cond ) = @_;
    my $app = MT->instance();
    return is_ua_keitai( $app );
}

sub _hdlr_if_smartphone {
    my ( $ctx, $args, $cond ) = @_;
    my $app = MT->instance();
    # return 1 if _hdlr_if_android( @_ );
    # return 1 if _hdlr_if_iphone( @_ );
    my $exclude = $args->{ exclude };
    if ( $exclude ) {
        $exclude = lc( $exclude );
        if ( $exclude eq 'tablet' ) {
            if ( get_agent( $app, 'Tablet' ) ) {
                return 0;
            }
        }
    }
    return get_agent( $app, 'Smartphone' );
}

sub _hdlr_if_tablet {
    my ( $ctx, $args, $cond ) = @_;
    my $app = MT->instance();
    return get_agent( $app, 'Tablet' );
}

sub _hdlr_if_pc {
    my ( $ctx, $args, $cond ) = @_;
    my $app = MT->instance();
    return get_agent( $app ) eq 'PC'
        ? 1 : 0;
}

sub _hdlr_if_iphone {
    my $app = MT->instance();
    return is_ua_iPhone( $app );
}

sub _hdlr_if_ipad {
    my $app = MT->instance();
    return is_ua_iPad( $app );
}

sub _hdlr_if_android {
    my $app = MT->instance();
    return is_ua_Android( $app );
}

sub _hdlr_if_mobile {
    my $app = MT->instance();
    return is_ua_mobile( $app );
}

sub _hdlr_keitai_content {
    my ( $ctx, $args, $cond ) = @_;
    my $app = MT->instance();
    my $page = $ctx->stash( 'current_archive_number' );
    if ( is_application( $app ) ) {
        $page = $app->param( 'page' ) unless $page;
    }
    $page = 1 unless $page;
    my $file_fi = $ctx->stash( 'current_file_info' );
    $ctx->stash( '_split_start_tag', $args->{ start_tag } );
    $ctx->stash( '_keitai_size', $args->{ size } ); #  * 1024
    $ctx->stash( '_keitai_current', $page );
    $ctx->stash( '_static', $args->{ static } );
    my $tokens  = $ctx->stash( 'tokens' );
    my $builder = $ctx->stash( 'builder' );
    my $content = $builder->build( $ctx, $tokens, $cond );
    if ( $file_fi ) {
        if ( $page == 1 ) {
            require MT::FileInfo;
            my @finfos = MT::FileInfo->load( { original_fi_id => $file_fi->id, } );
            my $build_count = $ctx->stash( '_keitai_page_count' );
            if ( ( $build_count - 1 ) < scalar ( @finfos ) ) {
                for my $finfo ( @finfos ) {
                    if ( $finfo->keitai_counter > $build_count ) {
                        my $file_path = $finfo->file_path;
                        if ( -f $file_path ) {
                            unlink $file_path;
                        }
                        $finfo->remove or die $finfo->errstr;
                    }
                }
            }
        }
    }
    return $content;
}

sub _hdlr_keitai_contentpagelist {
    my ( $ctx, $args, $cond ) = @_;
    my $tokens  = $ctx->stash( 'tokens' );
    my $builder = $ctx->stash( 'builder' );
    my $pages = $ctx->stash( '_keitai_page_count' );
    my $glue = $args->{ glue };
    my $res = '';
    for ( 1 .. $pages ) {
        $ctx->stash( '_list_counter', $_ );
        my $out = $builder->build( $ctx, $tokens,  {
                %$cond,
                lc ( 'KeitaiContentPageListHeader' ) => $_ == 1,
                lc ( 'KeitaiContentPageListFooter' ) => $_ == $pages,
            } );
        if (! defined( $out ) ) { return $ctx->error( $builder->errstr ) };
        $res .= $out;
        $res .= $glue if ( $glue && ( $_ != $pages ) );
    }
    $res;
}

sub _hdlr_pass_tokens {
    my ( $ctx, $args, $cond ) = @_;
    $ctx->stash( 'builder' )->build( $ctx, $ctx->stash( 'tokens' ), $cond );
}

sub _hdlr_keitai_contentbody {
    my ( $ctx, $args, $cond ) = @_;
    my $plugin_keitailib = MT->component( 'KeitaiLib' );
    my $app = MT->instance();
    my $tokens = $ctx->stash( 'tokens' );
    my $builder = $ctx->stash( 'builder' );
    my $file_fi = $ctx->stash( 'current_file_info' );
    my $content = $builder->build( $ctx, $tokens, $cond );
    return $content unless $file_fi;
    $content = trim ( $content );
    my $start_tag = $ctx->stash( '_split_start_tag' );
    my $size      = $ctx->stash( '_keitai_size' );
    my $static    = $ctx->stash( '_static' );
    my $page      = $ctx->stash( '_keitai_current' );
    $ctx->stash( 'current_archive_number', $page );
    my $file_tmpl = $ctx->stash( 'current_file_template' );
    my $file_ctx  = $ctx->stash( 'current_file_ctx' );
    my $file_args = $ctx->stash( 'current_file_args' );
    my $basename_prefix = $plugin_keitailib->get_config_value( 'basename_prefix' );
    $page--;
    my $body_len = do { use bytes; length $content; };
    my $pager = 1;
    if ( $body_len <= $size ) {
        $pager = 0;
    }
    my $regex;
    if ( $start_tag =~ /^</ ) {
        $start_tag = quotemeta( $start_tag );
        $regex = qr/$start_tag/;
    } else {
        $regex = qr/<$start_tag.*?>/;
    }
    my @paragraphs = split( /$regex/i, $content );
    my @new_paragraphs;
    for my $para ( @paragraphs ) {
        push ( @new_paragraphs, $para ) if $para;
    }
    @paragraphs = @new_paragraphs;
    if (! scalar( @paragraphs ) ) {
        $pager = 0;
    }
    $ctx->stash( '_keitai_page_count', 1 ) unless $pager;
    return $content unless $pager;
    my $continue = "";
    my $i = 0;
    my $contents;
    require MT::Request;
    my $r = MT::Request->instance;
    $contents = $r->cache( 'keitai_content_id:' . $file_fi->id );
    unless ( $contents ) {
        my $last;
        for my $tag ( $content =~ m/($regex)/isg ) {
            $last = $tag;
            my $buf = $continue . $tag . $paragraphs[ $i ];
            my $str_len = do { use bytes; length $buf; };
            if ( ( $str_len > $size ) && $continue && ( $buf !~ /^$regex$/ ) ) {
                $content = $continue;
                push ( @$contents, $content );
                $continue = $tag . $paragraphs[ $i ];
            } else {
                $continue = $buf;
            }
            $i++;
        }
        if ( $continue ) {
            push ( @$contents, $continue );
        }
        if ( $paragraphs[ $i ] ) {
            push ( @$contents, $last . $paragraphs[ $i ] );
        }
    }
    $r->cache( 'keitai_content_id:' . $file_fi->id, $contents );
    $ctx->stash( '_keitai_page_count', scalar( @$contents ) );
    my @build_fi;
    if ( $static ) {
        my $local_page = 1;
        require MT::FileInfo;
        for my $paragraph ( @$contents ) {
            if ( defined $file_fi ) {
                if ( $local_page > 1 ) {
                    my $pager_number = $local_page;
                    my $fileinfo_file_path = $file_fi->file_path;
                    my $fileinfo_url = $file_fi->url;
                    my $file_extension = file_extension( $fileinfo_file_path );
                    $fileinfo_file_path =~ s/(\.$file_extension$)/$basename_prefix$pager_number$1/i;
                    $fileinfo_url =~ s/(\.$file_extension$)/$basename_prefix$pager_number$1/i;
                    if (! $r->cache( 'published_keitai:' . $fileinfo_file_path ) ) {
                        my $current_archive_base = $fileinfo_url;
                        $current_archive_base =~ s/\.$file_extension$//;
                        $file_ctx->stash( 'current_archive_number', $pager_number );
                        $file_ctx->stash( '_keitai_current', $pager_number );
                        $file_ctx->stash( 'current_archive_base', $current_archive_base );
                        my $fi = MT::FileInfo->get_by_key( { archive_type => $file_fi->archive_type,
                                                             author_id => $file_fi->author_id,
                                                             blog_id => $file_fi->blog_id,
                                                             category_id => $file_fi->category_id,
                                                             entry_id => $file_fi->entry_id,
                                                             original_fi_id => $file_fi->id,
                                                             startdate => $file_fi->startdate,
                                                             # template_id => $file_fi->template_id,
                                                             # templatemap_id => $file_fi->templatemap_id,
                                                             file_path => $fileinfo_file_path,
                                                             url => $fileinfo_url,
                                                            } );
                        $r->cache( 'published_keitai:' . $fileinfo_file_path, 1 );
                        my $keitai_fi = _publish_keitai( $app, $file_tmpl, $file_ctx, $fi, $file_args, $pager_number );
                    }
                }
            }
            $local_page++;
        }
    }
    $ctx->stash( 'current_archive_number', $page + 1 );
    $ctx->stash( '_keitai_current', $page + 1 );
    return @$contents[ $page ];
}

sub _hdlr_if_keitai_pagecurrent {
    my ( $ctx, $args, $cond ) = @_;
    my $page    = $ctx->stash( 'current_archive_number' );
    my $current = $ctx->stash( '_list_counter' );
    if ( $page == $current ) {
        return 1;
    }
    return 0;
}

sub _hdlr_if_keitai_pagenext {
    my ( $ctx, $args, $cond ) = @_;
    my $page    = $ctx->stash( '_keitai_current' );
    my $counter = $ctx->stash( '_keitai_page_count' );
    if ( $page < $counter ) {
        return 1;
    }
    return 0;
}

sub _hdlr_if_keitai_pageprev {
    my ( $ctx, $args, $cond ) = @_;
    my $page = $ctx->stash( '_keitai_current' );
    if ( $page > 1 ) {
        return 1;
    }
    return 0;
}

sub _hdlr_keitai_pagelink {
    my ( $ctx, $args, $cond ) = @_;
    my $plugin_keitailib = MT->component( 'KeitaiLib' );
    my $page = $ctx->stash( '_list_counter' );
    my $url  = $ctx->stash( 'current_archive_url' );
    if ( $url ) {
        if ( $page > 1 ) {
            my $basename_prefix = $plugin_keitailib->get_config_value( 'basename_prefix' );
            my $file_extension = file_extension( $url, 1 );
            $url =~ s/(^.*)(\.$file_extension)$/$1$basename_prefix$page$2/;
        }
        return $url;
    }
    my $query_string;
    unless ( $url ) {
        my $app = MT->instance();
        return '?' . $page unless is_application( $app );
        if ( $app->mode =~ /preview/ ) {
            return '';
        }
        $url = $app->base . $app->mt_path . $app->script;
        if ( $app->query_string ) {
            my $query_string = $app->query_string;
            $query_string =~ s/page=[0-9]{1,}//;
            $url .= '?' . $query_string if $query_string;
        }
    }
    if (! $query_string ) {
        $url .= '?';
    }
    $url .= "page=$page";
    return $url;
}

sub _hdlr_keitai_pagenextlink {
    my ( $ctx, $args, $cond ) = @_;
    my $plugin_keitailib = MT->component( 'KeitaiLib' );
    my $page = $ctx->stash( "_keitai_current" );
    my $next = $page + 1;
    my $url  = $ctx->stash( 'current_archive_url' );
    if ( $url ) {
        if ( $next > 1 ) {
            my $basename_prefix = $plugin_keitailib->get_config_value( 'basename_prefix' );
            my $file_extension = file_extension( $url, 1 );
            $url =~ s/(^.*)(\.$file_extension)$/$1$basename_prefix$next$2/;
        }
        return $url;
    }
    my $query_string;
    unless ( $url ) {
        my $app = MT->instance();
        return '?' . $next unless is_application( $app );
        if ( $app->mode =~ /preview/ ) {
            return '';
        }
        $url = $app->base . $app->mt_path . $app->script;
        if ( $app->query_string ) {
            my $query_string = $app->query_string;
            $query_string =~ s/page=[0-9]{1,}//;
            $url .= '?' . $query_string if $query_string;
        }
    }
    if (! $query_string ) {
        $url .= '?';
    }
    $url .= "page=$next";
    return $url;
}

sub _hdlr_keitai_pageprevlink {
    my ( $ctx, $args, $cond ) = @_;
    my $plugin_keitailib = MT->component( 'KeitaiLib' );
    my $page = $ctx->stash( "_keitai_current" );
    my $prev = $page - 1;
    my $url  = $ctx->stash( 'current_archive_url' );
    if ( $url ) {
        if ( $prev > 1 ) {
            my $basename_prefix = $plugin_keitailib->get_config_value( 'basename_prefix' );
            my $file_extension = file_extension( $url, 1 );
            $url =~ s/(^.*)(\.$file_extension)$/$1$basename_prefix$prev$2/;
        }
        return $url;
    }
    my $query_string;
    unless ( $url ) {
        my $app = MT->instance();
        return '?' . $prev unless is_application( $app );
        if ( $app->mode =~ /preview/ ) {
            return '';
        }
        $url = $app->base . $app->mt_path . $app->script;
        if ( $app->query_string ) {
            my $query_string = $app->query_string;
            $query_string =~ s/page=[0-9]{1,}//;
            $url .= '?' . $query_string if $query_string;
        }
    }
    if (! $query_string ) {
        $url .= '?';
    }
    $url .= "page=$prev";
    return $url;
}

sub _hdlr_keitai_pagenumber {
    my ( $ctx, $args, $cond ) = @_;
    return $ctx->stash( '_list_counter' );
}

sub _hdlr_keitai_pagecount {
    my ( $ctx, $args, $cond ) = @_;
    return $ctx->stash( '_keitai_page_count' );
}

sub _hdlr_xml_document {
    my ( $ctx, $args, $cond ) = @_;
    my $charset = MT->config->PublishCharset || 'UTF-8';
    return '<?xml version="1.0" encoding="' . $charset . '"?>';
}

sub _hdlr_get_career {
    my $app = MT->instance();
    return get_agent( $app );
}

sub _filter_emoticon2mtml {
    my ( $text, $arg, $ctx ) = @_;
    require File::Basename;
    for my $img ( $text =~ m/(<img.*?>)/isg ) {
        my $src  = $1 if ( $img =~ m/src\s*="(.*?)"/is );
        my $alt  = $1 if ( $img =~ m/alt\s*="(.*?)"/is );
        my $size = $1 if ( $img =~ m/width\s*="(.*?)"/is );
        $size = 16 unless $size;
        my $search = quotemeta( $arg );
        if ( $src =~ /$arg/ ) {
            if ( $alt ) { $alt = 1; } else { $alt = 0; }
            my $basename = File::Basename::basename( $src );
            my $docomo_id = emoticon2docomo_id( $basename );
            if ( $docomo_id ) {
                my $mtml;
                $arg = lc ( $arg );
                if ( $arg eq 'regacy' ) {
                    $mtml = "<mt:GetEmojiLegacy docomo_id=\"$docomo_id\" emoticon=\"1\" alt=\"$alt\" size=\"$size\" base=\"$arg\">";
                } elsif ( $arg eq 'legacy' ) {
                    $mtml = "<mt:GetEmojiLegacy docomo_id=\"$docomo_id\" emoticon=\"1\" alt=\"$alt\" size=\"$size\" base=\"$arg\">";
                } else {
                    $mtml = "<mt:GetEmoji docomo_id=\"$docomo_id\" emoticon=\"1\" alt=\"$alt\" size=\"$size\" base=\"$arg\">";
                }
                $img = quotemeta( $img );
                $text =~ s/$img/$mtml/g;
            }
        }
    }
    return $text;
}

sub _filter_convertthumbnail {
    my ( $text, $arg, $ctx ) = @_;
    my $blog = $ctx->stash( 'blog' );
    my $test = $text;
    my $site_url    = site_url( $blog );
    my $site_path   = site_path( $blog );
    my $search_path = quotemeta( $site_url );
    require MT::Asset;
    require File::Basename;
    my ( $embed, $link, $dimension );
    if ( $arg =~ /,/ ) {
        ( $embed, $link, $dimension ) = split( /\s*,\s*/, $arg );
        $embed = trim( $embed );
        $link = trim( $link );
        $dimension = trim( $dimension || 'width' );
    } else {
        $embed = $arg;
        $link  = "";
    }
    if (! $dimension ) {
        $dimension = 'width';
    } else {
        $dimension = lc( $dimension );
    }
    return convert2thumbnail( $blog, $text, undef, $embed, $link, $dimension, 1 );
}

sub _filter_z2h {
    my $str = shift;
    require Unicode::Japanese;
    $str = Unicode::Japanese->new( utf8_off( $str ) )->z2h->get;
    return MT::Util::convert_word_chars( utf8_on( $str ), 0 );
    # return utf8_on( $str );
}

sub _filter_tel2link {
    my $text = shift;
    my $tag_1 = '<a href ="tel:';
    my $tag_2 = '">';
    my $tag_3 = '</a>';
    my $end;
    while (! $end ) {
        my $original = $text;
        $text =~ s/(<[^>]*>[^<]*?)(0\d{1,4}-\d{1,4}-\d{3,4})/$1$tag_1$2$tag_2$2$tag_3/ig;
        $text =~ s/(<a.*?>\/*)<a.*?>(0\d{1,4}-\d{1,4}-\d{3,4})<\/a>([^<]*?<\/a>)/$1$2$3/ig;
        if ( $text eq $original ) {
            $end = 1;
        }
    }
    return $text;
}

sub _filter_str2keitai {
    my $text = shift;
    my $plugin_keitailib = MT->component( 'KeitaiLib' );
    my $cite  = $plugin_keitailib->translate( 'Quote' );
    my $frame = $plugin_keitailib->translate( 'Frame' );
    my $regex;
    $regex = qr/<script[^>]*.*?<\/script>/;
    $text  =~ s!$regex!!isg;
    $regex = qr/<iframe[^>]*src=*["']([^"'>]*)["'][^>]*>*?<\/iframe>/;
    $text  =~ s!$regex!<a href="$1">$frame</a>!isg;
    $regex = qr/<blockquote[^>]*cite="(.{1,}?)"[^>]*>(.{1,}?)<\/blockquote>/;
    $text  =~ s!$regex!<a href="$1">$cite</a>$2!isg;
    $regex = qr/<[\/]*(frameset|frame|noframes)[^>]*?>/;
    $text  =~ s!$regex!!isg;
    $regex = qr/<[\/]*(strong|em|b|i|u|s|font)\s*?>/;
    $text  =~ s!$regex!!isg;
    $regex = qr/(<[^>]*)(onclick|onmouseup|onmouseover|onmouseout|onmousedown)=?(")[^>]*?(")/;
    $text  =~ s!$regex!$1!isg;
    $regex = qr/(<[^>]*)(onclick|onmouseup|onmouseover|onmouseout|onmousedown)=?(')[^>]*?(')/;
    $text  =~ s!$regex!$1!isg;
    return $text;
}

sub _publish_keitai {
    my ( $app, $tmpl, $ctx, $fi, $args, $num ) = @_;
    unless ( $fi->id ) {
        $fi->keitai_counter( $num );
        $fi->save or die $fi->errstr;
    }
    my $tmpl_obj = $tmpl;
    $tmpl = $tmpl->text;
    require MT::Builder;
    require MT::FileMgr;
    my $fmgr = MT::FileMgr->new( 'Local' ) or die MT::FileMgr->errstr;
    my $build = MT::Builder->new;
    my $tokens = $build->compile( $ctx, $tmpl )
        or return $app->log( $app->translate(
            "Parse error: [_1]", $build->errstr ) );
    defined( my $html = $build->build( $ctx, $tokens ) )
        or return $app->log( $app->translate(
            "Build error: [_1]", $build->errstr ) );
    my $orig_html = $html;
    MT->run_callbacks(
        'build_page',
        Context      => $ctx,
        context      => $ctx,
        Blog         => $ctx->stash( 'blog' ),
        blog         => $ctx->stash( 'blog' ),
        FileInfo     => $fi,
        file_info    => $fi,
        ArchiveType  => $args->{ArchiveType},
        archive_type => $args->{ArchiveType},
        RawContent   => \$orig_html,
        raw_content  => \$orig_html,
        Content      => \$html,
        content      => \$html,
        BuildResult  => \$orig_html,
        build_result => \$orig_html,
        Template     => $tmpl_obj,
        template     => $tmpl_obj,
        File         => $fi->file_path,
        file         => $fi->file_path,
    );
    if ( $fmgr->content_is_updated( $fi->file_path, \$html ) ) {
        $app->run_callbacks( 'build_file', \$args );
        write2file( $fi->file_path, $html );
    }
    return $fi;
}

1;
