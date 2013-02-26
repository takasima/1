package CustomGroup::Util;
use strict;
use base qw( Exporter );

our @EXPORT_OK = qw( is_user_can is_cms current_ts include_exclude_blogs permitted_blog_ids );

use MT::Util qw( offset_time_list );

sub permitted_blog_ids {
    my ( $app, $permissions ) = @_;
    my @permissions = ref $permissions eq 'ARRAY' ? @$permissions : $permissions;
    my @blog_ids;
    my $blog = $app->blog;
    if ( $blog ) {
        push( @blog_ids, $blog->id );
        unless ( $blog->is_blog ) {
            push( @blog_ids, map { $_->id } @{ $blog->blogs } );
        }
    }
    my $user = $app->user;
    if ( $user->is_superuser ) {
        unless ( @blog_ids ) {
            my @all_blogs = MT::Blog->load( { class => '*' } );
            @blog_ids = map { $_->id } @all_blogs;
        }
        if ( @blog_ids ) {
            @blog_ids = uniq_array( \@blog_ids );
            return wantarray ? @blog_ids : \@blog_ids;
        }
    }
    require MT::Permission;
    my $iter = MT->model( 'permission' )->load_iter( { author_id => $user->id,
                                                       ( @blog_ids ? ( blog_id => \@blog_ids ) : ( blog_id => { not => 0 } ) ),
                                                     }
                                                   );
    my @permitted_blog_ids;
    while ( my $p = $iter->() ) {
        next unless $p->blog;
        for my $permission ( @permissions ) {
            if ( is_user_can( $p->blog, $user, $permission ) ) {
                push( @permitted_blog_ids, $p->blog->id );
                last;
            }
        }
    }
    if ( @permitted_blog_ids ) {
        @permitted_blog_ids = uniq_array( \@permitted_blog_ids );
        return wantarray ? @permitted_blog_ids : \@permitted_blog_ids;
    }
    return;
}

sub include_exclude_blogs {
    my ( $ctx, $args ) = @_;
    unless ( $args->{ blog_id } || $args->{ include_blogs } || $args->{ exclude_blogs } ) {
        $args->{ include_blogs } = $ctx->stash( 'include_blogs' );
        $args->{ exclude_blogs } = $ctx->stash( 'exclude_blogs' );
        $args->{ blog_ids } = $ctx->stash( 'blog_ids' );
    }
    my ( %blog_terms, %blog_args );
    $ctx->set_blog_load_context( $args, \%blog_terms, \%blog_args ) or return $ctx->error($ctx->errstr);
    my @blog_ids = $blog_terms{ blog_id };
    return undef if ! @blog_ids;
    if ( wantarray ) {
        return @blog_ids;
    }
    return \@blog_ids;
}

sub is_user_can {
    my ( $blog, $user, $permission ) = @_;
    $permission = 'can_' . $permission;
    my $perm = $user->is_superuser;
    unless ( $perm ) {
        if ( $blog ) {
            my $admin = 'can_administer_blog';
            $perm = $user->permissions( $blog->id )->$admin ||
                    $user->permissions( $blog->id )->$permission;
        } else {
            $perm = $user->permissions()->$permission;
        }
    }
    return $perm;
}

sub is_cms {
    my $app = shift || MT->instance();
    return ( ref $app eq 'MT::App::CMS' ) ? 1 : 0;
}

sub current_ts {
    my $blog = shift;
    my @tl = offset_time_list( time, $blog );
    my $ts = sprintf '%04d%02d%02d%02d%02d%02d', $tl[5]+1900, $tl[4]+1, @tl[3, 2, 1, 0];
    return $ts;
}

1;
