<?php
require_once( 'class.baseobject.php' );
class CustomObject extends BaseObject
{
    public $_table = 'mt_co';
    public $_prefix = 'co_';
    private $_data = NULL;
    protected $_has_meta = TRUE;
}
ADODB_Active_Record::ClassHasMany( 'CustomObject', 'mt_co_meta', 'co_meta_co_id' );
?>