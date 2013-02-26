<?php
# Movable Type (r) (C) 2001-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

require_once('mtdb.base.php');

class MTDatabasemssqlserver extends MTDatabase {

    protected $has_distinct = false;

    protected function connect($user, $password = '', $dbname = '', $host = '', $port = '', $sock = '') {
        $db = ADONewConnection('mssqlnative');
        $db->pconnect($host, $user, $password, $dbname);
        $db->SetFetchMode(ADODB_FETCH_ASSOC);
        $this->conn = $db;
        return true;
    }

    public function set_names($mt) {
        return;
    }

    function unserialize($data) {
        $data = preg_replace('/\\\\([0-9]{3})/e', 'chr(\1)', $data);
        return parent::unserialize($data);
    }

    function limit_by_day_sql($column, $days) {
        return "(dateadd(day, $days, $column) >= getdate())";
    }

    function entries_recently_commented_on_sql($subsql) {
        $sql = $subsql;
        $sql = preg_replace("/where entry_status = 2/i",
                    "where entry_id in (
                        select entry_id from (
                            select TOP <LIMIT_RCO> entry_id, 
                                row_number() over(order by max(comment_created_on) desc, max( entry_authored_on) desc) as rownum
                            from mt_entry
                            inner join mt_comment on comment_entry_id = entry_id and comment_visible = 1,
                            mt_author where entry_status = 2", $sql);
        $sql = preg_replace("/[^(]order by(.+) (asc|desc)/i",
                    "group by entry_id
                      order by max(comment_created_on) desc, max(\$1) \$2
                  ) tables <OFFSET_RCO>)", $sql);
        return $sql;
    }

    function apply_extract_date($part, $column) {
        return "$part($column)";
    }

    // Override: Because MSSQLServer does not support length() function.
    public function resolve_url($path, $blog_id, $build_type = 3) {
        $path = preg_replace('!/$!', '', $path);
        $blog_id = intval($blog_id);
        # resolve for $path -- one of:
        #      /path/to/file.html
        #      /path/to/index.html
        #      /path/to/
        #      /path/to

        $mt = MT::get_instance();
        $index = $this->escape($mt->config('IndexBasename'));
        $escindex = $this->escape($index);

        require_once('class.mt_fileinfo.php');
        $records = null;
        $extras['join'] = array(
            'mt_template' => array(
                'condition' => "fileinfo_template_id = template_id"
                ),
            );
        foreach ( array($path, urldecode($path), urlencode($path)) as $p ) {
            $where = "fileinfo_blog_id = $blog_id
                      and ((fileinfo_url = '%1\$s' or fileinfo_url = '%1\$s/') or (fileinfo_url like '%1\$s/$escindex%%'))
                      and template_type != 'backup'
                      order by len(fileinfo_url) asc";
            $fileinfo= new FileInfo;
            $records = $fileinfo->Find(sprintf($where, $this->escape($p)),  false, false, $extras);
            if (!empty($records))
                break;
        }
        $path = $p;
        if (empty($records)) return null;

        $found = false;
        foreach ($records as $record) {
            if ( !empty( $build_type ) ) {
                if ( !is_array( $build_type ) ) {
                    $build_type_array = array( $build_type );
                } else {
                    $build_type_array = $build_type;
                }

                $tmpl =  $record->template();
                $map = $record->templatemap();
                $type = empty( $map ) ? $tmpl->build_type : $map->build_type;

                if ( !in_array( $type, $build_type_array ) ) {
                    continue;
                }
            }

            $fiurl = $record->url;
            if ($fiurl == $path) {
                $found = true;
                break;
            }
            if ($fiurl == "$path/") {
                $found = true;
                break;
            }
            $ext = $record->blog()->file_extension;
            if (!empty($ext)) $ext = '.' . $ext;
            if ($fiurl == ($path.'/'.$index.$ext)) {
                $found = true; break;
            }
            if ($found) break;
        }
        if (!$found) return null;
        $blog = $record->blog();
        $this->_blog_id_cache[$blog->id] =& $blog;
        return $record;
    }
}
?>
