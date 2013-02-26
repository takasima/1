<?php
    function __init_contactform_class ( $ctx ) {
        $driver = strtolower( get_class( $ctx->mt->db() ) );
        $oracle = strpos( $driver, 'oracle' );
        if ( $oracle ) {
            $prefix = 'cfm';
        } else {
            $prefix = 'contactform';
        }
        require_once "class.mt_{$prefix}.php";
        return $prefix;
    }
    function __init_contactformgroup_class ( $ctx ) {
        $driver = strtolower( get_class( $ctx->mt->db() ) );
        $oracle = strpos( $driver, 'oracle' );
        if ( $oracle ) {
            $prefix = 'cfmg';
        } else {
            $prefix = 'contactformgroup';
        }
        require_once "class.mt_{$prefix}.php";
        return $prefix;
    }
    function __init_contactformorder_class ( $ctx ) {
        $driver = strtolower( get_class( $ctx->mt->db() ) );
        $oracle = strpos( $driver, 'oracle' );
        if ( $oracle ) {
            $prefix = 'cfmo';
        } else {
            $prefix = 'contactformorder';
        }
        require_once "class.mt_{$prefix}.php";
        return $prefix;
    }
    function __init_feedback_class ( $ctx ) {
        $driver = strtolower( get_class( $ctx->mt->db() ) );
        $oracle = strpos( $driver, 'oracle' );
        if ( $oracle ) {
            $prefix = 'fb';
        } else {
            $prefix = 'feedback';
        }
        require_once "class.mt_{$prefix}.php";
        return $prefix;
    }?>