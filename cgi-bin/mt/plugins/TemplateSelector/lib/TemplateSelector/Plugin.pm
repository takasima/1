package TemplateSelector::Plugin;
use strict;
use File::Basename;
use lib 'addons/PowerCMS.pack/lib';
use PowerCMS::Util qw( save_asset set_upload_filename static_or_support site_path
                       is_power_edit is_cms current_user is_user_can uniq_filename
                       file_basename current_blog
                     );
use MT::Util qw( encode_html );
use TemplateSelector::Util;

sub _cb_post_clone {
    my ( $cb, %param ) = @_;
    my $plugin = MT->component( 'TemplateSelector' );
    my $callback = $param{ callback };
    my $state = $plugin->translate( 'Setting entry templates...' );
    my $state_id = $plugin->key;
    $callback->( $state, $state_id );
    my $entry_map = $param{ entry_map };
    my $template_map = $param{ template_map };
    my $counter = 0;
    for my $old_entry_id ( keys %$entry_map ) {
        my $old_entry = MT::Entry->load( { id => $old_entry_id } );
        if ( $old_entry ) {
            if ( my $old_template_module_id = $old_entry->template_module_id ) {
                if ( my $new_template_module_id = $template_map->{ $old_template_module_id } ) {
                    my $new_entry = MT::Entry->load( { id => $entry_map->{ $old_entry_id } } );
                    if ( $new_entry ) {
                        $new_entry->template_module_id( $new_template_module_id );
                        $new_entry->save or die $new_entry->errstr;
                        $counter++;
                    }
                    my $new_template_module = MT::Template->load( $new_template_module_id );
                    if ( $new_template_module ) {
                        if ( my $old_default_entry_id = $new_template_module->default_entry_id ) {
                            if ( my $new_default_entry_id = $entry_map->{ $old_default_entry_id } ) {
                                $new_template_module->default_entry_id( $new_default_entry_id );
                                $new_template_module->save or die $new_template_module->errstr;
                                $counter++;
                            }
                        }
                    }
                }
            }
        }
    }
    $callback->( $state . " " . MT->translate( "[_1] records processed.", $counter ), $state_id, );
}

sub _cb_tp_list_common {
    my ( $cb, $app, $param, $tmpl ) = @_;
    if ( $app->mode eq 'list' ) {
        my $class = $app->param( '_type' );
        if ( $class && $class =~ /^(?:entry|page)$/ ) {
            if ( my $filter_key = $app->param( 'filter_key' ) ) {
                if ( $filter_key eq '_template' ) {
                    $param->{ screen_group } = 'design';
                }
            }
        }
    }
}

sub _cb_ts_edit_entry {
    my ( $cb, $app, $tmpl ) = @_;
    my $insert = ' shown="$show_field" ';
    $$tmpl =~ s/(<mtapp:setting.+?id="title")/$1$insert/s; # title
}

sub _cb_tp_edit_entry_entry_prefs {
    my ( $cb, $app, $param, $tmpl ) = @_;
    if ( my $entry_id = $app->param( 'id' ) ) {
        my $entry = MT->model( 'entry' )->load( { id => $entry_id } );
        if ( $entry ) {
            if ( my $prefs = $entry->prefs ) {
                my @prefs = split( /,/, $prefs );
                my $field_loop = $param->{ field_loop };
                for my $hash ( @$field_loop ) {
                    if ( grep { $hash->{ field_id } eq $_ } @prefs ) {
                        $hash->{ show_field } = 1;
                    } else {
                        $hash->{ show_field } = 0;
                        if ( $hash->{ field_id } eq 'text' ) {
                            $param->{ html_head } .= '<style type="text/css">#text-field{display:none;}</style>';
                        }
                    }
                }
# FIXME: not so good...
                my @field_loop_new;
                for my $prefs_key ( @prefs ) {
                    my $pushed = 0;
                    for my $hash ( @$field_loop ) {
                        if ( $prefs_key eq $hash->{ field_id } ) {
                            push( @field_loop_new, $hash );
                            $pushed++;
                        }
                    }
                }
                my @field_loop_new_copy = @field_loop_new;
                my @field_loop_alt;
                for my $hash ( @$field_loop ) {
                    my $pushed = 0;
                    for my $hash_new ( @field_loop_new ) {
                        if ( $hash->{ field_id } eq $hash_new->{ field_id } ) {
                            my $new = shift @field_loop_new_copy;
                            push( @field_loop_alt, $new );
                            $pushed++;
                        }
                    }
                    unless ( $pushed ) {
                        unless ( grep { $hash->{ field_id } eq $_->{ field_id } } @field_loop_alt ) {
                            my %hash = %$hash;
                            push( @field_loop_alt, \%hash );
                        }
                    }
                }
                $param->{ field_loop } = \@field_loop_alt;
# /FIXME
            }
        }
    }
    elsif ( $app->param( 'reedit' ) ) {
        my @prefs = $app->param( 'custom_prefs' );
        my $field_loop = $param->{ field_loop };
        for my $hash ( @$field_loop ) {
            if ( grep { $hash->{ field_id } eq $_ } @prefs ) {
                $hash->{ show_field } = 1;
                $param->{ html_head } .= '<style type="text/css">#entry_form #' . $hash->{ field_id } . '-field{display:block;}</style>';
            } else {
                $hash->{ show_field } = 0;
                if ( $hash->{ field_id } eq 'text' ) {
                    $param->{ html_head } .= '<style type="text/css">#text-field{display:none;}</style>';
                }
            }
        }
    }
#    else {
#        my $field_loop = $param->{ field_loop };
#        my @fields = MT->model( 'field' )->load( { is_default => 1,
#                                                   blog_id => [ $app->blog->id, 0 ],
#                                                 }
#                                               );
#        return unless @fields;
#        my $field_loop = $param->{ field_loop };
#        for my $hash ( @$field_loop ) {
#            if ( grep { $hash->{ field_id } eq 'customfield_' . $_->basename } @fields ) {
#                $hash->{ show_field } = 1;
#            }
#        }
#    }
    1;
}

