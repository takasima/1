package PowerSearch::L10N::ja;

use strict;
use base qw/MT::Plugin::L10N/;

our %Lexicon = (
    'Enterprise Search powerd by Hyper Estraier.' => '全文検索機能を提供します (Powerd by Hyper Estraier)',
    'Update index of Hyper Estraier' => '検索インデックスのアップデート',
    'Path to draft' => '文書ドラフトのディレクトリ',
    'Default language' => 'デフォルト言語',
    'Path to estcmd' => 'estcmdのパス',
    'Path to db' => 'DB(インデックス)のパス',
    'Index of all' => '全ブログ検索',
    'Target file extentions' => 'HTML以外の検索対象',
    'Default pager limit' => 'デフォルトのページ送り件数',
    'Make index of all Blogs' => '全ブログを対象としたインデックスを作成する',
    'Realtime update' => 'インデックスアップデート',
    'Realtime update indexes' => 'エントリー/アイテム保存時にインデックスをアップデート予約する',
    "Make blog:[_1]'s index for [_2]" => 'ブログ：[_1] の検索インデックスを[_2]に作成しました。',
    "Make all blog's index for [_1]" => 'すべてのブログの検索インデックスを[_1]に作成しました。',
    "Update blog:[_1]'s index [_2]" => 'ブログ：[_1] の検索インデックス[_2]をアップデートしました。',
    "Update all blog's index [_1]" => 'すべてのブログの検索インデックス[_1]をアップデートしました。',
    'Exclude indexing path(es)' => 'HTML以外でインデックス対象から除外したいパス(カンマ区切り)',
    'No Blog specified.' => 'PowerSearch: ブログが指定されていません。',
    'Search Result Template Not exists in Blog ID: [_1].' => 'PowerSearch: ブログID: [_1] に検索結果テンプレートが存在しません。',
    '[_1] is not exist. Quit.' => 'PowerSearch: [_1] は存在しません。終了します。',
    '[_1] is not writable. Quit.' => 'PowerSearch: ディレクトリ: [_1] に書き込みできません。終了します。',
    '[_1] is not set. Quit.' => 'PowerSearch: 環境変数: [_1] がmt-config.cgiで設定されていません。終了します。',
    '[_1] is exist. Some trubles are occured. Quit.' => 'ディレクトリ: [_1] が存在しました。ディレクトリを削除後再度お試し下さい。終了します。',
    'Failed to execute external commands. Message: [_1]' => '外部コマンドの実行に失敗しました。メッセージ: [_1]',
    'Estraier.pm is not installed. Quit.' => 'Estraier.pmがサーバーにインストールされていません。終了します。',
);
1;
