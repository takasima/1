package PowerTheme::Util;
use strict;

use lib qw( addons/PowerCMS.pack/lib );
use PowerCMS::Util qw( site_path save_asset file_label );
use Encode; # FIXME

sub powercms_blog_theme_ids {
    return [ 'power_cms_blog_blog', 'power_cms_blog_case_study', 'power_cms_blog_news' ],
}

sub powercms_website_theme_ids {
    return [ 'power_cms_website', ],
}

sub blog_template_settings {
    my $__templatesettings = {
        news => {
            main_index => {
                pager => 1,
            },
            template_6375 => {
                pager => 1,
            },
        },
        examples => {
            main_index => {
                pager => 1,
            },
            category_entry_listing => {
                pager => 1,
            },
        },
        blog => {
            main_index => {
                pager => 1,
            },
            category_entry_listing => {
                pager => 1,
            },
        },
    };
    return $__templatesettings;
}

sub blog_settings {
    return {
        dynamic_mtml => 1,
    };
}

sub website_settings {
    return {
        dynamic_mtml => 1,
    };
}

sub website_customobject_groups {
    my $__website_customobject_groups = [
#        {
#          name => '機能一覧',
#          addfilter => 'all',
#          addfilter_blog_id => 0,
#          additem => 1,
#          addposition => 1,
#          filter_tag => '',
#          customobjects => [
#            'New Dynamic MTML',
#            'マルチDBサポート',
#          ]
#        },
    ];
    return $__website_customobject_groups;
}

sub website_customobjects {
    my $__customobjects = [
#        { name => 'New Dynamic MTML',
#          basename => 'new_dynamic_mtml',
#          class => 'customobject',
#          keywords => '',
#          set_period => 0,
#          status => 2,
#          current_revision => 1,
#          folder => 'archives',
#          functionoutline => '<p>マルチデバイスと最適化。</p>',
#          functionbody => '<p>test</p>',
#        },
#        { name => 'マルチDBサポート',
#          basename => 'multi_db_support.html',
#          class => 'customobject',
#          keywords => '',
#          set_period => 0,
#          status => 2,
#          current_revision => 1,
#          folder => 'archives',
#          functionoutline => '<p>複数のDBを1つのテンプレートエンジンで処理ができます。書き込みと読み出しDBを分けることも可能!</p>',
#          functionbody => '<p>test</p>',
#        },
    ];
    return $__customobjects;
}

sub website_plugin_settings {
    my $__pluginsettings = {
#        CustomObjectConfig => {
#            label_en => 'function',
#            label_plural => 'functions',
#            label_ja => '機能',
#        },
    };
    return $__pluginsettings;
}

sub website_objjectgroups {
    my $__objjectgroups = [
        { name => 'グローバルメニュー',
          class => 'objectgroup',
          items => [
            {
                class => 'website',
            },
            {
                class => 'page',
                key => 'title',
                value => '製品概要',
            },
            {
                class => 'page',
                key => 'title',
                value => '機能',
            },
            {
                class => 'blog',
                key => 'name',
                value => '導入事例',
            },
            {
                class => 'blog',
                key => 'name',
                value => 'ブログ',
            },
          ],
        },
        { name => 'フッターメニュー',
          class => 'objectgroup',
          items => [
            {
                class => 'website',
            },
            {
                class => 'page',
                key => 'title',
                value => '製品概要',
            },
            {
                class => 'page',
                key => 'title',
                value => '機能',
            },
            {
                class => 'blog',
                key => 'name',
                value => '導入事例',
            },
            {
                class => 'blog',
                key => 'name',
                value => 'ブログ',
            },
            {
                class => 'page',
                key => 'title',
                value => 'サイトマップ',
            },
            {
                class => 'page',
                key => 'title',
                value => 'お問い合わせ',
            },
          ],
        },
    ];
    return $__objjectgroups;
}

sub blog_entrygroups {
    my $__entrygroups = {
        examples => [
            {
              name => '記事グループ1',
              addfilter => 'all',
              addfilter_blog_id => 0,
              addposition => 0,
              filter_container => 0,
              entries => [
                'Movable TypeとPowerCMSを活用した釣り情報誌のオンライン展開',
                'Movable Type + PowerCMSで作る『営業する』不動産サイト',
                '小さい会社の大きな武器、PowerCMS ～グループ機能LOVE～',
                'カスタマイズ性と学習コストで選ぶ Movable Type + PowerCMS',
              ],
            },
        ],
    };
    return $__entrygroups;
}

