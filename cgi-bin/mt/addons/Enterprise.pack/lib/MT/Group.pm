# Movable Type (r) (C) 2006-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package MT::Group;

use strict;
use base qw( MT::Object );

__PACKAGE__->install_properties(
    {   column_defs => {
            'id'           => 'integer not null auto_increment',
            'name'         => 'string(255) not null',
            'display_name' => 'string(255)',
            'description'  => 'text',
            'status'       => 'integer',
            'external_id'  => 'string(255)',
        },
        defaults => { status => 1, },
        indexes  => {
            created_on  => 1,
            name        => 1,
            status      => 1,
            external_id => 1,
        },
        child_classes => ['MT::Association'],
        datasource    => 'group',
        primary_key   => 'id',
        audit         => 1,
    }
);

sub class_label {
    return MT->component('enterprise')->translate('Group');
}

sub class_label_plural {
    return MT->component('enterprise')->translate('Groups');
}

sub ACTIVE ()   {1}
sub INACTIVE () {2}

use Exporter;
*import = \&Exporter::import;
use vars qw(@EXPORT_OK %EXPORT_TAGS);
@EXPORT_OK = qw(ACTIVE INACTIVE);
%EXPORT_TAGS = ( constants => [qw(ACTIVE INACTIVE)] );

sub is_active { shift->status(@_) == ACTIVE; }

# TBD: use MT->instance->user_class ??

sub remove {
    my $group = shift;
    if ( ref $group ) {
        $group->remove_children( { key => 'group_id' } ) or return;
    }
    $group->SUPER::remove(@_);
}

sub user_iter {
    my $group = shift;
    my ( $terms, $args ) = @_;
    require MT::Association;
    require MT::Author;
    $args->{join} = MT::Association->join_on(
        'author_id',
        {   type     => MT::Association::USER_GROUP(),
            group_id => $group->id,
        }
    );
    MT::Author->load_iter( $terms, $args );
}

sub blog_iter {
    my $group = shift;
    my ( $terms, $args ) = @_;

    # restore once we allow group-system role associations
    #my $perm = $group->permissions;
    #if (!$perm->can_administer) {
    require MT::Association;
    $args->{join} = MT::Association->join_on(
        'blog_id',
        {   type     => MT::Association::GROUP_BLOG_ROLE(),
            group_id => $group->id,
        }
    );
    $args->{unique}   = 1;
    $args->{no_class} = 1;

    #}
    require MT::Blog;
    MT::Blog->load_iter( $terms, $args );
}

sub user_count {
    my $group = shift;
    my ( $terms, $args ) = @_;
    require MT::Association;
    require MT::Author;
    $args->{join} = MT::Association->join_on(
        'author_id',
        {   type     => MT::Association::USER_GROUP(),
            group_id => $group->id,
        }
    );
    MT::Author->count( $terms, $args );
}

sub role_iter {
    my $group = shift;
    my ( $terms, $args ) = @_;
    my $type;
    require MT::Association;
    my $blog_id = delete $terms->{blog_id};
    if ($blog_id) {
        $type = MT::Association::GROUP_BLOG_ROLE();
    }
    else {
        $type = MT::Association::GROUP_ROLE();
    }
    $args->{join} = MT::Association->join_on(
        'role_id',
        {   type     => $type,
            group_id => $group->id,
            $blog_id ? ( blog_id => $blog_id ) : (),
        }
    );
    require MT::Role;
    MT::Role->load_iter( $terms, $args );
}

sub add_user {
    my $group = shift;
    my ($user) = @_;
    $group->save unless $group->id;
    $user->save  unless $user->id;
    require MT::Association;
    MT::Association->link( $group, @_ );
}

sub remove_user {
    my $group = shift;
    require MT::Association;
    MT::Association->unlink( $group, @_ );
}

sub add_role {
    my $group = shift;
    my ( $role, $blog ) = @_;
    $group->save unless $group->id;
    $role->save  unless $role->id;
    $blog->save if $blog && !$blog->id;
    require MT::Association;
    MT::Association->link( $group, @_ );
    1;
}

