package Link::Listing;

use strict;

use MT::Util qw( encode_html encode_url remove_html );
use MT::I18N qw( substr_text length_text );

use lib qw( addons/PowerCMS.pack/lib );
use PowerCMS::Util qw( build_tmpl permitted_blog_ids );

sub _list_template_param {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $component = MT->component('Link');
    $param->{search_label} = $component->translate('Link');
    $param->{search_type}  = 'link';
}

sub _list_template_param_group {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $component = MT->component('Link');
    $param->{search_label} = $component->translate('Link');
    $param->{search_type}  = 'link';
}

sub _cms_pre_load_filtered_list {
    my ( $cb, $app, $filter, $load_options, $cols ) = @_;
    my $component = $app->param('datasource');
    if ( !$app->user->is_superuser ) {
        my $terms = $load_options->{terms} || {};
        my @blog_ids = permitted_blog_ids(
            $app,
            [
                'administer_website', 'administer_blog', 'manage_' . $component,
            ]
        );
        $terms->{blog_id} = \@blog_ids;
    }
    return 1;
}

sub list_props {
    my $app    = MT->instance;
    my $plugin = MT->component('Link');
    return {
        id => {
            base  => '__virtual.id',
            order => 100,
        },
        status => {
            auto    => 1,
            display => 'optional',
            label   => 'Status',
            order   => 125,
            html    => sub { status(@_) },
        },

        name => {
            base    => '__virtual.title',
            label   => 'Name',
            display => 'force',
            order   => 150,
            html    => sub { name(@_) },
        },
        url => {
            auto    => 1,
            label   => 'URL',
            display => 'optional',
            order   => 200,
            html    => sub { url(@_) },
        },
        description => {
            auto    => 1,
            label   => 'Description',
            display => 'default',
            order   => 250,
            html    => sub { description(@_) },
        },
        rating => {
            auto    => 1,
            label   => 'Rating',
            display => 'optional',
            order   => 300,
        },
        author_name => {
            base    => '__virtual.author_name',
            order   => 350,
            display => 'default',
        },
        created_on => {
            auto    => 1,
            display => 'default',
            label   => 'Created on',
            base    => '__virtual.created_on',
            order   => 400,
        },
        modified_on => {
            auto    => 1,
            display => 'optional',
            label   => 'Modified on',
            base    => '__virtual.modified_on',
            order   => 425,
        },

        rss_address => {
            auto    => 1,
            display => 'default',
            label   => 'RSS',
            order   => 450,
            html    => sub { rss(@_) }
        },

        current_user => {
            base            => '__common.current_user',
            label           => $plugin->translate('My Link'),
            filter_editable => 1,
        },
        tag             => { base => '__virtual.tag', tag_ds => 'link' },
        current_context => {
            base      => '__common.current_context',
            condition => sub { 0 },
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
            base    => '__virtual.title',
            label   => 'Name(Object Count)',
            display => 'force',
            order   => 200,
            html    => sub { group_name(@_) },
        },
        additem => {
            label   => 'Settings',
            display => 'optional',
            order   => 250,
            html    => sub { settings(@_) },
        },
        author_name => {
            base    => '__virtual.author_name',
            order   => 300,
            display => 'default',
        },
        blog_name => {
            base  => '__common.blog_name',
            label => sub {
                MT->app->blog
                  ? MT->translate('Blog Name')
                  : MT->translate('Website/Blog Name');
            },
            display   => 'default',
            site_name => sub { MT->app->blog ? 0 : 1 },
            order     => 400,
        },
        created_on => {
            base    => '__virtual.created_on',
            display => 'optional',
            order   => 500,
        },
        modified_on => {
            base  => '__virtual.modified_on',
            order => 600,
        },
        current_user => {
            base            => '__common.current_user',
            label           => 'My Link Groups',
            filter_editable => 1,
        },
        current_context => {
            base      => '__common.current_context',
            condition => sub { 0 },
        },
    };
}

sub system_filters_link {
    my $app     = MT->instance;
    my $plugin  = MT->component('Link');
    my $filters = {
        my_posts => {
            label => 'My Link',
            items => sub {
                [ { type => 'current_user' } ];
            },
            order => 1000,
        },
        draft => {
            label => 'Draft Link',
            items => sub {
                [
                    {
                        type => 'status',
                        args => { option => 'equal', value => 1 },
                    },
                ];
            },
            order => 2000,
        },
        published => {
            label => 'Published Link',
            items => sub {
                [
                    {
                        type => 'status',
                        args => { option => 'equal', value => 2 },
                    },
                ];
            },
            order => 3000,
        },
    };
    return $filters;
}

