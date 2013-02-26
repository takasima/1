package ContactForm::Plugin;

use strict;
use File::Temp qw( tempdir );

use MT::Util qw( format_ts offset_time_list encode_js encode_html ts2epoch epoch2ts );
use MT::I18N qw( substr_text length_text );
use ContactForm::Util qw( is_user_can upload utf8_on utf8_off read_from_file
                          get_weblog_ids current_ts remove_item csv_new is_windows
                          plugin_template_path encode_utf8_string_to_cp932_octets format_LF
                          valid_url valid_email valid_ts valid_phone_number valid_postal_code );

sub _init_request {
    my $app = MT->instance;
    if ( ref $app eq 'MT::App::CMS' ) {
        if ( ( $app->param( 'dialog_view' ) ) || ( MT->version_id =~ /^5\.0/ ) ) {
            $app->add_methods( list_contactform => \&_list_contactform );
            $app->add_methods( list_contactformgroup => \&_list_contactform );
            $app->add_methods( list_feedback => \&_list_contactform );
            my $menus = MT->registry( 'applications', 'cms', 'menus' );
            $menus->{ 'contactform:list_contactform' }->{ mode } = 'list_contactform';
            $menus->{ 'contactform:list_contactformgroup' }->{ mode } = 'list_contactformgroup';
            $menus->{ 'contactform:feedback' }->{ mode } = 'list_feedback';
        }
    }
    $app;
}

sub _pre_run {
    my ( $cb, $app ) = @_;
    #unless ( $app->blog ) {
    #    my $usermenu = $app->component( 'UserMenu' );
    #    my $powercms = $app->component( 'PowerCMS' );
    #    if ( $usermenu || $powercms ) {
    #        my $menus = MT->registry( 'applications', 'cms', 'menus' );
    #        $menus->{ 'contactform:feedback' }->{ view } = [ 'user', 'system', 'website', 'blog' ];
    #        $menus->{ 'contactform:list_contactformgroup' }->{ view } = [ 'user', 'system', 'website', 'blog' ];
    #        $menus->{ 'contactform:list_contactform' }->{ view } = [ 'user', 'system' ];
    #        $menus->{ 'contactform:create_contactform' }->{ view } = [ 'user', 'system' ];
    #    }
    #}
    if ( ( $app->mode eq 'save' ) && ( $app->param( '_type' ) eq 'contactform' ) ) {
        my $id = $app->param( 'id' );
        if ( $id ) {
            my $original = MT->model( 'contactform' )->load( $id );
            $original = $original->clone_all() if $original;
            require MT::Request;
            MT::Request->instance->cache( 'contactform_original' . $id, $original );
        }
    }
    if ( my $_type = $app->param( '_type' ) ) {
        if ( ( $app->mode eq 'search_replace' ) && ( $_type eq 'feedback' ) ) {
            if ( my $search = $app->param( 'search' ) ) {
                $app->param( 'search', utf8_off( $search ) );
            }
        }
    }
    return 1;
}

sub _post_run {
    my $app = MT->instance();
    if ( $app->mode eq 'run_actions' ) {
        if ( $app->param( 'installing' ) ) {
            require ContactForm::Upgrade;
            ContactForm::Upgrade::_upgrade_functions();
        }
    }
    return 1;
}

sub _serarch_replace_param {
    my ( $cb, $app, $param, $tmpl ) = @_;
    if ( my $_type = $app->param( '_type' ) ) {
        if ( ( $app->mode eq 'search_replace' ) && ( $_type eq 'feedback' ) ) {
            if ( my $search = $app->param( 'search' ) ) {
                $param->{ search } = utf8_on( $search );
            }
        }
    }
}

sub _contactform_permission {
    my $blog = shift;
    my $app = MT->instance();
    my $user = $app->user;
    return 1 if $user->is_superuser;
    if ( ref $blog ne 'MT::Blog' ) {
        $blog = undef;
    }
    $blog ||= $app->blog;
    if ( is_user_can( $blog, $user, 'administer_blog' ) ) {
        return 1;
    }
    if ( is_user_can( $blog, $user, 'manage_contactform' ) ) {
        return 1;
    }
    return 0;
}

sub _feedback_permission {
    my $blog = shift;
    my $app = MT->instance();
    my $user = $app->user;
    return 1 if $user->is_superuser;
    if ( ref $blog ne 'MT::Blog' ) {
        $blog = undef;
    }
    $blog ||= $app->blog;
    if ( is_user_can( $blog, $user, 'administer_blog' ) ) {
        return 1;
    }
    if ( is_user_can( $blog, $user, 'manage_form_feedback' ) ) {
        return 1;
    }
    return 0;
}

sub _formelement_permission {
    my $app = MT->instance();
    my $user = $app->user;
    return 1 if $user->is_superuser;
    return 1 if $user->can_manage_formelement;
    my $perms = $user->permissions;
    # return $app->return_to_dashboard( redirect => 1 )
    #        unless $perms || $user->is_superuser;
    if ( $perms && !$perms->can_manage_formelement ) {
        return 0;
    }
    return 1;
}

sub _view_contactform {
    my $app = shift;
    my $plugin = MT->component( 'ContactForm' );
    $app->{ plugin_template_path } = plugin_template_path( $plugin );
    $app->mode( 'edit' );
    return $app->forward( 'edit', @_ );
}

