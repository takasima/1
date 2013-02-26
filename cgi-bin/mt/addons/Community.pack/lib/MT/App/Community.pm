# Movable Type (r) (C) 2007-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package MT::App::Community;

use strict;
use base qw( MT::App );
use MT::I18N qw( encode_text );
use MT::Util
    qw( remove_html multi_iter encode_js is_valid_email is_url encode_url decode_url epoch2ts ts2epoch format_ts dirify encode_html );
use MT::Entry qw( :constants );
use MT::Log qw( :constants );
use MT::Author qw( :constants );
use MT::Promise qw( delay );
use CustomFields::Util qw( field_loop );
use HTTP::Date qw(time2isoz time2str str2time);

use constant NAMESPACE => 'community_pack_recommend';

sub id {'community'}

sub script_name { MT->config->CommunityScript }

sub init {
    my $app = shift;
    $app->SUPER::init(@_);
    $app->{default_mode}         = 'view';
    $app->{plugin_template_path} = '';
    $app;
}

sub init_request {
    my $app = shift;
    $app->SUPER::init_request(@_);

    # Global 'blog_id' parameter check; if we get something
    # other than an integer, die
    if ( my $blog_id = $app->param('blog_id') ) {
        if ( $blog_id ne int($blog_id) ) {
            die $app->translate("Invalid request");
        }
    }
}

sub validate_magic {
    my $app = shift;
    return 1
        if $app->param('username')
            && $app->param('password')
            && $app->request('fresh_login');
    return undef
        unless ( $app->current_magic || '' ) eq
        ( $app->param('magic_token') || '' );
    1;
}

sub jsonp_result {
    my $app = shift;
    my ( $result, $jsonp ) = @_;
    return $app->errtrans("Invalid request.")
        unless $jsonp =~ m/^[0-9a-zA-Z_.]+$/;
    $app->send_http_header("text/javascript+json");
    $app->{no_print_body} = 1;
    my $json = MT::Util::to_json($result);
    $app->print("$jsonp($json);");
    return undef;
}

sub jsonp_error {
    my $app = shift;
    my ( $error, $jsonp ) = @_;
    return $app->errtrans("Invalid request.")
        unless $jsonp =~ m/^[0-9a-zA-Z_.]+$/;
    $app->send_http_header("text/javascript+json");
    $app->{no_print_body} = 1;
    my $json = MT::Util::to_json( { error => $error } );
    $app->print("$jsonp($json);");
    return undef;
}

sub _login_user_commenter {
    my $app = shift;
    my $user;

    # Check if commenter is logged in
    my %cookies     = $app->cookies();
    my $cookie_name = $app->commenter_session_cookie_name;
    if ( !$cookies{$cookie_name} ) {
        return undef;
    }
    my $state
        = $app->unbake_user_state_cookie( $cookies{$cookie_name}->value() );
    my $session_key = $state->{sid} || '';
    $session_key =~ y/+/ /;
    require MT::Session;
    my $sess_obj = MT::Session->load( { id => $session_key } );
    my $timeout = $app->config->CommentSessionTimeout;

    if ($sess_obj) {
        $app->{session} = $sess_obj;
        if ( $user
            = $app->model('author')->load( { name => $sess_obj->name } ) )
        {
            $app->user($user);
            return $user;
        }
        elsif ( $sess_obj->start() + $timeout < time ) {
            delete $app->{session};
            $app->_invalidate_commenter_session( \%cookies );
            return undef;
        }
    }
    return $user;
}

