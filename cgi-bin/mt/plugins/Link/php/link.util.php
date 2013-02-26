<?php
    function __init_linkgroup_class ( $ctx ) {
        $driver = strtolower( get_class( $ctx->mt->db() ) );
        $oracle = strpos( $driver, 'oracle' );
        if ( $oracle ) {
            $prefix = 'lkg';
        } else {
            $prefix = 'linkgroup';
        }
        require_once "class.mt_{$prefix}.php";
        return $prefix;
    }
    function __init_linkorder_class ( $ctx ) {
        $driver = strtolower( get_class( $ctx->mt->db() ) );
        $oracle = strpos( $driver, 'oracle' );
        if ( $oracle ) {
            $prefix = 'linkorder';
        } else {
            $prefix = 'linkorder';
        }
        require_once "class.mt_{$prefix}.php";
        return $prefix;
    }
?>