sub _cb_tp_edit_field {
    my ( $cb, $app, $param, $tmpl ) = @_;
    return if $app->param( 'id' );
    my $plugin = MT->component( 'TemplateSelector' );
    if ( my $pointer = $tmpl->getElementById( 'tag' ) ) {
        my $nodeset = $tmpl->createElement( 'app:setting', { id => 'is_default',
                                                             label => $plugin->translate( 'Apply edit screen' ),
                                                             required => 0,
                                                          }
                                          );
        my $innerHTML = <<'MTML';
<__trans_section component="TemplateSelector">
    <input type="checkbox" id="is_default" name="is_default" value="1"<mt:if name="is_default"> checked="checked"</mt:if> />
    <label for="is_default"><__trans phrase="Apply"></label>
</__trans_section>
MTML
        $nodeset->innerHTML( $innerHTML );
        $tmpl->insertAfter( $nodeset, $pointer );
    }
}

sub _cb_to_edit_field {
    my ( $cb, $app, $tmpl ) = @_;
    return if $app->param( 'id' );
    my ( $search, $insert );
    $search = quotemeta( '</body>' );
    $insert = <<'MTML';
<script type="text/javascript">
jQuery().ready(function() {
    jQuery("#obj_type").change(function() {
        var value = jQuery(this).attr("value");
        if ((value === "entry") || (value === "page")) {
            jQuery("#is_default-field").show();
        } else {
            jQuery("#is_default-field").hide();
            jQuery("#is_default").prop("checked", false);
        }
    });
});
</script>
MTML
    $$tmpl =~ s/($search)/$insert$1/;
    $search = quotemeta( '</head>' );
    $insert = <<'MTML';
<style type="text/css">
#is_default-field {
    display: none;
}
</style>
MTML
    $$tmpl =~ s/($search)/$insert$1/;
}

sub _cb_cms_post_save_entry_save_prefs {
    my ( $eh, $app, $obj, $original ) = @_;
    if ( is_cms() && $app->param( 'id' ) ) {
        return 1;
    }
    my $prefs_type = $app->param( '_type' ) . '_prefs';
    my @prefs = $app->param( 'custom_prefs' );
    $obj->prefs( join( ',', @prefs ) );
    $obj->save or die $obj->errstr;
}

sub _cb_permission_post_save {
    my ( $cb, $obj ) = @_;
    return 1 unless is_cms();
    my $app = MT->instance;
    return 1 unless $app->mode eq 'save_entry_prefs';
    if ( my $entry_id = $app->param( 'id' ) ) {
        my $object_type = $app->param( '_type' );
        my $entry = MT->model( $object_type )->load( { id => $entry_id } );
        if ( $entry ) {
            my @prefs = $app->param( 'custom_prefs' );
            $entry->prefs( join( ',', @prefs ) );
            $entry->save or die $obj->errstr;
        }
    }
}

sub _cb_cms_post_save_field {
    my ( $eh, $app, $obj, $original ) = @_;
    return 1 unless $app->param( 'is_default' );
    my $field_basename = $obj->basename;
    my $custom_prefs = 'customfield_' . $field_basename;
    my $obj_type = $obj->obj_type;
    return 1 unless $obj_type =~ /^(?:entry|page)$/;
    my @entries = MT->model( $obj_type )->load( { ( $obj->blog_id ? ( blog_id => $obj->blog_id ) : () ) } );
    for my $entry ( @entries ) {
        my $prefs = $entry->prefs;
        my @prefs = $prefs ? split( /,/, $prefs ) : ();
        unless ( grep { $_ eq $custom_prefs } @prefs ) {
            $entry->prefs( join( ',', @prefs, $custom_prefs ) );
            $entry->save or die $entry->errstr;
        }
    }
    1;
}

sub _cb_cms_pre_load_filtered_list_entry {
    my ( $cb, $app, $filter, $load_options, $cols ) = @_;
    my $terms = $load_options->{ terms } || {};
    my $filter_key = $app->param( 'fid' );
    if ( $filter_key && $filter_key eq '_template' ) {
        if ( ref $terms eq 'ARRAY' ) {
            unshift( @$terms, [ { status => 7 } ] );
        } else {
            $terms->{ status } = 7;
        }
    } else {
        if ( ref $terms eq 'ARRAY' ) {
            unshift( @$terms, [ { status => { 'not' => 7 } } ] );
        } else {
            $terms->{ status } = { 'not' => 7 };
        }
    }
}

sub select_entry_tmpl {
    my $app = shift;
    return select_tmpl( $app, 'entry' );
}

sub select_page_tmpl {
    my $app = shift;
    return select_tmpl( $app, 'page' );
}

