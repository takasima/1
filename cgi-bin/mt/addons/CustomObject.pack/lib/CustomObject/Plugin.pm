package CustomObject::Plugin;

use strict;
use MT::Util qw( trim format_ts offset_time_list encode_js encode_url decode_url
                 encode_html decode_html ts2epoch epoch2ts );
use MT::I18N qw( substr_text length_text );
use CustomObject::Util qw( is_user_can build_tmpl upload utf8_on is_application valid_ts
                           get_weblogs current_ts remove_item csv_new read_from_file
                           plugin_template_path encode_utf8_string_to_cp932_octets
                           make_zip_archive write2file get_config_inheritance is_cms
                           is_oracle );
use File::Temp qw( tempdir );
                     
sub initializer {
    require CustomObject::Patch;
    require CustomObject::OverRide;
}

sub _init_request {
    my $app = MT->instance;
    if ( ref $app eq 'MT::App::CMS' ) {
        if ( ( $app->param( 'dialog_view' ) ) || ( MT->version_id =~ /^5\.0/ ) ) {
            $app->add_methods( list_customobject => \&_list_customobject );
            $app->add_methods( list_customobjectgroup => \&_list_customobject );
        }
    }
    $app;
}

sub _pre_run {
    my ( $cb, $app ) = @_;
    my $custom_objects = MT->registry( 'custom_objects' );
    my @objects = keys( %$custom_objects );
    my $menus = MT->registry( 'applications', 'cms', 'menus' );
    if ( ( $app->mode eq 'save' ) || ( $app->mode eq 'view' ) ) {
        my $_type = $app->param( '_type' );
        if ( grep( /^$_type$/, @objects ) ) {
            my $component = MT->component( $_type );
            if ( $component ) {
                if ( $app->mode eq 'save' ) {
                    $app->{ plugin_template_path } = plugin_template_path( $component );
                } elsif ( $app->mode eq 'view' ) {
                    if ( $app->request_method eq 'GET' ) {
                        my $_type = $app->param( '_type' );
                        if ( $_type ne 'customobject' ) {
                            my $query = $app->query_string;
                            my @qs = split( /;/, $query );
                            my @new_query;
                            for my $q ( @qs ) {
                                my @arg = split( /=/, $q );
                                my $val;
                                $val = $arg[1] if $arg[1];
                                my $pa = $arg[0];
                                if ( $pa eq '_type' ) {
                                    $val = 'customobject';
                                }
                                push ( @new_query, $pa . '=' . $val );
                            }
                            if (! $app->param( 'class' ) ) {
                                push ( @new_query, 'class=' . $_type );
                            }
                            my $return_args = join( '&', @new_query );
                            my $return_url = $app->base . $app->uri . '?' . $return_args;
                            return $app->print( "Location: $return_url\n\n" );
                        }
                    }
                }
           }
        }
    }
    my $search_order = 700;
    for my $class ( @objects ) {
        my $id = $custom_objects->{ $class }->{ id };
        my $plugin = MT->component( $class );
        my $config_plugin = $plugin;
        if ( $class eq 'customobject' ) {
            $config_plugin = MT->component( 'CustomObjectConfig' );
        }
        if ( MT->version_id =~ /^5\.0/ ) {
            $menus->{ $class . ':list_customobject' }->{ mode } = 'list_customobject';
            $menus->{ $class . ':list_customobjectgroup' }->{ mode } = 'list_customobject';
        }
        my $label = $config_plugin->translate( $id );
        my $module = $id . '::' . 'Plugin';
        eval "require $module";
        $search_order++;
        $plugin->registry->{ search_apis }->{ $class } = {
            handler => '$customobject::CustomObject::Plugin::_search_customobject',
            condition => '$' . $class . '::' . $id . '::Plugin::_' . $class . '_permission',
            perm_check => \&_dummy,
            order => $search_order,
            label => $label,
            results_table_template => 'include/customobject_table.tmpl',
            can_replace => 0,
            can_search_by_date => 1,
            date_column => 'authored_on',
            setup_terms_args => sub {
                my ( $terms, $args, $blog_id ) = @_;
                my $app = MT->instance;
                if ( my $blog = $app->blog ) {
                    if ( $blog->is_blog ) {
                        $terms->{ blog_id } = $blog_id;
                    } else {
                        my @ids;
                        push ( @ids, $blog_id );
                        my $blogs = $blog->blogs;
                        for my $b ( @$blogs ) {
                            if ( _customobject_permission( $b ) ) {
                                push ( @ids, $b->id )
                            }
                        };
                        $terms->{ blog_id } = \@ids;
                    }
                } else {
                    if (! $app->user->is_superuser ) {
                        require MT::Blog;
                        my $all_blogs = MT::Blog->load( { class => '*' } );
                        my @ids;
                        for my $b ( @$all_blogs ) {
                            if ( _customobject_permission( $b ) ) {
                                push ( @ids, $b->id );
                            }
                        }
                        $terms->{ blog_id } = \@ids;
                    }
                }
            },
            search_cols => { body => 'Body', keywords => 'Keywords', name => 'Name' },
        };
    }
    my $fields = MT->registry( 'customfield_types' );
    my $cf_objects = MT->registry( 'customfield_objects' );
    my $field_order = 2500;
    my $cf_order = 10000;
    for my $class ( @objects ) {
        my $component = $class;
        if ( $class eq 'customobject' ) {
            $component = 'CustomObjectConfig';
        }
        my $plugin = MT->component( $component );
        if ( $plugin ) {
            $menus->{ $class }->{ order } = $plugin->get_config_value( 'menu_order' );
            $fields->{ $class }->{ order } = $field_order;
            $field_order++;
            $fields->{ $class . '_multi' }->{ order } = $field_order;
            $field_order++;
            $fields->{ $class . '_group' }->{ order } = $field_order;
            $field_order++;
            $cf_objects->{ order } = $cf_order;
            $cf_order++;
        }
    }
    if ( my $model = $app->param( '_type' ) ) {
        if ( grep( /^$model$/, @objects ) ) {
            if ( $app->mode eq 'save' ) {
                if ( my $id = $app->param( 'id' ) ) {
                    my $original = MT->model( $model )->load( $id );
                    $original = $original->clone_all() if $original;
                    require MT::Request;
                    MT::Request->instance->cache( 'customobject_original' . $id, $original );
                }
            }
        }
    }
    my $lh = MT->language_handle;
    my $package = ref $lh;
    my $map = __map();
    my ( $label_en, $label_ja, $label_plural ) = __get_settings( $app );
    my $search_ja = utf8_on( 'カスタム項目' );
    my $search_en = 'CustomObject';
    my $search_plural = 'CustomObjects';
    my $search_lc = 'customobject';
    my $label_lc = lc( $label_en );
    for my $key ( keys( %$map ) ) {
        my $text = utf8_on( $map->{ $key } );
        $map->{ $key } = $text;
        if ( $package eq 'MT::L10N::ja' ) {
            $text =~ s/$search_ja/$label_ja/g;
            $map->{ $key } = $text;
        } else {
            my $new = $key;
            $new =~ s/$search_en/$label_en/g;
            $new =~ s/$search_plural/$label_plural/g;
            $new =~ s/$search_lc/$label_lc/g;
            $map->{ $key } = $new;
        }
    }
    if ( $package eq 'MT::L10N::ja' ) {
        $map->{ CustomObject } = $label_ja;
    } else {
        $map->{ CustomObject } = $label_en;
    }
    eval(<<END);
package $package;
\$Lexicon{\$_} = \$map->{\$_} foreach ( keys( %\$map ) );
END
    eval(<<'END');
package MT::L10N::ja;
use strict;
use utf8;
our %Lexicon;
$Lexicon{'Entry Listing'} = 'アーカイブ / ブログ記事リスト';
$Lexicon{'Invalid date \'[_1]\'; dates must be in the format YYYY-MM-DD HH:MM:SS.'} = '日時が不正です。日時はYYYY-MM-DD HH:MM:SSの形式で入力してください。';
$Lexicon{'Invalid date \'[_1]\'; dates should be real dates.'} = '日時が不正です。';
$Lexicon{'Please enter valid URL for the URL field: [_1]'} = 'URLを入力してください。[_1]';
$Lexicon{'Please enter some value for required \'[_1]\' field.'} = '「[_1]」は必須です。値を入力してください。';
$Lexicon{'Please ensure all required fields have been filled in.'} = '必須のフィールドに値が入力されていません。';
1;
END
    eval(<<'END');
package MT::L10N::en_us;
use strict;
our %Lexicon;
$Lexicon{'Entry Listing'} = 'Archive / Entry Listing';
1;
END
    return 1;
}

sub _dummy { return 1 }

sub cms_edit_template {
    my ( $cb, $app, $id, $obj, $param ) = @_;
    return 1 if !$app->blog || $app->blog->is_blog;
    if ( defined $app->param('type') && $app->param('type') eq 'archive' ) {
        $app->param( 'type', 'page' );
        $app->param( 'customobject_archive', 1 );
    }
    elsif ( $obj && defined $obj->type && $obj->type eq 'archive' ) {
        $app->param( 'customobject_archive', 1 );
    }
    return 1;
}

