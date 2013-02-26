package MT::App::ContactForm;

use strict;
use ContactForm::Util qw( build_tmpl read_from_file multibyte_length normalize
                          plugin_template_path send_mail utf8_on current_ts ceil );

use base qw( MT::App MT::App::CMS );
use MT;
use MT::App::CMS;
use MT::CMS::Common;
use MT::Log;
use MT::Session;

@MT::App::ContactForm = qw( MT::App );

sub init_request {
    my $app = shift;
    $app->SUPER::init_request( @_ );
    if ( my $id = $app->param( 'id' ) ) {
        require ContactForm::ContactFormGroup;
        my $group = ContactForm::ContactFormGroup->load( $id );
        if ( $group && $group->requires_login ) {
            $app->{ requires_login } = 1;
        }
    }
    $app;
}

sub _view {
    # ?__mode=view&blog_id={blog_id}&id={contactformgroup_id}&object_id={entry_id}&model=entry
    my $app = shift;
    my $component = MT->component( 'ContactForm' );
    my $id = $app->param( 'id' );
    require ContactForm::ContactFormGroup;
    my $group = ContactForm::ContactFormGroup->load( $id );
    return '' unless $group;
    my $blog = $app->blog;
    return '' unless $blog;
    my $vars;
    my $object_id = $app->param( 'object_id' );
    my $model = $app->param( 'model' );
    my $entry; my $category;
    require MT::Template::Context;
    my $ctx = MT::Template::Context->new;
    if ( $model && $object_id ) {
        if ( ( $model eq 'entry' ) || ( $model eq 'page' ) ) {
            $entry = MT->model( $model )->load( $object_id );
            return '' unless $entry;
            if ( $model eq 'entry' ) {
                $ctx->{ current_archive_type } = 'Individual';
                $ctx->{ archive_type } = 'Individual';
            } else {
                $ctx->{ current_archive_type } = 'Page';
                $ctx->{ archive_type } = 'Page';
            }
        } elsif ( ( $model eq 'category' ) || ( $model eq 'folder' ) ) {
            $category = MT->model( $model )->load( $object_id );
            return '' unless $category;
            $ctx->{ current_archive_type } = 'Category';
            $ctx->{ archive_type } = 'Category';
        }
    }
    $ctx->stash( 'contactformgroup', $group );
    my %args = ( ctx => $ctx,
                 blog => $blog,
                 entry => $entry,
                 category => $category,
                );
    # my $template = __get_template( $group, 'confirm' );
    my $template = __get_template( $group, 'cms' );
    $vars->{ template_type } = 'view';
    $vars->{ mode } = 'view';
    $vars->{ object_id } = $object_id;
    $vars->{ model } = $model;
    $vars->{ id } = $group->id;
    $vars->{ blog_id } = $app->blog->id;
    $vars->{ form_name } = $group->name;
    $vars->{ contactform } = 1;
    my $out = build_tmpl( $app, $template, \%args, $vars );
    return $out;
}

