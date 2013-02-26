package Campaign::Tools;

use strict;
use File::Spec;
use lib qw( addons/PowerCMS.pack/lib addons/Commercial.pack/lib );
use PowerCMS::Util qw( current_ts make_dir powercms_files_dir );
use CustomFields::Util qw( get_meta save_meta );

sub clone_object {
    my ( $cb, %param ) = @_;
    my $old_blog_id = $param{ old_blog_id };
    my $new_blog_id = $param{ new_blog_id };
    my $callback    = $param{ callback };
    my $app         = MT->instance;
    my $component = MT->component( 'Campaign' );
    my ( %campaigngroup_map, %campaign_map, %id_campaign, @moved_objects );
    require Campaign::CampaignOrder;
    if (! $app->param( 'clone_prefs_campaign' ) ) {
        my $terms = { blog_id => $old_blog_id };
        my $iter = MT->model( 'campaigngroup' )->load_iter( $terms );
        my $counter = 0;
        my $state = $component->translate( 'Cloning Campaign Groups for blog...' );
        my $group_label = $component->translate( 'Campaign Groups' );
        my $obj_label = $component->translate( 'Campaign' );
        while ( my $object = $iter->() ) {
            $counter++;
            my $new_object = $object->clone_all();
            delete $new_object->{ column_values }->{ id };
            delete $new_object->{ changed_cols }->{ id };
            $new_object->blog_id( $new_blog_id );
            $new_object->save or die $new_object->errstr;
            $campaigngroup_map{ $object->id } = $new_object->id;
        }
        $callback->(
            $state . " "
                . $app->translate( "[_1] records processed.", $counter ),
            $group_label
        );
        $counter = 0;
        $state = $component->translate( 'Cloning Campaigns for blog...' );
        $iter = MT->model( 'campaign' )->load_iter( $terms );
        while ( my $object = $iter->() ) {
            $counter++;
            my $new_object = $object->clone_all();
            delete $new_object->{ column_values }->{ id };
            delete $new_object->{ changed_cols }->{ id };
            $new_object->blog_id( $new_blog_id );
            # TODO::Assets
            $new_object->save or die $new_object->errstr;
            my $meta_data = get_meta( $object );
            save_meta( $new_object, $meta_data ) if %$meta_data;
            push ( @moved_objects, $new_object );
            $campaign_map{ $object->id } = $new_object->id;
            $id_campaign{ $new_object->id } = $new_object;
            # $id_campaign{ $object->id } = $object;
            my $order_iter = Campaign::CampaignOrder->load_iter( { campaign_id => $object->id } );
            while ( my $order = $order_iter->() ) {
                next unless $campaigngroup_map{ $order->group_id };
                my $new_order = $order->clone_all();
                delete $new_order->{ column_values }->{ id };
                delete $new_order->{ changed_cols }->{ id };
                $new_order->campaign_id( $campaign_map{ $order->campaign_id } );
                $new_order->group_id( $campaigngroup_map{ $order->group_id } );
                $new_order->save or die $new_order->errstr;
            }
        }
        $callback->(
            $state . " "
                . $app->translate( "[_1] records processed.", $counter ),
            $obj_label
        );
    }
    my $state = $component->translate( 'Cloning Campaign tags for blog...' );
    $callback->( $state, "campaign_tags" );
    my $iter
        = MT::ObjectTag->load_iter(
        { blog_id => $old_blog_id, object_datasource => 'campaign' }
        );
    my $counter = 0;
    while ( my $campaign_tag = $iter->() ) {
        next unless $campaign_map{ $campaign_tag->object_id };
        $counter++;
        my $new_campaign_tag = $campaign_tag->clone();
        delete $new_campaign_tag->{ column_values }->{ id };
        delete $new_campaign_tag->{ changed_cols }->{ id };
        $new_campaign_tag->blog_id( $new_blog_id );
        $new_campaign_tag->object_id(
            $campaign_map{ $campaign_tag->object_id } );
        $new_campaign_tag->save or die $new_campaign_tag->errstr;
    }
    $callback->(
        $state . " "
            . MT->translate( "[_1] records processed.",
            $counter ),
        'campaign_tags'
    );
    MT->request( 'campaigngroup_map', \%campaigngroup_map );
    MT->request( 'campaign_map', \%campaign_map );
    MT->request( 'id_campaign', \%id_campaign );
    # TODO::CustomField and Assets
    1;
}

