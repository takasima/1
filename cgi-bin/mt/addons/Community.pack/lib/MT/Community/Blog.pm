# Movable Type (r) (C) 2007-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package MT::Community::Blog;

use strict;
use base qw( MT::Blog );

__PACKAGE__->install_properties(
    {   column_defs => {
            'allow_anon_recommend' => 'integer meta',
            'upload_path'          => 'string meta',
            'run_junk_filter'      => 'integer meta',
        },
    }
);

# Add MT::Community::Blog meta fields to MT::Blog objects
# (necessary to prevent MT errors when cloning blogs, posting comments)
sub load_blog_meta_fields {
    my $ppkg = MT->model('blog');
    $ppkg->install_meta(
        {   column_defs => {
                'allow_anon_recommend' => 'integer meta',
                'upload_path'          => 'string meta',
                'run_junk_filter'      => 'integer meta',
            }
        }
    );
}

1;
