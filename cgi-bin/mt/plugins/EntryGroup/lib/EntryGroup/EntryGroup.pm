package EntryGroup::EntryGroup;
use strict;

use base qw( CustomGroup::CustomGroup );

__PACKAGE__->install_properties( {
    class_type => 'entrygroup',
} );

sub plugin {
    return MT->component( 'EntryGroup' );
}

sub child_class {
    return 'entry';
}

sub child_object_ds {
    return 'entry';
}

sub tag {
    return 'GroupEntries';
}

sub stash {
    return 'entry';
}

sub permission {
    require CustomGroup::Plugin;
    return CustomGroup::Plugin::_group_permission( undef, 'entrygroup' );
}

sub edit_permission {
    my ( $user, $obj ) = @_;
    return 1 if $user->is_superuser;
    return 1 if $user->permissions( $obj->blog_id )->can_administer_blog;
    return 1 if $user->permissions( $obj->blog_id )->can_administer_website;
    return 1 if $user->permissions( $obj->blog_id )->can_edit_all_posts;
    if ( $user->permissions( $obj->blog_id )->can_create_post ) {
        return 1 if ( $obj->author_id == $user->id );
    }
    return 0;
}

sub default_module_mtml {
    my $tmplate = <<'MTML';
<MT:GroupEntries group_id="$group_id">
<MT:GroupEntriesHeader><ul></MT:GroupEntriesHeader>
    <li><a href="<MT:EntryPermalink>"><MT:EntryTitle remove_html="1"></a></li>
<MT:GroupEntriesFooter></ul></MT:GroupEntriesFooter>
</MT:GroupEntries>
MTML
    return $tmplate;
}

1;