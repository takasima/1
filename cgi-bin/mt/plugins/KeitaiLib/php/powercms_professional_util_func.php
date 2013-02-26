<?php
function z2h_kigou( $text ) {
    $replaced = str_replace(
        array( '！', '…', '—', '‘', '“', '”', '＃', '＄', '％', '＆', '’', '（', '）', '＝', '～', '｜', '－', '＾', '￥',
               '｀', '｛', '＠', '［', '＋', '＊', '｝', '；', '：', '］', '＜', '＞', '？', '＿', '，', '．', '／', '「', '」'),
        array( '!',  '...',  '--',  "'",  '"',  '"',  '#',  '$',  '%',  '&',  "'",  '(',  ')',  '=',  '~',  '|',  '-',  '^',  '\\',
               '`',  '{',  '@',  '[',  '+',  '*',  '}',  ';',  ':',  ']',  '<',  '>',  '?',  '_',  ',',  '.',  '/',  '｢',  '｣'),  
        $text
    );
    return $replaced;
}
?>