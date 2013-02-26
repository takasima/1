package Campaign::Field;

use strict;
use lib qw( addons/Commercial.pack/lib );
use CustomFields::Util qw( get_meta );

sub _init_tags {
    my $app = MT->instance();
    return 1 if ( ref $app ) eq 'MT::App::Upgrader';
    require MT::Request;
    my $r = MT::Request->instance;
    my $cache = $r->cache( 'plugin-campaign-init' );
    return 1 if $cache;
    $r->cache( 'plugin-campaign-init', 1 );
    unless ( $ENV{FAST_CGI} || MT->config->PIDFilePath ) {
        if ( ref $app eq 'MT::App::CMS' ) {
            if ( $^O eq 'MSWin32' && lc $ENV{ 'REQUEST_METHOD' } eq 'post' ) {
                # pass
            } else {
                require CGI;
                $CGI::POST_MAX = $app->config->CGIMaxUpload;
                my $q = new CGI;
                my $mode = $q->param( '__mode' )
                    or return;
                $mode =~ s/_.*$//;
                my @load_at = qw/view rebuild preview save delete cfg default recover itemset publish/;
                unless ( grep { $mode =~ /^\Q$_\E/ } @load_at ) {
                    return;
                }
                my $type = $q->param( '_type' );
                if ( $type && ( $type eq 'field' ) ) {
                    return;
                }
            }
        }
    }
    my @fields = MT->model( 'field' )->load( { type => [ 'campaign', 'campaign_multi', 'campaign_group' ] } );
    my $core = MT->component( 'Campaign' );
    my $registry = $core->registry( 'tags', 'block' );
    my $commercial = MT->component( 'commercial' );
    my $tags = $commercial->registry( 'tags' );
    for my $field ( @fields ) {
        my $field_type = $field->type;
        my $tag = $field->tag;
        $tag = lc( $tag );
        delete( $tags->{ function }->{ $tag } );
        if ( $field_type eq 'campaign' ) {
            $registry->{ $tag } = sub { 
                my ( $ctx, $args, $cond ) = @_;
                require CustomFields::Template::ContextHandlers;
                my $field = CustomFields::Template::ContextHandlers::find_field_by_tag( $ctx )
                    or return _no_field( $ctx );
                local $ctx->{ __stash }{ field } = $field;
                my $res = '';
                my $value = CustomFields::Template::ContextHandlers::_hdlr_customfield_value( @_ );
                return '' unless $value;
                if ( $args->{ raw } ) {
                    return $value;
                }
                $args->{ id } = $value;
                require Campaign::Tags;
                return Campaign::Tags::_hdlr_campaigns( $ctx, $args, $cond );
            };
        } elsif ( $field_type eq 'campaign_multi' )  {
            $registry->{ $tag } = sub { 
                my ( $ctx, $args, $cond ) = @_;
                require CustomFields::Template::ContextHandlers;
                my $field = CustomFields::Template::ContextHandlers::find_field_by_tag( $ctx )
                    or return _no_field( $ctx );
                local $ctx->{ __stash }{ field } = $field;
                my $res = '';
                my $value = CustomFields::Template::ContextHandlers::_hdlr_customfield_value( @_ );
                return '' unless $value;
                $value =~ s/^,//;
                $value =~ s/,$//;
                if ( $args->{ raw } ) {
                    return $value;
                }
                $args->{ ids } = $value;
                require Campaign::Tags;
                return Campaign::Tags::_hdlr_campaigns( $ctx, $args, $cond );
            };
        } elsif ( $field_type eq 'campaign_group' )  {
            $registry->{ $tag } = sub { 
                my ( $ctx, $args, $cond ) = @_;
                require CustomFields::Template::ContextHandlers;
                my $field = CustomFields::Template::ContextHandlers::find_field_by_tag( $ctx )
                    or return _no_field( $ctx );
                local $ctx->{ __stash }{ field } = $field;
                my $res = '';
                my $value = CustomFields::Template::ContextHandlers::_hdlr_customfield_value( @_ );
                return '' unless $value;
                $value =~ s/^,//;
                $value =~ s/,$//;
                if ( $args->{ raw } ) {
                    return $value;
                }
                $args->{ group_id } = $value;
                require Campaign::Tags;
                return Campaign::Tags::_hdlr_campaigns( $ctx, $args, $cond );
            };
        }
    }
}