sub select_tmpl {
    my ( $app, $type ) = @_;
    my $blog = $app->blog or return $app->errtrans( 'Invalid request.' );
    my $fmgr = $blog->file_mgr;
    my $blog_id = $blog->id;
    my $plugin = MT->component( 'TemplateSelector' );
    $app->{ plugin_template_path } = File::Spec->catdir( $plugin->path, 'tmpl' );
    my $tmpl = 'templateselector_select_tmpl.tmpl';
    my %param;
    $param{ type_class } = $type;
    $param{ parent_entry_id } = $app->param( 'parent_entry_id' );
    my $scope = 'blog:' . $blog_id;
    my $sort_by = $plugin->get_config_value( $type . '_sort_by', $scope );
    my $sort_order = $plugin->get_config_value( $type . '_sort_order', $scope ) || 'descend';
    unless ( MT->model( 'template' )->has_column( $sort_by ) ) {
        $sort_by = 'created_on';
    }
    if ( $sort_order ne 'ascend' ) {
        $sort_order = 'descend';
    }
    my @templates = MT->model( 'template' )->load( { blog_id => $blog_id,
                                                     object_class => $type,
                                                     is_selector => 1,
                                                   }, {
                                                     'sort' => $sort_by,
                                                     direction => $sort_order,
                                                   },
                                                 );
    my $counter = 1;
    for my $template ( @templates ) {
        my $thumbnail_file_name = $template->thumbnail_path;
        my $thumbnail_path = File::Spec->catfile( static_or_support(), 'plugins', $plugin->id, 'thumbnail', $blog_id, $thumbnail_file_name );
        my $thumbnail_url;
        if ( -f $thumbnail_path ) {
            $thumbnail_url = $app->support_directory_url . 'plugins/' . $plugin->id . '/thumbnail/' . $blog_id . '/' . $thumbnail_file_name;
        } else {
            $thumbnail_url = $app->static_path . 'plugins/TemplateSelector/images/no-template-image.gif';
        }
        my $template_data = { 'counter' => $counter,
                              'template_id' => $template->id,
                              'template_name' => $template->name,
                              'thumbnail_url' => $thumbnail_url,
                            };
        push( @{ $param{ template_loop } }, $template_data );
        $counter++;
    }
    return $app->build_page( $tmpl, \%param );
}

sub _cb_tp_edit_entry {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $plugin = MT->component( 'TemplateSelector' );
    my $blog = $app->blog;
    if ( $app->param( 'error_tmpl' ) ) {
        $param->{ 'error_tmpl' } = $app->param( 'error_tmpl' );
        $param->{ error } = $app->translate( 'Template name must be unique within this [_1].', $blog->is_blog ? $app->translate( 'Blog' ) : $app->translate( 'Website' ) );
    }
    if ( $app->param( 'error_no_title' ) ) {
        $param->{ 'error_no_title' } = $app->param( 'error_no_title' );
        $param->{ error } = $plugin->translate( 'Title is Required to Status to Entry Template.' );
    }
    my $blog_id = $blog->id;
    my $id = $app->param( 'id' );
    my $type = $app->param( '_type' );
    my $template_module_id = $app->param( 'template_module_id' );
    my $duplicate = $app->param( 'duplicate' );
    my $reedit = $app->param( 'reedit' );
    my $user = current_user( $app );
    my $can_template_selector = TemplateSelector::Util::can_template_selector( $blog, $user );
    $param->{ can_template_selector } = $can_template_selector;
    unless ( $duplicate ) {
        my $perm = is_user_can( $blog, $user, 'edit_all_posts' );
        my $default_template_reg;
        my $default_template;
        unless ( $template_module_id ) {
            if ( ! $id && ! $reedit ) {
                $default_template = TemplateSelector::Util::get_default_template( $blog_id, $type );
                if ( $default_template ) {
                    $template_module_id = $default_template->id;
                }
            }
        }
        if ( $template_module_id && ! $reedit ) {
            my $current_template;
            if ( $default_template ) {
                $current_template = $default_template;
            } else {
                $current_template = MT->model( 'template' )->load( { id => $template_module_id,
                                                                     is_selector => 1,
                                                                     object_class => $type,
                                                                   }
                                                                 );
            }
            if ( defined $current_template ) {
                my $default_entry_id = $current_template->default_entry_id;
                if ( MT::Entry->count( { id => $default_entry_id } ) ) {
                    if ( my $default_entry_id = $current_template->default_entry_id ) {
                        return $app->redirect( $app->base . $app->uri( mode => 'view',
                                                                       args => { '_type' => $type,
                                                                                 'blog_id' => $blog_id,
                                                                                 'id' => $default_entry_id,
                                                                                 'duplicate' => 1,
                                                                                 'template_module_id' => $current_template->id,
                                                                                 'perms' => $perm,
                                                                       },
                                                                     )
                                             );
                    }
                }
            }
        }
    }
    my $entry_template_module_id;
    if ( $id ) {
        my $entry = MT->model( 'entry' )->load( { id => $id } );
        if ( $entry ) {
            $entry_template_module_id = $entry->template_module_id;
        }
    }
    my $no_template_selected = 0;
    if ( $app->param( 'reedit' ) ) {
        if ( $app->param( 'template_module_id' ) ) {
            $entry_template_module_id = $app->param( 'template_module_id' );
        } else {
            $no_template_selected = 1;
        }
    }
    my $select_options .= '<option value=""' . ( $no_template_selected ? ' selected="selected"' : '' ) . '>' . $plugin->translate( 'No Template Selected' ) . '</option>'."\n";
    my $counter = 0;
    my $max_string_length = 13;
    my $hidden_field = '';
    my @templates = TemplateSelector::Util::get_templates_for_selector( $blog_id, $type );
    for my $template ( @templates ) {
        my $template_id = $template->id;
        my $template_name = $template->name;
        if ( TemplateSelector::Util::words_count( $template_name ) > $max_string_length ) {
            $template_name = substr( $template_name, 0, $max_string_length ) . '...';
        }
        if ( ! $no_template_selected
             && (
                  ( $template_id && $entry_template_module_id && $template_id eq $entry_template_module_id ) ||
                  ( ! $id && $template->is_default_selector )
                )
        ) {
            $select_options .= '<option value="' . encode_html( $template_id ) . '" selected="selected">' . encode_html( $template_name ) . '</option>'."\n";
            $hidden_field = '<input type="hidden" name="template_module_id" id="template_module_id" value="' . encode_html( $template_id ) . '" />';
        } else {
            $select_options .= '<option value="' . encode_html( $template_id ) . '">' . encode_html( $template_name ) . '</option>'."\n";
        }
        $counter++;
    }
    if ( $counter ) {
        my $disabled = $can_template_selector ? '' : 'disabled="disabled"';
        if ( my $pointer = $tmpl->getElementById( 'entry-publishing-widget' ) ) {
            my $nodeset = $tmpl->createElement( 'app:widget', { id => 'template_name',
                                                                label => $plugin->translate( 'Template' ),
                                                                label_class => 'top-level',
                                                                required => 0,
                                                              }
                                              );
            my $innerHTML = <<MTML;
<select name="template_module_id" id="template_module_id" class="full-width" $disabled onchange="highlightSwitch(this)">
    $select_options
</select>
    $hidden_field
MTML
            $nodeset->innerHTML( $innerHTML );
            $tmpl->insertAfter( $nodeset, $pointer );
        }
    }
}

