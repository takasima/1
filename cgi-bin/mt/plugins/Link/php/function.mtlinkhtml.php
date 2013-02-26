<?php
function smarty_function_mtlinkhtml ( $args, $ctx ) {
    $link = $ctx->stash( 'link' );
    if (! isset( $link ) ) {
        return $ctx->error();
    } else {
        require_once( "MTUtil.php" );
        $name = $link->name;
        $url = $link->url;
        if ( (! $name ) || (! $url ) ) {
            return '';
        }
        $title = $link->title;
        $target = $link->target;
        $rel = $link->rel;
        $name = encode_html( $name );
        $tag = "<a href=\"$url\"";
        if ( $title ) {
            $title = encode_html( $title );
            $tag .= " title=\"$title\"";
        }
        if ( $target ) {
            $target = encode_html( $target );
            $tag .= " target=\"$target\"";
        }
        if ( $rel ) {
            $rel = encode_html( $rel );
            $tag .= " rel=\"$rel\"";
        }
        $tag .= ">$name</a>";
        return $tag;
    }
}
?>