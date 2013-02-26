<?php
# Movable Type (r) (C) 2001-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

function smarty_function_mtcommenternamethunk($args, &$ctx) {
    return $ctx->error(
        $ctx->mt->translate("This '[_1]' tag has been deprecated. Please use '[_2]' instead.",
            array( 'MTCommenterNameThunk', 'MTUserSessionState' )
    ));
}
?>
