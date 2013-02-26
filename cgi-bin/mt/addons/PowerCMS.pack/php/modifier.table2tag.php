<?php
function smarty_modifier_table2tag( $text, $arg ) {
    if ( preg_match( '/<!\-\-NO_TABLE2TAG\-\->/i', $text ) ) {
        $text = preg_replace( '/<!\-\-NO_TABLE2TAG\-\->/i', '', $text );
        return $text;
    }
    if ( $arg != 1 ) {
        $tag = explode( ",", $arg );
        if ( $tag[0] ) {
            $text = preg_replace( '/<table.*?>(.*?)<\/table>/is', "<$tag[0]>$1</$tag[0]>", $text );
        } else {
            $text = preg_replace( '/<table.*?>(.*?)<\/table>/is', '$1', $text );
        }
        if ( $tag[1] ) {
            $text = preg_replace( '/<tr.*?>(.*?)<\/tr>/is', "<$tag[1]>$1</$tag[1]>", $text );
        } else {
            $text = preg_replace( '/<tr.*?>(.*?)<\/tr>/is', '$1', $text );
        }
        if ( $tag[2] ) {
            $text = preg_replace( '/<td.*?>(.*?)<\/td>/is', "<$tag[2]>$1</$tag[2]>", $text );
        } else {
            $text = preg_replace( '/<td.*?>(.*?)<\/td>/is', '$1', $text );
        }
        if ( $tag[3] ) {
            $text = preg_replace( '/<thead.*?>(.*?)<\/thead>/is', "<$tag[3]>$1</$tag[3]>", $text );
        } else {
            $text = preg_replace( '/<thead.*?>(.*?)<\/thead>/is', '$1', $text );
        }
        if ( $tag[4] ) {
            $text = preg_replace( '/<tfoot.*?>(.*?)<\/tfoot>/is', "<$tag[4]>$1</$tag[4]>", $text );
        } else {
            $text = preg_replace( '/<tfoot.*?>(.*?)<\/tfoot>/is', '$1', $text );
        }
        if ( $tag[5] ) {
            $text = preg_replace( '/<caption.*?>(.*?)<\/caption>/is', "<$tag[5]>$1</$tag[5]>", $text );
        } else {
            $text = preg_replace( '/<caption.*?>(.*?)<\/caption>/is', '$1', $text );
        }
    } else {
        $text = preg_replace( '/<table.*?>(.*?)<\/table>/is', '$1', $text );
        $text = preg_replace( '/<tr.*?>(.*?)<\/tr>/is', '$1', $text );
        $text = preg_replace( '/<td.*?>(.*?)<\/td>/is', '$1', $text );
        $text = preg_replace( '/<thead.*?>(.*?)<\/thead>/is', '$1', $text );
        $text = preg_replace( '/<tfoot.*?>(.*?)<\/tfoot>/is', '$1', $text );
        $text = preg_replace( '/<caption.*?>(.*?)<\/caption>/is', '$1', $text );
    }
    return $text;
}
?>