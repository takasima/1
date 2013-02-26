package MT::App::CMS::Members;

use strict;
use base qw( MT::App );

use MT;
use MT::Blog;
use MT::Session;
use MT::Author;
use File::Spec;
use File::Basename;

use Members::Callbacks;
use Members::Util;

use MT::Util qw( trim );

use PowerCMS::Util qw( association_link is_ua_mobile site_url send_mail
                       support_dir is_image upload build_tmpl valid_email
                       get_mobile_id is_ua_keitai is_user_can current_blog
                       current_ts save_asset
                     );

use lib 'addons/Commercial.pack/lib';
use CustomFields::Util qw( field_loop );

sub init_request {
    my $app = shift;
    my $ua  = $app->get_header( 'User-Agent' );
    $app->SUPER::init_request(@_);
    $app->{default_mode} = 'view';
    $app->add_methods( view            => \&_view );
    $app->add_methods( login           => \&_login );
    $app->add_methods( logout          => \&_logout );
    $app->add_methods( signup          => \&_signup );
    $app->add_methods( edit_profile    => \&_profile );
    $app->add_methods( do_signup       => \&_do_signup );
    $app->add_methods( recover         => \&_recover );
    $app->add_methods( start_recover   => \&start_recover );
    $app->add_methods( new_pw          => \&_new_pw );
    $app->add_methods( redirect        => \&_redirect );
    $app->add_methods( test            => \&_test );
    $app->add_methods( secedes         => \&_secedes );
    $app->add_methods( secedes_confirm => \&_secedes_confirm );
    if ( $ua =~ /(?:^Opera|Mozilla)/ ) {
        my $mode = $app->param( '__mode' );
        if ( $mode ne 'do_signup' && $mode ne 'signup' &&
             $mode ne 'recover'   && $mode ne 'start_recover' &&
             $mode ne 'new_pw' )
        {
            my ( $sess, $user ) = $app->get_commenter_session();
            unless ( _get_author( $app, ( $sess ? $sess->id : '' ) ) ) {
                $user = undef;
            }
            if ($user) {
                $app->user($user);
            }
            else {
                $app->{requires_login} = 1;
            }
        }
    }
    else {
        my $sessid = $app->param( 'sessid' );
        my $user = _get_author( $app, $sessid );
        if ( defined $user ) {
            $app->user($user);
        }
    }
    $app;
}

sub _signup {
    my $app = shift;
    return $app->trans_error( 'Invalid request')
        unless current_blog( $app );
    my %param = ( blog_id => $app->blog->id );
    my $tmpl = File::Spec->catfile( $app->config( 'TemplatePath'),
        'comment', 'signup.tmpl' );
    return $app->build_page( $tmpl, \%param );
}

sub _recover {
    my $app = shift;
    return $app->trans_error( 'Invalid request')
        unless current_blog( $app );
    if ( my $mobile_address = $app->param( 'mobile_address') ) {
        $mobile_address = trim($mobile_address);
        if ( !$mobile_address ) {
            return $app->start_recover(
                {   error => $app->translate(
                        'Email Address is required for password recovery.'),
                }
            );
        }
        my $username = $app->param( 'name' );
        $username = trim($username);

        my @all_authors = $app->model( 'author')
            ->search_by_meta( 'mobile_address', $mobile_address );
        my @authors;
        foreach (@all_authors) {
            next unless $_->password && ( $_->password ne '(none)' );
            next unless $_->email;
            next if $username && $_->name ne $username;
            push( @authors, $_ );
        }

        if ( !@authors ) {
            return $app->start_recover(
                {   error => $app->translate( 'User not found'),
                    ( $username ? ( not_unique_email => 1 ) : () ),
                }
            );

        }
        elsif ( @authors > 1 ) {
            return $app->start_recover( { not_unique_email => 1, } );
        }
        my $user  = pop @authors;
        my $email = $user->email;
        $app->param( 'email', $email );
    }
    require MT::CMS::Tools;
    MT::CMS::Tools::recover_password( $app );

    # Tasks... Recover password and send mail
}

sub start_recover {
    my $app = shift;
    my ($param) = @_;
    return $app->trans_error( 'Invalid request')
        unless current_blog( $app );
    my $blog = $app->blog;
    my $identifier;
    if ( is_ua_keitai( $app ) ) {
        $identifier = 'members_recover_mobile';
    }
    else {
        $identifier = 'members_recover';
    }
    my $template
        = Members::Callbacks::_load_tmpl( $app, $blog, $identifier );
    my %args = ( blog => $app->blog );
    $param->{email}          = $app->param( 'email' );
    $param->{mobile_address} = $app->param( 'mobile_address' );
    $param->{return_to}
        = $app->param( 'return_to')
        || $app->config->ReturnToURL
        || '';
    $param->{blog_id} = $blog->id;
    return build_tmpl( $app, @$template[0], \%args, $param );
}