sub clone_blog {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $plugin = MT->component( 'Campaign' );
    my $elements = $tmpl->getElementsByTagName( 'unless' );
    my $obj_label = 'Campaign';
    my $obj = 'campaign';
    my ( $element )
        = grep { 'clone_prefs_input' eq $_->getAttribute( 'name' ) } @$elements;
    if ( $element ) {
        my $contents = $element->innerHTML;
        my $text     = <<EOT;
    <input type="hidden" name="clone_prefs_${obj}" value="<mt:var name="clone_prefs_${obj}">" />
EOT
        $element->innerHTML( $contents . $text );
    }
    ( $element )
        = grep { 'clone_prefs_checkbox' eq $_->getAttribute( 'name' ) }
        @$elements;
    if ( $element ) {
        my $contents = $element->innerHTML;
        my $text     = <<EOT;
            <li>
                <input type="checkbox" name="clone_prefs_${obj}" id="clone-prefs-${obj}" <mt:if name="clone_prefs_${obj}">checked="<mt:var name="clone_prefs_${obj}">"</mt:if> class="cb" />
                <label for="clone-prefs-${obj}"><__trans_section component="${obj_label}"><__trans phrase="${obj_label}s"></__trans_section></label>
            </li>
EOT
        $element->innerHTML( $contents . $text );
    }
    ( $element )
        = grep { 'clone_prefs_exclude' eq $_->getAttribute( 'name' ) }
        @$elements;
    if ( $element ) {
        my $contents = $element->innerHTML;
        my $text     = <<EOT;
<mt:if name="clone_prefs_${obj}" eq="on">
            <li><__trans_section component="${obj}"><__trans phrase="Exclude ${obj_label}s"></__trans_section></li>
</mt:if>
EOT
        $element->innerHTML( $contents . $text );
    }
}

sub _post_run {
    my $app = MT->instance();
    my $install;
    if ( ( ref $app ) eq 'MT::App::Upgrader' ) {
        if ( $app->mode eq 'run_actions' ) {
            if ( $app->param( 'installing' ) ) {
                $install = 1;
            }
        }
    }
    if ( $install ) {
        _install_role();
    }
    return 1;
}

sub _scheduled_publish {
    my $plugin_campaign = MT->component( 'Campaign' );
    my $app = MT->instance();
    require Campaign::Campaign;
    my @blogs = MT::Blog->load( { class => [ 'website', 'blog' ] } );
    for my $blog ( @blogs ) {
        my $ts = current_ts( $blog );
        my @campaigns = $app->model( 'campaign' )->load( { blog_id   => $blog->id, status => 3, },
                                                         { sort      => 'publishing_on',
                                                           start_val => $ts - 1,
                                                           direction => 'descend', } );
        for my $campaign ( @campaigns ) {
            my $original = $campaign->clone_all();
            $campaign->status( 2 );
            $campaign->save or die $campaign->errstr;
            $app->run_callbacks( 'post_publish.campaign', $app, $campaign, $original );
        }
        @campaigns = $app->model( 'campaign' )->load( { blog_id   => $blog->id, status => 2, set_period => 1 },
                                                      { sort      => 'period_on',
                                                        start_val => $ts - 1,
                                                        direction => 'descend', } );
        for my $campaign ( @campaigns ) {
            my $original = $campaign->clone_all();
            $campaign->status( 4 );
            $app->run_callbacks( 'post_close.campaign', $app, $campaign, $original );
            $campaign->save or die $campaign->errstr;
        }
    }
    return 1;
}

sub _install_role {
    my $app = MT->instance();
    require MT::Role;
    my $plugin_campaign = MT->component( 'Campaign' );
    my $role = MT::Role->get_by_key( { name => $plugin_campaign->translate( 'Campaign Administrator' ) } );
    if (! $role->id ) {
        my $role_en = MT::Role->load( { name => 'Campaign Administrator' } );
        if (! $role_en ) {
            my %values;
            $values{ created_by }  = $app->user->id if $app->user;
            $values{ description } = $plugin_campaign->translate( 'Can create campaign, edit campaign.' );
            $values{ is_system }   = 0;
            $values{ permissions } = "'manage_campaign','manage_campaigngroup'";
            $role->set_values( \%values );
            $role->save
                or return $app->trans_error( 'Error saving role: [_1]', $role->errstr );
        }
    }
    _make_campaign_dir();
    return 1;
}

sub _make_campaign_dir {
    my $powercms_files_dir = powercms_files_dir();
    if ( $powercms_files_dir ) {
        my $directory = File::Spec->catdir( $powercms_files_dir, 'campaign' );
        if (! -d $directory ) {
            if ( make_dir( $directory ) ) {
                unless (-w $directory ) {
                    chmod ( 0755, $directory );
                }
            }
        }
        return $directory;
    }
}

sub _default_module_mtml {
    return <<'MTML';
<MTCampaigns group_id="$group_id">
<MTCampaignsHeader><ul></MTCampaignsHeader>
<li><a href="<$MTCampaignURL encode_html="1"$>"><img src="<$MTCampaignBannerURL encode_html="1"$>" width="<$MTCampaignBannerWidth$>" height="<$MTCampaignBannerHeight$>" alt="<$MTCampaignTitle encode_html="1"$>" /></a></li>
<MTCampaignsFooter></ul></MTCampaignsFooter>
</MTCampaigns>
MTML
}

sub _task_adjust_order {
    my $updated = 0;
    my @orders = MT->model( 'campaignorder' )->load();
    for my $order ( @orders ) {
        my $remove = 0;
        if ( my $group_id = $order->group_id ) {
            my $group = MT->model( 'campaigngroup' )->load( { id => $group_id } );
            if ( $group ) {
                if ( ! $order->blog_id ) {
                    $order->blog_id( $group->blog_id );
                    $order->save or die $order->errstr;
                    $updated++;
                }
            } else {
                $remove = 1;
            }
        } else {
            $remove = 1;
        }
        if ( $remove ) {
            $order->remove();
            $updated++;
        }
    }
    return $updated;
}

1;
