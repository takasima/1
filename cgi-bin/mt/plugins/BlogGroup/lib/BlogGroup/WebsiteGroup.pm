package BlogGroup::WebsiteGroup;
use strict;

use base qw( CustomGroup::CustomGroup );

__PACKAGE__->install_properties( {
    class_type => 'websitegroup',
} );

sub plugin {
    return MT->component( 'BlogGroup' );
}

sub child_class {
    return 'website';
}

sub child_object_ds {
    return 'blog';
}

sub tag {
    return 'GroupWebsites';
}

sub stash {
    return 'blog';
}

sub permission {
    require CustomGroup::Plugin;
    return CustomGroup::Plugin::_group_permission( undef, 'websitegroup' );
}

sub edit_permission {
    my ( $user, $obj ) = @_;
    return 1 if $user->is_superuser;
    return 1 if $user->permissions( $obj->id )->can_administer_website;
    return 0;
}

sub default_module_mtml {
    my $tmplate = <<'MTML';
<MT:GroupWebsites group_id="$group_id">
<MT:GroupWebsitesHeader><ul></MT:GroupWebsitesHeader>
    <li><a href="<MT:WebsiteURL>"><MT:WebsiteName remove_html="1"></a></li>
<MT:GroupWebsitesFooter></ul></MT:GroupWebsitesFooter>
</MT:GroupWebsites>
MTML
    return $tmplate;
}

1;