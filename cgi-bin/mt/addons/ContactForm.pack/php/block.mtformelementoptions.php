<?php
function smarty_block_mtformelementoptions ( $args, $content, &$ctx, &$repeat ) {
    $localvars = array( 'formelementoption', 'formelementoptions', '_formelementoptions_counter' );
    $glue = $args[ 'glue' ];
    if (! isset( $content ) ) {
        $contactform = $ctx->stash( 'contactform' );
        if ( $contactform ) {
            $ctx->localize( $localvars );
            $options = $contactform->options;
            $options = explode( ',', $options );
            $ctx->stash( 'formelementoptions', $options );
            $counter = 0;
        }
        if ( ! $options[ 0 ] ) {
            $ctx->restore( $localvars );
            $repeat = false;
            return '';
        }
    } else {
        $options = $ctx->stash( 'formelementoptions' );
        $counter = $ctx->stash( '_formelementoptions_counter' );
    }
    if ( $counter < count( $options ) ) {
        $value = $options[ $counter ];
        $ctx->stash( 'formelementoptions', $options );
        $ctx->stash( '_formelementoptions_counter', $counter + 1 );
        $count = $counter + 1;
        $ctx->__stash[ 'vars' ][ 'option_value' ] = $value;
        $ctx->__stash[ 'vars' ][ '__counter__' ] = $count;
        $ctx->__stash[ 'vars' ][ '__odd__' ]  = ( $count % 2 ) == 1;
        $ctx->__stash[ 'vars' ][ '__even__' ] = ( $count % 2 ) == 0;
        $ctx->__stash[ 'vars' ][ '__first__' ] = $count == 1;
        $ctx->__stash[ 'vars' ][ '__last__' ] = ( $count == count( $options ) );
        $repeat = true;
    } else {
        $ctx->restore( $localvars );
        $repeat = false;
    }
    if ( ( $counter > 1 ) && $glue && (! empty( $content ) ) ) {
         $content = $glue . $content;
    }
    return $content;
}
?>