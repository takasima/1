# Movable Type (r) (C) 2007-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

# Original Copyright (c) 2005-2007 Arvind Satyanarayan

package CustomFields::App::CMS;

use strict;
use CustomFields::Util qw( get_meta save_meta field_loop _get_html );
use MT::Util qw( dirify encode_js );

sub load_system_filters {
    my $plugin  = shift;
    my $app     = MT->app;
    my $blog_id = $app->param('blog_id') || undef;
    my %filters;
    my @filters_to_sort;
    my $objects = MT->registry('customfield_objects');
    my $blog;
    if ( defined $blog_id ) {
        $blog = $app->blog;
        $blog = $app->model('blog')->load($blog_id)
            unless $blog;
    }

    my $order = 0;
    my %ordered_objects;
    $ordered_objects{$_} = $order += 100 for qw(
        entry page comment file audio video image category folder template
        blog website user
    );

    foreach my $object ( keys %$objects ) {
        my $context = $objects->{$object}{context};
        if ( ref $context ) {
            if ($blog) {
                next
                    if $blog->is_blog && !( grep { $_ eq 'blog' } @$context );
                next
                    if !$blog->is_blog
                        && !( grep { $_ eq 'website' } @$context );
            }
            else {
                next unless grep { $_ eq 'system' } @$context;
            }
        }
        elsif ( $context eq 'system' && $blog_id ) {
            next;
        }
        elsif ( $context eq 'blog' && !$blog_id ) {
            next;
        }

        my $class  = MT->model($object);
        my $filter = {
            label => sub {
                $plugin->translate( '[_1] Fields', $class->class_label );
            },
            items => [
                {   type => 'obj_type',
                    args => { value => $object },
                }
            ],
        };

        if ( my $o = $ordered_objects{$object} ) {
            $filter->{order} = $o;
            $filters{"cf_list_$object"} = $filter;
        }
        else {
            $filter->{type} = "cf_list_$object";
            push( @filters_to_sort, $filter );
        }
    }

    @filters_to_sort
        = sort { $a->{label}->() cmp $b->{label}->() } @filters_to_sort;
    for my $filter (@filters_to_sort) {
        $order += 100;
        $filter->{order} = $order;
        $filters{ delete $filter->{type} } = $filter;
    }

    return \%filters;
}

sub object_filter_options {
    my $prop    = shift;
    my $app     = MT->app;
    my $blog_id = $app->param('blog_id') || undef;
    my @options;
    my $objects = MT->registry('customfield_objects');
    my $blog;
    if ( defined $blog_id ) {
        $blog = $app->blog;
        $blog = $app->model('blog')->load($blog_id)
            unless $blog;
    }
    my $scope = !$blog ? 'system' : $blog->is_blog ? 'blog' : 'website';
    foreach my $object ( keys %$objects ) {
        my $context = $objects->{$object}{context};
        my %context;
        %context
            = map { $_ => 1 } ( ref $context ? (@$context) : ($context) );
        next if !$context{all} && !$context{$scope};
        my $class = MT->model($object);
        push @options, {
            label => sub {
                MT->translate( $class->class_label );
            },
            value => $object,
        };
    }
    return \@options;
}

sub load_customfield_types {
    my $customfield_types = {

        # type_key => {
        #   label => ' ',
        #   order => 999,
        #   field_html => ''
        #   options_field => '',
        #   options_delimiter => '',
        #   default_value => '',
        #   column_def => ''
        # },
        'text' => {
            label      => 'Single-Line Text',
            field_html => q{
                <input type="text" name="<mt:var name="field_name" escape="html">" id="<mt:var name="field_id">" class="text" value="<mt:var name="field_value" escape="html">" />
            },
            column_def => 'vchar_idx',
            order      => 100,
        },
        'textarea' => {
            label      => 'Multi-Line Text',
            field_html => {
                default => q{
                    <textarea name="<mt:var name="field_name" escape="html">" id="<mt:var name="field_id">" class="text high"><mt:var name="field_value" escape="html"></textarea>
                },

                # author => q{
                #     <!-- code here if different for 'author' object -->
                # },
            },
            column_def => 'vclob',
            order      => 200,
        },
        'checkbox' => {
            label      => 'Checkbox',
            field_html => q{
                <input type="hidden" name="<mt:var name="field_name" escape="html">_cb_beacon" value="1" /><input type="checkbox" name="<mt:var name="field_name" escape="html">" value="1" id="<mt:var name="field_id">"<mt:if name="field_value"> checked="checked"</mt:if> class="cb" /> <label class="hint" for="<mt:var name="field_id">"><mt:var name="description" escape="html"></label>
            },
            column_def => 'vinteger_idx',
            order      => 300,
        },
        'url' => {
            label      => 'URL',
            field_html => q{
                <input type="text" name="<mt:var name="field_name" escape="html">" id="<mt:var name="field_id">" class="text" value="<mt:var name="field_value" escape="html">" />
            },
            default_value => 'http://',
            column_def    => 'vchar',
            order         => 400,
        },
        'datetime' => {
            label             => 'Date and Time',
            field_html        => 'date-picker.tmpl',
            field_html_params => sub {
                my ( $key, $tmpl_key, $tmpl_param ) = @_;

                my $blog;
                if ( my $blog_id = $tmpl_param->{blog_id} ) {
                    $blog = MT->model('blog')->load($blog_id);
                }
                my $ts 
                    = $tmpl_param->{value}
                    || $tmpl_param->{field_value}
                    || '';
                if ( ref $ts ) {
                    $tmpl_param->{'date'} = $ts->{'date'};
                    $tmpl_param->{'time'} = $ts->{'time'};
                    return;
                }
                $ts =~ s/\D//g;

                my $app = MT->instance->isa('MT::App') ? MT->instance : undef;
                if ($ts) {
                    $tmpl_param->{date} = MT::Util::format_ts(
                        "%Y-%m-%d",
                        $ts,
                        $blog,
                        $app && $app->user
                        ? $app->user->preferred_language
                        : undef
                    );
                    $tmpl_param->{time} = MT::Util::format_ts(
                        "%H:%M:%S",
                        $ts,
                        $blog,
                        $app && $app->user
                        ? $app->user->preferred_language
                        : undef
                    );
                }
            },
            options_field => q{
                <__trans phrase="Show">: <select name="options" id="options">
                    <option value="datetime"<mt:if name="options" eq="datetime"> selected="selected"</mt:if>><__trans phrase="Date & Time"></option>
                    <option value="date"<mt:if name="options" eq="date"> selected="selected"</mt:if>><__trans phrase="Date Only"></option>
                    <option value="time"<mt:if name="options" eq="time"> selected="selected"</mt:if>><__trans phrase="Time Only"></option>
                </select>
            },
            no_default => 1,
            order      => 500,
            column_def => 'vdatetime_idx'
        },
        'select' => {
            label      => 'Drop Down Menu',
            field_html => q{
                    <select name="<mt:var name="field_name" escape="html">" id="<mt:var name="field_id">" class="se" mt:watch-change="1">
                        <mt:loop name="option_loop">
                            <option value="<mt:var name="option" escape="html">"<mt:if name="is_selected"> selected="selected"</mt:if>><mt:var name="label" escape="html"></option>
                        </mt:loop>
                    </select>
            },
            options_field => q{
                <input type="text" name="options" value="<mt:var name="options" escape="html">" id="options" class="text" />
                <p class="hint"><__trans phrase="Please enter all allowable options for this field as a comma delimited list"></p>
            },
            options_delimiter => ',',
            column_def        => 'vchar_idx',
            order             => 600,
        },
        'radio' => {
            label      => 'Radio Buttons',
            field_html => q{
                <ul class="custom-field-radio-list">
                <mt:loop name="option_loop">
                    <li><input type="radio" name="<mt:var name="field_name" escape="html">" value="<mt:var name="option" escape="html">" id="<mt:var name="field_id">_<mt:var name="__counter__">"<mt:if name="is_selected"> checked="checked"</mt:if> class="rb" /> <label for="<mt:var name="field_id">_<mt:var name="__counter__">"><mt:var name="label" escape="html"></label></li>
                </mt:loop>
                </ul>
            },
            options_field => q{
                <input type="text" name="options" value="<mt:var name="options" escape="html">" id="options" class="text" />
                <p class="hint"><__trans phrase="Please enter all allowable options for this field as a comma delimited list"></p>
            },
            options_delimiter => ',',
            column_def        => 'vchar_idx',
            order             => 700,
        },
        'embed' => {
            label      => 'Embed Object',
            field_html => {
                default => q{
                    <textarea name="<mt:var name="field_name" escape="html">" id="<mt:var name="field_id">" class="text high"><mt:var name="field_value" escape="html"></textarea>
                },
            },
            column_def => 'vclob',
            order      => 800,
            validate   => \&sanitize_embed,
        },
        'post_type' => {
            label             => 'Post Type',
            condition         => sub { MT->app->mode eq 'view' },
            field_html_params => sub {
                my ( $key, $tmpl_key, $tmpl_param ) = @_;
                $tmpl_param->{field_value} = MT->app->param('post_type')
                    || $tmpl_param->{object_type}
                    unless defined $tmpl_param->{field_value};
            },
            field_html =>
                q{<input type="hidden" name="customfield_post_type" value="<$mt:var name="field_value" escape="html"$>" />
                <ul id="entry-types">
                    <mt:loop name="post_type_loop">
                    <li id="entry-<$mt:var name="type" escape="html"$>"<mt:if name="type" eq="$field_value"> class="active"</mt:if>><a href="#" onclick="return updateEntryFields('<$mt:var name="type" escape="js"$>')" title="<$mt:var name="label" escape="html"$>"><$mt:var name="label" escape="html"$></a></li>
                    </mt:loop>
                </ul>},
            column_def  => 'vchar_idx',
            show_column => 0,
        },
    };

    # Add asset choosers
    require MT::Asset;
    my $asset_types = MT::Asset->class_labels;
    my @asset_types = sort { $asset_types->{$a} cmp $asset_types->{$b} }
        keys %$asset_types;

    my $order = 900;
    foreach my $a_type (@asset_types) {
        my $asset_type = $a_type;
        ($asset_type) = $a_type =~ /^asset\.(\w+)/;
        next unless $asset_type;
        $customfield_types->{$asset_type} = {
            label => sub { MT::Asset->class_handler($a_type)->class_label },
            field_html        => 'asset-chooser.tmpl',
            field_html_params => sub {
                $_[2]->{asset_type}       = $asset_type;
                $_[2]->{asset_type_label} = MT->translate($asset_type);
            },
            asset_type => $a_type,
            no_default => 1,
            column_def => 'vclob',
            order      => $order,
            context    => [ 'website', 'blog' ],
            sanitize   => \&MT::Util::sanitize_asset,
        };
        $order += 100;
    }

    return $customfield_types;
}

