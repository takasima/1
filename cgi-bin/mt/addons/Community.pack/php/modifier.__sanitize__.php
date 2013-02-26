<?php
# Movable Type (r) (C) 2001-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

function smarty_modifier___sanitize__($text) {
    require_once("modifier.sanitize.php");
    return smarty_modifier_sanitize($text, '1');
}
