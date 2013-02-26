package CustomObject::Field;

use strict;
use lib qw( addons/Commercial.pack/lib );
use CustomFields::Util qw( get_meta );

sub _init_tags {
    my $app = MT->instance();
    return 1 if ( ref $app ) eq 'MT::App::Upgrader';
    require MT::Request;
    my $r = MT::Request->instance;
    my $cache = $r->cache( 'plugin-customobject-init' );
    return 1 if $cache;
    $r->cache( 'plugin-customobject-init', 1 );
    my $core = MT->component( 'customobject' );
    my $registry = $core->registry( 'tags', 'block' );
    my $registry_function = $core->registry( 'tags', 'function' );
    my $custom_objects = MT->registry( 'custom_objects' );
    my @objects = keys( %$custom_objects );
    my @ats;
    for my $obj ( @objects ) {
        my $type = $custom_objects->{ $obj }->{ id };
        push ( @ats, $type );
        $registry->{"${type}CustomFields"}
            = '$Commercial::CustomFields::Template::ContextHandlers::_hdlr_customfields';
        $registry_function->{"${type}CustomFieldName"}
            = '$Commercial::CustomFields::Template::ContextHandlers::_hdlr_customfield_name';
        $registry_function->{"${type}CustomFieldDescription"}
            = '$Commercial::CustomFields::Template::ContextHandlers::_hdlr_customfield_description';
        $registry_function->{"${type}CustomFieldValue"}
            = '$Commercial::CustomFields::Template::ContextHandlers::_hdlr_customfield_value';
        # TODO::PHP
    }
    if ( ref $app eq 'MT::App::CMS' ) {
        if ( $^O eq 'MSWin32' && lc $ENV{ 'REQUEST_METHOD' } eq 'post' ) {
            # pass
        } else {
            my $load_at = [ 'view', 'rebuild', 'preview', 'save', 'delete', 'cfg', 'default', 'recover', 'itemset', 'publish' ];
            require CGI;
            $CGI::POST_MAX = $app->config->CGIMaxUpload;
            my $q = new CGI;
            my $mode = $q->param( '__mode' );
            return unless $mode;
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
    my $cfg_plugin = MT->component( 'CustomObjectConfig' );
    my $cfg_objects = $cfg_plugin->get_config_value( 'custom_objects' );
    my $class_plurals = $cfg_plugin->get_config_value( 'class_plurals' );
    my $class_names = $cfg_plugin->get_config_value( 'class_names' );
    my $archive_types = $cfg_plugin->get_config_value( 'archive_types' );
    my $cfg_objects_new = lc( join( ',', @objects ) );
    if ( $cfg_objects_new ) {
        if ( $cfg_objects_new ne $cfg_objects ) {
            $cfg_plugin->set_config_value( 'custom_objects', $cfg_objects_new );
        }
    }
    my $ats_new = join( ',', @ats );
    if ( $ats_new ) {
        if ( $ats_new ne $archive_types ) {
            $cfg_plugin->set_config_value( 'archive_types', $ats_new );
        }
    }
    my @names_array;
    my @plural_array;
    for my $obj ( @objects ) {
        my $class_label = $custom_objects->{ $obj }->{ id };
        my $class_label_plural = MT->model( $obj )->class_plural;
        push ( @names_array, $class_label );
        push ( @plural_array, $class_label_plural );
    }
    my $class_names_new = lc( join( ',', @names_array ) );
    my $class_plurals_new = lc( join( ',', @plural_array ) );
    if ( $class_names ne $class_names_new ) {
        $cfg_plugin->set_config_value( 'class_names', $class_names_new );
    }
    if ( $class_plurals ne $class_plurals_new ) {
        $cfg_plugin->set_config_value( 'class_plurals', $class_plurals_new );
    }
    my @types;
    my @functions = qw( BlogID ID Name Body Keywords CreatedOn PeriodOn ModifiedOn AuthoredOn Column );
    for my $object ( @objects ) {
        if ( $object ne 'customobject' ) {
            my $prefix = $custom_objects->{ $object }->{ id };
            my $lc_prefix = lc( $prefix );
            my $plugin = MT->component( $object );
            my $model = MT->model( $object );
            if ( $plugin && $model ) {
                my $block_name = $model->class_plural;
                my $lc_block_prefix = lc( $block_name );
                my $core_tags = MT->registry( 'tags', 'block', $block_name );
                if (! $core_tags ) {
                    $registry->{ $lc_block_prefix } = sub {
                        my ( $ctx, $args, $cond ) = @_;
                        $args->{ class } = $object;
                        require CustomObject::Tags;
                        return CustomObject::Tags::_hdlr_customobjects( $ctx, $args, $cond );
                    };
                    my $folder_tag = MT->registry( 'tags', 'block', $prefix . 'folder' );
                    if (! $folder_tag ) {
                        $registry->{ $prefix . 'folder' } = sub { 
                            my ( $ctx, $args, $cond ) = @_;
                            require CustomObject::Tags;
                            return CustomObject::Tags::_hdlr_customobject_folder( $ctx, $args, $cond );
                        };
                    }
                    my $count_tag = MT->registry( 'tags', 'function', $block_name . 'Count' );
                    if (! $count_tag ) {
                        $registry_function->{ $lc_block_prefix . 'count' } = sub {
                            my ( $ctx, $args ) = @_;
                            $ctx->stash( 'tag', 'customobjectscount' );
                            $args->{ class } = $object;
                            require CustomObject::Tags;
                            return CustomObject::Tags::_hdlr_customobjects( $ctx, $args );
                        };
                    }
                    my $basename_tag = MT->registry( 'tags', 'function', $prefix . 'basename' );
                    if (! $basename_tag ) {
                        $registry_function->{ $prefix . 'basename' } = sub {
                            my ( $ctx, $args ) = @_;
                            $ctx->stash( 'tag', 'customobjectbasename' );
                            require CustomObject::Tags;
                            return CustomObject::Tags::_hdlr_customobject_basename( $ctx, $args );
                        };
                    }
                    my $folderlink_tag = MT->registry( 'tags', 'function', $prefix . 'folderlink' );
                    if (! $folderlink_tag ) {
                        $registry_function->{ $prefix . 'folderlink' } = sub {
                            my ( $ctx, $args ) = @_;
                            $ctx->stash( 'tag', 'customobjectfolderlink' );
                            $args->{ class } = $object;
                            require CustomObject::Tags;
                            return CustomObject::Tags::_hdlr_folder_link( $ctx, $args );
                        };
                    }
                    my $permalink_tag = MT->registry( 'tags', 'function', $prefix . 'permalink' );
                    if (! $permalink_tag ) {
                        $registry_function->{ $prefix . 'permalink' } = sub {
                            my ( $ctx, $args ) = @_;
                            $ctx->stash( 'tag', 'customobjectpermalink' );
                            require CustomObject::Tags;
                            return CustomObject::Tags::_hdlr_customobject_permalink( $ctx, $args );
                        };
                    }
                    for my $func ( @functions ) {
                        my $core_tag = MT->registry( 'tags', 'function', $prefix . $func );
                        if (! $core_tag ) {
                            my $tag_name = lc( $prefix . $func );
                            $registry_function->{ $tag_name } = sub {
                                my ( $ctx, $args ) = @_;
                                $ctx->stash( 'tag', 'customobject' . $func );
                                require CustomObject::Tags;
                                return CustomObject::Tags::_hdlr_customobject_column( $ctx, $args );
                            };
                        }
                    }
                    my $author_tag = MT->registry( 'tags', 'function', $prefix . 'AuthorDisplayName' );
                    if (! $author_tag ) {
                        $registry_function->{ $lc_prefix . 'authordisplayname' } = sub {
                            my ( $ctx, $args ) = @_;
                            require CustomObject::Tags;
                            return CustomObject::Tags::_hdlr_author_displayname( $ctx, $args );
                        };
                    }
                    my $label_tag = MT->registry( 'tags', 'function', $prefix . 'Label' );
                    if (! $label_tag ) {
                        $registry_function->{ $lc_prefix . 'label' } = sub {
                            my ( $ctx, $args ) = @_;
                            require CustomObject::Tags;
                            $args->{ component } = $object;
                            return CustomObject::Tags::_hdlr_customobject_label( $ctx, $args );
                        };
                    }
                    my $header_tag = MT->registry( 'tags', 'block', $block_name . 'Header' );
                    if (! $header_tag ) {
                        $registry->{ $lc_block_prefix . 'header' } = sub {
                            my ( $ctx, $args, $cond ) = @_;
                            require CustomObject::Tags;
                            return CustomObject::Tags::_hdlr_customobjects_header( $ctx, $args, $cond );
                        };
                    }
                    my $footer_tag = MT->registry( 'tags', 'block', $block_name . 'Footer' );
                    if (! $footer_tag ) {
                        $registry->{ $lc_block_prefix . 'footer' } = sub {
                            my ( $ctx, $args, $cond ) = @_;
                            require CustomObject::Tags;
                            return CustomObject::Tags::_hdlr_customobjects_footer( $ctx, $args, $cond );
                        };
                    }
                    my $object_tag = MT->registry( 'tags', 'block', $prefix );
                    if (! $object_tag ) {
                        $registry->{ $lc_block_prefix . 'object' } = sub {
                            my ( $ctx, $args, $cond ) = @_;
                            require CustomObject::Tags;
                            return CustomObject::Tags::_hdlr_customobject( $ctx, $args, $cond );
                        };
                    }
                    my $tags_tag = MT->registry( 'tags', 'block', $prefix . 'Tags' );
                    if (! $tags_tag ) {
                        $registry->{ $lc_prefix . 'tags' } = sub {
                            my ( $ctx, $args, $cond ) = @_;
                            require CustomObject::Tags;
                            return CustomObject::Tags::_hdlr_customobject_tags( $ctx, $args, $cond );
                        };
                    }
                    my $author_block_tag = MT->registry( 'tags', 'block', $prefix . 'Author' );
                    if (! $author_block_tag ) {
                        $registry->{ $lc_prefix . 'author' } = sub {
                            my ( $ctx, $args, $cond ) = @_;
                            require CustomObject::Tags;
                            return CustomObject::Tags::_hdlr_customobject_author( $ctx, $args, $cond );
                        };
                    }
                    my $if_tag_block_tag = MT->registry( 'tags', 'block', $prefix . 'IfTagged?' );
                    if (! $if_tag_block_tag ) {
                        $registry->{ $lc_prefix . 'iftagged?' } = sub {
                            my ( $ctx, $args, $cond ) = @_;
                            require CustomObject::Tags;
                            return CustomObject::Tags::_hdlr_if_customobject_tagged( $ctx, $args, $cond );
                        };
                    }
                }
                my $block_name_single = $model->class_type;
                my $lc_block_prefix_single = lc( $block_name_single );
                my $core_tags_single = MT->registry( 'tags', 'block', $block_name_single );
                if ( ! $core_tags_single ) {
                    $registry->{ $lc_block_prefix_single } = sub {
                        my ( $ctx, $args, $cond ) = @_;
                        $args->{ class } = $object;
                        require CustomObject::Tags;
                        return CustomObject::Tags::_hdlr_customobject( $ctx, $args, $cond );
                    };
                }
            }
        }
    }
    my @fields = MT->model( 'field' )->load( { customobject => 1 } );
    my $commercial = MT->component( 'commercial' );
    my $tags = $commercial->registry( 'tags' );
    for my $field ( @fields ) {
        my $tag = $field->tag;
        $tag = lc( $tag );
        my $field_type = $field->type;
        delete( $tags->{ function }->{ $tag } );
        if ( $field_type !~ /_multi$/ ) {
            $registry->{ $tag } = sub {
                my ( $ctx, $args, $cond ) = @_;
                require CustomObject::Tags;
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
                if ( $field_type =~ /_group$/ ) {
                    my $field_type_org = $field_type;
                    $field_type =~ s/_group$//;
                    $args->{ group_id } = $value;
                    $args->{ class } = $field_type;
                    $field_type = $field_type_org;
                    return CustomObject::Tags::_hdlr_customobjects( $ctx, $args, $cond );
                }
                $args->{ id } = $value;
                $args->{ class } = $field_type;
                return CustomObject::Tags::_hdlr_customobject( $ctx, $args, $cond );
            };
        } else {
            $field_type =~ s/_multi$//;
            $registry->{ $tag } = sub {
                my ( $ctx, $args, $cond ) = @_;
                require CustomObject::Tags;
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
                $args->{ class } = $field_type;
                return CustomObject::Tags::_hdlr_customobjects( $ctx, $args, $cond );
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
    my ( $meth, $key, $label, $counter ) = @_;
    $key = 'customobject' unless $key;
    $label = 'CustomObject' unless $label;
    $counter = 2022 unless $counter;
    my $multi_counter = $counter + 1;
    my $group_counter = $counter + 2;
    my $customfield_types = {
        $key => {
            label             => $label,
            column_def        => 'vinteger_idx',
            order             => $counter,
            no_default        => 1,
            field_html        => \&_field_html,
            field_html_params => \&_field_html_params,
        },
        $key . '_multi' => {
            label             => 'Multiple ' . $label,
            column_def        => 'vchar_idx',
            order             => $multi_counter,
            no_default        => 1,
            field_html        => \&_field_html_multi,
            field_html_params => \&_field_html_params_multi,
        },
        $key . '_group' => {
            label             => $label . ' Group',
            column_def        => 'vinteger_idx',
            order             => $group_counter,
            no_default        => 1,
            field_html        => \&_field_html_group,
            field_html_params => \&_field_html_params_group,
        },
    };
}

# sub _options_field {
#     return '';
# }

sub _field_html {
    return <<'MTML';
<__trans_section component="CustomObject">
<span class="field-content" id="field_value-<mt:var name="field_id" escape="html">" style="padding:0px;display:block;margin-bottom:6px;line-height:1.4;">
<mt:if name="object_exists">
<span id="obj-<mt:var name="field_id" escape="html">-<mt:var name="id" escape="html">" style="margin-right:12px;white-space:nowrap;">
<mt:var name="name" escape="html"> (ID:<mt:var name="id" escape="html">)
<a href="javascript:;" onclick="jQuery(this).parent().remove();remove_val('<mt:var name="id" escape="html">','<mt:var name="field_id" escape="html">');"><img src="<mt:var name="static_uri">images/status_icons/close.gif" alt="<__trans phrase="Delete">" title="<__trans phrase="Delete">" /></a>
</span>
</mt:if>
</span>
<MTCustomObjectFieldScope class="$class" setvar="fieldscope">
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
        <a href="<mt:var name="script_url">?__mode=list_customobject&amp;blog_id=<mt:var name="field_blog_id">&amp;dialog_view=1&amp;edit_field=<mt:var name="field_id">&amp;costomobject_select=1&amp;class=<mt:var name="class">" class="mt-open-dialog button">
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
<__trans_section component="CustomObject">
<span class="field-content" id="field_value-<mt:var name="field_id" escape="html">" style="padding:0px;display:block;margin-bottom:6px;line-height:1.4;">
<mt:if name="object_exists">
<mtloop name="object_loop">
<span id="obj-<mt:var name="field_id" escape="html">-<mt:var name="id" escape="html">" style="margin-right:12px;white-space:nowrap;">
<mt:var name="name" escape="html"> (ID:<mt:var name="id" escape="html">)
<a href="javascript:;" onclick="jQuery(this).parent().remove();remove_val_multi('<mt:var name="id" escape="html">','<mt:var name="field_id" escape="html">');"><img src="<mt:var name="static_uri">images/status_icons/close.gif" alt="<__trans phrase="Delete">" title="<__trans phrase="Delete">" /></a>
</span>
</mt:loop>
</mt:if>
</span>
<MTCustomObjectFieldScope class="$class" setvar="fieldscope">
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
        <a href="<mt:var name="script_url">?__mode=list_customobject&amp;blog_id=<mt:var name="field_blog_id">&amp;dialog_view=1&amp;edit_field=<mt:var name="field_id">&amp;costomobject_select=1&amp;class=<mt:var name="class">" class="mt-open-dialog button">
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
<__trans_section component="CustomObject">
<span class="field-content" id="field_value-<mt:var name="field_id" escape="html">" style="padding:0px;display:block;margin-bottom:6px;line-height:1.4;">
<mt:if name="object_exists">
<span id="obj-<mt:var name="field_id" escape="html">-<mt:var name="id" escape="html">" style="margin-right:12px;white-space:nowrap;">
<mt:var name="name" escape="html"> (ID:<mt:var name="id" escape="html">)
<a href="javascript:;" onclick="jQuery(this).parent().remove();remove_val('<mt:var name="id" escape="html">','<mt:var name="field_id" escape="html">');"><img src="<mt:var name="static_uri">images/status_icons/close.gif" alt="<__trans phrase="Delete">" title="<__trans phrase="Delete">" /></a>
</span>
</mt:if>
</span>
<MTCustomObjectFieldScope class="$class" setvar="fieldscope">
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
        <a href="<mt:var name="script_url">?__mode=list_customobjectgroup&amp;blog_id=<mt:var name="field_blog_id">&amp;dialog_view=1&amp;edit_field=<mt:var name="field_id">&amp;costomobject_select=1&amp;class=<mt:var name="class">" class="mt-open-dialog button">
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
    my $plugin = MT->component( $key );
    if ( $plugin ) {
        my $label = 'CustomObject';
        if ( $key ne 'customobject' ) {
            $label = $plugin->name;
        }
        $param->{ field_label } = $plugin->translate( 'Select [_1]', $plugin->translate( $label ) );
        $param->{ class } = $key;
    }
    $param->{ field_class } = $key;
    if ( my $field_id = $param->{ field_value } ) {
        require CustomObject::CustomObject;
        my $obj = CustomObject::CustomObject->load( $field_id );
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
    $key =~ s/_multi$//;
    my $plugin = MT->component( $key );
    if ( $plugin ) {
        my $label = 'CustomObject';
        if ( $key ne 'customobject' ) {
            $label = $plugin->name;
        }
        $param->{ field_label } = $plugin->translate( 'Select [_1]', $plugin->translate( 'Multiple ' . $label ) );
        $param->{ class } = $key;
    }
    $param->{ field_class } = $key;
    if ( my $field_id = $param->{ field_value } ) {
        require CustomObject::CustomObject;
        my @ids = split( /,/, $field_id );
        my @objects = CustomObject::CustomObject->load( { id => \@ids } );
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
    my $orig_key = $key;
    my $class_key = $key;
    $key =~ s/_group$//;
    $class_key =~ s/_group$/group/;
    my $plugin = MT->component( $key );
    if ( $plugin ) {
        my $label = 'CustomObject';
        if ( $key ne 'customobject' ) {
            $label = $plugin->name;
        }
        $param->{ field_label } = $plugin->translate( 'Select [_1]', $plugin->translate( $label . ' Group' ) );
        $param->{ class } = $class_key;
    }
    $param->{ field_class } = $orig_key;
    if ( my $field_id = $param->{ field_value } ) {
        require CustomObject::CustomObjectGroup;
        my $obj = CustomObject::CustomObjectGroup->load( $field_id );
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