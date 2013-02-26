package MT::Plugin::PermissionFilterPCMS;
use strict;
use MT;
use MT::Plugin;
use base qw( MT::Plugin );

no warnings 'redefine';

my $plugin = __PACKAGE__->new( {
    id   => 'PermissionFilterPCMS',
    key  => 'permissionfilterpcms',
    name => 'PermissionFilterPCMS',
    author_name => 'Alfasado Inc.',
    author_link => 'http://alfasado.net/',
    description => 'PermissionFilter Security Filter for PowerCMS.',
    version => '1.4',
} );

sub init_registry {
    my $plugin = shift;
    my $app = MT->instance();
    my $pkg = 'cms_';
    my $pfx = '$Core::MT::CMS::';
    $plugin->registry( {
        applications => {
            cms => {
                callbacks => {
                    $pkg
                        . 'save_permission_filter.grouporder' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'delete_permission_filter.grouporder' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'save_permission_filter.contactformorder' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'delete_permission_filter.contactformorder' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'save_permission_filter.campaignorder' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'delete_permission_filter.campaignorder' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'save_permission_filter.itemgroup' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'delete_permission_filter.itemgroup' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'save_permission_filter.itemorder' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'delete_permission_filter.itemorder' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'save_permission_filter.sortnum' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'delete_permission_filter.sortnum' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'save_permission_filter.sortgroup' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'delete_permission_filter.sortgroup' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'save_permission_filter.objectorder' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'delete_permission_filter.objectorder' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'save_permission_filter.linkorder' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'delete_permission_filter.linkorder' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'save_permission_filter.customobjectorder' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'delete_permission_filter.customobjectorder' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'save_permission_filter.cmscache' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'delete_permission_filter.cmscache' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'save_permission_filter.assetorder' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'delete_permission_filter.assetorder' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'save_permission_filter.templateorder' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'delete_permission_filter.templateorder' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'save_permission_filter.cptasks' => sub {
                        return __is_admin();
                    },
                    $pkg
                        . 'delete_permission_filter.cptasks' => sub {
                        return __is_admin();
                    },
                    $pkg
                        . 'save_permission_filter.powerrevision' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'delete_permission_filter.powerrevision' => sub {
                        my ( $cb, $app, $obj ) = @_;
                        my $user = $app->user;
                        return 1 if $user->is_superuser();
                        if ( $obj->object_class eq 'page' ) { # page
                            if (! is_user_can( $obj->blog, $user, 'manage_pages' ) ) {
                                return $app->error( $app->translate( "Invalid request." ) );
                            }
                        } elsif ( $obj->object_class eq 'entry' ) { # entry
                            if (! is_user_can( $obj->blog, $user, 'create_post' ) && ! is_user_can( $obj->blog, $user, 'edit_all_posts' ) ) {
                                return $app->error( $app->translate( "Invalid request." ) );
                            }
                            if ( ! is_user_can( $obj->blog, $user, 'edit_all_posts' ) ) {
                                if ( $obj->author_id != $user->id ) {
                                    return $app->error( $app->translate( "Invalid request." ) );
                                }
                            }
                        }
                        return 1;
                    },
                    $pkg
                        . 'save_permission_filter.temporarylog' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'delete_permission_filter.temporarylog' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'save_permission_filter.templatereg' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'delete_permission_filter.templatereg' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'save_permission_filter.tempfile' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'delete_permission_filter.tempfile' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'save_permission_filter.temporaryfile' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'delete_permission_filter.temporaryfile' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'save_permission_filter.pcmslv' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'delete_permission_filter.pcmslv' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'save_permission_filter.pcmslvurls' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'delete_permission_filter.pcmslvurls' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'save_permission_filter.pcmslvsummary' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'delete_permission_filter.pcmslvsummary' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'save_permission_filter.pcmslvlasturls' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'delete_permission_filter.pcmslvlasturls' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'save_permission_filter.pcmslvreportsession' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'delete_permission_filter.pcmslvreportsession' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'save_permission_filter.pcmslvuserinfo' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'delete_permission_filter.pcmslvuserinfo' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'save_permission_filter.pcmslvreferrer' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'delete_permission_filter.pcmslvreferrer' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'save_permission_filter.pcmslvreferrersite' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'delete_permission_filter.pcmslvreferrersite' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'save_permission_filter.pcmslvsearch' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'delete_permission_filter.pcmslvsearch' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'save_permission_filter.pcmslvkeywords' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'delete_permission_filter.pcmslvkeywords' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'save_permission_filter.pcmslvlastkeywords' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'delete_permission_filter.pcmslvlastkeywords' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'save_permission_filter.pcmslvusersummary' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'delete_permission_filter.pcmslvusersummary' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'save_permission_filter.formvalue' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'delete_permission_filter.formvalue' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'save_permission_filter.extfields' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'delete_permission_filter.extfields' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'save_permission_filter.mailmagazine' => sub {
                        $app->error( $app->translate( "Invalid request." ) );
                    },
                    $pkg
                        . 'delete_permission_filter.mailmagazine' => sub {
                        my ( $cb, $app, $obj ) = @_;
                        my $user = $app->user;
                        return 1 if $user->is_superuser();
                        my $class = MT->model( 'blog' );
                        my $blog = $class->load( $obj->blog_id );
                        if (! is_user_can( $blog, $user, 'create_mailmagazine' ) ) {
                            $app->error( $app->translate( "Invalid request." ) );
                        } else {
                            return 1;
                        }
                    },
                    $pkg
                        . 'cms_pre_save.extraform' => sub {
                        my ( $cb, $app, $obj ) = @_;
                        my $user = $app->user;
                        return 1 if $user->is_superuser();
                        if (! is_user_can( $obj->blog, $user, 'manage_feedback' ) ) {
                            return 0;
                        }
                    },
                    $pkg
                        . 'delete_permission_filter.extraform' => sub {
                        my ( $cb, $app, $obj ) = @_;
                        my $user = $app->user;
                        return 1 if $user->is_superuser();
                        if (! is_user_can( $obj->blog, $user, 'manage_feedback' ) ) {
                            $app->error( $app->translate( "Invalid request." ) );
                        }
                    },
                },
            },
        },
    } );
}

sub is_user_can {
    my ( $blog, $user, $permission ) = @_;
    $permission = 'can_' . $permission;
    my $perm = $user->is_superuser;
    unless ( $perm ) {
        if ( $blog ) {
            my $admin = 'can_administer_blog';
            $perm = $user->permissions( $blog->id )->$admin ||
                    $user->permissions( $blog->id )->$permission;
        } else {
            $perm = $user->permissions()->$permission;
        }
    }
    return $perm;
}

sub __invalidate_magic {
    my $app = shift;
    $app->user( undef );
    if ( ( $app->{ query } ) && ( $app->{ query }->{ param } ) ) {
        $app->{ query }->{ param }->{ __mode } = '';
    }
    $app;
}

sub __is_admin {
    my $app = MT->instance;
    my $perms = $app->permissions;
    my $user  = $app->user;
    my $admin = $user->is_superuser
      || ( $perms && $perms->can_administer_blog );
    if ( ! $admin ) {
        return 0;
    }
    return 1;
}

MT->add_plugin( $plugin );

1;
