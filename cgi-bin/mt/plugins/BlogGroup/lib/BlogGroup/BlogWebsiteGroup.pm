package BlogGroup::BlogWebsiteGroup;
use strict;

use base qw( CustomGroup::CustomGroup );

__PACKAGE__->install_properties( {
    class_type => 'blogwebsitegroup',
} );

sub plugin {
    return MT->component( 'BlogGroup' );
}

sub child_class {
    return [ 'blog', 'website' ];
}

sub child_class_label {
    my $plugin = MT->component( 'BlogGroup' );
    return $plugin->translate( 'Blog / Website Group' );
}

sub child_object_ds {
    return 'blog';
}

sub tag {
    return 'GroupBlogsWebsites';
}

sub stash {
    return 'blog';
}

sub permission {
    require CustomGroup::Plugin;
    return CustomGroup::Plugin::_group_permission( undef, 'blogwebsitegroup' );
}

sub edit_permission {
    my ( $user, $obj ) = @_;
    return 1 if $user->is_superuser;
    if ( $obj->class eq 'website' ) {
        return 1 if $user->permissions( $obj->id )->can_administer_website;
    } else {
        return 1 if $user->permissions( $obj->id )->can_administer_blog;
    }
    return 0;
}

sub default_module_mtml {
    my $tmplate = <<'MTML';
<MT:GroupBlogsWebsites group_id="$group_id">
<MT:GroupBlogsWebsitesHeader><ul></MT:GroupBlogsWebsitesHeader>
<MTIfWebsite>
    <li class="website"><a href="<MT:WebsiteURL>"><MT:WebsiteName remove_html="1"></a></li>
<MTElse>
    <li class="blog"><a href="<MT:BlogURL>"><MT:BlogName remove_html="1"></a></li>
</MTIfWebsite>
<MT:GroupBlogsWebsitesFooter></ul></MT:GroupBlogsWebsitesFooter>
</MT:GroupBlogsWebsites>
MTML
    return $tmplate;
}

1;