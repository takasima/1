package mixiComment::L10N::ja;

use strict;
use utf8;
use base 'mixiComment::L10N::en_us';
use vars qw( %Lexicon );

%Lexicon = (

## plugins/mixiComment/lib/mixiComment/App.pm
	'mixi reported that you failed to login.  Try again.' => 'ログインに失敗しました。',

## plugins/mixiComment/mixiComment.pl
	'Allows commenters to sign in to Movable Type using their own mixi username and password via OpenID.' => 'mixiのアカウントを使ってMovable Typeにサインインし、コメントできるようにします。',
	'mixi' => 'ミクシィ',

## plugins/mixiComment/tmpl/config.tmpl
	'A mixi ID has already been registered in this blog.  If you want to change the mixi ID for the blog, <a href="[_1]">click here</a> to sign in using your mixi account.  If you want all of the mixi users to comment to your blog (not only your my mixi users), click the reset button to remove the setting.' => 'すでにmixiのIDを登録してあります。ブログに関連付けるmixiのIDを変えたい場合は、<a href="[_1]">ここをクリックしてmixiにログイン</a>してください。マイミクだけでなくすべてのmixiユーザーからのコメントを受け付けたいときは、初期化ボタンをクリックして設定を消去してください。',
	'If you want to restrict comments only from your my mixi users, <a href="[_1]">click here</a> to sign in using your mixi account.' => 'マイミクからのみコメントを受け付ける設定にするには、<a href="[_1]">ここをクリックしてまずmixiにログイン</a>してください。',

);

1;
