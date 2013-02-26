<?php
function smarty_block_mtaltsearchmetadata( $args, $content, &$ctx, &$repeat ) {
    $localvars = array( 'altsearch', '_altsearch_counter', 'altsearchs', 'pages', 'match', 'prev',
                        'next', 'current', 'bench', 'start', 'date', 'from', 'to' );
    $app = $ctx->stash( 'bootstrapper' );
    $param = array( 'args', 'ctx', 'content', 'repeat', 'execute_sql' );
    $app->delete_params( $param );
    $execute_sql = TRUE;
    if (! isset( $content ) ) {
        $ctx->localize( $localvars );
        list ( $usec, $sec ) = explode( ' ', microtime() );
        $start = (float)$sec + (float)$usec;
        $ctx->stash( 'start', $start );
        $param = isset( $_SERVER[ 'REDIRECT_QUERY_STRING' ] )
                      ? $_SERVER[ 'REDIRECT_QUERY_STRING' ]
                      : ( isset( $_SERVER[ 'QUERY_STRING' ] )
                          ? $_SERVER[ 'QUERY_STRING' ] : '' );
        parse_str( $param );
        if ( $includeBlogs ) {
            $include_blogs = $includeBlogs;
        }
        if ( $include_blogs ) {
            if (! is_array( $include_blogs ) ) {
                $include_blogs = explode( ",", $include_blogs );
            }
        }
        $from_enc = mb_detect_encoding( $query, 'UTF-8,EUC-JP,SJIS,JIS' );
        $charset = $ctx->mt->config( 'PublishCharset' );
        $charset or $charset = 'UTF-8';
        $ua = $_SERVER[ "HTTP_USER_AGENT" ];
        if ( $param != "" && preg_match( "/KDDI/", $ua ) ) {
            $get = explode( "&", $param );
            foreach ( $get as $value ) {
                list( $key, $val ) = explode( "=", $value );
                $$key = mb_convert_encoding( $val, $charset, "SJIS" );
            }
        }
        $query = mb_convert_encoding( $query, $charset, $from_enc );
        if ( $and_or == 'or' ) {} else {
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
        if ( $blog_id && !$include_blogs ) {
            $exclude = false;
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
                    break;
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
        if (! $blog_id && !$include_blogs ) {
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
        if ( $categories_and_or == 'and' ) {} else {
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
        $query = preg_replace ( '/^\s/', '', $query );
        $query = preg_replace ( '/\s$/', '', $query );
        $query = addslashes ( $query );
        $query = preg_replace ( '/_/', '', $query );
        $query = preg_replace ( '/%/', '', $query );
        $query = $ctx->mt->db()->escape( $query );
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
        if ( ( $date == 'created_on') || ( $date == 'modified_on' ) ) {
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
            $sql = "SELECT tag_id, "
                    . " tag_name, tag_n8d_id "
                    . " FROM mt_tag "
                    . " WHERE $lq ";
            $results = $ctx->mt->db()->Execute( $sql );
            $tags = array();
            if ( $results->RecordCount() > 0 ) {
                foreach ( $results as $row ) {
                    $tag_name = $row[ 'tag_name' ];
                    $tag_id = $row[ 'tag_id' ];
                    array_push( $tags, $tag_id );
                }
                $sql = "SELECT COUNT(DISTINCT mt_entry.entry_id) AS CNT FROM ";
                if ( ( $categories ) && $categories_and_or == 'or' ) {
                        $sql .= " mt_entry, mt_objecttag , mt_placement WHERE ";
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
                    $sql .= " mt_entry, mt_objecttag WHERE ";
                }
                $sql .= " mt_entry.entry_id = mt_objecttag.objecttag_object_id AND "
                . " mt_objecttag.objecttag_object_datasource = 'entry'";
                $lq = '';
                foreach( $tags as $id ){
                    if ( $lq == '' ) {
                        $lq .= " mt_objecttag.objecttag_tag_id = $id ";
                    } else {
                        $lq .= " OR mt_objecttag.objecttag_tag_id = $id ";
                    }
                }
                if ( $lq ) {
                    $sql .= " AND (" . $lq . ") ";
                }
                $sql .= " AND mt_entry.entry_status = 2";
                if ( is_array( $values ) and $values != array() ) {
                    $array = array();
                    foreach ( $values as $key => $value ) {
                        if ( ctype_digit( $value ) ) {
                            $array[] = " mt_entry.entry_blog_id = $value ";
                        }
                    }
                    if ( $array ) {
                        $sql .= ' AND (' . implode( ' OR ', $array ) . ') ';
                    }
                }
                $values = array();
                if ( $exclude_blogs ) {
                    foreach ( (array)$exclude_blogs as $key => $value ) {
                        $values = array_merge( $values, preg_split( '/\s*,\s*/', $value, -1, PREG_SPLIT_NO_EMPTY ) );
                    }
                }
                if ( is_array( $values ) and $values != array() ) {
                    foreach ( $values as $key => $value ) {
                        if ( ctype_digit( $value ) ) {
                            $sql .= " AND mt_entry.entry_blog_id != $value ";
                        }
                    }
                }
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
                            $lq = "(entry_title LIKE BINARY '%".$q."%'";
                        } else {
                            $lq = "(entry_title LIKE '%".$q."%'";
                        }
                    } else {
                        if ( $and_or == 'or' ) {
                            $lq .= " OR ";
                        } else {
                            $lq .= " AND ";
                        }
                        if ( $ctx->mt->config( 'DBDriver' ) == 'mysql' && !isset( $args[ 'not_binary' ] ) ) {
                            $lq .= "(entry_title LIKE BINARY '%" . $q . "%'";
                        } else {
                            $lq .= "(entry_title LIKE '%" . $q . "%'";
                        }
                    }
                    if ( $ctx->mt->config( 'DBDriver' ) == 'mysql' && !isset( $args[ 'not_binary' ] ) ) {
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
            if ( $lq ) {
                $lq .= " AND ";
            }
            if ( is_array( $values ) and $values != array() ) {
                $array = array();
                foreach ( $values as $key => $value ) {
                    if ( ctype_digit( $value ) ) {
                        $array[] = " entry_blog_id = $value ";
                    }
                }
                if ( $array ) {
                    $lq .= ' (' . implode(' OR ', $array ) . ') AND ';
                }
            }
            $values = array();
            if ( $exclude_blogs ) {
                foreach ( (array)$exclude_blogs as $key => $value ) {
                    $values = array_merge( $values, preg_split( '/\s*,\s*/', $value, -1, PREG_SPLIT_NO_EMPTY ) );
                }
            }
            if ( is_array( $values ) and $values != array() ) {
                foreach ( $values as $key => $value ) {
                    if ( preg_match('/^[0-9]+$/', $value ) ) {
                        $lq .= " entry_blog_id != $value AND ";
                    }
                }
            }
            $lq .= " entry_status = 2 ";
            if ( $categories && $categories_and_or == 'or' ) {
                $sql = " SELECT COUNT(DISTINCT mt_entry.entry_id) AS CNT ";
                $sql.= " FROM mt_entry,  mt_placement ";
                if ( $fulltext ) {
                    $sql.= " ,  mt_fulltext ";
                }
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
                $sql = "SELECT COUNT(DISTINCT entry_id) AS CNT "
                        . " FROM mt_entry "
                        . " WHERE ";
            }
            $sql .= " ($lq) ";
        }
        if ( $from ) {
            $sql .= " AND mt_entry.entry_" . $date . " >= '" . $from . " 00:00:00' ";
        }
        if ( $to ) {
            $sql .= " AND mt_entry.entry_" . $date . " <= '" . $to . " 23:59:59' ";
        }
        if ( ( $class == 'entry') || ( $class == 'page' ) ) {
            $sql .= " AND mt_entry.entry_class = '$class' ";
        }
        if ( $categories && $categories_and_or == 'and' ) {
            foreach ( $categories as $category_id ) {
                if ( ctype_digit( $category_id ) ) {
                    $sql .= " AND mt_entry.entry_id IN (SELECT mt_entry.entry_id FROM mt_entry, mt_placement WHERE mt_entry.entry_id = mt_placement.placement_entry_id AND mt_placement.placement_category_id = $category_id) ";
                }
            }
        }
        if ( $execute_sql ) {
            $app->run_callbacks( 'pre_altsearch_meta', $mt, $ctx, $args, $sql );
            $count = $ctx->mt->db()->Execute( $sql );
            $match = $count->FetchRow();
            $match = $match[ 0 ];
        } else {
            $match = 0;
        }
        $pages = ceil( $match / $limit );
        $prev = $offset - $limit;
        if ( 1 > $prev ) {
            $prev = 0;
        }
        $next = $offset + $limit;
        if ( $next > $match ) {
            $next = 0;
        }
        $current = ( ( $offset - 1 ) / $limit ) + 1;
        $last = $offset + $limit - 1;
        if ( $match < $last ) {
            $last = $offset + ( $match - $offset );
        }
        $ctx->stash( 'pages', $pages );
        $ctx->stash( 'match', $match );
        $ctx->stash( 'prev', $prev );
        $ctx->stash( 'next', $next );
        $ctx->stash( 'current', $current );
        $ctx->stash( 'last', $last );
        $ctx->stash( 'limit', $limit );
        $ctx->stash( 'offset', $offset );
        $ctx->stash( 'date', $date );
        $ctx->stash( 'from', $from );
        $ctx->stash( 'to', $to );
    } else {
        $counter = $ctx->stash( '_altsearch_counter' );
    }
    $pages = $ctx->stash( 'pages' );
    $match = $ctx->stash( 'match' );
    $prev = $ctx->stash( 'prev' );
    $next = $ctx->stash( 'next' );
    $current = $ctx->stash( 'current' );
    $last = $ctx->stash( 'last' );
    $date = $ctx->stash( 'date' );
    $from = $ctx->stash( 'from' );
    $to = $ctx->stash( 'to' );
    if (! isset( $pages ) ) {
        $ctx->stash( 'pages', $pages );
        $ctx->stash( 'match', $match );
        $ctx->stash( 'prev', $prev );
        $ctx->stash( 'next', $next );
        $ctx->stash( 'current', $current );
        $ctx->stash( 'last', $last );
        $ctx->stash( 'date', $date );
        $ctx->stash( 'from', $from );
        $ctx->stash( 'to', $to );
    } else {
        $counter = $ctx->stash( '_altsearch_counter' );
    }
    if ( $counter <= $pages -1 ) {
        $ctx->stash( 'altsearch', $altsearch );
        $ctx->stash( '_altsearch_counter', $counter + 1 );
        $ctx->stash( 'pages', $pages );
        $ctx->stash( 'match', $match );
        $ctx->stash( 'prev', $prev );
        $ctx->stash( 'next', $next );
        $ctx->stash( 'current', $current );
        $ctx->stash( 'last', $last );
        $ctx->stash( 'date', $date );
        $ctx->stash( 'from', $from );
        $ctx->stash( 'to', $to );
        list( $end_sec, $end_usec ) = explode( ' ', microtime() );
        $end = (float)$end_sec + (float)$end_usec;
        $start = $ctx->stash( 'start' );
        $ctx->stash( 'bench', round( ( $end - $start ), 4 ) );
        $repeat = true;
    } else {
        $ctx->restore( $localvars );
        $repeat = false;
    }
    return $content;
}
?>