sub edit_field {
    my ( $app, $param ) = @_;
    my $q      = $app->param;
    my $plugin = $app->component("Commercial");

    my $blog = $app->blog;
    my $blog_id = $blog ? $blog->id : 0;
    return $app->permission_denied()
        if !$app->user->is_superuser && !$blog_id;
    return $app->permission_denied() if !$app->can_do('administer_blog');
    my $id = $app->param('id');

    my ( @obj_types, @types_loop );

    require CustomFields::Field;
    for my $key ( @{ CustomFields::Field->column_names() } ) {
        if ( my $val = $q->param($key) ) {
            $param->{$key} = $val;
        }
    }
    $param->{object_label} = CustomFields::Field->class_label;

    my $obj_type = $q->param('obj_type');

    if ($id) {
        my $field
            = CustomFields::Field->load( { blog_id => $blog_id, id => $id } );
        return $app->return_to_dashboard( redirect => 1 ) if !$field;
        $obj_type ||= $field->obj_type;
        while ( my ( $key, $val ) = each %{ $field->column_values() } ) {
            $param->{$key} ||= $val;
        }
    }

    $param->{basename_limit} = ( $blog ? $blog->basename_limit : 0 ) || 30;

    my $customfield_objs = $app->registry('customfield_objects');
    my @cf_obj_keys      = sort {
        ( $customfield_objs->{$a}{order} || 0 )
            <=> ( $customfield_objs->{$b}{order} || 0 )
        }
        keys %$customfield_objs;

    foreach my $key (@cf_obj_keys) {
        my $context = $customfield_objs->{$key}->{context};
        if ( ref $context ) {
            if ($blog) {
                next
                    if $blog->is_blog && !( grep { $_ eq 'blog' } @$context );
                next
                    if !$blog->is_blog
                        && !( grep { $_ eq 'website' } @$context );
            }
            else {
                next unless grep { $_ eq 'system' } @$context;
            }
        }
        elsif ( $context eq 'system' && $blog_id ) {
            next;
        }
        elsif ( $context eq 'blog' && !$blog_id ) {
            next;
        }

        my $class = $app->model($key);
        push @obj_types,
            {
            obj_type       => $key,
            obj_type_label => ucfirst( $class->class_label ),
            ( $obj_type && $key eq $obj_type ) ? ( selected => 1 ) : (),
            };
    }

    my $customfield_types = $app->registry('customfield_types');
    my @customfield_types_loop;

    # Resort it by the order key
    my @cf_types = sort {
        ( $customfield_types->{$a}{order} || 0 )
            <=> ( $customfield_types->{$b}{order} || 0 )
        }
        keys %$customfield_types;

    foreach my $key (@cf_types) {
        next if ref $key eq 'HASH';
        my $type = $customfield_types->{$key};

        my $context = $customfield_types->{$key}->{context} || '';
        if ( ref $context ) {
            if ($blog) {
                next
                    if $blog->is_blog && !( grep { $_ eq 'blog' } @$context );
                next
                    if !$blog->is_blog
                        && !( grep { $_ eq 'website' } @$context );
            }
            else {
                next unless grep { $_ eq 'system' } @$context;
            }
        }
        elsif ( $context eq 'system' && $blog_id ) {
            next;
        }
        elsif ( $context eq 'blog' && !$blog_id ) {
            next;
        }

       # This $tmpl_param is used to build the default field and options field
        my $tmpl_param = $param;
        $tmpl_param->{key}        = $key;
        $tmpl_param->{field_name} = 'default';
        $tmpl_param->{field_id}   = 'default';
        $tmpl_param->{field_value}
            = $id
            ? $param->{default}
            : ( $param->{default} || $type->{default_value} );
        $tmpl_param->{options} = $param->{options};

      # If an options_delimiter is present, we need to populate an option_loop
        if ( $type->{options_delimiter} && $param->{options} ) {
            my @option_loop;
            my $expr = '\s*' . $type->{options_delimiter} . '\s?';
            my @options = split /$expr/, $param->{options};
            foreach my $option (@options) {
                my $label = $option;
                if ( $option =~ m/=/ ) {
                    ( $option, $label ) = split /\s*=\s*/, $option, 2;
                }
                my $option_row = { option => $option, label => $label };
                $option_row->{is_selected}
                    = defined $tmpl_param->{field_value}
                    ? ( $tmpl_param->{field_value} eq $option )
                    : 0;
                push @option_loop, $option_row;
            }
            $tmpl_param->{option_loop} = \@option_loop;
        }

        my $row = {
            key   => $key,
            label => $type->{label},
            $type->{no_default} ? ()
            : ( default_field => _get_html( $key, 'field_html', $tmpl_param )
            ),
            $type->{options_field}
            ? ( options_field =>
                    _get_html( $key, 'options_field', $tmpl_param ) )
            : (),
            options_delimiter => $type->{options_delimiter},
            show_column =>
                ( defined $type->{show_column} ? $type->{show_column} : 1 ),
            (   defined $type->{asset_type}
                ? ( asset_type => $type->{asset_type} )
                : ()
            ),
        };

        foreach my $k ( keys %$row ) {
            my $value = $row->{$k};
            if ( ref($value) eq 'CODE' ) {    # handle coderefs
                $row->{$k} = $value->(@_);
            }
        }

        push @customfield_types_loop, $row;
    }

    $param->{customfield_types_loop} = \@customfield_types_loop;
    $param->{obj_type_loop}          = \@obj_types;

    eval { require MT::Image; MT::Image->new or die; };
    $param->{do_thumb} = !$@ ? 1 : 0;
    $param->{saved} = $app->param('saved') || 0;
    $param->{cfg_customfield} = 1;
    $param->{level_label}
        = $blog
        ? (
          $blog->is_blog
        ? $app->translate('blog')
        : $app->translate('website')
        )
        : $app->translate('Movable Type');

    my $cat_type;
    if (   $blog_id
        && $id
        && ( ( $obj_type eq 'entry' ) || ( $obj_type eq 'page' ) ) )
    {
        my $entry_class = $app->model($obj_type);
        my $cat_class   = $app->model( $entry_class->container_type );
        my $cats        = $app->_build_category_list(
            blog_id => $blog_id,
            type    => $entry_class->container_type
        );
        foreach (@$cats) {
            if ( grep { $_ == $id } @{ $_->{category_fields} } ) {
                $_->{selected} = 1;
            }
        }

        $param->{categories}             = $cats;
        $param->{container_type}         = $entry_class->container_type;
        $param->{container_label_plural} = $cat_class->class_label_plural;
    }

    $app->add_breadcrumb(
        $app->translate("Custom Fields"),
        $app->uri(
            'mode' => 'list_field',
            args   => { $blog_id ? ( blog_id => $blog_id ) : () }
        )
    );

    $app->add_breadcrumb( $app->translate('Edit Field') );
    $app->build_page( $plugin->load_tmpl('edit_field.tmpl'), $param );
}

