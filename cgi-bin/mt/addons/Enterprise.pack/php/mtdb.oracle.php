<?php
# Movable Type (r) (C) 2001-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

require_once('mtdb.base.php');

class MTDatabaseoracle extends MTDatabase {

    protected $has_distinct = false;

    protected function connect($user, $password = '', $dbname = '', $host = '', $port = '', $sock = '') {
        $db = ADONewConnection('oci8');
        $db->NLS_DATE_FORMAT = 'YYYY-MM-DD HH24:MI:SS';
	$db->firstrows = false;
        $db->pconnect($host, $user, $password, $dbname);
        $this->conn = $db;
        return true;
    }

    public function escape($str) {
        return str_replace("'", "''", str_replace("''", "'", stripslashes($str)));
    }

    public function set_names($mt) {
        return;
    }

    function limit_by_day_sql($column, $days) {
        return $column . ' + interval \'' . intval($days) . '\' day >= sysdate';
    }

    function apply_extract_date($part, $column) {
        return "extract($part from $column)";
    }

    function entries_recently_commented_on_sql($subsql) {
        $sql = $subsql;
        $sql = preg_replace("/select\s+mt_entry/i",
               " select no_sort.* from(select B.comment_created,A",
               $sql);
        $sql = preg_replace("/\s+entry_/i",
               " A.entry_",
               $sql);
        $sql = preg_replace("/from\s+mt_entry/i",
               "from mt_entry A inner join(select entry_id, max(comment_created_on) comment_created from mt_entry inner join mt_comment on entry_id = comment_entry_id and comment_visible = 1 group by entry_id order by max(comment_created_on) desc) B on A.entry_id = B.entry_id",
               $sql);
        $sql .= ") no_sort order by no_sort.comment_created desc";
        return $sql;
    }

    public function decorate_column( $col ) {
        if ( !preg_match( '/DBMS_LOB.SUBSTR/', $col ) ) {
            return "DBMS_LOB.SUBSTR($col, 4000)";
        } else {
            return $col;
        }
    }
}
?>
