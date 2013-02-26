<?php
require_once( 'class.baseobject.php' );
class CustomObjectGroup extends BaseObject
{
    public $_table = 'mt_cog';
    protected $_prefix = "cog_";
    private $_data = NULL;
}
?>