sub _no_field {
    my ( $ctx ) = @_;
    return $ctx->error( MT->translate(
        "You used an '[_1]' tag outside of the context of the correct content; ",
        $ctx->stash( 'tag' ) ) );
}

sub _customfield_types {
    my $customfield_types = {
        campaign => {
            label             => 'Campaign',
            column_def        => 'vinteger_idx',
            order             => 902,
            no_default        => 1,
            field_html        => \&_field_html,
            field_html_params => \&_field_html_params,
        },
        campaign_multi => {
            label             => 'Campaign(Multiple)',
            column_def        => 'vchar_idx',
            order             => 903,
            no_default        => 1,
            field_html        => \&_field_html_multi,
            field_html_params => \&_field_html_params_multi,
        },
        campaign_group => {
            label             => 'Campaign Group',
            column_def        => 'vinteger_idx',
            order             => 904,
            no_default        => 1,
            field_html        => \&_field_html_group,
            field_html_params => \&_field_html_params_group,
        },
    };
}

sub _field_html {
    return <<'MTML';
<__trans_section component="Campaign">
<span class="field-content" id="field_value-<mt:var name="field_id" escape="html">" style="padding:0px;display:block;margin-bottom:6px;line-height:1.4em">
<mt:if name="object_exists">
<span id="obj-<mt:var name="field_id" escape="html">-<mt:var name="id" escape="html">">
<mt:var name="name" escape="html"> (ID:<mt:var name="id" escape="html">)
<a href="javascript:;" onclick="jQuery(this).parent().remove();remove_val('<mt:var name="id" escape="html">','<mt:var name="field_id" escape="html">');"><img src="<mt:var name="static_uri">images/status_icons/close.gif" alt="<__trans phrase="Delete">" title="<__trans phrase="Delete">" /></a>
</span>
</mt:if>
</span>
<MTCampaignFieldScope setvar="fieldscope">
<mt:if name="fieldscope" eq="blog">
<mt:setvar name="field_blog_id" value="$blog_id">
<mt:else>
<mt:setvar name="field_blog_id" value="$curr_website_id">
</mt:else>
</mt:if>
<input name="<mt:var name="field_name" escape="html">" id="<mt:var name="field_id" escape="html">" type="hidden" value="<mt:var name="value" escape="html" _default="0">" />
<input id="<mt:var name="field_id" escape="html">-checker" type="hidden" value="" />
<span class="actions-bar" style="clear:none;margin-top:4px">
    <span class="actions-bar-inner pkg actions">
        <a href="<mt:var name="script_url">?__mode=list_campaign&amp;blog_id=<mt:var name="field_blog_id">&amp;dialog_view=1&amp;edit_field=<mt:var name="field_id">&amp;costomobject_select=1" class="mt-open-dialog button">
        <mt:var name="field_label">
        </a>
    </span>
</span>
<mt:IfNotSent key="js_remove_val">
<script type="text/javascript">
    function remove_val(n,fld){
        var val_new = '';
        jQuery('#' + fld).val(val_new);
    }
</script>
</mt:IfNotSent>
</__trans_section>
MTML
}

