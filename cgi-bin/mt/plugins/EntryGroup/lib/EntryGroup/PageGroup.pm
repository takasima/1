package EntryGroup::PageGroup;
use strict;

use base qw( CustomGroup::CustomGroup );

__PACKAGE__->install_properties( {
    class_type => 'pagegroup',
} );

sub plugin {
    return MT->component( 'EntryGroup' );
}

sub child_class {
    return 'page';
}

sub child_object_ds {
    return 'entry';
}

sub tag {
    return 'GroupPages';
}

sub stash {
    return 'entry';
}

sub permission {
    require CustomGroup::Plugin;
    return CustomGroup::Plugin::_group_permission( undef, 'pagegroup' );
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
<MT:GroupPages group_id="$group_id">
<MT:GroupPagesHeader><ul></MT:GroupPagesHeader>
    <li><a href="<MT:PagePermalink>"><MT:PageTitle remove_html="1"></a></li>
<MT:GroupPagesFooter></ul></MT:GroupPagesFooter>
</MT:GroupPages>
MTML
    return $tmplate;
}

1;