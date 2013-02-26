package PowerImporter::L10N::ja;
use strict;
use base 'PowerImporter::L10N';

our %Lexicon = (
    'Import HTML pages to MT.' => '既存のHTMLページからエントリーをインポートします。',
    'HTML pages' => '既存のHTMLページ',
    'CSV or Tab-Separated Values' => 'CSV又はタブ区切りテキスト',
    'Overwrite if permalink exists.' => 'パーマリンクが同一のページを上書きする',
    'Create folders(categories).' => 'フォルダ(カテゴリ)を作成する',
    'Import root was not found.' => '正しいインポート・ルートを指定してください。',
    'The entry belongs to the all parent categories(only entry).' => 'エントリーをすべての親カテゴリに属するようにする(ブログ記事のみ)',
    "Creating new asset '[_1]'..." => "アイテム([_1])を作成しています...",
    "Creating new folder ('[_1]')..." => "フォルダ([_1])を作成しています...",
    "Saving page ('[_1]')..." => "ウェブページ([_1])を作成しています...",
    'Entry Option' => 'エントリー',
    'Category Option' => 'カテゴリー',
    'Import as entry' => 'ブログ記事としてインポート',
    'Import as page' => 'ウェブページとしてインポート',
    'File extensions(Comma separated)' => 'インポート対象のファイル拡張子(カンマ区切り)',
    'Import root' => 'インポート・ルート',
    'Exclude path(es)' => 'インポート対象外のパス(前方一致)',
    'Title field' => 'タイトル',
    'Text field' => '本文',
    'Text More field' => '追記',
    'Excerpt field' => '概要',
    'Keywords field' => 'キーワード',
    'Save settings.' => '設定を保存する',
    'Import now.' => 'すぐにインポートする',
    'Import settings saved, Do import when run-periodic-tasks.' => '設定を保存しました。HTMLページは次回のタスク実行時にインポートされます。',
    'Untitled document' => '名称未設定',
    'Regex' => '正規表現',
    'Separator character' => '抽出開始,終了文字のセパレータ',
);

1;
