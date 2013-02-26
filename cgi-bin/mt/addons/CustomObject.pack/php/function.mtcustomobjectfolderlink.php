<?php
function smarty_function_mtcustomobjectfolderlink ( $args, &$ctx ) {
    $category = $ctx->stash( 'category' );
    if (! isset( $category ) ) {
        $category = '';
//        return $ctx->error('');
    } else {
        $this_tag = $ctx->this_tag();
        if (! $this_tag ) return;
        $this_tag = preg_replace( '/^mt/i', '', $this_tag );
        $this_tag = preg_replace( '/folderlink$/i', '', $this_tag );
        global $custom_object_archive_types;
        if ( is_array( $custom_object_archive_types ) ) {
            foreach ( $custom_object_archive_types as $type ) {
                $low = strtolower( $type );
                if ( $low == $this_tag ) {
                    $at = 'Folder'. $type;
                    break;
                }
            }
        }
        require_once( 'class.mt_templatemap.php' );
        $id = $category->id;
        $blog_id = $category->blog_id;
        $blog = $ctx->stash( 'blog' );
        if ( $blog_id != $blog->id ) {
            $blog = $ctx->mt->db()->fetch_blog( $blog_id );
            $ctx->stash( 'blog', $blog );
        }
        $_map = new TemplateMap;
        $map = $_map->Find( "templatemap_blog_id={$blog_id} AND templatemap_archive_type='{$at}' AND templatemap_is_preferred=1" );
        if (! $map ) return '';
        $map = $map[0];
        $file_template = $map->file_template;
        if (! $file_template ) {
            $at_lc = strtolower( $at );
            $file_template = '%c/' . $at_lc . '/%i';
        }
        $file_template = preg_replace_callback('/%([_-]?[A-Za-z])/',
        '__folder_customobject_template_format', $file_template );
        $file_template = preg_replace( '/\/{2,}/', '/', $file_template );
        $file_template = preg_replace( '/(^\/|\/$)/', '', $file_template );
        $file_extension;
        if ( preg_match( '/>$/', $file_template ) ) {
            $file_extension = 1;
        }
        $_var_compiled = '';
        if (! $ctx->_compile_source( 'evaluated template', $file_template, $_var_compiled ) ) {
            return $ctx->error( "Error compiling text '$file_template'" );
        }
        ob_start();
        $ctx->_eval( '?>' . $_var_compiled );
        $_contents = ob_get_contents();
        ob_end_clean();
        $_contents = preg_replace( '/\/{2,}/', '/', $_contents );
        $_contents = preg_replace( '/(^\/|\/$)/', '', $_contents );
        if ( $file_extension ) {
            $ext = $blog->file_extension;
            if (! preg_match( "/\.$ext$/", $_contents ) ) {
                $_contents .= '.' . $ext;
            }
        }
        $_contents = preg_replace( '/\-+/', '-', $_contents );
        $site_url = $blog->site_url();
        if (! preg_match( '/\/$/', $site_url ) ) {
            $site_url .= '/';
        }
        return $site_url . $_contents;
    }
}
function __folder_customobject_template_format( $m ) {
    static $f = array(
        'b'  => "<MTFolderBasename>",
        '-b' => "<MTFolderBasename separator='-'>",
        '_b' => "<MTFolderBasename separator='_'>",
        'f'  => "<MTFolderBasename>",
        '-f' => "<MTFolderBasename separator='-'>",
        'c'  => "<MTSubCategoryPath>",
        '-c' => "<MTSubCategoryPath separator='-'>",
        '_c' => "<MTSubCategoryPath separator='_'>",
        'C'  => "<MTCategoryBasename>",
        '-C' => "<MTCategoryBasename separator='-'>",
        'i'  => '<MTIndexBasename extension="1">',
        'I'  => "<MTIndexBasename>",
    );
    return isset( $f[$m[1]] ) ? $f[$m[1]] : $m[1];
}
?>