<?php
function smarty_modifier_str2keitai( $text, $arg ) {
    $cite  = 'Quote';
    $frame = 'Frame';
    $regex = '<script[^>]*.*?<\/script>';
    $text  = preg_replace( "/$regex/is", '', $text );
    $regex = '<iframe[^>]*src=*["\']([^"\'>]*)["\'][^>]*>*?<\/iframe>';
    $text  = preg_replace( "/$regex/is", "<a href=\"$1\">$frame</a>", $text );
    $regex = '<blockquote[^>]*cite="(.{1,}?)"[^>]*>(.{1,}?)<\/blockquote>';
    $text  = preg_replace( "/$regex/is", "<a href=\"$1\">$cite</a>$2", $text );
    $regex = '<[\/]*(frameset|frame|noframes)[^>]*?>';
    $text  = preg_replace( "/$regex/is", '', $text );
    $regex = '<[\/]*(strong|em|b|i|u|s|font)[^>]*?>';
    $text  = preg_replace( "/$regex/is", '', $text );
    $regex = '(<[^>]*)(onclick|onmouseup|onmouseover|onmouseout|onmousedown)=?(")[^>]*?(")';
    $text  = preg_replace( "/$regex/is", '$1', $text );
    $regex = '(<[^>]*)(onclick|onmouseup|onmouseover|onmouseout|onmousedown)=?(\')[^>]*?(\')';
    $text  = preg_replace( "/$regex/is", '$1', $text );
    return $text;
}
?>