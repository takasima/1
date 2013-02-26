package SnippetField::Field;

use strict;
use SnippetField::Util qw( file_basename uniq_filename move_file support_dir upload
                           site_path is_writable is_user_can save_asset file_label temporary_asset );

#   Example:
#
# Field Options: snippet_value1,snippet_value2,snippet_value3,snippet_image
# Field Default:
# <p><input type="text" name="snippet_value1"
#     value="<mt:var name="snippet_value1" escape="html">" class="full-width ti" id="<mt:var name="field_id">" /></p>
# <p><input type="text" name="snippet_value2"
#     value="<mt:var name="snippet_value2" escape="html">" class="full-width ti" /></p>
# <p><label>
#     <input type="checkbox" name="snippet_value3" value="1"
#     <mt:loop name="snippet_value3_loop"><mt:if name="snippet_option" eq="1">checked="checked"</mt:if>
#     </mt:loop> />
#     option1
# </label>
# <label>
#     <input type="checkbox" name="snippet_value3" value="2"
#     <mt:loop name="snippet_value3_loop"><mt:if name="snippet_option" eq="2">checked="checked"</mt:if>
#     </mt:loop> />
#     option2
# </label></p>
# <p>
# <mt:if name="snippet_image">
#     <input type="hidden" name="snippet_image_original" value="<mt:var name="snippet_image_original" escape="html">" />
#     <mt:if name="snippet_image_thumbnail">
#     <a href="<mt:var name="snippet_image" escape="html">" target="_blank"><img src="<mt:var name="snippet_image_thumbnail">" width="100" height="100" alt="" /></a>
#     <mt:else>
#     <a href="<mt:var name="snippet_image" escape="html">" target="_blank"><mt:var name="snippet_image" escape="html"></a>
#     <mt:else>
#     </mt:else>
#     </mt:if>
# </mt:else>
# </mt:if>
# <input type="file" name="snippet_image" />
# <mt:if name="snippet_image">
# <label>
#     <input type="checkbox" name="snippet_image_remove" <mt:if name="snippet_image_remove">checked="checked"</mt:if> value="1" /> 削除
# </label>
# </mt:if>
# </p>