sub _default {
    my $app = shift;
    my $component = MT->component( 'ContactForm' );
    require ContactForm::Feedback;
    require ContactForm::ContactFormOrder;
    my $remote_ip = $app->remote_ip;
    my $session = _get_session( $remote_ip, $app->get_header( 'USER_AGENT' ) );
    my $blog = $app->blog;
    my $id = $app->param( 'id' );
    my $model = $app->param( 'model' );
    my $mode = $app->mode;
    if ( $mode eq 'submit' ) {
        my $plugin = MT->component( 'ContactFormConfig' );
        if ( _blocking_spam_post( $session, $plugin->get_config_value( 'throttle' ) ) ) {
            return $app->error( $component->translate( 'You are posting form data too quickly. Please try again later.' ) );
        }
    }
    my $object_id = $app->param( 'object_id' );
    my %param;
    require ContactForm::ContactFormGroup;
    my $group = ContactForm::ContactFormGroup->load( $id );
    return '' unless $group;
    require MT::Template::Context;
    my $ctx = MT::Template::Context->new;
    $ctx->stash( 'contactformgroup', $group );
    my ( $entry, $category, $data, $author, $owner_id, $match_obj );
    if ( $model && $object_id ) {
        if ( ( $model eq 'entry' ) || ( $model eq 'page' ) ) {
            $entry = MT->model( $model )->load( $object_id );
            return '' unless $entry;
            if ( $entry->status != 2 ) {
                return '';
            }
            if ( $model eq 'entry' ) {
                $ctx->{ current_archive_type } = 'Individual';
                $ctx->{ archive_type } = 'Individual';
            } else {
                $ctx->{ current_archive_type } = 'Page';
                $ctx->{ archive_type } = 'Page';
            }
            $owner_id = $entry->author_id;
            $match_obj = 1;
        } elsif ( ( $model eq 'category' ) || ( $model eq 'folder' ) ) {
            $category = MT->model( $model )->load( $object_id );
            return '' unless $category;
            $ctx->{ current_archive_type } = 'Category';
            $ctx->{ archive_type } = 'Category';
            $owner_id = $category->author_id;
            $match_obj = 1;
        } elsif ( $model eq 'author' ) {
            $author = MT->model( $model )->load( $object_id );
            return '' unless $author;
            $owner_id = $author->author_id;
            $match_obj = 1;
        }
    }
    if (! $match_obj ) {
        $object_id = undef;
        $model = undef;
    }
    if (! $owner_id ) {
        $owner_id = $group->author_id;
    }
    my $vars;
    $vars->{ object_id } = $object_id;
    $vars->{ model } = $model;
    $vars->{ id } = $group->id;
    $vars->{ blog_id } = $app->blog->id;
    $vars->{ mode } = $mode;
    $vars->{ form_name } = $group->name;
    $vars->{ identifier } = $app->param( 'identifier' );
    $vars->{ contactform } = 1;
    my $template = __get_template( $group, 'cms' );
    my %args = ( ctx => $ctx,
                 blog => $blog,
                 entry => $entry,
                 category => $category,
                 author => $author,
                );
    if (! $group->is_open ) {
        if ( $group->is_closed ) {
            $vars->{ template_type } = 'closed';
        } elsif ( $group->is_closed ) {
            $vars->{ template_type } = 'preopen';
        }
        my $out = build_tmpl( $app, $template, \%args, $vars );
        return $out;
    }
    my $confirm_ok = 1;
    my $submit_ok = 0;
    $param { 'join' } = [ 'ContactForm::ContactFormOrder', 'contactform_id',
             { group_id  => $id, },
             { 'sort'    => 'order',
               direction => 'ascend', } ];
    my @contactforms = MT->model( 'contactform' )->load( undef, \%param );
    my @form_loop;
    my $sender_email;
    for ( 1 .. 2 ) {
        my $i = 1;
        if ( $_ == 2 ) {
            @form_loop = ();
        }
        for my $contactform ( @contactforms ) {
            my $first;
            my $last;
            if ( $i == 1 ) {
                $first = 1;
            }
            if ( $i == scalar( @contactforms ) ) {
                $last = 1;
            }
            my $type = $contactform->type;
            my $mtml = $contactform->get_template;
            my $option = $contactform->options;
            my @options = split( /,/, $option );
            my $field_value = $app->param( $contactform->basename );
            if ( $contactform->normalize ) {
                $field_value = normalize( $field_value ) if $field_value;
            }
            $field_value =~ s/\r+//g;
            my $input = $field_value;
            my @field_vals = $app->param( $contactform->basename );
            my %params = ( form => $group,
                           vars => $vars,
                           field_basename => $contactform->basename,
                           field_name => $contactform->name,
                           field_required => $contactform->required,
                           field_default => $contactform->default,
                           field_value => $field_value,
                           field_raw => $field_value,
                           field_description => $contactform->description,
                           field_option => $option,
                           field_mode => $mode,
                           field_error => '',
                           option_value => '',
                           field_loop => undef,
                           multi_vals => '',
                          );
            my @option_value;
            if ( ( scalar @field_vals ) >= 1 ) {
                my $counter = 1;
                for my $val ( @field_vals ) {
                    if ( $contactform->normalize ) {
                        $val = normalize( $val ) if $val;
                    }
                    my ( $first, $last );
                    $first = 1 if $counter == 1;
                    $last = 1 if $counter == scalar @field_vals;
                    push @option_value, { field_raw => $val,
                                          __counter__ => $counter,
                                          __first__ => $first,
                                          __last__ => $last,
                                          };
                    $counter++;
                }
                $params{ option_value } = \@option_value;
                $input = join( '', @field_vals );
            }
            if ( my $format = $contactform->get_registry( 'format' ) ) {
                $format = MT->handler_to_coderef( $format );
                if ( $format ) {
                    my $format_value;
                    if (! @option_value ) {
                       $format_value = $format->( $app, $contactform, $field_value, \%params );
                    } else {
                       $format_value = $format->( $app, $contactform, \@field_vals, \%params );
                    }
                    if ( $format_value ne $field_value ) {
                        $params{ field_value } = $format_value;
                    }
                }
            }
            if ( $_ == 1 ) {
                if ( $mode eq 'confirm' ) {
                    if ( my $confirm = $contactform->get_registry( 'confirm' ) ) {
                        $confirm = MT->handler_to_coderef( $confirm );
                        if ( $confirm ) {
                            $confirm->( $app, $contactform, $field_value, \%params );
                        }
                    }
                }
            }
            if ( defined $input && $input ne '' && $contactform->validate ) {
                # if (! $input ) {
                #     $params{ field_error } = 'required';
                #     $confirm_ok = 0;
                # } else {
                    if ( my $validate = $contactform->get_registry( 'validate' ) ) {
                        $validate = MT->handler_to_coderef( $validate );
                        if ( $validate ) {
                            if (! @option_value ) {
                                if (! $validate->( $app, $contactform, $field_value, \%params ) ) {
                                    $params{ field_error } = 'invalid';
                                }
                            } else {
                                if (! $validate->( $app, $contactform, \@field_vals, \%params ) ) {
                                    $params{ field_error } = 'invalid';
                                }
                            }
                        }
                    }
                # }
            }
            if ( $contactform->required ) {
                if (! $input ) {
                    $params{ field_error } = 'required';
                    $confirm_ok = 0;
                }
            }
            if ( $type eq 'email' ) {
                $sender_email = $params{ field_value };
                if ( $group->single_post ) {
                    my $you_post = ContactForm::Feedback->load( { contactform_group_id => $group->id ,email => $sender_email } );
                    if ( defined ( $you_post ) ) {
                        $params{ field_error } = 'user_already_posted';
                        $confirm_ok = 0;
                    }
                }
            }
            if (! $params{ field_error } ) {
                if ( ( $contactform->check_length ) && ( $contactform->max_length ) ) {
                    my $multibyte = $contactform->count_multibyte;
                    my $length;
                    if ( $multibyte ) {
                        $length = multibyte_length( $field_value );
                        $length = ceil( $length );
                    } else {
                        $length = length( $field_value );
                    }
                    my $comp_length = $contactform->max_length + 1;
                    if ( $comp_length <= $length ) {
                        $params{ field_error } = 'over_limit';
                        $confirm_ok = 0;
                    }
                }
            }
            my $multi_vals;
            if ( @options ) {
                my @field_loop;
                my $j = 0;
                my @vals;
                for my $opt ( @options ) {
                    my $option_default;
                    my $local_first;
                    my $local_last;
                    if ( ( $field_value && ( $opt eq $field_value ) ) || ( grep $_ eq $opt, @field_vals ) ) {
                        $option_default = 1;
                        push ( @vals, $opt );
                    }
                    $j++;
                    if ( $j == 1 ) {
                        $local_first = 1;
                    }
                    if ( $j == scalar( @options ) ) {
                        $local_last = 1;
                    }
                    push @field_loop, {
                        option_value => $opt,
                        option_select => $option_default,
                        option_default => $option_default,
                        __first__ => $local_first,
                        __last__ => $local_last,
                        __counter__ => $j,
                    };
                }
                $params{ field_loop } = \@field_loop;
                $multi_vals = join( ',', @vals ) if ( @vals );
                $params{ multi_vals } = $multi_vals;
            }
            if ( $params{ field_error } ) {
                $confirm_ok = 0;
            }
            if ( $_ == 2 ) {
                if ( $mode eq 'submit' ) {
                    $field_value = $multi_vals if $multi_vals;
                    if ( ref $field_value eq 'Fh' ) {
                        $field_value = '';
                    }
                    $data->{ $i } = [ $contactform->name, $field_value, $contactform->basename, $contactform->type ];
                    if ( my $submit = $contactform->get_registry( 'submit' ) ) {
                        $submit = MT->handler_to_coderef( $submit );
                        if ( $submit ) {
                            $submit->( $app, $contactform, $field_value, \%params );
                        }
                    }
                }
            }
            $ctx->stash( 'contactform', $contactform );
            $args{ ctx } = $ctx;
            $app->run_callbacks( 'contactform.pre_build.' . $type, $app, $mtml, \%args, \%params );
            my $html = build_tmpl( $app, $mtml, \%args, \%params );
            push ( @form_loop, { field_html => $html,
                                 field_value => $field_value,
                                 field_label => $contactform->name,
                                 field_type => $contactform->type,
                                 __counter__ => $i,
                                 __first__ => $first,
                                 __last__ => $last, } );
            $i++;
        }
        if ( ( $_ == 1 ) && ( $mode ne 'submit' ) || (! $confirm_ok ) ) {
            last;
        }
    }
    $vars->{ field_loop } = \@form_loop;
    $vars->{ confirm_ok } = $confirm_ok;
    $args{ ctx } = $ctx;
    if ( $mode eq 'submit' && $confirm_ok ) {
        my $feedback;
        if ( $app->config->AllowReeditFeedback ) {
            if ( my $feedback_id = $app->param( 'feedback_id' ) ) {
                if ( my $user = $app->user ) {
                    $app->validate_magic or return $app->trans_error( 'Permission denied.' );
                    $feedback = ContactForm::Feedback->load( $feedback_id );
                    if (! $user->is_superuser ) {
                        if ( $feedback->created_by != $user->id ) {
                            return $app->trans_error( 'Permission denied.' );
                        }
                    }
                }
            }
        }
        $feedback = ContactForm::Feedback->new unless $feedback;
        $feedback->{ __data } = $data;
        $feedback->blog_id( $vars->{ blog_id } );
        $feedback->object_id( $vars->{ object_id } );
        $feedback->contactform_group_id( $group->id );
        $feedback->form_author_id( $group->author_id );
        $feedback->identifier( $app->param( 'identifier' ) );
        $feedback->email( $sender_email );
        $feedback->model( $model );
        $feedback->remote_ip( $remote_ip );
        $feedback->owner_id( $owner_id );
        if (! $app->run_callbacks( 'pre_save_feedback', $app, \$feedback, \%args, $vars ) ) {
            if ( $vars->{ callback_error } ) {
                return $app->error( $vars->{ callback_error } );
            } else {
                return $app->trans_error( 'Permission denied.' );
            }
        }
        if (! $group->not_save ) {
            $feedback->save or die $feedback->errstr;
        }
        $vars->{ feedback_id } = $feedback->id;
        $vars->{ feedback_remote_ip } = $feedback->remote_ip;
        $vars->{ feedback_status } = $feedback->status;
        $vars->{ feedback_email } = $feedback->email;
        $vars->{ form_name } = $group->name;
        $session->save or die $session->errstr;
        $app->run_callbacks( 'post_save_feedback', $app, $feedback, \%args, $vars );
        $submit_ok = 1;
        $vars->{ submit_ok } = $submit_ok;
        my $return_url = $group->return_url;
        my $from = $app->config->EmailAddressMain;
        my ( $mail2admin, $mail2sender );
        if (! $from ) {
            if ( my $author = $group->author ) {
                $from = $author->email;
            }
        }
        if ( $from ) {
            my $mail_admin = $group->mail_admin;
            my $send_mailto = $group->send_mailto;
            my $mail_sender = $group->mail_sender;
            my $mail_admin_tmpl = __get_template( $group, 'mail_admin' );
            my $mail_sender_tmpl = __get_template( $group, 'mail_sender' );
            if ( $mail_admin && $send_mailto ) {
                $vars->{ template_type } = 'mail_admin';
                $vars->{ mail_subject } = 1;
                my $subject = $group->notify_subject || $component->translate( 'Contact Form Notify' );
                #$args{ ctx } = $ctx;
                $send_mailto = build_tmpl( $app, $send_mailto, \%args, $vars ) if $send_mailto =~ /<\$?[Mm][Tt]/;
                $subject     = build_tmpl( $app, $subject, \%args, $vars ) if $subject =~ /<\$?[Mm][Tt]/;
                $vars->{ mail_subject } = 0;
                $vars->{ mail_body } = 1;
                #$args{ ctx } = $ctx;
                my $body = build_tmpl( $app, $mail_admin_tmpl, \%args, $vars );
                my %params4cb = ( component => 'ContactForm',
                                  contactform => $group,
                                  vars => $vars,
                                  args => \%args,
                                  mail_type => 'mail_admin', );
                if ( send_mail( $from, $send_mailto, $subject, $body, undef, undef, \%params4cb ) ) {
                    $mail2admin = 1;
                }
            }
            if ( $mail_sender && $sender_email ) {
                $vars->{ template_type } = 'mail_sender';
                $vars->{ mail_subject } = 1;
                my $subject = $group->sender_subject || $component->translate( 'Your post has been submitted' );
                #$args{ ctx } = $ctx;
                $subject = build_tmpl( $app, $subject, \%args, $vars ) if $subject =~ /<\$?[Mm][Tt]/;
                $vars->{ mail_subject } = 0;
                $vars->{ mail_body } = 1;
                $sender_email = build_tmpl( $app, $sender_email, \%args, $vars ) if $sender_email =~ /<\$?[Mm][Tt]/;
                my $body = build_tmpl( $app, $mail_sender_tmpl, \%args, $vars );
                my %params4cb = ( component => 'ContactForm',
                                  contactform => $group,
                                  vars => $vars,
                                  args => \%args,
                                  mail_type => 'mail_sender', );
                if ( send_mail( $from, $sender_email, $subject, $body, undef, undef, \%params4cb ) ) {
                    $mail2sender = 1;
                }
            }
            $vars->{ mail_subject } = 0;
            $vars->{ mail_body } = 0;
        }
        if ( $submit_ok ) {
            my $log_message = $component->translate( "New post for '[_1] (Blog:[_2]) ' was accepted.", $group->name, $group->blog->name );
            if ( $mail2admin && $mail2sender ) {
                $log_message .= $component->translate( 'Send email to sender and administrator.' );
            } elsif ( $mail2admin ) {
                $log_message .= $component->translate( 'Send email to administrator.' );
            } elsif ( $mail2sender ) {
                $log_message .= $component->translate( 'Send email to sender.' );
            }
            my $log = MT::Log->new;
            if ( defined $app->user ) {
                $log->author_id( $app->user->id );
            }
            $log->class( 'contactform' );
            $log->level( 1 );
            $log->blog_id( $group->blog_id );
            $log->message( $log_message );
            $log->ip( $remote_ip );
            $log->save or die $log->errstr;
        }
        if ( $return_url ) {
            $app->run_callbacks( ( ref $app ) . '::pre_redirect', $app, $feedback, \$return_url );
            return $app->redirect( $return_url );
        }
    }
    $vars->{ submit_ok } = $submit_ok;
    if ( ( $mode eq 'confirm' ) || (! $confirm_ok ) ) {
        # $template = __get_template( $group, 'confirm' );
        $vars->{ template_type } = 'confirm';
    } else {
        # $template = __get_template( $group, 'submit' );
        $vars->{ template_type } = 'submit';
    }
    #$args{ ctx } = $ctx;
    my $out = build_tmpl( $app, $template, \%args, $vars );
    return $out;
}

