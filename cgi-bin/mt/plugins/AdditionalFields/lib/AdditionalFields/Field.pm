package AdditionalFields::Field;

use strict;
use lib qw( addons/Commercial.pack/lib );
use CustomFields::Util qw( get_meta );
use MT::Util qw( trim );

sub _init_tags {
    my $app = MT->instance();
    return if ( ref $app ) eq 'MT::App::Upgrader';
    require MT::Request;
    my $r = MT::Request->instance;
    my $cache = $r->cache( 'plugin-additionalfields-init' );
    return 1 if $cache;
    $r->cache( 'plugin-additionalfields-init', 1 );
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
    my $core = MT->component( 'AdditionalFields' );
    my $registry = $core->registry( 'tags', 'block' );
    my @fields = MT->model( 'field' )->load( { type => [ 'entry', 'entry_multi', 'page', 'page_multi', 'checkbox_multi', 'dropdown_multi' ] } );
    my $commercial = MT->component( 'Commercial' );
    my $tags = $commercial->registry( 'tags' );
    for my $field ( @fields ) {
        my $field_type = $field->type;
        my $tag = $field->tag;
        $tag = lc( $tag );
        delete( $tags->{ function }->{ $tag } );
        if ( $field_type !~ /multi/ ) {
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
                my $class;
                if ( $field_type =~ /page/ ) {
                    $class = 'page';
                } elsif ( $field_type =~ /entry/ ) {
                    $class = 'entry';
                }
                if ( $class ) {
                    $args->{ id } = $value;
                    $args->{ class } = $class;
                    require AdditionalFields::Tags;
                    return AdditionalFields::Tags::_hdlr_related_entry( $ctx, $args, $cond );
                } else {
                    $value =~ s/^,//;
                    $value =~ s/,$//;
                    return '' unless $value;
                    my @options = split( /,/, $value );
                    my $tokens = $ctx->stash( 'tokens' );
                    my $builder = $ctx->stash( 'builder' );
                    my $i = 0; my $res = '';
                    my $odd = 1; my $even = 0;
                    my $glue = $args->{ glue };
                    for my $opt ( @options ) {
                        local $ctx->{ __stash }->{ vars }->{ __value__ } = $opt;
                        local $ctx->{ __stash }->{ vars }->{ __first__ } = ( $i == 0 );
                        local $ctx->{ __stash }->{ vars }->{ __counter__ } = $i + 1;
                        local $ctx->{ __stash }->{ vars }->{ __odd__ } = $odd;
                        local $ctx->{ __stash }->{ vars }->{ __even__ } = $even;
                        local $ctx->{ __stash }->{ vars }->{ __last__ } = ( !defined( $options[ $i + 1 ] ) );
                        my $out = $builder->build( $ctx, $tokens, $cond );
                        if ( !defined( $out ) ) { return $ctx->error( $builder->errstr ) };
                        $res .= $glue if defined $glue && length( $res ) && length( $out );
                        $res .= $out;
                        if ( $odd == 1 ) { $odd = 0 } else { $odd = 1 };
                        if ( $even == 1 ) { $even = 0 } else { $even = 1 };
                        $i++;
                    }
                    return $res;
                }
            };
        } elsif ( ( $field_type eq 'page_multi' ) || ( $field_type eq 'entry_multi' ) ) {
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
                my $class = 'entry';
                if ( $field_type =~ /page/ ) {
                    $class = 'page';
                }
                $args->{ ids } = $value;
                $args->{ class } = $class;
                require AdditionalFields::Tags;
                return AdditionalFields::Tags::_hdlr_related_entries( $ctx, $args, $cond );
            };
        } else {
            $registry->{ $tag } = sub { 
                my ( $ctx, $args, $cond ) = @_;
                require CustomFields::Template::ContextHandlers;
                my $field = CustomFields::Template::ContextHandlers::find_field_by_tag( $ctx )
                    or return _no_field( $ctx );
                local $ctx->{ __stash }{ field } = $field;
                my $value = CustomFields::Template::ContextHandlers::_hdlr_customfield_value( @_ );
                if ( $value ) {
                    $value =~ s/^,//;
                    $value =~ s/,$//;
                }
                return '' unless $value;
                if ( $args->{ raw } ) {
                    return $value;
                }
                my @options = split( /,/, $value );
                my $selectables = $field->options;
                $selectables =~ s/^,//;
                $selectables =~ s/,$//;
                my @selectables = split( /,/, $selectables );
                @options = grep {
                    my $opt = $_;
                    grep {
                        $opt eq $_;
                    } @selectables;
                } @options;
                my $tokens = $ctx->stash( 'tokens' );
                my $builder = $ctx->stash( 'builder' );
                my $i = 0; my $res = '';
                my $odd = 1; my $even = 0;
                my $glue = $args->{ glue };
                for my $opt ( @options ) {
                    local $ctx->{ __stash }->{ vars }->{ __value__ } = $opt;
                    local $ctx->{ __stash }->{ vars }->{ __first__ } = ( $i == 0 );
                    local $ctx->{ __stash }->{ vars }->{ __counter__ } = $i + 1;
                    local $ctx->{ __stash }->{ vars }->{ __odd__ } = $odd;
                    local $ctx->{ __stash }->{ vars }->{ __even__ } = $even;
                    local $ctx->{ __stash }->{ vars }->{ __last__ } = ( !defined( $options[ $i + 1 ] ) );
                    my $out = $builder->build( $ctx, $tokens, $cond );
                    if ( !defined( $out ) ) { return $ctx->error( $builder->errstr ) };
                    $res .= $glue if defined $glue && length( $res ) && length( $out );
                    $res .= $out;
                    if ( $odd == 1 ) { $odd = 0 } else { $odd = 1 };
                    if ( $even == 1 ) { $even = 0 } else { $even = 1 };
                    $i++;
                }
                return $res;
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

sub _pre_save_field {
    my ( $cb, $app, $obj, $original ) = @_;
    if ( ( $app->param( 'type' ) eq 'checkbox_multi' ) ||
         ( $app->param( 'type' ) eq 'dropdown_multi' ) ) {
        my $option = $app->param( 'options' );
        my @options = split( ',', $option );
        my @opts;
        for my $opt ( @options ) {
            push ( @opts, trim( $opt ) );
        }
        my @default_vals = $app->param( 'default' );
        my @default;
        for my $value ( @default_vals ) {
            $value = trim( $value );
            if ( grep( /^$value$/, @opts ) ) {
                push ( @default, $value );
            }
        }
        my $default_vals = '';
        if ( scalar @default ) {
            $default_vals = join( ',', @default );
        }
        $default_vals = ',' . $default_vals . ',';
        $obj->default( $default_vals );
    }
    return 1;
}

sub _customfield_types {
    my $customfield_types = {
        checkbox_multi => {
            label             => 'Multiple Checkbox',
            column_def        => 'vchar',
            order             => 301,
            options_delimiter => ',',
            options_field     => \&_options_field,
            field_html        => \&_field_html_cb,
            field_html_params => \&_field_html_params_mv,
            default_value => '',
        },
        dropdown_multi => {
            label             => 'Multiple Drop Down Menu',
            column_def        => 'vchar',
            order             => 601,
            options_delimiter => ',',
            options_field     => \&_options_field,
            field_html        => \&_field_html_dd,
            field_html_params => \&_field_html_params_mv,
            default_value => '',
        },
        entry => {
            label             => 'Entry',
            column_def        => 'vinteger_idx',
            order             => 2018,
            no_default        => 1,
            # options_delimiter => ',',
            # options_field     => \&_options_field,
            field_html        => \&_field_html,
            field_html_params => \&_field_html_params,
        },
        entry_multi => {
            label             => 'Multiple Entry',
            column_def        => 'vchar_idx',
            order             => 2019,
            no_default        => 1,
            # options_delimiter => ',',
            # options_field     => \&_options_field,
            field_html        => \&_field_html_multi,
            field_html_params => \&_field_html_params_multi,
        },
        page => {
            label             => 'Page',
            column_def        => 'vinteger_idx',
            order             => 2021,
            no_default        => 1,
            # options_delimiter => ',',
            # options_field     => \&_options_field,
            field_html        => \&_field_html,
            field_html_params => \&_field_html_params,
        },
        page_multi => {
            label             => 'Multiple Page',
            column_def        => 'vchar_idx',
            order             => 2022,
            no_default        => 1,
            # options_delimiter => ',',
            # options_field     => \&_options_field,
            field_html        => \&_field_html_multi,
            field_html_params => \&_field_html_params_multi,
        },
        ninteger => {
            label             => 'Text(Integer)',
            column_def        => 'vinteger_idx',
            order             => 250,
            no_default        => 1,
            field_html        => \&_field_html_numeric,
        },
        nfloat => {
            label             => 'Text(Float)',
            column_def        => 'vfloat_idx',
            order             => 251,
            no_default        => 1,
            field_html        => \&_field_html_numeric,
        },
        password => {
            label             => 'Password',
            column_def        => 'vchar_idx',
            order             => 255,
            no_default        => 1,
            field_html        => \&_field_html_password,
        },
        editor_textarea => {
            label      => 'Multi-Line with editor',
            field_html => {
                default => q{
                    <textarea name="<mt:var name="field_name" escape="html">" id="<mt:var name="field_id">" class="text high"><mt:var name="field_value" escape="html"></textarea>
                    <script type="text/javascript">
                        jQuery(function($) {
                            if (! MT || ! MT.EditorManager) {
                                return;
                            }

                            var id = '<mt:var name="field_id">';
                            var $field = $('#' + id);
                            if ($field.data('mt-editor')) {
                                return;
                            }

                            new MT.EditorManager(id);
                        });
                    </script>
                },
            },
            column_def => 'vclob',
            order      => 201,
        },
    };
}

sub _options_field {
    return <<'MTML';
<input type="text" name="options" value="<mt:var name="options" escape="html">" id="options" class="text full-width" />
<p class="hint"><__trans phrase="Please enter all allowable options for this field as a comma delimited list"></p>
MTML
}

sub _field_html_cb {
    return <<'MTML';
<__trans_section component="AdditionalFields">
<div>
<mt:unless name="edit_field">
<input type="hidden" name="<mt:var name="field_id">" id="<mt:var name="field_id">" value="<mt:if name="field_value"><mt:var name="field_value"></mt:if>" />
</mt:unless>
<mt:loop name="multi_field_loop">
<label><input <mt:unless name="edit_field">id="<mt:var name="field_id">-<mt:var name="__counter__">" onchange="script_field_html_cb( this, '<mt:var name="field_id">', <mt:var name="multi_field_count"> );"</mt:unless> type="checkbox" name="<mt:var name="field_id">" value="<mt:var name="item_value">" <mt:if name="checked">checked="checked"</mt:if> /> <mt:var name="item_value"></label>
</mt:loop>
<mt:unless name="edit_field">
<mt:IfNotSent key="script_field_html_cb">
<script type="text/javascript">
    function script_field_html_cb( input, basename, count ) {
        var field_array = new Array();
        var vals;
        for ( i = 1; i <= count; i++ ) {
            var ele = getByID( basename + '-' + i );
            if ( ele.checked ) {
                field_array.push( ele.value );
            }
        }
        vals = field_array.join( ',' );
        vals = ',' + vals + ',';
        getByID( basename ).value = vals;
    }
</script>
</mt:IfNotSent>
</mt:unless>
</div>
</__trans_section>
MTML
}

sub _field_html_dd {
    return <<'MTML';
<__trans_section component="AdditionalFields">
<div>
<mt:unless name="edit_field">
<input type="hidden" name="<mt:var name="field_id">" id="<mt:var name="field_id">" value="<mt:if name="field_value"><mt:var name="field_value"></mt:if>" />
</mt:unless>
<select name="<mt:var name="field_id">" multiple="multiple" size="<mt:var name="menusize">" style="height: auto" onchange="script_field_html_dd( this, '<mt:var name="field_id">' );">
<mt:loop name="multi_field_loop">
<option value="<mt:var name="item_value">" <mt:if name="checked">selected="selected"</mt:if>><mt:var name="item_value"></option>
</mt:loop>
</select>
<mt:unless name="edit_field">
<mt:IfNotSent key="script_field_html_dd">
<script type="text/javascript">
    function script_field_html_dd( dropdown, basename ) {
        var field_array = new Array();
        var vals;
        for ( var i = 0 ; i < dropdown.length; i++ ) {
            if ( dropdown[i].selected ) {
                field_array.push( dropdown[i].value );
            }
        }
        vals = field_array.join( ',' );
        vals = ',' + vals + ',';
        getByID( basename ).value = vals;
    }
</script>
</mt:IfNotSent>
</mt:unless>
</div>
</__trans_section>
MTML
}

sub _field_html_params_mv {
    my ( $key, $tmpl, $param ) = @_;
    my $app = MT->instance;
    if ( my $option = $param->{ options } ) {
        my $field_value = $param->{ field_value };
        if ( $field_value ) {
            $field_value =~ s/^,//;
            $field_value =~ s/,$//;
        }
        my @default = split( ',', $field_value );
        my @field_loop;
        my @options = split( /,/, $option );
        my $i = 1;
        for my $value ( @options ) {
            $value = trim( $value );
            my $checked;
            if ( $field_value && ( grep( /^$value$/, @default ) ) ) {
                $checked = 1;
            }
            push ( @field_loop, { item_value => $value,
                                  checked => $checked,
                                  serlected => $checked,
                                  '__counter__' => $i } );
            $i++;
        }
        $param->{ multi_field_loop } = \@field_loop;
        $param->{ multi_field_count } = scalar( @options );
    }
    if ( $app->param( '_type' ) eq 'field' ) {
        $param->{ edit_field } = 1;
    }
    $param->{ menusize } = MT->config( 'MultipleDropDownSize' );
    return 1;
}

sub _field_html {
    return <<'MTML';
<__trans_section component="AdditionalFields">
<span class="field-content" id="field_value-<mt:var name="field_id" escape="html">" style="padding:0px;display:block;margin-bottom:6px;line-height:1.4;">
<mt:if name="object_exists">
<span id="obj-<mt:var name="field_id" escape="html">-<mt:var name="id" escape="html">" style="margin-right:12px;white-space:nowrap;">
<mt:var name="title" escape="html"> (ID:<mt:var name="id" escape="html">)
<a href="javascript:;" onclick="jQuery(this).parent().remove();remove_val('<mt:var name="id" escape="html">','<mt:var name="field_id" escape="html">');"><img src="<mt:var name="static_uri">images/status_icons/close.gif" alt="<__trans phrase="Delete">" title="<__trans phrase="Delete">" /></a>
</span>
</mt:if>
</span>
<mt:if name="entry_class" eq="entry">
<MTEntryFieldScope setvar="fieldscope">
<mt:else>
<MTPageFieldScope setvar="fieldscope">
</mt:if>
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
        <a href="<mt:var name="script_url">?__mode=entries_dialog&amp;blog_id=<mt:var name="field_blog_id">&amp;dialog_view=1&amp;edit_field=<mt:var name="field_id">&amp;class=<mt:var name="entry_class">" class="mt-open-dialog button">
<mt:if name="entry_class" eq="entry">
        <__trans phrase="Select Entry">
<mt:else>
        <__trans phrase="Select Page">
</mt:if>
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
<__trans_section component="AdditionalFields">
<span class="field-content" id="field_value-<mt:var name="field_id" escape="html">" style="padding:0px;display:block;margin-bottom:6px;line-height:1.4;">
<mt:if name="object_exists">
<mtloop name="object_loop">
<span id="obj-<mt:var name="field_id" escape="html">-<mt:var name="id" escape="html">" style="margin-right:12px;white-space:nowrap;">
<mt:var name="title" escape="html"> (ID:<mt:var name="id" escape="html">)
<a href="javascript:;" onclick="jQuery(this).parent().remove();remove_val_multi('<mt:var name="id" escape="html">','<mt:var name="field_id" escape="html">');"><img src="<mt:var name="static_uri">images/status_icons/close.gif" alt="<__trans phrase="Delete">" title="<__trans phrase="Delete">" /></a>
</span>
</mt:loop>
</mt:if>
</span>
<mt:if name="entry_class" eq="entry">
<MTEntryFieldScope setvar="fieldscope">
<mt:else>
<MTPageFieldScope setvar="fieldscope">
</mt:if>
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
        <a href="<mt:var name="script_url">?__mode=entries_dialog&amp;blog_id=<mt:var name="field_blog_id">&amp;dialog_view=1&amp;edit_field=<mt:var name="field_id">&amp;class=<mt:var name="entry_class">" class="mt-open-dialog button">
<mt:if name="entry_class" eq="entry">
        <__trans phrase="Select Entry">
<mt:else>
        <__trans phrase="Select Page">
</mt:if>
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

sub _field_html_numeric {
    return <<'MTML';
                <input type="text" style="width:100px" name="<mt:var name="field_name" escape="html">" id="<mt:var name="field_id">" value="<mt:var name="field_value" escape="html" _default="0">" class="text num full-width ti" />
MTML
}

sub _field_html_password {
    return <<'MTML';
                <input type="password" style="width:100%" name="<mt:var name="field_name" escape="html">" id="<mt:var name="field_id">" value="<mt:var name="field_value" escape="html">" class="text full-width ti" />
MTML
}

sub _field_html_params {
    my ( $key, $tmpl, $param ) = @_;
    my $class = 'entry';
    if ( $key =~ /page/ ) {
        $class = 'page';
    }
    $param->{ entry_class } = $class;
    if ( my $field_id = $param->{ field_value } ) {
        my $obj = MT->model( $class )->load( $field_id );
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
    my $class = 'entry';
    if ( $key =~ /page/ ) {
        $class = 'page';
    }
    $param->{ entry_class } = $class;
    if ( my $field_id = $param->{ field_value } ) {
        my @ids = split( /,/, $field_id );
        my @objects = MT->model( $class )->load( { id => \@ids } );
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

1;
