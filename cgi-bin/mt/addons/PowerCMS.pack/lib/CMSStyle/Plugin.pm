package CMSStyle::Plugin;
use strict;

use MT::Util qw( encode_html );
use PowerCMS::Util qw( read_from_file url2path current_user get_weblogs
                       get_powercms_config );
use CMSStyle::Util;

sub _cb_ts_header {
    my ( $cb, $app, $tmpl ) = @_;
    my $plugin = MT->component( 'PowerCMS' );
    my ( $search, $insert );
    my $template_path = File::Spec->catdir( $plugin->path, 'tmpl', 'include', 'header_create_menu.tmpl' );
    $insert = '<mt:include name="' . $template_path . '" component="PowerCMS">';
    $search = quotemeta( '<li id="user">' ); # for Bookmarks. BACKWARD: '<ul id="utility-nav-list">'
    $$tmpl =~ s/($search)/$insert$1/;
    $insert =<<'MTML';
<link rel="stylesheet" href="<$mt:var name="static_uri"$>addons/PowerCMS.pack/css/cmsstyle.css" type="text/css" />
MTML
    $search = quotemeta( '</head>' );
    $$tmpl =~ s/($search)/$insert$1/;
}

sub _powercms_create_menu {
    my ( $cb, $app, $param, $tmpl ) = @_;
    return if $app->config( 'DisableCreateMenu' );
    return if exists $param->{ powercms_create_menu };
    return if $app->blog;
    my ( @webpage, @blogentry );
    my $r = MT::Request->instance;
    my $blogs = $r->cache( 'powercms_get_weblogs' );
    if (! $blogs ) {
        if ( my $blog = $app->blog ) {
            @$blogs = get_weblogs( $blog );
        } else {
            @$blogs = MT::Blog->load( { class => '*' },
                                      { limit => 10 },
                                    );
        }
        $r->cache( 'powercms_get_weblogs', $blogs );
    }
    for my $blog ( @$blogs ) {
        __create_label( $app, $blog, 'page', \@webpage );
        if ( $blog->is_blog ) {
            __create_label( $app, $blog, 'entry', \@blogentry );
        }
    }
    return unless ( @webpage || @blogentry );
    my $webpage_menu = __create_menu( $app, 'page', \@webpage );
    my $blogentry_menu = __create_menu( $app, 'entry', \@blogentry );
    my @create_menu;
    push( @create_menu, $webpage_menu ) if $webpage_menu;
    push( @create_menu, $blogentry_menu ) if $blogentry_menu;
    $param->{ powercms_create_menu } = \@create_menu;
}

{
    my $__max_num = 10;
    sub __create_label {
        my ( $app, $blog, $type, $ary ) = @_;
        if ( @$ary < $__max_num && CMSStyle::Util::has_permission( $type, $blog ) ) {
            push( @$ary, { sub_label => $blog->name,
                           sub_link_url => $app->uri( mode => 'view', args => { blog_id => $blog->id,
                                                                                _type => $type,
                                                                              },
                                                    ),
                         },
                );
        }
    }
    sub __create_menu {
        my ( $app, $type, $label_ary ) = @_;
        my @label = @$label_ary;
        return unless @label;
        if ( @label == 1 ) {
            return { menu_class => $type,
                     menu_link_url => $label[ 0 ]->{ sub_link_url },
                   };
        }
        if ( @label == $__max_num ) {
            $label[ $__max_num - 1 ] = { sub_label => '...',
                                         sub_link_url => $app->uri( mode => "blogselector_$type" ),
                                         is_dialog => 1,
                                       };
        }
        return { menu_class => $type,
                 sub_menus => \@label,
               };
    }
}

sub _add_lock_status {
    my ( $cb, $app, $param, $tmpl ) = @_;
    $param->{ 'unavailable_mt' } = get_powercms_config( 'powercms', 'unavailable' );
    if ( my $user = current_user( $app ) ) {
        $param->{ 'is_superuser' } = $user->is_superuser ? 1 : 0;
    }
}

sub _pre_run {
    my ( $cb, $app ) = @_;
    my $unavailable = get_powercms_config( 'powercms', 'unavailable' );
    my $user = current_user( $app ) or return 1;
    unless ( $user->is_superuser ) {
        if ( $unavailable ) {
            if ( $app->mode ne 'login_error' ) {
                return $app->redirect( $app->base . $app->uri( mode => 'login_error',
                                                               args => { is_locked => 1, },
                                                             ),
                                     );
            }
        }
    }
}

