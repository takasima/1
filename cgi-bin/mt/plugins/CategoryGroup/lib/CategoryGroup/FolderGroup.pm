package CategoryGroup::FolderGroup;
use strict;

use base qw( CustomGroup::CustomGroup );

__PACKAGE__->install_properties( {
    class_type => 'foldergroup',
} );

sub plugin {
    return MT->component( 'CategoryGroup' );
}

sub child_class {
    return 'folder';
}

sub child_object_ds {
    return 'category';
}

sub tag {
    return 'GroupFolders';
}

sub stash {
    return 'category';
}

sub permission {
    require CustomGroup::Plugin;
    return CustomGroup::Plugin::_group_permission( undef, 'foldergroup' );
}

sub edit_permission {
    my ( $user, $obj ) = @_;
    return 1 if $user->is_superuser;
    return 1 if $user->permissions( $obj->blog_id )->can_administer_blog;
    return 1 if $user->permissions( $obj->blog_id )->can_administer_website;
    return 1 if $user->permissions( $obj->blog_id )->can_manage_pages;
    return 0;
}

sub default_module_mtml {
    my $tmplate = <<'MTML';
<MT:GroupFolders group_id="$group_id">
<MT:GroupFoldersHeader><ul></MT:GroupFoldersHeader>
    <li><MT:FolderLabel remove_html="1"></li>
<MT:GroupFoldersFooter></ul></MT:GroupFoldersFooter>
</MT:GroupFolders>
MTML
    return $tmplate;
}

1;