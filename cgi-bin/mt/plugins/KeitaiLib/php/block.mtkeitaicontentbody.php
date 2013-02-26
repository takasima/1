<?php
function smarty_block_mtkeitaicontentbody( $args, $content, &$ctx, &$repeat ) {
    if ( isset( $content ) ) {
        $start_tag = $ctx->stash( '_split_start_tag' );
        $size      = $ctx->stash( '_keitai_size' );
        $page      = $ctx->stash( '_keitai_current' );
        if ( preg_match ( "/^</", $start_tag ) ) {
            $regex = preg_quote ( $start_tag, "/" );
            $separate_tag = false;
        } else {
            $regex        = "<{$start_tag}.*?>";
            $separate_tag = true;
            $start_tag    = "<{$start_tag}>";
        }
        $paragraphs = preg_split( "/{$regex}/", $content, -1, PREG_SPLIT_NO_EMPTY );
        $contents = array();
        if ( count( $paragraphs ) > 0 ) {
            if ( trim ( $paragraphs[0] ) == "" ) {
                unset( $paragraphs[0] );
            }
            $continue = "";
            $i = 0;
            foreach ( $paragraphs as $key => $paragraph ) {
                if ( $paragraph != "" ) {
                    if (! $i ) {
                        $buf = $paragraph;
                    } else {
                        $buf = $continue . $start_tag . $paragraph;
                    }
                    if ( strlen( $buf ) > $size ) {
                        $contents[] = $buf;
                        $continue = "";
                    } else {
                        $continue = $buf;
                    }
                }
                $i++;
            }
            if ( $continue ) {
                $contents[] = $continue;
            }
            $ctx->stash( "_keitai_page_count", count( $contents ) );
            return $contents[ $page - 1 ];
        }
    }
    return $content;
}
?>