sub _set_label_at_tp { # OK
    my ( $cb, $app, $param, $tmpl ) = @_;
    my @field_ids = ( 'title', 'text', 'tags', 'excerpt', 'keywords' );
    my $blog = $app->blog;
    my $aref = $param->{ field_loop } || [];
    my @data;
    for my $ref ( @$aref ) {
        next unless exists( $ref->{ field_name } );
        if ( grep { $_ eq $ref->{ field_name } } @field_ids ) {
            push( @data, $ref );
        }
    }
    my %data = map { $_->{ field_name }, $_; } @data;
    for my $key ( keys %data ) {
        my $setting = get_powercms_config( 'powercms', $key, $blog ) ||
                      get_powercms_config( 'powercms', $key )
            or next;
        $data{ $key }{ field_label } = $setting;
    }
    1;
}

sub _set_label { # OK
    my ( $cb, $app, $tmpl ) = @_;
    my $plugin = MT->component( 'PowerCMS' );
    my $blog = $app->blog;
    my $title = get_powercms_config( 'powercms', 'title', $blog ) ||
                get_powercms_config( 'powercms', 'title' );
    if ( $title ) {
        $$tmpl =~ s{(<mtapp:setting.+?id="title"(?:.+?)label_class=)"([^"]*)"((?:.+?)</mtapp:setting>)}{$1"top-label"$3}s;
        $$tmpl =~ s/<__trans\sphrase="Title">/$title/g;
    }
    my $text = get_powercms_config( 'powercms', 'text', $blog ) ||
               get_powercms_config( 'powercms', 'text' );
    if ( $text ) {
        $$tmpl =~ s/<__trans\sphrase="Body">/$text/g;
    }
    my $extended = get_powercms_config( 'powercms', 'extended', $blog ) ||
                   get_powercms_config( 'powercms', 'extended' );
    if ( $extended ) {
        $$tmpl =~ s/<__trans\sphrase="Extended">/$extended/g;
    }
    my $tags = get_powercms_config( 'powercms', 'tags', $blog ) ||
               get_powercms_config( 'powercms', 'tags' );
    if ( $tags ) {
        $$tmpl =~ s/<__trans\sphrase="Tags">/$tags/g;
    }
    my $basename = get_powercms_config( 'powercms', 'basename', $blog ) ||
                   get_powercms_config( 'powercms', 'basename' );
    if ( $basename ) {
        $$tmpl =~ s/<__trans\sphrase="Basename">/$basename/g;
    }
    my $comments = get_powercms_config( 'powercms', 'comments', $blog ) ||
                   get_powercms_config( 'powercms', 'comments' );
    if ( $comments ) {
        $$tmpl =~ s/<__trans\sphrase="Comments">/$comments/g;
        my $text = $plugin->translate( "Accept [_1]", $comments );
        $$tmpl =~ s/<__trans\sphrase="Accept Comments">/$text/g;
        # saved_comment=1
        $text = $plugin->translate( "Your changes to the [_1] have been saved.", $comments );
        $$tmpl =~ s/<__trans\sphrase="Your changes to the comment have been saved\.">/$text/g;
        # saved_deleted=1
        $text = $plugin->translate( "You have successfully deleted the checked [_1].", $comments );
        $$tmpl =~ s/<__trans\sphrase="You have successfully deleted the checked comment\(s\)\.">/$text/g;
    }
    my $trackbacks = get_powercms_config( 'powercms', 'trackbacks', $blog ) ||
                     get_powercms_config( 'powercms', 'trackbacks' );
    if ( $trackbacks ) {
        $$tmpl =~ s{<__trans\sphrase="TrackBacks"/>}{$trackbacks}g;
        my $text = $plugin->translate( "Accept [_1]", $trackbacks );
        $$tmpl =~ s/<__trans\sphrase="Accept Trackbacks">/$text/g;
        $text = $plugin->translate( "Outbound [_1] URLs", $trackbacks );
        $$tmpl =~ s/<__trans\sphrase="Outbound TrackBack URLs">/$text/g;
        # saved_deleted_ping=1
        $text = $plugin->translate( "You have successfully deleted the checked [_1].", $trackbacks );
        $$tmpl =~ s/<__trans\sphrase="You have successfully deleted the checked TrackBack\(s\)\.">/$text/g;
        # ping_errors=1
        $text = $plugin->translate( "One or more errors occurred when sending update pings or [_1].",$trackbacks );
        $$tmpl =~ s/<__trans\sphrase="One or more errors occurred when sending update pings or TrackBacks\.">/$text/g;
        # after send trackback
        $text = $plugin->translate( "View Previously Sent [_1]", $trackbacks );
        $$tmpl =~ s/<__trans\sphrase="View Previously Sent TrackBacks">/$text/g;
    }
    my $category = get_powercms_config( 'powercms', 'category', $blog ) ||
                   get_powercms_config( 'powercms', 'category' );
    if ( $category ) {
        $$tmpl =~ s/<__trans\sphrase="Categor(?:ies|y)">/$category/g;
    }
}