sub _create_customobject {
    my $app = shift;
    if ( $app->blog ) {
        $app->return_to_dashboard( redirect => 1 );
    }
    my $component = MT->component( 'CustomObject' );
    return $app->trans_error( 'Permission denied.' ) unless $app->user->is_superuser;
    $app->{ plugin_template_path } = plugin_template_path( $component );
    my $tmpl = 'create_customobject.tmpl';
    my $param;
    $param->{ saved } = $app->param( 'saved' );
    my $action = $app->param( 'action_name' );
    if ( $action && ( ( $action eq 'confirm' ) || ( $action eq 'submit' ) ) ) {
        $app->validate_magic or return $app->trans_error( 'Permission denied.' );
        my @settings = qw(plugin_id plugin_version ja class plural description description_ja menu_order);
        my $error;
        my $id = $app->param( 'plugin_id' );
        for my $setting ( @settings ) {
            my $value = $app->param( $setting );
            if ( $setting eq 'class' ) {
                $value = lc( $app->param( 'plugin_id' ) );
            }
            $param->{ $setting } = $value;
            if (! $value ) {
                $param->{ $setting . '_empty' } = 1;
                $error = 1;
            } else {
                if ( ( $setting eq 'plugin_id' ) || ( $setting eq 'plural' ) ) {
                    if ( $value !~ /^[a-zA-Z]{1,}$/ ) {
                        $param->{ $setting . '_invalid' } = 1;
                        $error = 1;
                    }
                } elsif ( $setting eq 'ja' ) {
                    my $new_value = sanitize_plugin( $value );
                    if ( $new_value ne $value ) {
                        $param->{ $setting . '_invalid' } = 1;
                        $param->{ $setting } = $new_value;
                        $error = 1;
                    }
                } elsif ( $setting eq 'menu_order' ) {
                    if ( $value !~ /^[0-9]{1,}$/ ) {
                        $param->{ $setting . '_invalid' } = 1;
                        $error = 1;
                    }
                } elsif ( $setting eq 'class' ) {
                    if ( $value !~ /^[a-z]{1,}$/ ) {
                        $param->{ $setting . '_invalid' } = 1;
                        $error = 1;
                    } else {
                        if ( MT->model( $value ) ) {
                            $error = 2;
                        }
                        if ( MT->component( $value ) ) {
                            $error = 2;
                        }
                    }
                } elsif ( $setting eq 'plugin_version' ) {
                    if ( $value !~ /^[0-9.]{1,}$/ ) {
                        $param->{ $setting . '_invalid' } = 1;
                        $error = 1;
                    }
                } elsif ( $setting =~ m/description/ ) {
                    my $new_value = sanitize_description( $value );
                    if ( $new_value ne $value ) {
                        $param->{ $setting . '_invalid' } = 1;
                        $param->{ $setting } = $new_value;
                        $error = 1;
                    }
                }
            }
        }
        if ( $error ) {
            $action = 'confirm';
            if ( $error == 1 ) {
                $param->{ error } = $component->translate( 'Please confirm your input values.' );
            } else {
                $param->{ error } = $component->translate( 'Models of the same name already exists.' );
            }
        } else {
            $param->{ confirm_message } = 1
        }
        $param->{ action_mode } = $action;
        if ( $action eq 'submit' ) {
            $param->{ tag_prefix } = 'mt:';
            $param->{ desc_prefix } = '\'<__trans phrase="';
            $param->{ desc_suffix } = '">\'';
            my $plugin_tmpl_dir = File::Spec->catdir( plugin_template_path( $component ), 'plugin_tmpl' );
            my $yaml = File::Spec->catfile( $plugin_tmpl_dir, 'config.yaml.tmpl' );
            my $php = File::Spec->catfile( $plugin_tmpl_dir, 'init.plugin.php.tmpl' );
            my $object = File::Spec->catfile( $plugin_tmpl_dir, 'Object.pm.tmpl' );
            my $plugin = File::Spec->catfile( $plugin_tmpl_dir, 'Plugin.pm.tmpl' );
            my $config = File::Spec->catfile( $plugin_tmpl_dir, 'customobject_config.tmpl' );
            my $l10n = File::Spec->catfile( $plugin_tmpl_dir, 'L10N.pm.tmpl' );
            my $l10nja = File::Spec->catfile( $plugin_tmpl_dir, 'ja.pm.tmpl' );
            my $group = File::Spec->catfile( $plugin_tmpl_dir, 'Group.pm.tmpl' );
            my $list_header = File::Spec->catfile( $plugin_tmpl_dir, 'list_header.tmpl' );
            my $group_list_header = File::Spec->catfile( $plugin_tmpl_dir, 'group_list_header.tmpl' );
            my $edit_class = File::Spec->catfile( $plugin_tmpl_dir, 'edit_class.tmpl' );
            my $archiver = File::Spec->catfile( $plugin_tmpl_dir, 'ArchiveType.tmpl' );
            my $folder_archiver = File::Spec->catfile( $plugin_tmpl_dir, 'FolderArchive.tmpl' );
            my $args;
            $yaml = read_from_file( $yaml );
            $php = read_from_file( $php );
            $object = read_from_file( $object );
            $group = read_from_file( $group );
            $plugin = read_from_file( $plugin );
            $config = read_from_file( $config );
            $l10n = read_from_file( $l10n );
            $l10nja = read_from_file( $l10nja );
            $list_header = read_from_file( $list_header );
            $group_list_header = read_from_file( $group_list_header );
            $edit_class = read_from_file( $edit_class );
            $archiver = read_from_file( $archiver );
            $folder_archiver = read_from_file( $folder_archiver );
            $yaml = build_tmpl( $app, $yaml, $args, $param );
            require YAML::Tiny;
            my $tiny = YAML::Tiny->new;
            $tiny = YAML::Tiny->read_string( $yaml ) || YAML::Tiny->errstr;
            if ( ref $tiny ne 'YAML::Tiny' ) {
                return $component->translate( 'YAML Error \'[_1]\'', $tiny );
            }
            $php = build_tmpl( $app, $php, $args, $param );
            $object = build_tmpl( $app, $object, $args, $param );
            my $check_str;
            $check_str = $object;
            eval ( $check_str );
            if ( $@ ) {
                return $component->translate( 'Module Error in \'[_1]\' \'[_2]\' ', "$id.pm", $@ );
            }
            $group = build_tmpl( $app, $group, $args, $param );
            $check_str = $group;
            eval ( $check_str );
            if ( $@ ) {
                return $component->translate( 'Module Error in \'[_1]\' \'[_2]\' ', $id . 'Group.pm', $@ );
            }
            $plugin = build_tmpl( $app, $plugin, $args, $param );
            $check_str = $plugin;
            eval ( $check_str );
            if ( $@ ) {
                return $component->translate( 'Module Error in \'Plugin.pm\' \'[_1]\' ', $@ );
            }
            $l10n = build_tmpl( $app, $l10n, $args, $param );
            $check_str = $l10n;
            eval ( $check_str );
            if ( $@ ) {
                return $component->translate( 'Module Error in \'L10n.pm\' \'[_1]\' ', $@ );
            }
            $l10nja = build_tmpl( $app, $l10nja, $args, $param );
            $check_str = $l10nja;
            eval ( $check_str );
            if ( $@ ) {
                return $component->translate( 'Module Error in \'ja.pm\' \'[_1]\' ', $@ );
            }
            $archiver = build_tmpl( $app, $archiver, $args, $param );
            $check_str = $archiver;
            eval ( $check_str );
            if ( $@ ) {
                return $component->translate( 'Module Error in \'ArchiveType\' \'[_1]\' ', $@ );
            }
            $folder_archiver = build_tmpl( $app, $folder_archiver, $args, $param );
            $check_str = $folder_archiver;
            eval ( $check_str );
            if ( $@ ) {
                return $component->translate( 'Module Error in \'FolderArchive\' \'[_1]\' ', $@ );
            }
            $config = build_tmpl( $app, $config, $args, $param );
            $config = decode_html( $config );
            my $direct;
            my $workdir;
            if ( MT->config( 'AllowDirectInstall' ) ) {
                my $plugin_dir = MT->config( 'PluginPath' );
                $workdir = File::Spec->catfile( $plugin_dir, $id );
                require MT::FileMgr;
                my $fmgr = MT::FileMgr->new( 'Local' ) or die MT::FileMgr->errstr;
                $workdir =~ s!/$!! unless $workdir eq '/';
                if ( $fmgr->exists( $workdir ) ) {
                    return $component->translate( 'Plugin \'[_1]\' already exist.', $workdir );
                } else {
                    $fmgr->mkpath( $workdir ) || return $component->translate( 'Error writing to \'[_1]\'', $id );
                }
                $direct = 1;
            }
            if (! $direct ) {
                my $tempdir = $app->config( 'TempDir' );
                $workdir = tempdir( DIR => $tempdir );
            }
            my $yaml_out = File::Spec->catfile( $workdir, 'config.yaml' );
            my $object_out = File::Spec->catfile( $workdir, 'lib', $id, $id . '.pm' );
            my $group_out = File::Spec->catfile( $workdir, 'lib', $id, $id . 'Group.pm' );
            my $php_out = File::Spec->catfile( $workdir, 'php', 'init.' . $id . '.php' );
            my $plugin_out = File::Spec->catfile( $workdir, 'lib', $id, 'Plugin.pm' );
            my $config_out = File::Spec->catfile( $workdir, 'tmpl', 'customobject_config.tmpl' );
            my $l10n_out = File::Spec->catfile( $workdir, 'lib', $id, 'L10N.pm' );
            my $l10nja_out = File::Spec->catfile( $workdir, 'lib', $id, 'L10N', 'ja.pm' );
            my $list_header_out = File::Spec->catfile( $workdir, 'tmpl', 'listing', $param->{ class } . '_list_header.tmpl' );
            my $group_list_header_out = File::Spec->catfile( $workdir, 'tmpl', 'listing', $param->{ class } . 'group_list_header.tmpl' );
            my $edit_class_out = File::Spec->catfile( $workdir, 'tmpl', 'edit_' . $param->{ class } . '.tmpl' );
            my $archiver_out = File::Spec->catfile( $workdir, 'lib', 'ArchiveType', $id . '.pm' );
            my $folder_archiver_out = File::Spec->catfile( $workdir, 'lib', 'ArchiveType', 'Folder' . $id . '.pm' );
            write2file( $yaml_out, $yaml );
            write2file( $object_out, $object );
            write2file( $group_out, $group );
            write2file( $php_out, $php );
            write2file( $plugin_out, $plugin );
            write2file( $l10n_out, $l10n );
            write2file( $l10nja_out, $l10nja );
            write2file( $list_header_out, $list_header );
            write2file( $group_list_header_out, $group_list_header );
            write2file( $config_out, $config );
            write2file( $edit_class_out, $edit_class );
            write2file( $archiver_out, $archiver );
            write2file( $folder_archiver_out, $folder_archiver );
            if ( $direct ) {
                $app->add_return_arg( saved => 1 );
                $app->call_return();
            } else {
                my $tmp_file = File::Spec->catfile( $workdir, $id . '.zip' );
                make_zip_archive( $workdir, $tmp_file );
                $app->{ no_print_body } = 1;
                my $basename = $id . '.zip';
                $app->set_header( 'Content-Disposition' => "attachment; filename=$basename" );
                $app->set_header( 'Pragma' => '' );
                $app->send_http_header( 'application/zip' );
                if ( open( my $fh, '<', $tmp_file ) ) {
                    binmode $fh;
                    my $data;
                    while ( read $fh, my ( $chunk ), 8192 ) {
                        $data .= $chunk;
                        print $chunk;
                    }
                    close $fh;
                }
                remove_item( $workdir );
                return;
            }
        }
    }
    return $app->build_page( $tmpl, $param );
}

sub sanitize_plugin {
    my $text = shift;
    $text =~ s/\r|\n|\t|\@|#|\%|:|\$|'|\\//g;
    $text = encode_html( $text );
    return $text;
}