sub _cb_tp_edit_entry_extra_status {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $plugin = MT->component( 'TemplateSelector' );
    my $entry_id = $app->param( 'id' );
    if ( $entry_id && ! $app->param( 'duplicate' ) ) {
        my $entry = MT->model( 'entry' )->load( { id => $entry_id } );
        if ( $entry && $entry->status == 7 ) {
            $param->{ status_template } = 1;
        }
    }
    if ( my $pointer = $tmpl->getElementById( 'status_etc' ) ) {
        my $nodeset = $tmpl->createElement( 'for', { id => 'extra_status_template',
                                                            label_class => 'no-label',
                                                            required => 0,
                                                   }
                                          );
        my $innerHTML = <<MTML;
<__trans_section component="TemplateSelector">
<option value="7"<mt:if name="status_template"> selected="selected"</mt:if>><__trans phrase="Create template"></option>
</__trans_section>
MTML
        $nodeset->innerHTML( $innerHTML );
        $tmpl->insertBefore( $nodeset, $pointer );
    }
    if ( $app->param( 'is_create_template' ) ) {
        $param->{ status_template } = 1;
    }
}

sub _cb_cms_post_save_entry {
    my ( $eh, $app, $obj, $original ) = @_;
    if ( is_power_edit() ) {
        return 1;
    }
    my $plugin = MT->component( 'TemplateSelector' );
    my $template_id = $app->param( 'template_module_id' );
    my $id = $obj->id;
    my $class = $obj->class;
    my $blog_id = $obj->blog_id;
    my $blog = $app->blog;
    my $user = current_user( $app );
    if ( $obj->status == 7 ) {
        unless ( $obj->title ) {
            $obj->status( defined $original ? $original->status : MT::Entry::HOLD() );
            $obj->save or die $obj->errstr;
            my $redirect_url = $app->base . $app->uri( mode => 'view',
                                                       args => { blog_id => $blog_id,
                                                                 _type => $class,
                                                                 id => $id,
                                                                 error_no_title => 1,
                                                               },
                                                     );
            return $app->print( "Location: $redirect_url\n\n" );
        }
        my $template = MT->model( 'template' )->get_by_key( { default_entry_id => $id,
                                                              blog_id => $blog_id,
                                                              type => 'custom',
                                                            }
                                                          );
        unless ( $template->id ) {
            my $name_reserved = MT->model( 'template' )->count( { blog_id => $blog_id,
                                                                  name => $obj->title,
                                                                }
                                                              );
            if ( $name_reserved ) {
                $obj->status( defined $original ? $original->status : MT::Entry::HOLD() );
                $obj->save or die $obj->errstr;
                my $redirect_url = $app->base . $app->uri( mode => 'view',
                                                           args => { blog_id => $blog_id,
                                                                     _type=> $class,
                                                                     id => $id,
                                                                     error_tmpl => 1,
                                                                   },
                                                         );
                return $app->print( "Location: $redirect_url\n\n" );
            }
            $template->build_dynamic( 0 );
            $template->created_by( $user->id );
            $template->rebuild_me( 1 );
            $template->is_selector( 1 );
            $template->name( $obj->title );
            my $new_tmpl;
            my $tmpl_file = 'templateselector_entry.tmpl';
            my $class = 'entry';
            if ( $class eq 'page' ) {
                $tmpl_file = 'templateselector_page.tmpl';
                $class = 'page';
            }
            $tmpl_file = File::Spec->catdir( $plugin->path, 'tmpl', $tmpl_file );
            my $fmgr = $blog->file_mgr;
            if ( $fmgr->exists( $tmpl_file ) ) {
                $new_tmpl = $fmgr->get_data( $tmpl_file );
            } else {
                $new_tmpl = $class eq 'entry' ? &_entry_tmpl() : &_page_tmpl();
            }
            $template->text( $new_tmpl );
            $template->object_class( $obj->class );
            $template->save or die $template->errstr;
            $obj->template_module_id( $template->id );
            $obj->save or die $obj->errstr;
        }
        my $redirect_url = $app->base . $app->uri( mode => 'view',
                                                   args => { blog_id => $blog_id,
                                                             _type => 'template',
                                                             id => $template->id,
                                                             type => 'module',
                                                             is_selector => 1,
                                                           },
                                                 );
        return $app->print( "Location: $redirect_url\n\n" );
    }
    1;
}

