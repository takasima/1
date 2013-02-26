package CustomObject::Object;
use strict;

sub blog_max_revisions {
    my $max_revisions_column = max_revisions_column();
    return { $max_revisions_column => 'integer meta' };
}

sub max_revisions_column {
    if ( is_oracle() ) {
        return 'max_revisions_co';
    } else {
        return 'max_revisions_customobject';
    }
}

sub is_oracle {
    return lc( MT->config( 'ObjectDriver' ) ) =~ /oracle/ ? 1 : 0;
}

1;