sub _new_pw {
    my $app = shift;
    return $app->trans_error( 'Invalid request')
        unless current_blog( $app );
    my $err;
    my $np = $app->param( 'password' );
    if ($np) {
        my $ag = $app->param( 'password_again' );
        if ( !$ag ) {
            $err = $app->translate( 'Please confirm your new password' );
        }
        elsif ( $np ne $ag ) {
            $err = $app->translate( 'Passwords do not match' );
        }
        else {
            my $plugin  = MT->component( 'Members' );
            my $blog_id = $app->blog->id;
            my @errors = ();
            my $config_scope = 'blog:'.$blog_id;
            if ( $plugin->get_config_value('validate_username_and_password', $config_scope) ) {
                if ( $plugin->get_config_value('password_deny_multibytes', $config_scope) ) {
                    if ( $np ne '' && $np =~ /[^\x20-\x7E]/ ) {
                        push @errors, $plugin->translate( 'Password should not include multi-byte characters.' );
                    }
                }
                if ( $plugin->get_config_value('password_combo_upper_lower', $config_scope) ) {
                    if ( $np ne '' ) {
                        unless ( $np =~ /[a-z]/ and $np =~ /[A-Z]/ ) {
                            push @errors, $plugin->translate( 'Password should contain uppercase and lowercase letters.' );
                        }
                    }
                }
                if ( $plugin->get_config_value('password_combo_letter_number', $config_scope) ) {
                    if ( $np ne '' ) {
                        unless ( $np =~ /\D/ and $np =~ /\d/ ) {
                            push @errors, $plugin->translate( 'Password Should contain letters and numbers.' );
                        }
                    }
                }
                if ( $plugin->get_config_value('password_require_special_characters', $config_scope) ) {
                    if ( $np ne '' ) {
                        unless ( $np =~ m'[!"#$%&\'\(\|\)\*\+,-\.\/\\:;<=>\?@\[\]^_`{}~]' ) {
                            push @errors, $plugin->translate( 'Password Should contain special characters.' );
                        }
                    }
                }
                my $password_minimum_length = $plugin->get_config_value('password_minimum_length', $config_scope);
                if ( $password_minimum_length !~ /\D/ ) {
                    if ( $np ne '' && length $np < $password_minimum_length ) {
                        push @errors, $plugin->translate( 'Password should be longer than [_1] characters', $password_minimum_length );
                    }
                }
            }
            unless ( @errors ) {
                require MT::CMS::Tools;
                return MT::CMS::Tools::new_password( $app );
            } else {
                $err = join '<br>', @errors;
            }
        }
    }
    my $blog = $app->blog;
    my $identifier;
    if ( is_ua_keitai( $app ) ) {
        $identifier = 'members_n_p_mobile';
    }
    else {
        $identifier = 'members_n_p';
    }
    my $template
        = Members::Callbacks::_load_tmpl( $app, $blog, $identifier );
    my %args = ( blog => $blog );
    my %param = (
        blog_id => $blog->id,
        email   => scalar $app->param( 'email'),
        token   => scalar $app->param( 'token'),
        $err ? ( error => $err ) : (),
    );
    return build_tmpl( $app, @$template[0], \%args, \%param );
}

sub redirect_to_edit_profile {
    my $app = MT->instance();
    return $app->trans_error( 'Invalid request')
        unless current_blog( $app );
    my $return_url = site_url( $app->blog ) . '/';
    $app->redirect($return_url);
}