sub _init_tags {
    my $app = MT->instance();
    return 1 if ( ref $app ) eq 'MT::App::Upgrader';
    require MT::Request;
    my $r = MT::Request->instance;
    my $cache = $r->cache( 'plugin-snippetfield-init' );
    return 1 if $cache;
    $r->cache( 'plugin-snippetfield-init', 1 );
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
    my $core = MT->component( 'SnippetField' );
    my @fields = MT->model( 'field' )->load( { type => 'snippet' } );
    my $commercial = MT->component( 'commercial' );
    my $tags = $commercial->registry( 'tags' );
    for my $field ( @fields ) {
        my $field_type = $field->type;
        my $tag = $field->tag;
        $tag = lc( $tag );
        delete( $tags->{ function }->{ $tag } );
        delete( $tags->{ block }->{ $tag . 'asset' } );
        $tags->{ function }->{ $tag } = sub {
            my ( $ctx, $args ) = @_;
            require CustomFields::Template::ContextHandlers;
            my $field = CustomFields::Template::ContextHandlers::find_field_by_tag( $ctx )
                or return _no_field( $ctx );
            local $ctx->{ __stash }{ field } = $field;
            my $data = CustomFields::Template::ContextHandlers::_hdlr_customfield_value( @_ );
            return '' unless $data;
            my $key = $args->{ key } || 'snippet';
            my $glue = $args->{ glue } || ',';
            if (! ref $data ) {
                require MT::Serialize;
                $data = MT::Serialize->unserialize( $data );
            }
            my $params = $data;
            return '' unless ( ref $params ) eq 'HASH';
            my $value = $params->{ $key };
            if ( ( ref $value ) eq 'ARRAY' ) {
                return join( $glue, @$value );
            }
            if ( $value && ( ref $value ) eq 'HASH' && ! %$value ) {
                return '';   
            }
            return $value;
        };
        $tags->{ block }->{ $tag . 'asset' } = sub {
            my ( $ctx, $args, $cond ) = @_;
            require CustomFields::Template::ContextHandlers;
            my $field = CustomFields::Template::ContextHandlers::find_field_by_tag( $ctx, $tag )
                or return _no_field( $ctx );
            local $ctx->{ __stash }{ field } = $field;
            my $data = CustomFields::Template::ContextHandlers::_hdlr_customfield_value( @_ );
            return '' unless $data;
            my $key = $args->{ key } || 'snippet';
            if (! ref $data ) {
                require MT::Serialize;
                $data = MT::Serialize->unserialize( $data );
            }
            my $params = $data;
            my $value = $params->{ $key };
            return '' unless $value;
            my $tokens = $ctx->stash( 'tokens' );
            my $builder = $ctx->stash( 'builder' );
            my $vars = $ctx->{ __stash }{ vars } ||= {};
            my $old_vars = $vars;
            if ( $value =~ m/^__snippet_preview_upload__/ ) {
                $value =~ s/^__snippet_preview_upload__//;
                if ( my $asset = temporary_asset( $value ) ) {
                    $ctx->stash( 'asset', $asset );
                } else {
                    return '';
                }
            } elsif ( $value =~ m/^__snippet_upload_asset__([0-9]{1,})$/ ) {
                my $asset_id = $1;
                require MT::Asset;
                if ( my $asset = MT::Asset->load( $asset_id ) ) {
                    $ctx->stash( 'asset', $asset );
                } else {
                    return '';
                }
            } else {
                return '';
            }
            my $out = $builder->build( $ctx, $tokens, $cond );
            $vars = $ctx->{ __stash }{ vars } = $old_vars;
            return $out;
        };
        $tags->{ block }->{ $tag . 'vars' } = sub {
            my ( $ctx, $args, $cond ) = @_;
            require CustomFields::Template::ContextHandlers;
            my $field = CustomFields::Template::ContextHandlers::find_field_by_tag( $ctx, $tag )
                or return _no_field( $ctx );
            local $ctx->{ __stash }{ field } = $field;
            my $data = CustomFields::Template::ContextHandlers::_hdlr_customfield_value( @_ );
            return '' unless $data;
            my $key = $args->{ key } || 'snippet';
            if (! ref $data ) {
                require MT::Serialize;
                $data = MT::Serialize->unserialize( $data );
            }
            my $params = $data;
            my $value = $params->{ $key };
            my @snipped_loop;
            if ( ( ref $value ) eq 'ARRAY' ) {
                for my $val ( @$value ) {
                    push ( @snipped_loop, { snippet_option => $val } );
                }
            } else {
                push ( @snipped_loop, { snippet_option => $value } );
            }
            my $tokens = $ctx->stash( 'tokens' );
            my $builder = $ctx->stash( 'builder' );
            my $vars = $ctx->{ __stash }{ vars } ||= {};
            my $old_vars = $vars;
            my $res = '';
            my $counter = 1;
            my $odd = 1;
            my $even = 0;
            for my $snippet ( @snipped_loop ) {
                $vars->{ snippet_option } = $snippet->{ snippet_option };
                $vars->{ __counter__ } = $counter;
                $vars->{ __first__ } = 1 if ( $counter == 1 );
                $vars->{ __first__ } = 0 if ( $counter != 1 );
                $vars->{ __value__ } = $snippet->{ snippet_option };
                $vars->{ __last__ } = 1 if ( $counter == ( scalar @snipped_loop ) );
                $vars->{ __last__ } = 0 if ( $counter != ( scalar @snipped_loop ) );
                $vars->{ __odd__ } = $odd;
                $vars->{ __even__ } = $even;
                my $out = $builder->build( $ctx, $tokens, $cond );
                $res .= $out;
                $counter++;
                if (! $even ) { $even = 1 } else { $even = 0 };
                if (! $odd ) { $odd = 1 } else { $odd = 0 };
            }
            $vars = $ctx->{ __stash }{ vars } = $old_vars;
            return $res;
        };
    }
}

sub _no_field {
    my ( $ctx ) = @_;
    return $ctx->error( MT->translate(
        "You used an '[_1]' tag outside of the context of the correct content; ",
        $ctx->stash( 'tag' ) ) );
}

