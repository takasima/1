package CustomGroupConfig::Tools;
use strict;

sub upgrade_group {
    require MT::Author;
    require MT::Permission;
    my $author = MT::Author->load(
        { status => 1 },
        { limit => 1,
          join => [ 'MT::Permission', 'author_id',
                { blog_id     => 0,
                  permissions => { like => "%'administer'%" } },
            ],
        },
    );
    eval { require ItemSort::SortGroup };
    unless ( $@ ) {
        require EntryGroup::EntryPageGroup;
        require ItemSort::SortNum;
        require CustomGroup::GroupOrder;
        my $iter = ItemSort::SortGroup->load_iter();
        while ( my $old = $iter->() ) {
            my $new = EntryGroup::EntryPageGroup->new;
            $new->blog_id( $old->blog_id );
            $new->name( $old->name );
            $new->additem( $old->add_item );
            $new->addposition( $old->add_position );
            $new->template_id( $old->template_id );
            $new->author_id( $author->id );
            if ( my $add_filter = $old->add_filter ) {
                if ( $add_filter eq 'category_id' ) {
                    $new->addfilter( 'category' );
                    $new->addfilter_cid( $old->filter_val );
                } elsif ( $add_filter eq 'tag' ) {
                    $new->addfilter( 'tag' );
                    $new->addfiltertag( $old->filter_val );
                }
            }
            $new->save or die $new->errstr;
            my $items_iter = ItemSort::SortNum->load_iter( { sortgroup_id => $old->id } );
            while ( my $old_order = $items_iter->() ) {
                my $new_order = CustomGroup::GroupOrder->new;
                $new_order->group_id( $new->id );
                $new_order->order( $old_order->number );
                $new_order->object_id( $old_order->entry_id );
                $new_order->object_class( $old_order->type );
                $new_order->save or die $new_order->errstr;
            }
        }
        # ItemSort::SortGroup->remove_all;
        # ItemSort::SortNum->remove_all;
    }
    eval { require ItemGroup::ItemGroup };
    unless ( $@ ) {
        require CategoryGroup::CategoryFolderGroup;
        require BlogGroup::BlogWebsiteGroup;
        require ItemGroup::ItemOrder;
        require CustomGroup::GroupOrder;
        my $iter = ItemGroup::ItemGroup->load_iter();
        while ( my $old = $iter->() ) {
            my $new;
            if ( $old->object_ds eq 'category' ) {
                $new = CategoryGroup::CategoryFolderGroup->new;
            } else {
                $new = BlogGroup::BlogWebsiteGroup->new;
            }
            $new->blog_id( $old->blog_id );
            $new->name( $old->name );
            $new->additem( $old->additem );
            $new->addposition( $old->addposition );
            $new->template_id( $old->template_id );
            $new->author_id( $author->id );
            $new->filter( $old->class );
            $new->save or die $new->errstr;
            my $items_iter = ItemGroup::ItemOrder->load_iter( { itemgroup_id => $old->id } );
            while ( my $old_order = $items_iter->() ) {
                my $new_order = CustomGroup::GroupOrder->new;
                $new_order->group_id( $new->id );
                $new_order->order( $old_order->number );
                $new_order->object_id( $old_order->object_id );
                $new_order->object_class( $old_order->class );
                $new_order->save or die $new_order->errstr;
            }
        }
        # ItemGroup::ItemGroup->remove_all;
        # ItemGroup::ItemOrder->remove_all;
    }
    return 1;
}

1;