sub _profile {
    my $app = shift;
    unless ( $app->user ) {
        return $app->trans_error( 'Permission denied.' );
    }
    return $app->trans_error( 'Invalid request')
        unless current_blog( $app );
    my %param;
    my $plugin  = MT->component( 'Members' );
    my $blog    = $app->blog;
    my $blog_id = $blog->id;
    $param{blog_id}    = $blog_id;
    $param{script_url} = $app->base . $app->uri;
    $param{sessid}     = $app->param( 'sessid' );
    my $type   = $app->param( 'type' );
    my $id     = $app->param( 'author_id' );
    my $author = ( $id ? MT::Author->load($id) : $app->user );
    return $app->trans_error( 'Invalid request') unless defined $author;

    if ( !$app->user->is_superuser ) {
        if ( $author->id != $app->user->id ) {
            return $app->trans_error( 'Permission denied.' );
        }
    }
    my %args = ( blog => $blog, author => $author, );
    my $error;
    my %errors;
    if ( $type eq 'save' ) {
        my $nickname       = $app->param( 'nickname' );
        my $email          = $app->param( 'email' );
        my $mobile_address = $app->param( 'mobile_address' );
        my $password       = $app->param( 'password' );
        my $pass_verify    = $app->param( 'pass_verify' );
        my $mail_token     = $app->param( 'mail_token' );
        my $mobile_id      = get_mobile_id( $app );
        if ( !$nickname || !$email ) {
            $error = 1;
            $errors{required} = 1;
            $errors{email}    = 1 if !$email;
            $errors{nickname} = 1 if !$nickname;
        }
        if ( is_ua_mobile( $app ) ) {
            if ( !$mobile_address ) {
                $error                  = 1;
                $errors{required}       = 1;
                $errors{mobile_address} = 1;
            }
        }
        if ( $password && ( $password ne $pass_verify ) ) {
            $error = 1;
            $errors{password}    = 1 if !$password;
            $errors{pass_verify} = 1 if !$pass_verify;
            $errors{password_not_verify} = 1;
        }
        if ( !valid_email($email) ) {
            $error = 1;
            $errors{email_not_valid} = 1;
        }
        if ($mobile_address) {
            if ( !valid_email($mobile_address) ) {
                $error = 1;
                $errors{mobile_not_valid} = 1;
            }
        }
        my $config_scope = 'blog:'.$blog_id;
        if ( $plugin->get_config_value('validate_username_and_password', $config_scope) ) {
            if ( $plugin->get_config_value('password_deny_multibytes', $config_scope) ) {
                if ( $password ne '' && $password =~ /[^\x20-\x7E]/ ) {
                    $error = 1;
                    $errors{password_deny_multibytes} = 1;
                }
            }
            if ( $plugin->get_config_value('password_combo_upper_lower', $config_scope) ) {
                if ( $password ne '' ) {
                    unless ( $password =~ /[a-z]/ and $password =~ /[A-Z]/ ) {
                        $error = 1;
                        $errors{password_combo_upper_lower} = 1;
                    }
                }
            }
            if ( $plugin->get_config_value('password_combo_letter_number', $config_scope) ) {
                if ( $password ne '' ) {
                    unless ( $password =~ /\D/ and $password =~ /\d/ ) {
                        $error = 1;
                        $errors{password_combo_letter_number} = 1;
                    }
                }
            }
            if ( $plugin->get_config_value('password_require_special_characters', $config_scope) ) {
                if ( $password ne '' ) {
                    unless ( $password =~ m'[!"#$%&\'\(\|\)\*\+,-\.\/\\:;<=>\?@\[\]^_`{}~]' ) {
                        $error = 1;
                        $errors{password_require_special_characters} = 1;
                    }
                }
            }
            my $password_minimum_length = $plugin->get_config_value('password_minimum_length', $config_scope);
            if ( $password_minimum_length !~ /\D/ ) {
                if ( $password ne '' && length $password < $password_minimum_length ) {
                    $error = 1;
                    $errors{password_minimum_length} = 1;
                }
            }
        }
        if (!$app->run_callbacks(
                'members_pre_save.profile', $app,
                \$author,                   \%param,
                \%errors
            )
        ) {
            $error = 1;
        }

        # Tasks...
        # Check Author's Required Customfields(CallBack)
        unless ( $app->run_callbacks( 'api_save_filter.author', $app ) ) {
            $error = 1;
            $param{ error_message } = $app->errstr;
        }
        if ($error) {
            $param{error}          = 1;
            $param{nickname}       = $nickname;
            $param{email}          = $email;
            $param{mobile_address} = $mobile_address;
            $param{mail_token}     = $mail_token;
            my @loop;
            for my $key ( keys %errors ) {
                push( @loop, { error_name => $key } );
            }
            $param{errors} = \@loop;
        }
        else {

            # Do Save
            $author->nickname($nickname);
            $author->email($email);
            $author->mobile_address($mobile_address);
            $author->mail_token($mail_token);
            $author->mobile_id($mobile_id)   if $mobile_id;
            $author->set_password($password) if $password;
            $author->modified_on( current_ts() );
            $author->save or die $author->errstr;
            $app->run_callbacks( 'api_post_save.author', $app, $author );
            my $userpics_dir
                = File::Spec->catdir( support_dir(), 'assets_c', 'userpics' );
            my $q    = $app->param;
            my $file = $q->upload( 'userpic' );

            if ( $file && is_image($file) ) {
                my %params
                    = ( author => $author, rename => 1, singler => 1, force_decode_filename => 1, );
                my $asset = upload( $app, $blog, 'userpic', $userpics_dir,
                    \%params );
                if ( $asset ) {
                    my $asset_id = $asset->id;
                    $asset->blog_id( 0 );
                    $asset->tags( '@userpic' );
                    $asset->save or die $asset->errstr;
                    if ( $author->userpic_asset_id ) {
                        require MT::Asset::Image;
                        my $old
                            = MT::Asset::Image->load( $author->userpic_asset_id );
                        if ( defined $old ) {
                            $old->remove or die $old->errstr;
                        }
                    }
                    $author->userpic_asset_id( $asset_id );
                    $author->save or die $author->errstr;
                }
            }
            $app->run_callbacks( 'members_post_save.profile', $app, $author );
            $param{saved} = 1;
        }
    }
    if ($error) {
        my $columns = $author->column_names;
        for my $column (@$columns) {
            $param{$column} = $author->$column unless $column eq 'password';
        }
        $param{mobile_address} = $author->mobile_address;
        $param{mail_token}     = $author->mail_token;

        # Tasks ... Author's CustomField Set (CallBack)
    }
    my $template_name = 'members_e_p';
    if ( is_ua_keitai( $app ) ) {
        $template_name .= '_mobile';
    }
    my %cf_param = (
        object_type => 'author',
        simple      => 1,
    );
    $param{field_loop} = field_loop( %cf_param );
    my $q = $app->param;
    my @query_params;
    for my $key ( $q->param ) {
        push( @query_params, { $key => $q->param($key) } );
    }
    $param{query_params} = \@query_params;
    if ( MT->component( 'MailMagazine' ) ) {
        if ( $author->permissions($blog_id)->can_mail_subscription ) {
            $param{'mail_subscription'} = 1;
        }
    }
    if ( my $return_url = $app->param( 'return_url') ) {
        $param{'return_url'} = $return_url;
    }
    my $template
        = Members::Callbacks::_load_tmpl( $app, $blog, $template_name );
    return build_tmpl( $app, @$template[0], \%args, \%param );
}