# This routine decrements the schema_version stored for the plugin
# to automatically trigger an "upgrade"
sub prep_customfields_upgrade {
    my $plugin = shift;
    my ($app) = @_;
    return $app->errtrans("Permission denied.") if !$app->user->is_superuser;
    my $cfg = MT->config;
    my $plugin_schema = $cfg->PluginSchemaVersion || {};
    $plugin_schema->{ $plugin->id } = $plugin->schema_version - '0.0001';
    if ( keys %$plugin_schema ) {
        $cfg->PluginSchemaVersion( $plugin_schema, 1 );
    }
    $cfg->save_config;

    $app->call_return;
}

sub cfg_customfields {
    my ( $cb, $app, $param, $tmpl ) = @_;

    my $q    = $app->param;
    my $blog = $app->blog;
    $blog = $app->model('blog')->load( $q->param('blog_id') )
        unless $blog;
    my $obj_type = $blog->is_blog ? 'blog' : 'website';
    $param ||= {};

    my $field_class = $app->model('field');
    my $field_exists = $field_class->exist( { obj_type => $obj_type } );

    if ($field_exists) {

        # Add <mtapp:fields> after placeholder1
        $app->param( 'id',    $q->param('blog_id') );
        $app->param( '_type', $obj_type );
        $param->{label_class} = 'left-label';
        add_app_fields( $cb, $app, $param, $tmpl, 'placeholder1',
            'insertAfter' );
    }
}

sub save_cfg_customfields {
    my $app = shift;
    my $q   = $app->param;

    $app->validate_magic
        or return $app->errtrans("Invalid request.");

    my $perms = $app->permissions;
    return $app->permission_denied()
        unless $app->user->is_superuser()
            || (   $perms
                && $perms->can_administer_blog );

    my $blog_id = scalar $q->param('blog_id')
        or return $app->errtrans("Invalid request.");
    my $blog = $app->model('blog')->load($blog_id);
    return $app->errtrans("Invalid request.")
        unless $blog;

    my $plugin = $app->component("Commercial");
    my $cb = MT::Callback->new( plugin => $plugin );
    CMSPostSave_customfield_objs( $cb, $app, $blog );

    return cfg_customfields( $app, { saved => 1 } );
}

sub CMSPostSave_customfield_objs {
    my ( $cb, $app, $obj ) = @_;
    return 1 unless $app->isa('MT::App');

    my $q = $app->param;
    my $blog_id = $app->param('blog_id') || 0;

    return 1 if !$q->param('customfield_beacon');

    require CustomFields::Field;
    my $meta = {};
    foreach ( $q->param() ) {
        next if $_ eq 'customfield_beacon';
        if (m/^customfield_(.*?)$/) {
            my $field_name = $1;
            if (m/^customfield_(.+?)_cb_beacon$/) {
                $field_name = $1;
                $meta->{$field_name}
                    = defined( $q->param("customfield_$field_name") )
                    ? $q->param("customfield_$field_name")
                    : '0';
            }
            else {
                my $field = CustomFields::Field->load(
                    {   $blog_id
                        ? ( blog_id => [ $blog_id, 0 ] )
                        : ( blog_id => $blog_id ),
                        basename => $field_name
                    }
                ) or next;
                if ( $field->type eq 'datetime' ) {
                    $meta->{$field_name}
                        = $q->param("customfield_$field_name") ne ''
                        ? $q->param("customfield_$field_name")
                        : undef;
                }
                else {
                    $meta->{$field_name}
                        = $q->param("customfield_$field_name");
                }
            }
        }
    }

    save_meta( $obj, $meta ) if %$meta;

    1;
}

sub CMSSaveFilter_customfield_objs_entry {
    CMSSaveFilter_customfield_objs( 'entry', @_ );
}

sub CMSSaveFilter_customfield_objs_page {
    CMSSaveFilter_customfield_objs( 'page', @_ );
}

sub CMSSaveFilter_customfield_objs_asset {
    CMSSaveFilter_customfield_objs( 'asset', @_ );
}

sub CMSSaveFilter_customfield_objs_template {
    CMSSaveFilter_customfield_objs( 'template', @_ );
}

sub CMSSaveFilter_customfield_objs_category {
    CMSSaveFilter_customfield_objs( 'category', @_ );
}

sub CMSSaveFilter_customfield_objs_folder {
    CMSSaveFilter_customfield_objs( 'folder', @_ );
}

sub CMSSaveFilter_customfield_objs_author {
    CMSSaveFilter_customfield_objs( 'author', @_ );
}

sub CMSSaveFilter_customfield_objs_comment {
    CMSSaveFilter_customfield_objs( 'comment', @_ );
}

sub CMSSaveFilter_customfield_objs_blog {
    CMSSaveFilter_customfield_objs( 'blog', @_ );
}

