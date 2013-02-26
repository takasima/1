<?php
    function __init_customobject_class ( $ctx ) {
        $driver = strtolower( get_class( $ctx->mt->db() ) );
        $oracle = strpos( $driver, 'oracle' );
        if ( $oracle ) {
            $prefix = 'co';
        } else {
            $prefix = 'customobject';
        }
        require_once "class.mt_{$prefix}.php";
        return $prefix;
    }
    function __init_customobjectgroup_class ( $ctx ) {
        $driver = strtolower( get_class( $ctx->mt->db() ) );
        $oracle = strpos( $driver, 'oracle' );
        if ( $oracle ) {
            $prefix = 'cog';
        } else {
            $prefix = 'customobjectgroup';
        }
        require_once "class.mt_{$prefix}.php";
        return $prefix;
    }
    function __init_customobjectorder_class ( $ctx ) {
        $driver = strtolower( get_class( $ctx->mt->db() ) );
        $oracle = strpos( $driver, 'oracle' );
        if ( $oracle ) {
            $prefix = 'coo';
        } else {
            $prefix = 'customobjectorder';
        }
        require_once "class.mt_{$prefix}.php";
        return $prefix;
    }
?>