sub _do_signup {
    my $app = shift;
    return $app->trans_error( 'Invalid request') unless current_blog( $app );
    my %param;
    my $plugin  = MT->component( 'Members' );
    my $blog    = $app->blog;
    my $blog_id = $blog->id;
    $param{ blog_id } = $blog_id;
    my $type = $app->param( 'type' );
    my $author;
    my $error;
    my $token = $app->param( 'token' );
    my $userpic_session;
    if ( $token ) {
        $userpic_session = MT::Session->load( { email => 'temporary_userpic@powercms.jp', id => $token } );
        if ( $userpic_session ) {
            $param{ userpic_filename } = File::Basename::basename( $userpic_session->name );
        }
    }
    $token = $app->make_magic_token unless $token;
    $param{ 'token' } = $token;
    $app->set_header( "Cache-Control" => "no-cache" );
    $app->set_header( "Pragma" => "no-cache" );

    if ( $type && $type eq 'regist' ) {
        $param{regist} = 1;
        my $token     = $app->param( 'magic_token' );
        my $author_id = $app->param( 'author_id' );
        my $sess      = MT::Session->load(
            {   kind => 'MM',
                id   => $token,
                name => $author_id,
            }
        );
        my $success;
        if ( defined $sess ) {
            my $timeout = $plugin->get_config_value( 'members_signup_timeout')
                || 604800;
            if ( ( time - $sess->start ) < $timeout ) {
                my $author_id = $sess->name;
                $author = MT::Author->load( $author_id );
                if ( defined $author ) {
                    if ( $author->status == MT::Author::INACTIVE() ) {
                        $success = 1;
                        $sess->remove or die $sess->errstr;
                    }
                }
            } else {
                $error = 1; # regisration timeout
            }
        }
        unless ( $success ) {
            $param{ registration_failed } = 1;
        }
    }
    else {
        my $name           = $app->param( 'username' );
        my $nickname       = $app->param( 'nickname' );
        my $email          = $app->param( 'email' );
        my $mobile_address = $app->param( 'mobile_address' );
        my $password       = $app->param( 'password' );
        my $pass_verify    = $app->param( 'pass_verify' );
        my $mail_token     = $app->param( 'mail_token' );
        my $mobile_id      = get_mobile_id( $app );
        my %errors;
        if (   !$name
            || !$nickname
            || !$email
            || !$password
            || !$pass_verify )
        {
            $error = 1;
            $errors{ required }    = 1;
            $errors{ username }    = 1 if !$name;
            $errors{ email }       = 1 if !$email;
            $errors{ nickname }    = 1 if !$nickname;
            $errors{ password }    = 1 if !$password;
            $errors{ pass_verify } = 1 if !$pass_verify;
        }
        if ( is_ua_mobile( $app ) ) {
            if ( !$mobile_address ) {
                $error                    = 1;
                $errors{ required }       = 1;
                $errors{ mobile_address } = 1;
            }
        }
        if ( $password ne $pass_verify ) {
            $error = 1;
            $errors{ password_not_verify } = 1;
        }
        if ( !valid_email( $email ) ) {
            $error = 1;
            $errors{ email_not_valid } = 1;
        }
        if ( $mobile_address ) {
            if ( !valid_email( $mobile_address ) ) {
                $error = 1;
                $errors{ mobile_not_valid } = 1;
            }
        }
        my $config_scope = 'blog:'.$blog_id;
        if ( $plugin->get_config_value('validate_username_and_password', $config_scope) ) {
            if ( $plugin->get_config_value('username_deny_multibytes', $config_scope) ) {
                if ( $name ne '' && $name =~ /[^\x20-\x7E]/ ) {
                    $error = 1;
                    $errors{username_deny_multibytes} = 1;
                }
            }
            if ( ! $plugin->get_config_value('username_allow_alphabet', $config_scope) ) {
                if ( $name ne '' && $name =~ /[A-Za-z]/ ) {
                    $error = 1;
                    $errors{username_allow_alphabet} = 1;
                }
            }
            if ( ! $plugin->get_config_value('username_allow_number', $config_scope) ) {
                if ( $name ne '' && $name =~ /[0-9]/ ) {
                    $error = 1;
                    $errors{username_allow_number} = 1;
                }
            }
            if ( ! $plugin->get_config_value('username_allow_special_characters', $config_scope) ) {
                if ( $name ne '' && $name =~ m'[!"#$%&\'\(\|\)\*\+,-\.\/\\:;<=>\?@\[\]^_`{}~]' ) {
                    $error = 1;
                    $errors{username_allow_special_characters} = 1;
                }
            }
            my $username_minimum_length = $plugin->get_config_value('username_minimum_length', $config_scope);
            if ( $username_minimum_length !~ /\D/ ) {
                if ( $name ne '' && length $name < $username_minimum_length ) {
                    $error = 1;
                    $errors{username_minimum_length} = 1;
                }
            }
            if ( $plugin->get_config_value('password_deny_multibytes', $config_scope) ) {
                if ( $password ne '' && $password =~ /[^\x20-\x7E]/ ) {
                    $error = 1;
                    $errors{password_deny_multibytes} = 1;
                }
            }
            if ( $plugin->get_config_value('password_combo_upper_lower', $config_scope) ) {
                if ( $password ne '' ) {
                    unless ( $password =~ /[a-z]/ and $password =~ /[A-Z]/ ) {
                        $error = 1;
                        $errors{password_combo_upper_lower} = 1;
                    }
                }
            }
            if ( $plugin->get_config_value('password_combo_letter_number', $config_scope) ) {
                if ( $password ne '' ) {
                    unless ( $password =~ /\D/ and $password =~ /\d/ ) {
                        $error = 1;
                        $errors{password_combo_letter_number} = 1;
                    }
                }
            }
            if ( $plugin->get_config_value('password_require_special_characters', $config_scope) ) {
                if ( $password ne '' ) {
                    unless ( $password =~ m'[!"#$%&\'\(\|\)\*\+,-\.\/\\:;<=>\?@\[\]^_`{}~]' ) {
                        $error = 1;
                        $errors{password_require_special_characters} = 1;
                    }
                }
            }
            my $password_minimum_length = $plugin->get_config_value('password_minimum_length', $config_scope);
            if ( $password_minimum_length !~ /\D/ ) {
                if ( $password ne '' && length $password < $password_minimum_length ) {
                    $error = 1;
                    $errors{password_minimum_length} = 1;
                }
            }
        }
        unless ( $error ) {
            $author = MT::Author->load( { name => $name } );
            if ( defined $author ) {
                $error = 1;
                $errors{ author_exist } = 1;
            }
        }
        my $confirm_ok;
        unless ( $error ) {
            if ( $app->param( 'signup_confirm' ) ) {
                $param{ confirm_ok } = 1;
                $confirm_ok = 1;
            }
        }
        if ( $app->param( 'signup_confirm' ) ) {
            my $q    = $app->param;
            my $file = $q->upload( 'userpic' );
            my $userpics_dir = File::Spec->catdir( support_dir(), 'assets_c', 'userpics' );
            if ( $file && is_image( $file ) ) {
                my %params
                    = ( no_asset => 1, rename => 1, singler => 1, force_decode_filename => 1, );
                my $out = upload( $app, $blog, 'userpic', $userpics_dir, \%params );
                my $basename = File::Basename::basename( $out );
                $param{ userpic_filename } = $basename;
                my $sess = MT::Session->new;
                $sess->id( $token );
                $sess->start( time );
                $sess->kind( 'UP' );
                $sess->name( $out );
                $sess->email( 'temporary_userpic@powercms.jp' );
                $sess->save or die $sess->errstr;
            }
        } else {
            if (! $app->run_callbacks(
                    'members_pre_save.new_user', $app,
                    \$author,                    \%param,
                    \%errors
                )
            ) {
                $error = 1;
            }
        }
        # Tasks...
        # Check Author's Required Customfields(CallBack)
        unless ( $app->run_callbacks( 'api_save_filter.author', $app ) ) {
            $error = 1;
            $param{ error_message } = $app->errstr;
        }
        if ( $error || $confirm_ok ) {
            $param{ error }          = 1 if $error;
            $error                   = 1;
            $param{ username }       = $name;
            $param{ nickname }       = $nickname;
            $param{ email }          = $email;
            $param{ mobile_address } = $mobile_address;
            $param{ mail_token }     = $mail_token;
            my @loop;
            for my $key ( keys %errors ) {
                push( @loop, { error_name => $key } );
            }
            $param{ errors } = \@loop;
        }
        else {
            unless ( defined $author ) {
                $author = MT::Author->new;
            }
            $author->name( $name );
            $author->nickname( $nickname );
            $author->email( $email );
            $author->mobile_address( $mobile_address );
            $author->mail_token( $mail_token ) if $mail_token;
            $author->regist_blog_id( $blog_id );
            $author->mobile_id( $mobile_id ) if $mobile_id;
            $author->type( 1 );
            $author->auth_type( 'MT' );
            unless ( $author->id ) {
                $author->status( MT::Author::INACTIVE() );
            }
            $author->set_password( $password );
            $author->preferred_language( $blog->language );
            $author->save or die $author->errstr;
            $app->run_callbacks( 'api_post_save.author', $app, $author );
            my $userpics_dir
                = File::Spec->catdir( support_dir(), 'assets_c', 'userpics' );
            my $q    = $app->param;
            my $file = $q->upload( 'userpic' );
            my $userpic_asset;
            if ( $file && is_image( $file ) ) {
                my %params
                    = ( author => $author, rename => 1, singler => 1, force_decode_filename => 1, );
                $userpic_asset = upload( $app, $blog, 'userpic', $userpics_dir,
                    \%params );
            } else {
                if ( $userpic_session ) {
                    my %params = ( file => $userpic_session->name,
                                   author => $author,
                                   );
                    $userpic_asset = save_asset( $app, $blog, \%params );
                }
            }
            if ( $userpic_asset ) {
                my $asset_id = $userpic_asset->id;
                $userpic_asset->blog_id( 0 );
                $userpic_asset->tags( '@userpic' );
                $userpic_asset->save or die $userpic_asset->errstr;
                $author->userpic_asset_id( $asset_id );
                $author->save or die $author->errstr;
                $userpic_session->remove or die $userpic_session->errstr;
            }
            my $privs;
            # delete new user's privilege from cache
            delete MT::Request->instance->{ __stash }->{ '__perm_author_' }
                unless $author->id;
            my $perm = $author->permissions( 0 );
            $perm->permissions( 'view' );
            $perm->save
                or return $author->error(
                "Error saving permission: " . $perm->errstr );
            require MT::Role;
            my $role
                = MT::Role->load( { name => $plugin->translate( 'Members' ) } );
            my $registration_all
                = $plugin->get_config_value( 'members_registration_all' );
            if ($registration_all) {
                my $iter = MT::Blog->load_iter( { class => '*' } );
                while ( my $blog = $iter->() ) {
                    my $result
                        = association_link( $app, $author, $role, $blog );
                }
            }
            else {
                my $result = association_link( $app, $author, $role, $blog );
            }
            $param{ saved } = 1;
            $app->run_callbacks( 'members_post_save.new_user', $app,
                $author );
        }
    }
    my $send_email;
    if ( is_ua_mobile( $app ) ) {
        $send_email = $author->mobile_address if $author;
    }
    else {
        $send_email = $author->email if $author;
    }
    $param{ send_email } = $send_email;
    my $from          = Members::Util::_mail_from();
    my $notify2       = Members::Util::_mail_to();
    my %args          = ( blog => $blog, author => $author, );
    my $template_name = 'members_signup';
    if ( is_ua_keitai( $app ) ) {
        $template_name .= '_mobile';
    }
    my $tmpl = Members::Callbacks::_load_tmpl( $app, $blog, $template_name );
    my $signup_success = 0;
    my $login_url;
    unless ( $error ) {
        if ( $type && $type eq 'regist' ) {
            unless ( $author ) {
                return $app->trans_error( 'Invalid request.' );
            }
            $param{registered} = 1;
            my $registration_status
                = $plugin->get_config_value( 'members_registration_status')
                || 3;
            $author->status( $registration_status );
            $param{ registration_status } = $registration_status;
            if ( is_ua_keitai( $app ) ) {
                $author->is_mobile_signup( 1 );
            }
            $author->save or die $author->errstr;
            $app->run_callbacks( 'members_post_registration', $app, $author );
            my $template;
            if ( $registration_status == MT::Author::PENDING() ) {
                $template = Members::Callbacks::_load_tmpl( $app, $blog,
                    'members_notify_a_p' );
            }
            elsif ( $registration_status == MT::Author::ACTIVE() ) {
                $template = Members::Callbacks::_load_tmpl( $app, $blog,
                    'members_notify_a_s' );
                my $return_url = site_url( $blog ) . '/';
                if ( $author->is_mobile_signup ) {
                    my $template_mobile_main_index
                        = MT->model( 'template' )->load(
                        {   blog_id    => $blog_id,
                            identifier => 'mobile_main_index'
                                . (
                                $blog->class eq 'website' ? '_website' : ''
                                ),
                            type => 'index',
                        }
                        );
                    if ( $template_mobile_main_index ) {
                        my $outfile = $template_mobile_main_index->outfile;
                        $return_url .= $outfile;
                    }
                }
                $login_url = $app->base
                    . $app->uri(
                    mode => 'view',
                    args => {
                        blog_id    => $blog_id,
                        return_url => $return_url,
                    }
                    );
                my %mail_params = ( login_url => $login_url,
                                    registration_status => MT::Author::ACTIVE(),
                                  );
                my $template = Members::Callbacks::_load_tmpl( $app, $blog,
                    'members_notify_u_t' );
                my $from = Members::Util::_mail_from();
                my $body = build_tmpl( $app, @$template[0], \%args,
                    \%mail_params );
                my $subject = build_tmpl( $app, @$template[1], \%args,
                    \%mail_params );
                my $email = $author->email;
                if ( is_ua_mobile( $app ) ) {
                    $email = $author->mobile_address;
                }
                my $result = send_mail( $from, $email, $subject, $body );
                $signup_success++;
            }
            my $send_notify2 = 1;
            if ( $registration_status == MT::Author::ACTIVE() && ! $plugin->get_config_value( 'members_email_notify2_active' ) ) {
                $send_notify2 = 0;
            }
            if ( $send_notify2 ) {
                my $mail_body = @$template[ 0 ];
                my $subject   = @$template[ 1 ];
                my $user_url  = '';
                {
                    local $app->{ is_admin } = 1;
                    $user_url .= $app->base . $app->mt_uri
                }
                $user_url .= '?__mode=view&_type=author&id=' . $author->id;
                my %mail_param = ( user_url => $user_url );
                $mail_body = build_tmpl( $app, $mail_body, \%args, \%mail_param );
                $subject = build_tmpl( $app, $subject, \%args );
                my $result = send_mail( $from, $notify2, $subject, $mail_body );
            }
        }
        else {
            my $token = $app->make_magic_token;
            my $sess = MT::Session->new;
            $sess->id( $token );
            $sess->start( time );
            $sess->kind( 'MM' );
            $sess->name( $author->id );
            $sess->save or die $sess->errstr;
            my $register_url = $app->base
                . $app->uri(
                mode => 'do_signup',
                args => {
                    type        => 'regist',
                    blog_id     => $blog_id,
                    author_id   => $author->id,
                    magic_token => $token,
                }
                );
            my $mail_param = +{
                register_url => $register_url,
                regist_url   => $register_url,
            };
            my $template = Members::Callbacks::_load_tmpl( $app, $blog,
                'members_notify_u_c' );
            my $mail_body = @$template[0];
            my $subject   = @$template[1];
            $mail_body = build_tmpl( $app, $mail_body, \%args, $mail_param );
            $subject   = build_tmpl( $app, $subject,   \%args, $mail_param );
            my $result
                = send_mail( $from, $send_email, $subject, $mail_body );
        }
    }
    $param{ static_uri } = $app->config->StaticWebPath;
    my %cf_param = (
        object_type => 'author',
        simple      => 1,
    );
    $param{ field_loop } = field_loop( %cf_param );
    my $q = $app->param;
    my @query_params;
    for my $key ( $q->param ) {
        push( @query_params, { $key => $q->param( $key ) } );
    }
    $param{query_params} = \@query_params;
    if ( $signup_success ) {
        $param{ login_url } = $login_url;
    }
    return build_tmpl( $app, @$tmpl[0], \%args, \%param );

    # $tmpl = File::Spec->catfile( $app->config( 'TemplatePath' ),
    #                                            'comment', 'signup.tmpl' );
    # return $app->build_page( $tmpl, \%param );
}

