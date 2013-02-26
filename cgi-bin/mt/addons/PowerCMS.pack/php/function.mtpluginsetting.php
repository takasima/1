<?php
function smarty_function_mtpluginsetting( $args, &$ctx ) {
    $app = $ctx->stash( 'bootstrapper' );
    $setting_name = $args[ 'name' ];
    $component = $args[ 'component' ] ? $args[ 'component' ] : 'PowerCMS';
    if ( $component ) {
        $scope = $args[ blog_id ] ? $args[ 'blog_id' ] : '';
        return $app->plugin_get_config_value( $component, $setting_name, $scope );
    }
    return '';
}
?>