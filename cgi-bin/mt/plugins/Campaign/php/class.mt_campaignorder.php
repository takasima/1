<?php
require_once( "class.baseobject.php" );
class CampaignOrder extends BaseObject
{
    public $_table = 'mt_campaignorder';
    protected $_prefix = "campaignorder_";
    private $_data = null;
}
?>