sub _set_w3c_form {
    my ( $eh, $app, $tmpl, $param ) = @_;
    return unless get_powercms_config( 'powercms', 'use_validation' );
    my $blog = $app->blog;
    my $file = $param->{ 'preview_url' };
    $file = url2path( $file, $blog );
    my $search = quotemeta( '<div class="actions-bar actions-bar-bottom line">' );
    my $button =<<'HTML';
<button
    mt:mode="view"
    type="submit"
    onclick="post2w3c();return false;"
    class="action primary button"
    >Markup Validation</button>
HTML
    $$tmpl =~ s/($search)/$1$button/s;
    my $preview_file = $param->{ 'preview_file' };
    my $magic_token = $param->{ 'magic_token' };
    my $url = $app->base . $app->uri( mode => 'contents_for_validation',
                                      args => {
                                        _preview_file => $preview_file,
                                        magic_token => $magic_token,
                                      },
                                    );
    # FIXME: Do we need check the iframe?
    my $script = <<"HTML";
<script type="text/javascript">
    var i_timer = setInterval(function(){
        var iframe = jQuery('#frame');
        if(iframe.length){
            clearInterval(i_timer);
            // var src = iframe.attr('src');
            var src = "$url";
            jQuery.ajax({
                url: src,
                async: false,
                dataType: 'html',
                success: function(data, dataType){
                    jQuery('#w3c #fragment').val(data);
                }
            });
        }
    }, 100);
    function post2w3c() {
        document.w3c.submit();
    }
</script>
HTML
    my $src = read_from_file( $file );
    $src =~ s/&/&amp;/g;
    $src = encode_html( $src );
    my $posturl = get_powercms_config( 'powercms', 'posturl' );
    my $form = <<"HTML";
<form action="$posturl" method="post" id="w3c" name="w3c" target="_blank">
    <input id="fragment" name="fragment" type="hidden" value="$src" />
    <input type="hidden" value="0" name="prefill" id="direct_prefill_no" />
    <input type="hidden" name="group" id="directgroup_yes" value="1">
</form>
HTML
    $search = quotemeta( '</form>' );
    $$tmpl =~ s/($search)/$1$script$form/s;
}

