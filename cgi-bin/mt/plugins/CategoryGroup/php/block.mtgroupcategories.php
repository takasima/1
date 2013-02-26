<?php
function smarty_block_mtgroupcategories ( $args, $content, &$ctx, &$repeat ) {
    $args[ 'class' ] = 'categorygroup';
    $args[ 'child_class' ] = 'category';
    $args[ 'stash' ] = 'category';
    $args[ 'prefix' ] = 'category';
    $this_tag = $ctx->this_tag();
    if (! $this_tag ) return;
    $this_tag = strtolower( $this_tag );
    $this_tag = preg_replace( '/^mt/i', '', $this_tag );
    if ( $this_tag != 'groupcategories' ) {
        $value;
        if (! isset ( $content ) ) {
            $value = _hdlr_customfield_value( $args, $ctx, $this_tag );
            if (! $value ) {
                $repeat = FALSE;
                return '';
            }
            $ctx->stash( $this_tag . '___customfield_value', $value );
        } else {
            $value = $ctx->stash( $this_tag . '___customfield_value' );
        }
        $args[ 'id' ] = $value;
        if ( $args[ 'raw' ] ) {
            return $value;
        }
        $args[ 'group_id' ] = $value;
    }
    require_once( 'block.mtgroupobjects.php' );
    return smarty_block_mtgroupobjects( $args, $content, $ctx, $repeat );
}
?>