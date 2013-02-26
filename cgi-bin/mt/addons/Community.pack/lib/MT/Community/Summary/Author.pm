# Movable Type (r) (C) 2006-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$
# Summary Object Framework functions for MT::Author

package MT::Community::Summary::Author;

use strict;
use warnings;

sub summarize_following_count {
    my $author = shift;
    my ($terms) = @_;

    require MT::Community::Friending;
    return MT->model('objectscore')->count(
        {   author_id => $author->id,
            object_ds => 'author',
            score     => [ MT::Community::Friending::CONTACT(), undef ],
            namespace => MT::Community::Friending::FRIENDING()
        },
        { range_incl => { score => 1 }, }
    );
}

sub summarize_followed_count {
    my $author = shift;
    my ($terms) = @_;

    require MT::Community::Friending;
    return MT->model('objectscore')->count(
        {   object_id => $author->id,
            object_ds => 'author',
            score     => [ MT::Community::Friending::CONTACT(), undef ],
            namespace => MT::Community::Friending::FRIENDING()
        },
        { range_incl => { score => 1 }, }
    );
}

sub _hdlr_following_count {
    my ( $ctx, $args, $cond ) = @_;
    my $author = $ctx->stash('author')
        or return $ctx->_no_author_error('MTAuthorFollowingCount');

    return $ctx->count_format( $author->summarize('following_count'), $args );
}

sub _hdlr_followers_count {
    my ( $ctx, $args, $cond ) = @_;
    my $author = $ctx->stash('author')
        or return $ctx->_no_author_error('MTAuthorFollowersCount');

    return $ctx->count_format( $author->summarize('followed_count'), $args );
}

sub expire_following_count {
    my ( $parent_obj, $obj, $terms, $action, $orig ) = @_;

# action: save/remove
# parent_obj => author, obj => object whose save triggered it, i.e. the objectscore
    require MT::Community::Friending;
    if ( $obj->namespace ne MT::Community::Friending->FRIENDING() ) {
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

{
    sub expire_followed_count;
    no warnings;
    *expire_followed_count = \&expire_following_count;
}

sub expire_entry_recommend_count {
    my ( $parent_obj, $obj, $terms, $action, $orig ) = @_;

# action: save/remove - but we're only ratcheting upwards
# parent_obj => author, obj => object whose save triggered it, i.e. the objectscore
    require MT::App::Community;
    if ( $obj->namespace ne MT::App::Community->NAMESPACE() ) {
        return;
    }
    if ( $obj->object_ds ne q{entry} ) {
        return;
    }
    if ( $action eq 'save' ) {
        $parent_obj->expire_summary($terms);
    }
    elsif ( $action eq 'remove' ) {
        $parent_obj->expire_summary($terms);
    }
    else {
        die "Incorrect action type '$action'; expected save/remove\n";
    }
}

sub summarize_entry_recommend_count {
    my $author = shift;
    my ($terms) = @_;
    require MT::App::Community;
    return MT->model('objectscore')->count(
        {   author_id => $author->id,
            object_ds => 'entry',
            score     => \' > 0',
            namespace => MT::App::Community->NAMESPACE()
        },
    );
}

1;