sub __view_session_check {
    my $app    = shift;
    my $author = $app->user
        or return;
    my $sess = $app->session
        or return;
    my $sess_timeout = $app->component( 'Members')
        ->get_config_value( 'members_session_timeout')
        || 3600;
    if ( ( time - $sess->start ) < $sess_timeout ) {
        return 1;
    }
    return; # TIMEOUT
}

sub _view {
    my $app = shift;
    unless ( $app->blog ) {
        return $app->trans_error( 'Invalid request' );
    }
    my $return_url = $app->param( 'return_url' );
    $return_url = site_url( $app->blog ) . '/' unless $return_url;
    my $sessid = $app->param( 'sessid' );
    if ( __view_session_check( $app ) ) {
        $app->make_commenter_session( $app->user );
        return $app->trans_error( 'Permission denied.')
            unless is_user_can( $app->blog, $app->user, 'view' );
        $app->run_callbacks( 'members_pre_login.user',
            $app, $app->blog, $app->user )
            || return $app->trans_error( 'Permission denied.' );
        if ( $sessid && is_ua_keitai( $app ) ) {
            if ( $return_url !~ m/\?/ ) {
                $return_url .= '?';
            }
            $app->redirect( $return_url . 'sessid=' . $sessid );
        }
        else {
            my $sep = $return_url =~ /\?/ ? '&' : '?';
            $return_url .= $sep . '_login=1#_login';
            $app->redirect( $return_url );
        }
    }
    else {
        require MT::Auth;
        MT::Auth->invalidate_credentials( { app => $app } );
        my %param;
        my $blog    = $app->blog;
        my %args    = ( blog => $blog );
        my $blog_id = $blog->id;
        $param{blog_id} = $blog_id;
        my $template_name = 'members_login';

        if ( is_ua_keitai( $app ) ) {
            $template_name .= '_mobile';
        }
        my $tmpl
            = Members::Callbacks::_load_tmpl( $app, $blog, $template_name );
        return build_tmpl( $app, @$tmpl[0], \%args, \%param );
    }
}

