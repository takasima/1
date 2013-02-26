package CustomObject::OverRide;
use strict;

sub init {
    # Only for override.
    # Do nothing.
}

use lib qw( addons/Commercial.pack/lib );
no warnings 'redefine';
require CustomFields::Template::ContextHandlers;
*CustomFields::Template::ContextHandlers::find_field_by_tag = sub  {
    my ( $ctx, $tag ) = @_;

    $tag ||= $ctx->stash('tag')
        or return;

    my $field = $ctx->stash('field');
    return $field
        if $field && lc $field->tag eq $tag;

    my $blog_id = $ctx->stash('blog_id');
    unless ($blog_id) {
        my $blog = $ctx->stash('blog');
        $blog_id = $blog->id if $blog;
    }
# PATCH
#    my $blog_ids = $blog_id ? [ $blog_id, 0 ] : 0;
    my $blog_ids;
    if ( MT->config->CustomObjectFieldScope eq 'website' && $field && $field->type eq 'customobject' ) {
        my $blog = $ctx->stash('blog');
        if ( $blog->is_blog ) {
            $blog_ids = $blog_id ? [ $blog_id, 0, $blog->website->id ] : 0;
        } else {
            $blog_ids = $blog_id ? [ $blog_id, 0 ] : 0;
        }
    } else {
        $blog_ids = $blog_id ? [ $blog_id, 0 ] : 0;
    }
# /PATCH

    return MT->model('field')->load(
        {   blog_id => $blog_ids,
            tag     => lc $tag,
        }
    );
};

1;