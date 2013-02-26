package MT::Plugin::mixiComment;

use strict;
use warnings;

use MT;
use base qw(MT::Plugin);

my $plugin = MT::Plugin::mixiComment->new(
    {   id          => 'mixicomment',
        name        => 'mixiComment',
        author_name => 'Six Apart, Ltd.',
        author_url  => 'http://www.movabletype.org/',
        description =>
            '<__trans phrase="Allows commenters to sign in to Movable Type using their own mixi username and password via OpenID.">',
        version => '1.31',
        settings =>
            new MT::PluginSettings( [ [ 'mixi_id', { Scope => 'blog' } ], ] ),
        l10n_class           => 'mixiComment::L10N',
        blog_config_template => 'config.tmpl',
    }
);
MT->add_plugin($plugin);

sub load_config {
    my $plugin = shift;
    my ( $args, $scope ) = @_;

    $plugin->SUPER::load_config(@_);

    if ( $scope =~ /blog:(\d+)/ ) {
        my $blog_id = $1;
        $args->{blog_id} = $blog_id;
    }
}

sub init_registry {
    my $plugin = shift;
    $plugin->registry(
        {   applications => {
                cms => {
                    methods => {
                        mixicomment_login_blog_owner =>
                            '$mixicomment::mixiComment::App::login_blog_owner',
                        mixicomment_verify_blog_owner =>
                            '$mixicomment::mixiComment::App::verify_blog_owner',
                    }
                }
            },
            commenter_authenticators => {
                'mixicomment' => {
                    label      => 'mixi',
                    class      => 'mixiComment::Auth::mixi',
                    login_form => <<EOT,
<__trans_section component="mixicomment">
<form method="post" action="<mt:var name="script_url">">
<input type="hidden" name="__mode" value="login_external" />
<input type="hidden" name="openid_url" value="<mt:var name="url">" />
<input type="hidden" name="blog_id" value="<mt:var name="blog_id">" />
<input type="hidden" name="entry_id" value="<mt:var name="entry_id">" />
<input type="hidden" name="static" value="<mt:var name="static" escape="html">" />
<input type="hidden" name="key" value="mixicomment" />
<div class="actions-bar actions-bar-login">
<input type="image" src="<mt:var name="static_uri">plugins/mixiComment/images/mixi_button.gif" width="150" height="28" />
</div>
</form>
</__trans_section>
EOT
                    condition =>
                        '$mixicomment::mixiComment::App::openid_commenter_condition',
                    login_form_params =>
                        '$mixicomment::mixiComment::App::commenter_auth_params',
                    logo => 'plugins/mixiComment/images/signin_mixi.png',
                    logo_small =>
                        'plugins/mixiComment/images/signin_mixi_small.gif'
                },
            },
        }
    );
}

sub instance {$plugin}

1;
__END__