sub website_contactformgroups {
    my $__contactformgroups = [
        { name => 'お問い合わせフォーム',
          cms_tmpl => {
            name => 'ウェブページ',
            identifier => 'page',
            type => 'page',
          },
          confirm_message => '下記の内容で送信します。',
          error_message => '入力した内容をご確認ください。',
          information_message => 'お問い合わせフォーム',
          mail_admin => 0,
          mail_admin_tmpl => 0,
          mail_sender => 0,
          mail_sender_tmpl => 0,
          message => 'ありがとうございました。',
          post_limit => 0,
          requires_login => 0,
          set_limit => 2,
          set_period => 2,
          status => 2,
          contactforms => [
            '氏名',
            'メールアドレス',
            '内容',
          ],
        },
    ];
    return $__contactformgroups;
}

sub website_contactforms {
    my $__contactforms = [
        { name => '氏名',
          check_length => 0,
          count_multibyte => 0,
          max_length => 0,
          mtml => &contactform_text_mtml(),
          mtml_id => 'text',
          required => 1,
          size => 0,
          status => 2,
          type => 'text',
          basename => 'name',
        },
        { name => 'メールアドレス',
          check_length => 0,
          count_multibyte => 0,
          max_length => 0,
          mtml => &contactform_text_mtml(),
          mtml_id => 'email',
          required => 1,
          validate => 1,
          size => 0,
          status => 2,
          type => 'email',
          basename => 'email',
        },
        { name => '内容',
          check_length => 0,
          count_multibyte => 0,
          max_length => 0,
          mtml => &contactform_textarea_mtml(),
          mtml_id => 'textarea',
          required => 0,
          size => 0,
          status => 2,
          type => 'textarea',
          basename => 'text',
        },
    ];
    return $__contactforms;
}

sub website_blog_groups {
    my $__groups = [
        { name => '新着一覧',
          blogs => [ 'news', 'examples' ],
        },
    ];
    return $__groups;
}

sub website_campaign_groups {
    my $__website_campaign_groups = [
        {
          name => 'サポート',
          addfilter => 'all',
          addfilter_blog_id => 0,
          additem => 0,
          addposition => 0,
          campaigns => [
            'PowerCMS マニュアル (PDF 18.6 MB)',
            'PowerCMS サポート',
#            'テンプレート作成Tips',
            'PowerCMS 機能一覧',
          ]
        },
        {
          name => 'トップページ右バナー',
          addfilter => 'all',
          addfilter_blog_id => 0,
          additem => 0,
          addposition => 0,
          campaigns => [
            'CAMPAIGN',
            '耳より情報',
            'プレゼント',
          ]
        },
        {
          name => '関連リンク',
          addfilter => 'all',
          addfilter_blog_id => 0,
          additem => 0,
          addposition => 0,
          campaigns => [
            'PowerCMS 3.0',
            'Movable Type/TypePad関連製品',
          ]
        },
    ];
    return $__website_campaign_groups;
}

sub website_campaigns {
    my $__website_campaigns = [
        {
          title => 'メインビジュアル',
          path => 'banner/main_visual.jpg',
          banner_height => 0,
          banner_width => 0,
          editor_select => 0,
          set_period => 2,
          status => 2,
          tags => 'main_visual',
          url => '#main_visual',
        },
        {
          title => 'Movable Type/Type Pad関連製品',
          banner_height => 0,
          banner_width => 0,
          editor_select => 0,
          set_period => 2,
          status => 2,
          url => '#related_products',
        },
        {
          title => 'PowerCMS 3.0',
          banner_height => 0,
          banner_width => 0,
          editor_select => 0,
          set_period => 2,
          status => 2,
          url => 'http://www.powercms.jp/',
        },
        {
          title => 'PowerCMS 機能一覧',
          banner_height => 0,
          banner_width => 0,
          editor_select => 0,
          set_period => 2,
          status => 2,
          url => 'http://www.powercms.jp/features/',
        },
#        {
#          title => 'テンプレート作成Tips',
#          banner_height => 0,
#          banner_width => 0,
#          editor_select => 0,
#          set_period => 2,
#          status => 2,
#          url => '#template_tips',
#        },
        {
          title => 'PowerCMS サポート',
          banner_height => 0,
          banner_width => 0,
          editor_select => 0,
          set_period => 2,
          status => 2,
          url => 'http://www.powercms.jp/support/',
        },
        {
          title => 'PowerCMS マニュアル (PDF 16.9 MB)',
          banner_height => 0,
          banner_width => 0,
          editor_select => 0,
          set_period => 2,
          status => 2,
          url => 'http://powercms.alfasado.net/src/standard/files/PowerCMSUserGuide_3.pdf',
        },
        {
          title => 'プレゼント',
          path => 'banner/banner_03.jpg',
          banner_height => 0,
          banner_width => 0,
          editor_select => 0,
          set_period => 2,
          status => 2,
          url => 'http://www.powercms.jp/#present',
        },
        {
          title => '耳より情報',
          path => 'banner/banner_02.jpg',
          banner_height => 0,
          banner_width => 0,
          editor_select => 0,
          set_period => 2,
          status => 2,
          url => 'http://www.powercms.jp/#good_news',
        },
        {
          title => 'CAMPAIGN',
          path => 'banner/banner_01.jpg',
          banner_height => 0,
          banner_width => 0,
          editor_select => 0,
          set_period => 2,
          status => 2,
          url => 'http://www.powercms.jp/#campaign',
        },
    ];
    return $__website_campaigns;
}

