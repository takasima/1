package TemplateSelector::Tags;
use strict;

sub _hdlr_entry_template_name {
    my ( $ctx, $args, $cond ) = @_;
    my $blog = $ctx->stash( 'blog' )
        or return $ctx->_no_blog_error( $ctx->stash( 'tag' ) );
    my $entry = $ctx->stash( 'entry' )
        or return $ctx->_no_entry_error( $ctx->stach( 'tag' ) );
    if ( my $template_id = $entry->template_module_id ) {
        my $template = MT->model( 'template' )->load( { id => $template_id } );
        return $template ? $template->name : '';
    }
    return '';
}

sub _hdlr_template_selector {
    my ( $ctx, $args, $cond ) = @_;
    my $blog = $ctx->stash( 'blog' )
        or return $ctx->_no_blog_error( $ctx->stash( 'tag' ) );
    my $entry = $ctx->stash( 'entry' )
        or return $ctx->_no_entry_error( $ctx->stash( 'tag' ) );
    my $name = $args->{ name };
    if ( my $template_id = $entry->template_module_id ) {
        my $template = MT->model( 'template' )->load( { id => $template_id } );
        if ( $template && $name ) {
            if ( $name eq $template->name ) {
                return 1;
            }
        }
    } elsif ( ! $name ) {
        return 1;
    }
    return 0;
}

sub _hdlr_template_selector_block { # This is pointer for insert template tag at post_save_template.
    my ( $ctx, $args, $cond ) = @_;
    return 1;
}

1;