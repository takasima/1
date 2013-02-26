<?php
function smarty_modifier_tel2link( $text, $arg ) {
    global $mt;
    $ctx = $mt->context();
    $app = $ctx->stash( 'bootstrapper' );
    $tel2link = NULL;
    if ( $arg == 'force' ) {
        $tel2link = 1;
    } elseif ( $app->get_agent( 'keitai' ) || $app->get_agent( 'smartphone' ) ) {
        $tel2link = 1;
    }
    if ( $tel2link ) {
        $tag_1 = '<a href="tel:';
        $tag_2 = '">';
        $tag_3 = '</a>';
        $pattern1 = '/(<[^>]*>[^<]*?)(0\d{1,4}-\d{1,4}-\d{3,4})/';
        $replace1 = '$1' . $tag_1 . '$2' . $tag_2 . '$2' . $tag_3;
        $pattern2 = '/(<a.*?>\/*)<a.*?>(0\d{1,4}-\d{1,4}-\d{3,4})<\/a>([^<]*?<\/a>)/';
        $replace2 = '$1$2$3';
        $i = 0;
        while (! $end ) {
            $original = $text;
            $text = preg_replace( $pattern1, $replace1, $text );
            //Nest tag
            $text = preg_replace( $pattern2, $replace2, $text );
            if ( $text == $original ) {
                $end = 1;
            }
            $i++;
            //Infinite loop
            if ( $i > 20 ) $end = 1;
        }
    }
    return $text;
}
?>