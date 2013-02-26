package BackupConfig::L10N::ja;
use strict;
use base qw/BackupConfig::L10N/;

our %Lexicon = (
    'Buckup SQL dump &amp; document root on periodic.' =>
        'SQLデータベース及びドキュメントルート以下のバックアップを定期実行します。',
    'SQL database successfully backed up.' =>
        'SQLデータベースをバックアップしました。',
    'Web document root successfully backed up.' =>
        'ドキュメントルートをバックアップしました。',
    'SQL database back up failed.' =>
        'SQLデータベースのバックアップに失敗しました。',
    'Web document root back up failed.' =>
        'ドキュメントルートのバックアップに失敗しました。',
    'No back up files was found.' =>
        'バックアップすべきファイルはありませんでした。',
    'Zip compress'      => 'ZIP圧縮',
    'Compress SQL file' => 'SQLファイルをZIP圧縮する',
    'Path to mysqldump ( or pg_dump | exp | sqlcmd )' =>
        'mysqldump(pg_dump | exp | sqlcmd)コマンドのパス',
    'Last backup (Unix time)' => '最終バックアップ(Unix time)',
    'Backup documents'        => 'ドキュメント',
    'Backup web document root' =>
        'ドキュメント・ルート以下をバックアップする',
    'Backup SQL' => 'SQL',
    'Backup SQL dump file' =>
        'SQLデータベースのダンプをバックアップする',
    'SQL option'             => 'SQLオプション',
    'Path to saved SQL file' => 'SQLファイルのバックアップ先',
    'Path to archived web document root' =>
        'ドキュメントルートのバックアップ先',
    'Update back up'             => '差分バックアップ',
    'Back up updated files only' => '差分バックアップ',
    'Path to web document root for back up, Comma separated' =>
        'ドキュメントバックアップ対象(カンマ区切り)',
    'Excludes' => 'バックアップ除外パス',
    'Regular expression, Comma separated' =>
        'カンマ区切り (正規表現)',
    'FTP'             => 'FTP転送',
    'FTP Server'      => 'FTPサーバー',
    'Use FTP server'  => 'バックアップデータをFTP転送する',
    'FTP server root' => 'ディレクトリ(CWD)',
    'FTP host'        => 'FTPサーバー名',
    'User id'         => 'ユーザーID',
    'Password'        => 'パスワード',
    'FTP put SQL file successfull.' =>
        'SQLファイルのFTP転送に成功しました。',
    'FTP put backup file of web document root successfull.' =>
        'ドキュメントルートのバックアップファイルのFTP転送に成功しました。',
    'FTP put SQL file failed.' =>
        'SQLファイルのFTP転送に失敗しました。',
    'FTP put backup file of web document root failed.' =>
        'ドキュメントルートのバックアップファイルのFTP転送に失敗しました。',
    'All back up process successfull.' =>
        'バックアッププロセスは正常に終了しました。',
    'Remove back up files' => 'バックアップの削除',
    'Remove back up files after FTP' =>
        'FTP転送が成功したらバックアップファイルを削除する',
    'Neither Archive::Zip nor Archive::Tar is available.' =>
        'Archive::Zip または Archive::Tar モジュールがインストールされていません。 ',
    'Net::FTP is not available.' =>
        'Net::FTP モジュールがインストールされていません。',
    'NLS_LANG(Oracle)' => 'NLS_LANG(オラクル)',
);

1;
