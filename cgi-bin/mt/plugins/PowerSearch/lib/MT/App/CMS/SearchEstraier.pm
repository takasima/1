package MT::App::CMS::SearchEstraier;

use strict;
use MT;
use MT::App;
use MT::Builder;
use MT::Session;
use MT::Template;
use MT::Template::Context;
use MT::Util qw( encode_url );

use File::Spec;

use Estraier;

use lib qw( addons/PowerCMS.pack/lib );
use PowerCMS::Util qw( is_user_can );

use base qw( MT::App );

sub init_request {
    my $app = shift;
    $app->SUPER::init_request(@_);
    $app->{default_mode}   = 'search';
    $app->{requires_login} = 0;
    $app->add_methods( search => \&_search );
    $app;
}

sub _search {
    my $app    = shift;
    my $plugin = MT->component('PowerSearch');
    my %params;

    my $error_tmpl
        = File::Spec->catdir( $plugin->path, 'tmpl', 'estraier_error.tmpl' );

    my $alt_tmpl
        = File::Spec->catdir( $plugin->path, 'tmpl', 'estraier_result.tmpl' );
    if ( -e $alt_tmpl && !$app->blog ) {
        return $app->build_page( $alt_tmpl, \%params );
    }

    my $blog;
    if ( $app->blog ) {
        $blog = $app->blog;
        my $members = MT->component('Members');
        if ( defined $members ) {
            if ( $blog->has_column( 'is_members' ) && $blog->is_members ) {
                my $login = _usercheck( $app, $blog, $members );
            }
        }
    }
    else {
        $blog = MT::Blog->load( undef, { limit => 1 } );
    }

    my $blog_id  = $blog->id;
    my $template = MT::Template->load(
        {   identifier => 'estraier_result',
            blog_id    => $blog_id
        }
    );

    if ( defined $template ) {
        my $tmpl = $template->text;
        my $ctx  = MT::Template::Context->new;

        $ctx->stash( 'blog',    $blog );
        $ctx->stash( 'blog_id', $blog->id );

        my $build = MT::Builder->new;
        my $tokens = $build->compile( $ctx, $tmpl )
            or return $app->error(
            $app->translate( "Parse error: [_1]", $build->errstr ) );
        defined( my $html = $build->build( $ctx, $tokens ) )
            or return $app->error(
            $app->translate( "Build error: [_1]", $build->errstr ) );
        return $html;
    }
    else {
        %params = ( no_result_template => 1, blog_id => $blog_id );
        if ( -e $error_tmpl ) {
            return $app->build_page( $error_tmpl, \%params );
        }
        else {
            return $app->error(
                $plugin->translate(
                    'Search Result Template Not exists.', $blog_id
                )
            );
        }
    }
}

sub _usercheck {
    my ( $app, $blog, $plugin ) = @_;
    my $charset      = $app->{cfg}->PublishCharset;
    my $sess_timeout = $plugin->get_config_value('members_session_timeout');
    $sess_timeout = 3600 unless $sess_timeout;
    my $q      = $app->param;
    my $cookie = $app->{cookies}->{mt_user};
    $cookie =~ s/^mt_user=(.*?)%3A%3A(.*?)%3A%3A.*$/$1,$2/;
    my @cookies    = split( /,/, $cookie );
    my $sess_id    = $cookies[1];
    my $return_uri = $app->base . $app->uri() . '?' . $app->query_string;
    $return_uri =~ s/;/&/g;

    # TODO : to adopt Mobile.

    if ($sess_id) {
        my $sess = MT::Session->load( { id => $sess_id, kind => 'US' } );
        if ( $sess && ( time - $sess->start ) < $sess_timeout ) {
            my $author_id = $sess->get('author_id');
            my $author    = $app->model('author')->load($author_id);
            if ( $author && is_user_can( $blog, $author, 'view' ) ) {
                $sess->start(time);
                $sess->save or die $sess->errstr;
                return 1;
            }
        }
    }
    my $base = $app->{cfg}->CGIPath;
    $base .= '/' if $base !~ /\/$/;
    my $memberscript = $app->{cfg}->MemberScript || 'mt-members.cgi';
    my $redirect_path
        = $base
        . $memberscript
        . '?__mode=view&return_url='
        . encode_url($return_uri)
        . '&blog_id='
        . $blog->id;
    return $app->redirect($redirect_path);
}

sub _is_login {
    my ( $app, $blog, $plugin ) = @_;
    my $cookie = $app->{cookies}->{mt_user};
    $cookie =~ s/^mt_user=(.*?)%3A%3A(.*?)%3A%3A.*$/$1,$2/;
    my @cookies   = split( /,/, $cookie );
    my $sess_id   = $cookies[1];
    my $sess_name = 'US';
    unless ($sess_id) {
        $sess_id
            = ( $app->{cookies}->{ $app->COMMENTER_COOKIE_NAME() }
            ? $app->{cookies}->{ $app->COMMENTER_COOKIE_NAME() }->value()
            : () );
        $sess_name = 'SI';
    }
    unless ($sess_id) {
        $sess_id
            = ( $app->{cookies}->{ $app->config->UserSessionCookieName }
            ? $app->{cookies}->{ $app->config->UserSessionCookieName }
                ->value()
            : () );
        if ( $sess_id =~ /sid:'(.*?)';/ ) {
            $sess_id = $1;
        }
        $sess_name = 'US';
    }
    if ($sess_id) {
        my $sess_timeout
            = $plugin->get_config_value('members_session_timeout');
        $sess_timeout = 3600 unless $sess_timeout;
        my $sess
            = MT::Session->load( { id => $sess_id, kind => $sess_name } );
        if ( $sess && ( time - $sess->start ) < $sess_timeout ) {
            my $author_id = $sess->get('author_id');
            my $author    = $app->model('author')->load($author_id);
            if ( $author && is_user_can( $blog, $author, 'view' ) ) {
                $sess->start(time);
                $sess->save or die $sess->errstr;
                return 1;
            }
        }
    }
}

1;
