package EntryUnpublish::Tags;
#use strict;

use MT::Util qw( offset_time_list );

sub _hdlr_if_entry_unpublished {
    my ( $ctx, $args, $cond ) = @_;
    my $entry = $ctx->stash( 'entry' ) or return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
    my $blog = $ctx->stash( 'blog' ) or return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
    if ( $args->{ checked } ) {
        return 0 unless $entry->unpublished;
    }
    if ( my $unpublished_on = $entry->unpublished_on ) {
        my @tl = &offset_time_list( time, $blog );
        my $ts = sprintf '%04d%02d%02d%02d%02d%02d', $tl[ 5 ] + 1900, $tl[ 4 ] + 1, @tl[ 3, 2, 1, 0 ];
        if ( $unpublished_on <= $ts ) {
            return 1;
        }
    }
    return 0;
}

sub _hdlr_entry_unpublished_on {
    my ( $ctx, $args, $cond ) = @_;
    my $entry = $ctx->stash( 'entry' ) or return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
    my $blog = $ctx->stash( 'blog' ) or return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
    if ( my $unpublished_on = $entry->unpublished_on ) {
        $args->{ ts } = $unpublished_on;
    }
    return $ctx->build_date( $args );
}

1;