sub create_blogs {
    my %__blogs = (
        news => {
            name => '新着情報',
            site_url => '/::/news/',
            site_path => 'news',
            theme_id => 'power_cms_blog_news',
        },
        examples => {
            name => '導入事例',
            site_url => '/::/case_study/',
            site_path => 'case_study',
            theme_id => 'power_cms_blog_case_study',
        },
        blog => {
            name => 'ブログ',
            site_url => '/::/blog/',
            site_path => 'blog',
            theme_id => 'power_cms_blog_blog',
        },
    );
    return \%__blogs;
}

my @allowed_file_extensions = (
    'jpg',
    'jpeg',
    'gif',
    'png',
);

sub save_blog_assets {
    my ( $blog ) = @_;
    return unless $blog;
    my $site_path = site_path( $blog ) or return;
    my $theme_id = $blog->theme_id or return;
    my $author_id = $blog->modified_by || $blog->created_by;
    my $author = MT->model( 'author' )->load( { id => $author_id } );
    my $theme = $blog->theme;
    my $theme_static_path = File::Spec->catdir( $theme->path, 'blog_static' );
    my $file_path_list = directory_file_list( $theme_static_path );
    my $q_theme_static_path = quotemeta( $theme_static_path );
    for my $file_path ( @$file_path_list ) {
        next unless grep { $file_path =~ /$_$/ } @allowed_file_extensions;
        $file_path =~ s/$q_theme_static_path/$site_path/;
        if ( -f $file_path ) {
            my $basename = file_label( $file_path );
            my %params = ( file => $file_path,
                           author => $author,
                           label => $basename,
                         );
            my $asset = save_asset( MT->instance(), $blog, \%params ) or die;
        }
    }
}

sub directory_file_list {
    my ( $directory_path, $file_path_list ) = @_;
    return unless -d $directory_path;
    opendir( my $dh, $directory_path ) or return;
    my @files = readdir( $dh );
    closedir( $dh );
    $file_path_list ||= [];
    for my $file ( @files ) {
        next if $file =~ /^\./;
        next if $file =~ /^\.\./;
        my $file_path = File::Spec->catfile( $directory_path, $file );
        if ( -d $file_path ) {
            directory_file_list( $file_path, $file_path_list );
        } elsif ( -f $file_path ) {
            push( @$file_path_list, $file_path );
        }
    }
    return $file_path_list;
}

# sub save_blog_assets {
#     my ( $blog ) = @_;
#     return unless $blog;
#     my $author_id = $blog->modified_by || $blog->created_by;
#     my $author = MT->model( 'author' )->load( { id => $author_id } );
#     my $site_path = site_path( $blog );
#     return unless $site_path;
#     my @exclude;
#     unless ( $blog->is_blog ) {
#         my @child_blogs = MT->model( 'blog' )->load( { parent_id => $blog->id } );
#         for my $child_blog ( @child_blogs ) {
#             my $child_blog_site_path = site_path( $child_blog );
#             push( @exclude, $child_blog_site_path );
#         }
#     }
#     return save_assets_in_directory( $site_path, $blog, $author, \@exclude );
# }
#
# sub save_assets_in_directory {
#     my ( $directory_path, $blog, $author, $exclude ) = @_;
#     opendir( my $dh, $directory_path ) or return;
#     my @files = readdir( $dh );
#     closedir( $dh );
#     my $app = MT->instance();
#     my $mt_dir = $app->{ mt_dir };
#     $mt_dir = quotemeta( $mt_dir );
#     FILES:
#     for my $file ( @files ) {
#         next if $file =~ /^\./;
#         next if $file =~ /^\.\./;
#         next if $file eq 'assets_c';
#         next if $file eq 'templates_c';
#         next if $file eq 'cache';
#         my $file_path = File::Spec->catfile( $directory_path, $file );
#         next if $file_path =~ /^$mt_dir/;
#         $file_path = Encode::decode_utf8( $file_path ); # FIXME
#         if ( $exclude ) {
#             for my $exclude_path ( @$exclude ) {
#                 my $search = quotemeta( $exclude_path );
#                 if ( $file_path =~ /$search/ ) {
#                     next FILES;
#                 }
#             }
#         }
#         if ( -d $file_path ) {
#             save_assets_in_directory( $file_path, $blog, $author, $exclude );
#         } else {
#             next unless grep { $file =~ /$_$/ } @allowed_file_extensions;
#             my $basename = file_label( $file_path );
#             my %params = ( file => $file_path,
#                            author => $author,
#                            label => $basename,
#                          );
#             my $asset = save_asset( MT->instance(), $blog, \%params ) or die;
#         }
#     }
# }

