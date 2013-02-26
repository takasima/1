<?php
require_once( 'class.baseobject.php' );
class CustomObjectOrder extends BaseObject
{
    public $_table = 'mt_coo';
    protected $_prefix = 'coo_';
    private $_data = NULL;
}
?>