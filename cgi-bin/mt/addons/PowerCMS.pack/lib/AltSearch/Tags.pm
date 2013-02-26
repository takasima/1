package AltSearch::Tags;

use strict;
use PowerCMS::Util qw( get_powercms_config );

sub _fltr_absolute {
    my ( $text, $arg, $ctx ) = @_;
    if ( $text =~ /(.*)\/$/ ) {
        $text = $1;
    }
    if ( $text =~ /(http.{1,}\/\/.{1,}?)(\/.{1,}$)/ ) {
        $text = $2 . '/';
    } else {
        $text = '/';
    }
    return $text;
}

sub _hdlr_alt_searchpath {
    my ( $ctx, $args, $cond ) = @_;
    if ( my $blog = $ctx->stash( 'blog' ) ) {
        return get_powercms_config( 'powercms', 'altsearch_path', $blog );
    }
    return '';
}

sub _hdlr_alt_searchfeedpath {
    my ( $ctx, $args, $cond ) = @_;
    if ( my $blog = $ctx->stash( 'blog' ) ) {
        return get_powercms_config( 'powercms', 'altsearch_feedpath', $blog );
    }
    return '';
}

sub _hdlr_alt_searchlimit {
    my ( $ctx, $args, $cond ) = @_;
    if ( my $blog = $ctx->stash( 'blog' ) ) {
        return get_powercms_config( 'powercms', 'altsearch_default_limit', $blog );
    }
    return '';
}

sub _hdlr_as {
    return '';
}

1;