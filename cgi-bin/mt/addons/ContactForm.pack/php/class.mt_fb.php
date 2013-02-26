<?php
require_once( 'class.baseobject.php' );
class Feedback extends BaseObject
{
    public $_table = 'mt_fb';
    public $_prefix = 'fb_';
    private $_data = NULL;
    protected $_has_meta = TRUE;
}
?>