<?php
    function __init_campaigngroup_class ( $ctx ) {
        $driver = strtolower( get_class( $ctx->mt->db() ) );
        $oracle = strpos( $driver, 'oracle' );
        if ( $oracle ) {
            $prefix = 'cpg';
        } else {
            $prefix = 'campaigngroup';
        }
        require_once "class.mt_{$prefix}.php";
        return $prefix;
    }
    function __init_campaignorder_class ( $ctx ) {
        $driver = strtolower( get_class( $ctx->mt->db() ) );
        $oracle = strpos( $driver, 'oracle' );
        if ( $oracle ) {
            $prefix = 'cpo';
        } else {
            $prefix = 'campaignorder';
        }
        require_once "class.mt_{$prefix}.php";
        return $prefix;
    }
?>