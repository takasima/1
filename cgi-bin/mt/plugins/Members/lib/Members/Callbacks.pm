package Members::Callbacks;

use strict;
use warnings;

use MT::Role;
use MT::Template;

use lib qw( addons/PowerCMS.pack/lib );
use PowerCMS::Util
    qw( save_asset association_link is_ua_mobile file_extension site_url
    uniq_filename set_upload_filename utf8_on read_from_file send_mail
    support_dir is_image upload build_tmpl valid_email get_mobile_id
    is_ua_keitai is_user_can current_blog );

use Members::Tags;
use Members::Util;

sub _cb_api_save_filter_comment {
    my ( $cb, $app ) = @_;
    my $entry_id = $app->param( 'entry_id' );
    my $entry = MT::Entry->load( $entry_id );
    my $blog = $app->model( 'blog' )->load( $entry->blog_id );
    if ( $blog->is_members ) {
        unless ( $app->user ) {
            my $sessid = $app->param( 'sessid' ) or return $app->trans_error( 'Invalid login.' );
            unless ( Members::Util::is_active_session( $sessid ) ) {
                return $app->trans_error( 'Invalid login.' );
            }
        }
    }
1;
}

sub _contactform_pre_redirect {
    my ( $cb, $app, $feedback, $return_url_ref ) = @_;
    my $group_id = $feedback->contactform_group_id;
    my $contactformgroup = MT->model( 'contactformgroup' )->load( { id => $group_id } );
    if ( $contactformgroup && $contactformgroup->requires_login ) {
        if ( my $sessid = $app->param( 'sessid' ) ) {
            $$return_url_ref .= ( ( $$return_url_ref =~ /\?/ ) ? "&" : "?" ) . "sessid=$sessid";
        }
    }
}

sub _post_run {
    my $app = MT->instance();
    my $install;
    if ( ( ref $app ) eq 'MT::App::Upgrader' ) {
        if ( $app->mode eq 'run_actions' ) {
            if ( $app->param('installing') ) {
                $install = 1;
            }
        }
    }
    if ($install) {
        Members::Util::_install_role();
    }
    return 1;
}

sub _cfg_prefs_param {
    my ( $cb, $app, $param, $tmpl ) = @_;

    my $plugin = MT->component('Members');

    my $pointer_field = $tmpl->getElementById('description');
    my $nodeset       = $tmpl->createElement(
        'app:setting',
        {   id       => 'is_members',
            label    => $plugin->translate("Member's"),
            required => 0,
        }
    );
    my $label     = $plugin->translate('View Only Member');
    my $innerHTML = <<__EOF__;
    <div><label>
    <input type="checkbox" name="is_members" id="is_members" value="1"
        <mt:if name="is_members"> checked="checked"</mt:if> />
    $label</label><input type="hidden" name="is_members" value="0" />
    </div>
__EOF__
    $nodeset->innerHTML($innerHTML);
    $tmpl->insertAfter( $nodeset, $pointer_field );
}

sub _cb_tmpl_source {
    my ( $cb, $app, $tmpl ) = @_;
    my $id = $cb->name;
    $id = $1 if ( $id =~ /\.([^.]+)$/ );
    $id = "members_$id";
    if ( $id !~ m/_notify_/ ) {
        $id .= '_mobile' if ( is_ua_keitai($app) );
    }
    my $src = _load_tmpl( $app, $app->blog, $id );
    $$tmpl = @$src[0] if $src;
}

sub _load_tmpl {
    my ( $app, $blog, $id ) = @_;
    my $plugin = MT->component('Members');

    my $blog_id = 0;
    if ( defined($blog) ) {
        $blog_id = $blog->id;
    }
    my $template = MT::Template->load(
        {   blog_id    => $blog_id,
            identifier => $id
        }
    );
    my $src = $template->text    if defined $template;
    my $sub = $template->subject if defined $template;
    $src
        = read_from_file(
        File::Spec->catdir( $plugin->path, 'tmpl', "$id.tmpl" ) )
        unless defined $template;
    $sub
        = read_from_file(
        File::Spec->catdir( $plugin->path, 'tmpl', "${id}_subject.tmpl" ) )
        unless defined $template;
    my @res = ( $src, $sub );
    return \@res;
}

sub _do_plugin_setting {
    my ( $cb, $app, $obj, $original ) = @_;
    my $plugin = MT->component('Members');

    return 1 unless $obj->is_members;

    my $members_role
        = MT::Role->get_by_key( { name => $plugin->translate('Members') } );
    if ( !$members_role->id ) {
        my %values;
        $values{created_by}  = 1;
        $values{description} = $plugin->translate('Can view pages.');
        $values{is_system}   = 0;
        $values{permissions} = "'view'";
        $members_role->set_values( \%values );
        $members_role->save
            or return $app->trans_error( 'Error saving role: [_1]',
                $members_role->errstr );

        # Tasks ... $app->log();
    }

    return 1;
}