sub CMSSaveFilter_customfield_objs {
    my ( $obj_type, $eh, $app ) = @_;
    my $q = $app->param;
    return 1 if !$q->param('customfield_beacon');

    my $blog_id = $q->param('blog_id') || 0;
    $obj_type = 'website'
        if $obj_type eq 'blog' && $app->blog && !$app->blog->is_blog;

    require CustomFields::Field;
    my $iter = CustomFields::Field->load_iter(
        {   $blog_id ? ( blog_id => [ $blog_id, 0 ] ) : (),
            $obj_type eq 'asset'
            ? ( obj_type => $q->param('asset_type') )
            : ( obj_type => $obj_type ),
        }
    );

    my $sanitizer = sub { return $_[0]; };
    unless ( $app->isa('MT::App::CMS') ) {

        # Sanitize if the value is submitted from an app other than CMS
        my $blog = $app->blog;
        require MT::Sanitize;
        my $sanitize_spec = ( $blog && $blog->sanitize_spec )
            || $app->config->GlobalSanitizeSpec;
        $sanitizer = sub {
            return $_[0]
                ? MT::Sanitize->sanitize( $_[0], $sanitize_spec )
                : $_[0];
        };
    }

    require MT::Asset;
    my $asset_types = MT::Asset->class_labels;
    my %fields;
    while ( my $field = $iter->() ) {
        my $row        = $field->column_values();
        my $field_name = "customfield_" . $row->{basename};
        if ( $row->{type} eq 'datetime' ) {
            my $ts = '';
            if ( $q->param("d_$field_name") || $q->param("t_$field_name") ) {
                my $date = $q->param("d_$field_name");
                $date = '1970-01-01' if $row->{options} eq 'time';
                my $time = $q->param("t_$field_name");
                $time = '00:00:00' if $row->{options} eq 'date';
                my $ao = $date . ' ' . $time;
                unless ( $ao
                    =~ m!^(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2})(?::(\d{2}))?$!
                    )
                {
                    return $eh->error(
                        $app->translate(
                            "Invalid date '[_1]'; dates must be in the format YYYY-MM-DD HH:MM:SS.",
                            $ao
                        )
                    );
                }
                my $s = $6 || 0;
                return $eh->error(
                    $app->translate(
                        "Invalid date '[_1]'; dates should be real dates.",
                        $ao
                    )
                    )
                    if (
                       $s > 59
                    || $s < 0
                    || $5 > 59
                    || $5 < 0
                    || $4 > 23
                    || $4 < 0
                    || $2 > 12
                    || $2 < 1
                    || $3 < 1
                    || ( MT::Util::days_in( $2, $1 ) < $3
                        && !MT::Util::leap_day( $0, $1, $2 ) )
                    );
                $ts = sprintf "%04d%02d%02d%02d%02d%02d", $1, $2, $3, $4, $5,
                    $s;
            }
            $q->param( $field_name, $ts );
        }
        elsif (( $row->{type} =~ m/^asset/ )
            || ( exists( $asset_types->{ 'asset.' . $row->{type} } ) ) )
        {
            if ( my $file = $q->param("file_$field_name") )
            {    # see asset-chooser.tmpl for parameter
                $q->param( $field_name, $file );
            }
        }
        elsif ( ( $row->{type} eq 'url' ) && $q->param($field_name) ) {
            my $valid = 1;
            my $value = $q->param($field_name);
            $value = '' unless defined $value;
            if ( $row->{required} ) {
                $valid = MT::Util::is_url($value);
            }
            else {
                if (   ( $value ne '' )
                    && ( $value ne ( $row->{default} || '' ) ) )
                {
                    $valid = MT::Util::is_url($value);
                }
            }
            return $eh->error(
                $app->translate(
                    "Please enter valid URL for the URL field: [_1]",
                    $row->{name}
                )
            ) unless $valid;
        }

        if ( $row->{required} ) {
            return $eh->error(
                $app->translate(
                    "Please enter some value for required '[_1]' field.",
                    $row->{name}
                )
                )
                if (
                (      $row->{type} eq 'checkbox'
                    || $row->{type} eq 'select'
                    || ( $row->{type} eq 'radio' )
                )
                && !defined $q->param($field_name)
                )
                || (
                (      $row->{type} ne 'checkbox'
                    && $row->{type} ne 'select'
                    && ( $row->{type} ne 'radio' )
                )
                && ( !defined $q->param($field_name)
                    || $q->param($field_name) eq '' )
                );
        }

        my $type_def = $app->registry( 'customfield_types', $row->{type} );

        # handle any special field-level validation
        if ( $type_def && ( my $h = $type_def->{validate} ) ) {
            $h = MT->handler_to_coderef($h) unless ref($h);
            if ( ref $h ) {
                my $value = $q->param($field_name);
                $app->error(undef);
                $value = $h->($value);
                if ( my $err = $app->errstr ) {
                    return $eh->error($err);
                }
                else {
                    $q->param( $field_name, $value );
                }
            }
        }
        elsif ( $q->param($field_name) ) {

            # Sanitize if the value is submitted from an app other than CMS
            $q->param( $field_name, $sanitizer->( $q->param($field_name) ) );
        }
    }

    1;
}

# Fixes bug where required checkbox became uncheckable
sub CMSPreSave_field {
    my ( $cb, $app, $obj, $original ) = @_;

    if ( $app->param('required') eq '' ) {
        $obj->required(0);
        $original->required(0);
    }

    if ('checkbox' eq $app->param('type')
        && ( $app->param('default_cb_beacon')
            && !$app->param('default') )
        )
    {
        $obj->default('0');
    }

    1;
}

# This callback is run only if the basename of the field changes
# and updates $meta to use the basename. Why am I sticking with basename
# and not using the field_id as in v2.0? Because basename makes a lot of
# operations (such as custom sorting and posting from a 3rd party client)
# MUCH faster since I don't need to LOAD customfields and can just use the
# basenames in the key => value

sub CMSPostSave_field {
    my ( $cb, $app, $field ) = @_;
    my $q = $app->param;

    my $changed = 0;

    # If 'required' was not found, this field changes to not required.
    if ( !$app->param('required') ) {
        $field->required(0);
        $changed = 1;
    }

    # Dirify to tag name
    my $tag = dirify( $field->tag );
    if ( $tag ne lc $field->tag ) {
        $field->tag($tag);
        $changed = 1;
    }

    $field->save if $changed;

    my @p         = $q->param;
    my $cat_class = $app->model( $q->param('container_type') );
    foreach my $p (@p) {
        next unless $p =~ /^selected_fields_(\d+)/;
        my $cat_id          = $1;
        my $original_fields = $q->param("selected_fields_$cat_id");
        my %fields          = map { $_ => 1 } split /,/, $original_fields;
        if ( $q->param("show_field_$cat_id") ) {
            $fields{ $field->id } = 1;
        }
        else {
            delete $fields{ $field->id };
        }
        my $cat = $cat_class->load($cat_id) or next;
        $cat->show_fields( join( ',', keys(%fields) ) );
        $cat->save;
    }

# Skip if the basename hasn't been manually changed (or if it's for a new field)
    return 1
        unless ( $q->param('basename_manual')
        && $q->param('basename_old') );

    my $basename_old = $q->param('basename_old');
    my $basename_new = $field->basename;

    my $class = $app->model( $field->obj_type . ':meta' );

    # Updates existing meta records, changing the existing
    # field.old_basename to field.new_basename
    my $driver = $class->driver;
    my $dbd    = $driver->dbd;

    my $stmt = $dbd->sql_class->new;
    my $virtual_col = $dbd->db_column_name( $class->datasource, 'type' );
    $stmt->add_complex_where(
        [ { $virtual_col => 'field.' . $basename_old } ] );

    my $sql = join q{ }, 'UPDATE', $driver->table_for($class), 'SET',
        $virtual_col, '= ?', $stmt->as_sql_where();

    my $dbh = $driver->rw_handle;
    $dbh->do( $sql, {}, 'field.' . $basename_new, @{ $stmt->{bind} } )
        or return $app->error( $dbh->errstr || $DBI::errstr );

    1;
}

sub CMSSaveFilter_field {
    my ( $eh, $app ) = @_;
    my $q = $app->param;

    # Are the required fields supplied?
    my @required_fields = qw( name type tag );
    push @required_fields, 'obj_type' unless $app->param('id');
    if ( $q->param('basename_manual') ) {
        my $rebasename = dirify( $q->param('basename') );
        $q->param( 'basename', $rebasename );
    }
    for my $field (@required_fields) {
        if ( !$q->param($field) ) {
            return $eh->error(
                $app->translate(
                    "Please ensure all required fields have been filled in.")
            );
        }
    }

    my $field_tag = lc $q->param('tag');
    return $eh->error(
        $app->translate(
            "The template tag '[_1]' is an invalid tag name.",
            $q->param('tag')
        )
    ) if $field_tag =~ /[^0-9A-Za-z_]/;

    # Is that tag already defined by some other field?
    MT->model('field')->validates_uniqueness_of_tag(
        $eh,
        {   tag      => $q->param('tag')      || undef,
            blog_id  => $q->param('blog_id')  || undef,
            id       => $q->param('id')       || undef,
            basename => $q->param('basename') || undef,
            obj_type => $q->param('obj_type') || undef,
            type     => $q->param('type')     || undef,
        }
    ) or return;    # has error

    # Is that tag already defined by core or some other plugin?
    my @components
        = grep { lc $_->id ne 'commercial' } MT::Component->select();
COMPONENT: for my $component (@components) {
        my $comp_tags = $component->registry("tags");
    SET: for my $type (qw( block function )) {
            my $tags = $comp_tags->{$type}
                or next SET;
        TAG: for my $tag ( keys %$tags ) {
                return $eh->error(
                    $app->translate(
                        "The template tag '[_1]' is already in use.",
                        $q->param('tag'),
                    )
                ) if $field_tag eq lc $tag;
            }
        }
    }

    # Is the basename already used?
    if ( $q->param('basename') && $q->param('basename') ne '' ) {
        my $basename = $q->param('basename');
        my $basename_is_unique
            = MT->model('field')->make_unique_field_basename(
            stem       => $basename,
            field_id   => $q->param('id') || 0,
            blog_id    => $q->param('blog_id') || 0,
            type       => $q->param('type') || q{},
            check_only => 1,
            );
        my $blog = $app->blog;
        my $blog_id = $blog ? $blog->id : 0;
        my $level
            = $blog
            ? (
              $blog->is_blog
            ? $app->translate('blog and the system')
            : $app->translate('website and the system')
            )
            : $app->translate('Movable Type');
        return $eh->error(
            $app->translate(
                "The basename '[_1]' is already in use. It must be unique within this [_2].",
                $basename,
                $level
            )
        ) if !$basename_is_unique;
    }

    return $eh->error(
        $app->translate(
            "You must select other type if object is the comment.")
        )
        if $q->param('obj_type') eq 'comment'
            && (   $q->param('type') eq 'audio'
                || $q->param('type') eq 'image'
                || $q->param('type') eq 'video'
                || $q->param('type') eq 'file' );

    1;
}

