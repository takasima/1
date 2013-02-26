<?php
function smarty_block_mtifcontactformisopen ( $args, $content, &$ctx, &$repeat ) {
    if (! isset( $content ) ) {
        $contactform = $ctx->stash( 'contactformgroup' );
        if (! isset( $contactform ) ) {
            return $ctx->error();
        } else {
            if ( $contactform->status != 2 ) {
                return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, FALSE );
            }
            if ( ( $contactform->set_limit != 1 ) && ( $contactform->set_period != 1 ) ) {
                return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, TRUE );
            }
            $publishing_on = $contactform->publishing_on;
            $publishing_on = preg_replace( '/[\s|:|\-]/', '', $publishing_on );
            $period_on = $contactform->period_on;
            $period_on = preg_replace( '/[\s|:|\-]/', '', $period_on );
            require_once( 'MTUtil.php' );
            $t  = time();
            $ts = offset_time_list( $t, $ctx->stash( 'blog' ) );
            $ts = sprintf( "%04d%02d%02d%02d%02d%02d",
                $ts[5]+1900, $ts[4]+1, $ts[3], $ts[2], $ts[1], $ts[0] );
            if ( ( $ts > $publishing_on ) && ( $ts < $period_on ) ) {
                return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, TRUE );
            } else {
                return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, FALSE );
            }
        }
    } else {
        return $ctx->_hdlr_if( $args, $content, $ctx, $repeat );
    }
}
?>