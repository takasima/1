<?php
function smarty_function_mtcustomobjectlabel ( $args, &$ctx ) {
    $blog_id = $args[ 'blog_id' ];
    // if (! isset( $blog_id ) ) {
        // $blog_id = $ctx->stash( 'blog' )->id;
    // }
    $component = $args[ 'component' ];
    $stash_key;
    if (! $component ) {
        $component = 'customobjectconfig';
        $stash_key = 'customobjectconfig';
    } else {
        $component = strtolower( $component );
        $stash_key = $component . 'config';
    }
    $config;
    if ( $blog_id ) {
        if ( $ctx->stash( "{$stash_key}:{$blog_id}" ) ) {
            $config = $ctx->stash( "{$stash_key}:{$blog_id}" );
        } else {
            $config = $ctx->mt->db()->fetch_plugin_data( $component, "configuration:blog:$blog_id" );
            $ctx->stash( "{$stash_key}:{$blog_id}", $config );
        }
    } else {
        if ( $ctx->stash( $stash_key ) ) {
            $config = $ctx->stash( $stash_key );
        } else {
            $config = $ctx->mt->db()->fetch_plugin_data( $component, 'configuration' );
            $ctx->stash( $stash_key, $config );
        }
    }
    $language = $args[ 'language' ];
    if (! $language ) {
        $language = $args[ 'lang' ];
    }
    $plural = $args[ 'plural' ];
    $label;
    if ( $language == 'ja' ) {
        $label = $config[ 'label_ja' ];
    } else {
        if ( isset( $plural ) ) {
            $label = $config[ 'label_plural' ];
        } else {
            $label = $config[ 'label_en' ];
        }
    }
    if (! isset( $label ) ) {
        $label = 'CustomObject';
    }
    return $label;
}
?>