sub system_filters_linkgroup {
    my $app     = MT->instance;
    my $plugin  = MT->component('LinkGroup');
    my $filters = {
        my_posts => {
            label => 'My Link Groups',
            items => sub {
                [ { type => 'current_user' } ];
            },
            order => 1000,
        },
    };
    return $filters;
}

sub list_actions {
    my $app = MT->instance;
    return if ( $app->param( 'dialog_view' ) );
    my $actions = {
        'delete' => {
            button      => 1,
            label       => 'Delete',
            mode        => 'delete',
            class       => 'icon-action',
            return_args => 1,
            args        => { _type => 'link' },
            order       => 300,
        },
        publish_links => {
            button      => 1,
            label       => 'Publish',
            mode        => 'publish_links',
            class       => 'icon-action',
            return_args => 1,
            order       => 400,
        },
        unpublish_links => {
            label       => 'Unpublish',
            mode        => 'unpublish_links',
            return_args => 1,
            order       => 600,
        },
        action_link_check => {
            label       => 'Check',
            mode        => 'action_link_check',
            return_args => 1,
            order       => 700,
        },
        add_tags => {
            label       => 'Add Tags...',
            mode        => 'add_tags_to_link',
            class       => 'icon-action',
            return_args => 1,
            order       => 800,
            input       => 1,
            input_label => 'Tags to add to selected Link:',
        },
        remove_tags => {
            label => 'Remove Tags...',

            # code        =>
            mode        => 'remove_tags_to_link',
            class       => 'icon-action',
            return_args => 1,
            order       => 900,
            input       => 1,
            input_label => 'Tags to remove from selected Link:',
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
            args        => { _type => 'linkgroup' },
            order       => 100,
        },
    };
}

sub content_actions {
    my ( $meth, $component ) = @_;
    if ( !$component ) {
        $component = 'link';
    }
    my $app      = MT->instance;
    my $plugin   = MT->component($component);
    my $uploader = <<MTML;
    </a>
<__trans_section component="$component">
    <a href="javascript:void(0);" class="icon-left icon-action" onclick="return upload_csv()"><__trans phrase="Import from CSV or OPML"></a>
        <form method="post" style="display:inline" action="<mt:var name="mt_url">" enctype="multipart/form-data" id="upload_link">
        <input type="hidden" name="blog_id" value="<mt:var name="blog_id">" />
        <input type="hidden" name="__mode" value="upload_link" />
        <input type="hidden" name="class" value="<mt:var name="class">" />
        <input type="hidden" name="return_args" value="<mt:var name="return_args" escape="html">" />
        <input type="hidden" name="magic_token" value="<mt:var name="magic_token">" />
        <span id="import_file" style="display:none;">
        <input onchange="file_select()" style="font-size:11px;" type="file" name="file" id="file" />
        <a href="javascript:void(0)" style="display:none" id="send_csv" onclick="return upload_csv()"><__trans phrase="Send"></a>
        &nbsp;&nbsp; </span>
        </form>
    <a>
</__trans_section>
MTML
    if ( $app->blog ) {
        my %args = ( blog => $app->blog );
        my %params = (
            class       => $component,
            blog_id     => $app->blog->id,
            magic_token => $app->current_magic(),
            return_args => $app->make_return_args,
        );
        $uploader = build_tmpl( $app, $uploader, \%args, \%params );
    }
    return {
        'download_link_csv' => {
            mode        => 'download_link_csv',
            class       => 'icon-download',
            label       => 'Download CSV',
            return_args => 1,
            condition   => sub { MT->app->blog ? 1 : 0 },
            order       => 100,
            args        => { class => $component },
            confirm_msg => sub {
                $plugin->translate(
                    'Are you sure you want to download all links?');
            },
        },
        'upload_link' => {
            class     => 'icon-none',
            label     => $uploader,
            condition => sub { MT->app->blog &&  MT->app->can_do( 'upload' ) ? 1 : 0 },
            order     => 200,
        },
    };
}

sub system_filters_tag {
    return {
        link => {
            label => 'Tags with Link',
            view  => [ 'blog', 'website' ],
            items => [ { type => 'for_link' } ],
            order => 1000,
        },
    };
}

