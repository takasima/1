<?php
require_once( 'class.baseobject.php' );
class CustomObject extends BaseObject
{
    public $_table = 'mt_customobject';
    public $_prefix = 'customobject_';
    private $_data = NULL;
    protected $_has_meta = TRUE;
}
ADODB_Active_Record::ClassHasMany( 'CustomObject', 'mt_customobject_meta', 'customobject_meta_customobject_id' );
?>