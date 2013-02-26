package Members::Util;

use strict;
use warnings;

use lib qw( addons/PowerCMS.pack/lib );
use PowerCMS::Util
    qw( save_asset association_link is_ua_mobile file_extension site_url
    uniq_filename set_upload_filename utf8_on read_from_file send_mail
    support_dir is_image upload build_tmpl valid_email get_mobile_id
    is_ua_keitai is_user_can current_blog );

sub is_active_session {
    my ( $session_id ) = @_;
    my $sess = MT->model( 'session' )->load( { id => $session_id } );
    return unless $sess;
    my $plugin = MT->component( 'Members' );
    my $sess_timeout = $plugin->get_config_value( 'members_session_timeout' );
    $sess_timeout = 3600 unless $sess_timeout;
    if ( ( time - $sess->start ) < $sess_timeout ) {
        return 1;
    }
    return; # TIMEOUT
}

sub _install_role {
    require MT::Role;
    my $app    = MT->instance();
    my $plugin = MT->component('Members');

    my $members_role
        = MT::Role->get_by_key( { name => $plugin->translate('Members') } );
    if ( !$members_role->id ) {
        my %values;
        $values{created_by}  = $app->user->id if $app->user;
        $values{description} = $plugin->translate('Can view pages.');
        $values{is_system}   = 0;
        $values{permissions} = "'view'";
        $members_role->set_values( \%values );
        $members_role->save
            or return $app->trans_error( 'Error saving role: [_1]',
            $members_role->errstr );

        $app->log( $plugin->translate('Member Role installed.') );
    }
}

sub _mail_from {
    my $app    = MT->instance();
    my $plugin = MT->component('Members');

    my $email_from;
    if ( current_blog($app) ) {
        $email_from = $plugin->get_config_value( 'members_email_from',
            'blog:' . $app->blog->id );
    }
    $email_from = $plugin->get_config_value('members_email_from')
        unless $email_from;
    $email_from = $app->config->EmailAddressMain unless $email_from;
    return $email_from;
}

sub _mail_to {
    my $app    = MT->instance();
    my $plugin = MT->component('Members');

    my $email_notify2;
    if ( current_blog($app) ) {
        $email_notify2 = $plugin->get_config_value( 'members_email_notify2',
            'blog:' . $app->blog->id );
    }
    $email_notify2 = $plugin->get_config_value('members_email_notify2')
        unless $email_notify2;
    $email_notify2 = $app->config->EmailAddressMain unless $email_notify2;
    return $email_notify2;
}

1;
