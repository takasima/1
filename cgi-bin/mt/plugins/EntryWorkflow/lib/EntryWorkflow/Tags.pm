package EntryWorkflow::Tags;
use strict;

use lib qw( addons/PowerCMS.pack/lib );
use PowerCMS::Util qw( current_user );
use EntryWorkflow::Util;

my $plugin = MT->component( 'EntryWorkflow' );

sub _hdlr_author_post_limit_in_blog {
    my ( $ctx, $args, $cond ) = @_;
    my $blog_id = $args->{ blog_id };
    my $app = MT->instance();
    my $user = current_user( $app );
    return 0 if $user->is_superuser;
    if (! $blog_id ) {
        my $blog = $ctx->stash( 'blog' );
        $blog = $app->blog unless $blog;
        if (! $blog ) {
            return 0;
        }
        $blog_id = $blog->id;
    }
    return EntryWorkflow::Util::author_post_limit_in_blog( $blog_id );
}

sub _hdlr_can_create_in_category {
    my ( $ctx, $args, $cond ) = @_;
    my $category_id = $args->{ category_id };
    return EntryWorkflow::Util::can_create_in_category( $category_id );
}

sub _hdlr_if_entry_can_editable {
    my ( $ctx, $args, $cond ) = @_;
#     my $entry = $ctx->stash( 'entry' )
#         or return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
    my $entry = $ctx->stash( 'entry' );
    unless ( $entry ) {
        if ( my $entry_id = $args->{ entry_id } ) {
            $entry = MT->model( 'entry' )->load( { id => $entry_id }, { no_class => 1 } );
        }
    }
    unless ( $entry ) {
        return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
    }
    my $app = MT->instance();
    my $user = current_user( $app );
    return EntryWorkflow::Util::can_edit_entry( $entry, $user );
}

sub _hdlr_entry_creator_context {
    my ( $ctx, $args, $cond ) = @_;
    my $entry = $ctx->stash( 'entry' )
        or return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
    my $author;
    if ( my $creator_id = $entry->creator_id ) {
        $author = MT->model( 'author' )->load( { id => $creator_id } );
        unless ( defined $author ) {
            $author = $entry->author;
        }
    } else {
        $author = $entry->author;
    }
    if ( $author ) {
        local $ctx->{ __stash }{ author } = $author;
        local $ctx->{ __stash }{ author_id } = $author->id;
        return $ctx->stash( 'builder' )->build( $ctx, $ctx->stash( 'tokens' ), $cond );
    }
    return '';
}

sub _hdlr_entry_creator_displayname {
    my ( $ctx, $args, $cond ) = @_;
    my $entry = $ctx->stash( 'entry' )
        or return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
    my $author;
    if ( my $creator_id = $entry->creator_id ) {
        $author = MT->model( 'author' )->load( { id => $creator_id } );
        unless ( defined $author ) {
            $author = $entry->author;
        }
    } else {
        $author = $entry->author;
    }
    return $author ? $author->nickname : $plugin->translate( 'Unknown' );
}

sub _hdlr_entry_creator_id {
    my ( $ctx, $args, $cond ) = @_;
    my $entry = $ctx->stash( 'entry' )
        or return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
    my $author;
    if ( my $creator_id = $entry->creator_id ) {
        $author = MT->model( 'author' )->load( { id => $creator_id } );
        unless ( defined $author ) {
            $author = $entry->author;
        }
    } else {
        $author = $entry->author;
    }
    return $author ? $author->id : '';
}

1;