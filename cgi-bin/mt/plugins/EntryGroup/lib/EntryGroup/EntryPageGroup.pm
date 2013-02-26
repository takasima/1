package EntryGroup::EntryPageGroup;
use strict;

use base qw( CustomGroup::CustomGroup );

__PACKAGE__->install_properties( {
    class_type => 'entrypagegroup',
} );

sub plugin {
    return MT->component( 'EntryGroup' );
}

sub child_class {
    return [ 'entry', 'page' ];
}

sub child_class_label {
    my $plugin = MT->component( 'EntryGroup' );
    return $plugin->translate( 'Entry / Page Group' );
}

sub child_object_ds {
    return 'entry';
}

sub tag {
    return 'GroupEntriesPages';
}

sub stash {
    return 'entry';
}

sub permission {
    require CustomGroup::Plugin;
    return CustomGroup::Plugin::_group_permission( undef, 'entrypagegroup' );
}

sub edit_permission {
    my ( $user, $obj ) = @_;
    return 1 if $user->is_superuser;
    return 1 if $user->permissions( $obj->blog_id )->can_administer_blog;
    return 1 if $user->permissions( $obj->blog_id )->can_administer_website;
    if ( $obj->class eq 'entry' ) {
        return 1 if $user->permissions( $obj->blog_id )->can_edit_all_posts;
        if ( $user->permissions( $obj->blog_id )->can_create_post ) {
            return 1 if ( $obj->author_id == $user->id );
        }
    } else {
        return 1 if $user->permissions( $obj->blog_id )->can_manage_pages;
    }
    return 0;
}

sub default_module_mtml {
    my $tmplate = <<'MTML';
<MT:GroupEntriesPages group_id="$group_id">
<MT:GroupEntriesPagesHeader><ul></MT:GroupEntriesPagesHeader>
<MTIf tag="EntryClass" eq="page">
    <li class="page"><a href="<MT:PagePermalink>"><MT:PageTitle></a></li>
<MTElse>
    <li class="entry"><a href="<MT:EntryPermalink>"><MT:EntryTitle></a></li>
</MTIf>
<MT:GroupEntriesPagesFooter></ul></MT:GroupEntriesPagesFooter>
</MT:GroupEntriesPages>
MTML
    return $tmplate;
}


sub cms_pre_save_category {
    my ( $cb, $app, $obj, $original ) = @_;
    my $plugin = MT->component( 'EntryGroup' );
    my $blog_id = $obj->blog_id;
    my $sync = $plugin->get_config_value( 'sync_entrygroup_category', 'blog:' . $blog_id );
    return 1 unless $sync;
    my $group;
    if ( $obj->label ne $original->label ) {
        $group = MT->model( 'entrypagegroup' )->load( { blog_id => $blog_id,
                                                        name => $original->label } );
        if (! defined $group ) {
            $group = MT->model( 'entrypagegroup' )->get_by_key( { blog_id => $blog_id,
                                                                  name => $obj->label } );
        }
    } else {
        $group = MT->model( 'entrypagegroup' )->get_by_key( { blog_id => $blog_id,
                                                              name => $obj->label } );
    }
    return 1 unless $group;
    if (! $obj->id ) {
        $obj->save or die $obj->errstr;
    }
    my $add_item = $plugin->get_config_value( 'add_item', 'blog:' . $blog_id );
    if ( $add_item ) {
        my $add_position = $plugin->get_config_value( 'add_position', 'blog:' . $blog_id );
        $group->addfilter( 'category' );
        $group->additem( 1 );
        $group->addfilter_cid( $obj->id );
        $group->addposition( $add_position );
    } else {
        $group->addfilter( undef );
        $group->additem( 0 );
        $group->addfilter_cid( undef );
        $group->addposition( undef );
    }
    $group->save or die $group->errstr;
    return 1;
}

1;