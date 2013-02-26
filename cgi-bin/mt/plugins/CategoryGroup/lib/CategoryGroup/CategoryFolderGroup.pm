package CategoryGroup::CategoryFolderGroup;
use strict;

use base qw( CustomGroup::CustomGroup );

__PACKAGE__->install_properties( {
    class_type => 'categoryfoldergroup',
} );

sub plugin {
    return MT->component( 'CategoryGroup' );
}

sub child_class {
    return [ 'category', 'folder' ];
}

sub child_class_label {
    my $plugin = MT->component( 'CategoryGroup' );
    return $plugin->translate( 'Category / Folder Group' );
}

sub child_object_ds {
    return 'category';
}

sub tag {
    return 'GroupCategoriesFolders';
}

sub stash {
    return 'category';
}

sub permission {
    require CustomGroup::Plugin;
    return CustomGroup::Plugin::_group_permission( undef, 'categoryfoldergroup' );
}

sub edit_permission {
    my ( $user, $obj ) = @_;
    return 1 if $user->is_superuser;
    return 1 if $user->permissions( $obj->blog_id )->can_administer_blog;
    return 1 if $user->permissions( $obj->blog_id )->can_administer_website;
    if ( $obj->class eq 'folder' ) {
        return 1 if $user->permissions( $obj->blog_id )->can_manage_pages;
    } else {
        return 1 if $user->permissions( $obj->blog_id )->can_edit_categories;
    }
    return 0;
}

sub default_module_mtml {
    my $tmplate = <<'MTML';
<MT:GroupCategoriesFolders group_id="$group_id">
<MT:GroupCategoriesFoldersHeader><ul></MT:GroupCategoriesFoldersHeader>
<MTIf tag="CategoryClass" eq="category">
    <li class="category"><a href="<MT:CategoryArchiveLink>"><MT:CategoryLabel remove_html="1"></a></li>
<MTElse>
    <li class="page"><MT:FolderLabel></li>
</MTIf>
<MT:GroupCategoriesFoldersFooter></ul></MT:GroupCategoriesFoldersFooter>
</MT:GroupCategoriesFolders>
MTML
    return $tmplate;
}

1;