sub __get_template {
    my ( $group, $key ) = @_;
    $key = $key . '_tmpl';
    my $tmpl = $group->$key;
    my $text = '';
    if ( $tmpl ) {
        require MT::Template;
        my $template = MT::Template->load( $tmpl );
        if ( $template ) {
            $text = $template->text;
        }
    }
    if (! $text ) {
        my $component = MT->component( 'ContactForm' );
        my $tmpl_path = plugin_template_path( $component, 'tmpl' );
        require File::Spec;
        $tmpl_path = File::Spec->catfile( $tmpl_path, $key . '.tmpl' );
        if ( -f $tmpl_path ) {
            $text = utf8_on( read_from_file( $tmpl_path ) );
        }
    }
    return $text;
}

sub _get_session {
    my ( $remote_ip, $ua ) = @_;
    my $uinfo = $remote_ip . $ua;
    require Digest::MD5;
    $uinfo = Digest::MD5::md5_hex( $uinfo );
    return MT::Session->get_by_key( { id => $uinfo, kind => 'PF' } );
}

sub _blocking_spam_post {
    my ( $session, $throttle ) = @_;
    my $past = $session->start;
    $session->start( time );
    return 0 unless $past; # NOT error
    $past = time - $past;
    return ( $past < $throttle );
}

1;
