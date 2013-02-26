<?php
require_once("class.baseobject.php");

class ExtFields extends BaseObject
{
    public $_table = 'mt_extfields';
    protected $_prefix = "extfields_";
    private $_data = null;
}