sub _cb_cms_post_save_entry {
    my ( $eh, $app, $obj, $original ) = @_;
    if ( my $text = $obj->text ) {
        my $changed = 0;
        $changed += ( $text =~ s/class="mt-image-none"\s*//g );
        $changed += ( $text =~ s/style=""\s*//g );
        if ( $changed ) {
            $obj->text( $text );
        }
    }
    if ( my $text_more = $obj->text_more ) {
        my $changed = 0;
        $changed += ( $text_more =~ s/class="mt-image-none"\s*//g );
        $changed += ( $text_more =~ s/style=""\s*//g );
        if ( $changed ) {
            $obj->text_more( $text_more );
        }
    }
1;
}

sub _cb_tp_asset_insert {
    my ( $eh, $app, $param ) = @_;
    if ( $app->param( 'align' ) eq 'none' ) {
        if ( my $upload_html = $param->{ upload_html } ) {
            $upload_html =~ s!class="mt-image-none"\s*!!g;
            $upload_html =~ s!style=""\s*!!g;
            $param->{ upload_html } = $upload_html;
        }
    }
}

1;

__END__

=head1 NAME

MT::Plugin::CMSStyle - CMSの見栄えをカスタマイズするプラグイン

=head1 概要

* フィールドラベルカスタマイズ機能(旧EntryLabel)

プラグイン設定画面からエントリー編集画面のフィールドラベルをカスタマイズする機能です。

* ダイレクト記事作成機能(旧BlogSelectorDialog)

システムメニューからのブログ記事やウェブページを作成する機能です。

システム画面右上に「新規作成」メニューを追加します。

* HTML文法チェック機能(旧MarkupValidation)

プレビュー時に生成されたHTMLの文法をW3C Markup Validation Serviceでチェックする機能です。

* CMSロック機能(旧LockMT)

管理画面を「システム管理者」以外のユーザに対して使えなくする機能です。

メニューバーに「ロック」アイコンを追加します。

* 画像挿入時mt-image-none削除機能(旧StylelessImage)

エントリ編集時の画像の挿入を行った際にimg属性中にclass="mt-image-none"が自動的に
設定されてしまうためそれを削除する機能です。

class に mt-image-none のみが設定されている場合に削除します。

=head1 SETTINGS

* フィールドラベルカスタマイズ機能(旧EntryLabel)

=over 4

=item * title - エントリー編集画面のフィールドラベル「タイトル」の代替テキスト

=item * body - エントリー編集画面のフィールドラベル「本文」の代替テキスト

=item * extended - エントリー編集画面のフィールドラベル「続き」の代替テキスト

=item * excerpt - エントリー編集画面のフィールドラベル「概要」の代替テキスト

=item * keywords - エントリー編集画面のフィールドラベル「キーワード」の代替テキスト

=item * tags - エントリー編集画面のフィールドラベル「タグ」の代替テキスト

=item * basename - エントリー編集画面のフィールドラベル「出力ファイル名」の代替テキスト

=item * comments - エントリー編集画面のフィールドラベル「コメント」の代替テキスト

=item * trackbacks - エントリー編集画面のフィールドラベル「トラックバック」の代替テキスト

=item * category - エントリー編集画面のフィールドラベル「カテゴリ」の代替テキスト

=back

* HTML文法チェック機能(旧MarkupValidation)

=over 4

=item * posturl - W3C Markup Validation Service の URL

=back

* CMSロック機能(旧LockMT)

=over 4

=item * unavailable - ロック中かどうかのフラグ

ロック中なら1、この設定はプラグイン設定からは変更できません。

=back

=head1 CALLBACKS

=head2 MT::App::CMS::template_source.edit_entry

* フィールドラベルカスタマイズ機能(旧EntryLabel)

=head3 特記事項

=over 4

=item * タイトル

MTデフォルトのテンプレートでは非表示(label_class="no-header")になっているため、
指定がある場合にlabel_class="top-lavel"に表示を変更する。

=item * コメント

「コメントを許可」、
saved_comment=1のときの表示文言、saved_deleted=1のときの表示文言
の「コメント」も一緒に変更する。

=item * トラックバック

「トラックバックを許可」、
「トラックバック送信先URL」saved_deleted_ping=1のときの表示文言、
ping_errors=1のときの表示文言、「送信済みのトラックバックを見る」の
「トラックバック」も一緒に変更する。

=back

=head2 MT::App::CMS::template_source.header

管理画面上部にシステムメニューを追加します。

=head2 MT::App::CMS::template_param.edit_entry

* フィールドラベルカスタマイズ機能(旧EntryLabel)

MT5では、ループで処理されている部分があった（概要とキーワード）ため
パラメータ中の該当部分を置き換える必要のある箇所をこのコールバックに分離した。

=head2 MT::App::CMS::template_param

* CMSロック機能(旧LockMT)

テンプレートにロック状態用の変数と管理者判定用の変数を埋め込みます。

* ダイレクトブログ記事作成機能(旧BlogSelectorDialog)

システム画面右上「新規作成」メニューに、「ブログ記事」「ウェブページ」を追加します。

=head2 MT::App::CMS::template_output.preview_strip

* HTML文法チェック機能(旧MarkupValidation)

プレビュー画面に「Markup Validation」ボタンを追加します。

=head2 MT::App::CMS::pre_run

* CMSロック機能(旧LockMT)

ロック時に非管理者ユーザをログインエラー中画面にリダイレクトさせます。

=head1 MODE

=head2 blogselector_entry

=head2 blogselector_page

* ダイレクト記事作成機能(旧BlogSelectorDialog)

ウェブサイトまたはブログを選択するダイアログを表示するモード
システム画面右上に追加される「新規作成」メニューの一番下から進みます。

=head2 lock_mt

=head2 unlock_mt

* CMSロック機能(旧LockMT)

ロック状態を切り替えるモード

メニューバーの「ロック」アイコンから切り替えします。

=cut