sub _field_html_multi {
    return <<'MTML';
<__trans_section component="Campaign">
<span class="field-content" id="field_value-<mt:var name="field_id" escape="html">" style="dpadding:0px;display:block;margin-bottom:6px;line-height:1.4em">
<mt:if name="object_exists">
<mtloop name="object_loop">
<span id="obj-<mt:var name="field_id" escape="html">-<mt:var name="id" escape="html">">
<mt:var name="name" escape="html"> (ID:<mt:var name="id" escape="html">)
<a href="javascript:;" onclick="jQuery(this).parent().remove();remove_val_multi('<mt:var name="id" escape="html">','<mt:var name="field_id" escape="html">');"><img src="<mt:var name="static_uri">images/status_icons/close.gif" alt="<__trans phrase="Delete">" title="<__trans phrase="Delete">" /></a>
</span>
</mt:loop>
</mt:if>
</span>
<MTCampaignFieldScope setvar="fieldscope">
<mt:if name="fieldscope" eq="blog">
<mt:setvar name="field_blog_id" value="$blog_id">
<mt:else>
<mt:setvar name="field_blog_id" value="$curr_website_id">
</mt:else>
</mt:if>
<input name="<mt:var name="field_name" escape="html">" id="<mt:var name="field_id" escape="html">" type="hidden" value="<mt:var name="value" escape="html">" />
<input id="<mt:var name="field_id" escape="html">-checker" type="hidden" value="multi" />
<span class="actions-bar" style="clear:none;margin-top:4px">
    <span class="actions-bar-inner pkg actions">
        <a href="<mt:var name="script_url">?__mode=list_campaign&amp;blog_id=<mt:var name="field_blog_id">&amp;dialog_view=1&amp;edit_field=<mt:var name="field_id">&amp;costomobject_select=1" class="mt-open-dialog button">
        <mt:var name="field_label">
        </a>
    </span>
</span>
<mt:IfNotSent key="js_remove_val_multi">
<script type="text/javascript">
    function remove_val_multi(n,fld){
        var val = jQuery('#' + fld).val();
        var val_sp = val.split(',');
        var val_new = '';
        for(var i = 0; i < val_sp.length; i++){
            if(val_sp[i] != n){
                if(val_sp[i] != ''){
                    val_new = val_new + val_sp[i] + ',';
                }
            }
        }
        if(val_new != ''){
            val_new = ',' + val_new;
        }
        jQuery('#' + fld).val(val_new);
    }
</script>
</mt:IfNotSent>
</__trans_section>
MTML
}

sub _field_html_group {
    return <<'MTML';
<__trans_section component="Campaign">
<span class="field-content" id="field_value-<mt:var name="field_id" escape="html">" style="padding:0px;display:block;margin-bottom:6px;line-height:1.4em">
<mt:if name="object_exists">
<span id="obj-<mt:var name="field_id" escape="html">-<mt:var name="id" escape="html">">
<mt:var name="name" escape="html"> (ID:<mt:var name="id" escape="html">)
<a href="javascript:;" onclick="jQuery(this).parent().remove();remove_val('<mt:var name="id" escape="html">','<mt:var name="field_id" escape="html">');"><img src="<mt:var name="static_uri">images/status_icons/close.gif" alt="<__trans phrase="Delete">" title="<__trans phrase="Delete">" /></a>
</span>
</mt:if>
</span>
<MTCampaignFieldScope setvar="fieldscope">
<mt:if name="fieldscope" eq="blog">
<mt:setvar name="field_blog_id" value="$blog_id">
<mt:else>
<mt:setvar name="field_blog_id" value="$curr_website_id">
</mt:else>
</mt:if>
<input name="<mt:var name="field_name" escape="html">" id="<mt:var name="field_id" escape="html">" type="hidden" value="<mt:var name="value" escape="html" _default="0">" />
<input id="<mt:var name="field_id" escape="html">-checker" type="hidden" value="" />
<span class="actions-bar" style="clear:none;margin-top:4px">
    <span class="actions-bar-inner pkg actions">
        <a href="<mt:var name="script_url">?__mode=list_campaigngroup&amp;blog_id=<mt:var name="field_blog_id">&amp;dialog_view=1&amp;edit_field=<mt:var name="field_id">&amp;costomobject_select=1" class="mt-open-dialog button">
        <mt:var name="field_label">
        </a>
    </span>
</span>
<mt:IfNotSent key="js_remove_val">
<script type="text/javascript">
    function remove_val(n,fld){
        var val_new = '';
        jQuery('#' + fld).val(val_new);
    }
</script>
</mt:IfNotSent>
</__trans_section>
MTML
}

