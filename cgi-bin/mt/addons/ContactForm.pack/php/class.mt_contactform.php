<?php
require_once( 'class.baseobject.php' );
class ContactForm extends BaseObject
{
    public $_table = 'mt_contactform';
    public $_prefix = 'contactform_';
    private $_data = NULL;
    protected $_has_meta = TRUE;
}
ADODB_Active_Record::ClassHasMany( 'ContactForm', 'mt_contactform_meta', 'contactform_meta_contactform_id' );
?>