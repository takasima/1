package Campaign::Listing;

use strict;

use MT::Util qw( encode_html encode_url remove_html );
use MT::I18N qw( substr_text length_text );

use lib qw( addons/PowerCMS.pack/lib );
use PowerCMS::Util qw( permitted_blog_ids );

sub _list_template_param {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $component = MT->component( 'Campaign' );
    $param->{ search_label } = $component->translate( 'Campaign' );
    $param->{ search_type } = 'campaign';
}

sub _list_template_param_group {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $component = MT->component( 'Campaign' );
    $param->{ search_label } = $component->translate( 'Campaign' );
    $param->{ search_type } = 'campaign';
}

sub _cms_pre_load_filtered_list {
    my ( $cb, $app, $filter, $load_options, $cols ) = @_;
    my $component = $app->param( 'datasource' );
    if (! $app->user->is_superuser ) {
        my $terms = $load_options->{ terms } || {};
        my @blog_ids = permitted_blog_ids( $app, [ 'administer_website',
                                                   'administer_blog',
                                                   'manage_' . $component ] );
        $terms->{ blog_id } = \@blog_ids;
    }
    return 1;
}

sub list_props {
    my $app = MT->instance;
    my $plugin = MT->component( 'Campaign' );
    return {
        id => {
            base  => '__virtual.id',
            order => 100,
        },
        image_id => {
            auto => 1,
            label => 'Image',
            display => 'default',
            order   => 125,
            html => sub { thumbnail( @_ ) },
        },
        title => {
            base       => '__virtual.title',
            label      => 'Title',
            display    => 'force',
            order      => 150,
            html => sub { name( @_ ) },
        },
        basename => {
            label => 'basename',
            auto  => 1,
            order => 170,
        },
        status => {
            auto    => 1,
            display => 'optional',
            label   => 'Status',
            order   => 200,
            html    => sub { status( @_ ) },
        },
        author_name => {
            base    => '__virtual.author_name',
            order   => 300,
            display => 'default',
        },
        set_period => {
            label   => 'Set Period',
            display => 'optional',
            order   => 400,
            html => sub { set_period( @_ ) },
        },
        publishing_on => {
            base    => '__virtual.created_on',
            label   => 'Publishing date',
            display => 'optional',
            order   => 500,
        },
        period_on => {
            label   => 'End date',
            base    => '__virtual.created_on',
            order   => 600,
        },
        created_on => {
            auto    => 1,
            display => 'optional',
            label   => 'Created on',
            base    => '__virtual.created_on',
            order   => 700,
        },
        modified_on => {
            auto    => 1,
            display => 'optional',
            label   => 'Modified on',
            base    => '__virtual.modified_on',
            order   => 800,
        },
        conversion => {
            display => 'optional',
            label   => 'Conversion(PV)',
            order   => 900,
            html => sub { conversion( @_ ) },
        },
        displays => {
            display => 'optional',
            label   => 'PV(Clicks)',
            order   => 1000,
            html => sub { displays( @_ ) },
        },
        uniqdisplays => {
            display => 'optional',
            label   => 'UU(Clicks)',
            order   => 1100,
            html => sub { uniqdisplays( @_ ) },
        },
        current_user => {
            base            => '__common.current_user',
            label           => $plugin->translate( 'My Campaign' ),
            filter_editable => 1,
        },
        tag => { base => '__virtual.tag', tag_ds => 'campaign' },
        current_context => {
            base      => '__common.current_context',
            condition => sub {0},
        },
    };
}

sub list_props_group {
    my $app = MT->instance;
    return {
        id => {
            base  => '__virtual.id',
            order => 100,
        },
        name => {
            base       => '__virtual.title',
            label      => 'Name(Object Count)',
            display    => 'force',
            order      => 200,
            html => sub { group_name( @_ ) },
        },
        additem => {
            label   => 'Settings',
            display => 'optional',
            order   => 250,
            html => sub { settings( @_ ) },
        },
        author_name => {
            base    => '__virtual.author_name',
            order   => 300,
            display => 'default',
        },
        blog_name => {
            base => '__common.blog_name',
            label =>
                sub { MT->app->blog ? MT->translate( 'Blog Name' ) : MT->translate( 'Website/Blog Name' ) },
            display   => 'default',
            site_name => sub { MT->app->blog ? 0 : 1 },
            order     => 400,
        },
        created_on => {
            base    => '__virtual.created_on',
            display => 'optional',
            order => 500,
        },
        modified_on => {
            base  => '__virtual.modified_on',
            order => 600,
        },
        current_user => {
            base            => '__common.current_user',
            label           => 'My Campaign Groups',
            filter_editable => 1,
        },
        current_context => {
            base      => '__common.current_context',
            condition => sub {0},
        },
    };
}

