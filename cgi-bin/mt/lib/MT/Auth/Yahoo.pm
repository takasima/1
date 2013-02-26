# Movable Type (r) (C) 2001-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package MT::Auth::Yahoo;

use strict;
use base qw( MT::Auth::OpenID );

sub get_nickname {
    my $class = shift;
    my ($vident) = @_;

    my $url = $vident->url;
    if ( $url =~ m(^https?://me.yahoo.com/([^/]+)/?$) ) {
        return $1;
    }
    elsif ( $url =~ m(^http://www.flickr.com/photos/(.+)$) ) {
        return $1;
    }

    return $class->SUPER::get_nickname(@_);
}

1;
