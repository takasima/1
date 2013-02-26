<?php
require_once( 'class.baseobject.php' );
class ContactForm extends BaseObject
{
    public $_table = 'mt_cfm';
    public $_prefix = 'cfm_';
    private $_data = NULL;
    protected $_has_meta = TRUE;
}
ADODB_Active_Record::ClassHasMany( 'ContactForm', 'mt_cfm_meta', 'cfm_meta_cfm_id' );
?>