sub CMSPrePreview_customfield_objs {
    my ( $cb, $app, $obj, $data ) = @_;
    my $q = $app->param;

    return 1 if !$q->param('customfield_beacon');
    my %param_hash = $app->param_hash;

    my $meta;
    foreach my $param ( $q->param() ) {
        if ( $param =~ m/^(d_|t_)?customfield_(.*?)$/ ) {
            my $type = $1 || '';
            my $mf = $2;

            if (!$obj->has_meta( 'field.' . $mf )) {
                # special support for check boxs
                next unless $mf =~ m/(.*)_cb_beacon$/;
                $mf = $1;
                next if exists $param_hash{"customfield_$mf"};
                next unless $obj->has_meta( 'field.' . $mf );
            }

            push @$data,
                {
                data_name  => "${type}customfield_$mf",
                data_value => scalar $q->param("${type}customfield_$mf")
                };
            next if $param eq 'customfield_beacon';

            my $value;
            if ( $type eq 'd_' || $type eq 't_' ) {
                my $ts = '';
                if (   $q->param("d_customfield_$mf")
                    || $q->param("t_customfield_$mf") )
                {
                    my $date = $q->param("d_customfield_$mf");
                    $date = '1970-01-01' if $date eq '';
                    my $time = $q->param("t_customfield_$mf");
                    $time = '00:00:00' if $time eq '';
                    $ts = $date . ' ' . $time;
                }
                $value = $ts;
            }
            else {
                $value = $q->param("customfield_$mf");
            }
            $obj->meta( 'field.' . $mf, $value );
        }
    }
    push @$data, { data_name => 'customfield_beacon', data_value => 1 };

    1;
}

# Transformer callbacks

sub add_reorder_widget {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $plugin = $cb->plugin;

    # Get our header include using the DOM
    my ($header);
    my $includes = $tmpl->getElementsByTagName('include');
    foreach my $include (@$includes) {
        if ( $include->attributes->{name} =~ /header.tmpl$/ ) {
            $header = $include;
            last;
        }
    }

    return 1 unless $header;

    require MT::Template;
    bless $header, 'MT::Template::Node';

    require File::Spec;
    my $reorder_widget_tmpl
        = File::Spec->catdir( $plugin->path, 'tmpl', 'reorder_fields.tmpl' );
    my $reorder_widget
        = $tmpl->createElement( 'include', { name => $reorder_widget_tmpl } );

    $tmpl->insertBefore( $reorder_widget, $header );
}

sub add_app_fields {
    my ( $cb, $app, $param, $tmpl, $marker, $where ) = @_;

    # For some reason, directly calling app:fields doesn't populate
    # a field_loop param. So
    populate_field_loop( $cb, $app, $param, $tmpl );

# Where should include the DOM method to insert app:fields relative to the marker
    $where ||= 'insertAfter';

    # Marker can contain either a node or an ID of a node
    unless ( ref $marker eq 'MT::Template::Node' ) {
        $marker = $tmpl->getElementById($marker);
    }

    my $appfields = $tmpl->createElement('app:fields');
    $tmpl->$where( $appfields, $marker );
}

# Although app:fields gives us the entire field loop, on the entry page
# we actually want the field_loop *before* we add the app:fields tag
sub populate_field_loop {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $plugin = $cb->plugin;
    my $q      = $app->param;

    my $mode        = $app->mode;
    my $blog_id     = $q->param('blog_id');
    my $object_id   = $q->param('id');
    my $object_type = $param->{asset_type} || $q->param('_type');
    my $is_entry
        = (    $object_type eq 'entry'
            || $object_type eq 'page'
            || $mode eq 'cfg_entry' );
    my $label_class = delete $param->{label_class}
        if exists $param->{label_class};
    my $field_type = $param->{field_type};
    my %param      = (
        $blog_id ? ( blog_id => $blog_id ) : (),
        ( $mode eq 'cfg_entry' )
        ? ( object_type => $field_type )
        : ( object_type => $object_type, object_id => $object_id ),
        $label_class ? ( label_class => $label_class ) : (),
        params => $param,
    );
    my $prefix    = $field_type ? $field_type . '_' : '';
    my $loop_name = $prefix . 'field_loop';
    my $loop      = $param->{$loop_name};
    my $fields    = field_loop(%param);

    foreach my $field (@$fields) {
        my $basename = $field->{basename};
        unless ( exists $field->{show_field} ) {
            my $show
                = !$is_entry         ? 1
                : $field->{required} ? 1
                : $param->{ $prefix
                    . "disp_prefs_show_customfield_$basename" } ? 1
                : 0;
            $field->{show_field} = $show;
        }
        $field->{use_field} = $field->{required} ne ''
            if !exists $field->{use_field};    # TODO: created by user
        $field->{lock_field} = 1 if $field->{required};
    }

    my %locked_fields;
    if ($loop) {    # an existing field loop, merge our fields into it
        my $i = 100;
    FIELD: foreach my $field (@$loop) {
            if ( $field->{field_name} =~ m/^field\.(.+)$/ ) {
                $field->{field_name}  = 'customfield_' . $1;
                $field->{field_id}    = 'customfield_' . $1;
                $field->{field_order} = $i++
                    unless exists $field->{field_order};
            }
            $locked_fields{ $field->{field_id} } = 1
                if $field->{lock_field};
            foreach my $cf (@$fields) {
                if ( $cf->{field_name} eq $field->{field_name} ) {
                    foreach ( keys %$cf ) {
                        $field->{$_} = $cf->{$_} unless exists $field->{$_};
                    }
                    $cf->{remove} = 1;
                    next FIELD;
                }
                $cf->{field_order} = $i++ unless exists $cf->{field_order};
            }
        }
        @$fields = grep { !$_->{remove} } @$fields;
        push @$loop, @$fields;
    }
    else {
        $loop = $param->{$loop_name} = $fields;
        my $i = 0;
        foreach (@$loop) {
            $_->{field_order} = $i++;
        }
    }

    if ( my $cf_loop = $param->{ $prefix . 'disp_prefs_custom_fields' } ) {

        # user supplied sort order
        my %order;
        my $i = 200;
        foreach (@$cf_loop) {
            $_->{name} =~ s/(.*):s$/$1/;
            $order{ $_->{name} } = $i++
                unless exists $locked_fields{ $_->{name} };
        }

        no warnings;
        @$loop = sort {
            ( $order{ $a->{field_id} } || $a->{field_order} || 0 )
                <=> ( $order{ $b->{field_id} } || $b->{field_order} || 0 )
        } @$loop;
    }
}

sub edit_entry_param {
    my ( $cb, $app, $param, $tmpl ) = @_;

    param_edit_entry_post_types(@_);

    my $plugin = $cb->plugin;

# YAY DOM
# Add the custom fields to the customizable_fields and custom_fields javascript variables
# for Display Options toggline
    my $header    = $tmpl->getElementById('header_include');
    my $html_head = $tmpl->createElement( 'setvarblock',
        { name => 'html_head', append => 1 } );
    my $innerHTML = q{
<script type="text/javascript">
/* <![CDATA[ */
    var customFieldByCategory = new Array();
    var customFields = new Object();
    <mt:loop name="field_loop"><mt:if name="field_id" like="^customfield_">customFields['<mt:var name="id">'] = '<mt:var name="field_id">';</mt:if><mt:if name="required">default_fields.push('<mt:var name="field_id">');</mt:if>
    </mt:loop>
/* ]]> */
</script>
};
    $html_head->innerHTML($innerHTML);
    $tmpl->insertBefore( $html_head, $header );

    my $footer    = $tmpl->getElementById('footer_include');
    my $html_foot = $tmpl->createElement( 'setvarblock',
        { name => 'html_body_footer', append => 1 } );
    my $static_uri = $app->static_path;
    $innerHTML = qq(
<script type="text/javascript" src="${static_uri}addons/Commercial.pack/js/customfield_header.js"></script>
);
    $html_foot->innerHTML($innerHTML);
    $tmpl->insertBefore( $html_foot, $footer );

    $param->{__fields_pre_loaded__} = 1
        if $param->{loaded_revision} && $param->{rev_number};

    # Add <mtapp:fields> before tags
    populate_field_loop( $cb, $app, $param, $tmpl );

    my $content_fields = $tmpl->getElementById('content_fields');
    my $beacon_tmpl
        = File::Spec->catdir( $plugin->path, 'tmpl', 'field_beacon.tmpl' );
    my $beacon = $tmpl->createElement( 'include', { name => $beacon_tmpl } );
    $tmpl->insertAfter( $beacon, $content_fields );

    #    # # Finally display our reorder widget
    #    add_reorder_widget($cb, $app, $param, $tmpl);
}

