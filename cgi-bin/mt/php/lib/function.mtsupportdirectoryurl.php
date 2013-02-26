<?php
# Movable Type (r) (C) 2001-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

function smarty_function_mtsupportdirectoryurl($args, &$ctx) {
    require_once "MTUtil.php";
    $url = support_directory_url();
    return $url;
}
?>