sub _login {
    my $app     = shift;
    my $plugin  = MT->component( 'Members' );
    my $ua      = $app->get_header( 'User-Agent' );
    my $blog_id = $app->param( 'blog_id' );
    if ( $ua =~ /(?:^Opera|Mozilla)/ ) {
        if ( $app->user ) {
            my $return_url = $app->base
                . $app->uri(
                mode => 'view',
                args => { blog_id => $blog_id }
                );
            my $return_param = $app->param( 'return_url' );
            if ( $return_param ) {
                $return_url .= '&return_url=' . MT::Util::encode_url( $return_param );
            }
            if ( $ua =~ /Nokia/ ) {
                $app->set_header( 'Location', $return_url );
                return 1;
            }
            return $app->redirect( $return_url );
        }
    }
    my $type = $app->param( 'type' );
    my $author;
    if ( $type && $type eq 'easy' ) {
        my $mobile_id = get_mobile_id( $app );
        my @authors = MT::Author->search_by_meta( mobile_id => $mobile_id );
        $app->trans_error( $plugin->translate( 'Unknown user') )
            unless @authors;
        $author = $authors[0];
        return $app->trans_error( $plugin->translate( 'Unknown user') )
            if $author->status != MT::Author::ACTIVE();
    }
    else {
        my $username = $app->param( 'username' );
        my $password = $app->param( 'password' );
        if ( is_ua_keitai( $app ) ) {
            unless ($username) {
                if ( $app->blog ) {
                    my $template
                        = Members::Callbacks::_load_tmpl( $app, $app->blog,
                        'members_login_mobile' );
                    my %args  = ( blog       => $app->blog );
                    my %param = ( return_url => $app->param( 'next_uri') );
                    return build_tmpl( $app, @$template[0], \%args, \%param );
                }
            }
        }
        $author = MT::Author->load( { name => $username } );
        return $app->trans_error( $plugin->translate( 'Unknown user') )
            unless defined $author;
        return $app->trans_error( $plugin->translate( 'Invalid password') )
            unless $author->is_valid_password($password);
        return $app->trans_error( $plugin->translate( 'Unknown user') )
            if $author->status != MT::Author::ACTIVE();
    }
    return $app->trans_error( 'Permission denied.')
        unless is_user_can( $app->blog, $author, 'view' );
    my $sess = MT::Session->get_by_key(
        {   email => $author->email,
            name  => $author->name,
            kind  => 'US'
        }
    );
    $sess->start(time);
    unless ( $sess->id ) {
        $sess->id( $app->make_magic_token );
    }
    if ( is_ua_keitai( $app ) ) {
        $sess->set( 'author_id', $author->id );
    }
    $sess->save or return die $sess->errstr;
    $app->make_commenter_session( $author );
    my $return_url = $app->param( 'return_url' );

# unless ( $return_url ) {
#     $return_url = $app->base . $app->uri( mode => 'view',
#                                           args => { blog_id => $blog_id, sessid => $sess->id } );
# }
    $return_url = site_url( $app->blog ) . '/' unless $return_url;
    if ( $return_url !~ m/\?/ ) {
        $return_url .= '?';
    }
    $return_url .= '&sessid=' . $sess->id;
    if ( $ua =~ /Nokia/ ) {
        $app->set_header( 'Location', $return_url );
        return 1;
    }
    $app->set_header( 'Content-Type' => 'text/html' ); # for SoftBank mobile
    return $app->redirect($return_url);
}

