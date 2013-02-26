<?php
require_once( 'class.baseobject.php' );
class CustomGroup extends BaseObject
{
    public $_table = 'mt_cg';
    protected $_prefix = "cg_";
    private $_data = NULL;
}
?>