sub _cb_ts_edit_template {
    my ( $cb, $app, $tmpl ) = @_;
    my $blog = $app->blog or return 1;
    my $search = '<form name="template-listing-form"';
    my $insert = ' enctype="multipart/form-data" ';
    $$tmpl =~ s/($search)/$1$insert/;
}

sub _cb_tp_edit_template {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $plugin = MT->component( 'TemplateSelector' );
    my $id = $app->param( 'id' );
    my $type = $app->param( 'type' );
    my $blog = $app->blog or return 1;
    my $blog_id = $blog->id;
    my $fmgr = $blog->file_mgr;
    my $template;
    if ( $id ) {
        if ( $template = MT->model( 'template' )->load( { id => $id } ) ) {
            $type = $template->type;
            $param->{ is_selector } = $template->is_selector;
            $param->{ is_default_selector } = $template->is_default_selector;
            if ( my $object_class = $template->object_class ) {
                $param->{ is_page } = $object_class eq 'page' ? 1 : 0;
                my $default_entry_id = $template->default_entry_id;
                my $iter = MT->model( $object_class )->load_iter( { blog_id => $blog->id,
                                                                    class => $object_class,
                                                                    status => 7,
                                                                  }
                                                                );
                if ( defined $iter ) {
                    while ( my $entry = $iter->() ) {
                        my $entry_id = $entry->id;
                        my $selected;
                        if ( $default_entry_id && $default_entry_id == $entry_id ) {
                            $selected = 1;
                        }
                        my $option = {
                            'default_entry_id' => $entry_id,
                            'default_entry_title' => $entry->title,
                            'default_entry_selected' => $selected,
                        };
                        push( @{ $param->{ 'default_entries' } }, $option );
                    }
                }
            }
            if ( my $thumbnail_path = $template->thumbnail_path ) {
                my $thumbnail_file_path = File::Spec->catdir( static_or_support(), 'plugins', $plugin->id, 'thumbnail', $blog_id, $thumbnail_path );
                if ( -f $thumbnail_file_path ) {
                    my $thumbnail_file_url = $app->support_directory_url . 'plugins/' . $plugin->id . '/thumbnail/' . $blog_id . '/' . $thumbnail_path;
                    $param->{ thumbnail_url } = $thumbnail_file_url;
                }
            }
        }
    }
    return unless $type;
    if ( $type =~ /^custom|module$/ ) {
        if ( my $pointer = $tmpl->getElementById( 'linked_file' ) ) {
            my $nodeset = $tmpl->createElement( 'app:setting', { id => 'is_selector',
                                                                 label => $plugin->translate( 'Selector' ),
                                                                 label_class => 'top-level',
                                                                 required => 0,
                                                               }
                                              );
            my $innerHTML = <<'MTML';
<__trans_section component="TemplateSelector">
        <script type="text/javascript">
            function revcms (obj) {
                if (obj.checked) {
                    <mt:if name="blog_id">
                    document.getElementById( 'cmstemplate-field' ).style.display = 'block';
                    document.getElementById( 'default_entry-field' ).style.display = 'block';
                    </mt:if>
                    document.getElementById( 'thumbnail-field' ).style.display = 'block';
                    document.getElementById( 'is_page' ).style.display = 'inline';
                    document.getElementById( 'default_label' ).style.display = 'inline';
                } else {
                    <mt:if name="blog_id">
                    document.getElementById( 'cmstemplate-field' ).style.display = 'none';
                    document.getElementById( 'default_entry-field' ).style.display = 'none';
                    </mt:if>
                    document.getElementById( 'thumbnail-field' ).style.display = 'none';
                    document.getElementById( 'is_page' ).style.display = 'none';
                    document.getElementById( 'default_label' ).style.display = 'none';
                }
            }
            $(function() {
            if (document.getElementById( 'is_selector' ).checked) {
                <mt:if name="blog_id">document.getElementById( 'default_entry-field' ).style.display = 'block';</mt:if>
                document.getElementById( 'thumbnail-field' ).style.display = 'block';
            } else {
                <mt:if name="blog_id">document.getElementById( 'default_entry-field' ).style.display = 'none';</mt:if>
                document.getElementById( 'thumbnail-field' ).style.display = 'none';
            }
            });
        </script>
        <ul>
            <li><input onclick="revcms(this)" type="checkbox" id="is_selector" name="is_selector" value="1"<mt:if name="is_selector"> checked="checked"</mt:if> mt:watch-change="1" /> <label for="is_selector"><__trans phrase="Add this template to Template Selector."></label></li>
        </ul>
        <mt:if name="blog_id">
        <ul>
            <li>
                <label for="is_default_selector" id="default_label"<mt:if name="is_selector"><mt:else> style="display:none"</mt:else></mt:if>><input type="checkbox" id="is_default_selector" name="is_default_selector" value="1"<mt:if name="is_default_selector"> checked="checked"</mt:if> mt:watch-change="1" /> <__trans phrase="Default template"></label>&nbsp;
                <select name="is_page" id="is_page" class="full-width" onchange="highlightSwitch(this)"<mt:if name="is_selector"><mt:else> style="display:none"</mt:else></mt:if>>
                <option value="0"<mt:unless name="is_page"> selected="selected"</mt:unless>><__trans phrase="Entry"></option>
                <option value="1"<mt:if name="is_page"> selected="selected"</mt:if>><__trans phrase="Page"></option>
                </select>
            </li>
        </ul>
        </mt:if>
        <input type="hidden" name="is_selector" value="0" /><input type="hidden" name="is_page" value="0" /><input type="hidden" name="is_default_selector" value="0" />
</__trans_section>
MTML
            $nodeset->innerHTML( $innerHTML );
            $tmpl->insertAfter( $nodeset, $pointer );
            if ( $app->param( 'is_selector' ) ) {
                $param->{ is_selector } = 1;
            }
        }
        if ( my $pointer = $tmpl->getElementById( 'is_selector' ) ) {
            my $nodeset = $tmpl->createElement( 'app:setting', { id => 'default_entry',
                                                                 label => $plugin->translate( 'Entry Template' ),
                                                                 label_class => 'top-level',
                                                                 required => 0,
                                                               }
                                              );
            my $innerHTML = <<'MTML';
<__trans_section component="TemplateSelector">
        <mt:if name="default_entry_id">
            <select name="default_entry_id" id="default_entry_id" class="full-width" onchange="highlightSwitch(this)">
            <mt:loop name="default_entries">
                <option value="<mt:var name="default_entry_id">"<mt:if name="default_entry_selected"> selected="selected"</mt:if>><mt:var name="default_entry_title"></option>
            </mt:loop>
            </select>
        <mt:else>
            <p><__trans phrase="No entries for template."></p>
        </mt:if>
</__trans_section>
MTML
            $nodeset->innerHTML( $innerHTML );
            $tmpl->insertAfter( $nodeset, $pointer );
        }
        if ( my $pointer = $tmpl->getElementById( 'default_entry' ) ) {
            my $nodeset = $tmpl->createElement( 'app:setting', { id => 'thumbnail',
                                                                 label => $plugin->translate( 'Thumbnail' ),
                                                                 label_class => 'top-level',
                                                                 required => 0,
                                                               }
                                              );
            my $innerHTML = <<'MTML';
<__trans_section component="TemplateSelector">
        <p><input type="file" name="thumbnail" id="thumbnail" /></p>
        <mt:if name="thumbnail_url">
        <p>
            <img src="<mt:var name="thumbnail_url" escape="html">" />
            <input type="checkbox" id="remove_thumbnail" name="remove_thumbnail" /> <__trans phrase="Delete">
        </p>
        </mt:if>
</__trans_section>
MTML
            $nodeset->innerHTML( $innerHTML );
            $tmpl->insertAfter( $nodeset, $pointer );
        }
    }
    1;
}

