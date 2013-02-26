<?php
require_once("class.baseobject.php");
class Link extends BaseObject
{
    public $_table = 'mt_link';
    protected $_prefix = "link_";
    private $_data = null;
}
?>