# Movable Type (r) (C) 2001-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package MT::Commercial::L10N::ja;

use strict;
use base 'MT::Commercial::L10N::en_us';
use vars qw( %Lexicon );
use utf8;
## The following is the translation table.

%Lexicon = (

## addons/Commercial.pack/config.yaml
	'http://www.sixapart.com/movabletype/' => 'http://www.sixapart.jp/movabletype/',
	'Professional designed, well structured and easily adaptable web site. You can customize default pages, footer and top navigation easily.' => 'バナー画像、水平型のナビゲーションなど、ホームページ用途に適したデザインです。あらかじめ用意されたページをカスタマイズして、簡単にウェブサイトを作成できます。',
	'_PWT_ABOUT_BODY' => '
<p><strong>以下の文章はサンプルです。内容を適切に書き換えてください。</strong></p>
<p>いろはにほへと ちりぬるを わかよたれそ つねならむ うゐのおくやま けふこえて あさきゆめみし ゑひもせす</p>
<p>色は匂へど 散りぬるを 我が世誰ぞ 常ならむ 有為の奥山 今日越えて 浅き夢見じ 酔ひもせず</p>
',
	'_PWT_CONTACT_BODY' => '
<p><strong>以下の文章はサンプルです。内容を適切に書き換えてください。</strong></p>
<p>お問い合わせはメールで: email (at) domainname.com</p>
',
	'Welcome to our new website!' => '新しいウェブサイトへようこそ!',
	'_PWT_HOME_BODY' => '
<p><strong>以下の文章はサンプルです。内容を適切に書き換えてください。</strong></p>
<p>いろはにほへと ちりぬるを わかよたれそ つねならむ うゐのおくやま けふこえて あさきゆめみし ゑひもせす</p>
<p>色は匂へど 散りぬるを 我が世誰ぞ 常ならむ 有為の奥山 今日越えて 浅き夢見じ 酔ひもせず</p>
<p>あめ つち ほし そら やま かは みね たに くも きり むろ こけ ひと いぬ うへ すゑ ゆわ さる おふ せよ えのえを なれ ゐて</p>
',
	'Create a blog as a part of structured website. This works best with Professional Website theme.' => 'プロフェッショナル ウェブサイトと連携する、ブログのテーマです。',
	'Unknown Type' => '不明な種類',
	'Unknown Object' => '不明なオブジェクト',
	'Not Required' => '必須ではない',
	'Are you sure you want to delete the selected CustomFields?' => '選択したカスタムフィールドを削除してもよろしいですか？',
	'Photo' => '写真',
	'Embed' => '埋め込み',
	'Custom Fields' => 'カスタムフィールド',
	'Field' => 'フィールド',
	'Template tag' => 'テンプレートタグ',
	'Updating Universal Template Set to Professional Website set...' => '汎用テンプレートセットをプロフェッショナルウェブサイトテンプレートセットにアップデートしています...',
	'Migrating CustomFields type...' => 'カスタムフィールドのタイプをアップデートしています...',
	'Converting CustomField type...' => 'カスタムフィールドのタイプを変換しています...',
	'Professional Styles' => 'プロフェッショナルスタイル',
	'A collection of styles compatible with Professional themes.' => 'プロフェッショナルテーマと互換のあるスタイルです。',
	'Professional Website' => 'プロフェッショナル ウェブサイト',
	'Blog Index' => 'ブログのメインページ',
	'Header' => 'ヘッダー',
	'Footer' => 'フッター',
	'Entry Metadata' => 'ブログ記事のメタデータ',
	'Page Detail' => 'ウェブページの詳細',
	'Footer Links' => 'フッターのリンク',
	'Powered By (Footer)' => 'Powered By (フッター)',
	'Recent Entries Expanded' => '最近のブログ記事 (拡張)',
	'Main Sidebar' => 'メインサイドバー',
	'Blog Activity' => 'アクティビティ',
	'Professional Blog' => 'プロフェッショナルブログ',
	'Entry Detail' => 'ブログ記事の詳細',
	'Blog Archives' => 'アーカイブ',

## addons/Commercial.pack/lib/CustomFields/App/CMS.pm
	'Show' => '表示項目',
	'Date & Time' => '日付と時刻',
	'Date Only' => '日付',
	'Time Only' => '時刻',
	'Please enter all allowable options for this field as a comma delimited list' => 'このフィールドで有効なすべてのオプションをカンマで区切って入力してください。',
	'Exclude Custom Fields' => 'カスタムフィールドの除外',
	'[_1] Fields' => '[_1]フィールド',
	'Edit Field' => 'フィールドの編集',
	'Invalid date \'[_1]\'; dates must be in the format YYYY-MM-DD HH:MM:SS.' => '日時が不正です。日時はYYYY-MM-DD HH:MM:SSの形式で入力してください。',
	'Invalid date \'[_1]\'; dates should be real dates.' => '日時が不正です。',
	'Please enter valid URL for the URL field: [_1]' => 'URLを入力してください。[_1]',
	'Please enter some value for required \'[_1]\' field.' => '「[_1]」は必須です。値を入力してください。',
	'Please ensure all required fields have been filled in.' => '必須のフィールドに値が入力されていません。',
	'The template tag \'[_1]\' is an invalid tag name.' => '[_1]というタグ名は不正です。',
	'The template tag \'[_1]\' is already in use.' => '[_1]というタグは既に存在します。',
	'blog and the system' => 'ブログとシステム',
	'website and the system' => 'ウェブサイトとシステム',
	'The basename \'[_1]\' is already in use. It must be unique within this [_2].' => '[_1]というベースネームはすでに使われています。[_2]内で重複しない値を入力してください。',
	'You must select other type if object is the comment.' => 'コメントでない場合、他の種類を選択する必要があります。',
	'type' => '種類',
	'Customize the forms and fields for entries, pages, folders, categories, and users, storing exactly the information you need.' => 'ブログ記事、ウェブページ、フォルダ、カテゴリ、ユーザーのフォームとフィールドをカスタマイズして、必要な情報を格納することができます。',
	' ' => ' ',
	'Single-Line Text' => 'テキスト',
	'Multi-Line Text' => 'テキスト(複数行)',
	'Checkbox' => 'チェックボックス',
	'Date and Time' => '日付と時刻',
	'Drop Down Menu' => 'ドロップダウン',
	'Radio Buttons' => 'ラジオボタン',
	'Embed Object' => '埋め込みオブジェクト',
	'Post Type' => '投稿タイプ',

## addons/Commercial.pack/lib/CustomFields/BackupRestore.pm
	'Restoring custom fields data stored in MT::PluginData...' => 'MT::PluginDataに保存されているカスタムフィールドのデータを復元しています...',
	'Restoring asset associations found in custom fields ( [_1] ) ...' => 'カスタムフィールド([_1])に含まれるアイテムとの関連付けを復元しています...',
	'Restoring url of the assets associated in custom fields ( [_1] )...' => 'カスタムフィールド([_1])に含まれるアイテムのURLを復元しています...',

## addons/Commercial.pack/lib/CustomFields/Field.pm
	'The template tag \'[_1]\' is already in use in the system level' => '[_1]というタグは既にシステムに存在します。',
	'The template tag \'[_1]\' is already in use in [_2]' => '[_1]というタグは既に[_2]に存在します。',
	'The template tag \'[_1]\' is already in use in this blog' => '[_1]というタグは既にこのブログに存在します。',
	'The \'[_1]\' of the template tag \'[_2]\' that is already in use in [_3] is [_4].' => '[_1]が違う\'[_2]\'というタグが[_3]に見つかったため、保存できません。([_1]: [_4])',
	'_CF_BASENAME' => 'ベースネーム',

## addons/Commercial.pack/lib/CustomFields/Template/ContextHandlers.pm
	'Are you sure you have used a \'[_1]\' tag in the correct context? We could not find the [_2]' => '[_2]が見つかりませんでした。[_1]タグを正しいコンテキストで使用しているか確認してください。',
	'You used an \'[_1]\' tag outside of the context of the correct content; ' => '[_1]タグを正しいコンテキストで使用していません。',

## addons/Commercial.pack/lib/CustomFields/Theme.pm
	'[_1] custom fields' => 'カスタムフィールド: [_1]',
	'a field on this blog' => 'このブログのカスタムフィールド',
	'a field on system wide' => 'システム全体のカスタムフィールド',
	'Conflict of [_1] "[_2]" with [_3]' => '[_3] と[_1]「[_2]」が衝突しています',
	'Template Tag' => 'テンプレートタグ',

## addons/Commercial.pack/lib/CustomFields/Upgrade.pm
	'Moving metadata storage for pages...' => 'ウェブページのメタデータ格納先を変更しています...',
	'Removing CustomFields display-order from plugin data...' => 'カスタムフィールドの古い並び順を削除しています...',
	'Removing unlinked CustomFields...' => '不要なカスタムフィールドを削除しています。',

## addons/Commercial.pack/lib/CustomFields/Util.pm
	'Cloning fields for blog:' => 'カスタムフィールドを複製しています:',

## addons/Commercial.pack/templates/professional/blog/about_this_page.mtml

## addons/Commercial.pack/templates/professional/blog/archive_index.mtml

## addons/Commercial.pack/templates/professional/blog/archive_widgets_group.mtml

## addons/Commercial.pack/templates/professional/blog/author_archive_list.mtml

## addons/Commercial.pack/templates/professional/blog/calendar.mtml

## addons/Commercial.pack/templates/professional/blog/categories.mtml

## addons/Commercial.pack/templates/professional/blog/category_archive_list.mtml

## addons/Commercial.pack/templates/professional/blog/comment_detail.mtml

## addons/Commercial.pack/templates/professional/blog/comment_form.mtml

## addons/Commercial.pack/templates/professional/blog/comment_listing.mtml

## addons/Commercial.pack/templates/professional/blog/comment_preview.mtml

## addons/Commercial.pack/templates/professional/blog/comment_response.mtml

## addons/Commercial.pack/templates/professional/blog/comments.mtml

## addons/Commercial.pack/templates/professional/blog/creative_commons.mtml

## addons/Commercial.pack/templates/professional/blog/current_author_monthly_archive_list.mtml

## addons/Commercial.pack/templates/professional/blog/current_category_monthly_archive_list.mtml

## addons/Commercial.pack/templates/professional/blog/date_based_author_archives.mtml

## addons/Commercial.pack/templates/professional/blog/date_based_category_archives.mtml

## addons/Commercial.pack/templates/professional/blog/dynamic_error.mtml

## addons/Commercial.pack/templates/professional/blog/entry.mtml

## addons/Commercial.pack/templates/professional/blog/entry_detail.mtml

## addons/Commercial.pack/templates/professional/blog/entry_listing.mtml
	'Recently by <em>[_1]</em>' => '<em>[_1]</em>の最近のブログ記事',

## addons/Commercial.pack/templates/professional/blog/entry_metadata.mtml

## addons/Commercial.pack/templates/professional/blog/entry_summary.mtml

## addons/Commercial.pack/templates/professional/blog/footer.mtml

## addons/Commercial.pack/templates/professional/blog/footer_links.mtml
	'Links' => 'リンク',

## addons/Commercial.pack/templates/professional/blog/header.mtml

## addons/Commercial.pack/templates/professional/blog/javascript.mtml

## addons/Commercial.pack/templates/professional/blog/main_index.mtml

## addons/Commercial.pack/templates/professional/blog/main_index_widgets_group.mtml

## addons/Commercial.pack/templates/professional/blog/monthly_archive_dropdown.mtml

## addons/Commercial.pack/templates/professional/blog/monthly_archive_list.mtml

## addons/Commercial.pack/templates/professional/blog/navigation.mtml

## addons/Commercial.pack/templates/professional/blog/openid.mtml

## addons/Commercial.pack/templates/professional/blog/page.mtml

## addons/Commercial.pack/templates/professional/blog/pages_list.mtml

## addons/Commercial.pack/templates/professional/blog/powered_by_footer.mtml

## addons/Commercial.pack/templates/professional/blog/recent_assets.mtml

## addons/Commercial.pack/templates/professional/blog/recent_comments.mtml
	'<a href="[_1]">[_2] commented on [_3]</a>: [_4]' => '<a href="[_1]">[_2] から [_3] に対するコメント</a>: [_4]',

## addons/Commercial.pack/templates/professional/blog/recent_entries.mtml

## addons/Commercial.pack/templates/professional/blog/search.mtml

## addons/Commercial.pack/templates/professional/blog/search_results.mtml

## addons/Commercial.pack/templates/professional/blog/sidebar.mtml

## addons/Commercial.pack/templates/professional/blog/signin.mtml

## addons/Commercial.pack/templates/professional/blog/syndication.mtml

## addons/Commercial.pack/templates/professional/blog/tag_cloud.mtml

## addons/Commercial.pack/templates/professional/blog/tags.mtml

## addons/Commercial.pack/templates/professional/blog/trackbacks.mtml

## addons/Commercial.pack/templates/professional/website/blog_index.mtml

## addons/Commercial.pack/templates/professional/website/blogs.mtml
	'Entries ([_1]) Comments ([_2])' => '記事([_1]) コメント([_2])',

## addons/Commercial.pack/templates/professional/website/comment_detail.mtml

## addons/Commercial.pack/templates/professional/website/comment_form.mtml

## addons/Commercial.pack/templates/professional/website/comment_listing.mtml

## addons/Commercial.pack/templates/professional/website/comment_preview.mtml

## addons/Commercial.pack/templates/professional/website/comment_response.mtml

## addons/Commercial.pack/templates/professional/website/comments.mtml

## addons/Commercial.pack/templates/professional/website/dynamic_error.mtml

## addons/Commercial.pack/templates/professional/website/entry_metadata.mtml

## addons/Commercial.pack/templates/professional/website/entry_summary.mtml

## addons/Commercial.pack/templates/professional/website/footer.mtml

## addons/Commercial.pack/templates/professional/website/footer_links.mtml

## addons/Commercial.pack/templates/professional/website/header.mtml

## addons/Commercial.pack/templates/professional/website/javascript.mtml

## addons/Commercial.pack/templates/professional/website/main_index.mtml

## addons/Commercial.pack/templates/professional/website/navigation.mtml

## addons/Commercial.pack/templates/professional/website/openid.mtml

## addons/Commercial.pack/templates/professional/website/page.mtml

## addons/Commercial.pack/templates/professional/website/pages_list.mtml

## addons/Commercial.pack/templates/professional/website/powered_by_footer.mtml

## addons/Commercial.pack/templates/professional/website/recent_entries_expanded.mtml
	'on [_1]' => '[_1]ブログ上',
	'By [_1] | Comments ([_2])' => '[_1] | コメント([_2])',

## addons/Commercial.pack/templates/professional/website/search.mtml

## addons/Commercial.pack/templates/professional/website/search_results.mtml
	'By default, this search engine looks for all words in any order. To search for an exact phrase, enclose the phrase in quotes:' => 'すべての単語が順序に関係なく検索されます。フレーズで検索したいときは引用符で囲んでください。',

## addons/Commercial.pack/templates/professional/website/sidebar.mtml

## addons/Commercial.pack/templates/professional/website/signin.mtml

## addons/Commercial.pack/templates/professional/website/syndication.mtml

## addons/Commercial.pack/templates/professional/website/tag_cloud.mtml

## addons/Commercial.pack/templates/professional/website/tags.mtml

## addons/Commercial.pack/templates/professional/website/trackbacks.mtml

## addons/Commercial.pack/tmpl/asset-chooser.tmpl
	'Choose [_1]' => '[_1]を選択',

## addons/Commercial.pack/tmpl/category_fields.tmpl
	'Show These Fields' => 'フィールド表示',

## addons/Commercial.pack/tmpl/cfg_customfields.tmpl
	'Data have been saved to custom fields.' => 'データはカスタムフィールドに保存されました。',
	'Save changes to blog (s)' => 'ブログに変更を保存',
	'No custom fileds could be found. <a href="[_1]">Create a field</a> now.' => 'カスタムフィールドがありません。<a href="[_1]">カスタムフィールドを作成</a>する。',

## addons/Commercial.pack/tmpl/edit_field.tmpl
	'Edit Custom Field' => 'カスタムフィールドの編集',
	'Create Custom Field' => 'カスタムフィールドの作成',
	'The selected field(s) has been deleted from the database.' => '選択されたフィールドはデータベースから削除されました。',
	'You must enter information into the required fields highlighted below before the custom field can be created.' => 'すべての必須フィールドに値を入力してください。',
	'You must save this custom field before setting a default value.' => '既定の値を設定する前に、このカスタムフィールドを保存する必要があります。',
	'Choose the system object where this custom field should appear.' => 'フィールドを追加するオブジェクトを選択してください。',
	'Required?' => '必須?',
	'Is data entry required in this custom field?' => 'このカスタムフィールドはデータ入力が必須ですか?',
	'Must the user enter data into this custom field before the object may be saved?' => 'フィールドに値は必須ですか?',
	'Default' => '既定値',
	'The basename must be unique within this [_1].' => 'ベースネームは、[_1]内で重複しない値を入力してください。',
	q{Warning: Changing this field's basename may require changes to existing templates.} => q{警告: このフィールドのベースネームを変更すると、テンプレートにも修正が必要になることがあります。},
	'Example Template Code' => 'テンプレートの例',
	'Show In These [_1]' => '[_1]に表示',
	'Save this field (s)' => 'このフィールドを保存 (s)',
	'field' => 'フィールド',
	'fields' => 'フィールド',
	'Delete this field (x)' => 'フィールドを削除 (x)',

## addons/Commercial.pack/tmpl/export_field.tmpl
	'Object' => 'オブジェクト',

## addons/Commercial.pack/tmpl/listing/field_list_header.tmpl

## addons/Commercial.pack/tmpl/reorder_fields.tmpl
	'open' => '開く',
	'click-down and drag to move this field' => 'フィールドをドラッグして移動します。',
	'click to %toggle% this box' => '%toggle%ときはクリックします。',
	'use the arrow keys to move this box' => '矢印キーでボックスを移動します。',
	', or press the enter key to %toggle% it' => '%toggle%ときはENTERキーを押します。',

);

1;
