# Movable Type (r) (C) 2006-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$
# Summary Object Framework functions for MT::Entry

package MT::Community::Summary::Entry;

use strict;
use warnings;

sub expire_favorited_count {
    my ( $parent_obj, $obj, $terms, $action, $orig ) = @_;

# action: save/remove - but we're only ratcheting upwards
# parent_obj => entry, obj => object whose save triggered it, i.e. the objectscore
    require MT::App::Community;
    if ( $obj->namespace ne MT::App::Community->NAMESPACE() ) {
        return;
    }
    my $orig_score = 0;
    if ( defined $orig->{__orig_value}->{score} ) {
        $orig_score = $orig->{__orig_value}->{score};
    }
    my $count = $parent_obj->summary($terms);
    if ( !defined $count || $count < 1 && $action eq 'remove' ) {
        $parent_obj->expire_summary($terms);
    }
    elsif ( $action eq 'save' ) {
        if ( $obj->score > 0 and $orig_score < 1 ) {
            $parent_obj->set_summary( $terms, $count + 1 );
        }
        if ( $orig_score > 0 and $obj->score < 1 ) {
            $parent_obj->set_summary( $terms, $count - 1 );
        }
    }
    elsif ( $action eq 'remove' ) {
        $parent_obj->set_summary( $terms, $count - 1 );
    }
    else {
        die "Incorrect action type '$action'; expected save/remove\n";
    }
}

sub summarize_favorited_count {
    my $entry = shift;
    my ($terms) = @_;
    require MT::App::Community;
    return MT->model('objectscore')->count(
        {   object_id => $entry->id,
            object_ds => 'entry',
            score     => \' > 0',                          #'
            namespace => MT::App::Community->NAMESPACE()
        },
    );
}

sub _hdlr_entry_score {
    my ( $ctx, $args ) = @_;
    return '' unless $args->{namespace};
    ( my $entry = $ctx->stash('entry') ) || return '';
    require MT::App::Community;
    return $ctx->super_handler($args)
        unless $args->{namespace} eq MT::App::Community->NAMESPACE();
    my $summarized_count = $entry->summarize('favorited_count');
    if ( !$summarized_count && exists( $args->{default} ) ) {
        return $args->{default};
    }
    return $ctx->count_format( $summarized_count, $args );
}

1;