sub system_filters_campaign {
    my $app = MT->instance;
    my $plugin = MT->component( 'Campaign' );
    my $filters = {
        my_posts => {
            label => 'My Campaign',
            items => sub {
                [ { type => 'current_user' } ];
            },
            order => 1000,
        },
        draft => {
            label => 'Draft Campaign',
            items => sub {
                [ { type => 'status', args => { option => 'equal', value => 1 } } ];
            },
            order => 2000,
        },
        published => {
            label => 'Published Campaign',
            items => sub {
                [ { type => 'status', args => { option => 'equal', value => 2 } } ];
            },
            order => 3000,
        },
        scheduled => {
            label => 'Scheduled Campaign',
            items => sub {
                [ { type => 'status', args => { option => 'equal', value => 3 } } ];
            },
            order => 4000,
        },
        ended => {
            label => 'Ended Campaign',
            items => sub {
                [ { type => 'status', args => { option => 'equal', value => 4 } } ];
            },
            order => 5000,
        },
    };
    return $filters;
}

sub list_actions {
    my $actions = {
        'delete' => {
            button      => 1,
            label       => 'Delete',
            mode        => 'delete',
            class       => 'icon-action',
            return_args => 1,
            args        => { _type => 'campaign' },
            order       => 300,
        },
        publish_campaigns => {
            button      => 1,
            label       => 'Publish',
            mode        => 'publish_campaigns',
            class       => 'icon-action',
            return_args => 1,
            order       => 400,
        },
        unpublish_campaigns => {
            label       => 'Unpublish',
            mode        => 'unpublish_campaigns',
            return_args => 1,
            order       => 600,
        },
        reserve_campaigns => {
            label       => 'Reserve',
            mode        => 'reserve_campaigns',
            return_args => 1,
            order       => 700,
        },
        end_campaigns => {
            label       => 'End',
            mode        => 'end_campaigns',
            return_args => 1,
            order       => 700,
        },
        add_tags => {
            label       => 'Add Tags...',
            mode        => 'add_tags_to_campaign',
            class       => 'icon-action',
            return_args => 1,
            order       => 800,
            input         => 1,
            input_label   => 'Tags to add to selected Campaign:',
        },
        remove_tags => {
            label       => 'Remove Tags...',
            # code        =>
            mode        => 'remove_tags_to_campaign',
            class       => 'icon-action',
            return_args => 1,
            order       => 900,
            input         => 1,
            input_label   => 'Tags to remove from selected Campaign:',
        },
    };
    return $actions;
}

sub list_group_actions {
    return {
        'delete' => {
            button      => 1,
            label       => 'Delete',
            mode        => 'delete',
            class       => 'icon-action',
            return_args => 1,
            args        => { _type => 'campaigngroup' },
            order       => 100,
        },
    };
}

sub system_filters_tag {
    return {
        campaign => {
            label => 'Tags with Campaign',
            view  => [ 'blog', 'website' ],
            items => [ { type => 'for_campaign' } ],
            order => 1000,
        },
    };
}

