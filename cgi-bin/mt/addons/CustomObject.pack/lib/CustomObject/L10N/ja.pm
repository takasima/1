package CustomObject::L10N::ja;
use strict;
use base qw/CustomObject::L10N/;

our %Lexicon = (
    'Create and manage custom object.' => 'カスタム項目を作成・管理します。',
    'Create Group' => 'グループの作成',
    'Manage Groups' => 'グループの管理',
    ' Group' => 'グループ',
    'Name' => '名前',
    'Basename' => 'ベースネーム',
    '(Unknown)' => '不明なユーザー',
    # 'Folder-Object' => 'フォルダ別カスタム項目',
    'Modified on' => '最終更新日',
    'Publish Date' => '公開日',
    'Closed' => '掲載終了',
    'Active' => '有効',
    'End date' => '掲載終了日',
    'Set Period' => '期間指定',
    'Unpublish' => '公開を取り消し',
    'Change Tag' => 'タグの変更',
    'Remove Relation' => '関連付けの解除',
    'Number of revisions per CustomObject' => 'カスタム項目更新履歴数',
    'CustomObject Scheduled Task' => 'カスタム項目のタスク',
    'All' => 'すべて',
    '[_1] where name contains [_2]' => '名前に [_2] を含む[_1]',
    'CustomObject Administrator' => 'カスタム項目管理者',
    'Can create CustomObject, edit CustomObject.' => 'カスタム項目の作成と管理ができます。',
    "[_1] '[_2]' (ID:[_3]) created by '[_4]'" => "'[_4]'が[_1]'[_2]'(ID:[_3])を作成しました。",
    "[_1] '[_2]' (ID:[_3]) edited by '[_4]'" => "'[_4]'が[_1]'[_2]'(ID:[_3])を更新しました。",
    "[_1] '[_2]' (ID:[_3]) deleted by '[_4]'" => "'[_4]'が[_1]'[_2]'(ID:[_3])を削除しました。",
    "[_1] Group '[_2]' (ID:[_3]) created by '[_4]'" => "'[_4]'が[_1]グループ'[_2]'(ID:[_3])を作成しました。",
    "[_1] Group '[_2]' (ID:[_3]) edited by '[_4]'" => "'[_4]'が[_1]グループ'[_2]'(ID:[_3])を更新しました。",
    "[_1] Group '[_2]' (ID:[_3]) deleted by '[_4]'" => "'[_4]'が[_1]グループ'[_2]'(ID:[_3])を削除しました。",
    'Label(en)' => '項目名(英)',
    'Label(ja)' => '項目名(日)',
    'Label plural' => '項目名複数形(英)',
    'Module Template' => 'モジュールテンプレート',
    'Use WYSIWYG' => 'リッチテキストを利用',
    'Editor CSS' => 'エディタCSS',
    'Create Object' => 'カスタム項目作成',

    # edit_customobject.tmpl
    'Edit [_1]' => '[_1]の編集',
    'Create [_1]' => '[_1]の作成',
    'List of [_1]' => '[_1]の一覧',
    '[_1] requires Name.' => '[_1]の名前は必須です。',
    'Save this [_1] (s)' => 'この[_1]を保存 (s)',
    'Delete this [_1] (x)' => 'この[_1]を削除 (x)',
    'Created on' => '作成日',
    'Are you sure you want to remove this [_1]?' => 'この[_1]を本当に削除しますか?',
    'Preview this [_1] (v)' => 'この[_1]をプレビュー (v)',

    # edit_customobjectgroup.tmpl
    'Edit [_1] Group' => '[_1]グループの編集',
    'Create [_1] Group' => '[_1]グループの作成',
    '[_1] of Group' => 'グループの[_1]',
    'Add new [_1]' => '新しい[_1]を追加',
    'Module Template' => 'モジュールテンプレート',
    'Are you sure you want to move to other page?' => '他のページに移動してもよろしいですか?',
    'Enter a Group name.' => 'グループ名を入力してください。',
    'Another group already exists by that name.' => '同名のグループが既に存在します。',
    'Reverse Check' => 'チェックを反転',
    'Reverse Item' => '表示順を反転',
    'website and all blogs' => 'すべてのウェブサイト/ブログ',
    'Group Settings' => 'グループの設定',
    'Name of Group' => 'グループ名',
    'Add first' => '先頭に追加',
    'Add last' => '末尾に追加',
    'Create Module' => 'モジュールの作成',
    'Edit Module' => 'モジュールの編集',
    'Tag is' => 'タグが',

    # list_customobject.tmpl
    'Select [_1]' => '[_1]を選択',
    'Manage [_1]' => '[_1]の管理',
    'Are you sure you want to import [_1] from CSV?' => 'CSVをアップロードして[_1]をインポートしますか?',
    'Are you sure you want to download all [_1]?' => '[_1]をエクスポートしますか?',
    'The [_1] has been deleted from database.' => '[_1]をデータベースから削除しました。',
    'Added Tags to selected [_1].' => '選択された[_1]にタグを追加しました。',
    'Not added Tags to selected [_1].' => '選択された[_1]にタグを追加できませんでした。',
    'Remove Tags from selected [_1].' => '選択された[_1]からタグを削除しました。',
    'Not removed Tags from selected [_1].' => '選択された[_1]からタグを削除できませんでした。',
    'The [_1] has been published.' => '[_1]のステータスを公開にしました。',
    'The [_1] has been unpublished.' => '[_1]のステータスを非公開にしました。',
    'The [_1] has been closed.' => '[_1]のステータスを掲載終了にしました。',
    'The [_1] has not been published.' => '公開する[_1]はありません。',
    'The [_1] has not been unpublished.' => '公開を取り消す[_1]はありません。',
    'The [_1] has not been closed.' => '掲載終了にする[_1]はありません。',
    'Are you sure you want to import [_1] from CSV?' => 'CSVから[_1]をインポートしてよろしいですか?',
    'The [_1] has been imported from CSV.' => 'CSVから[_1]をインポートしました。',
    'The [_1] has not been imported from CSV.'  => 'CSVから[_1]をインポートできませんでした。',
    'Import from CSV' => 'CSVからのインポート',
    'Download CSV' => 'CSVのダウンロード',
    'Please select a file to upload.' => 'アップロードするCSVファイルを選択してください。',
    'Neither Text::CSV_XS nor Text::CSV is available.' => 'Text::CSV_XS / Text::CSVがインストールされていません。',

    # list_customobjectgroup.tmpl
    'Manage [_1] Groups' => '[_1]グループの管理',
    'The [_1] Group has been deleted from database.' => '[_1]グループをデータベースから削除しました。',
    'Create [_1] Group' => '[_1]グループの作成',
    'My [_1] Groups' => '自分の[_1]グループ',
    '[_1] Groups of this Website' => 'ウェブサイトの[_1]グループ',

    # customobjectgroup_table.tmpl
    'Delete selected [_1] Groups (x)' => '選択された[_1]を削除 (x)',
    '[_1] Groups' => '[_1]グループ',
    'Object Count' => '項目数',

    # customobject_table.tmpl
    'Unpublish [_1] from selected datas (u)' => '選択された[_1]の公開を取り消す (x)',
    'Publish [_1] from selected datas (p)' => '選択された[_1]を公開 (p)',

    'Tags with [_1]' => '[_1]のタグ',

    # create_customobject.tmpl
    'Japanese Name' => '日本語名',
    'Class Type' => 'クラス(モデル)名',
    'Label(Plural)' => 'ラベル(複数形)',
    'Description' => '英文説明',
    'Japanese Description' => '和文説明',
    'Menu Order' => 'メニューの表示順',
    'Please confirm your input values.' => '入力内容を確認してください。',
    'Models of the same name already exists.' => 'クラス(モデル)名が重複しています',
    "Error writing to '[_1]'" => "'[_1]'に書き込めません",
    "Plugin '[_1]' already exist." => "プラグイン'[_1]'が既に存在します。",
    'New Plugin created successfully.' => 'プラグインを作成しました。',
    "Alphabet only(example:'Book')." => "アルファベットのみ(例:'Book')",
    "Alphabet only(example:'Book')." => "アルファベットのみ(例:'Book')",
    "ID is Alphabet only(example:'Book')." => "IDにはアルファベットのみ利用できます(例:'Book')。",
    "This field is required." => "この項目は必須です。",
    "Numerical or Floating point(example:'1.0')." => "数値または浮動小数点のみ(例:'1.0')。",
    "Japanese Name(example:'Book')." => "日本語名(例:'書籍')。",
    "Lowercase Alphabet only(example:'book')." => "アルファベット小文字のみ(例:'book')",
    "Lowercase Alphabet only(example:'book')." => "アルファベット小文字のみ(例:'book')",
    "Alphabet only(example:'Books')." => "アルファベットのみ(例:'Books')。",
    "Alphabet only(example:'Books')." => "アルファベットのみ(例:'Books')。",
    "Description in English(example:'Create and Manage Book.')." => "英文説明(例:'Create and Manage Book.')。",
    "Description in Japanese(example:'Create and Manage Book.')." => "和文説明(例:'書籍の作成と管理をします。')。",
    "Numerical only(example:'500')." => "数値のみ(例:'500')",
    'Some characters are not available.' => '利用できないキャラクタが含まれています。',
    'Are you sure you want to create this Plugin?' => 'この内容でカスタム項目を作成しますか?',
    'Create Plugin!' => 'この内容でプラグインを作成',
    'Create' => '作成する',

    # include/js_attachfield_multi.tmpl
    'Select'     => '選択',
    'Select (s)' => '選択 (s)',

    # Filter
    'Published [_1]' => '公開されている[_1]',
    'Unpublished [_1]' => '下書きの[_1]',
    'Unapproved [_1]' => '承認待ちの[_1]',
    'Scheduled [_1]' => '公開予約されている[_1]',
    'Closed [_1]' => '掲載が終了した[_1]',
    'Name(Object Count)' => '名前 (項目数)',
    'Add new Object to last' => '新しい項目を末尾に追加',
    'Add new Object to first' => '新しい項目を先頭に追加',

    # Rebuild
    "An error occurred publishing archive '[_1]'." => "アーカイブ「[_1]」の再構築中にエラーが発生しました。",

    # Customfield
    "Invalid date '[_1]'; dates must be in the format YYYY-MM-DD HH:MM:SS." => "日時が不正です。日時はYYYY-MM-DD HH:MM:SSの形式で入力してください。",
    "Invalid date '[_1]'; dates should be real dates." => "日時が不正です。",
    'Please enter valid URL for the URL field: [_1]' => 'URLを入力してください。[_1]',
    "Please enter some value for required '[_1]' field." => "「[_1]」は必須です。値を入力してください。",
    'Please ensure all required fields have been filled in.' => '必須のフィールドに値が入力されていません。',

    # Memo
    'Add new memo' => 'メモを追加',
    'Memo' => 'メモ',

    # Clone
    'Restore Custom Objects Relation...' => 'カスタム項目の関連付けを調整しています...',
    'Restore Custom Fields Object Relation...' => 'オブジェクト間の関連付けを調整しています...',

    # Restore
    'Restoring customobject associations found in custom fields ...' => 'カスタムフィールドに含まれるカスタムオブジェクトとの関連付けを復元しています...',

    # Task
    'Cleanup order' => 'カスタムオブジェクトグループのデータの整合性に関する調整',

    # AltL10N
    # 'Label plural' => 'オブジェクト名複数形(英)',
    # 'CustomObject' => 'カスタム項目',
    # 'Custom Object' => 'カスタム項目',
    # 'CustomObjects' => 'カスタム項目',
    # 'customobject' => 'カスタム項目',
    # 'My CustomObject' => '自分のカスタム項目',
    # 'My CustomObjects' => '自分のカスタム項目',
    # 'My CustomObject Group' => '自分のカスタム項目グループ',
    # 'Folder-CustomObject' => 'フォルダ別カスタム項目',
    # 'Tags with CustomObject' => 'カスタム項目のタグ',
    # 'Multiple CustomObject' => 'カスタム項目(複数選択)',
    # 'Create CustomObject' => 'カスタム項目の作成',
    # 'Edit CustomObject' => 'カスタム項目の編集',
    # 'Manage CustomObjects' => 'カスタム項目の一覧',
    # 'List of CustomObjects' => 'カスタム項目の一覧',
    # 'Delete selected CustomObjects (x)' => '選択したカスタム項目を削除 (x)',
    # 'Delete this CustomObject (x)' => 'このカスタム項目を削除 (x)',
    # 'Save this CustomObject (s)' => 'このカスタム項目を保存 (s)',
    # 'CustomObject Group' => 'カスタム項目グループ',
    # 'CustomObject Groups' => 'カスタム項目グループ',
    # 'Edit CustomObject Group' => 'カスタム項目グループの編集',
    # 'Create CustomObject Group' => 'カスタム項目グループの作成',
    # 'Manage CustomObject Groups' => 'カスタム項目グループの管理',
    # 'CustomObject Order' => 'カスタム項目グループの表示順',
    # 'CustomObject requires Name.' => 'カスタム項目には名前が必須です。',
    # 'Select CustomObject' => 'カスタム項目を選択',
    # 'Are you sure you want to remove this CustomObject?' => 'このカスタム項目を削除してもよろしいですか?',
    # 'Are you sure you want to publish selected CustomObjects?' => '選択したカスタム項目を公開してもよろしいですか?',
    # 'Are you sure you want to unpublish selected CustomObjects?' => '選択したカスタム項目の公開を取り消してもよろしいですか?',
    # 'Publish CustomObjects from selected datas (p)' => '選択したカスタム項目を公開 (p)',
    # 'Unublish CustomObjects from selected datas (u)' => '選択したカスタム項目の公開を取り消し (u)',
    # 'Tags to add to selected CustomObjects:' => '選択した項目に付けるタグ:',
    # 'Tags to remove from selected CustomObjects:' => '削除するタグ:',
    # 'Save this CustomObject (s)' => 'このカスタム項目を保存 (s)',
    # 'Delete this CustomObject (x)' => 'このカスタム項目を削除 (x)',
    # 'CustomObject Administrator' => 'カスタム項目の管理',
    # 'Manage CustomObject' => 'カスタム項目の管理',
    # 'Manage CustomObject Groups' => 'カスタム項目グループの管理',
    # 'Can create CustomObject, edit CustomObject.' => 'カスタム項目の作成と管理ができます。',
    # 'List of CustomObjects' => 'カスタム項目の一覧',
    # 'CustomObject of Group' => 'グループのカスタム項目',
    # 'Save this CustomObject' => 'このカスタム項目を保存する',
    # 'Save this CustomObject (s)' => 'このカスタム項目を保存する (s)',
    # 'Publish this CustomObject' => 'このカスタム項目を公開する',
    # 'Publish this CustomObject (s)' => 'このカスタム項目を公開する (s)',
    # 'Re-Edit this CustomObject' => 'このカスタム項目を編集する',
    # 'Re-Edit this CustomObject (e)' => 'このカスタム項目を編集する (e)',
    # 'You are previewing the CustomObject entitled &ldquo;[_1]&rdquo;' => 'プレビュー中: カスタム項目「[_1]」',
    # "CustomObject '[_1]' (ID:[_2]) edited and its status changed from [_3] to [_4] by user '[_5]'" => '[_5]がカスタム項目「[_1]」(ID:[_2])を更新し、公開の状態を[_3]から[_4]に変更しました。',
    # 'Cloning CustomObject Groups for blog...' => 'カスタム項目グループを複製しています...',
    # 'Cloning CustomObjects for blog...' => 'カスタム項目を複製しています...',
    # 'Cloning CustomObject tags for blog...' => 'カスタム項目のタグを複製しています...',
    # 'Exclude CustomObjects' => 'カスタム項目の除外',
);

1;
