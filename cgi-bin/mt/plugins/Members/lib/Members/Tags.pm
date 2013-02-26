package Members::Tags;

use strict;
use warnings;

use lib qw( addons/PowerCMS.pack/lib );
use PowerCMS::Util qw( build_tmpl is_application );

sub _hdlr_if_member_login {
    my ( $ctx, $args, $cond ) = @_;
    my $app  = MT->instance();
    my $user = get_user($app);
    return 0 unless defined $user;
    return is_user_can( $ctx->stash('blog'), $user, 'view' );
}

sub _hdlr_members_script {
    return MT->config('MemberScript') || 'mt-members.cgi';
}

sub _hdlr_members_login_check {
    my ( $ctx, $args, $cond ) = @_;
    my $app  = MT->instance();
    my $blog = $ctx->stash('blog');
    return unless $blog->is_members;
    my $phpcode = $args->{phpcode};
    my $mtml    = <<'MTML';
    // ========================================
    // Check Login
    // ========================================
    $cgi_url = $mt->config( 'CGIPath' );
    if ( substr( $cgi_url, strlen( $cgi_url ) - 1, 1 ) != '/' )
        $cgi_url .= '/';
    if ( preg_match( '!^(?:https?://[^/]+)?(/.*)$!', $cgi_url, $matches ) ) {
        $cgi_url = $matches[1];
    }
    $script_name = $mt->config( 'MemberScript' );
    if ( $script_name == '' ) {
        $script_name = 'mt-members.cgi';
    }
    $cgi_url .= $script_name;
    $return_url = $_SERVER[ 'REQUEST_URI' ];
    if ( preg_match( '/^[^?]*\?(.*)$/', $return_url ) ) {
        $query = preg_replace( '/^[^?]*\?(.*)$/', '$1', $return_url );
    }
    $return_url = preg_replace( '/\?.*$/', '', $return_url );
    if ( isset( $_COOKIE[ 'mt_user' ] ) ) {
        $cookie = $_COOKIE[ 'mt_user' ];
        if ( preg_match( '/^(.*?)::(.*?)::.*$/', $cookie, $match ) ) {
            $sess_id = $match[ 2 ];
        } else {
            $sess_id = $_REQUEST[ 'sessid' ];
        }
        $name = 'US';
    } else if ( isset( $_COOKIE[ 'mt_commenter' ] ) ) {
        $sess_id = $_COOKIE[ 'mt_commenter' ];
        $name = 'SI';
    } else if ( isset( $_COOKIE[ 'mt_blog_user' ] ) ) {
        $cookie = $_COOKIE[ 'mt_blog_user' ];
        if ( preg_match( "/sid:.'(.*?).'.*?$/", $cookie, $match ) ) {
            $sess_id = $match[ 1 ];
        }
        $name = 'US';
    } else {
        $sess_id = $_REQUEST[ 'sessid' ];
        $name = 'US';
    }
    $is_login = 0;
    if ( $sess_id != '' ) {
        $db = $mt->db();
        $plugin_data = $db->fetch_plugin_data( 'members', 'configuration' );
        $base = $plugin_data[ 'members_path_base' ];
        if ( $base == '' ) {
            $base = $_SERVER[ 'DOCUMENT_ROOT' ];
        }
        $base = preg_replace( '/\/$/', '', $base );
        $sql = "SELECT * FROM mt_session WHERE session_id ='{$sess_id}' and session_kind='{$name}'";
        $results = $db->Execute( $sql );
        if ( isset( $results ) ) {
            $results = $results->fields;
            $sess_obj = empty( $results ) ? NULL : $results;
            $user_id = 0;
            $user = NULL;
            $sess_data = $sess_obj[ 'session_data' ];
            $session_start = $sess_obj[ 'session_start' ];
            $plugin_data = $db->fetch_plugin_data( 'members', 'configuration' );
            $sess_timeout = $plugin_data[ 'members_session_timeout' ];
            if ( $sess_timeout == '' ) {
                $sess_timeout = 3600;
            }
            if ( $sess_obj && $sess_data
                           && ( time() - $session_start ) < $sess_timeout ) {
                $data = $db->unserialize( $sess_data );
                if ( $data ) {
                    $author_id = $data['author_id'];
                    if ( $author_id ) {
                        require_once ( 'class.mt_permission.php' );
                        $Permission = new Permission;
                        $where = "permission_author_id = '{$author_id}'"
                               . " and ("
                               . " permission_blog_id = '{$blog_id}'"
                               . " or permission_blog_id = 0"
                               . ")";
                        $results = $Permission->Find( $where );
                        if( ! empty( $results ) ) {
                            foreach ( $results as $perm_obj ) {
                                if ( preg_match( "/('view'|'administer'|'administer_website'|'administer_blog')/", $perm_obj->permission_permissions, $match ) ) {
                                    $is_login = 1;
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    if ( $is_login != 1 ) {
        header( 'HTTP/1.1 302 Found' );
        header( "Location: " . $cgi_url ."?__mode=view&return_url=" . rawurlencode( $return_url ) . "&blog_id=<mt:blogid>" );
        exit();
    }
MTML
    my %args = ( blog => $blog );
    my $code = build_tmpl( $app, $mtml, \%args );

    if ($phpcode) {
        my $init = <<'MTML';
    // ========================================
    // Include DPAPI
    // ========================================
    $mt_dir = '<$mt:CGIServerPath$>';
    $blog_id      = <$mt:BlogID$>;
    require_once $mt_dir . '/php/mt.php';
    $mt = MT::get_instance( $blog_id, '<$mt:ConfigFile$>' );
    set_error_handler( array( &$mt, 'error_handler' ) );
MTML
        my %args = ( blog => $blog );
        $code = "<?php\n" . $init . "\n" . $code . "?>";
        $code = build_tmpl( $app, $code, \%args );
    }
    return $code;
}

sub _hdlr_author_mobile_email {
    my ( $ctx, $args, $cond ) = @_;
    if ( my $author = $ctx->stash('author') ) {
        return $author->mobile_address || '';
    }
    return '';
}

sub _hdlr_author_mobile_token {
    my ( $ctx, $args, $cond ) = @_;
    if ( my $author = $ctx->stash('author') ) {
        return $author->mail_token || '';
    }
    return '';
}

sub _hdlr_field_query {
    my ($ctx) = @_;
    my $app   = MT->instance();
    my $field = $ctx->stash('field')
        or return $ctx->error(
        MT->translate(
            "You used an '[_1]' tag outside of the context of the correct content; ",
            $ctx->stash('tag')
        )
        );
    my $basename   = $field->basename;
    my $query      = $app->param( 'customfield_' . $basename );
    my $date_query = $app->param( 'd_customfield_' . $basename );
    my $time_query = $app->param( 't_customfield_' . $basename );
    if ( $date_query && $time_query ) {
        $query = $date_query . ' ' . $time_query;
    }
    elsif ($date_query) {
        $query = $date_query;
    }
    elsif ($time_query) {
        $query = $time_query;
    }
    return $query if $query;
    return '';
}

sub _hdlr_modifier {
    return $_[0];
}

sub _fltr_add_session_for_mobile {
    my($str, $arg, $ctx) = @_;
    unless ($arg) {
        return $str;
    }
    my $blog = $ctx->stash('blog')
        or return $str;
    my $app = MT->instance()
        or return $str;
    unless (is_application($app)) {
        return $str;
    }
    my $key    = 'sessid';
    my $sessid = $app->param($key);
    unless (defined $sessid && $sessid =~ /^[A-Za-z0-9]{40}$/) {
        return $str;
    }
    my $re_path = $arg =~ m{^(?i:https?:)?//}
                ? $arg
                : $blog->site_url();
    $re_path =~ s{^((?i:https?:)?//[^/]+)(.*?)/*$}{^(?i:$1)?$2/};
    $re_path = qr/$re_path/;
    my $base = $ctx->stash('current_archive_url');
    if (!defined $base &&
        (ref $app) =~ /^MT::App::Co(?:mments|ntactForm)$/) {
        $base = $app->config('CGIPath');
    }
    $str =~ s{
        ( < (?i: a   (?: \s [^>]*)? \s href
               | img (?: \s [^>]*)? \s src ) \s* = \s* ["']? )
        ( (?<= ") [^"]+ | (?<= ') [^']+ | [^\s<="'`>]+ )
    }{
        my $ret = $1;
        my($p, $f) = split /#/, $2 || '', 2;
        if ($p eq '') {
            $ret .= "#$f";
        } else {
            my $q;
            ($p, $q) = split /\?/, $p, 2;
            unless (defined $p) { $p = '' }
            unless (defined $q) { $q = '' }
            my $path = $p;
            unless ($p =~ m{^(?i:https?:/)?/}) {
                require URI;
                $path = URI->new_abs($p, $base);
            }
            if ($path =~ $re_path) {
                my $s = ($q =~ /([&;])/)[0] || '&';
                $q = join $s, ((grep !/\Q$key\E=/, split /[&;]+/, $q), "$key=$sessid");
            }
            $ret .= $p;
            $ret .= "?$q" if $q ne '';
            $ret .= "#$f" if defined $f;
        }
        $ret;
    }egx;
    $str;
}

1;
