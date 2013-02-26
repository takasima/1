package CreateDefaultRoles::Patch;

use strict;
use warnings;

sub init {
    # Only for override.
    # Do nothing.
}

{ no warnings 'redefine'; ## no critic

require MT::Role;
*MT::Role::create_default_roles = sub {
    my $class = shift;
    my (%param) = @_;

    my @default_roles = (
        {   name        => MT->translate('Website Administrator'),
            description => MT->translate('Can administer the website.'),
            perms       => [ 'administer_website', 'manage_member_blogs' ]
        },
        {   name        => MT->translate('Blog Administrator'),
            description => MT->translate('Can administer the blog.'),
            role_mask   => 2**12,
            perms       => ['administer_blog']
        },
        {   name        => MT->translate('Editor'),
            description => MT->translate(
                'Can upload files, edit all entries(categories), pages(folders), tags and publish the site.'
            ),
            perms => [
                'comment',         'create_post',
                'publish_post',    'edit_all_posts',
                'edit_categories', 'edit_tags',
                'manage_pages',    'rebuild',
                'upload',          'send_notifications',
                'manage_feedback', 'edit_assets'
            ],
        },
        {   name        => MT->translate('Author'),
            description => MT->translate(
                'Can create entries, edit their own entries, upload files and publish.'
            ),
            perms => [
                'comment',      'create_post',
                'publish_post', 'upload',
                'send_notifications'
            ],
        },
        {   name        => MT->translate('Designer'),
            description => MT->translate(
                'Can edit, manage, and publish blog templates and themes.'),
            role_mask => ( 2**4 + 2**7 ),
            perms     => [ 'manage_themes', 'edit_templates', 'rebuild' ]
        },
        {   name        => MT->translate('Webmaster'),
            description => MT->translate(
                'Can manage pages, upload files and publish blog templates.'),
            perms => [ 'manage_pages', 'rebuild', 'upload' ]
        },
        {   name        => MT->translate('Contributor'),
            description => MT->translate(
                'Can create entries, edit their own entries, and comment.'),
            perms => [ 'comment', 'create_post' ],
        },
        {   name        => MT->translate('Moderator'),
            description => MT->translate('Can comment and manage feedback.'),
            perms       => [ 'comment', 'manage_feedback' ],
        },
        {   name        => MT->translate('Commenter'),
            description => MT->translate('Can comment.'),
            role_mask   => 2**0,
            perms       => ['comment'],
        },
    );


    foreach my $r (@default_roles) {
next if MT::Role->count( { name => $r->{name} } );
        my $role = MT::Role->new();
        $role->name( $r->{name} );
        $role->description( $r->{description} );
        $role->clear_full_permissions;
        $role->set_these_permissions( $r->{perms} );
        if ( $r->{name} =~ m/^System/ ) {
            $role->is_system(1);
        }
        $role->role_mask( $r->{role_mask} ) if exists $r->{role_mask};
        $role->save
            or return $class->error( $role->errstr );
    }

    1;
};

}

1;