# Handling for structured post types on compose screen
sub param_edit_entry_post_types {
    my ( $cb, $app, $param, $tmpl ) = @_;

    my $e = MT::Entry->load( $param->{id} )
        if $param->{id};

    my $blog_id = $e ? $e->blog_id : $param->{blog_id};

    CustomFields::Field->exist(
        { blog_id => [ 0, $blog_id ], basename => 'post_type' } )
        or return;

    # handle any conditional exclusions
    my $object_type = $app->param('_type');
    my $type 
        = ( $e ? $e->meta('field.post_type') : undef )
        || $app->param('customfield_post_type')
        || $object_type;
    $type = 'entry' unless defined($type);
    $param->{customfield_post_type} = $type;

    my $types = MT->registry( $object_type . "_types" )
        or return;
    my $post_type_param = {};
    my @post_type_loop;

    # Create a spot for the 'basic' entry type
    my $orig_loop = $param->{field_loop};
    $types->{$object_type} = {
        key    => $object_type,
        label  => MT->model($object_type)->class_label,
        fields => join( ', ',
            map { $_->{field_id} } grep { $_->{lock_field} } @$orig_loop ),
        order => 0,
        }
        if !exists $types->{$object_type};

TYPE: foreach my $t ( keys %$types ) {
        my $label = $types->{$t}{label};
        my @fields = split /\s*,\s*/, $types->{$t}{fields};
        foreach my $f (@fields) {
            if ( $f =~ m/^field.(.+)/ ) {
                my $basename = $1;
                next TYPE
                    unless CustomFields::Field->exist(
                    {   blog_id  => [ 0, $blog_id ],
                        basename => $basename
                    }
                    );
            }
            else {
                next TYPE unless MT::Entry->has_column($f);
            }
        }
        $label = $label->() if ref $label eq 'CODE';
        $post_type_param->{$t} = {
            fields => [
                map { s/^field\./customfield_/; $_ } split /\s*,\s*/,
                $types->{$t}{fields}
            ],
            label => $label,
        };
        $types->{$t}{key} = $t;
        push @post_type_loop,
            { type => $t, label => $label, order => $types->{$t}{order} };
    }
    @post_type_loop = sort { $a->{order} <=> $b->{order} } @post_type_loop;

    $types = [ values %$types ];

    # $types = $app->filter_conditional_list( values %$types, $e );

    no warnings;    # not all may specify order
    @$types = sort { $a->{order} <=> $b->{order} } @$types;

    my @all_fields;

    @all_fields
        = map { $_->{field_id} } grep { !$_->{lock_field} } @$orig_loop;

    my %fields;
    my %show_fields;
    foreach my $t (@$types) {

        # Skips handling of post type when the fields to support
        # that type aren't present.
        next unless exists $post_type_param->{ $t->{key} };

        if ( my $fields = $t->{'fields'} ) {
            my @type_fields = split /\s*,\s*/, $fields;
            if ( $type eq $t->{key} ) {

                # save this list for later
                $show_fields{$_} = 1 for @type_fields;
            }
            if ( $t->{key} ne $object_type ) {
                foreach my $field (@type_fields) {
                    $show_fields{$field} = 0
                        unless exists $show_fields{$field};
                }
            }
            my $insert_pos = 0;
            foreach my $field (@type_fields) {
                if ( exists $fields{$field} ) {
                    $insert_pos = $fields{$field} + 1;
                    next;
                }
                splice( @all_fields, $insert_pos, 0, $field );
                for ( my $i = $insert_pos; $i <= $#all_fields; $i++ ) {
                    $fields{ $all_fields[$i] } = $i;
                }
                $insert_pos++;
            }
        }
    }

    # This is a required element for any structured post type
    unshift @all_fields, 'field.post_type';
    $show_fields{'field.post_type'} = 1;

    # fields: title, field.photo, text
    # fields: title, field.url, text
    # fields: title, field.embed, text
    # fields: title, field.audio, text

    # preset the fields to display for the post type; custom fields
    # will run after this and amend this list; but the items set here
    # should be shown irrespective to user preference, since these are
    # particularly relevant fields for the display of this type
    my $field_loop = [];
    my $order      = 1;
    foreach my $field (@all_fields) {
        push @$field_loop, {
            field_id     => $field,
            field_name   => $field,
            system_field => $field eq 'field.post_type',
            field_order  => $order++,
            lock_field   => exists $show_fields{$field} ? 1 : 0,
            use_field    => 0,
            show_field   => exists $show_fields{$field}
            ? $show_fields{$field}
            : $param->{ 'disp_prefs_show_' . $field },

            # Don't attempt to label custom fields; custom fields will label
            # themselves
            (   $field =~ m/^field\./
                ? ()
                : ( field_label => $app->translate( ucfirst($field) ) )
            ),
        };
    }

    # "system_field" is a field that has special meaning to the app
    #     ("post_type" is currently the only system field recognized)
    # "lock_field" means don't allow user to turn on/off display of field
    # "show_field" means show the field or not (can be based on user
    #     preference, but this setting forces them on or off)
    # "use_field" controls whether the field is reorderable in the
    #     display preferences.

    # Update or assign the 'post_type_loop' and 'field_loop' variables,
    # which control the set of icons to display to switch among post types
    # and provide the metadata for showing/hiding post type fields.
    $param->{post_type_loop} = \@post_type_loop
        if @post_type_loop > 1;
    $param->{field_loop} = $field_loop;

    # Add link tag to pull in stylesheet for post-types.
    my $version    = MT->component('Commercial')->version;
    my $static_uri = $app->static_path;
    $param->{html_head} ||= '';
    $param->{html_head}
        .= qq{    <link type="text/css" href="${static_uri}addons/Commercial.pack/css/post_types.css?v=$version" rel="stylesheet" />\n};

    # A bit of JavaScript to control display of fields on compose screen
    # when switching from one entry type to another; we hide the fields that
    # are not relevant to the edited type and show those that are.
    my $post_types_json = MT::Util::to_json($post_type_param);
    $param->{js_include} ||= '';
    $param->{js_include} .= <<"HTML";
<script type="text/javascript">
/* <![CDATA[ */
var postTypes = $post_types_json;
function oc(a) {var o={};for(var i=0;i<a.length;i++){o[a[i]]=true};return o}
function updateEntryFields(entryType) {
    if (!entryType.length) return;
    var f = document.forms['entry_form'];
    var old_type = f['customfield_post_type'].value;

    // no change
    if (old_type == entryType)
        return false;

    var fields_to_hide = postTypes[old_type]['fields'];
    var fields_to_show = postTypes[entryType]['fields'];
    var show_list = oc(fields_to_show);
    for (var i = 0; i < fields_to_hide.length; i++) {
        var fld = fields_to_hide[i];
        if (!show_list[fld]) {
            TC.addClassName(TC.elementOrId(fld + '-field'), 'hidden');
            f[fld].disabled = true;
            var pref = getByID("custom-prefs-" + fld);
            if (pref)
                pref.checked = false;
        }
    }
    var els = [];
    for (var i = 0; i < fields_to_show.length; i++) {
        var fld = fields_to_show[i];
        var el = TC.elementOrId(fld + '-field');
        els[i] = el;
        f[fld].disabled = false;
        var pref = TC.elementOrId("custom-prefs-" + fld);
        if (pref)
            pref.checked = true;
    }
    var post_type_el = TC.elementOrId('customfield_post_type-field');
    for (var i = els.length-1; i >=0; i--) {
        if (els[i].id != 'text-field') { // text-field is a special case due to the iframe and editor; skip it
            els[i].parentNode.removeChild(els[i]);
            post_type_el.parentNode.insertBefore(els[i],
                post_type_el.nextSibling);
        }
        TC.removeClassName(els[i], 'hidden');
    }
    TC.removeClassName(TC.elementOrId('entry-' + old_type), 'active');
    TC.addClassName(TC.elementOrId('entry-' + entryType), 'active');
    f['customfield_post_type'].value = entryType;
    return false;
}
/* ]]> */
</script>
HTML
}

