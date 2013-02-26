package AdditionalFields::Tags;

use strict;

sub _hdlr_related_entries {
    my ( $ctx, $args, $cond ) = @_;
    my $ids = $args->{ ids };
    return '' unless $ids;
    my $class = $args->{ class };
    my @id = split( /,/, $ids );
    my $sort_by = $args->{ sort_by };
    my $sort_order = $args->{ sort_order };
    my $lastn = $args->{ lastn };
    my $offset = $args->{ offset };
    my $params;
    if ( $sort_by ) {
        $sort_order = 'ascend' if (! $sort_order );
        $params->{ sort } = $sort_by;
        $params->{ direction } = $sort_order;
    }
    if ( $lastn ) {
        $offset = 0 if (! $offset );
        $params->{ offset } = $offset;
        $params->{ limit } = $lastn;
    }
    my @entries = MT->model( $class )->load( { id => \@id, status => 2 }, $params );
    my %loaded_entries;
    if (! $sort_by ) {
        if ( $sort_order eq 'descend' ) {
            @id = reverse( @id );
        }
        for my $entry ( @entries ) {
            $loaded_entries{ $entry->id } = $entry;
        }
        @entries = ();
        for my $entry_id ( @id ) {
            if ( my $entry = $loaded_entries{ $entry_id } ) {
                push ( @entries, $entry );
            }
        }
    }
    my $tokens = $ctx->stash( 'tokens' );
    my $builder = $ctx->stash( 'builder' );
    my $res = '';
    my $i = 0;
    my $odd = 1; my $even = 0;
    for my $entry ( @entries ) {
        local $ctx->{ __stash }->{ vars }->{ __first__ } = ( $i == 0 );
        local $ctx->{ __stash }{ entry } = $entry;
        local $ctx->{ __stash }{ blog } = $entry->blog;
        local $ctx->{ __stash }{ blog_id } = $entry->blog_id;
        local $ctx->{ __stash }->{ vars }->{ __counter__ } = $i + 1;
        local $ctx->{ __stash }->{ vars }->{ __odd__ } = $odd;
        local $ctx->{ __stash }->{ vars }->{ __even__ } = $even;
        local $ctx->{ __stash }->{ vars }->{ __last__ } = ( !defined( $entries[ $i + 1 ] ) );
        my $out = $builder->build( $ctx, $tokens, $cond );
        if ( !defined( $out ) ) { return $ctx->error( $builder->errstr ) };
        $res .= $out;
        if ( $odd == 1 ) { $odd = 0 } else { $odd = 1 };
        if ( $even == 1 ) { $even = 0 } else { $even = 1 };
        $i++;
    }
    return $res;
}

sub _hdlr_related_entry {
    my ( $ctx, $args, $cond ) = @_;
    my $id = $args->{ id };
    return '' unless $id;
    my $class = $args->{ class };
    my $entry = MT->model( $class )->load( { id => $id, status => 2 } );
    return '' unless $entry;
    local $ctx->{ __stash }{ entry } = $entry;
    local $ctx->{ __stash }{ blog } = $entry->blog;
    local $ctx->{ __stash }{ blog_id } = $entry->blog_id;
    my $tokens  = $ctx->stash( 'tokens' );
    my $builder = $ctx->stash( 'builder' );
    my $content = $builder->build( $ctx, $tokens, $cond );
    return $content;
}

sub _hdlr_entry_field_scope {
    my ( $ctx, $args, $cond ) = @_;
    return MT->config( 'EntryCustomFieldScope' ) || 'blog';
}

sub _hdlr_page_field_scope {
    my ( $ctx, $args, $cond ) = @_;
    return MT->config( 'PageCustomFieldScope' ) || 'blog';
}

sub _hdlr_set_context {
    my ( $ctx, $args, $cond ) = @_;
    my $stash = $args->{ stash };
    my $value = $args->{ value };
    $ctx->stash( $stash, $value );
    $ctx->stash( 'builder' )->build( $ctx, $ctx->stash( 'tokens' ), $cond );
}

sub _hdlr_if_not_sent {
    my ( $ctx, $args, $cond ) = @_;
    require MT::Request;
    my $r = MT::Request->instance;
    my $key = $args->{ key };
    if ( $r->cache( $key ) ) {
        return 0;
    } else {
        $r->cache( $key, 1 );
        return 1;
    }
}

1;