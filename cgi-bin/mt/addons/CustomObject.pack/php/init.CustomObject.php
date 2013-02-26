<?php
    $mt = MT::get_instance();
    $ctx =& $mt->context();
    global $custom_objects;
    global $custom_object_class_names;
    global $custom_object_class_plurals;
    global $custom_object_archive_types;
    $custom_objects = array( 'customobject' );
    $config = $ctx->mt->db()->fetch_plugin_data( 'customobjectconfig', 'configuration' );
    // require_once( 'class.mt_plugindata.php' );
    // $_config = new PluginData;
    // $where = "plugindata_plugin='customobjectconfig' AND plugindata_key='configuration'";
    // $config = $_config->Find( $where, FALSE, FALSE );
    if ( $config ) {
        // $config = $config[ 0 ];
        $ctx->stash( 'customobjectconfig', $config );
        // $custom_object = $config->data( 'custom_objects' );
        $custom_object = $config[ 'custom_objects' ];
        if ( $custom_object ) {
            $custom_objects = explode( ',', $custom_object );
        }
        $class_names = $config[ 'class_names' ];
        // $class_names = $config->data( 'class_names' );
        if ( $class_names ) {
            $custom_object_class_names = explode( ',', $class_names );
        }
        $class_plurals = $config[ 'class_plurals' ];
        // $class_plurals = $config->data( 'class_plurals' );
        if ( $class_plurals ) {
            $custom_object_class_plurals = explode( ',', $class_plurals );
        }
        $archive_types = $config[ 'archive_types' ];
        if ( $archive_types ) {
            $custom_object_archive_types = explode( ',', $archive_types );
        }
    }
    require_once( 'archive_lib.php' );
    ArchiverFactory::add_archiver( 'CustomObject', 'CustomObjectArchiver' );
    class CustomObjectArchiver implements ArchiveType {
        public function get_label( $args = NULL ) {
            return 'CustomObject';
        }
        public function get_title( $args ) {
            $mt = MT::get_instance();
            $ctx =& $mt->context();
            return encode_html( strip_tags( $ctx->tag( 'CustomObjectName', $args ) ) );
        }
        public function get_archive_list( $args ) {
        }
        public function archive_prev_next( $args, $content, &$repeat, $tag, $at ) {
        }
        public function get_range( $period_start ) {
            $mt = MT::get_instance();
            $ctx =& $mt->context();
            $period_start = preg_replace( '/[^0-9]/', '', $period_start );
            return start_end_day( $period_start, $ctx->stash( 'blog' ) );
        }
        public function prepare_list( $row ) {}
        public function setup_args( &$args ) {}
        public function get_archive_link_sql( $ts, $at, $args ) {}
        public function is_date_based() {
            return FALSE;
        }
        public function template_params() {
            $mt = MT::get_instance();
            $ctx =& $mt->context();
            $data = ___get_fileinfo( $ctx );
            $id = $data->customobject_id;
            $blog_id = $data->blog_id;
            require_once( 'customobject.util.php' );
            $prefix = __init_customobject_class( $ctx );
            $include_draft = " AND {$prefix}_status = 2 ";
            $where = "{$prefix}_blog_id={$blog_id} {$include_draft}";
            if ( isset( $id ) ) {
                $where = " {$prefix}_id='{$id}' $include_draft";
            }
            $extra[ 'limit' ] = 1;
            $_customobject = new CustomObject;
            $customobject = $_customobject->Find( $where, false, false, $extra );
            if ( isset( $customobject ) ) {
                $customobject = $customobject[ 0 ];
                $ctx->stash( 'customobject', $customobject );
            }
            $vars =& $ctx->__stash[ 'vars' ];
            $vars[ 'archive_class' ] = 'customobject-archive';
            $vars[ 'customobject_class' ] = 'customobject';
            $vars[ 'archive_listing' ]   = 1;
            $vars[ 'archive_template' ]  = 1;
            $vars[ 'customobject_archive' ] = 1;
        }
    }
    ArchiverFactory::add_archiver( 'FolderCustomObject', 'FolderCustomObjectArchiver' );
    class FolderCustomObjectArchiver implements ArchiveType {
        public function get_label( $args = NULL ) {
            return 'FolderCustomObject';
        }
        public function get_title( $args ) {
            $mt = MT::get_instance();
            $ctx =& $mt->context();
            return encode_html( strip_tags( $ctx->tag( 'FolderLabel', $args ) ) );
        }
        public function get_archive_list( $args ) {
        }
        public function archive_prev_next( $args, $content, &$repeat, $tag, $at ) {
        }
        public function get_range( $period_start ) {
            $mt = MT::get_instance();
            $ctx =& $mt->context();
            $period_start = preg_replace( '/[^0-9]/', '', $period_start );
            return start_end_day( $period_start, $ctx->stash( 'blog' ) );
        }
        public function prepare_list( $row ) {}
        public function setup_args( &$args ) {}
        public function get_archive_link_sql( $ts, $at, $args ) {}
        public function is_date_based() {
            return FALSE;
        }
        public function template_params() {
            $mt = MT::get_instance();
            $ctx =& $mt->context();
            $app = $ctx->stash( 'bootstrapper' );
            if ( $app ) {
                $data = $app->stash( 'fileinfo' );
                if ( isset( $data ) ) {
                    return $data;
                }
            }
            if ( $data = $ctx->stash( 'fileinfo' ) ) {
                return $data;
            }
            $data = ___get_fileinfo( $ctx );
            if ( $app ) {
                $app->stash( 'fileinfo', $data );
            }
            $ctx->stash( 'fileinfo', $data );
            $id = $data->category_id;
            $category = $mt->db()->fetch_folder( $id );
            if ( isset( $category ) ) {
                $ctx->stash( 'category', $category );
            }
            $vars =& $ctx->__stash[ 'vars' ];
            $vars[ 'archive_class' ] = 'folder-customobject-archive';
            $vars[ 'customobject_class' ] = 'customobject';
            $vars[ 'archive_listing' ]   = 1;
            $vars[ 'archive_template' ]  = 1;
            $vars[ 'folder_customobject_archive' ] = 1;
        }
    }
    function ___get_fileinfo ( $ctx ) {
        $app = $ctx->stash( 'bootstrapper' );
        $data = $app->stash( 'fileinfo' );
        if ( isset( $data ) ) {
            return $data;
        }
        $path = NULL;
        if ( !$path && $_SERVER[ 'REQUEST_URI' ] ) {
            $path = $_SERVER[ 'REQUEST_URI' ];
            // strip off any query string...
            $path = preg_replace( '/\?.*/', '', $path );
            // strip any duplicated slashes...
            $path = preg_replace( '!/+!', '/', $path );
        }
        if ( preg_match( '/IIS/', $_SERVER[ 'SERVER_SOFTWARE' ] ) ) {
            if ( preg_match( '/^\d+;( .* )$/', $_SERVER[ 'QUERY_STRING' ], $matches ) ) {
                $path = $matches[1];
                $path = preg_replace( '!^http://[^/]+!', '', $path );
                if ( preg_match( '/\?( .+ )?/', $path, $matches ) ) {
                    $_SERVER[ 'QUERY_STRING' ] = $matches[1];
                    $path = preg_replace( '/\?.*$/', '', $path );
                }
            }
        }
        $path = preg_replace( '/\\\\/', '\\\\\\\\', $path );
        $pathinfo = pathinfo( $path );
        $ctx->stash( '_basename', $pathinfo[ 'filename' ] );
        if ( isset( $_SERVER[ 'REDIRECT_QUERY_STRING' ] ) ) {
            $_SERVER[ 'QUERY_STRING' ] = getenv( 'REDIRECT_QUERY_STRING' );
        }
        if ( preg_match( '/\.( \w+ )$/', $path, $matches ) ) {
            $req_ext = strtolower( $matches[1] );
        }
        $data = $ctx->mt->resolve_url( $path );
        return $data;
    }
?>