sub remove_role {
    my $group = shift;
    require MT::Association;
    MT::Association->unlink( $group, @_ );
}

sub external_id {
    my $group = shift;
    if (@_) {
        return $group->SUPER::external_id( $group->unpack_external_id(@_) );
    }
    my $value = $group->SUPER::external_id;
    $value = $group->pack_external_id($value) if $value;
}

sub save {
    my $group         = shift;
    my $rebuild_perms = 0;
    if ( $group->id ) {
        $rebuild_perms = exists( $group->{changed_cols}->{status} ) ? 1 : 0;
    }
    my $res = $group->SUPER::save(@_)
        or return $group->error( $group->errstr() );
    if ($rebuild_perms) {
        require MT::Association;
        if (my $assoc_iter = MT::Association->load_iter(
                {   type => [
                        MT::Association::GROUP_ROLE(),
                        MT::Association::GROUP_BLOG_ROLE()
                    ],
                    group_id => $group->id,
                }
            )
            )
        {
            while ( my $assoc = $assoc_iter->() ) {
                $assoc->rebuild_permissions;
            }
        }
    }
    $res;
}

sub load {
    my $group = shift;
    my ( $terms, $args ) = @_;
    if ( ( ref($terms) eq 'HASH' ) && exists( $terms->{external_id} ) ) {
        $terms->{external_id}
            = $group->unpack_external_id( $terms->{external_id} );
    }
    $group->SUPER::load( $terms, $args );
}

sub load_iter {
    my $group = shift;
    my ( $terms, $args ) = @_;
    if ( ( ref($terms) eq 'HASH' ) && exists( $terms->{external_id} ) ) {
        $terms->{external_id}
            = $group->unpack_external_id( $terms->{external_id} );
    }
    $group->SUPER::load_iter( $terms, $args );
}

sub pack_external_id { return pack( 'H*', $_[1] ); }
sub unpack_external_id { return unpack( 'H*', $_[1] ); }

sub backup_terms_args {
    my $class = shift;
    my ($blog_ids) = @_;

    if ( defined($blog_ids) && scalar(@$blog_ids) ) {
        return {
            term => undef,
            args => {
                'join' => [
                    'MT::Association', 'group_id',
                    { blog_id => $blog_ids }, { unique => 1 }
                ]
            }
        };
    }
    else {
        return { term => undef, args => undef };
    }
}

1;
__END__

=head1 NAME

MT::Group

=head1 METHODS

=head2 is_active([$status])

Return true if the group is active.  As a side-effect, if an argument
is passed to this method, it will be used to set the status before
performing the check.

=head2 remove([\%terms])

Remove the group. Optionally, remove the group(s) by the given terms.

=head2 remove_role([\%terms])

Unlink the group-role association and optionally specify a set of
terms by which to restrict the operation.

=head2 remove_user([\%terms])

Unlink the group-user association and optionally specify a set of
terms by which to restrict the operation.

=head2 add_role($role, $blog)

Associate this group with the given role and webblog.

=head2 add_user($user)

Associate this group with the given user.

=head2 load([\%terms, \%args])

Return a list of groups given optional terms and args selection
arguments.

=head2 load_iter([\%terms, \%args])

Return an object of loaded groups for usage with iteration.

=head2 save()

Save the group!  If the status of the group has changed, rebuild the
permissions.

=head2 user_count([\%terms, \%args])

Return the number of members of the group.

=head2 user_iter([\%terms, \%args])

Return an object of group user-members for usage with iteration.

=head2 blog_iter([\%terms, \%args])

Return an object of group associated blogs for usage with iteration.

=head2 role_iter([\%terms, \%args])

Return an object of group associated roles for usage with iteration.

=head2 external_id()

Set the value of the external id for this group.

=head2 pack_external_id($id)

This function returns the given I<id> as a hexadecimal string.

=head2 unpack_external_id($id)

This function returns the given hexadecimal I<id> as an ordinary
string.

=head1 AUTHOR & COPYRIGHT

Please see L<MT/AUTHOR & COPYRIGHT>.

=cut
