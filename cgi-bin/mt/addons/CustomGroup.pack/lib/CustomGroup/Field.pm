package CustomGroup::Field;

use strict;
use lib qw( addons/Commercial.pack/lib );
use CustomFields::Util qw( get_meta );

sub _init_tags {
    my $app = MT->instance();
    return 1 if ( ref $app ) eq 'MT::App::Upgrader';
    require MT::Request;
    my $r = MT::Request->instance;
    my $k = 'plugin-customgroup-init';
    $r->cache($k)
        and return 1
        or $r->cache($k, 1);
    if ( ref $app eq 'MT::App::CMS' ) {
        if ( $^O eq 'MSWin32' && lc $ENV{ 'REQUEST_METHOD' } eq 'post' ) {
            # pass
        } else {
            my $load_at = [ 'view', 'rebuild', 'preview', 'save', 'delete', 'cfg', 'default', 'recover', 'itemset' ];
            require CGI;
            $CGI::POST_MAX = $app->config->CGIMaxUpload;
            my $q = new CGI;
            my $mode = $q->param( '__mode' )
                or return;
            $mode =~ s/_.*$//;
            if (! grep { $mode =~ /^\Q$_\E/ } @$load_at ) {
                return;
            }
            my $type = $q->param( '_type' );
            if ( $type && ( $type eq 'field' ) ) {
                return;
            }
        }
    }
    my $core = MT->component( 'Core' );
    my $block = $core->registry( 'tags', 'block' );
    my $function = $core->registry( 'tags', 'block' );
    my $custom_groups = MT->registry( 'custom_groups' );
    my @objects = keys( %$custom_groups );
    for my $object ( @objects ) {
        my $model = MT->model( $object );
        my $tag = lc( $model->tag );
        my $stash = $model->stash;
        my $child_class = $model->child_class;
        my $child_object_ds = $model->child_object_ds;
        my $core_tag = MT->registry( 'tags', 'block', $tag );
        if (! $core_tag ) {
            $block->{ $tag } = sub {
                my ( $ctx, $args, $cond ) = @_;
                $args->{ class } = $object;
                $args->{ stash } = $stash;
                $args->{ child_class } = $child_class;
                $args->{ child_object_ds } = $child_object_ds;
                $args->{ template_tag_name } = $tag;
                require CustomGroup::Tags;
                return CustomGroup::Tags::_hdlr_group_objects( $ctx, $args, $cond );
            };
        }
        my $count_tag = MT->registry( 'tags', 'function', $tag . 'count' );
        if (! $count_tag ) {
            $function->{ $tag . 'count' } = sub {
                my ( $ctx, $args, $cond ) = @_;
                $args->{ class } = $object;
                $args->{ stash } = $stash;
                $args->{ child_class } = $child_class;
                $args->{ child_object_ds } = $child_object_ds;
                $args->{ template_tag_name } = $tag;
                $args->{ count } = 1;
                require CustomGroup::Tags;
                return CustomGroup::Tags::_hdlr_group_objects( $ctx, $args, $cond );
            };
        }
        my $header_tag = MT->registry( 'tags', 'block', $tag . 'header' );
        if (! $header_tag ) {
            $block->{ $tag . 'header' } = sub {
                my ( $ctx, $args, $cond ) = @_;
                require CustomGroup::Tags;
                return CustomGroup::Tags::_hdlr_pass_tokens( $ctx, $args, $cond );
            };
        }
        my $footer_tag = MT->registry( 'tags', 'block', $tag . 'footer' );
        if (! $footer_tag ) {
            $block->{ $tag . 'footer' } = sub {
                my ( $ctx, $args, $cond ) = @_;
                require CustomGroup::Tags;
                return CustomGroup::Tags::_hdlr_pass_tokens( $ctx, $args, $cond );
            };
        }
    }
    my @fields = MT->model( 'field' )->load( { customgroup => 1 } );
    my $commercial = MT->component( 'commercial' );
    my $tags = $commercial->registry( 'tags' );
    for my $field ( @fields ) {
        my $tag = $field->tag;
        $tag = lc( $tag );
        my $field_type = $field->type;
        delete( $tags->{ function }->{ $tag } );
        $block->{ $tag } = sub {
            my ( $ctx, $args, $cond ) = @_;
            require CustomGroup::Tags;
            require CustomFields::Template::ContextHandlers;
            my $field = CustomFields::Template::ContextHandlers::find_field_by_tag( $ctx )
                or return _no_field( $ctx );
            local $ctx->{ __stash }{ field } = $field;
            my $res = '';
            my $value = CustomFields::Template::ContextHandlers::_hdlr_customfield_value( @_ )
                or return '';
            if ( $args->{ raw } ) {
                return $value;
            }
            $args->{ group_id } = $value;
            $args->{ class } = $field_type;
            my $stash = $custom_groups->{ $field_type }->{ stash };
            $args->{ stash } = $stash;
            $args->{ child_class } = MT->model( $field_type )->child_class;
            $args->{ child_object_ds } = MT->model( $field_type )->child_object_ds;
            return CustomGroup::Tags::_hdlr_group_objects( $ctx, $args, $cond );
        };
    }
    @fields = MT->model( 'field' )->load( { type => 'objectgroup' } );
    for my $field ( @fields ) {
        my $tag = $field->tag;
        $tag = lc( $tag );
        my $field_type = $field->type;
        delete( $tags->{ function }->{ $tag } );
        $block->{ $tag } = sub {
            my ( $ctx, $args, $cond ) = @_;
            require CustomGroup::Tags;
            require CustomFields::Template::ContextHandlers;
            my $field = CustomFields::Template::ContextHandlers::find_field_by_tag( $ctx )
                or return _no_field( $ctx );
            local $ctx->{ __stash }{ field } = $field;
            my $res = '';
            my $value = CustomFields::Template::ContextHandlers::_hdlr_customfield_value( @_ )
                or return '';
            if ( $args->{ raw } ) {
                return $value;
            }
            $args->{ group_id } = $value;
            require ObjectGroup::Tags;
            return ObjectGroup::Tags::_hdlr_og_groupitems( $ctx, $args, $cond );
        };
    }
}

