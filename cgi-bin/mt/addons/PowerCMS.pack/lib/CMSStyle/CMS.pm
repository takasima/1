package CMSStyle::CMS;
#use strict;

use MT::Util qw( encode_html );
use PowerCMS::Util qw( current_user get_powercms_config set_powercms_config utf8_on );
use CMSStyle::Util;

sub _blog_selector_redirect {
    my ( $app, $blog_id, $type, $tmpl ) = @_;
    my %param;
    my $return_url = $app->base . $app->uri( mode => 'view',
                                             args => { blog_id => $blog_id,
                                                       _type   => $type,
                                             },
                                           );
    $param{ 'redirect' } = $return_url;
    return $app->build_page( $tmpl, \%param );
}

sub _mode_blog_selector {
    my $app = shift;
    my $plugin = MT->component( 'PowerCMS' );
    my $user = current_user( $app );
    my $mode = $app->mode;
    my $type;
    if ( $mode =~ /^blogselector_(.*)$/ ) {
        $type = $1;
    }
    unless ( $type && $type =~ /^(?:entry|page)$/ ) {
        return $app->trans_error( 'Invalid request.' );
    }
    my $tmpl = $plugin->load_tmpl( 'cmsstyle_select_blog.tmpl' );
    my $class = $type eq 'page' ? '*' : 'blog';
    require MT::Blog;
    my @blogs = MT::Blog->load( { class => $class } );
    if ( @blogs == 1 ) {
        my $blog = $blogs[ 0 ];
        if ( CMSStyle::Util::has_permission( $type, $blog ) ) {
            return _blog_selector_redirect( $app, $blog->id, $type, $tmpl );
        }
        return $app->trans_error( 'Permission denied.' );
    }
    unless ( @blogs ) {
        return $app->build_page( $tmpl, { type => $type } );
    }
    my @tmpl_loop;
    for my $blog ( @blogs ) {
        if ( CMSStyle::Util::has_permission( $type, $blog ) ) {
            push( @tmpl_loop, $blog->get_values );
        }
    }
    unless ( @tmpl_loop ) {
        return $app->trans_error( 'Permission denied.' );
    }
    if ( @tmpl_loop == 1 ) {
        my $v = $tmpl_loop[ 0 ];
        return _blog_selector_redirect( $app, $v->{ blog_id }, $type, $tmpl );
    }
    my %param;
    $param{ type } = $type;
    $param{ tmpl_loop } = \@tmpl_loop;
    return $app->build_page( $tmpl, \%param );
}

sub _mode_lock_mt {
    my $app = shift;
    my $user = current_user( $app );
    unless ( $user->is_superuser && $app->validate_magic ) {
        return $app->trans_error( 'Permission denied.' );
    }
    my $plugin = MT->component( 'PowerCMS' );
    my $plugin_template_path = File::Spec->catdir( $plugin->path, 'tmpl' );
    $app->{ plugin_template_path } = $plugin_template_path;
    my $tmpl = 'simple_message.tmpl';
    require MT::Log;
    my $log = MT::Log->new;
    $log->class( 'workflow' );
    $log->author_id( $user->id );
    $log->level( MT::Log::INFO() );
    my %param;
    my $mode = $app->mode;
    if ( $mode eq 'lock_mt' ) {
        set_powercms_config( 'powercms', 'unavailable', 1 );
        $param{ 'page_title' } = $plugin->translate( 'Locked' );
        $param{ 'page_msg' } = $plugin->translate( 'MT was locked.' );
        $log->message( $plugin->translate( 'MT was locked.' ) );
    } else {
        set_powercms_config( 'powercms', 'unavailable', 0 );
        $param{ 'page_title' } = $plugin->translate( 'Unlocked' );
        $param{ 'page_msg' } = $plugin->translate( 'MT was unlocked.' );
        $log->message( $plugin->translate( 'MT was unlocked.' ) );
    }
    $param{ 'return_args' } = '';
    $log->save or die $log->errstr;
    return $app->build_page( $tmpl, \%param );
}

sub _mode_contents_for_validation {
    my $app = shift;
    unless ( $app->validate_magic ) {
        return $app->trans_error( 'Permission denied.' );
    }
    if ( my $preview_basename = $app->param( '_preview_file' ) ) {
        my $session = MT->model( 'session' )->load( { id => "MarkupValidation:$preview_basename",
                                                      kind => 'MV',
                                                    }
                                                  );
        if ( $session ) {
            return MT->config->PublishCharset =~ /^utf-?8$/i
                        ? utf8_on( $session->data )
                        : $session->data;
        }
    }
    return '';
}

1;