sub _field_html_params {
    my ( $key, $tmpl, $param ) = @_;
    my $plugin = MT->component( 'Campaign' );
    $param->{ field_label } = $plugin->translate( 'Select Campaign' );
    $param->{ field_class } = $key;
    if ( my $field_id = $param->{ field_value } ) {
        require Campaign::Campaign;
        my $obj = Campaign::Campaign->load( $field_id );
        if ( $obj ) {
            $param->{ object_exists } = 1;
            my $column_names = $obj->column_names;
            foreach my $column_name ( @$column_names ) {
                if ( $obj->has_column( $column_name ) ) {
                    $param->{ $column_name } = $obj->$column_name;
                }
            }
            my $meta = get_meta( $obj );
            foreach my $field ( keys %$meta ) {
                my $column_name = 'field.' . $field;
                if ( $obj->has_column( $column_name ) ) {
                    $param->{ $column_name } = $obj->$column_name;
                }
            }
        }
    }
    my $app = MT->instance;
    if ( my $blog = $app->blog ) {
        $param->{ blog_id } = $blog->id;
        if ( $blog->is_blog ) {
            $param->{ curr_website_id } = $blog->parent_id;
        } else {
            $param->{ curr_website_id } = $blog->id;
        }
    }
    return 1;
}

sub _field_html_params_multi {
    my ( $key, $tmpl, $param ) = @_;
    my $plugin = MT->component( 'Campaign' );
    $param->{ field_label } = $plugin->translate( 'Select Campaign' );
    $param->{ field_class } = $key;
    if ( my $field_id = $param->{ field_value } ) {
        require Campaign::Campaign;
        my @ids = split( /,/, $field_id );
        my @objects = Campaign::Campaign->load( { id => \@ids } );
        my @object_loop;
        my @active_id;
        for my $obj ( @objects ) {
            push( @active_id, $obj->id );
            $param->{ object_exists } = 1;
            my $local_param;
            my $column_names = $obj->column_names;
            foreach my $column_name ( @$column_names ) {
                if ( $obj->has_column( $column_name ) ) {
                    $local_param->{ $column_name } = $obj->$column_name;
                }
            }
            my $meta = get_meta( $obj );
            foreach my $field ( keys %$meta ) {
                my $column_name = 'field.' . $field;
                if ( $obj->has_column( $column_name ) ) {
                    $local_param->{ $column_name } = $obj->$column_name;
                }
            }
            push( @object_loop, $local_param );
        }
        if ( @active_id ) {
            my $ids = join( ',', @active_id );
            $ids = ',' . $ids . ',';
            $param->{ value } = $ids;
        } else {
            $param->{ value } = '';
        }
        $param->{ object_loop } = \@object_loop;
    }
    my $app = MT->instance;
    if ( my $blog = $app->blog ) {
        $param->{ blog_id } = $blog->id;
        if ( $blog->is_blog ) {
            $param->{ curr_website_id } = $blog->parent_id;
        } else {
            $param->{ curr_website_id } = $blog->id;
        }
    }
    return 1;
}

sub _field_html_params_group {
    my ( $key, $tmpl, $param ) = @_;
    my $plugin = MT->component( 'Campaign' );
    $param->{ field_label } = $plugin->translate( 'Select Campaign Group' );
    $param->{ field_class } = $key;
    if ( my $field_id = $param->{ field_value } ) {
        require Campaign::CampaignGroup;
        my $obj = Campaign::CampaignGroup->load( $field_id );
        if ( $obj ) {
            $param->{ object_exists } = 1;
            my $column_names = $obj->column_names;
            foreach my $column_name ( @$column_names ) {
                if ( $obj->has_column( $column_name ) ) {
                    $param->{ $column_name } = $obj->$column_name;
                }
            }
            my $meta = get_meta( $obj );
            foreach my $field ( keys %$meta ) {
                my $column_name = 'field.' . $field;
                if ( $obj->has_column( $column_name ) ) {
                    $param->{ $column_name } = $obj->$column_name;
                }
            }
        }
    }
    my $app = MT->instance;
    if ( my $blog = $app->blog ) {
        $param->{ blog_id } = $blog->id;
        if ( $blog->is_blog ) {
            $param->{ curr_website_id } = $blog->parent_id;
        } else {
            $param->{ curr_website_id } = $blog->id;
        }
    }
    return 1;
}

1;