sub list_entry_param {
    my ( $cb, $app, $param, $tmpl ) = @_;
    $param->{html_head} ||= '';
    $param->{html_head} .= <<'HTML';
    <style type="text/css">
        .filter-post_type #filter-mode-only {
            display: inline !important;
        }
        #filter-post_type {
            display: none;
        }
        .filter-post_type #filter-post_type {
            display: inline !important;
        }
    </style>
HTML
    push @{ $param->{quickfilter_loop} ||= [] },
        {
        filter  => 'post_type',
        label   => $app->translate('type'),
        type    => 'select',
        options => [
            {   key   => 'link',
                label => 'Link',
            },
        ],
        };
}

sub edit_category_param {
    my ( $cb, $app, $param, $tmpl ) = @_;

    # Add <mtapp:fields> after description
    add_app_fields( $cb, $app, $param, $tmpl, 'description', 'insertAfter' );

    # Display our reorder widget
    add_reorder_widget( $cb, $app, $param, $tmpl );

    my $obj_type
        = $param->{object_type} eq 'category' ? 'entry'
        : $param->{object_type} eq 'folder'   ? 'page'
        :                                       undef;
    return 1 unless defined $obj_type;

    # Show the list of Custom Fields for entry/page
    my $blog_ids = [0];
    if ( my $blog_id = $app->param('blog_id') ) {
        push @$blog_ids, $blog_id;
    }
    my $class = $app->model('field');
    my @fields
        = $class->load( { blog_id => $blog_ids, obj_type => $obj_type }, );

    my %existing_fields;
    if ( my $id = $app->param('id') ) {
        my $cat_class = $app->model( $app->param('_type') );
        if ($cat_class) {
            my $cat = $cat_class->load($id);
            if ( my $fields = $cat->show_fields ) {
                $existing_fields{$_} = 1 foreach split /,/, $fields;
            }
        }
    }

    my $list = [];
    foreach (@fields) {
        my $values = $_->get_values;
        $values->{selected} = 1 if exists $existing_fields{ $_->id };
        push @$list, $values;
    }
    $param->{show_fields_list} = $list;

    my ($place)
        = grep { $_->attributes->{name} eq 'action_buttons' }
        @{ $tmpl->getElementsByTagName('setvarblock') };
    return 1 unless $place;
    my $include = $tmpl->createElement( 'include',
        { name => 'category_fields.tmpl' } );
    $tmpl->insertBefore( $include, $place );
}

sub edit_author_param {
    my ( $cb, $app, $param, $tmpl ) = @_;

    # Add <mtapp:fields> after description
    add_app_fields( $cb, $app, $param, $tmpl, 'url', 'insertAfter' );

    # Finally display our reorder widget
    add_reorder_widget( $cb, $app, $param, $tmpl );
}

sub asset_insert_param {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $plugin = $cb->plugin;

    return 1 unless $app->param('edit_field') =~ /customfield/;

    my $block = $tmpl->getElementById('insert_script');
    return 1 unless $block;
    my $preview_html = '';
    my $ctx          = $tmpl->context;
    if ( my $asset = $ctx->stash('asset') ) {
        if ( $asset->class_type eq 'image' ) {
            my $view = encode_js( $app->translate("View image") );
            $preview_html
                = qq{<a href="<mt:asseturl>" target="_blank" title="$view"><img src="<mt:assetthumbnailurl width="240" height="240">" alt="" /></a>};
        }
    }
    $block->innerHTML(
        qq{top.insertCustomFieldAsset('<mt:var name="upload_html" escape="js">', '<mt:var name="edit_field" escape="js">', '$preview_html') }
    );
}

sub cfg_content_nav_param {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $plugin = $cb->plugin;

    my $more = $tmpl->getElementById('more_items');
    return 1 unless $more;

    my $existing = $more->innerHTML;
    $more->innerHTML(<<HTML);
$existing
<mt:if name="cfg_customfield">
<li class="active"><a href="<mt:var name="script_url">?__mode=list_field<mt:if name="blog_id">&amp;blog_id=<mt:var name="blog_id"></mt:if>"><__trans_section component="commercial"><__trans phrase="Custom Fields"></__trans_section></a></li>
<mt:else>
<li><a href="<mt:var name="script_url">?__mode=list_field<mt:if name="blog_id">&amp;blog_id=<mt:var name="blog_id"></mt:if>"><em><__trans_section component="commercial"><__trans phrase="Custom Fields"></__trans_section></em></a></li>
</mt:if>
HTML
}

sub cfg_entry_param {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $plugin = $cb->plugin;

    foreach my $type (qw(entry page)) {
        my $more = $tmpl->getElementById( $type . '_fields' );
        next unless $more;

        my $existing = $more->innerHTML;
        $more->innerHTML(<<HTML);
        <mt:loop name="${type}_field_loop">
        <li><input type="checkbox" name="${type}_custom_prefs" id="custom-prefs-customfield_<mt:var name="basename">" value="customfield_<mt:var name="basename">" <mt:if name="show_field"> checked="checked"</mt:if><mt:if name="lock_field"> disabled="disabled"</mt:if> class="cb" /> <label for="custom-prefs-customfield_<mt:var name="basename">"><mt:var name="name" escape="html"></label></li>
        </mt:loop>
HTML
        $param->{field_type} = $type;
        populate_field_loop( $cb, $app, $param, $tmpl );
    }
}

sub edit_asset_param {
    my ( $cb, $app, $param, $tmpl ) = @_;

    # Add <mtapp:fields> after tags
    add_app_fields( $cb, $app, $param, $tmpl, 'tags', 'insertAfter' );

    # Finally display our reorder widget
    add_reorder_widget( $cb, $app, $param, $tmpl );
}

sub edit_comment_param {
    my ( $cb, $app, $param, $tmpl ) = @_;

    # Add <mtapp:fields> after text
    add_app_fields( $cb, $app, $param, $tmpl, 'text', 'insertAfter' );

    # Finally display our reorder widget
    add_reorder_widget( $cb, $app, $param, $tmpl );
}

sub edit_template_param {
    my ( $cb, $app, $param, $tmpl ) = @_;

    $param->{__fields_pre_loaded__} = 1
        if $param->{loaded_revision} && $param->{rev_number};

    # Add <mtapp:fields> after template-body
    add_app_fields( $cb, $app, $param, $tmpl, 'template-body',
        'insertAfter' );

    # Finally display our reorder widget
    add_reorder_widget( $cb, $app, $param, $tmpl );
}

sub blog_stats_entry {
    my ( $cb, $app, $param, $tmpl ) = @_;

    # Inject CSS for post type
    my $version    = MT->component('Commercial')->version;
    my $static_uri = $app->static_path;
    my $innerHTML  = qq{
    <link type="text/css" href="${static_uri}addons/Commercial.pack/css/post_types.css?v=$version" rel="stylesheet" />\n
};

    my $head = $tmpl->getElementById('html_head');
    $head->innerHTML( $head->innerHTML() . $innerHTML );

    #Inject EntryPostType tag for post_type
    my $place = $tmpl->getElementById('entry_type');
    $place->innerHTML('<mt:EntryPostType>');
}

sub new_version_widget {
    my ( $cb, $app, $param, $tmpl ) = @_;

    $param->{feature_loop} ||= [];
    unshift @{ $param->{feature_loop} },
        {
        feature_label => MT->translate('Custom Fields'),
        feature_url   => $app->help_url('professional/custom-fields.html'),
        feature_description => MT->translate(
            'Customize the forms and fields for entries, pages, folders, categories, and users, storing exactly the information you need.'
        )
        };
}

