<?php
require_once( 'class.baseobject.php' );
class Campaign extends BaseObject
{
    public $_table = 'mt_campaign';
    protected $_prefix = 'campaign_';
    private $_data = NULL;
    protected $_has_meta = TRUE;
}
ADODB_Active_Record::ClassHasMany( 'Campaign', 'mt_campaign_meta', 'campaign_meta_campaign_id' );
?>