sub list_props_tag {
    return {
        for_campaign => {
            base        => '__virtual.tag',
            filter_tmpl => '<mt:Var name="filter_form_hidden">',
            base_type   => 'hidden',
            label       => 'Tags with Campaign',
            display     => 'none',
            obj_class   => 'campaign',
            view        => [ 'blog', 'website' ],
            singleton   => 1,
            terms       => sub {
                my $prop = shift;
                my ( $args, $db_terms, $db_args, $options ) = @_;
                my $blog_id = $options->{ blog_ids };
                my $join = '= objecttag_object_id';
                $db_args->{joins} ||= [];
                require Campaign::Campaign;
                push @{ $db_args->{ joins } }, MT->model( 'objecttag' )->join_on(
                    'tag_id',
                    {   object_datasource =>
                            'campaign',
                    },
                    {   group  => [ 'tag_id' ],
                        unique => 1,
                        join   => Campaign::Campaign->join_on(
                            undef,
                            {   class => $prop->obj_class,
                                id    => \$join,
                            }
                        ),
                    });
                return;
            },
        },
        campaign_count => {
            label       => 'Campaigns',
            base        => '__virtual.integer',
            count_class => 'campaign',
            display     => 'default',
            order       => 800,
            col         => 'id',
            obj_class   => 'campaign',
            view        => [ 'blog', 'website' ],
            view_filter => 'none',
            raw         => sub {
                my ( $prop, $obj ) = @_;
                my $blog_id = MT->app->param('blog_id') || 0;
                my $join = '= objecttag_object_id';
                require Campaign::Campaign;
                MT->model( 'objecttag' )->count(
                    {   ( $blog_id ? ( blog_id => $blog_id ) : () ),
                        tag_id            => $obj->id,
                        object_datasource => 'campaign',
                    },
                    {   join => Campaign::Campaign->join_on(
                            undef,
                            {   class => $prop->obj_class,
                                id    => \$join,
                            }
                        ),
                    }
                );
            },
            html_link => sub {
                my ( $prop, $obj, $app ) = @_;
                require Campaign::Plugin;
                if (! Campaign::Plugin::_campaign_permission( $app->blog, $prop->{ obj_class } ) ) {
                    return;
                }
                return $app->uri(
                    mode => 'list',
                    args => {
                        _type      => $prop->count_class,
                        class      => $prop->count_class,
                        blog_id    => $app->param( 'blog_id' ) || 0,
                        filter     => 'tag',
                        filter_val => $obj->name,
                    },
                );
            },
            bulk_sort => sub {
                my $prop = shift;
                my ( $objs, $options ) = @_;
                my $join = '= objecttag_object_id';
                require Campaign::Campaign;
                my $iter = MT->model( 'objecttag' )->count_group_by(
                    {   (   scalar @{ $options->{ blog_ids } || [] }
                            ? ( blog_id => $options->{ blog_id } )
                            : ()
                        ),
                        object_datasource => 'campaign',
                    },
                    {   sort      => 'cnt',
                        direction => 'ascend',
                        group     => [ 'tag_id' ],
                        join      => Campaign::Campaign->join_on(
                            undef,
                            {   class => $prop->obj_class,
                                id    => \$join,
                            }
                        ),
                    });
                my %counts;
                while ( my ( $cnt, $id ) = $iter->() ) {
                    $counts{ $id } = $cnt;
                }
                return sort {
                    ( $counts{ $a->id } || 0 ) <=> ( $counts{ $b->id } || 0 )
                } @$objs;
            },
        },
    };
}

sub name {
    my ( $prop, $obj, $app ) = @_;
    my $icon = status_icon( $prop, $obj, $app );
    my $name = encode_html( $obj->title ) || '...';
    my $edit_link = $app->uri(
        mode => 'view',
        args => {
            _type => 'campaign',
            blog_id => $obj->blog_id,
            id => $obj->id,
        }
    );
    return qq{
        $icon <a href="$edit_link">$name</a>
    };
}

sub status {
    my ( $prop, $obj, $app ) = @_;
    my $plugin = MT->component( 'Campaign' );
    my $status = $obj->status;
    my $alt = $plugin->translate( $obj->status_text );
    my $icon = status_icon( $prop, $obj, $app );
    return $icon . " " . $alt;
}

sub group_name {
    my ( $prop, $obj, $app ) = @_;
    my $name = encode_html( $obj->name ) || '...';
    my $args = { _type => 'campaigngroup',
                 blog_id => $obj->blog_id,
                 id => $obj->id,
                };
    if ( my $filter_tag = $obj->filter_tag ) {
        $args->{ filter_tag } = encode_html( $filter_tag );
    }
    if ( my $filter = $obj->filter ) {
        $args->{ filter } = encode_html( $filter );
    }
    my $edit_link = $app->uri(
        mode => 'view',
        args => $args,
    );
    my $children_count = $obj->children_count;
    return qq{
        <a href="$edit_link">$name</a> ($children_count)
    };
}