sub contactform_textarea_mtml {
    return <<'MTML';
<$mt:SetVar name="display_description" value="0"$>
<mt:unless name="field_mode"><$mt:SetVar name="display_description" value="1"$></mt:unless>
<mt:if name="field_error"><$mt:SetVar name="display_description" value="1"$></mt:if>
<div id="<mt:var name="field_basename">-field" class="contact-form-field clf">
	<p class="form-label">
		<label for="<mt:var name="field_basename">">
		<mt:var name="field_name">
		<mt:if name="field_description"><mt:if name="display_description"><span class="description"><mt:var name="field_description"></span></mt:if></mt:if>
		<mt:if name="field_required"><mt:if name="display_description"><span class="must">※必須</span></mt:if></mt:if>
		</label>
	</p>
	<p class="form-element">
	<mt:if name="field_mode">
		<mt:if name="field_error">
		<textarea class="contact-form-textarea" name="<mt:var name="field_basename">" id="<mt:var name="field_basename">"><mt:var name="field_raw" escape="html"></textarea>
		<br /><span class="field_error">
			<mt:if name="field_error" eq="invalid">
				<$MT:Trans phrase="Invalid '[_1]'." component="ContactForm" params="$field_name"$>
			<mt:elseif name="field_error" eq="over_limit">
				<$MT:Trans phrase="Input exceeds the limit number of characters'[_1]'." component="ContactForm" params="$field_name"$>
			<mt:else>
				<$MT:Trans phrase="'[_1]' is required." component="ContactForm" params="$field_name"$>
			</mt:else>
			</mt:if>
		</span>
		<mt:else>
		<span class="field_value"><mt:var name="field_value" escape="html"><input type="hidden" name="<mt:var name="field_basename">" value="<mt:var name="field_value" escape="html">" /></span>
		</mt:else>
		</mt:if>
	<mt:else>
		<textarea class="contact-form-textarea" name="<mt:var name="field_basename">" id="<mt:var name="field_basename">"><mt:var name="field_default" escape="html"></textarea>
	</mt:else>
	</mt:if>
	</p>
</div>
MTML
}

sub contactform_text_mtml {
    return <<'MTML';
<$mt:SetVar name="display_description" value="0"$>
<mt:unless name="field_mode"><$mt:SetVar name="display_description" value="1"$></mt:unless>
<mt:if name="field_error"><$mt:SetVar name="display_description" value="1"$></mt:if>
<div id="<mt:var name="field_basename">-field" class="contact-form-field clf">
	<p class="form-label">
		<label for="<mt:var name="field_basename">">
		<mt:var name="field_name">
		<mt:if name="field_description"><mt:if name="display_description"><span class="description"><mt:var name="field_description"></span></mt:if></mt:if>
		<mt:if name="field_required"><mt:if name="display_description"><span class="must">※必須</span></mt:if></mt:if>
		</label>
	</p>
	<p class="form-element">
	<mt:if name="field_mode">
		<mt:if name="field_error">
		<input type="text" class="contact-form-text-full" name="<mt:var name="field_basename">" id="<mt:var name="field_basename">" value="<mt:var name="field_raw" escape="html">" />
		<br /><span class="field_error">
			<mt:if name="field_error" eq="invalid">
				<$MT:Trans phrase="Invalid '[_1]'." component="ContactForm" params="$field_name"$>
			<mt:elseif name="field_error" eq="over_limit">
				<$MT:Trans phrase="Input exceeds the limit number of characters'[_1]'." component="ContactForm" params="$field_name"$>
			<mt:else>
				<$MT:Trans phrase="'[_1]' is required." component="ContactForm" params="$field_name"$>
			</mt:else>
			</mt:if>
		</span>
		<mt:else>
		<span class="field_value"><mt:var name="field_value" escape="html"><input type="hidden" name="<mt:var name="field_basename">" value="<mt:var name="field_value" escape="html">" /></span>
		</mt:else>
		</mt:if>
	<mt:else>
		<input type="text" class="contact-form-text-full" name="<mt:var name="field_basename">" id="<mt:var name="field_basename">" value="<mt:var name="field_default" escape="html">" />
	</mt:else>
	</mt:if>
	</p>
</div>
MTML
}

1;
