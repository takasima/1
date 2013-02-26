package Members::L10N::ja;

use strict;
use base 'MT::Plugin::L10N';

our %Lexicon = (
    'Enable members area.' => '認証付き領域を設定します。',

    # Role
    'Members' => '会員ページの閲覧',
    'Can view pages.' =>
        '会員専用ページを閲覧することができます',
    'Member Role installed.' =>
        'ロール: 会員ページの閲覧 がインストールされました。',

    # Templates(Name)
    'Member\'s Log in' => '会員サイトへのログイン',
    'Member\'s Log in (Mobile)' =>
        '会員サイトへのログイン(携帯)',
    'Member\'s Sign Up' => '会員サイトへのサインアップ',
    'Member\'s Sign Up (Mobile)' =>
        '会員サイトへのサインアップ(携帯)',
    'Member\'s Redirector (Mobile)' => 'リダイレクトページ(携帯)',
    'Member\'s Edit Profile'        => 'プロフィールの編集',
    'Member\'s Edit Profile (Mobile)' =>
        'プロフィールの編集(携帯)',
    'Member\'s Password Recovery' => 'パスワードの再設定',
    'Member\'s Password Recovery (Mobile)' =>
        'パスワードの再設定(携帯)',
    'Member\'s Change Password' => 'パスワードの変更',
    'Member\'s Change Password (Mobile)' =>
        'パスワードの変更(携帯)',
    'Member\'s Notify Confirm for User' =>
        '新規会員登録時のユーザーへの確認通知メール',
    'Member\'s Notify Registered for User' =>
        '新規会員登録時のユーザーへの登録完了メール',
    'Member\'s Notify Untrusted User for Admin' =>
        '新規会員仮登録の管理者への通知メール',
    'Member\'s Notify Registered User for Admin' =>
        '新規会員完了時の管理者への通知メール',
    'Member\'s Notify Password Recovery' =>
        'パスワード再設定通知メール',

    # Templates
    'Moblie E-mail'  => '携帯メール',
    'Secret Token'   => '秘密のフレーズ',
    'Invalid value'  => '不正な値です',
    'Saving failed.' => '保存に失敗しました。',

    # Mail
    'Member\'s account confirmation on \'[_1]\'' =>
        '\'[_1]\'への新規アカウント登録の確認',
    'Your account has been trusted for \'[_1]\'' =>
        '\'[_1]\'への新規アカウント登録の完了',
    'A new untrust user \'[_1]\' registered on \'[_2]\'' =>
        '\'[_2]\'への未承認ユーザー\'[_1]\'の登録通知',
    'A new user \'[_1]\' has successfully registered on \'[_2]\'' =>
        '\'[_2]\'への新規ユーザー\'[_1]\'の登録通知',

    'System administrator of \'[_1]\' trusted you.' =>
        '\'[_1]\'のシステム管理者があなたを承認しました。',
    '[_1] registered to the \'[_2]\'' =>
        '[_1]がブログ\'[_2]\'に登録されました。',
    'Please click to regist \'[_1]\'' =>
        'クリックして\'[_1]\'への登録を完了してください',
    'Login to \'[_1]\'' => '\'[_1]\'へログイン',

    'This email is to notify you that a new user has successfully registered on \'[_1]\'.'
        => 'このメールは新しいユーザーが\'[_1]\'に登録を完了したことを通知するメールです。',
    'This email is to notify you that a new untrusted user registered on \'[_1]\'.'
        => 'このメールは新しい未承認のユーザーが\'[_1]\'に登録を完了したことを通知するメールです。',
    'To view or edit this user, please click on or cut and paste the following URL into a web browser:'
        => 'このユーザーの情報を見たり編集する場合には、下記のURLをクリックするか、URLをコピーしてブラウザのアドレス欄に貼り付けてください。',
    'To trust this user, please click on or cut and paste the following URL into a web browser:'
        => 'このユーザーを承認する場合には、下記のURLをクリックするか、URLをコピーしてブラウザのアドレス欄に貼り付けてください。',
    'This email is to notify you that a new signup on \'[_1]\'.' =>
        'このメールは\'[_1]\'へのサインアップを通知するメールです。',
    'If you did not request this change, you can safely ignore this email.' =>
        'このメールに心当たりがないときは、何もせずに無視してください。',

    # App
    'Thanks for the confirmation. This account has been disabled. Please wait for a while until it is approved by the administrator.'
        => 'ご登録ありがとうございます。システム管理者によって承認されるまでしばらくお待ちください。',
    'Redirect' => 'リダイレクト',
    'This URL is out of this site.' =>
        '他のサイトに移動しようとしています',
    'Are you sure want to move to this url?' =>
        'このURLに移動してもよろしいですか?',
    'Quick Login Setting was successful.' =>
        '機器IDの登録を完了しました',
    'Quick Login Setting was failed.' =>
        '機器IDの登録に失敗しました',
    'Unknown user' => 'ユーザーが不明です。',
    'Invalid password' =>
        '正しいパスワードを入力してください。',
    'Thanks for the confirmation. This account has been disabled. Please wait for a while until it is approved by the administrator.'
        => 'ご登録ありがとうございます。システム管理者によって承認されるまでしばらくお待ちください。',
    'You have attempted to use a feature that you do not have permission to access. If you believe you are seeing this message in error contact your system administrator.'
        => 'アクセス権がありません。システム管理者に連絡してください。',

    # CMS
    'Member\'s'        => '会員限定サイト',
    'View Only Member' => '会員限定サイトにする',
    'View Site'        => '会員サイトの閲覧',

    # Config
    'Site Base Path'          => 'サイトのルート・パス',
    'Index Files'             => 'インデックス・ファイル',
    'Exclude Files Extension' => '権限チェック除外ファイル',
    'Session Timeout'         => 'セッション有効期限',
    'Sign up Timeout'         => '仮登録ユーザーの有効期限',
    'Register user\'s status' => '登録ユーザーのステータス',
    'Notify Send to'   => 'ユーザー登録時の通知先アドレス',
    'Notify Send From' => 'メールのFromアドレス',
    'Allow Register'   => 'すべてに同時登録',
    'Register to All member\'s site.' =>
        'すべての会員サイトに同時登録する',
    'Send registered mail to author' => 'ユーザー登録時にメール通知する',
);

1;