sub clone_blog {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $plugin   = $cb->plugin;
    my $elements = $tmpl->getElementsByTagName('unless');
    my ($element)
        = grep { 'clone_prefs_input' eq $_->getAttribute('name') } @$elements;
    if ($element) {
        my $contents = $element->innerHTML;
        my $text     = <<EOT;
        <input type="hidden" name="clone_prefs_customfields" value="<mt:var name="clone_prefs_customfields">" />
EOT
        $element->innerHTML( $contents . $text );
    }
    ($element)
        = grep { 'clone_prefs_checkbox' eq $_->getAttribute('name') }
        @$elements;
    if ($element) {
        my $contents = $element->innerHTML;
        my $text     = <<EOT;
                <li>
                    <input type="checkbox" name="clone_prefs_customfields" id="clone-prefs-customfields" <mt:if name="clone_prefs_customfields">checked="<mt:var name="clone_prefs_customfields">"</mt:if> class="cb" />
                    <label for="clone-prefs-customfields"><__trans_section component="commercial"><__trans phrase="Custom Fields"></__trans_section></label>
                </li>
EOT
        $element->innerHTML( $contents . $text );
    }
    ($element)
        = grep { 'clone_prefs_exclude' eq $_->getAttribute('name') }
        @$elements;
    if ($element) {
        my $contents = $element->innerHTML;
        my $text     = <<EOT;
    <mt:if name="clone_prefs_customfields" eq="on">
                <li><__trans_section component="commercial"><__trans phrase="Exclude Custom Fields"></__trans_section></li>
    </mt:if>
EOT
        $element->innerHTML( $contents . $text );
    }
}

sub header_add_style {
    my ( $cb, $app, $param, $tmpl ) = @_;

    my $heads = $tmpl->getElementsByTagName('setvarblock');
    my $head;
    foreach (@$heads) {
        if ( $_->attributes->{name} =~ /html_head$/ ) {
            $head = $_;
            last;
        }
    }

    return 1 unless $head;

    require MT::Template;
    bless $head, 'MT::Template::Node';

    my $html_head = $tmpl->createElement( 'setvarblock',
        { name => 'html_head', append => 1 } );
    my $innerHTML = q{
<link rel="stylesheet" href="<mt:var name="static_uri">addons/Commercial.pack/styles-customfields.css" type="text/css" media="screen" title="CustomFields Stylesheet" charset="utf-8" />
};
    $html_head->innerHTML($innerHTML);

    $tmpl->insertBefore( $html_head, $head );
    1;
}

# Other callbacks

sub post_remove_object {
    my ( $eh, $obj ) = @_;
    return 1 if $obj->has_meta();

    my $type = $obj->class_type || $obj->datasource;
    my $id = $obj->id;
    require MT::PluginData;
    MT::PluginData->remove(
        { plugin => 'CustomFields', key => "${type}_${id}" } );
}

sub pre_remove_objectasset {
    my ( $cb, $oa ) = @_;
    my $obj = MT->model( $oa->object_ds )->load( { id => $oa->object_id } )
        or return;
    my @fields = MT->model('field')->load(
        {   obj_type => $oa->object_ds,
            type     => { like => 'asset%' },
            blog_id =>
                $oa->blog_id,  #currently, we have no system-wide asset field.
        }
    );
    my $updated = 0;
    foreach my $field (@fields) {
        my $meta_column = 'field.' . $field->basename;
        my $meta_data   = $obj->$meta_column();
        my ($asset_id) = $meta_data =~ m/\smt:asset-id="(\d+)"/i;
        if ( $oa->asset_id == $asset_id ) {
            $obj->$meta_column('');
            $updated++;
        }
    }
    $obj->save if $updated;
}

sub sanitize_embed {
    my ($str) = @_;
    my $blog;
    my $app = MT->instance;
    $blog = $app->blog if $app->can('blog');
    return MT::Util::sanitize_embed( $str,
        { error_handler => $app, blog => $blog } );
}

sub save_fields_list {
    my ( $cb, $app, $obj ) = @_;
    return 1 unless $app->isa('MT::App');
    return 1 if $app->mode eq 'bulk_update_category';

    my $q = $app->param;
    my @p = $q->param;
    my @ids;
    foreach my $p (@p) {
        next unless $p =~ /^show_field_(\d+)/;
        push @ids, $1;
    }
    $obj->show_fields( join( ',', @ids ) );
    1;
}

sub cms_pre_load_filtered_list {
    my ( $cb, $app, $filter, $load_options, $cols ) = @_;

    $load_options->{editable_filters} ||= [];
    push(
        @{ $load_options->{editable_filters} },
        sub {
            my ( $objs, $options ) = @_;
            &editable_filter( $app, $objs, $options );
        }
    );

    if ( $app->blog ) {
        $load_options->{terms}{blog_id} = [ $load_options->{blog_id}, 0 ];
        return;
    }
    my $user = $app->user;
    return if $user->is_superuser;
    return if $user->permissions(0)->can_do('edit_templates');

    require MT::Permission;
    my $opt_blog_ids = $load_options->{blog_ids} || undef;
    my $iter = MT::Permission->load_iter(
        {   author_id => $user->id,
            (   $opt_blog_ids
                ? ( blog_id => $opt_blog_ids )
                : ( blog_id => { not => 0 } )
            ),
        },
    );

    my $blog_ids;
    while ( my $perm = $iter->() ) {
        push @$blog_ids, $perm->blog_id;
    }
    push @$blog_ids, 0;

    my $terms = $load_options->{terms};
    $terms->{blog_id} = $blog_ids
        if $blog_ids;
    $load_options->{terms} = $terms;
}

sub list_template_param {
    my ( $cb, $tmpl, $param ) = @_;
    my $user = MT->app->user;
    if ( $user->can_do( 'edit_custom_fields', at_least_one => 1 ) ) {
        $param->{has_list_actions} = 1;
    }
}

sub editable_filter {
    my ( $app, $objs, $options ) = @_;
    my $user        = $app->user;
    my $i           = 0;
    my $local_scope = $app->param('blog_id');
    my @result      = ();
    my %perms;
    for my $obj (@$objs) {
        my $blog_id = $obj->blog_id;
        if ( !$blog_id && $local_scope ) {
            next;
        }
        if ( !$user->is_superuser ) {
            if ( !exists $perms{$blog_id} ) {
                my $perm = MT::Permission->load(
                    { blog_id => $obj->blog_id, author_id => $user->id } );
                $perms{$blog_id}
                    = $perm ? $perm->can_do('edit_custom_fields') : 0;
            }
            next unless $perms{$blog_id};
        }

        push( @result, $obj );
    }

    @result;
}

sub filtered_list_param {
    my ( $cb, $app, $param, $objs ) = @_;
    my $user        = $app->user;
    my $i           = 0;
    my $local_scope = $app->param('blog_id');
    my %perms;
    for my $obj (@$objs) {
        my $row     = $param->{objects}->[ $i++ ];
        my $blog_id = $obj->blog_id;
        if ( !$blog_id && $local_scope ) {
            $row->[0] = 0;
            next;
        }
        next if $user->is_superuser;
        if ( !exists $perms{$blog_id} ) {
            my $perm = MT::Permission->load(
                { blog_id => $obj->blog_id, author_id => $user->id } );
            $perms{$blog_id}
                = $perm ? $perm->can_do('edit_custom_fields') : 0;
        }
        $row->[0] = 0 unless $perms{$blog_id};
    }
}

sub can_save {
    my ( $eh, $app, $obj ) = @_;
    my $author = $app->user;
    return 1 if $author->is_superuser();

    my $blog_id;
    if ( defined $obj and ref $obj ) {
        $blog_id = $obj->blog_id;
    }
    elsif ( defined $obj ) {

        # we got the id of this field
        my $loaded_obj = MT->model('field')->load($obj);
        return 0 unless $loaded_obj;
        $blog_id = $loaded_obj->blog_id;
    }
    elsif ( $app->blog ) {
        $blog_id = $app->blog->id;
    }
    else {
        $blog_id = 0;
    }

    return $author->permissions($blog_id)->can_do('edit_custom_fields');
}

sub can_delete {
    my ( $eh, $app, $obj ) = @_;
    my $author = $app->user;
    return 1 if $author->is_superuser();

    $obj = MT->model('field')->load($obj) unless ref $obj;
    my $blog_id = $obj ? $obj->blog_id : ( $app->blog ? $app->blog->id : 0 );

    return $author->permissions($blog_id)->can_do('edit_custom_fields');
}

1;
