<?php
function smarty_block_mtifcontactformisclosed ( $args, $content, &$ctx, &$repeat ) {
    if (! isset( $content ) ) {
        $contactform = $ctx->stash( 'contactformgroup' );
        if (! isset( $contactform ) ) {
            return $ctx->error();
        } else {
            require_once( 'contactform.util.php' );
            if ( $contactform->status == 5 ) {
                return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, TRUE );
            }
            if ( ( $contactform->set_limit != 1 ) && ( $contactform->set_period != 1 ) ) {
                return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, FALSE );
            }
            $prefix = __init_feedback_class( $ctx );
            $_feedback = new Feedback;
            $contactform_id = $contactform->id;
#            $feedback_count = $_feedback->count( "contactform_group_id={$contactform_id}" );
            $feedback_count = $_feedback->count( array( 'where' => "{$prefix}_contactform_group_id={$contactform_id}" ) );
            if ( $contactform->set_limit == 1 ) {
                if ( $feedback_count >= $post_limit ) {
                    return $ctx->_hdlr_if( $args, $content, $ctx, $repeat, FALSE );
                    // TODO :: Status to 4.?
                }
            }
            $period_on = $contactform->period_on;
            $period_on = preg_replace( '/[\s|:|\-]/', '', $period_on );
            require_once( 'MTUtil.php' );
            $t  = time();
            $ts = offset_time_list( $t, $ctx->stash( 'blog' ) );
            $ts = sprintf( "%04d%02d%02d%02d%02d%02d",
                $ts[5]+1900, $ts[4]+1, $ts[3], $ts[2], $ts[1], $ts[0] );
            if ( $ts >= $period_on ) {
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