sub check_perm_js {
    my $app  = shift;
    my $q    = $app->param;
    my $user = $app->_login_user_commenter();
    return $app->json_error( $app->translate("Invalid request.") )
        unless $user;

    my $blog;
    my $blog_id = $q->param('blog_id');
    if ( defined($blog_id) && $blog_id ) {
        return $app->json_error( $app->translate("Invalid request.") )
            unless ( $blog_id =~ m/\d+/ );
        $blog = $app->model('blog.community')->load($blog_id)
            or return $app->json_error( $app->translate("Invalid request.") );
    }

    my $perm = $user->permissions($blog_id);
    if (   $user->is_superuser
        || $perm->can_comment )
    {
        my %c = $app->cookies;
        my ($cmntr_id) = split ';', $c{'commenter_id'};
        my @cmntr_id = split '=', $cmntr_id;
        $cmntr_id = decode_url( $cmntr_id[1] );

        my %id_kookee = (
            -name  => "commenter_id",
            -value => $cmntr_id . qq{,\'$blog_id\'},
            -path  => '/'
        );
        $app->bake_cookie(%id_kookee);

        return $app->json_result( { blog_id => $blog_id } );
    }
    return $app->json_result( {} );
}

sub public_login {
    my $app = shift;
    my $q   = $app->param;
    my %opt = @_;

    require MT::Lockout;
    if ( MT::Lockout->is_locked_out( $app, $app->remote_ip ) ) {
        $app->{hide_goback_button} = 1;
        return $app->errtrans("Invalid request");
    }

    $opt{error} = encode_html( $q->param('error') )
        if defined $q->param('error');

    my $blog;
    my $blog_id = $q->param('blog_id');
    if ( defined($blog_id) && $blog_id ) {
        return $app->errtrans("Invalid parameter")
            unless ( $blog_id =~ m/\d+/ );
        $blog = $app->model('blog.community')->load($blog_id)
            or return $app->errtrans("Invalid parameter");
    }

    my $return_to = $q->param('return_to') || $q->param('return_url');
    if ($return_to) {
        $return_to = remove_html($return_to);
        return $app->errtrans('Invalid request.')
            unless is_url($return_to);
    }

    my $tmpl = $app->load_global_tmpl( 'login_form', $blog_id )
        or return $app->errtrans("No login form template defined");
    my $param = {
        blog_id   => $blog_id,
        return_to => $return_to,
    };
    my $cfg = $app->config;
    if ( my $registration = $cfg->CommenterRegistration ) {
        if ( $cfg->AuthenticationModule eq 'MT' ) {
            $param->{registration_allowed} = $registration->{Allow} ? 1 : 0;
            $param->{registration_allowed} = 0
                if ( $blog && !$blog->allow_commenter_regist );
        }
    }
    $param->{ 'auth_mode_' . $cfg->AuthenticationModule } = 1;
    require MT::Auth;
    $param->{can_recover_password} = MT::Auth->can_recover_password;
    $param->{error} = $opt{error} if exists $opt{error};
    $param->{message} = $app->param('message') if $app->param('message');
    $param->{error}   = $param->{error};
    $param->{message} = encode_html( $param->{message} );
    $param->{system_template} = 1;

    if ( !$blog ) {
        require MT::Blog;
        $blog = MT::Blog->new();
        $blog->commenter_authenticators( MT->config('DefaultCommenterAuth') );
    }

    my $external_authenticators
        = $app->external_authenticators( $blog, $param );

    if (@$external_authenticators) {
        $param->{auth_loop}      = $external_authenticators;
        $param->{default_signin} = $external_authenticators->[0]->{key}
            unless exists $param->{default_signin};
    }

    $tmpl->param($param);
    $tmpl;
}
*login_form = \&public_login;    # for compatibility with MT::App::Comments

sub login_external {
    my $app = shift;
    my $q   = $app->param;

    my $authenticator = MT->commenter_authenticator( $q->param('key') );
    my $auth_class    = $authenticator->{class};
    eval "require $auth_class;";
    if ( my $e = $@ ) {
        return $app->error($e);
    }
    if ( !$q->param('static') ) {
        my $cfg = $app->config;
        my $url
            = $q->param('return_url')
            || $cfg->ReturnToURL
            ? $cfg->ReturnToURL
            : $app->uri( mode => 'edit' );
        $app->param( 'static', $url );
    }
    $auth_class->login($app);
}

sub login_pending {
    my $app  = shift;
    my $q    = $app->param;
    my $user = $app->user;
    return q() unless $user;

    my $blog;
    my $blog_id = $q->param('blog_id');
    if ( defined($blog_id) && $blog_id ) {
        return $app->errtrans("Invalid parameter")
            unless ( $blog_id =~ m/\d+/ );
        $blog = $app->model('blog.community')->load($blog_id)
            or return $app->errtrans("Invalid parameter");
    }

    my $return_to = $q->param('return_to');
    if ($return_to) {
        $return_to = remove_html($return_to);
        return $app->errtrans('Invalid request.')
            unless is_url($return_to);
    }
    else {
        my $cfg = $app->config;
        $return_to
            = $cfg->ReturnToURL
            ? $cfg->ReturnToURL
            : q();
    }

    my $cgi_path = $app->config('CGIPath');
    $cgi_path .= '/' unless $cgi_path =~ m!/$!;
    my $url 
        = $cgi_path 
        . $app->config->CommunityScript
        . $app->uri_params(
        'mode' => 'resend_auth',
        args   => {
            'return_to' => $return_to,
            'id'        => $user->id,
            $blog ? ( 'blog_id' => $blog_id ) : (),
        },
        );

    if ( ( $url =~ m!^/! ) && $blog ) {
        my ($blog_domain) = $blog->site_url =~ m|(.+://[^/]+)|;
        $url = $blog_domain . $url;
    }

    $app->translate(
        'Before you can sign in, you must authenticate your email address. <a href="[_1]">Click here</a> to resend the verification email.',
        $url
    );
}

sub commenter_loggedin {
    my $app = shift;
    my $q   = $app->param;
    my ( $commenter, $commenter_blog_id ) = @_;

    my $return_to = $q->param('return_to') || $q->param('return_url');
    if ($return_to) {
        $return_to = remove_html($return_to);
        $return_to =~ s/#.*//;
        return $app->errtrans('Invalid request.')
            unless is_url($return_to);
    }

    my $url;
    my $sess = $app->make_commenter_session($commenter);
    my $ott  = MT->model('session')->new();
    $ott->kind('OT');    # One time Token
    $ott->id( MT::App::make_magic_token() );
    $ott->start(time);
    $ott->duration( time + 5 * 60 );
    $ott->set( sid => $sess );
    $ott->save
        or return $app->error(
        $app->translate(
            "The login could not be confirmed because of a database error ([_1])",
            $ott->errstr
        )
        );

    if ($return_to) {
        $url = $return_to . '#_login_' . $ott->id;
        unless ( $app->is_valid_redirect_target ) {
            return $app->error(
                $app->translate(
                    q{You are trying to redirect to external resources: [_1]},
                    encode_html($return_to)
                )
            );
        }
    }
    else {
        if ($commenter_blog_id) {
            my $blog
                = $app->model('blog.community')->load( $q->param('blog_id') )
                or return $app->errtrans("Invalid parameter");
            $url = $blog->site_url . '#_login_' . $ott->id;
        }
        else {
            my $cfg = $app->config;
            $url
                = $cfg->ReturnToURL
                ? $cfg->ReturnToURL
                : $app->uri( mode => 'edit' );
        }
    }
    return $url if $url;
    $app->SUPER::commenter_loggedin(@_);
}

# FIXME: copied over from MT::App::Comments
sub _create_commenter_assign_role {
    my $app = shift;
    my ($blog_id) = @_;
    require MT::Auth;
    my $error = MT::Auth->sanity_check($app);
    if ($error) {
        $app->log(
            {   message  => $error,
                level    => MT::Log::ERROR(),
                class    => 'system',
                category => 'register_commenter'
            }
        );
        return undef;
    }
    my $commenter = $app->model('author')->new;
    $commenter->name( $app->param('username') );
    $commenter->nickname( $app->param('nickname') );
    $commenter->set_password( $app->param('password') );
    $commenter->email( $app->param('email') );
    $commenter->external_id( $app->param('external_id') );
    $commenter->type( MT::Author::AUTHOR() );
    $commenter->status( MT::Author::ACTIVE() );
    $commenter->auth_type( $app->config->AuthenticationModule );
    return undef unless ( $commenter->save );

    $commenter->add_default_roles;
    my $flip = 1;
    my $have_default_roles
        = grep { $_ == $blog_id }
        map { ( $flip = !$flip ) ? $_ : () }
        split ',', MT->config->DefaultAssignments;

    if ( not $have_default_roles ) {
        require MT::Role;
        require MT::Association;
        my $role = MT::Role->load_same( undef, undef, 1, 'comment' );
        my $blog = MT::Blog->load($blog_id);
        if ( $role && $blog ) {
            MT::Association->link( $commenter => $role => $blog );
        }
        else {
            my $blog_name = $blog ? $blog->name : '(Blog not found)';
            $app->log(
                {   message => MT->translate(
                        "Error assigning commenting rights to user '[_1] (ID: [_2])' for weblog '[_3] (ID: [_4])'. No suitable commenting role was found.",
                        $commenter->name, $commenter->id,
                        $blog_name,       $blog->id,
                    ),
                    level    => MT::Log::ERROR(),
                    class    => 'system',
                    category => 'new'
                }
            );
        }
    }
    $app->user($commenter);
    $commenter;
}

# FIXME: mostly copied over from MT::App::Comments
sub do_login {
    my $app     = shift;
    my $q       = $app->param;
    my $name    = $q->param('username');
    my $blog_id = $q->param('blog_id');
    my $blog    = MT::Blog->load($blog_id) if ( defined $blog_id );
    my $auths   = $blog->commenter_authenticators if $blog;
    if ( $blog && $auths !~ /MovableType/ ) {
        $app->log(
            {   message => $app->translate(
                    'Invalid commenter login attempt from [_1] to blog [_2](ID: [_3]) which does not allow Movable Type native authentication.',
                    $name, $blog->name, $blog_id
                ),
                level    => MT::Log::WARNING(),
                category => 'login_commenter',
            }
        );
        return $app->login_form( error => $app->translate('Invalid login.') );
    }

    require MT::Auth;
    my $ctx = MT::Auth->fetch_credentials( { app => $app } );
    $ctx->{blog_id} = $blog_id;
    my $result = MT::Auth->validate_credentials($ctx);
    my ( $message, $error );
    if (   ( MT::Auth::NEW_LOGIN() == $result )
        || ( MT::Auth::NEW_USER() == $result )
        || ( MT::Auth::SUCCESS() == $result ) )
    {
        my $commenter = $app->user;
        if ( $q->param('external_auth') && !$commenter ) {
            $app->param( 'name', $name );
            if ( MT::Auth::NEW_USER() == $result ) {
                $commenter = $app->_create_commenter_assign_role(
                    $q->param('blog_id') );
                return $app->login_form(
                    error => $app->translate('Invalid login') )
                    unless $commenter;
            }
            elsif ( MT::Auth::NEW_LOGIN() == $result ) {
                my $registration = $app->config->CommenterRegistration;
                unless (
                       $registration
                    && $registration->{Allow}
                    && ( $app->config->ExternalUserManagement
                        || ( $blog && $blog->allow_commenter_regist ) )
                    )
                {
                    return $app->login_form(
                        error => $app->translate(
                            'Successfully authenticated but signing up is not allowed.  Please contact system administrator.'
                        )
                    ) unless $commenter;
                }
                else {
                    return $app->login_form(
                        error => $app->translate('You need to sign up first.')
                    ) unless $commenter;
                }
            }
        }
        MT::Auth->new_login( $app, $commenter );
        if ( $app->_check_commenter_author( $commenter, $blog_id ) ) {
            my $return_to = $app->commenter_loggedin( $commenter, $blog_id );
            if ( !$return_to ) {
                return $app->load_tmpl(
                    'error.tmpl',
                    {   error              => $app->errstr,
                        hide_goback_button => 1,
                    }
                );
            }

            return $app->redirect($return_to);
        }
        $error   = $app->translate("Permission denied.");
        $message = $app->translate(
            "Login failed: permission denied for user '[_1]'", $name );
    }
    elsif ( MT::Auth::PENDING() == $result ) {

        # Login invalid; auth layer reports user was pending
        # Check if registration is allowed and if so send special message
        if ( my $registration = $app->config->CommenterRegistration ) {
            if ( $registration->{Allow} ) {
                $error = $app->login_pending();
            }
        }
        $error
            ||= $app->translate(
            'This account has been disabled. Please see your Movable Type system administrator for access.'
            );
        $app->user(undef);
        $app->log(
            {   message => $app->translate(
                    "Failed login attempt by pending user '[_1]'", $name
                ),
                level    => MT::Log::WARNING(),
                category => 'login_user',
            }
        );
    }
    elsif (MT::Auth::INVALID_PASSWORD() == $result
        || MT::Auth::SESSION_EXPIRED() == $result )
    {
        $message = $app->translate(
            "Login failed: password was wrong for user '[_1]'", $name );
    }
    elsif ( MT::Auth::INACTIVE() == $result ) {
        $message
            = $app->translate( "Failed login attempt by disabled user '[_1]'",
            $name );
    }
    elsif ( MT::Auth::LOCKED_OUT() == $result ) {
        $message = $app->translate('Invalid login.');
    }
    else {
        $message
            = $app->translate( "Failed login attempt by unknown user '[_1]'",
            $name );
    }
    $app->log(
        {   message  => $message,
            level    => MT::Log::SECURITY(),
            category => 'login_commenter',
        }
    ) if $message;
    $ctx->{app} ||= $app;
    MT::Auth->invalidate_credentials($ctx);
    return $app->login_form( error => $error
            || $app->translate("Invalid login") );
}

# FIXME: copied over from MT::App::Comments
sub _check_commenter_author {
    my $app = shift;
    my ( $commenter, $blog_id ) = @_;

    return 1 unless $blog_id;

    # Using MT::Author::commenter_status here, since it also
    # takes the permission "restrictions" into account.
    my $status = $commenter->commenter_status($blog_id);

    # INACTIVE == BANNED
    return 0 if $status == MT::Author::BANNED();
    return 0 if $commenter->status == MT::Author::BANNED();

    # NOT using $status for this test, since $status may be
    # assigned 'PENDING' by 'commenter_status' if no permission
    # record exists at all. We want to check below to see if
    # commenting permission is auto-vivified based on blog configuration
    # in such a case.
    if ( MT::Author::PENDING() == $commenter->status() ) {
        $app->error(
            $app->translate(
                "Failed comment attempt by pending registrant '[_1]'",
                $commenter->name
            )
        );
        return 0;
    }
    elsif ( $commenter->blog_perm($blog_id)->can_comment ) {
        return 1;
    }
    else {

        # No explicit permissions are given for this commenter, so
        # see if blog is configured as "open to registration" for
        # commenting. If it is, auto-assign commenting permissions
        # for this blog only.
        if ( my $registration = $app->config->CommenterRegistration ) {
            my $blog = MT::Blog->load($blog_id)
                or return $app->error(
                $app->translate( 'Cannot load blog #[_1].', $blog_id ) );
            if ($registration->{Allow}
                && (   $app->config->ExternalUserManagement
                    || $blog->allow_commenter_regist )
                )
            {

                # By policy, this blog permits this type of user
                # and they are not banned (as they have no blog perms/
                # restrictions, so permit this comment)
                return 1;
            }
        }
    }
    $app->error(
        $app->translate(
            "Login failed: permission denied for user '[_1]'",
            $commenter->name
        )
    );
    return 0;
}

sub logout {
    my $app = shift;
    my $q   = $app->param;

    my $return_to = $q->param('return_to') || $q->param('return_url');
    if ($return_to) {
        $return_to = remove_html($return_to);
        $return_to =~ s/#.+//;
        return $app->errtrans('Invalid request.')
            unless is_url($return_to);
    }

    $app->SUPER::logout();

    return $app->redirect( $return_to . '#_logout' );
}

sub redirect_to_target {
    my $app = shift;
    my $q   = $app->param;

    my $cfg = $app->config;
    my $target;
    require MT::Util;
    my $static = $q->param('static') || $q->param('return_url') || '';

    if ( ( $static eq '' ) || ( $static eq '1' ) ) {
        require MT::Entry;
        my $entry = MT::Entry->load( $q->param('entry_id') || 0 )
            or return $app->error(
            $app->translate(
                'Cannot load entry #[_1].',
                $q->param('entry_id')
            )
            );
        $target = $entry->archive_url;
    }
    elsif ( $static ne '' ) {
        $target = $static;
    }
    if ( $q->param('logout') ) {
        if ( $app->user
            && ( 'TypeKey' eq $app->user->auth_type ) )
        {
            return $app->redirect(
                $cfg->SignOffURL
                    . "&_return="
                    . MT::Util::encode_url( $target . '#_logout' ),
                UseMeta => 1
            );
        }
    }
    $target =~ s!#.*$!!;    # strip off any existing anchor
    return $app->redirect(
        $target . '#_' . ( $q->param('logout') ? 'logout' : 'login' ),
        UseMeta => 1 );
}

sub register {
    my $app  = shift;
    my %opts = @_;
    my $q    = $app->param;

    my $blog;
    my $blog_id = $q->param('blog_id');
    if ( defined($blog_id) && $blog_id ) {
        return $app->errtrans("Invalid parameter")
            unless ( $blog_id =~ m/\d+/ );
        $blog = $app->model('blog.community')->load($blog_id)
            or return $app->errtrans("Invalid parameter");
    }

    my $return_to = $q->param('return_to');
    if ($return_to) {
        $return_to = remove_html($return_to);
        return $app->errtrans('Invalid request.')
            unless is_url($return_to);
    }

    my $param = {
        blog_id   => $blog_id,
        return_to => $return_to,
        %opts,
    };

    my $cfg          = $app->config;
    my $registration = $cfg->CommenterRegistration
        or return $app->errtrans("Invalid parameter");

    return $app->errtrans('Signing up is not allowed.')
        unless $registration->{Allow}
            && ( !$blog || ( $blog && $blog->allow_commenter_regist ) );

    if (my $provider = MT->effective_captcha_provider(
            $blog ? $blog->captcha_provider : undef
        )
        )
    {
        $param->{captcha_fields}
            = $provider->form_fields( $blog ? $blog->id : undef );
    }
    $param->{ 'auth_mode_' . $cfg->AuthenticationModule } = 1;
    $param->{field_loop} = field_loop( object_type => 'author', simple => 1 );
    my $tmpl = $app->load_global_tmpl( 'register_form', $blog_id );
    $param->{system_template} = 1;
    $tmpl->param($param);
    return $tmpl;
}

sub do_register {
    my $app = shift;
    my $q   = $app->param;

    return $app->error( $app->translate("Invalid request") )
        if $app->request_method() ne 'POST';

    my $cfg   = $app->config;
    my $param = {};
    $param->{$_} = $q->param($_) foreach qw(email url username nickname);
    $param->{ 'auth_mode_' . $cfg->AuthenticationModule } = 1;

    my $return_to = remove_html( $q->param('return_to') )
        if $q->param('return_to');
    if ($return_to) {
        return $app->errtrans('Invalid request.')
            unless is_url($return_to);
    }
    else {
        $return_to
            = $cfg->ReturnToURL
            ? $cfg->ReturnToURL
            : q();
    }
    $param->{return_to} = $return_to
        if $return_to;
    if ($return_to) {
        $return_to = remove_html($return_to);
        return $app->errtrans('Invalid request.')
            unless is_url($return_to);
    }
    else {
        $return_to
            = $cfg->ReturnToURL
            ? $cfg->ReturnToURL
            : q();
    }
    $param->{return_to} = $return_to
        if $return_to;

    my $blog;
    my $blog_id = $q->param('blog_id');

    if ( defined($blog_id) && $blog_id ) {
        return $app->errtrans("Invalid parameter")
            unless ( $blog_id =~ m/\d+/ );
        $blog = $app->model('blog.community')->load($blog_id)
            or return $app->errtrans("Invalid parameter");
        $param->{blog_id} = $blog_id
            if $blog;
    }
    else {
        return $app->errtrans("Invalid request");
    }

    # Willingness of the Movable Type instance and the blog itself
    # to allow users to register must be checked before a pending
    # user is created.
    my $registration = $cfg->CommenterRegistration;

    return $app->errtrans("Invalid parameter")
        unless $registration;

    return $app->errtrans('Signing up is not allowed.')
        unless $registration->{Allow}
            && ( !$blog || ( $blog && $blog->allow_commenter_regist ) );

    my $filter_result = $app->run_callbacks( 'api_save_filter.author', $app );

    $app->param( 'name', $q->param('username') )
        ;    # using 'name' for checking user
    $app->param( 'pass', $q->param('password') )
        ;    # using 'pass' for matching password
    if ( lc( $cfg->AuthenticationModule ) eq 'mt' ) {
        my $error = __verify_password_strength( $app, $q->param('username'),
            scalar $q->param('pass') );
        $error ||= MT::Auth->sanity_check($app);
        if ($error) {
            $param->{error} = encode_html($error);
            return $app->forward( 'register', %$param );
        }
    }

    my $user;
    $user = $app->create_user_pending($param) if $filter_result;
    unless ($user) {
        $param->{error} = encode_html( $app->errstr );
        return $app->forward( 'register', %$param );
    }

    ## Assign default role
    $user->add_default_roles;

    my $original = $user->clone();
    $app->run_callbacks( 'api_post_save.author', $app, $user, $original );

    if ( $user->email ) {
        ## Send confirmation email in the background.
        MT::Util::start_background_task(
            sub {
                $app->_send_signup_confirmation(
                    $user->id, $user->email,
                    $return_to ? $return_to        : undef,
                    $blog      ? $param->{blog_id} : undef
                );
            }
        );
    }

    my $tmpl = $app->load_global_tmpl( 'register_confirmation', $blog_id );
    $tmpl->param(
        {   email => $user->email
            ? $user->email
            : $app->translate('(No email address)'),
            $return_to ? ( return_to => $return_to ) : (),
            $blog_id   ? ( blog_id   => $blog_id )   : (),
            system_template => 1,
        }
    );
    $tmpl;
}

sub resend_auth {
    my $app = shift;
    my $q   = $app->param;

    my $blog;
    my $blog_id = $q->param('blog_id');
    if ( defined($blog_id) && $blog_id ) {
        return $app->errtrans("Invalid parameter")
            unless ( $blog_id =~ m/\d+/ );
        $blog = $app->model('blog.community')->load($blog_id)
            or return $app->errtrans("Invalid parameter");
    }

    my $return_to = $q->param('return_to');
    if ($return_to) {
        $return_to = remove_html($return_to);
        return $app->errtrans('Invalid request.')
            unless is_url($return_to);
    }
    else {
        my $cfg = $app->config;
        $return_to
            = $cfg->ReturnToURL
            ? $cfg->ReturnToURL
            : q();
    }

    my $id   = $q->param('id');
    my $user = $app->model('author')->load($id)
        or return $app->errtrans("Invalid parameter");
    return $app->errtrans("Invalid parameter")
        if MT::Author::PENDING() != $user->status;

    # remove existing registration tokens for the user
    require MT::Session;
    my $sess
        = MT::Session->remove(
        { kind => 'CR', email => $user->email, name => $user->id },
        );

    ## Send confirmation email in the background.
    MT::Util::start_background_task(
        sub {
            $app->_send_signup_confirmation(
                $user->id, $user->email,
                $return_to ? $return_to : undef,
                $blog      ? $blog_id   : undef
            );
        }
    );

    my $tmpl = $app->load_global_tmpl( 'register_confirmation', $blog_id );
    $tmpl->param(
        {   email => $user->email,
            $return_to ? ( return_to => $return_to ) : (),
            resend => 1,
            $blog_id ? ( blog_id => $blog_id ) : (),
            system_template => 1,
        }
    );
    $tmpl;
}

sub _send_signup_confirmation {
    my $app = shift;
    my ( $id, $email, $return_to, $blog_id ) = @_;
    my $cfg = $app->config;

    my $blog;
    if ( defined $blog_id ) {
        $blog = $app->model('blog.community')->load($blog_id);
    }
    my $token = $app->make_magic_token;

    my $subject  = $app->translate('Movable Type Account Confirmation');
    my $cgi_path = $app->config('CGIPath');
    $cgi_path .= '/' unless $cgi_path =~ m!/$!;
    my $url 
        = $cgi_path 
        . $cfg->CommunityScript
        . $app->uri_params(
        'mode' => 'do_confirm',
        args   => {
            'token' => $token,
            'email' => $email,
            'id'    => $id,
            defined($blog_id)   ? ( 'blog_id'   => $blog_id )   : (),
            defined($return_to) ? ( 'return_to' => $return_to ) : (),
        },
        );

    if ( ( $url =~ m!^/! ) && $blog ) {
        my ($blog_domain) = $blog->site_url =~ m|(.+://[^/]+)|;
        $url = $blog_domain . $url;
    }

    my $body = $app->build_email( 'email_verification_email',
        { $blog ? ( blog => $blog ) : (), confirm_url => $url } );

    require MT::Mail;
    my $from_addr;
    my $reply_to;
    if ( $cfg->EmailReplyTo ) {
        $reply_to = $cfg->EmailAddressMain;
    }
    else {
        $from_addr = $cfg->EmailAddressMain;
    }
    $from_addr = undef if $from_addr && !is_valid_email($from_addr);
    $reply_to  = undef if $reply_to  && !is_valid_email($reply_to);

    unless ( $from_addr || $reply_to ) {
        $app->log(
            {   message =>
                    MT->translate("System Email Address is not configured."),
                level    => MT::Log::ERROR(),
                class    => 'system',
                category => 'email'
            }
        );
        return;
    }

    my %head = (
        id => 'email_verification_email',
        To => $email,
        $from_addr ? ( From       => $from_addr ) : (),
        $reply_to  ? ( 'Reply-To' => $reply_to )  : (),
        Subject => $subject,
    );
    my $charset = $cfg->MailEncoding || $cfg->PublishCharset;
    $head{'Content-Type'} = qq(text/plain; charset="$charset");

    ## Save it in session to purge later
    require MT::Session;
    my $sess = MT::Session->new;
    $sess->id($token);
    $sess->kind('CR');    # CR == Commenter Registration
    $sess->email($email);
    $sess->name($id);
    $sess->set( blog_id => $blog_id );
    $sess->start(time);
    $sess->save;

    MT::Mail->send( \%head, $body )
        or die MT::Mail->errstr();
}

sub do_confirm {
    my $app = shift;
    my $q   = $app->param;
    my $cfg = $app->config;

    my $q_blog_id = $q->param('blog_id');
    my $return_to = $q->param('return_to');
    my $email     = $q->param('email');
    my $token     = $q->param('token');
    my $user_id   = $q->param('id');

    if ($return_to) {
        return $app->errtrans('Invalid request.')
            unless $app->is_valid_redirect_target;
    }
    else {
        $return_to = $cfg->ReturnToURL || '';
    }

    ## Token expiration check
    require MT::Session;
    my $sess = MT::Session->load(
        { id => $token, kind => 'CR', email => $email, name => $user_id } );

    unless ($sess) {
        my $user = MT::Author->load($user_id) if $user_id;
        if ( $user && $user->status eq MT::Author::ACTIVE() ) {
            return $app->public_login();
        }
        else {
            $user->remove
                if $user;
            my $msg = $app->translate(
                'Your confirmation have expired. Please register again.');
            if ($return_to) {
                $msg .= '&nbsp;'
                    . $app->translate(
                    '<a href="[_1]">Return to the original page.</a>',
                    $return_to );
            }
            return $app->forward( 'register', message => $msg );
        }
    }
    $sess->remove;

    my $user = MT::Author->load( $sess->name );
    if ( $sess->start() < ( time - 60 * 60 * 24 ) ) {
        $user->remove;
        my $msg = $app->translate(
            'Your confirmation have expired. Please register again.');
        if ($return_to) {
            $msg .= '&nbsp;'
                . $app->translate(
                '<a href="[_1]">Return to the original page.</a>',
                $return_to );
        }
        return $app->forward( 'register', message => $msg );
    }

    my $error = sub {
        $user->remove;
        return $app->errtrans(@_);
    };

    my $blog_id = $sess->get('blog_id');

    return $error->("Invalid request.")
        unless $blog_id == $q_blog_id;

    my $blog;
    if ($blog_id) {
        $blog = $app->model('blog')->load($blog_id)
            or return $error->( 'Cannot load blog #[_1].', $blog_id );
        $app->blog($blog);
    }

    # Willingness of the Movable Type instance and the blog itself
    # to allow users to register must be checked before a pending
    # user is created.
    my $registration = $cfg->CommenterRegistration;

    return $error->("Invalid parameter")
        unless $registration;

    return $error->('Signing up is not allowed.')
        unless $registration->{Allow}
            && ( !$blog || $blog->allow_commenter_regist );

    $user->status( MT::Author::ACTIVE() );
    $user->save
        or return $app->forward( 'register', error => $user->errstr );

    $app->log(
        {   message => $app->translate(
                "User '[_1]' (ID:[_2]) has been successfully registered.",
                $user->name, $user->id
            ),
            level    => MT::Log::INFO(),
            class    => 'author',
            category => 'new',
        }
    );
    $user->add_default_roles();

    if ( $app->config->NewUserAutoProvisioning ) {

        # provision new user with a personal blog
        $app->run_callbacks( 'new_user_provisioning', $user );
    }

    if ( my $registration = $app->config->CommenterRegistration ) {
        if ( my $ids = $registration->{Notify} ) {
            ## Send notification email in the background.
            MT::Util::start_background_task(
                sub {
                    $app->_send_registration_notification( $user, $blog_id,
                        $ids );
                }
            );
        }
    }

    $app->param( 'message',
        $app->translate('Thanks for the confirmation.  Please sign in.') );
    $app->public_login();
}

sub _send_registration_notification {
    my $app = shift;
    my ( $user, $blog_id, $ids ) = @_;

    my $blog;
    if ($blog_id) {
        $blog = MT::Blog->load($blog_id);
    }
    my $subject;
    if ($blog) {
        $subject = $app->translate( "[_1] registered to the blog '[_2]'",
            $user->name, $blog->name );
    }
    else {
        $subject = $app->translate( "[_1] registered to Movable Type.",
            $user->name );
    }
    my $url = $app->mt_uri(
        mode => 'view',
        args => {
            '_type' => 'author',
            id      => $user->id
        }
    );

    if ( ( $url =~ m!^/! ) && $blog ) {
        my ($blog_domain) = $blog->site_url =~ m|(.+://[^/]+)|;
        $url = $blog_domain . $url;
    }

    my $body = $app->build_email(
        'register_notification_email',
        {   $blog ? ( blog => $blog ) : (),
            commenter   => $user,
            profile_url => $url
        }
    );

    $app->_send_sysadmins_email( $ids, 'register_notification', $body,
        $subject, $user->email );
}

sub start_recover {
    require MT::App::CMS;
    MT::App::CMS::start_recover(@_);
}

sub reset_password {
    require MT::CMS::Tools;
    return MT::CMS::Tools::reset_password(@_);
}

sub redirect_to_edit_profile {
    my $app = shift;
    return $app->redirect( $app->uri( mode => 'edit' ) );
}

sub loggedin_js {
    local $SIG{__WARN__} = sub { };
    my $app = shift;

    my $user_name;
    my $user_id;
    my $user = $app->_login_user_commenter();

    $user_name = 'false';
    $user_id   = 'false';

    if ($user) {
        if ( my $user_cookie = $app->cookie_val('mt_user') ) {
            $user_cookie = encode_text( $user_cookie, 'utf-8' );
            my @user_cookie = split '::', $user_cookie;
            if (   ( $user_cookie[0] eq $user->name )
                && ( $user_cookie[1] eq $app->current_magic ) )
            {
                $user_name = $user->nickname
                    || $app->translate('(Display Name not set)');
                $user_name
                    = "'"
                    . MT::Util::encode_js( $user->nickname || $user->name )
                    . "'";
                $user_id = $user->id;
            }
        }
        elsif ( $user->type == MT::Author::AUTHOR() ) {

            # MT Native user but only has comment permission
            $user_name
                = "'"
                . MT::Util::encode_js( $user->nickname
                    || $app->translate('(Display Name not set)') )
                . "'";
            $user_id = $user->id;
        }
        else {

            # Commenter type
            $user_name
                = "'"
                . MT::Util::encode_js( $user->nickname
                    || "User #" . $user->id )
                . "'";
            $user_id = $user->id;
        }
    }
    my $blog_id        = $app->param('blog_id');
    my $perms          = $user->permissions($blog_id) if $blog_id && $user;
    my $can_post_entry = $perms && $perms->can_create_post ? 'true' : 'false';

    $app->send_http_header("text/javascript");
    $app->{no_print_body} = 1;
    $app->set_header( 'Cache-Control' => 'no-cache' );
    $app->set_header( 'Expires'       => '-1' );
    my $magic_token = $app->current_magic;

    $app->print(<<JS);
user = $user_name;
user_id = $user_id;
can_post_entry = $can_post_entry;
magic_token = '$magic_token';
JS
}

sub _return_scores {
    my $app   = shift;
    my %param = @_;
    my ( $blog_id, $ids, $ds, $ns, $summary )
        = @param{qw( blog_id object_id datasource namespace summary )};
    $ns ||= NAMESPACE();
    my $plugin = $app->{plugin};
    my $q      = $app->param;

    my $jsonp = $q->param('jsonp') || 'scores_for';
    my $f     = $q->param('f')     || 'sum';
    $f = 'sum,avg,count,high,low,scored,authored'
        if $f eq 'all';

    my %func_map = (
        sum   => 'score_for',
        avg   => 'score_avg',
        count => 'vote_for',
        high  => 'score_high',
        low   => 'score_low',
    );

    my %results;
    my $user = $app->_login_user_commenter;

    my @id_list;
    for my $id ( split ',', $ids ) {
        next if !$id;
        push @id_list, $id;
        $results{$id} = { count => 0 };
    }
    if (@id_list) {
        my %scores;
        for my $func ( split ',', $f ) {
            if ( 'scored' eq $func ) {
                ## check if user is
                ## if not, check if anonymous scoring is ok
                my %terms;
                if ($user) {
                    $terms{author_id} = $user->id;
                }
                else {
                    if ( $blog_id && blog_allows_anon_recommend($blog_id) ) {
                        $terms{ip} = $app->remote_ip;
                    }
                    else {

                        # we shouldn't be calling in this case!
                    }
                }
                if (%terms) {
                    $terms{object_id} = \@id_list;
                    $terms{object_ds} = $ds;
                    $terms{namespace} = $ns;
                    require MT::ObjectScore;
                    if ( my @scores = MT::ObjectScore->load( \%terms ) ) {
                        foreach my $score (@scores) {
                            $results{ $score->object_id }{'scored'}
                                = $score->score;
                        }
                    }
                }
            }
            elsif ( 'authored' eq $func ) {
                my $class = $app->model($ds);
                if ($user) {
                    require MT::Entry;
                    my @entries = $class->load(
                        {   id        => \@id_list,
                            author_id => $user->id
                        },
                        { fetchonly => ['id'] }
                    );

                    $results{ $_->id }{$func} = 1 foreach @entries;
                }
            }
            else {
                my $method = $func_map{$func};
                my $class  = $app->model($ds);
                if ( $method && $class->can($method) ) {
                    my @obj = $class->load( { id => \@id_list } );
                    foreach my $obj (@obj) {
                        if ( $summary && $obj->has_summary($summary) ) {
                            $results{ $obj->id }{$func}
                                = $obj->summarize($summary);
                        }
                        else {
                            if ( my $value = $obj->$method($ns) ) {
                                $results{ $obj->id }{$func} = $value;
                            }
                        }
                    }
                }
            }
        }
    }

    $app->jsonp_result( \%results, $jsonp );
}

sub blog_allows_anon_recommend {
    my ($blog_id) = @_;
    my $blog = MT->model('blog.community')->load($blog_id);
    return 0 unless $blog;

    return $blog->allow_anon_recommend ? 1 : 0;
}

sub score {
    my $app = shift;
    my $q   = $app->param;

    my $jsonp = $q->param('jsonp') || 'scores_for';

    my $blog_id = $q->param('blog_id');

    my $ids = $q->param('id')
        or return $app->jsonp_error( 'Invalid request', $jsonp );

    my $ds = $q->param('ds') || 'entry';

    my $class = $app->model($ds)
        or return $app->jsonp_error( 'Invalid request', $jsonp );

    my $namespace = $q->param('namespace') || NAMESPACE();

    $app->_return_scores(
        blog_id    => $blog_id,
        object_id  => $ids,
        datasource => $ds,
        namespace  => $namespace,
        summary    => 'favorited_count'
    );
}

sub vote {
    my $app = shift;
    my $q   = $app->param;

    my $jsonp     = $q->param('jsonp')     || 'scores_for';
    my $namespace = $q->param('namespace') || NAMESPACE();

    my $id = $q->param('id')
        or return $app->jsonp_error( 'Invalid request', $jsonp );

    my $ds = $q->param('ds') || 'entry';

    my $class = $app->model($ds)
        or return $app->jsonp_error( 'Invalid request', $jsonp );

    my $obj = $class->load($id)
        or return $app->jsonp_error( 'Invalid request', $jsonp );

    my $blog_id = $q->param('blog_id');
    unless ( $blog_id && $obj->can('blog_id') ) {
        $blog_id = $obj->blog_id;
    }
    return $app->jsonp_error( 'Invalid request', $jsonp )
        unless $blog_id;

    ## you can remove your vote by passing "0" to score parameter
    my $value
        = defined $q->param('score')
        ? $q->param('score')
        : 1;
    my $overwrite
        = defined $q->param('ow')
        ? $q->param('ow')
        : 0;

    my %terms;
    ## check if user is
    my $user = $app->_login_user_commenter();

    if ($user) {
        $app->validate_magic
            or return $app->jsonp_error( 'Invalid request.', $jsonp );
        $terms{author_id} = $user->id;
    }
    else {
        my $login_error = $app->errstr;
        if ( blog_allows_anon_recommend($blog_id) ) {
            $terms{ip} = $app->remote_ip;
        }
        else {
            return $app->jsonp_error( $login_error, $jsonp );
        }
    }

    $app->run_callbacks( 'api_pre_save.vote', $app, $user, $obj, $value );

    $obj->set_score( $namespace, $user, $value, $overwrite, $blog_id )
        or return $app->jsonp_error( $obj->errstr, $jsonp );

    $app->run_callbacks( 'api_post_save.vote', $app, $user, $obj, $value );

    # For now, we're only rebuilding an entry object...
    if ( $ds eq 'entry' ) {
        if ( MT::Entry::RELEASE() == $obj->status ) {
            MT::Util::start_background_task(
                sub {
                    $app->rebuild_entry(
                        Entry             => $obj->id,
                        BuildDependencies => 1
                    );
                }
            );
        }
    }

    $app->_return_scores(
        blog_id    => $blog_id,
        object_id  => $id,
        datasource => $ds,
        namespace  => $namespace,
        summary    => 'favorited_count'
    );
}

sub show_error {
    my $app = shift;
    my ($param) = @_;
    if ( !ref $param ) {
        $param = { error => $param };
    }

    if ( $app->param('ajax') ) {
        if ( my $blog = $app->blog ) {
            my $tmpl = $app->model('template')->load(
                {   type    => 'entry_response',
                    blog_id => $blog->id,
                }
            );
            if ($tmpl) {
                my $ctx = $tmpl->context;
                $tmpl->param(
                    {   'body_class'      => 'mt-entry-error',
                        'entry_status'    => 0,
                        'error'           => $param->{error},
                        'system_template' => 1,
                    }
                );
                $ctx->stash( 'entry',   undef );
                $ctx->stash( 'blog',    $blog );
                $ctx->stash( 'blog_id', $blog->id );
                my $html = $tmpl->output();
                return $html if defined $html;
            }
        }
    }
    return $app->SUPER::show_error(@_);
}

sub post {
    my $app = shift;
    return
        unless $app->request_method eq 'POST';

    my $q       = $app->param;
    my $blog_id = $q->param('blog_id');
    return $app->errtrans("Invalid request") unless $blog_id;

    my $blog = $app->model('blog.community')->load($blog_id);
    return $app->errtrans("Invalid request") unless $blog;
    $app->blog($blog);

    my $user = $app->_login_user_commenter()
        or return $app->errtrans("Login required");
    $app->validate_magic
        or return $app->errtrans("Invalid request");

    my $perms = $user->permissions($blog_id);
    unless ( $user->is_superuser
        || ( $perms && $perms->can_create_post ) )
    {
        return $app->errtrans("Permission denied.");
    }

    # Permission for upload / Exists check for CF
    foreach my $p ( $q->param() ) {
        next if !$q->param($p);
        if ( $p =~ /^file_customfield_(.*?)$/ ) {
            require CustomFields::Field;
            my $field = CustomFields::Field->load(
                {   $blog_id
                    ? ( blog_id => [ $blog_id, 0 ] )
                    : ( blog_id => $blog_id ),
                    basename => $1,
                }
            );

            if ($field) {
                return $app->errtrans("Invalid request")
                    unless MT->model( $field->type );
            }
            else {
                return $app->errtrans("Invalid request");
            }
        }
    }

    require MT::Sanitize;
    my $sanitize_spec = $blog->sanitize_spec
        || $app->config->GlobalSanitizeSpec;

    my $title = $q->param('title');
    $title = '' unless defined $title;
    $title =~ s/^\s+|\s+$//gs;
    $title = MT::Util::remove_html($title);

    my $text = $q->param('text');
    $text = '' unless defined $text;
    $text =~ s/^\s+|\s+$//gs;

    if ( ( $title eq '' ) && ( $text eq '' ) ) {
        return $app->errtrans('Title or Content is required.');
    }

    # for custom fields
    $q->param( 'customfield_beacon', 1 );
    $q->param( '_type',              'entry' );

    $app->run_callbacks( 'api_save_filter.entry', $app )
        || return;

    my $entry = $app->model('entry')->new;
    my $orig  = $entry->clone();
    $entry->title($title);
    $entry->text($text);
    $entry->blog_id($blog_id);
    $entry->author_id( $user->id );
    my $cb 
        = $q->param('text_format')
        || MT->config->PublicPostFormat
        || $user->text_format
        || $blog->convert_paras
        || '__default__';
    $cb .= ',__sanitize__';

    $entry->convert_breaks($cb);
    $entry->allow_comments( $blog->allow_comments_default );
    $entry->allow_pings( $blog->allow_pings_default );

    foreach my $fld (qw( text_more excerpt keywords )) {
        my $val = $q->param($fld);
        next unless defined $val;
        $val =~ s/^\s+|\s+$//gs;
        $entry->column( $fld, $val ) if $val ne '';
    }

    for my $fld (qw( title text text_more excerpt keywords )) {
        my $val = $entry->column($fld);
        if ( $val && $val =~ m/\x00/ ) {
            $val =~ tr/\x00//d;
            $entry->column( $fld, $val );
        }
    }

    my $tags = $app->param('tags');
    if ( defined $tags ) {
        $tags =~ tr/\x00//d;
        $tags = remove_html($tags);

        require MT::Tag;
        my $tag_delim = chr( $user->entry_prefs->{tag_delim} );
        my @tags = MT::Tag->split( $tag_delim, $tags );
        $entry->set_tags(@tags);
    }

    MT::Util::translate_naughty_words($entry);

    if (  !( $user->is_superuser )
        && ( $perms && !$perms->can_publish_post ) )
    {
        $entry->status( MT::Entry::REVIEW() );
        $app->_post_junk_filter($entry)
            if $blog->run_junk_filter;
    }
    elsif ( $user->is_superuser || $perms->can_administer_blog ) {
        $entry->status( $blog->status_default );
    }
    else {
        $entry->status( $blog->status_default );
        $app->_post_junk_filter($entry);
    }

    $app->run_callbacks( 'api_pre_save.entry', $app, $entry, $orig )
        || return $app->error(
        $app->translate(
            "Saving [_1] failed: [_2]",
            $entry->class_label, $app->errstr
        )
        );

    $entry->save
        or return $app->error(
        $app->translate(
            "Saving [_1] failed: [_2]", $entry->class_label,
            $entry->errstr
        )
        );

    $app->log(
        {   message => $app->translate(
                "[_1] '[_2]' (ID:[_3]) added by user '[_4]'",
                $entry->class_label, $entry->title,
                $entry->id,          $user->name
            ),
            level    => MT::Log::INFO(),
            class    => 'entry',
            category => 'new',
            metadata => $entry->id
        }
    );

    # for custom field asset
    my ( @cf_assets, @cf_objasset );
    foreach my $p ( $q->param() ) {
        next if !$q->param($p);
        if ( $p =~ /^file_customfield_(.*?)$/ ) {
            if ( my $file_type = $q->param("type_customfield_$1") ) {
                my $asset
                    = $app->_handle_upload( $p, require_type => $file_type );
                if ( !defined($asset) && $app->errstr ) {
                    $entry->remove();
                    $_->remove() for ( @cf_assets, @cf_objasset );
                    return $app->error( $app->errstr );
                }
                if ($asset) {
                    push @cf_assets, $asset;
                    $q->param( "customfield_$1",
                        $asset->as_html( { include => 1, enclose => 1 } ) );
                    my $obj_asset = MT->model('objectasset')->load(
                        {   asset_id  => $asset->id,
                            object_ds => 'entry',
                            object_id => $entry->id
                        }
                    );
                    unless ($obj_asset) {
                        my $obj_asset = MT->model('objectasset')->new;
                        $obj_asset->blog_id($blog_id);
                        $obj_asset->asset_id( $asset->id );
                        $obj_asset->object_ds('entry');
                        $obj_asset->object_id( $entry->id );
                        $obj_asset->save;
                        push @cf_objasset, $obj_asset;
                    }
                }
            }
        }
    }

    my $cid = $q->param('category') || $q->param('category_id');
    if ($cid) {
        require MT::Placement;
        my $place = MT::Placement->new;
        $place->entry_id( $entry->id );
        $place->blog_id( $entry->blog_id );
        $place->is_primary(1);
        $place->category_id($cid);
        $place->save;
    }

    $app->run_callbacks( 'api_post_save.entry', $app, $entry, $orig );

    $q->param( 'customfield_beacon', 0 );

    if ( MT::Entry::RELEASE() == $entry->status ) {
        $app->rebuild_entry(
            Entry             => $entry->id,
            BuildDependencies => 1,
            BuildIndexes      => 0
            )
            or return $app->error(
            $app->translate( "Publish failed: [_1]", $app->errstr ) );

        MT::Util::start_background_task(
            sub {
                $app->rebuild_indexes( Blog => $blog )
                    or return $app->errtrans( "Publish failed: [_1]",
                    $app->errstr );
            }
        );
    }

    my $tmpl = $app->model('template')->load(
        {   type    => 'entry_response',
            blog_id => $blog_id,
        }
    );
    unless ($tmpl) {
        return $app->errtrans(
            'System template entry_response not found in blog: [_1]',
            $blog->name );
    }
    my $ctx = $tmpl->context;
    $tmpl->param(
        {   'body_class'      => 'mt-entry-confirmation',
            'entry_status'    => $entry->status,
            'system_template' => 1,
        }
    );
    $ctx->stash( 'entry',   $entry );
    $ctx->stash( 'blog',    $blog );
    $ctx->stash( 'blog_id', $blog->id );
    my $html = $tmpl->output();
    $html = $tmpl->errstr unless defined $html;

    ## Send notification email in the background.
    if ( my $registration = $app->config->CommenterRegistration ) {
        if ( my $ids = $registration->{Notify} ) {
            MT::Util::start_background_task(
                sub {
                    $app->_send_entry_notification( $entry, $blog, $ids );
                }
            );
        }
    }

    return $html;
}

sub _post_junk_filter {
    my $app = shift;
    my ($entry) = @_;

    my $user = $app->user;

    # Score with junk filters as if this were a comment;
    # if it scores as junk, set state of post to 'review'
    my $comment = $app->model('comment')->new;
    $comment->author( $user->nickname || $user->name );
    $comment->email( $user->email );
    $comment->ip( $app->remote_ip );
    $comment->blog_id( $entry->blog_id );

    my $text = $entry->title || "";
    $text
        .= "\n"
        . (
        MT->apply_text_filters( $entry->text || '', $entry->text_filters ) );
    $text .= "\n"
        . (
        MT->apply_text_filters(
            $entry->text_more || '',
            $entry->text_filters
        )
        );
    $text .= "\n" . ( $entry->keywords || '' );
    $text .= "\n" . ( $entry->excerpt  || '' );

    # Include text from any custom fields that were assigned too
    if ( my $meta = $entry->meta_obj->get_collection('field') ) {
        foreach ( values %$meta ) {
            $text .= "\n" . $_ if defined $_;
        }
    }

    $comment->text($text);

    # Assign visible status by default if entry status is
    # set to release
    my $status = $entry->status;
    $comment->visible( $status == MT::Entry::RELEASE() );

    require MT::JunkFilter;
    MT::JunkFilter->filter($comment);

    if ( $comment->is_junk ) {

        # forcibly set to review
        $status = MT::Entry::JUNK();
    }
    elsif ( !$comment->visible ) {
        $status = MT::Entry::REVIEW();
    }

    if ( defined $status ) {
        $entry->status($status);
        my $log = $comment->junk_log;
        $entry->junk_log($log)
            if defined $log;
    }

    return;
}

sub _handle_upload {
    my $app = shift;
    my ( $param, %options ) = @_;

    my $q = $app->param;

    my ( $fh, $info ) = $app->upload_info($param);
    return 0 if !$fh;

    my $mimetype;
    if ($info) {
        $mimetype = $info->{'Content-Type'};
    }

    my $basename = $q->param($param);
    $basename =~ s!\\!/!g;    ## Change backslashes to forward slashes
    $basename =~ s!^.*/!!;    ## Get rid of full directory paths
    if ( $basename =~ m!\.\.|\0|\|! ) {
        return $app->errtrans( "Invalid filename '[_1]'", $basename );
    }
    $basename
        = Encode::is_utf8($basename)
        ? $basename
        : Encode::decode( $app->charset,
        File::Basename::basename($basename) );

    my ( $base, $uploaded_path, $ext )
        = File::Basename::fileparse( $basename, '\.[^\.]*' );

    require Image::Size;
    my ( $tmp_w, $tmp_h, $tmp_id ) = Image::Size::imgsize($fh);
    $ext = '.' . lc($tmp_id)
        if ( $tmp_w
        && $tmp_h
        && $tmp_id
        && lc($tmp_id) ne lc($ext)
        && !( lc($ext) eq '.jpeg' && lc($tmp_id) eq 'jpg' )
        && !( lc($ext) eq '.swf'  && lc($tmp_id) eq 'cws' ) );

    if ( my $deny_exts = $app->config->DeniedAssetFileExtensions ) {
        my @deny_exts = map {
            if   ( $_ =~ m/^\./ ) {qr/$_/i}
            else                  {qr/\.$_/i}
        } split '\s?,\s?', $deny_exts;
        my @ret = File::Basename::fileparse( $base . $ext, @deny_exts );
        if ( $ret[2] ) {
            return $app->errtrans(
                'The file ([_1]) that you uploaded is not allowed.',
                $base . $ext );
        }
    }

    if ( my $allow_exts = $app->config('AssetFileExtensions') ) {
        my @allow_exts = map {
            if   ( $_ =~ m/^\./ ) {qr/$_/i}
            else                  {qr/\.$_/i}
        } split '\s?,\s?', $allow_exts;
        my @ret = File::Basename::fileparse( $base . $ext, @allow_exts );
        unless ( $ret[2] ) {
            return $app->errtrans(
                'The file ([_1]) that you uploaded is not allowed.',
                $base . $ext );
        }
    }

    # dirify $base
    $base = dirify($base);

    if ( my $asset_type = $options{require_type} ) {
        require MT::Asset;
        my $asset_pkg = MT::Asset->handler_for_file( $base . $ext );
        if ( $asset_type eq 'audio' ) {
            return $app->errtrans("Please select an audio file to upload.")
                if !$asset_pkg->isa('MT::Asset::Audio');
        }
        elsif ( $asset_type eq 'image' ) {
            return $app->errtrans("Please select an image to upload.")
                if !$asset_pkg->isa('MT::Asset::Image');
        }
        elsif ( $asset_type eq 'video' ) {
            return $app->errtrans("Please select a video to upload.")
                if !$asset_pkg->isa('MT::Asset::Video');
        }
    }

    my ( $blog_id, $blog, $save_path, $local_path, $fmgr, %complements );
    if ( !$options{system_context} && ( $blog_id = $q->param('blog_id') ) ) {
        return $app->errtrans("Invalid request") unless $blog_id;

        $blog = $app->model('blog.community')->load($blog_id);
        return $app->errtrans("Invalid request") unless $blog;
        $app->blog($blog);

        $save_path = $blog->upload_path || '%r'
            or return 0;
        $save_path .= '/' unless $save_path =~ m|/$|;
        if ( $save_path && ( $save_path =~ m!^\%([ra])! ) ) {
            my $root
                = !$blog || $1 eq 'r'
                ? $blog->site_path
                : $blog->archive_path;
            $root =~ s!(/|\\)$!!;
            $local_path = $save_path;
            $local_path =~ s!^\%[ra]!$root!;
        }
        return unless $local_path;
        $fmgr        = $blog->file_mgr;
        %complements = ();
    }
    else {
        $blog_id   = 0;
        $save_path = '%s/uploads/';
        $local_path
            = File::Spec->catdir( $app->support_directory_path(), 'uploads' );

        require MT::FileMgr;
        $fmgr        = MT::FileMgr->new('Local');
        %complements = (
            Max => ( $app->config('UserpicMaxUpload') || 0 ),
            Square => ( $options{square} || 0 ),
        );
    }

    $fmgr->mkpath($local_path)
        if !$fmgr->exists($local_path);

    # Find unique name for the file.
    my $i         = 1;
    my $base_copy = $base;
    while (
        $fmgr->exists( File::Spec->catfile( $local_path, $base . $ext ) ) )
    {
        $base = $base_copy . '_' . $i++;
    }

    my $local_relative = File::Spec->catfile( $save_path,  $base . $ext );
    my $local          = File::Spec->catfile( $local_path, $base . $ext );

    require MT::Image;
    my ( $w, $h, $id, $write_file ) = MT::Image->check_upload(
        Fh    => $fh,
        Fmgr  => $fmgr,
        Local => $local,
        %complements
    );

    return $app->error( MT::Image->errstr )
        unless $write_file;

    my $umask = oct $app->config('UploadUmask');
    my $old   = umask($umask);
    defined( my $bytes = $write_file->() )
        or return $app->error(
        $app->translate(
            "Error writing upload to '[_1]': [_2]",
            $local, $fmgr->errstr
        )
        );
    umask($old);

    ## Close up the filehandle.
    close $fh;

    require MT::Asset;
    my $asset_pkg = MT::Asset->handler_for_file($local);
    my $is_image 
        = defined($w)
        && defined($h)
        && $asset_pkg->isa('MT::Asset::Image');
    my $asset;
    $asset = $asset_pkg->new();
    $asset->file_path($local_relative);
    $asset->file_name( $base . $ext );
    my $ext_copy = $ext;
    $ext_copy =~ s/\.//;
    $asset->file_ext($ext_copy);
    $asset->blog_id($blog_id);

    my $original = $asset->clone;
    my $url      = $local_relative;
    $url =~ s!\\!/!g;
    $asset->url($url);
    if ($is_image) {
        $asset->image_width($w);
        $asset->image_height($h);
    }
    $asset->mime_type($mimetype);

    $asset->save
        or return $app->error( $asset->errstr );

    MT->run_callbacks(
        'api_upload_file.' . $asset->class,
        File  => $local,
        file  => $local,
        Url   => $url,
        url   => $url,
        Size  => $bytes,
        size  => $bytes,
        Asset => $asset,
        asset => $asset,
        Type  => $asset->class,
        type  => $asset->class,
        $blog ? ( Blog => $blog ) : (),
        $blog ? ( blog => $blog ) : ()
    );
    if ($is_image) {
        MT->run_callbacks(
            'api_upload_image',
            File       => $local,
            file       => $local,
            Url        => $url,
            url        => $url,
            Size       => $bytes,
            size       => $bytes,
            Asset      => $asset,
            asset      => $asset,
            Height     => $h,
            height     => $h,
            Width      => $w,
            width      => $w,
            Type       => 'image',
            type       => 'image',
            ImageType  => $id,
            image_type => $id,
            $blog ? ( Blog => $blog ) : (),
            $blog ? ( blog => $blog ) : ()
        );
    }

    $asset;

}

sub _send_entry_notification {
    my $app = shift;
    my ( $entry, $blog, $ids ) = @_;

    my $subject
        = $app->translate( "New entry '[_1]' added to the blog '[_2]'",
        $entry->title, $blog->name );

    my $url = $app->mt_uri(
        mode => 'view',
        args => {
            '_type' => 'entry',
            id      => $entry->id,
            blog_id => $blog->id,
        }
    );

    if ( $url =~ m!^/! ) {
        my ($blog_domain) = $blog->site_url =~ m|(.+://[^/]+)|;
        $url = $blog_domain . $url;
    }

    my $body = $app->build_email(
        'new_entry_email.mtml',
        {   blog     => $blog,
            entry    => $entry,
            edit_url => $url
        }
    );

    $app->_send_sysadmins_email( $ids, 'entry_notification', $body, $subject,
    );
}

sub view_profile_method {
    my $app      = shift;
    my $id       = $app->param('id');
    my $username = $app->param('username');
    my $blog_id  = $app->param('blog_id') || 0;

    if ($blog_id) {
        my $blog = $app->model('blog.community')->load($blog_id);
        return $app->errtrans("Invalid request") unless $blog;
    }

    my $user = $app->_login_user_commenter;
    unless ( $id || $username ) {
        if ($user) {
            $id       = $user->id;
            $username = $user->name;
        }
        else {
            return $app->errtrans("Id or Username is required");
        }
    }

    if ($id) {
        $user = $app->model('author')->load($id);
    }
    elsif ($username) {

        # FIXME: Should we specify auth_type here?
        $user = $app->model('author')->load( { name => $username } );
        $id = $user->id if $user;
    }
    return $app->errtrans("Unknown user")
        if ( !$user || $user->status != MT::Author::ACTIVE() );

    my $tmpl = $app->load_global_tmpl( 'profile_view', $blog_id )
        or return $app->error("No profile view template defined");

    my ( $state, $commenter ) = $app->session_state;
    my %param = ();
    $param{blog_id}  = $blog_id;
    $param{name}     = $user->name;
    $param{nickname} = $user->nickname;
    $param{name}     = $user->name;
    $param{url}      = $user->url;
    $param{field_loop}
        = field_loop( object_type => 'author', object_id => $id );
    $param{profile_self} = 1
        if $commenter
            && $commenter->id == $id;
    $param{system_template} = 1;

    my $ctx = $tmpl->context;
    $ctx->stash( 'author',  $user );
    $ctx->stash( 'blog_id', $blog_id ) if $blog_id;
    $ctx->stash( 'entries', delay( sub { entries_by_user($ctx) } ) );
    $tmpl->param( \%param );
    $tmpl;
}

sub entries_by_user {
    my ( $ctx, $limit ) = @_;

    my $user    = $ctx->stash('author');
    my $blog_id = $ctx->stash('blog_id');

    my $attr;
    $attr->{blog_ids} = $blog_id ? $blog_id : 'all';
    my $terms = {
        author_id => $user->id,
        status    => 2,
    };
    $limit ||= 20;
    my $args = {
        'sort'    => 'authored_on',
        direction => 'descend',
        limit     => $limit,
    };

    if ( my $mb = MT->component('multiblog') ) {
        require MultiBlog;
        MultiBlog::filter_blogs_from_args( $mb, $ctx, $attr );
    }
    $ctx->set_blog_load_context( $attr, $terms, $args );
    my @entries = MT::Entry->load( $terms, $args );
    return \@entries;
}

sub edit_profile_method {
    my $app     = shift;
    my %param   = $_[0] ? %{ $_[0] } : ();
    my $q       = $app->param;
    my $blog_id = $app->param('blog_id') || 0;

    my $user = $app->_login_user_commenter();
    return $app->errtrans("Unknown user") if ( !$user );

    my $tmpl = $app->load_global_tmpl( 'profile_edit_form', $blog_id )
        or return $app->error("No profile edit template defined");

    my $return_to = $q->param('return_to');
    if ($return_to) {
        $return_to = remove_html($return_to);
        return $app->errtrans('Invalid request.')
            unless is_url($return_to);
    }

    my $return_args
        = $app->uri_params( mode => 'edit', args => { id => $user->id } );
    $return_args =~ s!^\?!!;

    my $cfg = $app->config;

    $param{ 'auth_mode_' . $cfg->AuthenticationModule } = 1;
    $param{blog_id}                                     = $blog_id;
    $param{name}                                        = $user->name;
    $param{nickname}                                    = $user->nickname;
    $param{name}                                        = $user->name;
    $param{email}                                       = $user->email;
    $param{url}                                         = $user->url;
    $param{return_to}                                   = $return_to;
    if ( my $userpic_id = $user->userpic_asset_id ) {
        $param{userpic_id} = $userpic_id;
        $param{userpic}    = $user->userpic_html();
    }
    $param{return_args} = $return_args;
    $param{magic_token} = $app->current_magic;
    $param{field_loop}  = field_loop(
        object_type => 'author',
        object_id   => $user->id,
        simple      => 1
    );
    $param{profile_self} = 1;
    eval { require MT::Image; MT::Image->new or die; };
    $param{can_use_userpic}                   = $@ ? 0 : 1;
    $param{id}                                = $user->id;
    $param{ 'auth_type_' . $user->auth_type } = 1;
    $param{system_template}                   = 1;
    $param{saved}                             = $app->param('saved');

    my $authenticator = MT->commenter_authenticator( $user->auth_type );
    my $auth_class = $authenticator->{class} || 'MT::Auth::MT';
    eval "require $auth_class;";
    $param{can_modify_password} = $auth_class->password_exists;

    if (    ( $user->auth_type eq 'MT' )
        and ( $user->column('password') !~ /^\$6\$|{SHA}/ )
        and ( not $param{error} ) )
    {
        $param{error} = $app->translate(
            "For improved security, please change your password");
    }

    my $ctx = $tmpl->context;
    $ctx->stash( 'author', $user );
    $ctx->stash( 'blog_id', $blog_id ) if $blog_id;
    $tmpl->param( \%param );
    $tmpl;
}

sub __verify_password_strength {
    my $app = shift;
    MT::App::verify_password_strength( $app, @_ );
}

sub save_profile_method {
    my $app = shift;

    return $app->error( $app->translate("Invalid request") )
        if $app->request_method() ne 'POST';

    my $q      = $app->param;
    my %param  = ();
    my $author = $app->_login_user_commenter();
    return $app->error( $app->translate("Invalid request") )
        unless $author;

    $app->validate_magic
        or return $app->errtrans("Invalid request");

    my $auth_type = $author->auth_type;
    if ( $auth_type eq 'MT' ) {
        my $nickname = $q->param('nickname');
        unless ( $nickname && $q->param('email') ) {
            $param{error} = $app->translate(
                'All required fields must have valid values.');
        }
        if ( $nickname =~ m/([<>])/ ) {
            $param{error} = $app->translate(
                "[_1] contains an invalid character: [_2]",
                $app->translate("Display Name"),
                encode_html($1)
            );
        }
        if ( ( $q->param('pass') || '' ) ne ( $q->param('pass_verify') || '' )
            )
        {
            $param{error} = $app->translate('Passwords do not match.');
        }
        if ( scalar $q->param('pass') ) {
            require MT::Auth;
            if (not MT::Auth->is_valid_password(
                    $author, scalar( $q->param('old_pass') )
                )
                )
            {
                $param{error} = $app->translate(
                    'Failed to verify the current password.');
            }
            elsif (
                my $error = __verify_password_strength(
                    $app, $author->name, scalar $q->param('pass')
                )
                )
            {
                $param{error} = $error;
            }
        }
    }
    my $email = $q->param('email');
    if ( $email && !is_valid_email($email) ) {
        $param{error} = $app->translate('Email Address is invalid.');
    }
    if ( $email && $email =~ m/([<>])/ ) {
        $param{error} = $app->translate(
            "[_1] contains an invalid character: [_2]",
            $app->translate("Email Address"),
            encode_html($1)
        );
    }
    my $url = $q->param('url');
    if ( $url && ( !is_url($url) || ( $url =~ m/[<>]/ ) ) ) {
        $param{error} = $app->translate("URL is invalid.");
    }

    my $return_to = $q->param('return_to');
    if ($return_to) {
        $return_to = remove_html($return_to);
        return $app->errtrans('Invalid request.')
            unless is_url($return_to);
    }

    if ( !$app->run_callbacks( 'api_save_filter.author', $app ) ) {
        $param{error} = $app->errstr;
    }

    if ( $param{error} ) {
        require MT::Log;
        $app->log(
            {   message  => $param{error},
                level    => MT::Log::ERROR(),
                class    => 'author',
                category => 'save_author_profile'
            }
        );
        $param{return_args} = $app->param('return_args');
        for my $f (qw( name nickname email url state blog_id )) {
            $param{$f} = $q->param($f);
        }
        $param{return_to} = $return_to;
        return $app->edit_profile_method( \%param );
    }

    my $original = $author->clone();
    my $names    = $author->column_names;
    my %values   = map { $_ => ( scalar $q->param($_) ) } @$names;

    my @cols = qw(is_superuser can_create_blog can_view_log password id);
    delete $values{$_} for @cols;

    $author->set_values( \%values );
    $author->modified_on( epoch2ts( undef, time ) );

    if ( $auth_type eq 'MT' ) {
        my $pass = $q->param('pass');
        if ($pass) {
            $author->set_password($pass);
        }
    }

    $app->run_callbacks( 'api_pre_save.author', $app, $author, $original )
        || return;

    $author->save
        or return $app->error(
        $app->translate( "Saving object failed: [_1]", $author->errstr ) );

    my $asset = $app->_handle_upload(
        'file',
        require_type   => 'image',
        square         => ( $app->config->UserpicAllowRect ? 0 : 1 ),
        system_context => 1
    );
    if ( !defined($asset) && $app->errstr ) {
        return $app->error( $app->errstr );
    }
    if ($asset) {
        $asset->tags('@userpic');
        $asset->save;
        if ( my $userpic = $author->userpic ) {

           # Remove the old userpic thumb so the new asset's will be generated
           # in its place.
            my $thumb_file = $author->userpic_file();
            my $fmgr       = MT::FileMgr->new('Local');
            if ( $fmgr->exists($thumb_file) ) {
                $fmgr->delete($thumb_file);
            }

            $userpic->remove;
        }
        $author->userpic_asset_id( $asset->id );
        $author->save;
    }

    $app->run_callbacks( 'api_post_save.author', $app, $author, $original )
        || return;

    if ( my $blog_id = $q->param('blog_id') ) {
        $app->add_return_arg( 'blog_id' => $blog_id );
    }
    $app->add_return_arg( 'return_to' => $return_to );
    $app->add_return_arg( 'saved'     => 1 );
    $app->bake_commenter_cookie( $app->session, $author );
    $app->call_return;
}

sub feed_profile_method {
    my $app  = shift;
    my $type = $app->param('_type')
        || 'posts';    # posts, comments, replies or actions
    my $id       = $app->param('id');
    my $username = $app->param('username');
    my $blog_id  = $app->param('blog_id') || 0;

    my $user;
    unless ( $id || $username ) {
        ($user) = $app->login();
        if ($user) {
            $id       = $user->id;
            $username = $user->name;
        }
        else {
            return $app->errtrans("Id or Username is required");
        }
    }

    unless ($user) {
        if ($id) {
            $user = $app->model('author')->load($id);
        }
        else {
            $user = $app->model('author')->load( { name => $username } );
        }
    }
    return $app->errtrans("Unknown user")
        if ( !$user || $user->status != MT::Author::ACTIVE() );

    my $schema = $app->param('rss') || 'atom';
    my $tmpl_name = $schema eq 'atom' ? 'profile_feed' : 'profile_feed_rss';
    my $tmpl = $app->load_global_tmpl( $tmpl_name, $blog_id )
        or return $app->error("No profile feed template defined");

    my $ctx = $tmpl->context;
    $ctx->stash( 'author', $user );
    $ctx->stash( 'blog_id', $blog_id ) if $blog_id;
    my $param = {};
    my $str   = qq();
    for my $key ( $app->param ) {
        $str .= '&amp;' unless $str eq '';
        $str .= $key . '=' . encode_url( $app->param($key) );
    }
    $param->{feed_self}
        = $app->base . $app->app_path . $app->script . '?' . $str;

    my ( $last_ts, $last_blog, $entries, $comments, $actions );
    if ( 'posts' eq $type ) {
        $param->{entry}      = 1;
        $param->{feed_title} = $app->translate( 'Recent Entries from [_1]',
            $user->nickname || '' );
        $entries = entries_by_user( $ctx, 15 );
        if ( $entries && @$entries && $entries->[0] ) {
            $last_ts   = $entries->[0]->authored_on;
            $last_blog = $entries->[0]->blog;
        }
    }
    elsif ( 'comments' eq $type ) {
        $param->{comment} = 1;
        $param->{feed_title}
            = $app->translate( 'Comments from [_1]', $user->nickname || '' );
        my @comments = $app->model('comment')->load(
            { commenter_id => $user->id, visible => 1 },
            {   sort_order => 'created_on',
                direction  => 'descend',
                limit      => 15
            },
        );
        if ( @comments && $comments[0] ) {
            $last_ts   = $comments[0]->created_on;
            $last_blog = $comments[0]->blog;
        }
        $comments = \@comments;
    }
    elsif ( 'replies' eq $type ) {
        $param->{comment} = 1;
        $param->{feed_title}
            = $app->translate( 'Responses to Comments from [_1]',
            $user->nickname || '' );
        require MT::Community::Tags;
        $comments = MT::Community::Tags::comments_from_threads(
            { author_id => $user->id, lastn => 15 } );
        if ( $comments && @$comments && $comments->[0] ) {
            $last_ts   = $comments->[0]->created_on;
            $last_blog = $comments->[0]->blog;
        }
    }
    elsif ( 'actions' eq $type ) {
        $param->{action} = 1;
        $param->{feed_title}
            = $app->translate( 'Actions from [_1]', $user->nickname || '' );
        require MT::Community::Tags;
        $actions = MT::Community::Tags::actions(
            { author_id => $user->id, },
            {   'sort'    => 'created_on',
                direction => 'descend',
                limit     => 15,
            },
            default_sort => 1
        );
        if ( $actions && @$actions && $actions->[0] ) {
            my ( $type, $obj ) = @{ $actions->[0] };
            $last_ts
                = $type eq 'entry' ? $obj->authored_on : $obj->created_on;
            if ( $type eq 'score' ) {
                my $entry
                    = MT->model( $obj->object_ds )->load( $obj->object_id );
                $last_blog = $entry->blog;
            }
            else {
                $last_blog = $obj->blog;
            }
        }
    }

    if ( $last_ts && $last_blog ) {
        my $so                  = $last_blog->server_offset;
        my $partial_hour_offset = 60 * abs( $so - int($so) );
        my $tz                  = sprintf( "%s%02d%02d",
            $so < 0 ? '-' : '+',
            abs($so), $partial_hour_offset );

        $param->{feed_updated} = time2isoz( ts2epoch( undef, $last_ts ) );
        $param->{feed_updated} =~ s/ /T/;
        $param->{feed_updated_rfc822}
            = format_ts( '%a, %d %b %Y %H:%M:%S ' . $tz,
            $last_ts, undef, 'en', 0 );
    }
    else {
        my @last_ts = gmtime(time);
        $last_ts = sprintf "%04d%02d%02d%02d%02d%02d",
            $last_ts[5] + 1900, $last_ts[4] + 1, $last_ts[3],
            $last_ts[2], $last_ts[1], $last_ts[0];
        my $tz = '+0000';
        $param->{feed_updated} = time2isoz( ts2epoch( undef, $last_ts ) );
        $param->{feed_updated} =~ s/ /T/;
        $param->{feed_updated_rfc822}
            = format_ts( '%a, %d %b %Y %H:%M:%S ' . $tz,
            $last_ts, undef, 'en', 0 );
    }

    $param->{blog_id}         = $blog_id;
    $param->{system_template} = 1;
    $tmpl->param($param);

    $ctx->stash( 'entries', $entries )
        if $entries;
    $ctx->stash( 'comments', $comments )
        if $comments;
    $ctx->stash( 'actions', $actions )
        if $actions;

    my $mod_since = $app->get_header('If-Modified-Since');
    $app->{no_print_body} = 1;
    if (   $last_ts
        && $mod_since
        && ( ts2epoch( undef, $last_ts ) <= str2time($mod_since) ) )
    {
        $app->response_code(304);
        $app->response_message('Not Modified');
        $app->send_http_header('application/atom+xml');
    }
    else {
        $app->set_header( 'Last-Modified',
            time2str( ts2epoch( undef, $last_ts ) ) )
            if $last_ts;

        my $out = eval { $app->build_page($tmpl) };

        if ( my $error = $@ || $tmpl->errstr ) {
            $app->response_code(500);
            $app->send_http_header('text/plain');
            $app->print_encode($error);
        }
        else {
            $app->send_http_header('application/atom+xml');
            $app->print_encode($out);
        }
    }
}

## Friending related methods
sub _validate_request {
    my $app = shift;
    return $app->error('Invalid request.')
        unless $app->request_method eq 'POST';
    my $q = $app->param;

    my $user = $app->_login_user_commenter();
    if ( !$user ) {
        return $app->error('Login required');
    }
    $app->validate_magic
        or return $app->error("Invalid request.");

    my $id = $app->param('id')
        or return $app->error("User id is required");

    my $target_user = $app->model('author')->load($id);
    return $app->error("Unknown user")
        unless $target_user;
    return $app->error("Inactive user")
        unless $target_user->status == MT::Author::ACTIVE();
    return $target_user;
}

sub follow {
    my $app    = shift;
    my $q      = $app->param;
    my $jsonp  = $q->param('jsonp') || 'follow';
    my $target = $app->_validate_request()
        or return $app->jsonp_error( $app->errstr, $jsonp );
    require MT::Community::Friending;
    MT::Community::Friending::follow( $app->user, $target )
        or return $app->jsonp_error( "Unknown user", $jsonp );

    return $app->jsonp_result( { id => $target->id, name => $target->name },
        $jsonp );
}

sub leave {
    my $app    = shift;
    my $q      = $app->param;
    my $jsonp  = $q->param('jsonp') || 'follow';
    my $target = $app->_validate_request()
        or return;

    require MT::Community::Friending;
    MT::Community::Friending::leave( $app->user, $target )
        or return $app->jsonp_error( "Unknown user", $jsonp );

    return $app->jsonp_result( { id => $target->id, name => $target->name },
        $jsonp );
}

sub relations_js {
    my $app   = shift;
    my $q     = $app->param;
    my $jsonp = $app->param('jsonp') || 'relations';
    $jsonp = undef if $jsonp !~ m/^\w+$/;
    return $app->error("Invalid request.") unless $jsonp;

    my ( $state, $commenter ) = $app->session_state;

    my $following = 0;
    my $followed  = 0;
    if ($commenter) {
        require MT::Community::Friending;
        $following = MT::Community::Friending::is_following( $commenter,
            $q->param('author_id') );
        $followed = MT::Community::Friending::is_followed( $commenter,
            $q->param('author_id') );
    }

    $app->{no_print_body} = 1;
    $app->set_header( 'Cache-Control' => 'no-cache' );
    $app->set_header( 'Expires'       => '-1' );
    $app->send_http_header("text/javascript");
    $app->print("$jsonp($following, $followed);\n");
    return undef;
}

sub unpublish_entry {
    my $app = shift;
    return
        unless $app->request_method eq 'POST';

    my $q  = $app->param;
    my $id = $q->param('id');
    return $app->errtrans("Invalid request") unless $id;

    my $ds = $q->param('ds') || 'entry';
    my $obj = $app->model($ds)->load($id);
    return $app->errtrans("Invalid request")
        unless $obj && $obj->isa('MT::Entry');
    return q() unless MT::Entry::RELEASE() == $obj->status;

    my $blog = $obj->blog;
    $app->blog($blog);

    my $user = $app->_login_user_commenter()
        or return $app->errtrans("Login required");
    $app->validate_magic
        or return $app->errtrans("Invalid request");

    my $perms = $user->permissions( $blog->id );
    unless ( $user->is_superuser
        || ( $perms && $perms->can_edit_entry( $obj, $user ) ) )
    {
        return $app->errtrans("Permission denied.");
    }

    $obj->status( MT::Entry::HOLD() );
    $obj->save
        or return $app->error(
        $app->translate(
            "Saving [_1] failed: [_2]",
            $obj->class_label, $obj->errstr
        )
        );

    MT::Util::start_background_task(
        sub {
            my %recip = $app->publisher->rebuild_deleted_entry(
                Entry => $obj,
                Blog  => $blog
            );
            $app->rebuild_indexes( Blog => $blog )
                or
                return $app->errtrans( "Publish failed: [_1]", $app->errstr );
        }
    );

    return q();
}

sub remove_userpic {
    my $app    = shift;
    my $q      = $app->param;
    my $author = $app->_login_user_commenter();
    return unless $author;

    $app->validate_magic() or return;

    my $user_id = $q->param('user_id');
    return unless $user_id;

    my $user = $app->model('author')->load( { id => $user_id } )
        or return;

    if ( ( !$author->is_superuser ) && ( $user->id != $author->id ) ) {
        return $app->permission_denied();
    }

    if ( $user->userpic_asset_id ) {
        my $old_file = $user->userpic_file();
        my $fmgr     = MT::FileMgr->new('Local');
        if ( $fmgr->exists($old_file) ) {
            $fmgr->delete($old_file);
        }
        $user->userpic_asset_id(0);
        $user->save;
    }
    return 'success';
}

1;
__END__
