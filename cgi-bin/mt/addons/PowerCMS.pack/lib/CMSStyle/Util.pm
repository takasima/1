package CMSStyle::Util;
use strict;

use PowerCMS::Util qw( current_user is_user_can );

sub has_permission {
    my ( $class, $blog ) = @_;
    my $app = MT->instance();
    my $user = current_user( $app );
    return 0 unless defined $user;
    return 1 if $user->is_superuser;
    return 1 if $user->can_create_blog;
    my $perm = $class eq 'entry' ? 'create_post' : 'manage_pages';
    if ( defined $blog ) {
        return is_user_can( $blog, $user, $perm );
    } else {
        require MT::Request;
        my $r = MT::Request->instance;
        my $self = $r->cache( 'can_manage:' . $class );
        return 1 if $self;
        require MT::Permission;
        my @blogs = map { $_->blog_id }
        grep { $_->$perm }
        MT::Permission->load( { author_id => $user->id } );
        if ( @blogs ) {
            $r->cache( 'can_manage:' . $class, 1 );
            return 1;
        }
    }
    return 0;
}

1;