sub _preview_snippet {
    my ( $cb, $app, $obj, $params ) = @_;
    if (! $app->param( 'customfield_beacon' ) ) {
        return;
    }
    my $q = $app->param();
    my $support_dir = support_dir();
    require File::Spec;
    my $upload_dir = File::Spec->catdir( $support_dir, 'snippet_temp_dir' );
    for my $key ( $q->param ) {
        if ( $key =~ /^__customfield_(.*)$/ ) {
            my $basename = 'field.' . $1;
            if ( $q->param( $key ) eq '__ignore_snippet_field' ) {
                push @$params, {
                          data_name  => $key,
                          data_value => '__ignore_snippet_field',
                      };
                $key =~ s/^__//;
                my $data;
                my $option_key = '__ignore_snippet_field_' . $key . '_options';
                my $option = $q->param( $option_key );
                my $required = $q->param( '__ignore_snippet_field_' . $key . '_required' );
                # my $label = $q->param( '__ignore_snippet_field_customfield_' . $key . '_label' );
                my $field_input;
                if ( $option ) {
                    push @$params,
                      {
                          data_name  => $option_key,
                          data_value => $option,
                      };
                    my @options = split( /,/, $option );
                    for my $opt ( @options ) {
                        my $value = $q->param( $opt );
                        my @values = $q->param( $opt );
                        my $upload = $q->upload( $opt );
                        if ( my $original = $q->param( $opt . '_original' ) ) {
                            $value = $original;
                        }
                        if ( $upload ) {
                            # TODO :: Check Permission.
                            my %params = ( rename => 1,
                                           singler => 1,
                                           no_asset => 1,
                                          );
                            if ( my $asset = upload( $app, $app->blog, $opt, $upload_dir, \%params ) ) {
                                my $tmp = '__snippet_preview_upload__' . $asset;
                                require MT::Session;
                                my $file_basename = file_basename( $asset );
                                my $sess = MT::Session->get_by_key( { name => $asset, kind => 'TF' } );
                                $sess->id( $file_basename );
                                $sess->start( time );
                                $sess->save or die $sess->errstr;
                                $data->{ $opt } = $tmp;
                                push @$params,
                                  {
                                      data_name  => $opt,
                                      data_value => $tmp,
                                  };
                            }
                            $field_input = 1;
                        } elsif ( scalar @values > 1 ) {
                            $data->{ $opt } = \@values;
                            $field_input = 1;
                            for my $pv ( @values ) {
                                push @$params,
                                  {
                                      data_name  => $opt,
                                      data_value => $pv,
                                  };
                            }
                        } else {
                            push @$params,
                              {
                                  data_name  => $opt,
                                  data_value => $value,
                              };
                            if ( my $remove = $q->param( $opt . '_remove' ) ) {
                                $value = '';
                                push @$params,
                                  {
                                      data_name  => $opt . '_remove',
                                      data_value => 1,
                                  };
                            }
                            $data->{ $opt } = $value;
                            $field_input = 1 if $value;
                        }
                    }
                }
                if ( $field_input ) {
                    require MT::Serialize;
                    my $ser = MT::Serialize->serialize( \$data );
                    # $app->param( $key, $ser );
                    $obj->$basename( $data );
                } else {
                    $app->param( $key, '' );
                    # $q->param( $key, '' );
                    $obj->$basename( undef );
                }
            }
        }
    }
    # PATCH
    my $key = 'preview:' . $obj->class_type . ':' . $app->user->id . ':' . $obj->id;
    my $r = MT::Request->instance();
    $r->cache( $key, $obj );
    # /PATCH
    return 1;
}

sub _save_snippet {
    my ( $cb, $app ) = @_;
    if (! $app->param( 'customfield_beacon' ) ) {
        return 1;
    }
    my @snippet_fields;
    my @upload_fields;
    my $snippet_data;
    my $q = $app->param();
    require MT::Request;
    my $r = MT::Request->instance;
    for my $key ( $q->param ) {
        if ( $key =~ /^__customfield_(.*)$/ ) {
            my $basename = 'field.' . $1;
            my $field_name = 'customfield_' . $1;
            if ( $q->param( $key ) eq '__ignore_snippet_field' ) {
                $key =~ s/^__//;
                my $data;
                my $option = $q->param( '__ignore_snippet_field_' . $key . '_options' );
                my $required = $q->param( '__ignore_snippet_field_' . $key . '_required' );
                my $label = $q->param( '__ignore_snippet_field_' . $key . '_label' );
                my $field_input;
                if ( $option ) {
                    my @options = split( /,/, $option );
                    push ( @snippet_fields, @options );
                    for my $opt ( @options ) {
                        my $value = $q->param( $opt );
                        if ( my $original = $q->param( $opt . '_original' ) ) {
                            $value = $original;
                        }
                        if ( my $remove = $q->param( $opt . '_remove' ) ) {
                            $value = '';
                        }
                        my @values = $q->param( $opt );
                        my $upload = $q->upload( $opt );
                        if ( $upload ) {
                            my $val = $q->param( $opt );
                            $data->{ $opt } = $val . ''; ## to_string
                            push ( @upload_fields, $opt );
                            $field_input = 1;
                        } elsif ( scalar @values > 1 ) {
                            $data->{ $opt } = \@values;
                            $field_input = 1;
                        } else {
                            $data->{ $opt } = $value;
                            $field_input = 1 if $value;
                        }
                    }
                }
                if ( $data ) {
                    # require MT::Serialize;
                    # my $ser = MT::Serialize->serialize( \$data );
                    # $app->param( $key, $ser ); # couldn't save multipart
                    # $snippet_data->{ $basename } = $ser;
                    $snippet_data->{ $basename } = $data;
                    if ( $required ) {
                        $app->param( $field_name, 1 );
                    }
                } else {
                    if ( $required ) {
                        $cb->error( MT->component( 'SnippetField' )->translate( 'Please enter some value for required \'[_1]\' field.', $label ) );
                        return 0;
                    }
                }
            }
        }
    }
    $r->cache( 'snippet_fields_snippet_data', $snippet_data );
    $r->cache( 'snippet_fields_snippet_names', \@snippet_fields );
    $r->cache( 'snippet_fields_upload_fields', \@upload_fields );
    return 1;
}