sub _no_field {
    my ( $ctx ) = @_;
    return $ctx->error( MT->translate(
        "You used an '[_1]' tag outside of the context of the correct content; ",
        $ctx->stash( 'tag' ) ) );
}

sub _customfield_types {
    my $custom_groups = MT->registry( 'custom_groups' );
    my @objects = keys( %$custom_groups );
    my $customfield_types;
    for my $object ( @objects ) {
        my $component = $custom_groups->{ $object }->{ component };
        my $order = $custom_groups->{ $object }->{ field_order };
        $component = MT->component( $component );
        my $label = $component->translate( $custom_groups->{ $object }->{ field_name } );
        $customfield_types->{ $object } = {
            label             => $label,
            column_def        => 'vinteger_idx',
            order             => $order,
            no_default        => 1,
            field_html        => \&_field_html,
            field_html_params => \&_field_html_params,
        };
    }
    $customfield_types->{ 'objectgroup' } = {
        label             => 'Object Group',
        column_def        => 'vinteger_idx',
        order             => 3300,
        no_default        => 1,
        field_html        => \&_field_html,
        field_html_params => \&_field_html_params,
    };
    return $customfield_types;
}

sub _field_html {
    return <<'MTML';
<__trans_section component="CustomGroup">
<span class="field-content" id="field_value-<mt:var name="field_id" escape="html">" style="padding:0px;display:block;margin-bottom:6px;line-height:1.4em">
<mt:if name="object_exists">
<span id="obj-<mt:var name="field_id" escape="html">-<mt:var name="id" escape="html">">
<mt:var name="name" escape="html"> (ID:<mt:var name="id" escape="html">)
<a href="javascript:;" onclick="jQuery(this).parent().remove();remove_val('<mt:var name="id" escape="html">','<mt:var name="field_id" escape="html">');"><img src="<mt:var name="static_uri">images/status_icons/close.gif" alt="<__trans phrase="Delete">" title="<__trans phrase="Delete">" /></a>
</span>
</mt:if>
</span>
<MTCustomGroupFieldScope scope_type="$mode" setvar="fieldscope">
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
        <a href="<mt:var name="script_url">?__mode=list_<mt:var name="mode">&amp;blog_id=<mt:var name="field_blog_id">&amp;dialog_view=1&amp;edit_field=<mt:var name="field_id">&amp;_type=<mt:var name="mode">&amp;customgroup_select=1" class="mt-open-dialog button">
        <__trans phrase="Select [_1]" params="<mt:var name="class_label">">
        </a>
    </span>
</span>
<mt:IfNotSent key="js_remove_val">
<script type="text/javascript">
    function remove_val(n, fld) {
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
    my $app = MT->instance;
    $param->{ blog_id } = $app->blog->id if $app->blog;
    $param->{ mode } = $key;
    $param->{ class_label } = MT->model( $key )->class_label;
    if ( my $field_id = $param->{ field_value } ) {
        my $obj;
        if ( $key eq 'objectgroup' ) {
            require ObjectGroup::ObjectGroup;
            $obj = ObjectGroup::ObjectGroup->load( $field_id );
        } else {
            require CustomGroup::CustomGroup;
            $obj = CustomGroup::CustomGroup->load( $field_id );
        }
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
