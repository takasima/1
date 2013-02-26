package PowerCMS::L10N::ja;
use strict;
use base qw/PowerCMS::L10N/;

our %Lexicon = (
    'PowerCMS Configration' => 'PowerCMS 設定',
    'Are you sure you want to reset configration?' => '設定をリセットしてよろしいですか?',
    'PowerCMS Configration is not available.' => '設定可能な項目はありません。',
    'Your server does not have XML::Parser installed. XML::Parser required for Entry/Page revision.' => 'サーバーにXML::Parserがインストールされていません。XML::ParserはPowerCMSのリビジョン機能に必要です。',
    'Your server does not have Archive::Zip installed. Archive::Zip is required for various functions.' => 'サーバーにArchive::Zipがインストールされていません。Archive::ZipはPowerCMSの様々な機能に必要です。',
    'System Overview' => 'システムメニュー',
    'Your settings have been reset.' => '設定をリセットしました。',
    'Refresh Cache Successful.' => 'キャッシュをクリアしました。',
    'Refresh Cache' => '検索キャッシュのクリア',
    'Excludes search from other blog.' => '他のブログからの検索を禁止する',
    'The server is temporarily unable to service your request due to maintenance downtime. <br />Please try again later.
If you think this is a server error, please contact the webmaster.'
        => '現在CMSはメンテナンスなどの理由のため管理者以外の操作が制限されています。',
    'Access mt.cgi' => 'mt.cgiへのアクセス',
    'Can\'t change permission for system administrator.' => 'システム管理者の権限を変更することはできません。',
    'Allow access to mt.cgi' => 'mt.cgiへのアクセスを許可',
    'Deny access to mt.cgi' => 'mt.cgiへのアクセスを制限',
    'Sending mail failed: [_1]' => 'メール送信に失敗しました: [_1]',
    'Subject is empty.' => '件名がありません',
    'Body is empty.' => '本文がありません',
    'To is empty.' => '宛先がありません',
    'From is empty.' => '送信元がありません',
    'Duplicate' => '複製',
    'Rebuild Shortcut' => '再構築',
    'PowerCMS News' => 'PowerCMS ニュース',
    'PowerCMS Feedback' => 'フィードバック',
    'No PowerCMS news available.' => 'ニュースはありません',
    'Memo' => 'メモ',
    'This is free space to memo. This is never used.' => 'メモとしてご利用ください。この設定が使われることはありません。',
    'This module is required in PowerCMS' => 'このモジュールは、PowerCMS の動作のために必要です。',
    'This module is required in post by mail by PowerCMS' => 'このモジュールは、PowerCMS Professional 版以上に同梱されているメール投稿の動作のために必要です。',
    'This module is required in enterprise search by PowerCMS' => 'このモジュールは、PowerCMS Enterprise 版以上に同梱されているエンタープライズ検索の動作のために必要です。',
    'This module is required in parse CSV which cell contains changing line, by PowerCMS' => 'このモジュールは、PowerCMS が改行を含んだ CSV を読み込むために必要です。',
    'This module is required in parse CSV by PowerCMS' => 'このモジュールは、PowerCMS が CSV を読み込むために必要です。',
    'Field basename' => 'ベースネーム',

    # Quick Edit
    'Quick Edit' => 'クイック編集',
    'Drag this link to your browser\'s toolbar, then click it when you are visiting a entry(page) that you want to edit entry(page).' => 'このリンクをブラウザのツールバーにドラッグし、ブログ記事(ウェブページ)でクリックするとエントリーの編集画面へ移動できます。',

    # Rebuild All Blogs
    'Rebuild All' => 'すべてを再構築',
    'Total publish time: [_1].' => '全再構築の処理時間: [_1]秒',

    # Rebuild Trigger
    'Rebuild Trigger' => '再構築トリガー',
    'You can write YAML format. Example:' => 'YAML形式で指定します。例:',
    'To use this, You specify the RebuildTriggerPluginSetting 1 in mt-config.cgi.' => 'プラグイン設定で再構築トリガーを指定するには mt-config.cgi に RebuildTriggerPluginSetting 1 を指定してください。',

    # Minifier
    'Minifier' => 'コード圧縮',
    'Movable Type cannot write to the powercms_files directory. Please check the permissions for the directory.' => '一時保存用のディレクトリに書き込みできません。環境変数 PowerCMSFilesDir で設定したディレクトリのパーミッションを確認してください。',
    'Minifying JavaScript and CSS code in mt-static' => 'mt-static以下のJavaScript / CSSコードを圧縮する',

    # View Site
    'Default WebSite URL' => 'デフォルトサイトURL',

    # Alt Search
    'Dynamic Search' => 'ダイナミック検索',
    'Search Path' => '検索ページのパス',
    'Feed Path' => '検索フィードのパス',
    'Default Limit' => 'デフォルトの表示件数',

    # Design Permissions
    'Manage Widgets' => 'ウィジェットの管理',
    'Manage Styles'  => 'スタイルの管理',

    # Bookmark
    'Bookmark' => 'ブックマーク',
    'Add to Bookmark' => 'ブックマークに追加',
    'Edit Bookmark' => 'ブックマークの編集',
    'Bookmark Label' => 'ラベル',
    'Bookmark URL' => 'パラメタ',
    'Icon' => 'アイコン',
    'Order' => '表示順',

    # EntryUnpublish
    'Unpublish Entry' => '指定日非公開を反映',
    'Unpublish Entry Task' => '指定日非公開',
    'Unpublished Entry' => '非公開にしたエントリー',
    'Entry status changed &amp; Blog has been rebuilt.' => 'エントリーを下書きにして再構築を実行しました。',
    'No entry to change status.' => '非公開にするエントリーはありませんでした。',
    'Change status of entry failed: [_1]' => 'エントリーのステータス変更に失敗しました: [_1]',
    'Rebuild error: [_1]' => '再構築に失敗しました: [_1]',
    'Unpublish' => '非公開日',

    # CMSStyle
    'Field Label Setting' => 'フィールドラベル設定',
    'Accept [_1]' => '[_1]を許可',
    'Your changes to the [_1] have been saved.' => '[_1]の変更を保存しました。',
    'You have successfully deleted the checked [_1].' => '選択した[_1]を削除しました。',
    'Outbound [_1] URLs' => '[_1]送信先URL',
    'One or more errors occurred when sending update pings or [_1].' => '更新通知か[_1]送信でひとつ以上のエラーが発生しました。',
    'View Previously Sent [_1]' => '送信済みの[_1]を見る',
    'W3C Markup Validation Setting' => 'W3C Markup Validation 設定',
    'Use Markup Validation' => 'W3C Markup Validation を利用',
    'Use' => '利用する',
    'Url of W3C Markup Validation Service' => 'W3C Markup Validation Service の URL',
    'MT was locked.' => 'Movable Type の管理画面を一時的にロックしました。ロックを解除するまで管理者以外の一切の操作は制限されます。',
    'MT was unlocked.' => '管理画面のロックを解除しました。',
    'Lock/Unlock MT' => '管理画面ロック/解除',
    'Locked' => '管理画面のロック',
    'Unlocked' => '管理画面のロックを解除',
    'Now CMS is locked.' => '現在CMSはロックされています',
    'Now CMS is unlocked.' => 'CMSは操作可能です',
    'Now CMS is locked. Unlock CMS?' => 'CMSのロックを解除してユーザーの操作を許可しますか?',
    'Now CMS is unlocked. Lock CMS?' => 'CMSをロックして管理者以外の操作を制限しますか?',
    'Select Website or Blog' => 'ウェブサイトまたはブログを選択',
    'No websites or blogs can be selected' => '選択可能なウェブサイトまたはブログがありません',
    'System Overview' => 'システムメニュー',
    'Cleanup temporary data for markup validation' => 'Markup validation のための一時データの削除',

    # Bookmark
    'Bookmarks' => 'ブックマーク',
    'Are you sure you want to remove this shortcut?' => 'このブックマークを本当に削除しますか?',
    'Failed to remove' => '削除に失敗しました',
    'No shortcut available.' => 'ブックマークはありません。',
    'Can not edit bookmark' => '編集する場合は画面を更新してください',
);

1;