sub _cb_cms_post_save_template {
    my ( $eh, $app, $obj, $original ) = @_;
    my $plugin = MT->component( 'TemplateSelector' );
    my $blog = $app->blog;
    my $blog_id;
    if ( defined $blog ) {
        $blog_id = $blog->id;
    } else {
        return 1;
#         $blog_id = 0;
#         $blog = MT::Blog->load( undef, { limit => 1 } );
    }
    my $fmgr = $blog->file_mgr;
    if ( $app->param( 'remove_thumbnail' ) ) {
        if ( TemplateSelector::Util::remove_thumbnail( $obj ) ) {
            $obj->save or die $obj->errstr;
        }
    }
    my $template_id = $obj->id;
    if ( my $is_selector = $app->param( 'is_selector' ) ) {
        my ( $thumb_url, $thumb_path );
        my $q = $app->param;
        my $FH = $q->upload( 'thumbnail' );
        my $file_name;
        if ( $FH ) {
            my $directory = File::Spec->catdir( static_or_support(), 'plugins', $plugin->id, 'thumbnail', $blog_id );
            $file_name = file_basename( $FH );
            my $out = File::Spec->catfile( $directory, $file_name );
            $out = uniq_filename( $out );
            if ( MT->config->NoDecodeFilename ) { # FIXME
                $out = Encode::decode_utf8( $out );
            }
            $file_name = file_basename( $out );
            my $dir = File::Basename::dirname( $out );
            $dir =~ s!/$!! unless $dir eq '/';
            unless ( $fmgr->exists( $dir ) ) {
                $fmgr->mkpath( $dir );
            }
            my $temp_file_path = "$out.new";
            my $umask = $app->config( 'UploadUmask' );
            my $old = umask( oct $umask );
            local *OUT;
            open ( OUT, "> $temp_file_path" ) or die "Can't open $temp_file_path!";
            binmode ( OUT );
            while( read ( $FH, my $buffer, 1024 ) ) {
                print OUT $buffer;
            }
            close ( OUT );
            close ( $FH );
            # make thumbnail
            require MT::Image;
            my $img = MT::Image->new( Filename => $temp_file_path );
            if ( defined $img ) {
                my ( $blob, $w, $h ) = $img->scale( Width => 160 );
                open ( TF, "> $out" ) or die $!;
                binmode TF;
                print TF $blob;
                close TF;
                unlink( $temp_file_path );
            } else {
                $fmgr->rename( $temp_file_path, $out );
            }
            umask( $old );
        }
        $obj->is_selector( 1 );
        if ( $FH ) {
            $obj->thumbnail_path( $file_name );
        }
        $obj->default_entry_id( $app->param( 'default_entry_id' ) );
        my $object_class = $app->param( 'is_page' ) ? 'page' : 'entry';
        unless ( $blog->is_blog ) {
            $object_class = 'page';
        }
        $obj->object_class( $object_class );
        my $template_type = $object_class eq 'page' ? 'page' : 'individual';
        $obj->is_default_selector( $app->param( 'is_default_selector' ) ? 1 : 0 );
        $obj->save or die $obj->errstr;
        my @templates = MT->model( 'template' )->load( { blog_id => $blog_id,
                                                         type => $template_type,
                                                       }
                                                     );
        for my $template ( @templates ) {
            my $template_text = $template->text;
            my $tmpl_name = $obj->name;
            my $q_name = quotemeta( $tmpl_name );
            unless ( $template_text =~ /<MT:{0,1}IfTemplateSelector\sname="$q_name"><\${0,1}MT:{0,1}Include\smodule="$q_name"\${0,1}\sblog_id="$blog_id"\${0,1}><\/MT:{0,1}IfTemplateSelector>/i ) { # FIXME: not so good...
                my $old = '<MTIfTemplateSelectorBlock>';
                my $q_old = quotemeta( $old );
                my $new = "\n" . '<MTIfTemplateSelector name="' . $tmpl_name . '"><MTInclude module="' . $tmpl_name . '" blog_id="' . $blog_id . '"></MTIfTemplateSelector>';
                $template_text =~ s/(<MT(:{0,1}?)IfTemplateSelectorBlock>)/$1$new/i;
                $template->text( $template_text );
                $template->save or die $template->errstr;
            }
        }
    }
    1;
}

