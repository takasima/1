# Movable Type (r) (C) 2006-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package MT::Enterprise::L10N::ja;

use strict;
use base 'MT::Enterprise::L10N::en_us';
use vars qw( %Lexicon );
use utf8;

## The following is the translation table.

%Lexicon = (

## addons/Enterprise.pack/app-cms.yaml
	'Groups ([_1])' => 'グループ([_1])',
	'Are you sure you want to delete the selected group(s)?' => '選択されているグループを削除してよろしいですか?',
	'Are you sure you want to remove the selected member(s) from the group?' => '選択されているメンバーをグループから削除してよろしいですか?',
	'[_1]\'s Group' => '[_1]の所属するグループ',
	'Groups' => 'グループ',
	'Manage Member' => 'メンバーの管理',
	'Bulk Author Export' => 'ユーザーの一括出力',
	'Bulk Author Import' => 'ユーザーの一括登録',
	'Synchronize Users' => 'ユーザーを同期',
	'Synchronize Groups' => 'グループを同期',
	'Add user to group' => 'グループにユーザーを追加',

## addons/Enterprise.pack/app-wizard.yaml
	'This module is required in order to use the LDAP Authentication.' => 'LDAP認証を利用する場合に必要です。',
	'This module is required in order to use SSL/TLS connection with the LDAP Authentication.' => 'LDAP認証でSSLまたはTLS接続を利用する場合に必要です。',
	'This module and its dependencies are required in order to use CRAM-MD5, DIGEST-MD5 or LOGIN as a SASL mechanism.' => 'Authen::SASLはCRAM-MD5、DIGEST-MD5又はLOGINをSASLメカニズムとして利用する場合に必要となります。',

## addons/Enterprise.pack/config.yaml
	'Permissions of group: [_1]' => 'グループ[_1]の権限',
	'Group' => 'グループ',
	'Groups associated with author: [_1]' => 'ユーザー[_1]と関連付けられたグループ',
	'Inactive' => '有効ではない',
	'Members of group: [_1]' => 'グループ [_1]のメンバー',
	'Advanced Pack' => 'Advanced Pack',
	'User/Group' => 'ユーザー/グループ',
	'User/Group Name' => 'ユーザー/グループ名',
	'__GROUP_MEMBER_COUNT' => 'メンバー数',
	'My Groups' => '自分のグループ',
	'Group Name' => 'グループ名',
	'Manage Group Members' => 'グループメンバーの管理',
	'Group Members' => 'グループメンバー',
	'Group Member' => 'メンバー',
	'Permissions for Users' => 'ユーザーの権限',
	'Permissions for Groups' => 'グループの権限',
	'Active Groups' => '有効なグループ',
	'Disabled Groups' => '無効なグループ',
	'Oracle Database (Recommended)' => 'Oracleデータベース(推奨)',
	'Microsoft SQL Server Database' => 'Microsoft SQL Serverデータベース',
	'Microsoft SQL Server Database UTF-8 support (Recommended)' => 'Microsoft SQL Serverデータベース UTF-8サポート(推奨)',
	'Publish Charset' => '文字コード',
	'ODBC Driver' => 'ODBCドライバ',
	'External Directory Synchronization' => '外部ディレクトリと同期',
	'Populating author\'s external ID to have lower case user name...' => '小文字のユーザー名を外部IDに設定しています...',

## addons/Enterprise.pack/lib/MT/Auth/LDAP.pm
	'User [_1]([_2]) not found.' => 'ユーザー[_1]([_2])が見つかりませんでした。',
	'User \'[_1]\' cannot be updated.' => 'ユーザー「[_1]」を更新できませんでした。',
	'User \'[_1]\' updated with LDAP login ID.' => 'ユーザー「[_1]」をLDAPのログインIDで更新しました。',
	'LDAP user [_1] not found.' => 'LDAPサーバー上にユーザーが見つかりません: [_1]',
	'User [_1] cannot be updated.' => 'ユーザー「[_1]」を更新できませんでした。',
	'User cannot be updated: [_1].' => 'ユーザーの情報を更新できません: [_1]',
	'Failed login attempt by user \'[_1]\' who was deleted from LDAP.' => 'LDAPから削除されたユーザー [_1] がログインしようとしました。',
	'User \'[_1]\' updated with LDAP login name \'[_2]\'.' => 'ユーザー「[_1]」のログイン名をLDAP名「[_2]」に変更しました。',
	'Failed login attempt by user \'[_1]\'. A user with that username already exists in the system with a different UUID.' => '[_1]がログインできませんでした。同名のユーザーが別の外部IDですでに存在します。',
	'User \'[_1]\' account is disabled.' => 'ユーザー「[_1]」を無効化しました。',
	'LDAP users synchronization interrupted.' => 'LDAPユーザーの同期が中断されました。',
	'Loading MT::LDAP failed: [_1]' => 'MT::LDAPの読み込みに失敗しました: [_1]',
	'External user synchronization failed.' => 'ユーザーの同期に失敗しました。',
	'An attempt to disable all system administrators in the system was made.  Synchronization of users was interrupted.' => 'すべてのシステム管理者が無効にされるため、ユーザーの同期は中断されました。',
	'Information about the following users was modified:' => '次のユーザーの情報が変更されました: ',
	'The following users were disabled:' => '次のユーザーが無効化されました: ',
	'LDAP users synchronized.' => 'LDAPユーザーが同期されました。',
	'Synchronization of groups can not be performed without LDAPGroupIdAttribute and/or LDAPGroupNameAttribute being set.' => 'グループを同期するためにはLDAPGroupIdAttributeおよびLDAPGroupNameAttributeの設定が必須です。',
	'LDAP groups synchronized with existing groups.' => '既存のグループがLDAPグループと同期されました。',
	'Information about the following groups was modified:' => '次のグループの情報が更新されました: ',
	'No LDAP group was found using the filter provided.' => '指定されたフィルタではLDAPグループが見つかりませんでした。',
	'The filter used to search for groups was: \'[_1]\'. Search base was: \'[_2]\'' => '検索フィルタ: \'[_1]\' 検索ベース: \'[_2]\'',
	'(none)' => '(なし)',
	'The following groups were deleted:' => '以下のグループが削除されました。',
	'Failed to create a new group: [_1]' => '新しいグループを作成できませんでした: [_1]',
	'[_1] directive must be set to synchronize members of LDAP groups to Movable Type Advanced.' => 'Movable Type AdvancedでLDAPグループのメンバーを同期するには、[_1]を設定する必要があります。',
	'Members removed: ' => 'グループから削除されたメンバー: ',
	'Members added: ' => '追加されたメンバー: ',
	'Memberships in the group \'[_2]\' (#[_3]) were changed as a result of synchronizing with the external directory.' => '外部ディレクトリとの同期の結果グループ「[_2]」(ID: [_3])を更新しました。',
	'LDAPUserGroupMemberAttribute must be set to enable synchronizing of members of groups.' => 'グループのメンバーを同期するにはLDAPUserGroupMemberAttributeの設定が必須です。',

## addons/Enterprise.pack/lib/MT/Enterprise/BulkCreation.pm
	'Formatting error at line [_1]: [_2]' => '[_1]行目でエラーが見つかりました: [_2]',
	'Invalid command: [_1]' => 'コマンドが認識できません: [_1]',
	'Invalid number of columns for [_1]' => '[_1] コマンドのカラムの数が不正です',
	'Invalid user name: [_1]' => 'ログイン名の設定に誤りがあります: [_1]',
	'Invalid display name: [_1]' => '表示名の設定に誤りがあります: [_1]',
	'Invalid email address: [_1]' => 'メールアドレスが正しくありません: [_1]',
	'Invalid language: [_1]' => '使用言語の設定に誤りがあります: [_1]',
	'Invalid password: [_1]' => 'パスワードの設定に誤りがあります: [_1]',
	'\'Personal Blog Location\' setting is required to create new user blogs.' => 'ユーザーのブログを作成する場合は、\'個人用ブログの場所\'を設定してください。',
	'Invalid weblog name: [_1]' => 'ブログ名の設定に誤りがあります: [_1]',
	'Invalid blog URL: [_1]' => 'ブログURLの設定に誤りがあります: [_1]',
	'Invalid site root: [_1]' => 'サイトパスの設定に誤りがあります: [_1]',
	'Invalid timezone: [_1]' => '時間帯 (タイムゾーン) の設定に誤りがあります: [_1]',
	'Invalid theme ID: [_1]' => 'テーマIDの設定に誤りがあります: [_1]',
	'A user with the same name was found.  The registration was not processed: [_1]' => '同名のユーザーが登録されているため、登録できません: [_1]',
	'Blog for user \'[_1]\' can not be created.' => 'ブログ「[_1]」へユーザーを登録できませんでした。',
	'Blog \'[_1]\' for user \'[_2]\' has been created.' => 'ユーザー[_2]のブログ「[_1]」を作成しました。',
	'Error assigning weblog administration rights to user \'[_1] (ID: [_2])\' for weblog \'[_3] (ID: [_4])\'. No suitable weblog administrator role was found.' => 'ユーザー「[_1]」(ID:[_2])にブログ「[_3]」(ID:[_4])への権限を付与できませんでした。利用できるブログの管理者ロールが見つかりませんでした。',
	'Permission granted to user \'[_1]\'' => 'ユーザー [_1] に権限を設定しました。',
	'User \'[_1]\' already exists. The update was not processed: [_2]' => '[_1] というユーザーがすでに存在します。更新はできませんでした: [_2]',
	'User \'[_1]\' not found.  The update was not processed.' => 'ユーザー「[_1]」が見つからないため、更新できません。',
	'User \'[_1]\' has been updated.' => 'ユーザーの情報を更新しました: [_1]',
	'User \'[_1]\' was found, but the deletion was not processed' => 'ユーザー「[_1]」が見つかりましたが、削除できません。',
	'User \'[_1]\' not found.  The deletion was not processed.' => 'ユーザー「[_1]」が見つからないため、削除できません。',
	'User \'[_1]\' has been deleted.' => 'ユーザーを削除しました: [_1]',

## addons/Enterprise.pack/lib/MT/Enterprise/CMS.pm
	'Movable Type Advanced has just attempted to disable your account during synchronization with the external directory. Some of the external user management settings must be wrong. Please correct your configuration before proceeding.' => '外部ディレクトリとの同期中にあなた自身が無効化されそうになりました。外部ディレクトリによるユーザー管理の設定が誤っているかもしれません。構成を確認してください。',
	'Each group must have a name.' => 'グループには名前が必要です。',
	'Search Users' => 'ユーザーを検索',
	'Select Groups' => 'グループを選択',
	'Groups Selected' => '選択されたグループ',
	'Search Groups' => 'グループを検索',
	'Add Users to Groups' => 'グループにユーザーを追加',
	'Invalid group' => 'グループが不正です。',
	'Add Users to Group [_1]' => '[_1]にユーザーを追加',
	'User \'[_1]\' (ID:[_2]) removed from group \'[_3]\' (ID:[_4]) by \'[_5]\'' => '[_5]がユーザー「[_1](ID:[_2])」をグループ「[_3](ID:[_4])」から削除しました。',
	'Group load failed: [_1]' => 'グループをロードできませんでした: [_1]',
	'User load failed: [_1]' => 'ユーザーをロードできませんでした: [_1]',
	'User \'[_1]\' (ID:[_2]) was added to group \'[_3]\' (ID:[_4]) by \'[_5]\'' => '[_5]がユーザー「[_1](ID:[_2])」をグループ「[_3](ID:[_4])」に追加しました。',
	'Users & Groups' => 'ユーザー/グループ',
	'Group Profile' => 'グループのプロフィール',
	'Author load failed: [_1]' => 'ユーザーをロードできませんでした: [_1]',
	'Invalid user' => '不正なユーザーです。',
	'Assign User [_1] to Groups' => 'ユーザー[_1]をグループ[_1]に追加',
	'Type a group name to filter the choices below.' => 'グループ名を入力してフィルタリングします。',
	'Bulk import cannot be used under external user management.' => 'ExternalUserManagement環境ではユーザーの一括編集はできません。',
	'Bulk management' => '一括管理',
	'No records were found in the file.  Make sure the file uses CRLF as the line-ending characters.' => '登録するレコードがありません。改行コードがCRLFになっているかどうか確認してください。',
	'Registered [quant,_1,user,users], updated [quant,_2,user,users], deleted [quant,_3,user,users].' => '登録:[quant,_1,人,人]、更新:[quant,_2,人,人]、削除:[quant,_3,人,人]',
	'Bulk author export cannot be used under external user management.' => 'ExternalUserManagement環境ではユーザーの一括出力はできません。',
	'A user can\'t change his/her own username in this environment.' => '自分のユーザー名を変えることはこの構成ではできません。',
	'An error occurred when enabling this user.' => 'ユーザーを有効化するときにエラーが発生しました: [_1]',

## addons/Enterprise.pack/lib/MT/Enterprise/Upgrade.pm
	'Fixing binary data for Microsoft SQL Server storage...' => 'Microsoft SQL Serverでバイナリデータを移行しています...',

## addons/Enterprise.pack/lib/MT/Enterprise/Wizard.pm
	'PLAIN' => 'PLAIN',
	'CRAM-MD5' => 'CRAM-MD5',
	'Digest-MD5' => 'Digest-MD5',
	'Login' => 'ログイン',
	'Found' => '見つかりました',
	'Not Found' => '見つかりませんでした',

## addons/Enterprise.pack/lib/MT/Group.pm

## addons/Enterprise.pack/lib/MT/LDAP.pm
	'Invalid LDAPAuthURL scheme: [_1].' => 'LDAPAuthURLのスキーム「[_1]」が不正です。',
	'Error connecting to LDAP server [_1]: [_2]' => 'LDAPサーバー [_1] に接続できません: [_2]',
	'User not found in LDAP: [_1]' => 'LDAPサーバー上にユーザーが見つかりません: [_1]',
	'Binding to LDAP server failed: [_1]' => 'LDAPサーバーに接続できません: [_1]',
	'More than one user with the same name found in LDAP: [_1]' => 'LDAPサーバー上に同一名のユーザーが見つかりました: [_1]',

## addons/Enterprise.pack/lib/MT/ObjectDriver/Driver/DBD/MSSQLServer.pm
	'PublishCharset [_1] is not supported in this version of the MS SQL Server Driver.' => 'PublishCharset [_1]はMS SQL Serverのドライバでサポートされていません。',

## addons/Enterprise.pack/lib/MT/ObjectDriver/Driver/DBD/UMSSQLServer.pm
	'This version of UMSSQLServer driver requires DBD::ODBC version 1.14.' => 'このバージョンのUMSSQLServerドライバは、DBD::ODBCバージョン1.14以上で動作します。',
	'This version of UMSSQLServer driver requires DBD::ODBC compiled with Unicode support.' => 'このバージョンのUMSSQLServerドライバは、UnicodeをサポートするDBD::ODBCが必要です。',

## addons/Enterprise.pack/tmpl/author_bulk.tmpl
	'Manage Users in bulk' => 'ユーザーの一括管理',
	'_USAGE_AUTHORS_2' => 'ユーザーの情報を一括で編集できます。CSV形式のコマンドファイルをアップロードしてください。',
	q{New user blog would be created on '[_1]'.} => q{ユーザーのブログはウェブサイト '[_1]' に作成されます。},
	'[_1] Edit</a>' => '[_1] 編集</a>',
	q{You must set 'Personal Blog Location' to create a new blog for each new user.} => q{ユーザーのブログを作成する場合は、'個人用ブログの場所'を設定してください。},
	'[_1] Setting</a>' => '[_1] 設定</a>',
	'Upload source file' => 'ソースファイルのアップロード',
	'Specify the CSV-formatted source file for upload' => 'アップロードするCSV形式のソースファイルを指定してください。',
	'Source File Encoding' => 'ソースファイルのエンコーディング',
	'Movable Type will automatically try to detect the character encoding of your import file.  However, if you experience difficulties, you can set the character encoding explicitly.' => 'Movable Typeはインポートするファイルの文字コードを自動的に検出します。問題が起きたときには、明示的に文字コードを指定することもできます。',
	'Upload (u)' => 'アップロード (u)',

## addons/Enterprise.pack/tmpl/cfg_ldap.tmpl
	'Authentication Configuration' => '認証の構成',
	'You must set your Authentication URL.' => '認証URLを設定してください。',
	'You must set your Group search base.' => 'グループの検索を開始する場所を設定してください。',
	'You must set your UserID attribute.' => 'ユーザーの識別子を示す属性を設定してください。',
	'You must set your email attribute.' => '電子メールを示す属性を設定してください。',
	'You must set your user fullname attribute.' => 'フルネーム示す属性を設定してください。',
	'You must set your user member attribute.' => 'メンバー属性に対応するユーザーの属性を設定してください。',
	'You must set your GroupID attribute.' => 'グループの識別子を示す属性を設定してください。',
	'You must set your group name attribute.' => 'グループの名前を示す属性を設定してください。',
	'You must set your group fullname attribute.' => 'グループのフルネームを示す属性を設定してください。',
	'You must set your group member attribute.' => 'グループのメンバーを示す属性を設定してください。',
	'An error occurred while attempting to connect to the LDAP server: ' => 'LDAPサーバーへの接続中にエラーが発生しました：',
	'You can configure your LDAP settings from here if you would like to use LDAP-based authentication.' => 'LDAPで認証を行う場合、LDAPの設定を行うことができます。',
	'Your configuration was successful.' => '構成を完了しました。',
	q{Click 'Continue' below to configure the External User Management settings.} => q{次へをクリックしてExternalUserManagementの設定に進んでください。},
	q{Click 'Continue' below to configure your LDAP attribute mappings.} => q{次へをクリックして属性マッピングに進んでください。},
	'Your LDAP configuration is complete.' => 'LDAPの構成を完了しました。',
	q{To finish with the configuration wizard, press 'Continue' below.} => q{次へをクリックして構成ウィザードを完了してください。},
	q{Can't locate Net::LDAP. Net::LDAP module is required to use LDAP authentication.} => q{Net::LDAPが見つかりません。Net::LDAPはLDAP認証を利用するのために必要です。},
	'Use LDAP' => 'LDAPを利用する',
	'Authentication URL' => '認証URL',
	'The URL to access for LDAP authentication.' => 'LDAP認証でアクセスするURL',
	'Authentication DN' => '認証に利用するDN',
	'An optional DN used to bind to the LDAP directory when searching for a user.' => 'ユーザーを検索するときにLDAPディレクトリにバインドするDN（任意）',
	'Authentication password' => '認証に利用するDNのパスワード',
	'Used for setting the password of the LDAP DN.' => '認証に利用するDNが接続するときのパスワード',
	'SASL Mechanism' => 'SASLメカニズム',
	'The name of the SASL Mechanism used for both binding and authentication.' => 'バインドと認証で利用するSASLメカニズムの名前',
	'Test Username' => 'テストユーザー名',
	'Test Password' => 'パスワード',
	'Enable External User Management' => '外部ディレクトリでユーザー管理を行う',
	'Synchronization Frequency' => '同期間隔',
	'The frequency of synchronization in minutes. (Default is 60 minutes)' => '同期を行う間隔（既定値は60分）',
	'15 Minutes' => '15分',
	'30 Minutes' => '30分',
	'60 Minutes' => '60分',
	'90 Minutes' => '90分',
	'Group Search Base Attribute' => 'グループの検索を開始する場所',
	'Group Filter Attribute' => 'グループを表すフィルタ',
	'Search Results (max 10 entries)' => '検索結果（最大10件だけ表示します）',
	'CN' => 'CN',
	'No groups were found with these settings.' => 'グループが見つかりませんでした。',
	'Attribute mapping' => '属性マッピング',
	'LDAP Server' => 'LDAPサーバー',
	'Other' => 'その他',
	'User ID Attribute' => 'ユーザーの識別子を示す属性',
	'Email Attribute' => '電子メールを示す属性',
	'User Fullname Attribute' => 'フルネーム示す属性',
	'User Member Attribute' => 'メンバー属性に対応するユーザーの属性',
	'GroupID Attribute' => 'グループの識別子を示す属性',
	'Group Name Attribute' => 'グループの名前を示す属性',
	'Group Fullname Attribute' => 'グループのフルネームを示す属性',
	'Group Member Attribute' => 'グループのメンバーを示す属性',
	'Search Result (max 10 entries)' => '検索結果（最大10件）',
	'Group Fullname' => 'フルネーム',
	'(and [_1] more members)' => '(他[_1]ユーザー)',
	'No groups could be found.' => 'グループが見つかりませんでした。',
	'User Fullname' => 'フルネーム',
	'(and [_1] more groups)' => '(他[_1]グループ)',
	'No users could be found.' => 'ユーザーが見つかりませんでした。',
	'Test connection to LDAP' => 'LDAPへの接続を試す',
	'Test search' => '検索を試す',

## addons/Enterprise.pack/tmpl/create_author_bulk_end.tmpl
	'All users were updated successfully.' => 'すべてのユーザーの更新が完了しました。',
	'An error occurred during the update process. Please check your CSV file.' => 'ユーザーの更新中にエラーが発生しました。CSVファイルの内容を確認してください。',

## addons/Enterprise.pack/tmpl/create_author_bulk_start.tmpl

## addons/Enterprise.pack/tmpl/dialog/dialog_select_group_user.tmpl

## addons/Enterprise.pack/tmpl/dialog/select_groups.tmpl
	'You need to create some groups.' => 'グループを作成してください。',
	q{Before you can do this, you need to create some groups. <a href="javascript:void(0);" onclick="closeDialog('[_1]');">Click here</a> to create a group.} => q{実行する前にグループを作成する必要があります。 <a href="javascript:void(0);" onclick="closeDialog('[_1]');">ここをクリックして</a>グループを作成してください。},

## addons/Enterprise.pack/tmpl/edit_group.tmpl
	'Edit Group' => 'グループの編集',
	'Create Group' => 'グループの作成',
	'This group profile has been updated.' => 'グループのプロフィールを更新しました。',
	'This group was classified as pending.' => 'このグループは保留中になっています。',
	'This group was classified as disabled.' => 'このグループは無効になっています。',
	'Member ([_1])' => 'メンバー([_1])',
	'Members ([_1])' => 'メンバー([_1])',
	'Permission ([_1])' => '権限([_1])',
	'Permissions ([_1])' => '権限([_1])',
	'LDAP Group ID' => 'LDAPグループID',
	'The LDAP directory ID for this group.' => 'LDAPディレクトリでこのグループに適用されている識別子',
	'Status of this group in the system. Disabling a group prohibits its members&rsquo; from accessing the system but preserves their content and history.' => 'グループの状態。グループを無効にするとメンバーのシステムへのアクセスに影響があります。メンバーのコンテンツや履歴は削除されません。',
	'The name used for identifying this group.' => 'グループを識別する名前',
	'The display name for this group.' => 'グループの表示名',
	'The description for this group.' => 'グループの説明',
	'Save changes to this field (s)' => 'フィールドへの変更を保存 (s)',

## addons/Enterprise.pack/tmpl/include/group_table.tmpl
	'Enable selected group (e)' => '選択されたグループを有効にする (e)',
	'Disable selected group (d)' => '選択されたグループを無効にする (d)',
	'group' => 'グループ',
	'groups' => 'グループ',
	'Remove selected group (d)' => '選択されたグループを削除する (d)',

## addons/Enterprise.pack/tmpl/include/list_associations/page_title.group.tmpl
	'Users &amp; Groups for [_1]' => 'ユーザーとグループ - [_1]',

## addons/Enterprise.pack/tmpl/listing/group_list_header.tmpl
	'You successfully disabled the selected group(s).' => '選択されたグループを無効にしました。',
	'You successfully enabled the selected group(s).' => '選択されたグループを有効にしました。',
	'You successfully deleted the groups from the Movable Type system.' => 'グループをMovable Typeのシステムから削除しました。',
	q{You successfully synchronized the groups' information with the external directory.} => q{外部のディレクトリとグループの情報を同期しました。},

## addons/Enterprise.pack/tmpl/listing/group_member_list_header.tmpl
	'You successfully deleted the users.' => 'ユーザーを削除しました。',
	'You successfully added new users to this group.' => 'グループに新しいユーザーを追加しました。',
	q{You successfully synchronized users' information with the external directory.} => q{外部のディレクトリとユーザー情報を同期しました。},
	'Some ([_1]) of the selected users could not be re-enabled because they are no longer found in LDAP.' => '選択されたユーザーのうち[_1]人は外部ディレクトリ上に存在しないので有効にできませんでした。',
	'You successfully removed the users from this group.' => 'グループからユーザーを削除しました。',

);

1;
