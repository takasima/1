<?php
require_once( 'class.baseobject.php' );
class CustomObjectGroup extends BaseObject
{
    public $_table = 'mt_customobjectgroup';
    protected $_prefix = "customobjectgroup_";
    private $_data = NULL;
}
?>