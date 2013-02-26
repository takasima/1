package CategoryGroup::CategoryGroup;
use strict;

use base qw( CustomGroup::CustomGroup );

__PACKAGE__->install_properties( {
    class_type => 'categorygroup',
} );

sub plugin {
    return MT->component( 'CategoryGroup' );
}

sub child_class {
    return 'category';
}

sub child_object_ds {
    return 'category';
}

sub tag {
    return 'GroupCategories';
}

sub stash {
    return 'category';
}

sub permission {
    require CustomGroup::Plugin;
    return CustomGroup::Plugin::_group_permission( undef, 'categorygroup' );
}

sub edit_permission {
    my ( $user, $obj ) = @_;
    return 1 if $user->is_superuser;
    return 1 if $user->permissions( $obj->blog_id )->can_administer_blog;
    return 1 if $user->permissions( $obj->blog_id )->can_administer_website;
    return 1 if $user->permissions( $obj->blog_id )->can_edit_categories;
    return 0;
}

sub default_module_mtml {
    my $tmplate = <<'MTML';
<MT:GroupCategories group_id="$group_id">
<MT:GroupCategoriesHeader><ul></MT:GroupCategoriesHeader>
    <li><a href="<MT:CategoryArchiveLink>"><MT:CategoryLabel remove_html="1"></a></li>
<MT:GroupCategoriesFooter></ul></MT:GroupCategoriesFooter>
</MT:GroupCategories>
MTML
    return $tmplate;
}

1;