sub _cb_cms_post_delete_template {
    my ( $eh, $app, $obj ) = @_;
    my $blog_id = $obj->blog_id;
    TemplateSelector::Util::remove_thumbnail( $obj );
    my @templates = MT->model( 'template' )->load( { blog_id => $blog_id } );
    foreach my $template ( @templates ) {
        my $template_text = $template->text;
        my $tmpl_name = $obj->name;
        if ( $template_text =~ /<MTIfTemplateSelector\sname="$tmpl_name"><MTInclude\smodule="$tmpl_name"\sblog_id="$blog_id"><\/MTIfTemplateSelector>/ ) { # FIXME: not so good...
            my $search = quotemeta( "\n" . '<MTIfTemplateSelector name="' . $tmpl_name . '"><MTInclude module="' . $tmpl_name . '" blog_id="' . $blog_id . '"></MTIfTemplateSelector>' );
            $template_text =~ s/$search//gsi;
            $template->text( $template_text );
            $template->save or die $template->errstr;
        }
    }
}

sub _cb_ts_list_entry { # add status filter for template
    my ( $cb, $app, $tmpl ) = @_;
    my $search = quotemeta( '<option value="4"><__trans phrase="scheduled"></option>' );
    my $insert = '<mt:if name="has_edit_template"><option value="7"><__trans phrase="template"></option></mt:if>';
    $$tmpl =~ s/($search)/$1$insert/ig;
}

sub _cb_tp_list_entry { # add params for filtering template
    my ( $eh, $app, $param ) = @_;
    my $filter = $app->param( 'filter' );
    my $filter_val = $app->param( 'filter_val' );
    if ( $filter && $filter eq 'status' && $filter_val && $filter_val == 7 ) {
        $param->{ 'filter' } = 'status';
        $param->{ 'filter_val' } = 7;
    }
    my $blog = current_blog( $app );
    my $user = current_user( $app );
    $param->{ 'has_edit_template' } = TemplateSelector::Util::can_template_selector( $blog, $user ) ? 1 : 0;
}

sub _cb_tp_preview_strip {
    my ( $eh, $app, $param ) = @_;
    if ( my $template_id = $app->param( 'template_module_id' ) ) {
        my $input = {
            'data_name' => 'template_module_id',
            'data_value' => $template_id,
        };
        push( @{ $param->{ 'entry_loop' } }, $input );
    }
    for my $custom_prefs ( $app->param( 'custom_prefs' ) ) {
        my $input = {
            'data_name' => 'custom_prefs',
            'data_value' => $custom_prefs,
        };
        push( @{ $param->{ 'entry_loop' } }, $input );
    }
    1;
}

sub _cb_tp_blog_stats {
    my ( $eh, $app, $param, $tmpl ) = @_;
    if ( my $static_uri = $app->static_path ) {
        $static_uri =~ s!/$!!;
        $param->{ html_head } .= <<MTML;
<style type ="text/css">
.dashboard .entry-status-template {
    background-image: url( '$static_uri/plugins/TemplateSelector/images/status_template.gif' );
}
</style>
MTML
    }
}

