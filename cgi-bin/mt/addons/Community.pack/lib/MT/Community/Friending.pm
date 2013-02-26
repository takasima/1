# Movable Type (r) (C) 2007-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package MT::Community::Friending;

use strict;
use MT::Author qw( :constants );
use MT::Entry qw( :constants );
use CustomFields::Util qw( field_loop );

use constant FRIENDING => 'community_friending';

# Terms taken from XFN definition of friends
use constant CONTACT      => 1;
use constant ACQUAINTANCE => 2;
use constant FRIEND       => 3;

## Utility methods of friending feature
sub follow {
    my ( $user, $target ) = @_;

    return unless $user;

    if ( !ref($target) && ( $target =~ /^\d+$/ ) ) {

        # target may be id
        $target = MT->model('author')->load($target);
    }
    return unless $target;
    return unless $target->status == MT::Author::ACTIVE();

    my $app = MT->instance;

    $app->run_callbacks( 'api_pre_save.follow', $app, $user, $target );

    my $objectscore;
    $objectscore = MT->model('objectscore')->load(
        {   author_id => $user->id,
            object_id => $target->id,
            object_ds => q{author},
            namespace => FRIENDING()
        }
    );
    unless ($objectscore) {
        $objectscore = MT->model('objectscore')->new;
        $objectscore->author_id( $user->id );
        $objectscore->object_id( $target->id );
        $objectscore->object_ds(q{author});
        $objectscore->namespace( FRIENDING() );
    }
    $objectscore or return;
    $objectscore->score( CONTACT() );
    $objectscore->save();
    $app->run_callbacks( 'api_post_save.follow', $app, $user, $target );

    1;
}

sub leave {
    my ( $user, $target ) = @_;

    return unless $user;

    if ( !ref($target) && ( $target =~ /^\d+$/ ) ) {

        # target may be id
        $target = MT->model('author')->load($target);
    }
    return unless $target;
    return unless $target->status == MT::Author::ACTIVE();

    my $app = MT->instance;

    $app->run_callbacks( 'api_pre_remove.follow', $app, $user, $target );

    my $terms = {
        author_id => $user->id,
        object_id => $target->id,
        object_ds => 'author',
        namespace => FRIENDING()
    };
    my $result;
    if ( my $objectscore = MT->model('objectscore')->load($terms) ) {
        $result = $objectscore->remove;
        $app->run_callbacks( 'api_post_remove.follow', $app, $user, $target );
    }
    $result;
}

sub followers {
    my ( $user, $terms, $args ) = @_;

    $terms ||= {};
    $args  ||= {};
    $terms->{status} = MT::Author::ACTIVE()
        unless exists $terms->{status};
    $args->{limit} = 20 unless exists $args->{limit};
    unless ( exists $args->{'sort'} ) {
        $args->{'sort'}      = 'created_on';
        $args->{'direction'} = 'descend';
    }
    return MT->model('author')->load(
        $terms,
        {   'join' => MT->model('objectscore')->join_on(
                'author_id',
                {   object_id => $user->id,
                    object_ds => 'author',
                    score     => [ CONTACT(), undef ],
                    namespace => FRIENDING()
                },
                {   range_incl => { score => 1 },
                    %$args
                }
            )
        }
    );
}

sub followings {
    my ( $user, $terms, $args ) = @_;

    $terms ||= {};
    $args  ||= {};
    $terms->{status} = MT::Author::ACTIVE()
        unless exists $terms->{status};
    $args->{limit} = 20 unless exists $args->{limit};
    unless ( exists $args->{'sort'} ) {
        $args->{'sort'}      = 'created_on';
        $args->{'direction'} = 'descend';
    }
    return MT->model('author')->load(
        $terms,
        {   'join' => MT->model('objectscore')->join_on(
                'object_id',
                {   author_id => $user->id,
                    object_ds => 'author',
                    score     => [ CONTACT(), undef ],
                    namespace => FRIENDING()
                },
                {   range_incl => { score => 1 },
                    %$args
                }
            )
        }
    );
}

sub followers_iter {
    my ( $user, $terms, $args ) = @_;

    $terms ||= {};
    $args  ||= {};
    $terms->{status} = MT::Author::ACTIVE()
        unless exists $terms->{status};
    unless ( exists $args->{'sort'} ) {
        $args->{'sort'}      = 'created_on';
        $args->{'direction'} = 'descend';
    }
    my $iter = MT->model('author')->load_iter(
        $terms,
        {   'join' => MT->model('objectscore')->join_on(
                'author_id',
                {   object_id => $user->id,
                    object_ds => 'author',
                    score     => [ CONTACT(), undef ],
                    namespace => FRIENDING()
                },
                {   range_incl => { score => 1 },
                    %$args
                }
            )
        }
    );
    $iter;
}

