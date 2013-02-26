<?php
require_once( 'class.baseobject.php' );
class Feedback extends BaseObject
{
    public $_table = 'mt_feedback';
    public $_prefix = 'feedback_';
    private $_data = NULL;
}
?>