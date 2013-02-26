<?php
    ArchiverFactory::add_archiver( 'Folder', 'FolderArchiver' );
    class FolderArchiver implements ArchiveType {
        public function get_label( $args = NULL ) {
            return 'Folder';
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
            require_once( 'dynamicmtml.util.php' );
            $data = get_fileinfo_from_ctx( $ctx );
            $cat = $data->fileinfo_category_id;
            $archive_category = $mt->db()->fetch_folder( $cat );
            $ctx->stash( 'category', $archive_category );
            $ctx->stash( 'archive_category', $archive_category );
            $vars =& $ctx->__stash[ 'vars' ];
            $vars[ 'archive_class' ] = 'folder-archive';
            $vars[ 'archive_listing' ]   = 1;
            $vars[ 'archive_template' ]  = 1;
            $vars[ 'folder_archive' ] = 1;
        }
    }
?>