sub _notify_registered {
    my ( $cb, $app, $obj, $original ) = @_;
    return 1 unless $obj->regist_blog_id;
    if ( ( $app->mode eq 'enable_object' ) || ( $app->mode eq 'save' ) ) {
        if ( defined $original ) {
            if (   ( $original->status == MT::Author::PENDING() )
                && ( $obj->status == MT::Author::ACTIVE() ) )
            {
                require MT::Permission;
                my @blogs = MT::Blog->load(
                    undef,
                    {   join => [
                            'MT::Permission',
                            'blog_id',
                            {   author_id   => $obj->id,
                                blog_id     => { not => 0 },
                                permissions => { like => "%'view'%" },
                            },
                            undef
                        ],
                        no_class => 1,
                    },
                );
                return 1 unless @blogs;
                my @regist_blogs = grep { $_->id eq $obj->regist_blog_id } @blogs;
                my $blog = $regist_blogs[0];
                unless ( $blog ){
                    $blog = shift @blogs;
                }
                return 1 unless $blog;
                my %args = ( blog => $blog, author => $obj, );
                my $return_url = site_url($blog) . '/';
                if ( $obj->is_mobile_signup ) {
                    my $template_mobile_main_index
                        = MT->model('template')->load(
                        {   blog_id    => $blog->id,
                            identifier => 'mobile_main_index'
                                . (
                                $blog->class eq 'website' ? '_website' : ''
                                ),
                            type => 'index',
                        }
                        );
                    if ($template_mobile_main_index) {
                        my $outfile = $template_mobile_main_index->outfile;
                        $return_url .= $outfile;
                    }
                }
                my $login_url
                    = $app->base
                    . $app->app_path
                    . Members::Tags::_hdlr_members_script()
                    . '?blog_id='
                    . $blog->id
                    . '&return_url='
                    . $return_url;
                my %params = ( login_url => $login_url );
                my $template
                    = _load_tmpl( $app, $blog, 'members_notify_u_t' );
                return 1 unless $template;
                my $from = Members::Util::_mail_from();
                my $body
                    = build_tmpl( $app, @$template[0], \%args, \%params );
                my $subject
                    = build_tmpl( $app, @$template[1], \%args, \%params );
                my $email = $obj->email;
                $email .= ',' . $obj->mobile_address if $obj->mobile_address;
                my $result = send_mail( $from, $email, $subject, $body );
            }
        }
    }
    return 1;
}

sub _pre_search {
    my $app = MT->instance();
    my @search_id;
    my $blog_id = $app->param('blog_id');
    if ($blog_id) {
        if ( !$app->param('IncludeBlogs') ) {
            return unless $app->blog->is_members;
            my $user = current_user($app);
            if ($user) {
                return is_user_can( $app->blog, $user, 'view' );
            }
        }
    }
    push( @search_id, $blog_id ) if $blog_id;
    my $IncludeBlogs = $app->param('IncludeBlogs');
    push( @search_id, split( /,/, $IncludeBlogs ) ) if $IncludeBlogs;
    if ( scalar @search_id ) {
        my $count = MT::Blog->count( { id => \@search_id, is_members => 1 } );
        return 0 if $count;
    }
    else {
        my @exclude_id;
        my $ExcludeBlogs = $app->param('ExcludeBlogs');
        push( @exclude_id, split( /,/, $ExcludeBlogs ) ) if $ExcludeBlogs;
        my @blog = MT::Blog->load( { is_members => 1 } );
        for my $b (@blog) {
            my $blog_id = $b->id;
            if ( grep( /^$blog_id$/, @exclude_id ) ) {
                next;
            }
            return 0;
        }
    }
    return 1;
}

sub _recover_mail_filter {
    my $cb       = shift;
    my (%params) = @_;
    my $app      = MT->instance();
    return 1 if ( ( ref $app ) ne 'MT::App::CMS::Members' );
    return 1 if ( $app->mode ne 'recover' );
    my $blog = current_blog($app);
    return 1 unless $blog;
    my $body = $params{body};
    $body = $$body;

    if ( $body =~ m!(^https?://[^?]+\?.*?__mode=new_pw&token=.*)!m ) {
        my $url = $1;
        my $template = _load_tmpl( $app, $blog, 'members_notify_recover' );
        return 1 unless $template;
        my %params = ( link_to_login => $url );
        my %args   = ( blog          => $blog );
        my $subject  = build_tmpl( $app, @$template[1], \%args, \%params );
        my $new_body = build_tmpl( $app, @$template[0], \%args, \%params );
        my $from     = Members::Util::_mail_from();
        my $to       = $app->param('email');
        if ( $app->param('mobile_address') ) {
            $to = $app->param('mobile_address');
        }
        return 1 unless $to;
        my $res = send_mail( $from, $to, $subject, $new_body );
        return 0;
    }
    return 1;
}

sub filtered_list_author {
    my ( $cb, $app, $filter, $load_options, $cols ) = @_;
    my $plugin = MT->component('Members');

    my $args = $load_options->{args} || {};

    if ( my $fid = $app->param('fid') ) {
        if ( $fid eq 'members' ) {
            my $role
                = MT::Role->load( { name => $plugin->translate('Members') } );
            if ($role) {
                require MT::Association;
                $args->{'join'} = MT::Association->join_on(
                    'author_id',
                    { role_id => $role->id, },
                    { unique  => 1, },
                );
            }
        }
    }
}

sub _cb_build_file_filter {
    my($eh, %args) = @_;
    if (my $ctx = $args{Context}) {
        unless ($ctx->stash(my $var = 'current_archive_url')) {
            if (defined $args{FileInfo}) {
                $ctx->stash($var, $args{FileInfo}->url);
            }
            elsif (defined $args{File} and defined $args{Blog}) {
                $ctx->stash($var,
                    PowerCMS::path2url($args{File}, $args{Blog}));
            }
        }
    }
    1;
}

1;