sub _mk_view_logout_return_url {
    my ($app, $flag) = @_;
    my $blog_id = $app->param( 'blog_id' );
    $blog_id = undef if ( $blog_id !~ /^[0-9]{1,}$/ );
    if ( !defined($blog_id) && $app->blog ) {
        $blog_id = $app->blog->id;
    }
    return $app->base
        . $app->uri(
        mode => 'view',
        args => { blog_id => $blog_id, ( $flag ? ( $flag => 1 ) : () ) }
        );
}

sub _logout {
    my $app = shift;
    my $ua  = $app->get_header( 'User-Agent' );
    if ( $ua =~ /(?:^Opera|Mozilla)/ ) {
        $app->logout();
    }
    my $sessid = $app->param( 'sessid' );
    my $sess   = MT::Session->load(
        {   id   => $sessid,
            kind => 'US'
        }
    );
    if ( defined $sess ) {
        $sess->remove or die $sess->errstr;
    }
    my $return_url = $app->param( 'return_url' );
    $return_url = _mk_view_logout_return_url( $app, 'logout' ) unless $return_url;
    if ( $ua =~ /Nokia/ ) {
        $app->set_header( 'Location', $return_url );
        return 1;
    }
    return $app->redirect($return_url);
}

sub _redirect {
    my $app = shift;
    unless ( $app->blog ) {
        return $app->trans_error( 'Invalid request' );
    }
    my $blog   = $app->blog;
    my $url    = $app->param( 'url' );
    my %args   = ( blog => $blog );
    my %params = ( url  => $url );
    my $template = Members::Callbacks::_load_tmpl( $app, $blog,
        'members_redirector_mobile' );
    return build_tmpl( $app, @$template[0], \%args, \%params );
}