sub _customfield_types {
    my $customfield_types = {
        snippet => {
            label             => 'Snippet',
            column_def        => 'vblob',
            order             => 333,
            field_html        => \&_field_html,
            field_html_params => \&_field_html_params,
            options_field => \&_field_options,
            default_value => '',
        },
    };
}

sub _field_options {
    return <<'MTML';
<__trans_section component="SnippetField">
    <input type="text" name="options" value="<mt:var name="options" escape="html">" id="options" class="full-width text" />
    <p class="hint"><__trans phrase="Please enter all input element's &quot;name&quot; attributes for this field as a comma delimited list."></p>
</__trans_section>
MTML
}

sub _field_html {
    return <<'MTML';
<__trans_section component="SnippetField">
<mt:if name="edit_field">
<div>
    <textarea rows="17" name="<mt:var name="field_name" escape="html">" id="<mt:var name="field_id">" class="full-width ta text low" rows="3" cols="72"><mt:var name="field_value" escape="html"></textarea>
</div>
<mt:else>
<mt:var name="default" mteval="1">
    <input type="hidden" name="__<mt:var name="field_name" escape="html">" value="__ignore_snippet_field" />
    <input type="hidden" name="__ignore_snippet_field_<mt:var name="field_name" escape="html">_options" value="<mt:var name="options" escape="html">" />
<mt:if name="required">
    <input type="hidden" name="<mt:var name="field_name" escape="html">" value="" />
    <input type="hidden" name="__ignore_snippet_field_<mt:var name="field_name" escape="html">_label" value="<mt:var name="field_label" escape="html">" />
    <input type="hidden" name="__ignore_snippet_field_<mt:var name="field_name" escape="html">_required" value="1" />
</mt:if>
</mt:else>
</mt:if>
</__trans_section>
MTML
}

