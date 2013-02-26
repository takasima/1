<?php
    function __init_customgroup_class ( $ctx ) {
        $driver = strtolower( get_class( $ctx->mt->db() ) );
        $oracle = strpos( $driver, 'oracle' );
        if ( $oracle ) {
            $prefix = 'cg';
        } else {
            $prefix = 'customgroup';
        }
        require_once "class.mt_{$prefix}.php";
        return $prefix;
    }
    function __init_grouporder_class ( $ctx ) {
        $prefix = 'grouporder';
        require_once "class.mt_{$prefix}.php";
        return $prefix;
    }
?>