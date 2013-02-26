<?php
require_once( 'class.baseobject.php' );
class CustomGroup extends BaseObject
{
    public $_table = 'mt_customgroup';
    protected $_prefix = "customgroup_";
    private $_data = NULL;
}
?>