sub _field_html_params {
    my ( $key, $tmpl, $param ) = @_;
    my $app = MT->instance;
    my $support_directory_url = $app->support_directory_url;
    my $support_directory_path = quotemeta( support_dir() );
    if ( $app->param( 'reedit' ) ) {
        my $q = $app->param();
        for my $key ( $q->param ) {
            if ( $key =~ /^__customfield_(.*)$/ ) {
                my $basename = 'field.' . $1;
                if ( $q->param( $key ) eq '__ignore_snippet_field' ) {
                    $key =~ s/^__//;
                    my $data;
                    my $option_key = '__ignore_snippet_field_' . $key . '_options';
                    my $option = $q->param( $option_key );
                    my $required = $q->param( '__ignore_snippet_field_' . $key . '_required' );
                    if ( $option ) {
                        my @options = split( /,/, $option );
                        for my $opt ( @options ) {
                            my $value = $q->param( $opt );
                            $param->{ $opt . '_original' } = $value;
                            my $set = 0;
                            if ( $value ) {
                                if ( $value =~ m/^__snippet_preview_upload__/ ) {
                                    $value =~ s/^__snippet_preview_upload__//;
                                    if ( my $asset = temporary_asset( $value ) ) {
                                        if ( $asset->class eq 'image' ) {
                                            my ( $thumbnail, $w, $h ) = __get_thumbnail( $asset );
                                            $param->{ $opt . '_thumbnail' } = $thumbnail;
                                        }
                                        my $url = $asset->url;
                                        if ( $url ) {
                                            # $url =~ s!https{0,1}://.*?/!/!;
                                            $param->{ $opt } = $url;
                                            $set++;
                                        }
                                    }
                                    $value =~ s/^$support_directory_path/$support_directory_url/;
                                }
                            }
                            if ( $value =~ m/^__snippet_upload_asset__([0-9]{1,})$/ ) {
                                my $asset_id = $1;
                                require MT::Asset;
                                if ( my $asset = MT::Asset->load( $asset_id ) ) {
                                    if ( $asset->class eq 'image' ) {
                                        my ( $thumbnail, $w, $h ) = __get_thumbnail( $asset );
                                        $param->{ $opt . '_thumbnail' } = $thumbnail;
                                    }
                                    my $url = $asset->url;
                                    if ( $url ) {
                                       # $url =~ s!https{0,1}://.*?/!/!;
                                        $param->{ $opt } = $url;
                                        $set++;
                                    }
                                } else {
                                    $param->{ $opt } = '';
                                }
                            }
                            my @values = $q->param( $opt );
                            my @snipped_loop;
                            if ( scalar @values > 1 ) {
                                for my $val ( @values ) {
                                    push ( @snipped_loop, { snippet_option => $val } );
                                }
                                $param->{ $opt } = $value;
                            } else {
                                if ( my $remove = $q->param( $opt . '_remove' ) ) {
                                    $param->{ $opt . '_remove' } = 1;
                                }
                                unless ( $set ) {
                                    $param->{ $opt } = $value;
                                }
                                push ( @snipped_loop, { snippet_option => $value } );
                            }
                            $param->{ $opt . '_loop' } = \@snipped_loop;
                        }
                    }
                }
            }
        }
    } else {
        my $field_value = $param->{ field_value };
        if ( $field_value ) {
#             require MT::Serialize;
#             my $out = MT::Serialize->unserialize( $field_value );
#             my $params = $$out;
            my $params = $field_value;
            if ( ( ref $params ) eq 'HASH' ) {
                for my $key ( keys %$params ) {
                    my $value = $params->{ $key };
                    $param->{ $key } = $value;
                    $param->{ $key . '_original' } = $value;
                    my @snipped_loop;
                    if ( ( ref $value ) eq 'ARRAY' ) {
                        for my $val ( @$value ) {
                            push ( @snipped_loop, { snippet_option => $val } );
                        }
                    } elsif ( ( ref $value ) eq 'HASH' ) {
                        if ( keys %$value ) {
                            for my $ref_key ( keys %$value ) {
                                $param->{ $key }->{ $ref_key } = $value->{ $ref_key };
                            }
                        } else {
                            $param->{ $key } = undef;
                            $param->{ $key . '_original' } = undef;
                        }
                    } else {
                        if ( $value ) {
                            if ( $value =~ m/^__snippet_preview_upload__/ ) {
                                $value =~ s/^__snippet_preview_upload__//;
                                $value =~ s/^$support_directory_path/$support_directory_url/;
                                $param->{ $key } = $value;
                            }
                            if ( $value =~ m/^__snippet_upload_asset__([0-9]{1,})$/ ) {
                                my $asset_id = $1;
                                require MT::Asset;
                                if ( my $asset = MT::Asset->load( $asset_id ) ) {
                                    if ( $asset->class eq 'image' ) {
                                        my ( $thumbnail, $w, $h ) = __get_thumbnail( $asset );
                                        $param->{ $key . '_thumbnail' } = $thumbnail;
                                    }
                                    my $url = $asset->url;
                                    if ( $url ) {
                                        # $url =~ s!https{0,1}://.*?/!/!;
                                        $param->{ $key } = $url;
                                    }
                                } else {
                                    $param->{ $key } = '';
                                }
                            }
                        }
                        push ( @snipped_loop, { snippet_option => $value } );
                    }
                    $param->{ $key . '_loop' } = \@snipped_loop;
                }
            }
        }
    }
    if ( $app->param( '_type' ) eq 'field' ) {
        $param->{ edit_field } = 1;
    }
    return 1;
}