sub _secedes_confirm {
    my $app = shift;
    my $user = $app->user
        or return $app->trans_error( 'Invalid request.' );
    if ( $user->is_superuser ) {
        return $app->trans_error( 'Invalid request.' );
    }
    my $blog = $app->blog;
    my %args = ( blog => $blog,
                 author => $user );
    my %params = ( script_url => $app->base . $app->uri,
                   sessid => $app->param( 'sessid' ) );
    my $template_name = 'members_s_c';
    if ( is_ua_keitai( $app ) ) {
        $template_name .= '_mobile';
    }
    my $template = Members::Callbacks::_load_tmpl( $app, $blog,
                                                        $template_name );
    return build_tmpl( $app, @$template[0], \%args, \%params );
}

sub _secedes {
    my $app = shift;
    my $user = $app->user
        or return $app->trans_error( 'Invalid request.' );
    if ( $user->is_superuser ) {
        return $app->trans_error( 'Invalid request.' );
    }
    $app->validate_magic() or return $app->trans_error( 'Invalid request.' );
    my $return_url = $app->param( 'return_url' ) ||
                     _mk_view_logout_return_url( $app, 'secedes' );
    if (! $app->run_callbacks( 'members_pre_secedes.user',
                                    $app, \$user ) ) {
        return $app->trans_error( 'Invalid request.' );
    }
    $user->status( MT::Author::INACTIVE () );
    $user->save or die $user->errstr;
    $app->run_callbacks( 'members_post_secedes.user', $app, \$user, \$return_url );
    if (! $return_url ) {
        if ( my $blog = $app->blog ) {
            $return_url = $blog->site_url;
        } else {
            $return_url = $app->base . '/';
        }
    }
    $app->redirect( $return_url );
}

sub _get_author {
    my ( $app, $sessid ) = @_;
    my $author;
    my $sess = MT::Session->load(
        {   id   => $sessid,
            kind => 'US'
        }
    );
    if ( defined $sess ) {
        my $plugin       = MT->component( 'Members' );
        my $sess_timeout = (
              $plugin
            ? $plugin->get_config_value( 'members_session_timeout')
            : 3600
        );
        if ( ( time - $sess->start ) < $sess_timeout ) {
            $author = MT::Author->load( { name => $sess->name } );
            $sess->start(time);
            $sess->save or die $sess->errstr;
        }
        else {
            my $return_url = _mk_view_logout_return_url( $app );
            $sess->remove or die $sess->errstr;
            require MT::Auth;
            MT::Auth->invalidate_credentials( { app => $app } );
            $app->redirect($return_url);
        }
    }
    if ($author) {
        if ( $app->blog ) {
            if ( !is_user_can( $app->blog, $author, 'view' ) ) {
                $sess->remove if $sess;
                return undef;
            }
        }
    }
    return $author;
}

1;