sub _list_contactform {
    my $app = shift;
    my $plugin = MT->component( 'ContactForm' );
    my $user = $app->user;
    my $mode = $app->mode;
    my $list_id = $mode;
    $list_id =~ s/^list_//;
    my %blogs;
    my $system_view;
    my $website_view;
    my $blog_view;
    my @blog_ids;
    my $r = MT::Request->instance;
    if (! defined $app->blog ) {
        $system_view = 1;
        if ( $list_id ne 'contactform' ) {
            my @all_blogs = MT::Blog->load( { class => [ 'website', 'blog' ] } );
            for my $blog ( @all_blogs ) {
                my $perm;
                if ( $list_id =~ /feedback$/ ) {
                    $perm = _feedback_permission( $blog );
                } else {
                    $perm = _contactform_permission( $blog );
                }
                if ( $perm ) {
                    $blogs{ $blog->id } = $blog;
                    push( @blog_ids, $blog->id );
                }
            }
        }
    } else {
        if ( $list_id =~ /feedback$/ ) {
            if (! _feedback_permission( $app->blog ) ) {
                return $app->trans_error( 'Permission denied.' );
            }
        } else {
            if (! _contactform_permission( $app->blog ) ) {
                return $app->trans_error( 'Permission denied.' );
            }
        }
        if ( $app->blog->class eq 'website' ) {
            $website_view = 1;
            $blogs{ $app->blog->id } = $app->blog;
            push ( @blog_ids, $app->blog->id );
            my $all_blogs = $app->blog->blogs;
            for my $blog ( @$all_blogs ) {
                my $perm;
                if ( $list_id =~ /feedback$/ ) {
                    $perm = _feedback_permission( $blog );
                } else {
                    $perm = _contactform_permission( $blog );
                }
                if ( $perm ) {
                    $blogs{ $blog->id } = $blog;
                    push ( @blog_ids, $blog->id );
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
            if ( $column =~ /_on$/ ) {
                $val = format_ts( '%Y&#24180;%m&#26376;%d&#26085;', $val, undef,
                                  $app->user ? $app->user->preferred_language : undef );
            } else {
                if ( $val ) {
                    $val = substr_text( $val, 0, 30 ) . ( length_text( $val ) > 30 ? '...' : '' );
                }
            }
            $row->{ $column } = $val;
        }
        if ( $list_id =~ /feedback$/ ) {
            my @get_table = $obj->get_table;
            my @data_loop;
            my $str = '';
            my $form = $obj->form;
            my $types = $form->_types;
            for my $data ( @get_table ) {
                push @data_loop, { field_label => @$data[0], field_data => @$data[1] };
                $str .= ', ' if $str;
                my $val = @$data[1];
                my $label = @$data[0];
                my $is_date;
                if ( $types && $types->{ $label } eq 'date' ) {
                    $val = format_ts( '%Y&#24180;%m&#26376;%d&#26085;', $val, undef,
                                  $app->user ? $app->user->preferred_language : undef );
                    $is_date = 1;
                }
                if (! $is_date && $val ) {
                    $val = encode_html( $val );
                    $val =~ s/\n+//g;
                }
                $str .= $val;
            }
            $str = substr_text( $str, 0, 70 ) . ( length_text( $str ) > 70 ? '...' : '' );
            $row->{ data_loop } = \@data_loop;
            $row->{ value } = $str;
            if ( $form ) {
                $row->{ form_id } = $form->id;
                $row->{ form_name } = $form->name;
                $row->{ author_name } = $form->author->name;
                $row->{ author_id } = $form->author->id;
            }
            if ( my $form_object = $obj->object ) {
                my $object_label = $obj->object_label;
                my $object_name = $obj->object_name;
                $row->{ parent_object_name } = $object_name;
                $row->{ parent_object_label } = $object_label;
                $row->{ parent_object } = 1;
            } else {
                $row->{ parent_object_name } = $obj->object_name;
                $row->{ parent_object_label } = $obj->object_label;
            }
            # $row->{ object_id } = $obj->object_id;
            # $row->{ model } = $obj->model;
        }
        if (! $blog_view ) {
            if ( $list_id ne 'contactform' ) {
                if ( defined $blogs{ $obj->blog_id } ) {
                    my $blog_name = $blogs{ $obj->blog_id }->name;
                    $blog_name = substr_text( $blog_name, 0, 20 ) . ( length_text( $blog_name ) > 20 ? '...' : '' );
                    $row->{ weblog_name } = $blog_name;
                    $row->{ weblog_id } = $obj->blog_id;
                    if ( $list_id !~ /feedback$/ ) {
                        $row->{ can_edit } = _contactform_permission( $blogs{ $obj->blog_id } );
                        $row->{ can_feedback } = _feedback_permission( $blogs{ $obj->blog_id } );
                    } else {
                        $row->{ can_edit } = _feedback_permission( $blogs{ $obj->blog_id } );
                    }
                }
            } else {
                $row->{ can_edit } = 1;
            }
        } else {
            $row->{ can_edit } = 1;
        }
        if ( $list_id =~ /group$/ ) {
            require ContactForm::ContactFormOrder;
            my $count = ContactForm::ContactFormOrder->count( { group_id => $obj->id } );
            $row->{ count } = $count;
            $row->{ feedback_count } = $obj->feedback_count;
        } elsif ( $list_id !~ /feedback$/ ) {
            $row->{ field_label } = $obj->label;
        }
        if ( $list_id !~ /feedback$/ ) {
            my $obj_author = $obj->author;
            $row->{ author_name } = $obj_author->name;
        } else {
            my $form_author = $obj->form_author;
            $row->{ form_author_name } = $form_author->name;
            $row->{ form_author_id } = $form_author->id;
        }
    };
    my %terms;
    my $param;
    # if ( $list_id !~ /feedback$/ ) {
    my @contactform_admin;
    if ( $list_id =~ /group$/ ) {
        @contactform_admin = _load_contactform_admin( @blog_ids );
    } elsif ( $list_id =~ /feedback$/ ) {
        @contactform_admin = _load_feedback_admin( @blog_ids );
        require ContactForm::ContactFormGroup;
        my @groups = ContactForm::ContactFormGroup->load( { blog_id => \@blog_ids } );
        my @contactform_group_loop;
        for my $group ( @groups ) {
            push ( @contactform_group_loop, { group_id => $group->id, group_name => $group->name } );
        }
        $param->{ contactform_group_loop } = \@contactform_group_loop;
    } else {
        @contactform_admin = _load_formelement_admin();
    }
    my @author_loop;
    for my $admin ( @contactform_admin ) {
        $r->cache( 'cache_author:' . $admin->id, $admin );
        push @author_loop, {
                author_id => $admin->id,
                author_name => $admin->name, };
    }
    $param->{ author_loop } = \@author_loop;
    # }
    __contactform_objects_param( \$param );
    $app->{ plugin_template_path } = plugin_template_path( $plugin );
    $param->{ list_id }        = $list_id;
    $param->{ system_view }    = $system_view;
    $param->{ website_view }   = $website_view;
    $param->{ blog_view }      = $blog_view;
    $param->{ filter }         = $app->param( 'filter' );
    $param->{ filter_val }     = $app->param( 'filter_val' );
    $param->{ approved }       = $app->param( 'approved' );
    $param->{ unapproved }     = $app->param( 'unapproved' );
    $param->{ flagged }        = $app->param( 'flagged' );
    $param->{ not_approved }   = $app->param( 'not_approved' );
    $param->{ not_unapproved } = $app->param( 'not_unapproved' );
    $param->{ not_flagged }    = $app->param( 'not_flagged' );
    $param->{ edit_field }     = $app->param( 'edit_field' );
    $param->{ LIST_NONCRON }   = 1;
    $param->{ saved_deleted }  = 1 if $app->param( 'saved_deleted' );
    $param->{ dialog_view }    = 1 if $app->param( 'dialog_view' );
    $param->{ imported }       = 1 if $app->param( 'imported' );
    $param->{ not_imported }   = 1 if $app->param( 'not_imported' );
    if ( $list_id eq 'contactform' ) {
        $param->{ search_label } = $plugin->translate( 'Form Element' );
    } elsif ( $list_id eq 'contactformgroup' ) {
        $param->{ search_label } = $plugin->translate( 'Contact Form' );
    } elsif ( $list_id eq 'feedback' ) {
        $param->{ search_label } = $plugin->translate( 'Feedback' );
    }
    if ( my $query = $app->param( 'query' ) ) {
        $terms{ name } = { like => '%' . $query . '%' };
        $param->{ query } = $query;
    }
    if ( $list_id =~ /feedback$/ ) {
        if ( my $model = $app->param( 'model' ) ) {
            $param->{ filter_model } = $model;
            $terms{ model } = $model;
        }
    }
    if ( $list_id ne 'contactform' ) {
        $terms{ blog_id } = \@blog_ids;
    }
    my %args;
    $args{ sort } = 'created_on';
    $args{ direction } = 'descend';
    if ( $app->param( 'dialog_view' ) ) {
        $args{ limit } = 25;
    }
    return $app->listing (
        {
            type   => $list_id,
            code   => $code,
            args   => \%args,
            params => $param,
            terms  => \%terms,
        }
    );
}

sub _search_contactform {
    my $app = shift;
    my $plugin = MT->component( 'ContactForm' );
    my ( %args ) = @_;
    my %blogs;
    my $system_view;
    my $website_view;
    my $blog_view;
    my @blog_ids;
    my $list_id = $app->param( '_type' );
    my $r = MT::Request->instance;
    if (! defined $app->blog ) {
        $system_view = 1;
        if ( $list_id ne 'contactform' ) {
            my @all_blogs = MT::Blog->load( { class => [ 'website', 'blog' ] } );
            for my $blog ( @all_blogs ) {
                my $perm;
                if ( $list_id =~ /feedback$/ ) {
                    $perm = _feedback_permission( $blog );
                } else {
                    $perm = _contactform_permission( $blog );
                }
                if ( $perm ) {
                    $blogs{ $blog->id } = $blog;
                    push( @blog_ids, $blog->id );
                }
            }
        }
    } else {
        if ( $list_id =~ /feedback$/ ) {
            if (! _feedback_permission( $app->blog ) ) {
                return $app->trans_error( 'Permission denied.' );
            }
        } else {
            if (! _contactform_permission( $app->blog ) ) {
                return $app->trans_error( 'Permission denied.' );
            }
        }
        if ( $app->blog->class eq 'website' ) {
            $website_view = 1;
            $blogs{ $app->blog->id } = $app->blog;
            push ( @blog_ids, $app->blog->id );
            my $all_blogs = $app->blog->blogs;
            for my $blog ( @$all_blogs ) {
                my $perm;
                if ( $list_id =~ /feedback$/ ) {
                    $perm = _feedback_permission( $blog );
                } else {
                    $perm = _contactform_permission( $blog );
                }
                if ( $perm ) {
                    $blogs{ $blog->id } = $blog;
                    push ( @blog_ids, $blog->id );
                }
            }
        } else {
            $blog_view = 1;
            push ( @blog_ids, $app->blog->id );
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
        if ( $list_id =~ /feedback$/ ) {
            my @get_table = $obj->get_table;
            my @data_loop;
            my $str = '';
            my $form = $obj->form;
            my $types = $form->_types;
            for my $data ( @get_table ) {
                push @data_loop, { field_label => @$data[0], field_data => @$data[1] };
                $str .= ', ' if $str;
                my $val = @$data[1];
                my $label = @$data[0];
                my $is_date;
                if ( $types && $types->{ $label } eq 'date' ) {
                    $val = format_ts( '%Y&#24180;%m&#26376;%d&#26085;', $val, undef,
                                  $app->user ? $app->user->preferred_language : undef );
                    $is_date = 1;
                }
                if (! $is_date && $val ) {
                    $val = encode_html( $val );
                    $val =~ s/\n+//g;
                }
                $str .= $val;
            }
            $str = substr_text( $str, 0, 70 ) . ( length_text( $str ) > 70 ? '...' : '' );
            $row->{ data_loop } = \@data_loop;
            $row->{ value } = $str;
            if ( $form ) {
                $row->{ form_id } = $form->id;
                $row->{ form_name } = $form->name;
                $row->{ author_name } = $form->author->name;
                $row->{ author_id } = $form->author->id;
            }
            if ( my $form_object = $obj->object ) {
                my $object_label = $obj->object_label;
                my $object_name = $obj->object_name;
                $row->{ parent_object_name } = $object_name;
                $row->{ parent_object_label } = $object_label;
                $row->{ parent_object } = 1;
            } else {
                $row->{ parent_object_name } = $obj->object_name;
                $row->{ parent_object_label } = $obj->object_label;
            }
            # $row->{ object_id } = $obj->object_id;
            # $row->{ model } = $obj->model;
        }
        if (! $blog_view ) {
            if ( defined $blogs{ $obj->blog_id } ) {
                my $blog_name = $blogs{ $obj->blog_id }->name;
                $blog_name = substr_text( $blog_name, 0, 20 ) . ( length_text( $blog_name ) > 20 ? '...' : '' );
                $row->{ weblog_name } = $blog_name;
                $row->{ weblog_id } = $obj->blog_id;
                $row->{ can_edit } = _contactform_permission( $blogs{ $obj->blog_id } );
            } else {
                $row->{ can_edit } = _contactform_permission();
            }
        } else {
            $row->{ can_edit } = 1;
        }
        if ( $list_id =~ /group$/ ) {
            require ContactForm::ContactFormOrder;
            my $count = ContactForm::ContactFormOrder->count( { group_id => $obj->id } );
            $row->{ count } = $count;
        } elsif ( $list_id !~ /feedback$/ ) {
            $row->{ field_label } = $obj->label;
        }
        if ( $list_id !~ /feedback$/ ) {
            my $obj_author = $obj->author;
            $row->{ author_name } = $obj_author->name;
        } else {
            my $form_author = $obj->form_author;
            $row->{ form_author_name } = $form_author->nickname || $form_author->name;
            $row->{ form_author_id } = $form_author->id;
        }
        my $obj_author = $obj->author;
        $row->{ author_name } = $obj_author->nickname || $obj_author->name;
        push @data, $row;
        last if $limit and @data > $limit;
    }
    if ( $list_id eq 'contactform' ) {
        $param->{ search_label } = $plugin->translate( 'Form Element' );
    } elsif ( $list_id eq 'contactformgroup' ) {
        $param->{ search_label } = $plugin->translate( 'Contact Form' );
    } elsif ( $list_id eq 'feedback' ) {
        $param->{ search_label } = $plugin->translate( 'Feedback' );
    }
    $param->{ search_type } = $list_id;
    $param->{ search_replace } = 1;
    return [] unless @data;
    $param->{ system_view } = 1 unless $app->param ( 'blog_id' );
    $param->{ object_loop } = \@data;
    \@data;
}

sub _upload_contactform_csv {
    my $app = shift;
    my $plugin = MT->component( 'ContactForm' );
    my $user = $app->user;
    my $blog = $app->blog;
    if ( defined $blog ) {
        $app->return_to_dashboard();
    }
    if (! _formelement_permission() ) {
        return $app->trans_error( 'Permission denied.' );
    }
    $app->validate_magic or return $app->trans_error( 'Permission denied.' );
    my $csv = csv_new()
        or return $app->error( $plugin->translate( 'Neither Text::CSV_XS nor Text::CSV is available.' ) );
    my $tempdir = $app->config( 'TempDir' );
    my $workdir = tempdir( DIR => $tempdir );
    my %params = ( format_LF => 1,
                   singler => 1,
                   no_asset => 1,
                  );
    my $upload = upload( $app, undef, 'file', $workdir, \%params );
    require MT::Author;
    my $i = 0;
    my $do;
    my @column_names;
    open my $fh, '<', $upload;
    my $model = $app->model( 'contactform' );
    my $cnames = $model->column_names;
    while ( my $columns = $csv->getline ( $fh ) ) {
        if (! $i ) {
            for my $cell ( @$columns ) {
                push ( @column_names, $cell );
            }
        } else {
            my $j = 0;
            my $perm = 1;
            my $ts = current_ts();
            my $id;
            my %values;
            my $csv_obj;
            for my $cell ( @$columns ) {
                $csv_obj->{ $column_names[$j] } = $cell;
                if ( $model->has_column( $column_names[$j] ) ) {
                    my $guess_encoding = MT::I18N::guess_encoding( $cell );
                    unless ( $guess_encoding =~ /^utf-?8$/i ) {
                        $cell = utf8_on( MT::I18N::encode_text( $cell, 'cp932', 'utf8' ) );
                    }
                    if ( $column_names[$j] eq 'id' ) {
                        $id = $cell;
                    } else {
                        if ( $column_names[$j] =~ /_on$/ ) {
                            if (! $cell ) {
                                $cell = $ts;
                            } else {
                                $cell =~ s/^\t//;
                            }
                        }
                    }
                    $values{ $column_names[$j] } = $cell;
                }
                $j++;
            }
            my $contactform;
            if ( $id ) {
                $contactform = $model->get_by_key( { id => $id } );
            } else {
                $contactform = $model->new;
            }
            for my $name ( @$cnames ) {
                if ( $name =~ /_on$/ ) {
                    if (! $contactform->$name ) {
                        $contactform->$name( $ts );
                    }
                } else {
                    $contactform->$name( $values{ $name } );
                }
            }
            if ( $contactform->author_id ) {
                my $author = MT::Author->load( $contactform->author_id );
                if (! defined $author ) {
                    $perm = 0;
                }
            } else {
                $contactform->author_id( $app->user->id );
            }
            if (! $contactform->name ) {
                $perm = 0;
            }
            if ( $perm ) {
                $app->run_callbacks( 'cms_pre_import.contactform', $app, $contactform, $csv_obj ) || next;
                $contactform->save or $contactform->errstr;
                $app->run_callbacks( 'cms_post_import.contactform', $app, $contactform, $csv_obj );
                $do = 1;
            }
        }
        $i++;
    }
    close $fh;
    if ( $do ) {
        $app->run_callbacks( 'cms_finish_import.contactform', $app, $upload );
    }
    remove_item( $workdir );
    if ( $do ) {
        $app->add_return_arg( imported => 1 );
    } else {
        $app->add_return_arg( not_imported => 1 );
    }
    $app->call_return;
}

sub _download_contactform_csv {
    my $app = shift;
    my $plugin = MT->component( 'ContactForm' );
    my $blog = $app->blog;
    if ( defined $blog ) {
        return $app->return_to_dashboard();
    }
    if (! _formelement_permission() ) {
        return $app->trans_error( 'Permission denied.' );
    }
    $app->validate_magic or return $app->trans_error( 'Permission denied.' );
    my $csv = csv_new()
        or return $app->error( $plugin->translate( 'Neither Text::CSV_XS nor Text::CSV is available.' ) );
    $app->{ no_print_body } = 1;
    my $ts = current_ts();
    my $model = $app->model( 'contactform' );
    $app->set_header( 'Content-Disposition' => "attachment; filename=csv_$ts.csv" );
    $app->set_header( 'Pragma' => '' );
    $app->send_http_header( 'text/csv' );
    my $column_names = $model->column_names;
    require CustomFields::Field;
    my @fields = CustomFields::Field->load( { obj_type => 'contactform' } );
    for my $field ( @fields ) {
        push ( @$column_names, 'field.' . $field->basename );
    }
    if ( $csv->combine( @$column_names ) ) {
        my $string = $csv->string;
        $string = encode_utf8_string_to_cp932_octets( $string );
        print $string;
    }
    my $iter = $model->load_iter();
    while ( my $item = $iter->() ) {
        my @values;
        for my $c ( @$column_names ) {
            my $value = $item->$c;
            if ( $value && ( $c =~ /_on$/ ) && ( $value =~ /^[0-9]{14}$/ ) ) {
                $value = "\t$value";
            }
            push ( @values, $value );
        }
        if ( $csv->combine( @values ) ) {
            my $string = utf8_on( $csv->string );
            $string = encode_utf8_string_to_cp932_octets( $string );
            print "\n$string";
        }
    }
}

sub _edit_author {
    my ( $cb, $app, $param, $tmpl ) = @_;
    if ( my $id = $app->param( 'id' ) ) {
        my $author = MT->model( 'author' )->load( $id );
        my $loaded_permissions = $param->{ loaded_permissions };
        my @new_perms;
        for my $perm ( @$loaded_permissions ) {
            if ( $perm->{ id } eq 'can_manage_formelement' ) {
                if ( $author->is_superuser ) {
                    $perm->{ can_do } = 1;
                } else {
                    $perm->{ can_do } = $author->can_manage_formelement;
                }
            }
            push ( @new_perms, $perm );
        }
        $param->{ loaded_permissions } = \@new_perms;
    }
}

sub _edit_feedback {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $plugin = MT->component( 'ContactForm' );
    my $ctx    = $tmpl->context;
    my $type   = $app->param( '_type' );
    my $class  = $app->model( $type );
    my $blog   = $app->blog;
    # if (! $blog ) {
    #     return;
    #     # $app->return_to_dashboard();
    # }
    # if (! _feedback_permission( $app->blog ) ) {
    #     # $app->return_to_dashboard( permission => 1 );
    # }
    my $id = $app->param( 'id' );
    if ( $id ) {
        my $obj = $class->load( $id );
        if (! defined $obj ) {
            return;
            # $app->return_to_dashboard( permission => 1 );
        }
        $ctx->stash( 'feedback', $obj );
        # if ( $obj->blog_id != $blog->id ) {
        #     $app->return_to_dashboard( permission => 1 );
        # }
        # if (! _feedback_permission( $obj->blog ) ) {
        #     $app->return_to_dashboard( permission => 1 );
        # }
        my $obj_author = $obj->author( 'created_by' );
        $param->{ obj_author } = $obj_author->nickname;
        my $columns = $obj->column_names;
        my $form = $obj->form;
        if ( $form ) {
            $param->{ form_name } = $form->name;
            $ctx->stash( 'contactform', $form );
        }
        my $types = $form->_types;
        for my $column ( @$columns ) {
            if ( $column =~ /_on$/ ) {
                my $column_ts = $obj->$column;
                $param->{ $column . '_date' } = format_ts( '%Y-%m-%d', $column_ts );
                $param->{ $column . '_time' } = format_ts( '%H:%M:%S', $column_ts );
            }
        }
        my @get_table = $obj->get_table;
        my @data_loop;
        my $field_count = 1;
        for my $data ( @get_table ) {
            my $label = @$data[0];
            my $val = @$data[1];
            my $basename = @$data[2];
            my $field_type = @$data[3];
            $val = format_LF( $val );
            my ( $is_date, $multiline, $ts_date, $ts_time );
            if ( $field_type eq 'textarea' ) {
                $multiline = 1;
            }
            my $field_param = { field_label => @$data[0],
                                field_count => $field_count,
                                field_basename => $basename,
                                field_type => $field_type,
                                field_data => $val,
                               };
            if ( my $cms_param = __get_registry( $field_type, 'cms_param' ) ) {
                $cms_param = MT->handler_to_coderef( $cms_param );
                if ( $cms_param ) {
                    $cms_param->( $app, $obj, $field_param );
                }
            }
            push @data_loop, $field_param;
            $field_count++;
        }
        $param->{ data_loop } = \@data_loop;
        my $next = $obj->_nextprev( 'next' );
        if ( $next ) {
            $param->{ next_contactform_id } = $next->id;
        }
        my $previous = $obj->_nextprev( 'previous' );
        if ( $previous ) {
            $param->{ previous_contactform_id } = $previous->id;
        }
    } else {
        my $columns = $class->column_names;
        my @tl = offset_time_list( time, $app->blog );
        my $ts_date = sprintf '%04d-%02d-%02d', $tl[5]+1900, $tl[4]+1, $tl[3];
        my $ts_time = sprintf '%02d:%02d:%02d', @tl[2, 1, 0];
        for my $column ( @$columns ) {
            if ( $column =~ /_on$/ ) {
                $param->{ $column . '_date' } = $ts_date;
                $param->{ $column . '_time' } = $ts_time;
            }
        }
    }
    $param->{ saved } = $app->param( 'saved' );
    $param->{ search_label } = $plugin->translate( 'Feedback' );
    $param->{ screen_group } = 'contactform';
    $param->{ return_args } = _force_view_mode_return_args( $app );
    return 1;
}

sub _edit_contactform {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $plugin = MT->component( 'ContactForm' );
    my $type   = $app->param( '_type' );
    my $class  = $app->model( $type );
    my $blog   = $app->blog;
    if ( $app->blog ) {
        $app->return_to_dashboard();
    }
    if (! _formelement_permission() ) {
        $app->return_to_dashboard( permission => 1 );
    }
    __contactform_objects_param( \$param );
    my $id = $app->param( 'id' );
    if ( $id ) {
        my $obj = $class->load( $id );
        if (! defined $obj ) {
            $app->return_to_dashboard( permission => 1 );
        }
        my $columns = $obj->column_names;
        for my $column ( @$columns ) {
            if ( $column =~ /_on$/ ) {
                my $column_ts = $obj->$column;
                $param->{ $column . '_date' } = format_ts( '%Y-%m-%d', $column_ts );
                $param->{ $column . '_time' } = format_ts( '%H:%M:%S', $column_ts );
            }
        }
        my $next = $obj->_nextprev( 'next' );
        if ( $next ) {
            $param->{ next_contactform_id } = $next->id;
        }
        my $previous = $obj->_nextprev( 'previous' );
        if ( $previous ) {
            $param->{ previous_contactform_id } = $previous->id;
        }
    } else {
        my $columns = $class->column_names;
        my @tl = offset_time_list( time, $app->blog );
        my $ts_date = sprintf '%04d-%02d-%02d', $tl[5]+1900, $tl[4]+1, $tl[3];
        my $ts_time = sprintf '%02d:%02d:%02d', @tl[2, 1, 0];
        for my $column ( @$columns ) {
            if ( $column =~ /_on$/ ) {
                $param->{ $column . '_date' } = $ts_date;
                $param->{ $column . '_time' } = $ts_time;
            }
        }
    }
    $param->{ lang } = $app->user->preferred_language;
    $param->{ saved } = $app->param( 'saved' );
    $param->{ search_label } = $plugin->translate( 'Form' );
    $param->{ screen_group } = 'contactform';
    $param->{ return_args } = _force_view_mode_return_args( $app );
    $param->{ search_label } = $plugin->translate( 'Form Element' );
    # Add <mtapp:fields> after basename
    require CustomFields::App::CMS;
    CustomFields::App::CMS::add_app_fields( $cb, $app, $param, $tmpl, 'basename', 'insertAfter' );
}

sub __contactform_objects_param {
    my $param = shift;
    my $contactform_objects = MT->registry( 'contactform_objects' );
    my $contactforms_order;
    foreach my $key ( keys %$contactform_objects ) {
        my $contactform_object = $contactform_objects->{ $key };
        $contactforms_order->{ $key } = $contactform_object->{ order };
    }
    my @keys; my $labels;
    foreach my $key ( sort { $contactforms_order->{ $a } <=> $contactforms_order->{ $b } } keys %$contactforms_order ) {
        push ( @keys, $key );
        my $component = $contactform_objects->{ $key }->{ plugin };
        my $label = $contactform_objects->{ $key }->{ name };
        if ( $component ) {
            $component = MT->component( $component->{ id } );
            if ( $component ) {
                $label = $component->translate( $label );
            }
        }
        $labels->{ $key } = $label;
    }
    my @contactforms_loop;
    for my $key ( @keys ) {
        my $contactform_object = $contactform_objects->{ $key };
        push @contactforms_loop, { field_key => $key,
                                   field_label => $labels->{ $key } };
    }
    $$param->{ contactforms_loop } = \@contactforms_loop;
}

sub _edit_contactform_out {
    my ( $cb, $app, $tmpl, $param ) = @_;
    $$tmpl =~ s/(<div id="customfield_[^"]+-field" class="field +)(?:required +)*(field-)top(?=-label *">)/$1$2left/gi;
}

sub _approve_feedbacks {
    __status_change( 'approved', 2 );
}

sub _unapprove_feedbacks {
    __status_change( 'unapproved', 1 );
}

sub _addflag2_feedbacks {
    __status_change( 'flagged', 3 );
}

sub _download_feedbacks {
    my $app = shift;
    my $plugin = MT->component( 'ContactForm' );
    my $blog = $app->blog;
    if (! defined $blog && ! $app->validate_magic() ) {
        $app->return_to_dashboard();
    }
    if (! _feedback_permission( $blog ) ) {
        return $app->trans_error( 'Permission denied.' );
    }
    $app->validate_magic or return $app->trans_error( 'Permission denied.' );
    my $ts = current_ts();
    my $csv = csv_new()
        or return $app->error( $plugin->translate( 'Neither Text::CSV_XS nor Text::CSV is available.' ) );
    $app->{ no_print_body } = 1;
    $app->set_header( 'Content-Disposition' => "attachment; filename=csv_$ts.csv" );
    $app->set_header( 'Pragma' => '' );
    $app->send_http_header( 'text/csv' );
    if ( $app->param( 'all_selected' ) ) {
        $app->setup_filtered_ids;
    }
    my @ids = $app->param( 'id' );
    my $do;
    require ContactForm::Feedback;
    my @feedbacks = ContactForm::Feedback->load( { id => \@ids } );
    my $keys;
    # my $res;
    for my $feedback ( @feedbacks ) {
        if (! _feedback_permission( $feedback->blog ) ) {
            return $app->trans_error( 'Permission denied.' );
        }
        my @get_keys = $feedback->get_keys;
        unshift( @get_keys, $plugin->translate( 'Post On' ) );
        my $new_keys = join( ',', @get_keys );
        my $new_line;
        if (! $keys ) {
            $keys = $new_keys;
            $new_line = 1;
        } else {
            if ( $keys ne $new_keys ) {
                $keys = $new_keys;
                $new_line = 1;
            }
        }
        if ( $new_line ) {
            if ( $csv->combine( @get_keys ) ) {
                my $string = $csv->string;
                $string = encode_utf8_string_to_cp932_octets( utf8_on( $string ) );
                print "$string\n";
                # $res .= $string;
            }
        }
        my @get_data = $feedback->get_download_data;
        unshift( @get_data, "\t" . $feedback->created_on() );
        if ( $csv->combine( @get_data ) ) {
            my $string = $csv->string;
            $string = encode_utf8_string_to_cp932_octets( utf8_on( $string ) );
            print "$string\n";
            # $res .= $string;
        }
    }
    # $res;
}

sub _status_contactformgroup {
    my $app = shift;
    my $plugin = MT->component( 'ContactForm' );
    if ( $app->param( 'all_selected' ) ) {
        $app->setup_filtered_ids;
    }
    my @ids = $app->param( 'id' );
    my $do;
    my $status = $app->param( 'action_name' );
    if ( $status =~ /[^1-5]/ ) { # FIXME?: /^[^1-5]$/
        return $app->errtrans( 'Invalid request.' )
    }
    require ContactForm::ContactFormGroup;
    for my $id ( @ids ) {
        my $form = ContactForm::ContactFormGroup->load( $id )
            or return $app->errtrans( 'Invalid request.' );
        if (! _contactform_permission( $form->blog ) ) {
            return $app->trans_error( 'Permission denied.' );
        }
        if ( $form->status != $status ) {
            my $original = $form->clone_all();
            my $before = $plugin->translate( $original->status_text );
            $form->status( $status );
            $form->save or die $form->errstr;
            if ( $status == 1 ) {
                $app->run_callbacks( 'post_unpublish.contactformgroup', $app, $form, $original );
            } elsif ( $status == 2 ) {
                $app->run_callbacks( 'post_publish.contactformgroup', $app, $form, $original );
            } elsif ( $status == 3 ) {
                $app->run_callbacks( 'post_review.contactformgroup', $app, $form, $original );
            } elsif ( $status == 4 ) {
                $app->run_callbacks( 'post_future.contactformgroup', $app, $form, $original );
            } elsif ( $status == 5 ) {
                $app->run_callbacks( 'post_close.contactformgroup', $app, $form, $original );
            }
            my $after = $plugin->translate( $form->status_text );
            $app->log( {
                message => $plugin->translate( "Form '[_1]'(ID:[_2]) edited and its status changed from [_3] to [_4] by user '[_5]'",
                    $form->name, $form->id, $before, $after, $app->user->name ),
                blog_id => $form->blog_id,
                author_id => $app->user->id,
                class => 'contactform',
                level => MT::Log::INFO(),
            } );
            $do = 1;
        }
    }
    if ( $do ) {
        $app->add_return_arg( 'status_contactformgroup' => 1, status => $status );
    } else {
        $app->add_return_arg( 'not_status_contactformgroup' => 1, status => $status );
    }
    $app->call_return;
}

sub __status_change {
    my ( $param, $status ) = @_;
    my $app = MT::instance();
    $app->validate_magic or return $app->trans_error( 'Permission denied.' );
    my $plugin = MT->component( 'ContactForm' );
    if ( $app->param( 'all_selected' ) ) {
        $app->setup_filtered_ids;
    }
    my @ids = $app->param( 'id' );
    my $do;
    require ContactForm::Feedback;
    for my $id ( @ids ) {
        my $feedback = ContactForm::Feedback->load( $id )
            or return $app->errtrans( 'Invalid request.' );
        if (! _feedback_permission( $feedback->blog ) ) {
            return $app->trans_error( 'Permission denied.' );
        }
        if ( $feedback->status != $status ) {
            my $original = $feedback->clone_all();
            my $before = $plugin->translate( $original->status_text );
            $feedback->status( $status );
            $feedback->save or die $feedback->errstr;
            if ( $status == ContactForm::Feedback::HOLD() ) {
                $app->run_callbacks( 'post_unpublish.feedback', $app, $feedback, $original );
            } elsif ( $status == ContactForm::Feedback::RELEASE() ) {
                $app->run_callbacks( 'post_publish.feedback', $app, $feedback, $original );
            } elsif ( $status == ContactForm::Feedback::FLAGGED() ) {
                $app->run_callbacks( 'post_flagged.feedback', $app, $feedback, $original );
            }
            my $after = $plugin->translate( $feedback->status_text );
            $app->log( {
                message => $plugin->translate( "Feedback (ID:[_1]) edited and its status changed from [_2] to [_3] by user '[_4]'", $feedback->id, $before, $after, $app->user->name ),
                blog_id => $feedback->blog_id,
                author_id => $app->user->id,
                class => 'contactform',
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

sub _edit_contactformgroup {
    my ( $cb, $app, $param, $tmpl ) = @_;
    require ContactForm::ContactFormGroup;
    require ContactForm::ContactFormOrder;
    my $plugin = MT->component( 'ContactForm' );
    my $type   = $app->param( '_type' );
    my $class  = $app->model( $type );
    my $blog   = $app->blog
        or $app->return_to_dashboard();
    if (! _contactform_permission( $blog ) ) {
        $app->return_to_dashboard( permission => 1 );
    }
    my $id = $app->param( 'id' );
    my $obj;
    if ( $id ) {
        $obj = $class->load( $id );
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
    if (! defined $app->blog ) {
        $app->return_to_dashboard( redirect => 1 );
    } else {
        if (! _contactform_permission( $app->blog ) ) {
            $app->return_to_dashboard( redirect => 1 );
        }
        if ( $app->blog->class eq 'website' ) {
            push @weblog_loop, {
                    weblog_id => $app->blog->id,
                    weblog_name => $app->blog->name, };
            $website_view = 1;
            $blogs{ $app->blog->id } = $app->blog;
            push ( @blog_ids, $app->blog->id );
            my $all_blogs = $app->blog->blogs;
            for my $blog ( @$all_blogs ) {
                if ( _contactform_permission( $blog ) ) {
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
            $blogs{ $app->blog->id } = $app->blog;
        }
        # if (! $blog_view ) {
        #     $terms{ 'blog_id' } = \@blog_ids;
        # } else {
        #     $terms{ 'blog_id' } = $app->blog->id;
        # }
        my @contactforms = MT->model( 'contactform' )->load( \%terms, \%args );
        my @item_loop;
        for my $contactform ( @contactforms ) {
            my $add_item = 1;
            if ( $id ) {
                my $item = MT->model( 'contactformorder' )->load( { group_id => $id, contactform_id => $contactform->id } );
                $add_item = 0 if defined $item;
            }
            if ( $add_item ) {
                push @item_loop, {
                        id => $contactform->id,
                        label => $contactform->label,
                        item_name => $contactform->name };
            }
        }
        $param->{ item_loop } = \@item_loop;
        if ( $id ) {
            my $args = { 'join' => [ 'ContactForm::ContactFormOrder', 'contactform_id',
                       { group_id => $id, },
                       { sort => 'order',
                         direction => 'ascend',
                       } ] };
            my @contactforms = MT->model( 'contactform' )->load( \%terms, $args );
            my @group_loop;
            for my $contactform ( @contactforms ) {
                push @group_loop, {
                        id => $contactform->id,
                        label => $contactform->label,
                        item_name => $contactform->name };
            }
            $param->{ group_loop } = \@group_loop;
        }
    }
    my @groups = ContactForm::ContactFormGroup->load();
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
    require MT::Template;
    push ( @blog_ids, 0 );
    my @template = MT::Template->load( { blog_id => \@blog_ids, type => [ 'custom', 'individual', 'page', 'archive', 'email' ] } );
    my @tmpl_loop;
    for my $template( @template ) {
        my $weblog_name;
        if ( $template->blog_id ) {
            $weblog_name = $blogs{ $template->blog_id };
            if ( $weblog_name ) {
                $weblog_name = $weblog_name->name;
            }
        }
        push ( @tmpl_loop, { tmpl_name => $template->name,
                             weblog_name => $weblog_name,
                             tmpl_type => $template->type,
                             tmpl_id => $template->id, } );
    }
    if (! $obj ) {
        my @tl = offset_time_list( time, $app->blog );
        my $ts_date = sprintf '%04d-%02d-%02d', $tl[5]+1900, $tl[4]+1, $tl[3];
        my $ts_time = sprintf '%02d:%02d:%02d', @tl[2, 1, 0];
        my $current_ts = sprintf '%04d%02d%02d', $tl[5]+1900, $tl[4]+1, $tl[3];
        $current_ts .= '000000';
        $param->{ publishing_on_date } = $ts_date;
        $param->{ publishing_on_time } = $ts_time;
        my $plugin_config = MT->component( 'ContactFormConfig' );
        my $default_period = $plugin_config->get_config_value( 'default_period' ) || 30;
        $current_ts = _end_date( $app->blog, $current_ts, $default_period );
        $ts_date = substr( $current_ts, 0, 4 ) . '-' . substr( $current_ts, 4, 2 ) . '-' . substr( $current_ts, 6, 2 );
        $param->{ period_on_date } = $ts_date;
        $param->{ period_on_time } = $ts_time;
        $param->{ status } = $app->config( 'DefaultFormStatus' ) || 2;
    } else {
        my $publishing_on = $obj->publishing_on;
        my $period_on = $obj->period_on;
        $param->{ publishing_on_date } = format_ts( '%Y-%m-%d', $publishing_on );
        $param->{ publishing_on_time } = format_ts( '%H:%M:%S', $publishing_on );
        $param->{ period_on_date } = format_ts( '%Y-%m-%d', $period_on );
        $param->{ period_on_time } = format_ts( '%H:%M:%S', $period_on );
        my $next = $obj->_nextprev( 'next' );
        if ( $next ) {
            $param->{ next_contactform_id } = $next->id;
        }
        my $previous = $obj->_nextprev( 'previous' );
        if ( $previous ) {
            $param->{ previous_contactform_id } = $previous->id;
        }
    }
    $param->{ can_edit }     = _formelement_permission();
    $param->{ tmpl_loop }    = \@tmpl_loop;
    $param->{ saved }        = $app->param( 'saved' );
    $param->{ search_label } = $plugin->translate( 'Form' );
    $param->{ search_type }  = 'contactform';
    $param->{ screen_group } = 'contactform';
    $param->{ filter }       = $app->param( 'filter' );
    $param->{ return_args }  = _force_view_mode_return_args( $app );
    # Add <mtapp:fields> after requires_login
    require CustomFields::App::CMS;
    CustomFields::App::CMS::add_app_fields( $cb, $app, $param, $tmpl, 'requires_login', 'insertAfter' );
}

sub _load_formelement_admin {
    my $author_class = MT->model( 'author' );
    require MT::Author;
    my %terms1 = ( blog_id => 0, permissions => { like => "\%'administer\%" } );
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
    my %terms2 = ( blog_id => 0, permissions => { like => "\%'manage_formelement'\%" } );
    my @contactform_admin = $author_class->load(
        { type => MT::Author::AUTHOR(),
          id => { not => \@author_id } },
        { join => [ 'MT::Permission', 'author_id',
            \%terms2,
            { unique => 1 } ],
        }
    );
    push ( @admin, @contactform_admin );
    return @admin;
}

sub _load_feedback_admin {
    my @blog_id = @_;
    push ( @blog_id, 0 );
    my $author_class = MT->model( 'author' );
    require MT::Author;
    my %terms1 = ( blog_id => \@blog_id, permissions => { like => "\%'administer\%" } );
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
    my %terms2 = ( blog_id => \@blog_id, permissions => { like => "\%'manage_feedback'\%" } );
    my @contactform_admin = $author_class->load(
        { type => MT::Author::AUTHOR(),
          id => { not => \@author_id } },
        { join => [ 'MT::Permission', 'author_id',
            \%terms2,
            { unique => 1 } ],
        }
    );
    push ( @admin, @contactform_admin );
    return @admin;
}

sub _load_contactform_admin {
    my @blog_id = @_;
    push ( @blog_id, 0 );
    my $author_class = MT->model( 'author' );
    require MT::Author;
    my %terms1 = ( blog_id => \@blog_id, permissions => { like => "\%'administer\%" } );
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
    my %terms2 = ( blog_id => \@blog_id, permissions => { like => "\%'manage_contactform'\%" } );
    my @contactform_admin = $author_class->load(
        { type => MT::Author::AUTHOR(),
          id => { not => \@author_id } },
        { join => [ 'MT::Permission', 'author_id',
            \%terms2,
            { unique => 1 } ],
        }
    );
    push ( @admin, @contactform_admin );
    return @admin;
}

sub _force_view_mode_return_args {
    my $app = shift;
    my $return = $app->make_return_args;
    $return =~ s/edit/view/;
    return $return;
}

sub _validate_checkbox {
    my ( $app, $contactform, $value, $params ) = @_;
    my $option = $contactform->options;
    $value = @$value[0];
    if ( ( $value eq '1' ) || ( $value eq $option ) ) {
        return 1;
    }
    return 0;
}

sub _validate_select_radio {
    my ( $app, $contactform, $value, $params ) = @_;
    my $option = $contactform->options;
    my @options = split( /,/, $option );
    $value = @$value[0];
    if (! grep( /^$value$/, @options ) ) {
        return 0;
    }
    return 1;
}

sub _validate_multi {
    my ( $app, $contactform, $value, $params ) = @_;
    my $option = $contactform->options;
    my @options = split( /,/, $option );
    if ( ( ref $value ) eq 'ARRAY' ) {
        for my $val ( @$value ) {
            if (! grep( /^$val$/, @options ) ) {
                return 0;
            }
        }
    } else {
        my @vals = split( /,/, $value );
        for my $val ( @vals ) {
            if (! grep( /^$val$/, @options ) ) {
                return 0;
            }
        }
    }
    return 1;
}

sub _validate_date_and_time {
    my ( $app, $contactform, $value, $params, $opt ) = @_;
    # 2011-04-09 00:00:00
    if ( ( ref $value ) eq 'ARRAY' ) {
        $value = @$value[ 0 ] . @$value[ 1 ];
    }
    my $date;
    if ( $value =~ /^[0-9]{14}$/ ) {
        $date = $value;
    } elsif ( $value =~ /\s/ ) {
        my ( $day, $time ) = split( /\s/, $value );
        if ( $day && $day =~ m!([-:/])! ) {
            my $sep = quotemeta( $1 );
            my @items = split( /$sep/, $day );
            if ( scalar ( @items ) == 3 ) {
                my $yyyy = $items[0];
                my $mm = $items[1];
                $mm = sprintf ( '%02d', $mm ) if $mm;
                my $dd = $items[2];
                $dd = sprintf ( '%02d', $dd ) if $dd;
                $day = $yyyy . $mm . $dd;
            }
        }
        if ( $time && $time =~ m!([-:/])! ) {
            my $sep = quotemeta( $1 );
            my @items = split( /$sep/, $time );
            if ( scalar ( @items ) == 3 ) {
                my $hh = $items[0];
                $hh = sprintf ( '%02d', $hh ) if $hh;
                my $mm = $items[1];
                $mm = sprintf ( '%02d', $mm ) if $mm;
                my $ss = $items[2];
                $ss = sprintf ( '%02d', $ss ) if $ss;
                $time = $hh . $mm . $ss;
            }
        }
        if (! $time ) {
            $date = $day if $day;
        } else {
            $date = $day . $time;
        }
    } else {
        $date = $value;
        $date =~ s/\W+//g;
    }
    if ( $date =~ /^[0-9]{8}$/ ) {
        $date .= '000000';
    }
    if ( $opt == 1 ) {
        if ( valid_ts( $date ) ) {
            return $date;
        }
        return $value;
    }
    if (! valid_ts( $date ) ) {
        return 0;
    }
    return 1;
}

sub _validate_date {
    my ( $app, $contactform, $value, $params, $opt ) = @_;
    my $date = $value;
    if ( ( ref $date ) eq 'ARRAY' ) {
        $date = @$date[0];
    }
    if ( $date =~ m!([-:/])! ) {
        my $sep = quotemeta( $1 );
        my @date = split( /$sep/, $date );
        if ( scalar ( @date ) == 3 ) {
            my $yyyy = $date[0];
            my $mm = $date[1];
            $mm = sprintf ( '%02d', $mm ) if $mm;
            my $dd = $date[2];
            $dd = sprintf ( '%02d', $dd ) if $dd;
            $date = $yyyy . $mm . $dd;
        }
    } else {
        $date = $value;
        if ( ( ref $date ) eq 'ARRAY' ) {
            $date = @$date[0];
        }
        $date =~ s/\W+//g;
    }
    if ( $date =~ /^[0-9]{8}$/ ) {
        $date .= '000000';
    }
    if ( $opt == 1 ) {
        if ( valid_ts( $date ) ) {
            return $date;
        }
        return $value;
    }
    if (! valid_ts( $date ) ) {
        return 0;
    }
    return 1;
}

sub _validate_url {
    my ( $app, $contactform, $value, $params ) = @_;
    return valid_url( $value );
}

sub _validate_email {
    my ( $app, $contactform, $value, $params ) = @_;
    return valid_email( $value );
}

sub _validate_tel {
    my ( $app, $contactform, $value, $params ) = @_;
    return valid_phone_number( $value );
}

sub _validate_zip {
    my ( $app, $contactform, $value, $params ) = @_;
    return valid_postal_code( $value );
}

sub _format_date {
    return _validate_date( @_, 1 );
}

sub _format_date_and_time {
    return _validate_date_and_time( @_, 1 );
}

sub _cms_param_date {
    my ( $app, $obj, $param ) = @_;
    my $field_data = $param->{ field_data };
    $param->{ is_date } = 1;
    $param->{ ts_date } = format_ts( '%Y-%m-%d', $field_data );
    $param->{ ts_time } = format_ts( '%H:%M:%S', $field_data );
}

sub _cms_tmpl_default {
    q{
        <input type="text" name="field_data-<mt:var name="field_count" escape="html">" id="field_data-<mt:var name="field_count" escape="html">" class="text full-width" value="<mt:var name="field_data" escape="html">" />
    };
}

sub _cms_tmpl_date {
    q{
        <input type="text" id="field_data-<mt:var name="field_count" escape="html">" name="field_data-date-<mt:var name="field_count" escape="html">" style="width:7em;" class="text start-date text-date" value="<mt:var name="ts_date" escape="html">" >
        <input type="hidden" name="field_data-time-<mt:var name="field_count" escape="html">" value="<mt:var name="ts_time" escape="html">">
        <input type="hidden" name="field_data-<mt:var name="field_count" escape="html">" value="contact-form-type-date" />
    };
}

sub _cms_tmpl_date_time {
    q{
        <input type="text" id="field_data-<mt:var name="field_count" escape="html">" name="field_data-date-<mt:var name="field_count" escape="html">" style="width:7em;" class="text start-date text-date" value="<mt:var name="ts_date" escape="html">" >
        <input type="text" name="field_data-time-<mt:var name="field_count" escape="html">" style="width:5.5em;" class="text start-time" value="<mt:var name="ts_time" escape="html">">
        <input type="hidden" name="field_data-<mt:var name="field_count" escape="html">" value="contact-form-type-date" />
    };
}

sub _cms_tmpl_textarea {
    q{
        <textarea name="field_data-<mt:var name="field_count" escape="html">" id="hidden_field-<mt:var name="field_count" escape="html">" class="text full-width"><mt:var name="field_data" escape="html"></textarea>
    };
}

sub __get_registry {
    my ( $type, $registry ) = @_;
    my $contactform_objects = MT->registry( 'contactform_objects' );
    my $contactform_object = $contactform_objects->{ $type };
    if ( $contactform_object ) {
        my $registry = $contactform_object->{ $registry };
        return $registry;
    }
}

sub _scheduled_task {
    my $plugin = MT->component( 'ContactForm' );
    my $app = MT->instance();
    require ContactForm::ContactFormGroup;
    require MT::Log;
    require MT::Blog;
    my @blogs = MT::Blog->load( { class => [ 'website', 'blog' ] } );
    for my $blog ( @blogs ) {
        my $ts = current_ts( $blog );
        my @contactforms = ContactForm::ContactFormGroup->load( { blog_id => $blog->id,
                                                                  status => 4, },
                                                                { sort      => 'publishing_on',
                                                                  start_val => $ts - 1,
                                                                  direction => 'descend', } );
        for my $contactform ( @contactforms ) {
            my $original = $contactform->clone_all();
            $contactform->status( 2 );
            $contactform->save or die $contactform->errstr;
            $app->log( {
                message => $plugin->translate( "Form '[_1]'(ID:[_2])'s status changed from [_3] to [_4] by Task.",
                                $contactform->name, $contactform->id, MT->translate( 'Future' ), MT->translate( 'Published' ) ),
                blog_id => $contactform->blog_id,
                class => 'contactform',
                level => MT::Log::INFO(),
            } );
            $app->run_callbacks( 'post_publish.contactformgroup', $app, $contactform, $original );
        }
        @contactforms = ContactForm::ContactFormGroup->load( { blog_id => $blog->id,
                                                               status => 2, set_period => 1 },
                                                             { sort      => 'period_on',
                                                               start_val => $ts - 1,
                                                               direction => 'descend', } );
        for my $contactform ( @contactforms ) {
            my $original = $contactform->clone_all();
            $contactform->status( 5 );
            $app->run_callbacks( 'post_close.contactformgroup', $app, $contactform, $original );
            $app->log( {
                message => $plugin->translate( "Form '[_1]'(ID:[_2])'s status changed from [_3] to [_4] by Task.",
                                $contactform->name, $contactform->id, MT->translate( 'Published' ), $plugin->translate( 'Ended' ) ),
                blog_id => $contactform->blog_id,
                class => 'contactform',
                level => MT::Log::INFO(),
            } );
            $contactform->save or die $contactform->errstr;
        }
        @contactforms = ContactForm::ContactFormGroup->load( { blog_id => $blog->id,
                                                               status => 2, set_limit => 1 } );
        for my $contactform ( @contactforms ) {
            my $post_limit = $contactform->post_limit;
            $post_limit = $post_limit + 0;
            my $feedback_count = $contactform->feedback_count;
            $feedback_count++;
            if ( $post_limit < $feedback_count ) {
                my $original = $contactform->clone_all();
                $contactform->status( 5 );
                $app->run_callbacks( 'post_close.contactformgroup', $app, $contactform, $original );
                $contactform->save or die $contactform->errstr;
                $app->log( {
                    message => $plugin->translate( "Form '[_1]'(ID:[_2])'s status changed from [_3] to [_4] by Task.",
                                    $contactform->name, $contactform->id, MT->translate( 'Published' ), $plugin->translate( 'Ended' ) ),
                    blog_id => $contactform->blog_id,
                    class => 'contactform',
                    level => MT::Log::INFO(),
                } );
            }
        }
    }
    return 1;
}

sub _module_mtml {
    require File::Spec;
    my $plugin = MT->component( 'ContactForm' );
    my $plugin_template_path = plugin_template_path( $plugin );
    my $module = File::Spec->catfile( $plugin_template_path, 'module_mtml.tmpl' );
    if ( -f $module ) {
        return read_from_file( $module );
    }
}

sub _footer_source {
    my ( $cb, $app, $tmpl ) = @_;
    my $id = MT->component(__PACKAGE__ =~ /^([^:]+)/)->id;
    $$tmpl =~ s{(<__trans phrase="http://www\.sixapart\.com/movabletype/">)}
               {<mt:if name="id" eq="$id"><__trans phrase="http://alfasado.net/"><mt:else>$1</mt:if>};
}

sub _end_date {
    my ( $blog, $ts, $day ) = @_;
    $ts = ts2epoch( $blog, $ts );
    $ts += 86400 * $day;
    return epoch2ts( $blog, $ts );
}

sub _cb_restore {
    my ( $cb, $objects, $deferred, $errors, $callback ) = @_;

    my %restored_objects;
    for my $key ( keys %$objects ) {
        if ( $key =~ /^ContactForm::ContactFormGroup#(\d+)$/ ) {
            $restored_objects{ $1 } = $objects->{ $key };
        }
    }

    require CustomFields::Field;

    my %class_fields;
    $callback->(
        MT->translate(
            "Restoring contactform associations found in custom fields ...",
        ),
        'cf-restore-object-contactform'
    );

    my $r = MT::Request->instance();
    for my $restored_object ( values %restored_objects ) {
        my $iter = CustomFields::Field->load_iter( { blog_id  => [ $restored_object->blog_id, 0 ],
                                                     type => [ 'contactform' ],
                                                   }
                                                 );
        while ( my $field = $iter->() ) {
            my $class = MT->model( $field->obj_type )
                or next;
            my @related_objects = $class->load( { blog_id => $restored_object->blog_id } );
            my $column_name = 'field.' . $field->basename;
            for my $related_object ( @related_objects ) {
                my $cache_key = $class . ':' . $related_object->id . ':' . $column_name;
                next if $r->cache( $cache_key );
                my $value = $related_object->$column_name;
                my $restored_value;
                if ( $field->type eq 'contactform' ) {
                    my $restored = $objects->{ 'ContactForm::ContactFormGroup#' . $value };
                    if ( $restored ) {
                        $restored_value = $restored->id;
                    }
                }
                $related_object->$column_name( $restored_value );
                $related_object->save or die $related_object->errstr;
                $r->cache( $cache_key, 1 );
            }
        }
    }
    $callback->( MT->translate( "Done." ) . "\n" );
}

sub _task_adjust_order {
    my $updated = 0;
    my @orders = MT->model( 'contactformorder' )->load();
    for my $order ( @orders ) {
        my $remove = 0;
        if ( my $group_id = $order->group_id ) {
            my $group = MT->model( 'contactformgroup' )->load( { id => $group_id } );
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