sub followings_iter {
    my ( $user, $terms, $args ) = @_;

    $terms ||= {};
    $args  ||= {};
    $terms->{status} = MT::Author::ACTIVE()
        unless exists $terms->{status};
    unless ( exists $args->{'sort'} ) {
        $args->{'sort'}      = 'created_on';
        $args->{'direction'} = 'descend';
    }
    my $iter = MT->model('author')->load_iter(
        $terms,
        {   'join' => MT->model('objectscore')->join_on(
                'object_id',
                {   author_id => $user->id,
                    object_ds => 'author',
                    score     => [ CONTACT(), undef ],
                    namespace => FRIENDING()
                },
                {   range_incl => { score => 1 },
                    %$args
                }
            )
        }
    );
    $iter;
}

sub entries_by_followings {
    my ( $user, $terms, $args ) = @_;

    $terms ||= {};
    $args  ||= {};
    $terms->{status} = MT::Entry::RELEASE()
        unless exists $terms->{status};
    $args->{limit} = 20
        unless exists $args->{limit};
    unless ( exists $args->{'sort'} ) {
        $args->{'sort'}      = 'authored_on';
        $args->{'direction'} = 'descend';
    }

    my @entries = MT->model('entry')->load(
        $terms,
        {   'join' => MT->model('objectscore')->join_on(
                undef,
                {   object_id => \'= entry_author_id',
                    author_id => $user->id,
                    object_ds => 'author',
                    score     => [ CONTACT(), undef ],
                    namespace => FRIENDING()
                },
                { range_incl => { score => 1 } }
            ),
            %$args
        }
    );
    \@entries;
}

sub comments_by_followings {
    my ( $user, $terms, $args ) = @_;

    $terms ||= {};
    $args  ||= {};
    $terms->{visible} = 1
        unless exists $terms->{visible};
    $args->{limit} = 20
        unless exists $args->{limit};
    unless ( exists $args->{'sort'} ) {
        $args->{'sort'}      = 'created_on';
        $args->{'direction'} = 'descend';
    }

    my @comments = MT->model('comment')->load(
        $terms,
        {   'join' => MT->model('objectscore')->join_on(
                undef,
                {   object_id => \'= comment_commenter_id',
                    author_id => $user->id,
                    object_ds => 'author',
                    score     => [ CONTACT(), undef ],
                    namespace => FRIENDING()
                },
                { range_incl => { score => 1 } }
            ),
            %$args
        }
    );
    \@comments;
}

sub favorites_by_followings {
    my ( $user, $terms, $args ) = @_;

    require MT::App::Community;
    my $entry_class = MT->model('entry');
    my @entries     = $entry_class->load(
        $terms,
        {   'join' => MT->model('objectscore')->join_on(
                undef,
                {   object_id => \'= entry_id',
                    object_ds => $entry_class->datasource,
                    namespace => MT::App::Community::NAMESPACE(),
                },
                {   'alias' => 'favorites',
                    'join'  => MT->model('objectscore')->join_on(
                        undef,
                        {   author_id => \'favorites.objectscore_author_id',
                            author_id => $user->id,
                            object_ds => 'author',
                            score     => [ CONTACT(), undef ],
                            namespace => FRIENDING()
                        },
                        {   alias      => 'friends',
                            range_incl => { score => 1 }
                        }
                    ),
                }
            ),
            %$args
        }
    );
    \@entries;
}

sub is_following {
    my ( $user, $target_id ) = @_;

    return 0 unless $user;
    return 0 unless $target_id;

    my $f = MT->model('objectscore')->load(
        {   author_id => $user->id,
            object_id => $target_id,
            object_ds => 'author',
            score     => [ CONTACT(), undef ],
            namespace => FRIENDING()
        },
        { range_incl => { score => 1 } }
    ) or return 0;
    return $f->score;
}

sub is_followed {
    my ( $user, $target_id ) = @_;

    return 0 unless $user;
    return 0 unless $target_id;

    my $f = MT->model('objectscore')->load(
        {   author_id => $target_id,
            object_id => $user->id,
            object_ds => 'author',
            score     => [ CONTACT(), undef ],
            namespace => FRIENDING()
        },
        { range_incl => { score => 1 } }
    ) or return 0;
    return $f->score;
}

1;
__END__
