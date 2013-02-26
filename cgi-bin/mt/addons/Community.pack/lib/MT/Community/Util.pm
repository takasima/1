# Movable Type (r) (C) 2007-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package MT::Community::Util;

use strict;

sub comment_post_insert {
    my ( $cb, $comment ) = @_;

    my $blog = $comment->blog;

    # this behavior is only for forum-type blogs
    return unless ( $blog->template_set || '' ) =~ m/forum/;

    my $entry = $comment->entry or return;

    # "Touch" the entry by updated the modified on timestamp. This allows
    # for the forum index to be listed properly in order by modification
    # date. Replies to forum topics 'bump' the topic back up.
    $entry->modified_on( $comment->created_on );
    $entry->save;

    1;
}

sub sanitize_filter {
    my $str = shift;
    return '' unless defined $str;
    require MT::Sanitize;
    my $app = MT->instance;
    my $spec;
    if ( $app->isa('MT::App') ) {
        if ( my $blog = $app->blog ) {
            $spec = $blog->sanitize_spec;
        }
    }
    return MT::Sanitize->sanitize( $str,
        $spec || $app->config->GlobalSanitizeSpec );
}

# Remove MT::Community::Blog object from cache when
# underlying MT::Blog object has been updated or deleted.
sub uncache_blog {
    my ( $eh, $mt_blog ) = @_;
    my $app  = MT->instance;
    my $blog = $app->model('blog.community')->load( $mt_blog->id );
    $blog->uncache_object if $blog;
}

1;
