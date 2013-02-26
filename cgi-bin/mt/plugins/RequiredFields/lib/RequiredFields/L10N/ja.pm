package RequiredFields::L10N::ja;

use strict;
use base qw/RequiredFields::L10N/;

our %Lexicon = (
    'Check required input fields.' => 'フィールドの入力チェックを行います。',
    'Standard Field' => 'チェック対象のフィールド（name）',
    'Ext Field' => 'チェック対象の拡張フィールド（ラベル）',
    'The entry categories are required.' => 'カテゴリの選択を必須にします。',
    'When you check the preview.' => 'プレビューの際にもチェックを行います。',
    "Setting about inputs like 'LABEL,name', per line." => 'チェック対象にしたい入力欄を「ラベル,name」のようにカンマ区切りで指定します。改行区切りで複数の指定が可能です。',
    'Setting about ExtFields labels, per line.' => 'チェック対象にしたい拡張フィールドの「ラベル名」を指定します。改行区切りで複数の指定が可能です。',
);

1;