sub list_props_tag {
    return {
        for_link => {
            base        => '__virtual.tag',
            filter_tmpl => '<mt:Var name="filter_form_hidden">',
            base_type   => 'hidden',
            label       => 'Tags with Link',
            display     => 'none',
            obj_class   => 'link',
            view        => [ 'blog', 'website' ],
            singleton   => 1,
            terms       => sub {
                my $prop = shift;
                my ( $args, $db_terms, $db_args, $options ) = @_;
                my $blog_id = $options->{blog_ids};
                my $join    = '= objecttag_object_id';
                $db_args->{joins} ||= [];
                require Link::Link;
                push @{ $db_args->{joins} }, MT->model('objecttag')->join_on(
                    'tag_id',
                    { object_datasource => 'link' },
                    {
                        group  => ['tag_id'],
                        unique => 1,
                        join   => Link::Link->join_on(
                            undef,
                            {
                                class => $prop->obj_class,
                                id    => \$join,
                            }
                        ),
                    }
                );
                return;
            },
        },
        link_count => {
            label       => 'Links',
            base        => '__virtual.integer',
            count_class => 'link',
            display     => 'default',
            order       => 800,
            col         => 'id',
            obj_class   => 'link',
            view        => [ 'blog', 'website' ],
            view_filter => 'none',
            raw         => sub {
                my ( $prop, $obj ) = @_;
                my $blog_id = MT->app->param('blog_id') || 0;
                my $join = '= objecttag_object_id';
                require Link::Link;
                MT->model('objecttag')->count(
                    {
                        ( $blog_id ? ( blog_id => $blog_id ) : () ),
                        tag_id            => $obj->id,
                        object_datasource => 'link',
                    },
                    {
                        join => Link::Link->join_on(
                            undef,
                            {
                                class => $prop->obj_class,
                                id    => \$join,
                            }
                        ),
                    }
                );
            },
            html_link => sub {
                my ( $prop, $obj, $app ) = @_;
                require Link::Plugin;
                if (
                    !Link::Plugin::_link_permission(
                        $app->blog, $prop->{obj_class}
                    )
                  )
                {
                    return;
                }
                return $app->uri(
                    mode => 'list',
                    args => {
                        _type      => $prop->count_class,
                        class      => $prop->count_class,
                        blog_id    => $app->param('blog_id') || 0,
                        filter     => 'tag',
                        filter_val => $obj->name,
                    },
                );
            },
            bulk_sort => sub {
                my $prop = shift;
                my ( $objs, $options ) = @_;
                my $join = '= objecttag_object_id';
                require Link::Link;
                my $iter = MT->model('objecttag')->count_group_by(
                    {
                        (
                            scalar @{ $options->{blog_ids} || [] }
                            ? ( blog_id => $options->{blog_id} )
                            : ()
                        ),
                        object_datasource => 'link',
                    },
                    {
                        sort      => 'cnt',
                        direction => 'ascend',
                        group     => ['tag_id'],
                        join      => Link::Link->join_on(
                            undef,
                            {
                                class => $prop->obj_class,
                                id    => \$join,
                            }
                        ),
                    },
                );
                my %counts;
                while ( my ( $cnt, $id ) = $iter->() ) {
                    $counts{$id} = $cnt;
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
    my $link_icon = url_icon( $prop, $obj, $app );
    my $name = encode_html( $obj->name ) || '...';
    my $edit_link = $app->uri(
        mode => 'view',
        args => {
            _type   => 'link',
            blog_id => $obj->blog_id,
            id      => $obj->id,
        }
    );
    return qq{
        $icon <a href="$edit_link">$name</a> $link_icon
    };
}

sub url {
    my ( $prop, $obj, $app ) = @_;
    my $var = $obj->url;
    my $short =
      substr_text( $var, 0, 40 ) . ( length_text($var) > 40 ? "..." : "" );
    my $icon = link_status_icon( $prop, $obj, $app );
    return $icon . $short;
}

sub url_icon {
    my ( $prop, $obj, $app ) = @_;
    return '' unless $obj->url;
    my $url  = MT->static_path . 'images/status_icons/view.gif';
    my $icon = '<a href="' . encode_html( $obj->url ) . '" target="_blank">';
    $icon .=
        '<img width="13" height="9" alt="'
      . encode_html( $obj->name )
      . '" src="';
    $icon .= $url . '" />';
    $icon .= '</a>';
    return $icon;
}

sub link_status_icon {
    my ( $prop, $obj, $app ) = @_;
    return '' unless $obj->url;
    my $url =
        MT->static_path
      . 'images/status_icons/'
      . ( $obj->broken_link ? 'warning.gif' : 'success.gif' );
    my $icon = '<a href="' . encode_html( $obj->url ) . '" target="_blank">';
    $icon .= '<img width="9" height="9" alt="link status" src="';
    $icon .= $url . '" />';
    $icon .= '</a>';
    return $icon;
}

sub description {
    my ( $prop, $obj, $app ) = @_;
    my $var = $obj->description;
    my $short =
      substr_text( $var, 0, 40 ) . ( length_text($var) > 40 ? "..." : "" );
    return $short;
}

sub rss {
    my ( $prop, $obj, $app ) = @_;
    my $var = $obj->rss_address
        or return '';
    $var = encode_html($var);
    my $html = '<div style="background-color:#4444ff;padding:1px 0px;text-align:center;">';
    $html .= qq{<a style="color:white" target="_blank" href="$var" title="$var">RSS</a>};
    $html .= '</div>';
    return $html;
}

sub status {
    my ( $prop, $obj, $app ) = @_;
    my $plugin = MT->component('Link');
    my $status = $obj->status;
    my $alt    = $plugin->translate( $obj->status_text );
    my $icon   = status_icon( $prop, $obj, $app );
    return $icon . " " . $alt;
}

sub group_name {
    my ( $prop, $obj, $app ) = @_;
    my $name = encode_html( $obj->name ) || '...';
    my $args = {
        _type   => 'linkgroup',
        blog_id => $obj->blog_id,
        id      => $obj->id,
    };
    if ( my $filter_tag = $obj->filter_tag ) {
        $args->{filter_tag} = encode_html($filter_tag);
    }
    if ( my $filter = $obj->filter ) {
        $args->{filter} = encode_html($filter);
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
    my $plugin = MT->component('Link');
    if ( !$obj->additem ) {
        return $plugin->translate('None');
    }
    my $addposition = $obj->addposition;
    my $settings;
    if ($addposition) {
        $settings = $plugin->translate('Add new Link to last');
    }
    else {
        $settings = $plugin->translate('Add new Link to first');
    }
    my @sets;
    if ( my $addfiltertag = $obj->addfiltertag ) {
        my $set = $plugin->translate('Tag is');
        $set .= "'$addfiltertag'";
        push( @sets, $set );
    }
    if ( $obj->blog->class eq 'website' ) {
        if ( my $addfilter_blog_id = $obj->addfilter_blog_id ) {
            require MT::Blog;
            my $blog = MT::Blog->load($addfilter_blog_id);
            push( @sets, $blog->name ) if $blog;
        }
        else {
            push( @sets, $plugin->translate('website and all blogs') );
        }
    }
    if (@sets) {
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
    if ($asset) {
        if ( $asset->class eq 'image' ) {
            ( $thumbnail, $w, $h ) = __get_thumbnail($asset);
            my $asset_label = encode_html( $asset->label );
            $asset_alt =
              MT->translate( 'Thumbnail image for [_1]', $asset_label );
            $asset_url = $asset->url;
        }
    }
    if ($thumbnail) {
        return qq{
            <a href="$asset_url" target="_blank"><img src="$thumbnail" width="32" height="32" alt="$asset_alt" /></a>
        };
    }
    else {
        return '-';
    }
}

sub __get_thumbnail {
    my $asset = shift;
    my %args;
    $args{Square} = 1;
    if ( $asset->image_height > $asset->image_width ) {
        $args{Width} = 32;
    }
    else {
        $args{Height} = 32;
    }
    return $asset->thumbnail_url(%args);
}

sub status_icon {
    my ( $prop, $obj, $app ) = @_;
    my $plugin = MT->component('Link');
    my $status = $obj->status;
    my $alt;
    my $gif;
    if ( $status == $obj->HOLD ) {
        $alt = $plugin->translate('Draft');
        $gif = 'draft.gif';
    }
    elsif ( $status == $obj->RELEASE ) {
        $alt = $plugin->translate('Publishing');
        $gif = 'success.gif';
    }
    elsif ( $status == $obj->FUTURE ) {
        $alt = $plugin->translate('Scheduled');
        $gif = 'future.gif';

        # } elsif ( $status == $obj->REVIEW ) {
        #     $gif = 'warning.gif';
    }
    elsif ( $status == $obj->CLOSE ) {
        $alt = $plugin->translate('Ended');
        $gif = 'close.gif';
    }
    my $url  = MT->static_path . 'images/status_icons/' . $gif;
    my $icon = '<img width="9" height="9" alt="' . $alt . '" src="';
    $icon .= $url . '" />';
    return $icon;
}

1;