sub sanitize_description {
    my $text = shift;
    $text =~ s/\r|\n|\t|#|\\//g;
    $text =~ s/(\@|#|\%|\$|\\)/\\$1/g;
    $text = encode_html( $text );
    return $text;
}

sub _menu_permission {
    my ( $meth, $plugin ) = @_;
    return 0 unless MT->component( 'CustomObject' );
    $plugin = 'CustomObjectConfig' unless $plugin;
    my $app = MT->instance();
    my $blog = $app->blog;
    my $component = MT->component( $plugin );
    if ( $blog ) {
        if (! $component->get_config_value( 'is_active', 'blog:' . $blog->id ) ) {
            return 0;
        }
    } else {
        if (! $component->get_config_value( 'is_active' ) ) {
            return 0;
        }
    }
    if ( $plugin ne 'CustomObjectConfig' ) {
        return _customobject_permission( undef, $plugin );
    } else {
        return _customobject_permission( undef, 'customobject' );
    }
}

sub _group_menu_permission {
    my ( $meth, $plugin ) = @_;
    return 0 unless MT->component( 'CustomObject' );
    $plugin = 'CustomObjectConfig' unless $plugin;
    my $app = MT->instance();
    my $blog = $app->blog;
    my $component = MT->component( $plugin );
    if ( $blog ) {
        if (! $component->get_config_value( 'is_active', 'blog:' . $blog->id ) ) {
            return 0;
        }
    } else {
        if (! $component->get_config_value( 'is_active' ) ) {
            return 0;
        }
    }
    if ( $plugin ne 'CustomObjectConfig' ) {
        return _group_permission( undef, $plugin );
    } else {
        return _group_permission( undef, 'customobject' );
    }
}

sub _customobject_permission {
    my ( $blog, $class ) = @_;
    my $app = MT->instance();
    my $user = $app->user;
    if ( $blog && ( ref $blog ne 'MT::Blog' ) ) {
        $blog = undef;
    }
    $blog = $app->blog unless $blog;
    return 1 if $user->is_superuser;
    if (! $class ) {
        if ( $app->param( 'class' ) ) {
            $class = $app->param( 'class' );
        } elsif ( $app->param( '_type' ) ) {
            $class = $app->param( '_type' );
        } elsif ( $app->param( 'datasource' ) ) {
            $class = $app->param( 'datasource' );
        }
    }
    $class = 'customobject' unless $class;
    $class =~ s/group$//;
    if ( is_cms( $app ) && $app->mode eq 'search_replace' ) {
        my $custom_objects = MT->registry( 'custom_objects' );
        my @objects = keys( %$custom_objects );
        return 0 unless grep { $_ eq $class } @objects;
    }
    if (! $blog ) {
        my %terms1 = ( author_id => $app->user->id, blog_id => { not => 0 }, permissions => { like => "%'administer_%" } );
        my %terms2 = ( author_id => $app->user->id, blog_id => { not => 0 }, permissions => { like => "%'manage_$class'%" } );
        require MT::Permission;
        my $perms = MT::Permission->count( [ \%terms1, '-or', \%terms2 ] );
        if ( $perms ) {
            return 1;
        } else {
            return 0;
        }
    }
    if ( is_user_can( $blog, $user, 'administer_blog' ) ) {
        return 1;
    }
    if ( is_user_can( $blog, $user, 'administer_website' ) ) {
        return 1;
    }
    if ( is_user_can( $blog, $user, 'manage_' . $class ) ) {
        return 1;
    }
    if ( $app->param( 'dialog_view' ) ) {
        return 1;
    }
    return 0;
}

sub _group_permission {
    my ( $blog, $class ) = @_;
    my $app = MT->instance();
    my $user = $app->user;
    if ( $blog && ( ref $blog ne 'MT::Blog' ) ) {
        $blog = undef;
    }
    $blog = $app->blog unless $blog;
    return 1 if $user->is_superuser;
    if (! $class ) {
        if ( $app->param( 'class' ) ) {
            $class = $app->param( 'class' );
        } elsif ( $app->param( '_type' ) ) {
            $class = $app->param( '_type' );
        } elsif ( $app->param( 'datasource' ) ) {
            $class = $app->param( 'datasource' );
        }
    }
    $class = 'customobject' unless $class;
    $class =~ s/group$//;
    if (! $blog ) {
        my %terms1 = ( author_id => $app->user->id, blog_id => { not => 0 }, permissions => { like => "%'administer_%" } );
        my %terms2 = ( author_id => $app->user->id, blog_id => { not => 0 }, permissions => { like => "%'manage_$class" . "group'%" } );
        require MT::Permission;
        my $perms = MT::Permission->count( [ \%terms1, '-or', \%terms2 ] );
        if ( $perms ) {
            return 1;
        } else {
            return 0;
        }
    }
    if ( is_user_can( $blog, $user, 'administer_blog' ) ) {
        return 1;
    }
    if ( is_user_can( $blog, $user, 'administer_website' ) ) {
        return 1;
    }
    if ( is_user_can( $blog, $user, 'manage_' . $class . 'group' ) ) {
        return 1;
    }
    if ( $app->param( 'dialog_view' ) ) {
        return 1;
    }
    return 0;
}

sub __is_admin {
    my $blog = shift;
    my $app = MT->instance();
    my $user = $app->user;
    $blog = $app->blog unless $blog;
    my $class = 'customobject';
    if ( $app->param( 'class' ) ) {
        $class = $app->param( 'class' );
    }
    return 1 if $user->is_superuser;
    if (! $blog ) {
        return 0;
    }
    if ( is_user_can( $blog, $user, 'administer_blog' ) ) {
        return 1;
    }
    if ( is_user_can( $blog, $user, 'administer_website' ) ) {
        return 1;
    }
    return 0;
}

sub __map {
    my $map = {
    'Label plural' => 'オブジェクト名複数形(英)',
    'CustomObject' => 'カスタム項目',
    'Custom Object' => 'カスタム項目',
    'CustomObjects' => 'カスタム項目',
    'customobject' => 'カスタム項目',
    'My CustomObject' => '自分のカスタム項目',
    'My CustomObjects' => '自分のカスタム項目',
    'My CustomObject Groups' => '自分のカスタム項目グループ',
    'Folder-CustomObject' => 'フォルダ別カスタム項目',
    'Folder-Object' => 'フォルダ別カスタム項目',
    'Tags with CustomObject' => 'カスタム項目のタグ',
    'Multiple CustomObject' => 'カスタム項目(複数選択)',
    'Create CustomObject' => 'カスタム項目の作成',
    'Edit CustomObject' => 'カスタム項目の編集',
    'Manage CustomObjects' => 'カスタム項目の一覧',
    'List of CustomObjects' => 'カスタム項目の一覧',
    'Delete selected CustomObjects (x)' => '選択したカスタム項目を削除 (x)',
    'Delete this CustomObject (x)' => 'このカスタム項目を削除 (x)',
    'Save this CustomObject (s)' => 'このカスタム項目を保存 (s)',
    'CustomObject Group' => 'カスタム項目グループ',
    'CustomObject Groups' => 'カスタム項目グループ',
    'Edit CustomObject Group' => 'カスタム項目グループの編集',
    'Create CustomObject Group' => 'カスタム項目グループの作成',
    'Manage CustomObject Groups' => 'カスタム項目グループの管理',
    'CustomObject Order' => 'カスタム項目グループの表示順',
    'CustomObject requires Name.' => 'カスタム項目には名前が必須です。',
    'Select CustomObject' => 'カスタム項目を選択',
    'Are you sure you want to remove this CustomObject?' => 'このカスタム項目を削除してもよろしいですか?',
    'Are you sure you want to publish selected CustomObjects?' => '選択したカスタム項目を公開してもよろしいですか?',
    'Are you sure you want to unpublish selected CustomObjects?' => '選択したカスタム項目の公開を取り消してもよろしいですか?',
    'Publish CustomObjects from selected datas (p)' => '選択したカスタム項目を公開 (p)',
    'Unublish CustomObjects from selected datas (u)' => '選択したカスタム項目の公開を取り消し (u)',
    'Tags to add to selected CustomObjects:' => '選択した項目に付けるタグ:',
    'Tags to remove from selected CustomObjects:' => '削除するタグ:',
    'Save this CustomObject (s)' => 'このカスタム項目を保存 (s)',
    'Delete this CustomObject (x)' => 'このカスタム項目を削除 (x)',
    'CustomObject Administrator' => 'カスタム項目の管理',
    'Manage CustomObject' => 'カスタム項目の管理',
    'Manage CustomObject Groups' => 'カスタム項目グループの管理',
    'Can create CustomObject, edit CustomObject.' => 'カスタム項目の作成と管理ができます。',
    'List of CustomObjects' => 'カスタム項目の一覧',
    'CustomObject of Group' => 'グループのカスタム項目',
    'Save this CustomObject' => 'このカスタム項目を保存する',
    'Save this CustomObject (s)' => 'このカスタム項目を保存する (s)',
    'Publish this CustomObject' => 'このカスタム項目を公開する',
    'Publish this CustomObject (s)' => 'このカスタム項目を公開する (s)',
    'Re-Edit this CustomObject' => 'このカスタム項目を編集する',
    'Re-Edit this CustomObject (e)' => 'このカスタム項目を編集する (e)',
    'You are previewing the CustomObject entitled &ldquo;[_1]&rdquo;' => 'プレビュー中: カスタム項目「[_1]」',
    'CustomObject \'[_1]\' (ID:[_2]) edited and its status changed from [_3] to [_4] by user \'[_5]\'' => '[_5]がカスタム項目「[_1]」(ID:[_2])を更新し、公開の状態を[_3]から[_4]に変更しました。',
    'Cloning CustomObject Groups for blog...' => 'カスタム項目グループを複製しています...',
    'Cloning CustomObjects for blog...' => 'カスタム項目を複製しています...',
    'Cloning CustomObject tags for blog...' => 'カスタム項目のタグを複製しています...',
    'Exclude CustomObjects' => 'カスタム項目の除外',
};
    return $map;
}

sub __get_settings {
    my ( $app, $blog, $component ) = @_;
    $blog = $app->blog unless $blog;
    my $config_plugin = MT->component( 'CustomObjectConfig' );
    if ( ( $component ) && ( $component ne 'customobject' ) ) {
        $component = MT->component( $component );
        if ( $component ) {
            $config_plugin = $component;
        }
    }
    my $label_en;
    my $label_ja;
    my $label_plural;
    if ( $blog ) {
        $label_en = $config_plugin->get_config_value( 'label_en', 'blog:'. $blog->id );
        $label_ja = $config_plugin->get_config_value( 'label_ja', 'blog:'. $blog->id );
        $label_plural = $config_plugin->get_config_value( 'label_plural', 'blog:'. $blog->id );
        if (! $label_en ) {
            if ( $blog->parent_id ) {
                $label_en = $config_plugin->get_config_value( 'label_en', 'blog:'. $blog->parent_id );
            }
            if (! $label_en ) {
                $label_en = $config_plugin->get_config_value( 'label_en' );
            }
        }
        if (! $label_ja ) {
            if ( $blog->parent_id ) {
                $label_ja = $config_plugin->get_config_value( 'label_ja', 'blog:'. $blog->parent_id );
            }
            if (! $label_ja ) {
                $label_ja = $config_plugin->get_config_value( 'label_ja' );
            }
        }
        if (! $label_plural ) {
            if ( $blog->parent_id ) {
                $label_plural = $config_plugin->get_config_value( 'label_plural', 'blog:'. $blog->parent_id );
            }
            if (! $label_plural ) {
                $label_plural = $config_plugin->get_config_value( 'label_plural' );
            }
        }
        $label_ja = $config_plugin->translate( $config_plugin->name ) unless $label_ja;
    } else {
        $label_en = $config_plugin->get_config_value( 'label_en' );
        $label_ja = $config_plugin->get_config_value( 'label_ja' );
        $label_plural = $config_plugin->get_config_value( 'label_plural' );
        $label_ja = $config_plugin->translate( $config_plugin->name ) unless $label_ja;
    }
    return ( $label_en, $label_ja, $label_plural );
}

sub _view_customobject {
    my $app = shift;
    my $plugin = MT->component( 'CustomObject' );
    $app->{ plugin_template_path } = plugin_template_path( $plugin );
    $app->mode( 'edit' );
    return $app->forward( 'edit', @_ );
}

sub _list_customobject {
    my $app = shift;
    my $plugin = MT->component( 'CustomObject' );
    my $user = $app->user;
    my $mode = $app->mode;
    my $list_id = $mode;
    $list_id =~ s/^list_//;
    if ( $mode eq 'list' ) {
        $mode = 'customobject';
        $list_id = 'customobject';
    }
    my %blogs;
    my $system_view;
    my $website_view;
    my $blog_view;
    my @blog_ids;
    my $r = MT::Request->instance;
    if (! defined $app->blog ) {
        $system_view = 1;
        my @all_blogs = MT::Blog->load( { class => [ 'website', 'blog' ] } );
        for my $blog ( @all_blogs ) {
            if ( $list_id =~ /group$/ ) {
                if ( _group_permission( $blog ) ) {
                    $blogs{ $blog->id } = $blog;
                    push( @blog_ids, $blog->id );
                }
            } else {
                if ( _customobject_permission( $blog ) ) {
                    $blogs{ $blog->id } = $blog;
                    push( @blog_ids, $blog->id );
                }
            }
        }
    } else {
        if ( $list_id =~ /group$/ ) {
            if (! _group_permission( $app->blog ) ) {
                return $app->trans_error( 'Permission denied.' );
            }
        } else {
            if (! _customobject_permission( $app->blog ) ) {
                return $app->trans_error( 'Permission denied.' );
            }
        }
        if ( $app->blog->class eq 'website' ) {
            $website_view = 1;
            $blogs{ $app->blog->id } = $app->blog;
            push ( @blog_ids, $app->blog->id );
            my $all_blogs = $app->blog->blogs;
            for my $blog ( @$all_blogs ) {
                if ( $list_id =~ /group$/ ) {
                    if ( _group_permission( $blog ) ) {
                        $blogs{ $blog->id } = $blog;
                        push ( @blog_ids, $blog->id );
                    }
                } else {
                    if ( _customobject_permission( $blog ) ) {
                        $blogs{ $blog->id } = $blog;
                        push ( @blog_ids, $blog->id );
                    }
                }
            }
        } else {
            $blog_view = 1;
            push ( @blog_ids, $app->blog->id );
        }
    }
    my $code = sub {
        my ( $obj, $row ) = @_;
        my $columns = $obj->column_names;
        for my $column ( @$columns ) {
            my $val = $obj->$column;
            $row->{ $column . '_raw' } = $val;
            if ( $column =~ /_on$/ ) {
                $val = format_ts( '%Y&#24180;%m&#26376;%d&#26085;', $val, undef,
                                  $app->user ? $app->user->preferred_language : undef );
            } else {
                if ( $val ) {
                    $val = substr_text( $val, 0, 20 ) . ( length_text( $val ) > 20 ? '...' : '' );
                }
            }
            $row->{ $column } = $val;
        }
        if ( (! defined $app->blog ) || ( $website_view ) ) {
            if ( defined $blogs{ $obj->blog_id } ) {
                my $blog_name = $blogs{ $obj->blog_id }->name;
                $blog_name = substr_text( $blog_name, 0, 20 ) . ( length_text( $blog_name ) > 20 ? '...' : '' );
                $row->{ weblog_name } = $blog_name;
                $row->{ weblog_id } = $obj->blog_id;
                $row->{ can_edit } = _customobject_permission( $blogs{ $obj->blog_id } );
                if ( $list_id =~ /group$/ ) {
                    if ( defined $blogs{ $obj->addfilter_blog_id } ) {
                        $row->{ filter_blogname } = $blogs{ $obj->addfilter_blog_id }->name;
                    }
                }
            }
        } else {
            $row->{ can_edit } = 1;
        }
        if ( $list_id =~ /group$/ ) {
            require CustomObject::CustomObjectOrder;
            my $count = CustomObject::CustomObjectOrder->count( { group_id => $obj->id } );
            $row->{ count } = $count;
            if ( $count ) {
                $row->{ published_children } = $obj->published_children;
            } else {
                $row->{ published_children } = 0;
            }
        }
        my $obj_author = $obj->author;
        $row->{ author_name } = $obj_author->name;
    };
    my @customobject_admin = _load_customobject_admin( @blog_ids );
    my @author_loop;
    for my $admin ( @customobject_admin ) {
        $r->cache( 'cache_author:' . $admin->id, $admin );
        push @author_loop, {
                author_id => $admin->id,
                author_name => $admin->name, };
    }
    my %terms;
    my %param;
    if ( $list_id !~ /group$/ ) {
        my @tag_loop;
        require MT::Tag;
        require MT::ObjectTag;
        my @tags = MT::Tag->load( undef,
                                  { join => MT::ObjectTag->join_on( 'tag_id',
                                  { blog_id => \@blog_ids, object_datasource => 'customobject', },
                                  { unique => 1, } ) } );
        for my $tag ( @tags ) {
            push @tag_loop, {
                tag_name => $tag->name, };
        }
        $param{ tag_loop } = \@tag_loop;
    }
    $app->{ plugin_template_path } = plugin_template_path( $plugin );
    $param{ list_id } = $list_id;
    $param{ author_loop }  = \@author_loop;
    $param{ system_view }  = $system_view;
    $param{ website_view } = $website_view;
    $param{ blog_view } = $blog_view;
    $param{ filter } = $app->param( 'filter' );
    $param{ filter_val } = $app->param( 'filter_val' );
    $param{ edit_field } = $app->param( 'edit_field' );
    $param{ LIST_NONCRON }    = 1;
    $param{ saved_deleted }   = 1 if $app->param( 'saved_deleted' );
    $param{ dialog_view }     = 1 if $app->param( 'dialog_view' );
    $param{ published }       = 1 if $app->param( 'published' );
    $param{ not_published }   = 1 if $app->param( 'not_published' );
    $param{ unpublished }     = 1 if $app->param( 'unpublished' );
    $param{ not_unpublished } = 1 if $app->param( 'not_unpublished' );
    $param{ imported } = 1 if $app->param( 'imported' );
    $param{ not_imported } = 1 if $app->param( 'not_imported' );
    $param{ search_label } = $plugin->translate( 'Custom Object' );
    if ( my $query = $app->param( 'query' ) ) {
        $terms{ name } = { like => '%' . $query . '%' };
        $param{ query } = $query;
    }
    # if ( $website_view ) {
        $terms{ blog_id } = \@blog_ids;
    # }
    my %args;
    $args{ sort } = 'created_on';
    $args{ direction } = 'descend';
    if ( $app->param( 'dialog_view' ) ) {
        $args{ limit } = 25;
    }
    my $class = $app->param( 'class' );
    if ( $class ) {
        $terms{ class } = $class;
        $param{ screen_group } = $class;
        if (! $app->param( 'dialog_view' ) ) {
            my $pref_id = 'customobject_';
            if ( $list_id =~ /group$/ ) {
                $pref_id .= 'gp_'
            }
            $pref_id .= $class;
            my $list_pref = $app->list_pref( $pref_id );
            if ( $list_pref ) {
                my $pref = $list_pref->{ rows };
                if ( $pref ) {
                    $args{ limit } = $pref;
                }
            }
        }
    } else {
        $terms{ class } = $app->param( '_type' );
        $class = $terms{ class };
    }
    $param{ search_type } = $class;
    return $app->listing (
        {
            type   => $list_id,
            code   => $code,
            args   => \%args,
            params => \%param,
            terms  => \%terms,
        }
    );
}

sub _search_customobject {
    my $app = shift;
    my $list_id = $app->param( '_type' );
    my $plugin = MT->component( 'CustomObject' );
    my $class_plugin = MT->component( $list_id );
    my ( %args ) = @_;
    my %blogs;
    my $system_view;
    my $website_view;
    my $blog_view;
    my @blog_ids;
    my $r = MT::Request->instance;
    if (! defined $app->blog ) {
        $system_view = 1;
    } else {
        if (! _customobject_permission( $app->blog ) ) {
            return $app->trans_error( 'Permission denied.' );
        }
        if ( $app->blog->class eq 'website' ) {
            $website_view = 1;
        } else {
            $blog_view = 1;
        }
    }
    my $iter;
    if ( $args{ iter } ) {
        $iter = $args{ iter };
    } elsif ( $args{ items } ) {
        $iter = sub { pop @{ $args{ items } } };
    }
    return [] unless $iter;
    my $limit = $args{ limit };
    my $param = $args{ param } || {};
    my @data;
    while ( my $obj = $iter->() ) {
        my $row = $obj->column_values;
        $row->{ object } = $obj;
        my $columns = $obj->column_names;
        for my $column ( @$columns ) {
            my $val = $obj->$column;
            if ( $column =~ /_on$/ ) {
                $val = format_ts( '%Y&#24180;%m&#26376;%d&#26085;', $val, undef,
                                  $app->user ? $app->user->preferred_language : undef );
            }
            $row->{ $column } = $val;
        }
        if ( (! defined $app->blog ) || ( $website_view ) ) {
            if ( my $blog = $obj->blog ) {
                my $blog_name = $blog->name;
                $blog_name = substr_text( $blog_name, 0, 20 ) . ( length_text( $blog_name ) > 20 ? '...' : '' );
                $row->{ weblog_name } = $blog_name;
                $row->{ weblog_id } = $obj->blog_id;
                $row->{ can_edit } = _customobject_permission( $blog );
            }
        } else {
            $row->{ can_edit } = 1;
        }
        my $obj_author = $obj->author;
        $row->{ author_name } = $obj_author->name;
        push @data, $row;
        last if $limit and @data > $limit;
    }
    if ( $list_id ne 'customobject' ) {
        $param->{ search_label } = $class_plugin->translate( $class_plugin->name );
    }
    $param->{ search_type }  = $list_id;
    $param->{ search_replace } = 1;
    return [] unless @data;
    $param->{ system_view } = 1 unless $app->param ( 'blog_id' );
    $param->{ object_loop } = \@data;
    \@data;
}

sub _upload_customobject_csv {
    my $app = shift;
    my $plugin = MT->component( 'CustomObject' );
    my $user = $app->user;
    my $blog = $app->blog;
    if (! defined $blog ) {
        $app->return_to_dashboard();
    }
    if (! _customobject_permission( $blog ) ) {
        return $app->trans_error( 'Permission denied.' );
    }
    $app->validate_magic or return $app->trans_error( 'Permission denied.' );
    require MT::Request;
    my $r = MT::Request->instance;
    my $snippet_sep = $app->config( 'ImportExportSnippetSeparator' ) || ':';
    my $snippet_delim = $app->config( 'ImportExportSnippetDelimiter' ) || ';';
    $snippet_sep = quotemeta( $snippet_sep );
    $snippet_delim = quotemeta( $snippet_delim );
    my $csv = csv_new() || return $app->error( $plugin->translate( 'Neither Text::CSV_XS nor Text::CSV is available.' ) );
    my $tempdir = $app->config( 'TempDir' );
    my $workdir = tempdir( DIR => $tempdir );
    my %params = ( format_LF => 1,
                   singler => 1,
                   no_asset => 1,
                  );
    my $upload = upload( $app, $blog, 'file', $workdir, \%params );
    require MT::Blog;
    require MT::Website;
    require MT::Author;
    my $i = 0;
    my $do;
    my @column_names;
    open my $fh, '<', $upload;
    my $model = MT->model( 'customobject' );
    my $class = $app->param( 'class' );
    if ( $class ) {
        my $custom_objects = MT->registry( 'custom_objects' );
        my @objects = keys( %$custom_objects );
        if ( grep( /^$class$/, @objects ) ) {
            $model = MT->model( $class );
        }
    }
    my $cnames = $model->column_names;
    my @weblogs = get_weblogs( $blog );
    my @weblog_ids;
    for my $b ( @weblogs ) { push @weblog_ids, $b->id; }
    while ( my $columns = $csv->getline ( $fh ) ) {
        if (! $i ) {
            for my $cell ( @$columns ) {
                push ( @column_names, $cell );
            }
        } else {
            my $j = 0;
            my $perm = 1;
            my $blog_id;
            my $weblog;
            my $ts = current_ts( $blog );
            my $id;
            my %values;
            my $csv_obj;
            my @assets;
            for my $cell ( @$columns ) {
                $csv_obj->{ $column_names[$j] } = $cell;
                if ( ( $model->has_column( $column_names[$j] ) ) || ( $column_names[$j] eq 'tags' ) ) {
                    my $guess_encoding = MT::I18N::guess_encoding( $cell );
                    unless ( $guess_encoding =~ /^utf-?8$/i ) {
                        $cell = utf8_on( MT::I18N::encode_text( $cell, 'cp932', 'utf8' ) );
                    }
                    if ( $column_names[$j] eq 'blog_id' ) {
                        if ( grep( /^$cell$/, @weblog_ids ) ) {
                            $blog_id = $cell;
                        } else {
                            $perm = 0;
                        }
                    } elsif ( $column_names[$j] eq 'id' ) {
                        $id = $cell;
                    } else {
                        if ( $column_names[$j] =~ /_on$/ ) {
                            if (! $cell ) {
                                $cell = $ts;
                            } else {
                                $cell =~ s/^\t//;
                            }
                        }
                        $values{ $column_names[$j] } = $cell;
                    }
                }
                $j++;
            }
            my $customobject;
            if ( $id ) {
                $customobject = $model->get_by_key( { id => $id } );
                if ( my $obj_blog_id = $customobject->blog_id ) {
                    if (! grep( /^$obj_blog_id$/, @weblog_ids ) ) {
                        $perm = 0;
                    }
                }
            } else {
                $customobject = $model->new;
            }
            if (! $blog_id ) {
                $blog_id = $blog->id;
            }
            $weblog = MT::Blog->load( $blog_id );
            if (! defined $weblog ) {
                $weblog = MT::Website->load( $blog_id );
            }
            if (! defined $weblog ) {
                $perm = 0;
            }
            if ( $perm ) {
                for my $key ( keys %values ) {
                    if ( $key eq 'tags' ) {
                        my @tags = split( /,/, $values{ $key } );
                        $customobject->set_tags( @tags );
                    } elsif ( $key =~ /^field\.(.*$)/ ) {
                        # Set CustomField Asset
                        my $field_basename = $1;
                        my $field_blog_id = $customobject->blog_id || $blog_id;
                        my $field_type;
                        $field_type = $r->cache( 'field_type:' . $field_blog_id . ':' . $field_basename );
                        if (! $field_type ) {
                            my $field = MT->model( 'field' )->load( { blog_id => [ 0, $field_blog_id ],
                                                                      basename => $field_basename },
                                                                    { limit => 1 } );
                            if ( $field ) {
                                $field_type = $field->type;
                                $r->cache( 'field_type:' . $field_blog_id . ':' . $field_basename, $field_type );
                            }
                        }
                        if ( $field_type ) {
                            if ( ( $field_type eq 'file' ) || ( $field_type eq 'image' ) ||
                                 ( $field_type eq 'video' ) || ( $field_type eq 'audio' ) ) {
                                if ( $values{ $key } && ( ( $values{ $key } =~ /^\%r/ ) || ( $values{ $key } =~ /^\%a/ ) ) ) {
                                    my $asset = MT::Asset->load( { blog_id => $field_blog_id,
                                                                   file_path => $values{ $key },
                                                                   class => '*', } );
                                    if ( $asset ) {
                                        push ( @assets, $asset );
                                        my $asst_id = $asset->id;
                                        my $url = $asset->url;
                                        my $label = MT->translate( 'View image' );
                                        if ( $field_type ne 'image' ) {
                                            $label = MT->translate( 'View' );
                                        }
                                        $values{ $key } = qq{<form mt:asset-id="$asst_id" class="mt-enclosure mt-enclosure-$field_type" style="display: inline;"><a href="$url">$label</a></form>};
                                    }
                                }
                            }
                        }
                        if ( $field_type ne 'snippet' ) {
                            $customobject->$key( $values{ $key } );
                        } else {
                            if ( $values{ $key } ) {
                                my $data;
                                my @values = split( /$snippet_delim/, $values{ $key } );
                                for my $val ( @values ) {
                                    my @key_val = split( /$snippet_sep/, $val );
                                    $key_val[0] =~ s/\\$//;
                                    $key_val[1] =~ s/\\$//;
                                    $data->{ $key_val[0] } = $key_val[1];
                                }
                                $customobject->$key( $data );
                            }
                        }
                    } else {
                        $customobject->$key( $values{ $key } );
                    }
                }
            }
            for my $name ( @$cnames ) {
                if ( $name =~ /_on$/ ) {
                    if (! $customobject->$name ) {
                        $customobject->$name( $ts );
                    }
                }
            }
            if ( $customobject->author_id ) {
                my $author = MT::Author->load( $customobject->author_id );
                if (! defined $author ) {
                    $perm = 0;
                }
                if (! _customobject_permission( $weblog, $author ) ) {
                    $perm = 0;
                }
            } else {
                $customobject->author_id( $app->user->id );
            }
            if (! $customobject->name ) {
                $perm = 0;
            }
            if ( $perm ) {
                $customobject->blog_id( $blog_id );
                $customobject->class( $class );
                $app->run_callbacks( 'cms_pre_import.customobject', $app, $customobject, $csv_obj ) || next;
                $customobject->save or $customobject->errstr;
                if ( @assets ) {
                    for my $asset ( @assets ) {
                        my $object_asset = MT->model( 'objectasset' )->get_by_key( { blog_id => $customobject->blog_id,
                                                                                     asset_id => $asset->id,
                                                                                     object_ds => $customobject->datasource,
                                                                                     object_id => $customobject->id,
                                                                                   }
                                                                                 );
                        $object_asset->save or die $object_asset->errstr;
                    }
                }
                $app->run_callbacks( 'cms_post_import.customobject', $app, $customobject, $csv_obj );
                $do = 1;
            }
        }
        $i++;
    }
    close $fh;
    if ( $do ) {
        $app->run_callbacks( 'cms_finish_import.customobject', $app, $blog, $upload );
    }
    remove_item( $workdir );
    if ( $do ) {
        $app->add_return_arg( imported => 1 );
    } else {
        $app->add_return_arg( not_imported => 1 );
    }
    $app->call_return;
}

sub _download_customobject_csv {
    my $app = shift;
    my $plugin = MT->component( 'CustomObject' );
    my $blog = $app->blog;
    if (! defined $blog ) {
        return $app->return_to_dashboard();
    }
    if (! _customobject_permission( $blog ) ) {
        return $app->trans_error( 'Permission denied.' );
    }
    $app->validate_magic or return $app->trans_error( 'Permission denied.' );
    my $snippet_sep = $app->config( 'ImportExportSnippetSeparator' ) || ':';
    my $snippet_delim = $app->config( 'ImportExportSnippetDelimiter' ) || ';';
    $snippet_sep = quotemeta( $snippet_sep );
    $snippet_delim = quotemeta( $snippet_delim );
    my $csv = csv_new() || return $app->error( $plugin->translate( 'Neither Text::CSV_XS nor Text::CSV is available.' ) );
    $app->{ no_print_body } = 1;
    my $ts = current_ts();
    my $class;
    my $model = MT->model( 'customobject' );
    if ( $class = $app->param( 'class' ) ) {
        my $custom_objects = MT->registry( 'custom_objects' );
        my @objects = keys( %$custom_objects );
        if ( grep( /^$class$/, @objects ) ) {
            $model = MT->model( $class );
        }
    } else {
        $class = 'customobject';
    }
    $app->set_header( 'Content-Disposition' => "attachment; filename=csv_$ts.csv" );
    $app->set_header( 'Pragma' => '' );
    $app->send_http_header( 'text/csv' );
    my @weblogs = get_weblogs( $blog );
    my @weblog_ids;
    for my $b ( @weblogs ) { push @weblog_ids, $b->id; }
    my @field_ids = @weblog_ids;
    push ( @field_ids, 0 );
    my $column_names = $model->column_names;
    my $new_column;
    for my $column ( @$column_names ) {
        if ( $column ne 'class' ) {
            push ( @$new_column, $column );
        }
    }
    $column_names = $new_column;
    push ( @$column_names, 'tags' );
    require CustomFields::Field;
    my @fields = CustomFields::Field->load( { blog_id => \@field_ids, obj_type => $class } );
    my @snippets;
    for my $field ( @fields ) {
        push ( @$column_names, 'field.' . $field->basename );
        if ( $field->type eq 'snippet' ) {
            push( @snippets, 'field.' . $field->basename );
        }
    }
    if ( $csv->combine( @$column_names ) ) {
        my $string = $csv->string;
        $string = encode_utf8_string_to_cp932_octets( $string );
        print $string;
    }
    my $iter = $model->load_iter( { blog_id => \@weblog_ids } );
    while ( my $item = $iter->() ) {
        my @l_fields;
        for my $c ( @$column_names ) {
            if ( $c eq 'tags' ) {
                my @tags = $item->get_tags;
                my $tag = join( ',', @tags );
                push ( @l_fields, $tag );
            } else {
                if ( $item->has_column( $c ) ) {
                    my $value = $item->$c;
                    if (! grep( /^\Q$c\E$/, @snippets ) ) {
                        my $value = $item->$c;
                        if ( ( $c =~ /_on$/ ) && ( $value =~ /^[0-9]{14}$/ ) ) {
                            $value = "\t$value";
                        }
                        push ( @l_fields, $value );
                    } else {
                        if (! ref $value ) {
                           require MT::Serialize;
                           $value = MT::Serialize->unserialize( $value );
                        }
                        my $params = ( ref $value ) eq 'REF' ? $$value : $value;
                        my @snippet;
                        for my $key ( keys %$params ) {
                            my $val = $params->{ $key };
                            my $data = $key . $snippet_sep . $val;
                            push ( @snippet, $data );
                        }
                        push( @l_fields, join( $snippet_delim, @snippet ) );
                    }
                }
            }
        }
        if ( $csv->combine( @l_fields ) ) {
            my $l_string = $csv->string;
            $l_string = utf8_on( $l_string );
            $l_string = MT::I18N::encode_text( $l_string, 'utf8', 'cp932' );
            print "\n$l_string";
        }
    }
}

sub _publish_customobjects {
    require CustomObject::CustomObject;
    _status_change( 'published', CustomObject::CustomObject::RELEASE() );
}

sub _unpublish_customobjects {
    require CustomObject::CustomObject;
    _status_change( 'unpublished', CustomObject::CustomObject::HOLD() );
}

sub _closed_customobjects {
    require CustomObject::CustomObject;
    _status_change( 'closed', CustomObject::CustomObject::CLOSED() );
}

sub _review_customobjects {
    require CustomObject::CustomObject;
    _status_change( 'closed', CustomObject::CustomObject::REVIEW() );
}

sub _status_change {
    my ( $param, $status ) = @_;
    my $app = MT::instance();
    my $plugin = MT->component( 'CustomObject' );
    if ( $app->param( 'all_selected' ) ) {
        $app->setup_filtered_ids;
    }
    my @id = $app->param( 'id' );
    my $do;
    require CustomObject::CustomObject;
    for my $customobject_id ( @id ) {
        my $customobject = $app->model( 'customobject' )->load( $customobject_id );
        return $app->errtrans( 'Invalid request.' ) unless $customobject;
        if (! _customobject_permission( $customobject->blog ) ) {
            return $app->trans_error( 'Permission denied.' );
        }
        if ( $customobject->status != $status ) {
            my $original = $customobject->clone_all();
            my $before = $plugin->translate( $original->status_text );
            $customobject->status( $status );
            $customobject->save or die $customobject->errstr;
            if ( ( $original->status == 2 ) || ( $customobject->status == 2 ) ) {
                require ArchiveType::CustomObject;
                my $custom_objects = MT->registry( 'custom_objects' );
                my $at = $custom_objects->{ $customobject->class }->{ id };
                ArchiveType::CustomObject::rebuild_customobject( $app, $customobject->blog, $at, $customobject );
            }
            if ( $status == CustomObject::CustomObject::HOLD() ) {
                $app->run_callbacks( 'post_unpublish.customobject', $app, $customobject, $original );
            } elsif ( $status == CustomObject::CustomObject::RELEASE() ) {
                $app->run_callbacks( 'post_publish.customobject', $app, $customobject, $original );
            }
            my $after = $plugin->translate( $customobject->status_text );
            $app->log( {
                message => $plugin->translate( 'CustomObject \'[_1]\' (ID:[_2]) edited and its status changed from [_3] to [_4] by user \'[_5]\'', $customobject->name, $customobject->id, $before, $after, $app->user->name ),
                blog_id => $customobject->blog_id,
                author_id => $app->user->id,
                class => 'customobject',
                level => MT::Log::INFO(),
            } );
            $do = 1;
        }
    }
    if ( $do ) {
        $app->add_return_arg( $param => 1 );
    } else {
        $app->add_return_arg( 'not_' . $param => 1 );
    }
    $app->call_return;
}

sub _add_tags_to_customobject {
    my $app = MT::instance();
    my $itemset_action_input = $app->param( 'itemset_action_input' );
    my $do;
    if ( $itemset_action_input ) {
        require MT::Tag;
        my $tag_delim = chr( $app->user->entry_prefs->{ tag_delim } ) || ',';
        my @tag_names = MT::Tag->split( $tag_delim, $itemset_action_input );
        my $plugin = MT->component( 'CustomObject' );
        if ( $app->param( 'all_selected' ) ) {
            $app->setup_filtered_ids;
        }
        my @id = $app->param( 'id' );
        require CustomObject::CustomObject;
        for my $customobject_id ( @id ) {
            my $customobject = $app->model( 'customobject' )->load( $customobject_id );
            return $app->errtrans( 'Invalid request.' ) unless $customobject;
            if (! _customobject_permission( $customobject->blog ) ) {
                return $app->trans_error( 'Permission denied.' );
            }
            $customobject->add_tags( @tag_names );
            $customobject->save or die $customobject->errstr;
            $do = 1;
        }
    }
    if ( $do ) {
        $app->add_return_arg( 'add_tags_to_customobject' => 1 );
    } else {
        $app->add_return_arg( 'not_add_tags_to_customobject' => 1 );
    }
    $app->call_return;
}

sub _remove_tags_to_customobject {
    my $app = MT::instance();
    my $itemset_action_input = $app->param( 'itemset_action_input' );
    my $do;
    if ( $itemset_action_input ) {
        require MT::Tag;
        my $tag_delim = chr( $app->user->entry_prefs->{ tag_delim } ) || ',';
        my @tag_names = MT::Tag->split( $tag_delim, $itemset_action_input );
        my $plugin = MT->component( 'CustomObject' );
        if ( $app->param( 'all_selected' ) ) {
            $app->setup_filtered_ids;
        }
        my @id = $app->param( 'id' );
        require CustomObject::CustomObject;
        for my $customobject_id ( @id ) {
            my $customobject = $app->model( 'customobject' )->load( $customobject_id );
            return $app->errtrans( 'Invalid request.' ) unless $customobject;
            if (! _customobject_permission( $customobject->blog ) ) {
                return $app->trans_error( 'Permission denied.' );
            }
            $customobject->remove_tags( @tag_names );
            $customobject->save or die $customobject->errstr;
            $do = 1;
        }
    }
    if ( $do ) {
        $app->add_return_arg( 'remove_tags_to_customobject' => 1 );
    } else {
        $app->add_return_arg( 'not_remove_tags_to_customobject' => 1 );
    }
    $app->call_return;
}

sub _asset_insert {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $edit_field = $app->param( 'edit_field' );
    return 1 unless $edit_field;
    if ( $edit_field =~ /^customobject_(.*$)/ ) {
        $edit_field = $1;
        my $pointer_field = $tmpl->getElementById( 'insert_script' );
        $pointer_field->innerHTML( qq{window.parent.custom_insertHTML('<mt:var name="upload_html" escape="js">', '$edit_field' );} );
    }
}

# sub _cfg_plugin {
#     my ( $cb, $app, $tmpl ) = @_;
#     if ( $$tmpl !~ m!/ui\.sortable\.js"! ) {
#         my $header = '<mt:setvarblock name="html_head">';
#         $header .= '<script type="text/javascript" src="<mt:var name="static_uri">jqueryui/ui.sortable.js"></script>';
#         $header .= '</mt:setvarblock>';
#         $$tmpl = $header . $$tmpl;
#     }
# }

sub _list_tag_src {
    my ( $cb, $app, $tmpl ) = @_;
    my $custom_objects = MT->registry( 'custom_objects' );
    if ( my $filter_key = $app->param( 'filter_key' ) ) {
        if ( $custom_objects->{ $filter_key } ) {
            my $search = quotemeta( 'filter=exacttag' );
            my $object = encode_url( $filter_key );
            $$tmpl =~ s/$search/class=$object$1/;
            $search = quotemeta( '<$mt:var name="link_to"$>' );
            $$tmpl =~ s/$search/list_customobject/;
        }
    }
}

sub _list_tag {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $plugin = MT->component( 'CustomObject' );
    my $list_filters = $param->{ list_filters };
    my $custom_objects = MT->registry( 'custom_objects' );
    my @objects = keys( %$custom_objects );
    for my $object ( @objects ) {
        my $component = MT->component( $object );
        if ( $component ) {
            my $label = $object;
            if ( my $model = MT->model( $object ) ) {
                $label = $model->class_label;
            }
            if ( $app->param( 'filter_key' ) eq $object ) {
                $param->{ screen_group } = $object;
                $param->{ filter_label } = $component->translate( 'Tags with [_1]', $label );
            }
            push @$list_filters,
            {
              key   => $object,
              label => $component->translate( 'Tags with [_1]', $label ),
            };
        }
    }
    $param->{ list_filters } = $list_filters;
}

sub _cms_pre_preview {
    my ( $cb, $app, $preview_tmpl, $data ) = @_;
    my $ctx = $preview_tmpl->context;
    if ( my $id = $preview_tmpl->id ) {
        if ( $ctx->{ __stash }->{ vars }->{ customobject_archive } ) {
            require MT::TemplateMap;
            return unless $app->blog;
            my $blog_id = $app->blog->id;
            my $map = MT::TemplateMap->load( { blog_id => $blog_id, template_id => $id, is_preferred => 1 } );
            if ( $map ) {
                my $class = $ctx->{ __stash }->{ vars }->{ customobject_class };
                my $o = MT->model( $class )->load( { blog_id => $blog_id }, { limit => 1 } );
                if (! defined $o ) {
                    my $plugin = MT->component( $class );
                    $o = MT->model( $class )->new;
                    $o->blog_id( $blog_id );
                    $o->id( 0 );
                    $o->name( $plugin->translate( 'CustomObject' ) );
                    $o->keywords( 'Lorem ipsum dolor sit amet, consectetuer adipiscing elit.' );
                }
                $ctx->{ __stash }{ customobject } = $o;
                $ctx->stash( 'customobject', $o );
            }
        }
        if ( $ctx->{ __stash }->{ vars }->{ folder_customobject_archive } ) {
            return unless $app->blog;
            my $blog_id = $app->blog->id;
            my $map = MT::TemplateMap->load( { blog_id => $blog_id, template_id => $id, is_preferred => 1 } );
            if ( $map ) {
                my $type = $map->archive_type;
                $type =~ s/^Folder//;
                my $model = $type;
                my $module = $model . '::' . $model;
                eval "require $module";
                my $o = MT->model( 'folder' )->load( { blog_id => $blog_id }, {
                                                       limit => 1,
                                                       'join' => [ $module, 'category_id',
                                                                 { blog_id => $blog_id, status => 2 },
                                                                 { unique => 1 } ] } );
                if (! defined $o ) {
                    $o = MT->model( 'folder' )->new;
                    $o->blog_id( $blog_id );
                    $o->id( 0 );
                    $o->label( MT->translate( 'Folder' ) );
                    $o->description( 'Lorem ipsum dolor sit amet, consectetuer adipiscing elit.' );
                }
                $ctx->{ __stash }{ category } = $o;
                $ctx->stash( 'category', $o );
            }
        }
    }
}

sub _rebuild_confirm {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $opts = $param->{ rebuild_option_loop };
    my @new_opt;
    for my $opt ( @$opts ) {
        if ( $opt->{ label } ) {
            push ( @new_opt, $opt );
        }
    }
    $param->{ rebuild_option_loop } = \@new_opt;
}

sub _cfg_prefs_param {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $plugin = MT->component( 'CustomObject' );
    my $pointer_node = $tmpl->getElementById( 'max_revisions_template' );
    return unless $pointer_node;
    my $options_node = $tmpl->createElement( 'app:setting', {
        id => 'max_revisions_customobject',
        label => $plugin->translate( 'Number of revisions per CustomObject' ),
        show_label => 1,
    } );
    my $inner = <<'MTML';
        <input type="text" name="max_revisions_customobject" id="max_revisions_customobject" class="text num" value="<mt:var name="max_revisions_customobject" escape="html">" />
MTML
    $options_node->innerHTML( $inner );
    $tmpl->insertAfter( $options_node, $pointer_node );
#     $param->{ max_revisions_customobject } =
#         $app->blog->max_revisions_customobject || $MT::Revisable::MAX_REVISIONS;
    require CustomObject::Object;
    my $max_revisions_column = CustomObject::Object::max_revisions_column();
    $param->{ max_revisions_customobject } =
        $app->blog->$max_revisions_column || $MT::Revisable::MAX_REVISIONS;
}

sub _list_tag_param {
    my ( $cb, $app, $param, $tmpl ) = @_;
    if ( my $type = $app->param( '_type' ) ) {
        if ( $type eq 'tag' ) {
            if ( my $filter_key = $app->param( 'filter_key' ) ) {
                my $custom_objects = MT->registry( 'custom_objects' );
                my @objects = keys( %$custom_objects );
                if (! grep( /^$type$/, @objects ) ) {
                    $param->{ screen_group } = $filter_key;
                    if ( $app->blog ) {
                        my $plugin = $app->param( 'filter_key' );
                        $param->{ search_type } = $plugin;
                        if ( $plugin eq 'customobject' ) {
                            $plugin = 'customobjectconfig';
                        }
                        my ( $label_en, $label_ja, $label_plural ) = __get_settings( $app, $app->blog, $plugin );
                        if ( $app->user->preferred_language eq 'ja' ) {
                            $param->{ search_label } = $label_ja;
                        } else {
                            $param->{ search_label } = $label_en;
                        }
                        
                    }
                }
            }
        }
    }
}

sub _list_customobject_param {
    my ( $cb, $app, $param, $tmpl ) = @_;
    $param->{ component } = 'customobject';
    my $plugin = 'customobjectconfig';
    my $mode = $app->mode;
    my $class = $app->param( 'class' );
    $param->{ class } = encode_html( $class );
    if ( $class ) {
        $param->{ return_args } = $param->{ return_args } . '&class=' . encode_html( $class );
    } else {
        $class = 'customobject';
    }
    $class =~ s/group$//;
    $plugin = $class;
    # $plugin = MT->component( $plugin );
    $param->{ component } = $class;
    $param->{ screen_group } = encode_html( $class );
    my $top_nav_loop = $param->{ top_nav_loop };
    for my $nav ( @$top_nav_loop ) {
        if ( my $sub_nav = $nav->{ sub_nav_loop } ) {
            for my $sub_sub ( @$sub_nav ) {
                if ( $sub_sub->{ current } ) {
                    $sub_sub->{ current } = 0;
                } elsif ( $sub_sub->{ id } eq $class . ':' . $mode ) {
                    $sub_sub->{ current } = 1;
                }
            }
        }
    }
    my ( $label_en, $label_ja, $label_plural ) = __get_settings( $app, $app->blog, $plugin );
    if ( $app->user->preferred_language eq 'ja' ) {
        $param->{ class_label } = $label_ja;
        $param->{ class_label_plural } = $label_ja;
        $param->{ object_label } = $label_ja;
        $param->{ object_label_plural } = $label_ja;
        $param->{ search_label } = $label_ja;
    } else {
        $param->{ object_label } = $label_en;
        $param->{ object_label_plural } = $label_plural;
        $param->{ search_label } = $label_en;
    }
    if ( $app->blog ) {
        $param->{ __is_admin__ } = __is_admin( $app->blog );
        $param->{ screen_blog_id } = $app->blog->id;
    }
    $param->{ search_type } = $class;
    return;
}

sub _cms_pre_save_customobject {
    my ( $cb, $app, $obj, $original ) = @_;
    if (! $obj->class ) {
        $obj->class( 'customobject' );
    }
    # if (! defined( $obj->basename ) || ( $obj->basename eq '' ) ) {
    #     # TODO::Check Uniq(Old and New)
    #     $obj->basename( $obj->make_unique_basename );
    # }
    if (! _customobject_permission( $obj->blog, $obj->class ) ) {
        # $app->return_to_dashboard( permission => 1 );
        return 0;
    }
    return 1;
}

# sub _cms_post_delete {
#     my ( $cb, $app, $obj, $original ) = @_;
#     if ( MT->version_id =~ /^5\.0/ ) {
#         return;
#     }
#     if ( $app->mode eq 'delete' ) {
#         if (! $app->param( 'action_name' ) ) {
#             my @id = $app->param( 'id' );
#             if ( scalar( @id ) == 1 ) {
#                 my $type = $obj->class;
#                 my $args;
#                 $args->{ blog_id } = $obj->blog_id;
#                 $args->{ _type } = $type;
#                 $args->{ saved_deleted } = 1;
#                 if ( $type ne 'customobject' ) {
#                     $args->{ class } = $type;
#                 }
#                 my $query_str = $app->uri( mode => 'list',
#                                            args => $args );
#                 my $return_url = $app->base . $query_str;
#                 return $app->print( "Location: $return_url\n\n" );
#             }
#         }
#     }
#     return 1;
# }

sub _cms_post_delete_customobject {
    my ( $cb, $app, $customobject ) = @_;
    my $custom_objects = MT->registry( 'custom_objects' );
    my $blog = $customobject->blog;
    my $fmgr = $blog->file_mgr;
    my $at = $custom_objects->{ $customobject->class }->{ id };
    require ArchiveType::CustomObject;
    $at = 'Folder' . $at;
    if ( my $folder = $customobject->folder ) {
        my $count = CustomObject::CustomObject->count( { blog_id => $customobject->blog_id,
                                                         status => CustomObject::CustomObject::RELEASE(),
                                                         category_id => $folder->id,
                                                         class => '*' } );
        if ( $count ) {
            my %param = (
                Force => 1,
            );
            require ArchiveType::FolderCustomObject;
            ArchiveType::FolderCustomObject::rebuild_folder( $app, $blog, $at, $folder, %param );
        } else {
            my @finfo = MT->model( 'fileinfo' )->load(
                { archive_type => $at,
                  blog_id => $customobject->blog_id,
                  category_id => $folder->id,
                }
            );
            for my $f ( @finfo ) {
                $fmgr->delete( $f->file_path );
                $f->remove;
            }
        }
    }
}

sub _cms_pre_save_field {
    my ( $cb, $app, $obj, $original ) = @_;
    my $custom_objects = MT->registry( 'custom_objects' );
    my @objects = keys( %$custom_objects );
    my $is_custom_object = 0;
    for my $object ( @objects ) {
        if ( ( $obj->type eq $object ) || ( $obj->type eq $object . '_multi' ) ||
            ( $obj->type eq $object . '_group' ) ) {
            $is_custom_object = 1;
            last;
        }
    }
    $obj->customobject( $is_custom_object );
    return 1;
}

sub _cms_pre_save_blog {
    my ( $cb, $app, $obj, $original ) = @_;
    if ( my $max_revisions_customobject = $app->param( 'max_revisions_customobject' ) ) {
        require CustomObject::Object;
        my $max_revisions_column = CustomObject::Object::max_revisions_column();
        $obj->$max_revisions_column( $max_revisions_customobject );
    }
    return 1;
}

sub _search_replace {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $custom_objects = MT->registry( 'custom_objects' );
    my @objects = keys( %$custom_objects );
    my $search_tabs = $param->{ search_tabs };
    for my $class ( @objects ) {
        if ( $class ne 'customobject' ) {
            my $id = $custom_objects->{ $class }->{ id };
            my $plugin = MT->component( $class );
            my $label = $plugin->translate( $id );
            push @$search_tabs, { key => $class, label => $label };
        }
    }
    $param->{ search_tabs } = $search_tabs;
}

sub _edit_customobject {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $component = MT->component( 'CustomObject' );
    my $config_plugin = MT->component( 'CustomObjectConfig' );
    my $type = $app->param( '_type' );
    $app->param( '_type', 'customobject' );
    $param->{ label_class } = 'field-top-label';
    $param->{ edit_screen } = 1;
    $param->{ screen_class } = 'edit-entry';
    my $class = $app->param( 'class' );
    if ( $class = $app->param( 'class' ) ) {
        $type = $class;
    }
    if ( $class && ( $class ne 'customobject' ) ) {
        $config_plugin = MT->component( $class );
        if (! $config_plugin ) {
            $config_plugin = MT->component( 'CustomObjectConfig' );
        }
    }
    my @custom_fields = MT->model( 'field' )->load( { obj_type => $type } );
    my @options_loop;
    for my $cf ( @custom_fields ) {
        push @options_loop, { cf_name => $cf->name, cf_basename => $cf->basename };
    }
    $param->{ options_loop } = \@options_loop;
    my $object = $app->model( $type );
    my $blog = $app->blog;
    if (! $blog ) {
        $app->return_to_dashboard();
    }
    if (! _customobject_permission( $app->blog ) ) {
        $app->return_to_dashboard( permission => 1 );
    }
    my $custom_objects = MT->registry( 'custom_objects' );
    my $at = $custom_objects->{ $type }->{ id };
    require MT::TemplateMap;
    if ( my $tmpl_map = MT::TemplateMap->exist(
        {   archive_type => $at,
            is_preferred => 1,
            blog_id      => $blog->id,
        }
        ) ) {
        $param->{ has_template } = 1;
    }
    my $id = $app->param( 'id' );
    if ( $id ) {
        my $obj = $object->load( $id );
        if (! defined $obj ) {
            $app->return_to_dashboard( permission => 1 );
        }
        if ( $obj->blog_id != $blog->id ) {
            $app->return_to_dashboard( permission => 1 );
        }
        if ( $blog->use_revision ) {
            my $rn = $app->param( 'r' );
            if ( defined( $rn ) && $rn != $obj->current_revision ) {
                my $rev = $obj->load_revision( { rev_number => $rn } );
                if ( $rev && @$rev ) {
                    $obj = $rev->[ 0 ];
                    my $values = $obj->get_values;
                    $param->{ $_ } = $values->{ $_ } foreach keys %$values;
                    $param->{ loaded_revision } = 1;
                }
                $param->{ rev_number } = $rn;
                $param->{ missing_tags_rev } = 1
                    if exists( $obj->{ __missing_tags_rev } )
                        && $obj->{ __missing_tags_rev };
                require CustomObject::CustomObject;
                my $status_text = $obj->status_text;
                $param->{ current_status_label } = $config_plugin->translate( $status_text );
            }
            $param->{ rev_date } = format_ts( '%Y-%m-%d %H:%M:%S',
            $obj->modified_on, $blog,
            $app->user ? $app->user->preferred_language : undef );
        }
        my $columns = $obj->column_names;
        $param->{ permalink } = $obj->permalink;
        my $folder_path = $obj->folder_path;
        my $path2folder;
        my @pathes;
        if ( $folder_path ) {
            for my $f ( @$folder_path ) {
                push ( @pathes, $f->basename );
            }
            $path2folder = join( '/', @pathes );
            $path2folder = '/' . $path2folder . '/';
        } else {
            $path2folder = '/';
        }
        $param->{ folder_path } = $path2folder;
        if ( $app->param( 'reedit' ) ) {
            $param->{ obj_name } = $app->param( 'name' );
            for my $column ( @$columns ) {
                if ( $column =~ /_on$/ ) {
                    $param->{ $column . '_date' } = $app->param( $column . '_date' );
                    $param->{ $column . '_time' } = $app->param( $column . '_time' );
                } else {
                    $param->{ $column } = $app->param( $column );
                }
            }
            $param->{ 'tags' } = $app->param( 'tags' );
            $param->{ 'revision-note' } = $app->param( 'revision-note' );
            if ( $app->param( 'save_revision' ) ) {
                $param->{ save_revision } = 1;
            } else {
                $param->{ save_revision } = 0;
            }
        } else {
            for my $column ( @$columns ) {
                if ( $column =~ /_on$/ ) {
                    my $column_ts = $obj->$column;
                    $param->{ $column . '_date' } = format_ts( '%Y-%m-%d', $column_ts );
                    $param->{ $column . '_time' } = format_ts( '%H:%M:%S', $column_ts );
                }
            }
            my @tags = $obj->tags;
            my $tag = join( ',', @tags );
            $param->{ tags } = $tag;
            my $next = $obj->_nextprev( 'next' );
            if ( $next ) {
                $param->{ next_customobject_id } = $next->id;
            }
            $param->{ obj_name } = $obj->name;
            if ( ( $app->mode eq 'save' ) || $app->param('reedit') ) { # is error
                $param->{ obj_name } = $app->param( 'name' );
            }
        }
        my $previous = $obj->_nextprev( 'previous' );
        if ( $previous ) {
            $param->{ previous_customobject_id } = $previous->id;
        }
        # ObjectMemo
        # my $memo = MT->component( 'ObjectMemo' );
        # if ( $memo ) {
        #     my @memo_loop;
        #     my @object_memo = MT->model( 'objectmemo' )->get_memo( $obj );
        #     for my $m ( @object_memo ) {
        #         my $created_on = format_ts( '%Y-%m-%d@%H:%M', $m->created_on );
        #         push ( @memo_loop, {
        #             memo_id => $m->id,
        #             memo_label => $m->label,
        #             memo_created_on => $created_on,
        #             memo_text => $m->text,
        #             memo_author => $m->author->nickname,
        #             can_edit => $m->can_edit,
        #         } );
        #     }
        #     $param->{ memo_loop } = \@memo_loop;
        #     $param->{ can_create_memo } = MT->model( 'objectmemo' )->can_create;
        # }
    } else {
        if ( $app->param( 'reedit' ) ) {
            $param->{ obj_name } = $app->param( 'name' );
            $param->{ tags } = $app->param( 'tags' );
            $param->{ 'revision-note' } = $app->param( 'revision-note' );
            $param->{ authored_on_date } = $app->param( 'authored_on_date' );
            $param->{ authored_on_time } = $app->param( 'authored_on_time' );
            $param->{ period_on_date } = $app->param( 'period_on_date' );
            $param->{ period_on_time } = $app->param( 'period_on_time' );
            $param->{ save_revision } = $app->param( 'save_revision' ) ? 1 : 0;
        } else {
            my $columns = $object->column_names;
            my @tl = offset_time_list( time, $app->blog );
            my $ts_date = sprintf '%04d-%02d-%02d', $tl[5]+1900, $tl[4]+1, $tl[3];
            my $ts_time = sprintf '%02d:%02d:%02d', @tl[2,1,0];
            for my $column ( @$columns ) {
                if ( $column =~ /_on$/ ) {
                    $param->{ $column . '_date' } = $ts_date;
                    $param->{ $column . '_time' } = $ts_time;
                }
            }
            my $default_period = $config_plugin->get_config_value( 'default_period', 'blog:'. $blog->id ) || 30;
            my $end_ts = _get_end_date( $blog, current_ts( $blog ), $default_period );
            $ts_date = substr( $end_ts, 0, 4 ) . '-' . substr( $end_ts, 4, 2 ) . '-' . substr( $end_ts, 6, 2 );
            $param->{ period_on_date } = $ts_date;
            $param->{ period_on_time } = '00:00:00';
            $param->{ status } = $config_plugin->get_config_value( 'default_status', 'blog:'. $blog->id );
        }
    }
    my $editor_style_css = $config_plugin->get_config_value( 'editor_style_css', 'blog:'. $blog->id );
    my $field_order = $config_plugin->get_config_value( 'field_order', 'blog:'. $blog->id );
    $param->{ field_order } = $field_order;
    $param->{ status_draft } = $config_plugin->get_config_value( 'status_draft', 'blog:'. $blog->id );
    $param->{ status_review } = $config_plugin->get_config_value( 'status_review', 'blog:'. $blog->id );
    $param->{ status_publishing } = $config_plugin->get_config_value( 'status_publishing', 'blog:'. $blog->id );
    $param->{ status_future } = $config_plugin->get_config_value( 'status_future', 'blog:'. $blog->id );
    $param->{ status_closed } = $config_plugin->get_config_value( 'status_closed', 'blog:'. $blog->id );
    $param->{ default_status } = $config_plugin->get_config_value( 'default_status', 'blog:'. $blog->id );
    my $display_options = $config_plugin->get_config_value( 'display_options', 'blog:'. $blog->id );
    if ( $display_options ) {
        my @fields = MT->model( 'field' )->load( { obj_type => $type } );
        my @field_loop = qw(name body keywords tags authored_on_date period_on_date basename folder);
        my @hidden_field;
        for my $field ( @fields ) {
            push( @field_loop, 'customfield_' . $field->basename );
        }
        my @opt = split( /,/, $display_options );
        for my $check_item ( @field_loop ) {
            if (! grep( /^$check_item$/, @opt ) ) {
                push ( @hidden_field, { field_name => $check_item } );
            }
        }
        # ObjectMemo
        my $memo = MT->component( 'ObjectMemo' );
        if ( $memo ) {
            if ( grep( /^memo$/, @opt ) ) {
                $param->{ show_memo } = 1;
            }
        }
        $param->{ hidden_field } = \@hidden_field;
    }
    my %args = ( blog => $app->blog );
    $editor_style_css = build_tmpl( $app, $editor_style_css, \%args );
    $param->{ editor_style_css } = $editor_style_css;
    $param->{ theme_advanced_buttons1 } = $config_plugin->get_config_value( 'theme_advanced_buttons1', 'blog:'. $blog->id );
    $param->{ theme_advanced_buttons2 } = $config_plugin->get_config_value( 'theme_advanced_buttons2', 'blog:'. $blog->id );
    $param->{ theme_advanced_buttons3 } = $config_plugin->get_config_value( 'theme_advanced_buttons3', 'blog:'. $blog->id );
    $param->{ theme_advanced_buttons4 } = $config_plugin->get_config_value( 'theme_advanced_buttons4', 'blog:'. $blog->id );
    $param->{ theme_advanced_buttons5 } = $config_plugin->get_config_value( 'theme_advanced_buttons5', 'blog:'. $blog->id );
    $param->{ use_wysiwyg } = $config_plugin->get_config_value( 'use_wysiwyg', 'blog:'. $blog->id );
    $param->{ lang } = $app->user->preferred_language;
    $param->{ saved } = $app->param( 'saved' );
    $param->{ search_label } = $component->translate( 'CustomObject' );
    $param->{ screen_group } = 'customobject';
    $param->{ return_args } = _force_view_mode_return_args( $app );
    if ( $blog->use_revision ) {
        $param->{ use_revision } = 1;
    }
    $class = 'customobject' unless $class;
    $param->{ search_type } = $class;
    my ( $label_en, $label_ja, $label_plural ) = __get_settings( $app, $app->blog, $class );
    if ( $app->user->preferred_language eq 'ja' ) {
        $param->{ class_label } = $label_ja;
        $param->{ class_label_plural } = $label_ja;
        $param->{ search_label } = $label_ja;
    } else {
        $param->{ class_label } = $label_en;
        $param->{ class_label_plural } = $label_plural;
        $param->{ search_label } = $label_en;
    }
    $param->{ component } = 'customobject';
    my $plugin = 'customobjectconfig';
    # my $class = $app->param( 'class' );
    if ( $class ) {
        $param->{ component } = $class;
        $plugin = $class;
        $param->{ return_args } = $param->{ return_args } . '&class=' . encode_html( $class );
        $param->{ screen_group } = encode_html( $class );
        $param->{ class } = encode_html( $class );
    } else {
        $class = 'customobject';
    }
    $app->param( '_type', $class );
    if (! $app->param( 'id' ) ) {
        my $top_nav_loop = $param->{ top_nav_loop };
        my $mode = $app->mode;
        for my $nav ( @$top_nav_loop ) {
            if ( my $sub_nav = $nav->{ sub_nav_loop } ) {
                for my $sub_sub ( @$sub_nav ) {
                    if ( $sub_sub->{ current } ) {
                        $sub_sub->{ current } = 0;
                    } elsif ( $sub_sub->{ id } eq $class . ':create_customobject' ) {
                        $sub_sub->{ current } = 1;
                    }
                }
            }
        }
    }
    my $cat_id;
    my %places;
    my $blog_id = $blog->id;
    my $data = $app->_build_category_list(
        blog_id => $blog_id,
        markers => 1,
        type    => 'folder',
    );
    my $top_cat = $cat_id;
    my @sel_cats;
    my $cat_tree = [];
    push @$cat_tree,
        {
        folder_id         => -1,
        category_label    => '/',
        category_basename => '/',
        category_path     => [],
        };
    $top_cat ||= -1;
    foreach ( @$data ) {
        next unless exists $_->{ category_id };
        $_->{ category_path_ids } ||= [];
        unshift @{ $_->{ category_path_ids } }, -1;
        push @$cat_tree,
            {
            folder_id => $_->{ category_id },
            category_label_spacer => '&nbsp;&nbsp;' . ($_->{ category_label_spacer } x 2),
            category_label    => $_->{ category_label } . '/',
            category_basename => $_->{ category_basename } . '/',
            category_path   => $_->{ category_path_ids } || [],
            category_fields => $_->{ category_fields }   || [],
            };
        push @sel_cats, $_->{ category_id }
            if $places{ $_->{ category_id } }
                && $_->{ category_id } != $cat_id;
    }
    $param->{ category_tree } = $cat_tree;
    $param->{ category_id } = -1 unless $param->{ category_id };
    $param->{ folder_path } = '/' unless $param->{ folder_path };
    unshift @sel_cats, $top_cat if defined $top_cat && $top_cat ne '';
    $param->{ selected_category_loop } = \@sel_cats;
    $param->{ have_multiple_categories } = scalar @$data > 1;
    # Add <mtapp:fields> after tags
    if ( $class ne 'customobject' ) {
        if ( $param->{ error } ) {
            unless ( my $req = MT->request( 'edit_customobject_param' ) ) {
                $req = MT->request( 'edit_customobject_param', 1 );
                return;
            }
        }
    }
    $param->{ label_class } = 'top-label';
    $param->{ is_oracle } = is_oracle();
    require CustomFields::App::CMS;
    CustomFields::App::CMS::add_app_fields( $cb, $app, $param, $tmpl, 'keywords', 'insertBefore' );
}

sub _edit_customobject_out {
    my ( $cb, $app, $tmpl, $param ) = @_;
    # $$tmpl =~ s/(<div id="customfield_[^"]+-field" class="field +)(?:required +)*(field-)top(?=-label *">)/$1$2left/gi;
}

sub _edit_template_param {
    my ( $cb, $app, $param, $tmpl ) = @_;
    if (! $app->param( 'id' ) ) {
        if ( my $blog = $app->blog ) {
            if ( my $group_id = $app->param( 'customobjectgroup_id' ) ) {
                require CustomObject::CustomObjectGroup;
                my $group = CustomObject::CustomObjectGroup->load( $group_id );
                if ( $group ) {
                    my $plugin = MT->component( 'CustomObject' );
                    my $config_plugin = MT->component( 'CustomObjectConfig' );
                    my $class = $app->param( 'class' );
                    if ( $class && ( $class ne 'customobjectgroup' ) ) {
                        $config_plugin = MT->component( $class );
                        if (! $config_plugin ) {
                            $config_plugin = MT->component( 'CustomObjectConfig' );
                        }
                    }
                    if (! $class ) {
                        $class = 'customobject';
                    }
                    my $group_name = $group->name;
                    my $template = get_config_inheritance( $config_plugin, 'default_module_mtml', $blog );
                    # my $template = $config_plugin->get_config_value( 'default_module_mtml', 'blog:'. $blog->id );
                    my $tmpl_label;
                    my $model = MT->model( $class );
                    if (! $template ) {
                        if ( $model ) {
                            $template = $model->default_module_mtml;
                        }
                    }
                    if ( $model ) {
                        $tmpl_label = $model->class_label;
                    }
                    if (! $tmpl_label ) {
                        $tmpl_label = $plugin->translate( 'CustomObject Group' );
                    }
                    $template =~ s/\$group_name/$group_name/isg;
                    $group_id = $group->id;
                    $template =~ s/\$group_id/$group_id/isg;
                    my $hidden_field = '<input type="hidden" name="customobjectgroup_id" value="' . $group_id . '" />';
                    $param->{ name } = encode_html( $tmpl_label . ' : ' . $group_name );
                    $param->{ text } = $template;
                    my $pointer_field = $tmpl->getElementById( 'title' );
                    my $innerHTML = $pointer_field->innerHTML;
                    $pointer_field->innerHTML( $innerHTML . $hidden_field );
                }
            }
        }
    }
    if ( $app->param( 'customobject_archive' ) ) {
        $param->{ type } = 'archive';
        my $archive_types = $param->{ archive_types };
        my @custom_archive_types;
        my $custom_objects = MT->registry( 'custom_objects' );
        my @objects = keys( %$custom_objects );
        for my $obj ( @objects ) {
            my $types = $custom_objects->{ $obj }->{ archive_types };
            if ( ref $types && ( ref $types eq 'ARRAY' ) ) {
                for my $t ( @$types ) {
                    push ( @custom_archive_types, $t );
                }
            } else {
                push ( @custom_archive_types, $types );
            }
        }
        my @new_loop;
        for my $type ( @$archive_types ) {
            my $archive_type = $type->{ archive_type };
            if ( grep( /^$archive_type$/, @custom_archive_types ) ) {
                push ( @new_loop, $type );
            }
        }
        $param->{ archive_types } = \@new_loop;
    }
}

sub _cms_post_save_template {
    my ( $cb, $app, $obj, $original ) = @_;
    if (! $original->id ) {
        my $blog = $app->blog;
        if ( defined $blog ) {
            my $type = $obj->type;
            if ( $type ne 'custom' ) {
                return 1;
            }
            my $group_id = $app->param( 'customobjectgroup_id' );
            if ( $group_id ) {
                my $group = CustomObject::CustomObjectGroup->load( $group_id );
                if ( $group ) {
                    $group->template_id( $obj->id );
                    $group->save or die $group->errstr;
                }
            }
        }
    }
    return 1;
}

sub _cms_post_delete_folder {
    my ( $cb, $app, $obj, $original ) = @_;
    require CustomObject::CustomObject;
    my @objects = CustomObject::CustomObject->load( { blog_id => $obj->blog_id,
                                                      category_id => $obj->id,
                                                      class => '*' } );
    for my $obj ( @objects ) {
        $obj->category_id( -1 );
        $obj->save or die $obj->errstr;
    }
    return 1;
}

sub _cms_post_delete_template {
    my ( $cb, $app, $obj, $original ) = @_;
    my $type = $obj->type;
    if ( $type ne 'custom' ) {
        return 1;
    } else {
        require CustomObject::CustomObjectGroup;
        my $group = CustomObject::CustomObjectGroup->load( { template_id => $obj->id } );
        if ( $group ) {
            $group->template_id( undef );
            $group->save or die $group->errstr;
        }
    }
    return 1;
}

sub _edit_customobjectgroup {
    my ( $cb, $app, $param, $tmpl ) = @_;
    require CustomObject::CustomObjectGroup;
    require CustomObject::CustomObjectOrder;
    my $component = MT->component( 'CustomObject' );
    my $type  = $app->param( '_type' );
    my $model = $app->model( $type );
    my $class = $app->param( 'class' );
    if (! $class ) {
        $class = 'customobjectgroup';
    }
    my $child_class = $class;
    $child_class =~ s/group$//;
    my $blog = $app->blog;
    if (! $blog ) {
        $app->return_to_dashboard();
    }
    if (! _group_permission( $app->blog ) ) {
        $app->return_to_dashboard( permission => 1 );
    }
    my $id = $app->param( 'id' );
    my $obj;
    if ( $id ) {
        $obj = $model->load( $id );
        if (! defined $obj ) {
            $app->return_to_dashboard( permission => 1 );
        }
        if ( $obj->blog_id != $blog->id ) {
            $app->return_to_dashboard( permission => 1 );
        }
    }
    my %blogs;
    my @weblog_loop;
    my $website_view;
    my $blog_view;
    my @blog_ids;
    my %terms;
    my %args;
    if ( $child_class ) {
        $terms{ class } = $child_class;
    }
    if (! defined $app->blog ) {
        $app->return_to_dashboard( redirect => 1 );
    } else {
        if (! _group_permission( $app->blog ) ) {
            $app->return_to_dashboard( redirect => 1 );
        }
        if ( $app->blog->class eq 'website' ) {
            push @weblog_loop, {
                    weblog_id => $app->blog->id,
                    weblog_name => $app->blog->name, };
            $website_view = 1;
            $blogs{ $app->blog->id } = $app->blog;
            push ( @blog_ids, $app->blog->id );
            my @all_blogs = MT::Blog->load( { parent_id => $app->blog->id } );
            for my $blog ( @all_blogs ) {
                if ( _group_permission( $blog ) ) {
                    $blogs{ $blog->id } = $blog;
                    push ( @blog_ids, $blog->id );
                    push @weblog_loop, {
                            weblog_id => $blog->id,
                            weblog_name => $blog->name, };
                }
            }
            $param->{ weblog_loop } = \@weblog_loop;
        } else {
            $blog_view = 1;
            push ( @blog_ids, $app->blog->id );
        }
        if (! $blog_view ) {
            $terms{ 'blog_id' } = \@blog_ids;
        } else {
            $terms{ 'blog_id' } = $app->blog->id;
        }
        my @customobjects;
        if ( $app->param( 'filter' ) && $app->param( 'filter' ) eq 'tag' ) {
            require MT::Tag;
            my $tag = MT::Tag->load( { name => $app->param( 'filter_tag' ) }, { binary => { name => 1 } } );
            if ( $tag ) {
                require MT::ObjectTag;
                $args { 'join' } = [ 'MT::ObjectTag', 'object_id',
                           { tag_id  => $tag->id,
                             blog_id => \@blog_ids,
                             object_datasource => 'customobject' }, ];
                @customobjects = MT->model( 'customobject' )->load( \%terms, \%args );
            }
        } else {
            @customobjects = MT->model( 'customobject' )->load( \%terms, \%args );
        }
        my @item_loop;
        for my $customobject ( @customobjects ) {
            my $add_item = 1;
            if ( $id ) {
                my $item = MT->model( 'customobjectorder' )->load( { group_id => $id, customobject_id => $customobject->id } );
                $add_item = 0 if defined $item;
            }
            if ( $add_item ) {
                my $weblog_name = '';
                if (! $blog_view ) {
                    $weblog_name = $blogs{ $customobject->blog_id }->name;
                    $weblog_name = " ($weblog_name)";
                }
                push @item_loop, {
                        id => $customobject->id,
                        status => $customobject->status,
                        item_name => $customobject->name . $weblog_name,
                        weblog_id => $customobject->blog_id, };
            }
        }
        $param->{ item_loop } = \@item_loop;
        if ( $id ) {
            my $args = { 'join' => [ 'CustomObject::CustomObjectOrder', 'customobject_id',
                       { group_id => $id, },
                       { sort => 'order',
                         direction => 'ascend',
                       } ] };
            my @customobjects = MT->model( 'customobject' )->load( \%terms, $args );
            my @group_loop;
            for my $customobject ( @customobjects ) {
                my $weblog_name = '';
                if (! $blog_view ) {
                    $weblog_name = $blogs{ $customobject->blog_id }->name;
                    $weblog_name = " ($weblog_name)";
                }
                push @group_loop, {
                        id => $customobject->id,
                        status => $customobject->status,
                        item_name => $customobject->name . $weblog_name,
                        weblog_id => $customobject->blog_id, };
            }
            $param->{ group_loop } = \@group_loop;
        }
    }
    my @groups = CustomObject::CustomObjectGroup->load( { blog_id => $blog->id, class => $class } );
    if ( @groups ) {
        my @names;
        for my $g ( @groups ) {
            if ( (! $id ) || $id != $g->id ) {
                push ( @names, "'" . encode_js ( $g->name ) . "'" );
            }
        }
        my $names_array = join( ' , ', @names );
        $param->{ names_array } = $names_array if $names_array;
    }
    $param->{ saved } = $app->param( 'saved' );
    $param->{ search_label } = $component->translate( 'CustomObject' );
    $param->{ return_args } = _force_view_mode_return_args( $app );
    my $plugin = 'customobjectconfig';
    $param->{ class } = encode_html( $class );
    if ( $child_class && ( $child_class ne 'customobject' ) ) {
        $plugin = $child_class;
        $param->{ screen_group } = $child_class;
        $param->{ component } = $child_class;
        $param->{ return_args } = $param->{ return_args } . '&class=' . encode_url( $class );
    } else {
        $param->{ screen_group } = 'customobject';
        $param->{ component } = 'customobject';
        $child_class = 'customobject';
    }
    if (! $app->param( 'id' ) ) {
        my $top_nav_loop = $param->{ top_nav_loop };
        my $mode = $app->mode;
        for my $nav ( @$top_nav_loop ) {
            if ( my $sub_nav = $nav->{ sub_nav_loop } ) {
                for my $sub_sub ( @$sub_nav ) {
                    if ( $sub_sub->{ current } ) {
                        $sub_sub->{ current } = 0;
                    } elsif ( $sub_sub->{ id } eq $child_class . ':create_customobjectgroup' ) {
                        $sub_sub->{ current } = 1;
                    }
                }
            }
        }
    }
    $param->{ search_type } = $child_class;
    $param->{ filter } = $app->param( 'filter' );
    if ( my $filter_tag = $app->param( 'filter_tag' ) ) {
        $param->{ filter_tag } = $filter_tag;
        $param->{ return_args } = $param->{ return_args } . '&filter_tag=' . encode_url( $filter_tag );
    }
    my ( $label_en, $label_ja, $label_plural ) = __get_settings( $app, $app->blog, $plugin );
    if ( $app->user->preferred_language eq 'ja' ) {
        $param->{ class_label } = $label_ja;
        $param->{ class_label_plural } = $label_ja;
        $param->{ search_label } = $label_ja;
    } else {
        $param->{ class_label } = $label_en;
        $param->{ class_label_plural } = $label_plural;
        $param->{ search_label } = $label_en;
    }
}

sub _load_customobject_admin {
    my @blog_id = @_;
    push ( @blog_id, 0 );
    my $author_class = MT->model( 'author' );
    require MT::Author;
    my %terms1 = ( blog_id => \@blog_id, permissions => { like => "%'administer%" } );
    my @admin = $author_class->load(
        { type => MT::Author::AUTHOR(), },
        { join => [ 'MT::Permission', 'author_id',
            \%terms1,
            { unique => 1 } ],
        }
    );
    my @author_id;
    for my $author ( @admin ) {
        push ( @author_id, $author->id );
    }
    my %terms2 = ( blog_id => \@blog_id, permissions => { like => "%'manage_customobject'%" } );
    my @customobject_admin = $author_class->load(
        { type => MT::Author::AUTHOR(),
          id => { not => \@author_id } },
        { join => [ 'MT::Permission', 'author_id',
            \%terms2,
            { unique => 1 } ],
        }
    );
    push ( @admin, @customobject_admin );
    return @admin;
}

sub _install_role {
    my $app = MT->instance();
    eval { # FIXME: new install needs eval?
        require MT::Role;
        my $plugin = MT->component( 'CustomObject' );
        my $role = MT::Role->get_by_key( { name => $plugin->translate( 'CustomObject Administrator' ) } );
        if (! $role->id ) {
            my $role_en = MT::Role->load( { name => 'CustomObject Administrator' } );
            if (! $role_en ) {
                my %values;
                $values{ created_by }  = $app->user->id;
                $values{ description } = $plugin->translate( 'Can create CustomObject, edit CustomObject.' );
                $values{ is_system }   = 0;
                $values{ permissions } = "'manage_customobject','manage_customobjectgroup'";
                $role->set_values( \%values );
                $role->save
                    or return $app->trans_error( 'Error saving role: [_1]', $role->errstr );
            }
        }
    };
    return 1;
}

sub _force_view_mode_return_args {
    my $app = shift;
    my $return = $app->make_return_args;
    if ( $app->mode eq 'save' ) {
        $return =~ s/save/view/;
    } else {
        $return =~ s/edit/view/;
    }
    $return =~ s/&id=$/$1/;
    return $return;
}

sub _view_log {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my ( $label_en, $label_ja, $label_plural ) = __get_settings( $app );
    my $class_loop = $param->{ class_loop };
    push @$class_loop, { class_name => 'customobject', class_label => $label_ja };
    my $custom_objects = MT->registry( 'custom_objects' );
    my @objects = keys( %$custom_objects );
    for my $object ( @objects ) {
        if ( $object ne 'customobject' ) {
            my ( $object_en, $object_ja, $object_plural ) = __get_settings( $app, $app->blog, $object );
            push @$class_loop, { class_name => $object, class_label => $object_ja };
        }
    }
    $param->{ class_loop } = $class_loop;
}

sub _template_table {
    my ( $cb, $app, $tmpl ) = @_;
    if ( $app->blog ) {
        if (! $app->blog->is_blog ) {
            my $pointer = '<li><a href="<mt:var name="script_url">?__mode=view&amp;_type=template&amp;type=archive';
            my $search = quotemeta( $pointer );
            $$tmpl =~ s!$search!</mt:if><mt:if name="blog_id">$pointer!;
            $$tmpl =~ s!<__trans\sphrase="Entry\sListing">!<__trans phrase="Archive">!;
        }
    }
}

sub _display_options {
    my ( $cb, $app, $tmpl ) = @_;
    my $mode = $app->mode;
    if ( ( $mode eq 'list_customobject' ) || ( $mode eq 'list_customobjectgroup' ) ) {
        if ( my $class = $app->param( 'class' ) ) {
            my $old = quotemeta( '<mt:var name="OBJECT_TYPE">' );
            my $pref_id = 'customobject_';
            if ( $mode eq 'list_customobjectgroup' ) {
                $pref_id .= 'gp_'
            }
            $pref_id .= $class;
            $$tmpl =~ s/$old/$pref_id/;
            my $list_pref = $app->list_pref( $pref_id );
            if ( $list_pref ) {
                my $pref = $list_pref->{ rows };
                my @limits = qw(25 50 100 200);
                # <mt:if name="LIMIT_25"> selected="selected"</mt:if>
                for my $limit ( @limits ) {
                    my $search = '<mt:if name="LIMIT_' . $limit . '"> selected="selected"</mt:if>';
                    $search = quotemeta( $search );
                    my $new = '';
                    if ( $limit == $pref ) {
                        $new = ' selected="selected"';
                    }
                    $$tmpl =~ s/$search/$new/;
                }
            }
        }
    }
}

sub _footer_source {
    my ( $cb, $app, $tmpl ) = @_;
    my $id = MT->component(__PACKAGE__ =~ /^([^:]+)/)->id;
    $$tmpl =~ s{(<__trans phrase="http://www\.sixapart\.com/movabletype/">)}
               {<mt:if name="id" eq="$id"><__trans phrase="http://alfasado.net/"><mt:else>$1</mt:if>};
}

sub _get_end_date {
    my ( $blog, $ts, $day ) = @_;
    $ts = ts2epoch( $blog, $ts );
    $ts += 86400 * $day;
    return epoch2ts( $blog, $ts );
}

sub _cb_restore {
    my ( $cb, $objects, $deferred, $errors, $callback ) = @_;

    my $custom_objects = MT->registry( 'custom_objects' );
    my @custom_object_models = keys %$custom_objects;
    my @custom_object_classes = map { MT->model( $_ ) } @custom_object_models;
    
    my %restored_objects;
    for my $key ( keys %$objects ) {
        if ( grep { $key =~ /^\Q$_\E[(:?Group)]*#(\d+)$/ } @custom_object_classes ) {
            $restored_objects{ $key } = $objects->{ $key };
        }
    }

    require CustomFields::Field;

    my %class_fields;
    $callback->(
        MT->translate(
            "Restoring customobject associations found in custom fields ...",
        ),
        'cf-restore-object-customobject'
    );

    my $r = MT::Request->instance();
    for my $restored_object ( values %restored_objects ) {
        for my $custom_object_model ( @custom_object_models ) {
            {
                my $field = CustomFields::Field->load( { blog_id  => [ $restored_object->blog_id, 0 ],
                                                         type => $custom_object_model,
                                                       }
                                                     );
                next unless $field;
                my $class = MT->model( $field->obj_type );
                my @related_objects = $class->load( $class->has_column( 'blog_id' ) ? { blog_id => $restored_object->blog_id } : undef );
                my $column_name = 'field.' . $field->basename;
                for my $related_object ( @related_objects ) {
                    my $cache_key = $class . ':' . $related_object->id . ':' . $column_name;
                    next if $r->cache( $cache_key );
                    my $value = $related_object->$column_name;
                    my $restored_value;
                    my $restored = $objects->{ MT->model( $custom_object_model ) . '#' . $value };
                    if ( $restored ) {
                        $restored_value = $restored->id;
                    }
                    $related_object->$column_name( $restored_value );
                    $related_object->save or die $related_object->errstr;
                    $r->cache( $cache_key, 1 );
                }
            }
            {
                # multi
                my $field = CustomFields::Field->load( { blog_id  => [ $restored_object->blog_id, 0 ],
                                                         type => $custom_object_model . '_multi',
                                                       }
                                                     );
                next unless $field;
                my $class = MT->model( $field->obj_type );
                my @related_objects = $class->load( { blog_id => $restored_object->blog_id } );
                my $column_name = 'field.' . $field->basename;
                for my $related_object ( @related_objects ) {
                    my $cache_key = $class . ':' . $related_object->id . ':' . $column_name;
                    next if $r->cache( $cache_key );
                    my $value = $related_object->$column_name;
                    my @values = split( /,/, $value );
                    my @new_values;
                    for my $backup_id ( @values ) {
                        next unless $backup_id;
                        next unless $objects->{ MT->model( $custom_object_model ) . '#' . $backup_id };
                        my $restored_obj = $objects->{ MT->model( $custom_object_model ) . '#' . $backup_id };
                        push( @new_values, $restored_obj->id );
                    }
                    my $restored_value;
                    if ( @new_values ) {
                        $restored_value = ',' . join( ',', @new_values ) . ',';
                    }
                    $related_object->$column_name( $restored_value );
                    $related_object->save or die $related_object->errstr;
                    $r->cache( $cache_key, 1 );
                }
            }
            {
                # group
                my $field = CustomFields::Field->load( { blog_id  => [ $restored_object->blog_id, 0 ],
                                                         type => $custom_object_model . '_group',
                                                       }
                                                     );
                next unless $field;
                my $class = MT->model( $field->obj_type );
                my @related_objects = $class->load( { blog_id => $restored_object->blog_id } );
                my $column_name = 'field.' . $field->basename;
                for my $related_object ( @related_objects ) {
                    my $cache_key = $class . ':' . $related_object->id . ':' . $column_name;
                    next if $r->cache( $cache_key );
                    my $value = $related_object->$column_name;
                    my $restored_value;
                    my $restored = $objects->{ MT->model( $custom_object_model ) . 'Group#' . $value };
                    if ( $restored ) {
                        $restored_value = $restored->id;
                    }
                    $related_object->$column_name( $restored_value );
                    $related_object->save or die $related_object->errstr;
                    $r->cache( $cache_key, 1 );
                }
            }
        }
    }
    $callback->( MT->translate( "Done." ) . "\n" );
    
    # restore template_id
    for my $key ( keys %$objects ) {
        if ( grep { $key =~ /^\Q$_\EGroup#(\d+)$/ } @custom_object_classes ) {
            my $new_group = $objects->{$key};
            if ( my $template_id = $new_group->template_id ) {
                my $new_template = $objects->{ 'MT::Template#'.$template_id };
                $new_group->template_id( $new_template ? $new_template->id : undef );
                $new_group->update();
            }
        }
    }
    
    1;
}

sub _cb_customobjectorder_post_save {
   my ( $cb, $obj ) = @_;
   unless ( $obj->group_class ) {
       if ( my $group_id = $obj->group_id() ) {
           my $customobjectgroup = MT->model( 'customobjectgroup' )->load( { id => $group_id } );
           if ( $customobjectgroup ) {
               $obj->group_class( $customobjectgroup->class );
               $obj->save or die $obj->errstr;
           }
       }
   }
1;
}

sub _cb_blog_post_delete { # especially for 'customobjectgroup'
    my ( $cb, $app, $obj ) = @_;
    my $blog_id = $obj->id;
    my @object_models = ( 'customobject', 'customobjectgroup', 'customobjectorder' );
    for my $model ( @object_models ) {
        my $terms = { blog_id => $blog_id };
        $terms->{ class } = '*' unless $model eq 'customobjectorder';
        my @objects = MT->model( $model )->load( $terms );
        for my $object ( @objects ) {
           $object->remove;
        }
    }
    1;
}

sub _cb_cmssavefilter_customfield_objs {
    my ( $cb, $app ) = @_;
    if ( MT->component( 'Commercial' )->version >= 1.62 ) {
        my $method = $cb->method();
        if ( $method =~ /^cms_save_filter\.(.*?)$/ ) {
            my $class = $1;
            unshift( @_, $class );
        }
    }
    require CustomFields::App::CMS;
    CustomFields::App::CMS::CMSSaveFilter_customfield_objs( @_ );
}

1;