<?php
function smarty_block_mtaltsearchresults( $args, $content, &$ctx, &$repeat ) {
    $localvars = array( 'entry', '_entries_counter', 'entries',
                        'blog', 'blog_id', 'permalink' );
    # 2.043
    $app = $ctx->stash( 'bootstrapper' );
    $param = array( 'args', 'ctx', 'content', 'repeat', 'execute_sql' );
    $app->delete_params( $param );
    # /2.043
    $execute_sql = TRUE;
    if (! isset( $content ) ) {
        $ctx->localize( $localvars );
        # /2.043
        $param = isset( $_SERVER[ 'REDIRECT_QUERY_STRING' ] )
                      ? $_SERVER[ 'REDIRECT_QUERY_STRING' ]
                      : ( isset( $_SERVER[ 'QUERY_STRING' ] )
                          ? $_SERVER[ 'QUERY_STRING' ] : '' );
        parse_str( $param );
        # /2.043
        if ( $includeBlogs ) {
            $include_blogs = $includeBlogs;
        }
        if ( $include_blogs ) {
            if (! is_array( $include_blogs ) ) {
                $include_blogs = explode( ",", $include_blogs );
            }
        }
        $from_enc    = mb_detect_encoding( $query, 'UTF-8,EUC-JP,SJIS,JIS' );
        $charset = $ctx->mt->config( 'PublishCharset' );
        if (! $charset ) {
            $charset = 'UTF-8';
        }
        $ua = $_SERVER[ "HTTP_USER_AGENT" ];
        if ( $param != "" && preg_match("/KDDI/", $ua ) ) {
            $get = explode( "&", $param );
            foreach ( $get as $value ) {
                list( $key, $val ) = explode( "=", $value );
                if ( $key == 'include_blogs' ) {
                    continue;
                }
                $$key = mb_convert_encoding( $val, $charset, "SJIS" );
            }
        }
        $query = mb_convert_encoding( $query, $charset, $from_enc );
        if ( preg_match( "/KDDI/", $ua ) ) { # FIXME
            $query = urldecode( $query );
        }
        if ( $and_or != 'or' ) {
            $and_or = 'and';
        }
        // Search Blog ID
        $values  = array();
        $exclude = true;
        if ( empty( $blog_id ) || ! ctype_digit( $blog_id ) ) {
            if ( is_string( $blog_id ) ) {
                list( $blog_id, $category ) = explode( '-', $blog_id, 2 );
            }
            if ( empty( $blog_id ) || ! ctype_digit( $blog_id ) ) {
                unset( $blog_id, $category );
            } elseif ( empty( $category ) || ! ctype_digit( $category ) ) {
                unset( $category );
            }
        }
        if ( $blog_id ) {
            $values[ $blog_id ] = $blog_id;
        }
        require_once 'class.mt_blog.php';
        if ( $include_blogs ) {
            foreach ( $include_blogs as $buf ) {
                if ( $buf == "all" ) {
                    $include_blogs = array();
                    $_blog = new Blog;
                    $blogs = $_blog->Find( '' );
                    foreach ( $blogs as $read ) {
                        $values[ $read->id ] = $read->id;
                    }
                } else {
                    # 2.043
                    if ( ctype_digit( $buf ) ) {
                        if ( $buf ) {
                            $values[ $buf ] = $buf;
                        }
                    }
                    # /2.043
                }
            }
        }
        if (! $blog_id && ! $include_blogs ) {
            $_blog = new Blog;
            $blogs = $_blog->Find( '' );
            foreach ( $blogs as $read ) {
                $values[ $read->id ] = $read->id;
            }
        }
        if ( $exclude ) {
            foreach ( $values as $key => $buf ) {
                $_blog = new Blog;
                $where = "blog_id={$buf}";
                $extra = array(
                    "limit"  => 1,
                    "offset" => 0,
                );
                $read  = $_blog->Find( $where, false, false, $extra );
                if ( $read[0]->blog_id != $blog_id && $read[0]->blog_exclude_search == 1 ) {
                    unset( $values[ $key ] );
                }
            }
        }
        if ( count( $values ) == 0 ) {
            $_blog = new Blog;
            $blogs = $_blog->Find( '' );
            foreach ( $blogs as $buf ) {
                if ( $buf->exclude_search != 1 ) {
                    $values[ $buf->id ] = $buf->id;
                }
            }
        }
        if ( $categories ) {
            if (! is_array( $categories ) ) {
                $categories = preg_split( '/\s*,\s*/', $categories, -1, PREG_SPLIT_NO_EMPTY );
            }
        } else {
            $categories = array();
        }
        if ( $category ) {
            $categories[] = $category;
        }
        # 2.043
        $_categories = array();
        foreach ( $categories as $cat ) {
            if ( ctype_digit( $cat ) ) {
                if ( $cat ) {
                    $_categories[] = $cat;
                }
            }
        }
        $categories = $_categories;
        # /2.043
        if ( $categories_and_or != 'and' ) {
            $categories_and_or = 'or';
        }
        if (! ctype_digit( $offset ) ) {
            $offset = NULL;
        }
        if (! $offset ) {
            $offset = 1;
        }
        if (! ctype_digit( $limit ) ) {
            $limit = NULL;
        }
        if (! $limit ) {
            if ( $blog_id ) {
                if ( ctype_digit( $blog_id ) ) {
                    $config = $ctx->mt->db()->fetch_plugin_data( 'altsearch', "configuration:blog:$blog_id" );
                    $limit = isset( $config[ 'default_limit' ] ) ? $config[ 'default_limit' ] : 20;
                } else {
                    $limit = 20;
                }
            } else {
                $limit = 20;
            }
        }
        $counter = 0;
    } else {
        $counter = $ctx->stash( '_entries_counter' );
    }
    $entries = $ctx->stash( 'entries' );
    if (! isset( $entries ) ) {
        $query = preg_replace ( '/^\s/', '', $query );
        $query = preg_replace ( '/\s$/', '', $query );
        $query = addslashes ( $query );
        $query = preg_replace ( '/_/', '', $query );
        $query = preg_replace ( '/%/', '', $query );
        $query = $ctx->mt->db()->escape( $query );
        $sort  = 0;
        if ( ( $sort_by ) && (
            ( $sort_by == 'title' ) ||
            ( $sort_by == 'modified_on' ) ||
            ( $sort_by == 'text' ) ||
            ( $sort_by == 'text_more' ) ||
            ( $sort_by == 'keywords' ) ||
            ( $sort_by == 'excerpt' ) ||
            ( $sort_by == 'created_on' ) ||
            ( $sort_by == 'authored_on' ) ||
            ( $sort_by == 'author_id' ) ) ) {
            $sort_by = 'entry_' . $sort_by;
            $sort = 1;
        } else {
            $sort_by = 'entry_authored_on';
        }
        if ( $sort_order ) {
            if ( $sort_order == 'ascend' ){
                $sort_order = 'ASC';
            } else {
                $sort_order = 'DESC';
            }
            $sort = 1;
        } else {
            $sort_order = 'DESC';
        }
        //sort_order="ascend | descend
        if ( $from_y ) {
            $from = "$from_y-$from_m-$from_d";
            $to = "$to_y-$to_m-$to_d";
        }
        if ( $from ) {
            if (! preg_match( "/^[0-9]{4}\-[0-9]{2}\-[0-9]{2}$/", $from ) ) {
                $from = '';
            }
        }
        if ( $to ) {
            if (! preg_match( "/^[0-9]{4}\-[0-9]{2}\-[0-9]{2}$/", $to ) ) {
                $to = '';
            }
        }
        if ( ( $date == 'created_on' ) || ( $date == 'modified_on' ) ) {
        } else {
            $date = 'authored_on';
        }
        $lq = '';
        if ( $tag ) {
            $query = preg_replace ( '/,\s{2,}/', ',', $query );
            $qs = explode( ",", $query );
            foreach ( $qs as $q ) {
                if ( $lq == '' ) {
                    $lq = " tag_name = '" . $q . "'";
                } else {
                    $lq .= " OR tag_name = '" . $q . "'";
                }
            }
            $lq .= " AND tag_is_private = 0 ";
            require_once 'class.mt_tag.php';
            $_tag = new Tag;
            $where = $lq;
            $results = $_tag->Find( $where );
            $tags = array();
            if ( count( $results ) > 0 ) {
                foreach ( $results as $row ) {
                    $tag_name = $row->tag_name;
                    $tag_id = $row->tag_id;
                    array_push( $tags, $tag_id );
                }
                // for oracle
                $driver = strtolower( get_class( $ctx->mt->db() ) );
                $oracle = strpos( $driver, 'oracle' );
                $sql = "SELECT " . ( $oracle ? "" : "DISTINCT" ) . " mt_entry.entry_id , mt_entry.entry_blog_id, mt_entry.entry_class FROM ";
                if ( ( $categories ) && $categories_and_or == 'or' ) {
                    $sql .= " mt_entry, mt_objecttag , mt_placement , mt_author WHERE ";
                    $sql .= " mt_entry.entry_id = mt_placement.placement_entry_id AND ( ";
                    $i = 0;
                    foreach ( $categories as $category_id ) {
                        if ( $category_id !== '' && ctype_digit( $category_id ) ) {
                            $i++;
                            if ( $i >= 2 ) {
                                $sql .= " OR ";
                            }
                            $sql .= " mt_placement.placement_category_id = $category_id ";
                        }
                    }
                    $sql .= " ) AND ";
                } else {
                    $sql .= " mt_entry, mt_objecttag, mt_author WHERE ";
                }
                $sql .= " mt_entry.entry_id = mt_objecttag.objecttag_object_id AND "
                     . " mt_objecttag.objecttag_object_datasource = 'entry' AND (";
                $lq = '';
                foreach( $tags as $id ){
                    if ( ctype_digit( $id ) ) {
                        if ( $lq == '' ) {
                            $lq .= " mt_objecttag.objecttag_tag_id = $id ";
                        } else {
                            $lq .= " OR mt_objecttag.objecttag_tag_id = $id ";
                        }
                    }
                }
                $sql .= "$lq) ";
            } else {
                $execute_sql = FALSE;
            }
        } else {
            if ( $no_keyword ) {
            } else {
                $query = preg_replace ( '/\s{2,}/', ' ', $query );
                $qs = explode( " ", $query );
                foreach ( $qs as $q ) {
                    if ( $lq == '' ) {
                        if ( $ctx->mt->config( 'DBDriver' ) == 'mysql' && !isset( $args[ 'not_binary' ] ) ) {
                            $lq = "(entry_title LIKE BINARY '%" . $q . "%'";
                        } else {
                            $lq = "(entry_title LIKE '%" . $q . "%'";
                        }
                    } else {
                        if ( $and_or == 'or' ) {
                            $lq .= " OR ";
                        } else {
                            $lq .= " AND ";
                        }
                        if ( $ctx->mt->config( 'DBDriver' ) == 'mysql' && !isset( $args[ 'not_binary' ] ) ) {
                            $lq .= "(entry_title LIKE BINARY '%".$q."%'";
                        } else {
                            $lq .= "(entry_title LIKE '%".$q."%'";
                        }
                    }
                    if ( $ctx->mt->config('DBDriver') == 'mysql' && !isset( $args[ 'not_binary' ] ) ) {
                        $lq .= " OR entry_text LIKE BINARY '%" . $q . "%'";
                        $lq .= " OR entry_text_more LIKE BINARY '%" . $q . "%'";
                        $lq .= " OR entry_excerpt LIKE BINARY '%" . $q . "%'";
                        $lq .= " OR entry_ext_datas LIKE BINARY '%" . $q . "%'";
                        $lq .= " OR entry_keywords LIKE BINARY '%" . $q . "%')";
                    } else {
                        $lq .= " OR entry_text LIKE '%" . $q . "%'";
                        $lq .= " OR entry_text_more LIKE '%" . $q . "%'";
                        $lq .= " OR entry_excerpt LIKE '%" . $q . "%'";
                        $lq .= " OR entry_ext_datas LIKE '%" . $q . "%'";
                        $lq .= " OR entry_keywords LIKE '%" . $q . "%')";
                    }
                }
                if ( $lq ) {
                    $lq = '(' . $lq . ')';
                }
            }
            if ( $categories && $categories_and_or == 'or' ) {
                $sql = " SELECT distinct mt_entry.entry_id , mt_entry.entry_blog_id, mt_entry.entry_class "
                        . " FROM mt_entry,  mt_placement, mt_author ";
                $sql .= " WHERE mt_entry.entry_id = mt_placement.placement_entry_id AND ( ";
                $i = 0;
                foreach ( $categories as $category_id ) {
                    if ( ctype_digit( $category_id ) ) {
                        $i++;
                        if ( $i >= 2 ) {
                            $sql .= " OR ";
                        }
                        $sql .= " mt_placement.placement_category_id = $category_id ";
                    }
                }
                $sql .= " ) AND ";
            } else {
                $sql = "SELECT mt_entry.entry_id , mt_entry.entry_blog_id, mt_entry.entry_class "
                        .  " FROM mt_entry, mt_author "
                        .  " WHERE ";
            }
            if ( $lq ) {
                $sql .= " ($lq) ";
            }
        }
        if ( $lq ) {
            $sql .= " AND ";
        }
        $sql .= " mt_entry.entry_author_id = mt_author.author_id "
             .  " AND entry_status = 2";
        if ( $from ) {
            $sql .= " AND mt_entry.entry_" . $date . " >= '" . $from . " 00:00:00' ";
        }
        if ( $to ) {
            $sql .= " AND mt_entry.entry_" . $date . " <= '" . $to . " 23:59:59' ";
        }
        if ( is_array( $values ) and $values != array() ) {
            $array = array();
            foreach ( $values as $key => $value ) {
                if ( ctype_digit( $value ) ) {
                    $array[] = " entry_blog_id = $value ";
                }
            }
            if ( $array ) {
                $sql .= ' AND (' . implode( ' OR ', $array ) . ') ';
            }
        }
        $values = array();
        if ( $exclude_blogs ) {
            foreach ( (array)$exclude_blogs as $key => $value ) {
                $values = array_merge( $values, preg_split('/\s*,\s*/', $value, -1, PREG_SPLIT_NO_EMPTY ) );
            }
        }
        if ( is_array( $values ) and $values != array() ) {
            foreach ( $values as $key => $value ) {
                if ( ctype_digit( $value ) ) {
                    $sql .= " AND entry_blog_id != $value ";
                }
            }
        }
        if ( ( $class == 'entry' ) || ( $class == 'page' ) ) {
            $sql .= " AND mt_entry.entry_class = '$class' ";
        }
        if ( $categories && $categories_and_or == 'and' ) {
            foreach ( $categories as $category_id ) {
                if ( ctype_digit( $category_id ) ) {
                    $sql .= " AND mt_entry.entry_id IN (SELECT mt_entry.entry_id FROM mt_entry, mt_placement WHERE mt_entry.entry_id = mt_placement.placement_entry_id AND mt_placement.placement_category_id = $category_id) ";
                }
            }
        }
        $params = array( 'sql' => $sql, 'sort_by' => $sort_by, 'sort_order' => $sort_order,
                         'limit' => $limit, 'offset' => $offset );
        $app->run_callbacks( 'pre_altsearch', $mt, $ctx, $args, $params );
        $sql = $params[ 'sql' ];
        $offset = $params[ 'offset' ];
        $limit = $params[ 'limit' ];
        $sort_by = $params[ 'sort_by' ];
        $sort_order = $params[ 'sort_order' ];
        $sql .= " ORDER BY $sort_by $sort_order ";
        if ( ctype_digit( $offset ) ) {
            if ( ctype_digit( $limit ) ) {
                if ( $offset < 1 ) {
                    $offset = 0;
                } else {
                    $offset--;
                }
            }
        } else {
            $offset = 0;
        }
        if ( $execute_sql ) {
            // $app->run_callbacks( 'pre_altsearch', $mt, $ctx, $args, $sql );
            $entries = $ctx->mt->db()->SelectLimit( $sql, $limit, $offset );
        } else {
            $entries = array();
        }
        $ctx->stash( 'entries', $entries );
    } else {
        $counter = $ctx->stash( '_entries_counter' );
    }
    if ( $counter < $entries->RecordCount() ) {
        $blog_id = $ctx->stash( 'blog_id' );
        $entries->Move( $counter );
        $entry = $entries->FetchRow();
        if ( $blog_id != $entry[ 'entry_blog_id' ] ) {
            $blog_id = $entry[ 'entry_blog_id' ];
            $ctx->stash( 'blog_id', $blog_id );
            $ctx->stash('blog', $ctx->mt->db()->fetch_blog( $blog_id ) );
        }
        $args[ 'blog_id' ] = $blog_id;
        $at = 'Individual';
        //MT4 only
        $class = $entry[ 'entry_class' ];
        $e;
        if ( $class == 'page' ) {
            $at = 'Page';
            $e = $ctx->mt->db()->fetch_page( $entry[ 'entry_id' ] );
        } else {
            $e = $ctx->mt->db()->fetch_entry( $entry[ 'entry_id' ] );
        }
        $ctx->stash( 'entry', $e );
        $permalink = $ctx->mt->db()->entry_link( $entry[ 'entry_id' ], $at, $args );
        $ctx->stash( 'permalink', $permalink );
        $ctx->stash( '_entries_counter', $counter + 1 );
        $repeat = true;
    } else {
        $ctx->restore( $localvars );
        $repeat = false;
    }
    return $content;
}
?>