sub _entry_tmpl {
    return <<'TMPL';
<MTIf tag="MTEntryBody">
<div class="text">
<$MTEntryBody$>
</div>
</MTIf>
<MTIf tag="MTEntryMore">
<div class="text_more">
<$MTEntryMore$>
</div>
</MTIf>
<div class="extrafields">
<MTExtFields>
    <MTIfExtFieldType type="text">
        <h3><$MTExtFieldText$></h3>
    </MTIfExtFieldType>
    <MTIfExtFieldType type="textarea">
        <$MTExtFieldText$>
    </MTIfExtFieldType>
    <MTIfExtFieldType type="file">
        <MTIfExtFieldNonEmpty>
            <MTIfExtFieldTypeImage>
                <p><img src="<$MTExtFieldFilePath$>" alt="<$MTExtFieldAlt escape="html"$>" width="<$MTExtFieldImageWidth$>" height="<$MTExtFieldImageHeight$>" /></p>
            <MTElse>
                <p>Download:<a href="<$MTExtFieldFilePath$>"><img src="<$MTStaticWebPath$>plugins/ExtFields/icons/icon32_<$MTExtFieldFileSuffix$>.gif" width="32" width="32"><$MTExtFieldAlt escape="html"$></a></p>
            </MTElse>
            </MTIfExtFieldTypeImage>
        </MTIfExtFieldNonEmpty>
    </MTIfExtFieldType>
    <MTIfExtFieldType type="cbgroup">
            <MTIfExtFieldNonEmpty>
                <p><$MTExtFieldText$></p>
            </MTIfExtFieldNonEmpty>
    </MTIfExtFieldType>
    <MTIfExtFieldType type="radio">
        <MTIfExtFieldNonEmpty>
            <p><$MTExtFieldLabel escape="html"$>:<$MTExtFieldText$></p>
        </MTIfExtFieldNonEmpty>
    </MTIfExtFieldType>
    <MTIfExtFieldType type="select">
        <MTIfExtFieldNonEmpty>
            <p><$MTExtFieldLabel escape="html"$>:<$MTExtFieldText$></p>
        </MTIfExtFieldNonEmpty>
    </MTIfExtFieldType>
    <MTIfExtFieldType type="checkbox">
        <MTIfExtFieldNonEmpty>
            <p><$MTExtFieldText$></p>
        </MTIfExtFieldNonEmpty>
    </MTIfExtFieldType>
    <MTIfExtFieldType type="date">
        <MTIfExtFieldNonEmpty>
            <p><$MTExtFieldLabel escape="1"$>:<$MTExtFieldText$></p>
        </MTIfExtFieldNonEmpty>
    </MTIfExtFieldType>
</MTExtFields>
</div>
TMPL
}

sub _page_tmpl {
    return <<'TMPL';
<MTIf tag="MTPageBody">
<div class="text">
<$MTPageBody$>
</div>
</MTIf>
<MTIf tag="MTPageMore">
<div class="text_more">
<$MTPageMore$>
</div>
</MTIf>
<div class="extrafields">
<MTExtFields>
    <MTIfExtFieldType type="text">
        <h3><$MTExtFieldText$></h3>
    </MTIfExtFieldType>
    <MTIfExtFieldType type="textarea">
        <$MTExtFieldText$>
    </MTIfExtFieldType>
    <MTIfExtFieldType type="file">
        <MTIfExtFieldNonEmpty>
            <MTIfExtFieldTypeImage>
                <p><img src="<$MTExtFieldFilePath$>" alt="<$MTExtFieldAlt escape="html"$>" width="<$MTExtFieldImageWidth$>" height="<$MTExtFieldImageHeight$>" /></p>
            <MTElse>
                <p>Download:<a href="<$MTExtFieldFilePath$>"><img src="<$MTStaticWebPath$>plugins/ExtFields/icons/icon32_<$MTExtFieldFileSuffix$>.gif" width="32" width="32"><$MTExtFieldAlt escape="html"$></a></p>
            </MTElse>
            </MTIfExtFieldTypeImage>
        </MTIfExtFieldNonEmpty>
    </MTIfExtFieldType>
    <MTIfExtFieldType type="cbgroup">
            <MTIfExtFieldNonEmpty>
                <p><$MTExtFieldText$></p>
            </MTIfExtFieldNonEmpty>
    </MTIfExtFieldType>
    <MTIfExtFieldType type="radio">
        <MTIfExtFieldNonEmpty>
            <p><$MTExtFieldLabel escape="html"$>:<$MTExtFieldText$></p>
        </MTIfExtFieldNonEmpty>
    </MTIfExtFieldType>
    <MTIfExtFieldType type="select">
        <MTIfExtFieldNonEmpty>
            <p><$MTExtFieldLabel escape="html"$>:<$MTExtFieldText$></p>
        </MTIfExtFieldNonEmpty>
    </MTIfExtFieldType>
    <MTIfExtFieldType type="checkbox">
        <MTIfExtFieldNonEmpty>
            <p><$MTExtFieldText$></p>
        </MTIfExtFieldNonEmpty>
    </MTIfExtFieldType>
    <MTIfExtFieldType type="date">
        <MTIfExtFieldNonEmpty>
            <p><$MTExtFieldLabel escape="html"$>:<$MTExtFieldText$></p>
        </MTIfExtFieldNonEmpty>
    </MTIfExtFieldType>
</MTExtFields>
</div>
TMPL
}

sub _cb_restore {
    my $self = shift;
    my ( $all_objects, $deferred, $errors, $callback ) = @_;
    for my $key ( keys %$all_objects ) {
        if ( $key =~ /^MT::Entry#(\d+)$/ || $key =~ /^MT::Page#(\d+)$/ ) {
            my $new_entry = $all_objects->{$key};
            if ( my $template_module_id = $new_entry->template_module_id ) {
                my $new_template = $all_objects->{ 'MT::Template#'.$template_module_id };
                $new_entry->template_module_id( $new_template ? $new_template->id : undef );
                $new_entry->update();
            }
        }
    }
    1;
}

1;