sub settings {
    my ( $prop, $obj, $app ) = @_;
    my $plugin = MT->component( 'Campaign' );
    if (! $obj->additem ) {
        return $plugin->translate( 'None' );
    }
    my $addposition = $obj->addposition;
    my $settings;
    if ( $addposition ) {
        $settings = $plugin->translate( 'Add new Campaign to last' );
    } else {
        $settings = $plugin->translate( 'Add new Campaign to first' );
    }
    my @sets;
    if ( my $addfiltertag = $obj->addfiltertag ) {
        my $set = $plugin->translate( 'Tag is' );
        $set .= "'$addfiltertag'";
        push ( @sets, $set );
    }
    if ( $obj->blog->class eq 'website' ) {
        if ( my $addfilter_blog_id = $obj->addfilter_blog_id ) {
            require MT::Blog;
            my $blog = MT::Blog->load( $addfilter_blog_id );
            push ( @sets, $blog->name ) if $blog;
        } else {
            push ( @sets, $plugin->translate( 'website and all blogs' ) );
        }
    }
    if ( @sets ) {
        my $added = join( ', ', @sets );
        $settings .= "($added)";
    }
    return $settings;
}

sub thumbnail {
    my ( $prop, $obj, $app ) = @_;
    my $asset = $obj->image;
    my ( $thumbnail, $w, $h );
    my $asset_alt;
    my $asset_url;
    if ( $asset ) {
        if ( $asset->class eq 'image' ) {
            ( $thumbnail, $w, $h ) = __get_thumbnail( $asset );
            my $asset_label = encode_html( $asset->label );
            $asset_alt = MT->translate( 'Thumbnail image for [_1]', $asset_label );
            $asset_url = $asset->url;
        }
    }
    if ( $thumbnail ) {
        return qq{
            <a href="$asset_url" target="_blank"><img src="$thumbnail" width="32" height="32" alt="$asset_alt" /></a>
        };
    } else {
        return '-';
    }
}

sub __get_thumbnail {
    my $asset = shift;
    my %args;
    $args{ Square } = 1;
    if ( $asset->image_height > $asset->image_width ) {
        $args{ Width } = 32;
    } else {
        $args{ Height } = 32;
    }
    return $asset->thumbnail_url( %args );
}

sub set_period {
    my ( $prop, $obj, $app ) = @_;
    my $plugin = MT->component( 'Campaign' );
    if ( $obj->set_period == 1 ) {
        return $plugin->translate( 'Yes' );
    } else {
        return $plugin->translate( 'No' );
    }
}

sub conversion {
    my ( $prop, $obj, $app ) = @_;
    my $conversion = $obj->conversion || '-';
    my $conversionview = $obj->conversionview || '-';
    return "$conversion ($conversionview)";
}

sub displays {
    my ( $prop, $obj, $app ) = @_;
    my $displays = $obj->displays || '-';
    my $clicks = $obj->clicks || '-';
    return "$displays ($clicks)";
}

sub uniqdisplays {
    my ( $prop, $obj, $app ) = @_;
    my $displays = $obj->uniqdisplays || '-';
    my $clicks = $obj->uniqclicks || '-';
    return "$displays ($clicks)";
}

sub status_icon {
    my ( $prop, $obj, $app ) = @_;
    my $plugin = MT->component( 'Campaign' );
    my $status = $obj->status;
    my $alt;
    my $gif;
    if ( $status == $obj->HOLD ) {
        $alt = $plugin->translate( 'Draft' );
        $gif = 'draft.gif';
    } elsif ( $status == $obj->RELEASE ) {
        $alt = $plugin->translate( 'Publishing' );
        $gif = 'success.gif';
    } elsif ( $status == $obj->FUTURE ) {
        $alt = $plugin->translate( 'Scheduled' );
        $gif = 'future.gif';
    # } elsif ( $status == $obj->REVIEW ) {
    #     $gif = 'warning.gif';
    } elsif ( $status == $obj->CLOSE ) {
        $alt = $plugin->translate( 'Ended' );
        $gif = 'close.gif';
    }
    my $url = MT->static_path . 'images/status_icons/' . $gif;
    my $icon = '<img width="9" height="9" alt="' . $alt . '" src="';
    $icon .= $url . '" />';
    return $icon;
}

1;
