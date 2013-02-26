package BlogGroup::BlogGroup;
use strict;

use base qw( CustomGroup::CustomGroup );

__PACKAGE__->install_properties( {
    class_type => 'bloggroup',
} );

sub plugin {
    return MT->component( 'BlogGroup' );
}

sub child_class {
    return 'blog';
}

sub child_object_ds {
    return 'blog';
}

sub tag {
    return 'GroupBlogs';
}

sub stash {
    return 'blog';
}

sub permission {
    require CustomGroup::Plugin;
    return CustomGroup::Plugin::_group_permission( undef, 'bloggroup' );
}

sub edit_permission {
    my ( $user, $obj ) = @_;
    return 1 if $user->is_superuser;
    return 1 if $user->permissions( $obj->id )->can_administer_blog;
    return 0;
}

sub default_module_mtml {
    my $tmplate = <<'MTML';
<MT:GroupBlogs group_id="$group_id">
<MT:GroupBlogsHeader><ul></MT:GroupBlogsHeader>
    <li><a href="<MT:BlogURL>"><MT:BlogName remove_html="1"></a></li>
<MT:GroupBlogsFooter></ul></MT:GroupBlogsFooter>
</MT:GroupBlogs>
MTML
    return $tmplate;
}

1;