sub _cms_post_save {
    my ( $cb, $app, $obj, $original ) = @_;
    if (! $app->param( 'customfield_beacon' ) ) {
        return 1;
    }
    my $class = $app->param( '_type' );
    my $cf_type = MT->registry( 'customfield_objects' );
    if (! exists $cf_type->{ $class } ) {
        return 1;
    }
    my $do;
    require MT::Request;
    my $r = MT::Request->instance;
    my $snippet_fields = $r->cache( 'snippet_fields_snippet_names' );
    my $snippet_data = $r->cache( 'snippet_fields_snippet_data' );
    my $upload_fields = $r->cache( 'snippet_fields_upload_fields' );
    my $blog = $app->blog;
    require File::Spec;
    require MT::Serialize;
    my $upload_dir;
    if ( $blog ) {
        $upload_dir = site_path( $blog );
        $upload_dir = File::Spec->catdir( $upload_dir, 'upload' );
    } else {
        $upload_dir = File::Spec->catdir( support_dir(), 'upload' );
    }
    if ( $snippet_data ) {
        for my $key ( keys %$snippet_data ) {
            my $data = $snippet_data->{ $key };
            my $orig_meta = MT::Serialize->unserialize( $obj->$key );
            $orig_meta = $$orig_meta;
            for my $name ( keys %$data ) {
                my $field_value = $data->{ $name };
                if ( $upload_fields && grep( /^$name$/, @$upload_fields ) ) {
                    my %params = ( object => $obj,
                                   author => $app->user,
                                   rename => 1,
                                   singler => 1,
                                   label => file_label( $field_value ),
                                   # no_asset => 0,
                                  );
                    if ( my $asset = upload( $app, $blog, $name, $upload_dir, \%params ) ) {
                        if ( $asset ) {
                            $data->{ $name } = '__snippet_upload_asset__' . $asset->id;
                            if ( $orig_meta && $orig_meta->{ $name } ) {
                                my $old = $orig_meta->{ $name };
                                if ( $old =~ /^__snippet_upload_asset__([0-9]{1,})$/ ) {
                                    my $old_id = $1;
                                    require MT::Asset;
                                    if ( my $old_asset = MT::Asset->load( $old_id ) ) {
                                        require MT::ObjectAsset;
                                        my $datasource = $obj->datasource;
                                        my @objectasset = MT::ObjectAsset->load( { asset_id => $old_id,
                                                                                   object_ds => $datasource } );
                                        if ( @objectasset ) {
                                            if ( scalar ( @objectasset ) == 1 ) {
                                                $old_asset->remove or die $old_asset->errstr;
                                            }
                                            for my $rel ( @objectasset ) {
                                                if ( $rel->object_id == $obj->id ) {
                                                    $rel->remove or die $rel->errstr;
                                                    last;
                                                }
                                            }
                                        } else {
                                            $old_asset->remove or die $old_asset->errstr;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                if ( $field_value =~ /^__snippet_preview_upload__(.*)$/ ) {
                    my $path = $1;
                    if (-f $path ) {
                        my $new = uniq_filename( File::Spec->catfile( $upload_dir, file_basename( $path ) ) );
                        if ( move_file( $path, $new ) ) {
                            if ( $blog ) {
                                my %params = ( file => $new, object => $obj );
                                my $asset = save_asset( $app, $blog, \%params, 1 );
                                if ( $asset ) {
                                    $data->{ $name } = '__snippet_upload_asset__' . $asset->id;
                                }
                            }
                        }
                    }
                }
            }
            # TODO :: __snippet_preview_upload__
            $app->run_callbacks( 'pre_save_snippet', $app, \$data );
#             my $ser = MT::Serialize->serialize( \$data );
#             $obj->$key( $ser );
            if ( $obj->has_column( 'ext_datas' ) ) {
                my $ext_datas = $obj->ext_datas();
                for my $data_value ( values %$data ) {
                    if ( $data_value =~ m/^__snippet_upload_asset__([0-9]{1,})$/ ) {
                        my $asset_id = $1;
                        if ( my $asset = MT->model( 'asset' )->load( $asset_id ) ) {
                            $ext_datas .= "\n" . $asset->file_name;
                        }
                    } elsif ( ( ref $data_value ) eq 'ARRAY' ) {
                        $ext_datas .= "\n" . join( "\n", @$data_value );
                    } else {
                        $ext_datas .= "\n" . $data_value;
                    }
                }
                $obj->ext_datas( $ext_datas );
            }
            $obj->$key( $data );
            $do = 1;
            # TODO :: Save Upload File(At Save or reedit).
        }
    }
    if ( $do ) {
        $obj->save;
    }
    return 1;
}

sub __get_thumbnail {
    my $asset = shift;
    my %args;
    $args{ Square } = 1;
    if ( $asset->image_height > $asset->image_width ) {
        $args{ Width } = 100;
    } else {
        $args{ Height } = 100;
    }
    return $asset->thumbnail_url( %args );
}

1;
