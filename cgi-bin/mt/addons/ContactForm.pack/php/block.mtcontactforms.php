<?php
function smarty_block_mtcontactforms( $args, $content, &$ctx, &$repeat ) {
    $localvars = array( 'contactform', '_contactforms_counter', 'contactforms',
                        'contactformgroup' );
    $id = $args[ 'id' ];
    if (! isset( $content ) ) {
        $ctx->localize( $localvars );
        if ( $ctx->__stash[ 'contactforms' ] ) {
            $ctx->__stash[ 'contactforms' ] = NULL;
        }
        $counter = 0;
    } else {
        $counter = $ctx->stash( '_contactforms_counter' );
    }
    $contactforms = $ctx->stash( 'contactforms' );
    if (! isset( $contactforms ) ) {
        include_once( 'contactform.util.php' );
        $prefix = __init_contactform_class ( $ctx );
        $group_prefix = __init_contactformgroup_class ( $ctx );
        $_group = new ContactFormGroup;
        $where = "{$group_prefix}_id = '{$id}'";
        $group = $_group->Find( $where );
        if ( count( $group ) ) {
            $group = $group[ 0 ];
            $order_prefix = __init_contactformorder_class ( $ctx );
            $where = " {$order_prefix}_group_id={$id}"
                   . " ORDER BY {$order_prefix}_order ASC"
                   ;
            $extra[ 'join' ] = array(
                "mt_{$order_prefix}" => array(
                    'condition' => "{$order_prefix}_contactform_id={$prefix}_id",
                ),
            );
        } else {
            $repeat = FALSE;
            return '';
        }
        $_contactform = new ContactForm;
        $contactforms = $_contactform->Find( $where, false, false, $extra );
        if ( count( $contactforms ) == 0 ) {
            $contactforms = array();
        }
        $ctx->stash( 'contactformgroup', $group );
        $ctx->stash( 'contactforms', $contactforms );
    } else {
        $group = $ctx->stash( 'contactformgroup' );
        $counter = $ctx->stash( '_contactforms_counter' );
        $ctx->stash( 'contactformgroup', $group );
    }
    if ( $counter < count( $contactforms ) ) {
        $contactform = $contactforms[ $counter ];
        if ( is_object( $contactform ) ) {
            $local_blog_id = $contactform->blog_id;
            if ( $local_blog_id ) {
                $ctx->stash( 'blog', $ctx->mt->db()->fetch_blog( $local_blog_id ) );
                $ctx->stash( 'blog_id', $local_blog_id );
            }
        }
        $ctx->stash( 'contactform', $contactform );
        $ctx->stash( '_contactforms_counter', $counter + 1 );
        $count = $counter + 1;
        $ctx->__stash[ 'vars' ][ '__counter__' ] = $count;
        $ctx->__stash[ 'vars' ][ '__odd__' ]  = ( $count % 2 ) == 1;
        $ctx->__stash[ 'vars' ][ '__even__' ] = ( $count % 2 ) == 0;
        $ctx->__stash[ 'vars' ][ '__first__' ] = $count == 1;
        $ctx->__stash[ 'vars' ][ '__last__' ] = ( $count == count( $contactforms ) );
        $repeat = true;
    } else {
        $ctx->restore( $localvars );
        $repeat = false;
    }
    return $content;
}
?>