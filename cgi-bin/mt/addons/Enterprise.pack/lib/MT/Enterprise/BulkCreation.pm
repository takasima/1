# Movable Type (r) (C) 2006-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package MT::Enterprise::BulkCreation;
use strict;
use warnings;
use Carp;

use MT::Util qw(is_valid_email);
use I18N::LangTags qw(is_language_tag);

use MT::Author qw( AUTHOR ACTIVE );

use MT::ErrorHandler;
use base qw( MT::ErrorHandler );

my %commands = (
    register => 13,
    update   => 6,
    delete   => 2,
);

sub do_bulk_create {
    my $obj   = shift;
    my %param = @_;

    my $line_number = $param{LineNumber};
    my $line        = $param{Line};
    my $cb          = $param{Callback} || sub { };
    my $app         = $param{App};

    my ( $command, $error ) = $obj->_parse_line($line);
    if ($error) {
        my $message = MT->translate( "Formatting error at line [_1]: [_2]",
            $line_number, $error );
        require MT::Log;
        $app->log(
            {   message  => $message,
                level    => MT::Log::ERROR(),
                class    => 'system',
                category => 'create_author_bulk'
            }
        );

        return $obj->error($message);
    }

    $obj->$command( $app, $cb, @$line );
}

sub _parse_line {
    my $obj = shift;
    my ($lineref) = @_;

    $lineref->[0] = lc $lineref->[0];

    if ( !exists( $commands{ $lineref->[0] } ) ) {
        return ( undef,
            MT->translate( 'Invalid command: [_1]', $lineref->[0] ) );
    }
    my $num_items = scalar @$lineref;
    if ( $commands{ $lineref->[0] } != $num_items ) {
        return (
            $lineref->[0],
            MT->translate(
                "Invalid number of columns for [_1]",
                $lineref->[0]
            )
        );
    }
    my $method = '_parse_line_' . $lineref->[0];
    return $obj->$method($lineref);
}

sub _is_valid_username {
    my $obj = shift;
    my ($username) = @_;
    if (   ( length($username) < 1 )
        || ( length($username) > 255 )
        || ( index( $username, '\n' ) > -1 ) )
    {
        return $obj->error(
            MT->translate( "Invalid user name: [_1]", $username ) );
    }
    if ( $username =~ m/^\s*$/ ) {
        return $obj->error(
            MT->translate( "Invalid user name: [_1]", $username ) );
    }
    if ( $username =~ m/([<>])/ ) {
        return $obj->error(
            MT->translate( "Invalid user name: [_1]", $username ) );
    }
    1;
}

sub _is_valid_nickname {
    my $obj = shift;
    my ($nickname) = @_;
    if (   ( length($nickname) < 1 )
        || ( length($nickname) > 255 )
        || ( index( $nickname, '\n' ) > -1 ) )
    {
        return $obj->error(
            MT->translate( "Invalid display name: [_1]", $nickname ) );
    }
    if ( $nickname =~ m/^\s*$/ ) {
        return $obj->error(
            MT->translate( "Invalid display name: [_1]", $nickname ) );
    }
    if ( $nickname =~ m/([<>])/ ) {
        return $obj->error(
            MT->translate( "Invalid display name: [_1]", $nickname ) );
    }
    1;
}

sub _parse_line_register {
    my $obj       = shift;
    my ($lineref) = @_;
    my @line      = @$lineref;
    my $create_blog;
    my $command = $lineref->[0];

    # username
    $obj->_is_valid_username( $lineref->[1] )
        or return ( $command, $obj->errstr );

    # nickname
    $obj->_is_valid_nickname( $lineref->[2] )
        or return ( $command, $obj->errstr );

    #email
    if (   length( $lineref->[3] ) < 1
        || length( $lineref->[3] ) > 127
        || index( $lineref->[3], '\n' ) > -1
        || !is_valid_email( $lineref->[3] ) )
    {
        return ( $command,
            MT->translate( "Invalid email address: [_1]", $lineref->[3] ) );
    }

    #language
    if ( length( $lineref->[4] ) == 0 ) {
        $lineref->[4] = MT->config->DefaultLanguage || 'en';
    }

    if ( !is_language_tag( $lineref->[4] ) ) {
        return ( $command,
            MT->translate( "Invalid language: [_1]", $lineref->[4] ) );
    }

    #initial password
    my $authentication_mode = MT->config->AuthenticationModule || 'MT';
    if ( $authentication_mode eq 'MT' ) {
        if (   ( length( $lineref->[5] ) < 1 )
            || ( length( $lineref->[5] ) > 60 )
            || ( index( $lineref->[5], '\n' ) > -1 ) )
        {
            return ( $command,
                MT->translate( "Invalid password: [_1]", $lineref->[5] ) );
        }
        if ( $lineref->[5] =~ m/^\s*$/ ) {
            return ( $command,
                MT->translate( "Invalid password: [_1]", $lineref->[5] ) );
        }
    }

    #weblog name
    $lineref->[6] =~ s/^\s*$//;
    if ( length( $lineref->[6] ) != 0 ) {

        if ( !defined MT->config->NewUserDefaultWebsiteId ) {
            return (
                $command,
                MT->translate(
                    "'Personal Blog Location' setting is required to create new user blogs."
                )
            );
        }

        if (   ( length( $lineref->[6] ) < 1 )
            || ( length( $lineref->[6] ) > 255 )
            || ( index( $lineref->[6], '\n' ) > -1 ) )
        {
            return ( $lineref->[0],
                MT->translate( "Invalid weblog name: [_1]", $lineref->[6] ) );
        }

        #weblog description
        $lineref->[7] =~ s/^\s*$//;

        #site url and site root
        $lineref->[8]  =~ s/^\s*$//;    # subdomain
        $lineref->[9]  =~ s/^\s*$//;    # site url
        $lineref->[10] =~ s/^\s*$//;    # site path

        return ( $lineref->[0],
            MT->translate( "Invalid blog URL: [_1]", $lineref->[8] ) )
            if !length( $lineref->[8] ) && !length( $lineref->[9] );
        if ( $lineref->[8] =~ m/[<>"{}|\\^\[\]`]+/ ) {
            return ( $command,
                MT->translate( "Invalid blog URL: [_1]", $lineref->[8] ) );
        }
        if ( $lineref->[9] =~ m/[<>"{}|\\^\[\]`]+/ ) {
            return ( $command,
                MT->translate( "Invalid blog URL: [_1]", $lineref->[9] ) );
        }
        if ( length( $lineref->[10] ) == 0 ) {
            return ( $lineref->[0],
                MT->translate( "Invalid site root: [_1]", $lineref->[10] ) );
        }

        #timezone
        $lineref->[11] =~ s/^\s*$//;
        if ( length( $lineref->[11] ) != 0 ) {
            if ( $lineref->[11] =~ m/^[\+-][0-9]{2}(?:00|30)$/ ) {
                $lineref->[11] =~ s/^(?:(?:\+|(-))0?([1-9]?[0-9])00)$/$2/;
                $lineref->[11] =~ s/^(?:(?:\+|(-))0?([1-9]?[0-9])30)$/$2\.5/;
            }
            else {
                return ( $lineref->[0],
                    MT->translate( "Invalid timezone: [_1]", $lineref->[11] )
                );
            }
        }
        else {
            return ( $lineref->[0],
                MT->translate( "Invalid timezone: [_1]", $lineref->[11] ) );
        }

        #theme ID
        if ( $lineref->[12] !~ /^[a-z][a-z0-9\-\_]+$/i ) {
            return ( $lineref->[0],
                MT->translate( "Invalid theme ID: [_1]", $lineref->[12] ) );
        }
    }
    return ( $lineref->[0], undef );
}

sub _parse_line_update {
    my $obj       = shift;
    my ($lineref) = @_;
    my @line      = @$lineref;
    my $command   = $lineref->[0];
    $lineref->[3] =~ s/^\s*$//;
    $lineref->[4] =~ s/^\s*$//;
    $lineref->[5] =~ s/^\s*$//;

    # username
    $obj->_is_valid_username( $lineref->[1] )
        or return $obj->error( $command, $obj->errstr );

    # new username
    if ( $lineref->[2] && !$obj->_is_valid_username( $lineref->[2] ) ) {
        return $obj->error( $command, $obj->errstr );
    }

    # new nickname
    if ( $lineref->[3] && !$obj->_is_valid_nickname( $lineref->[3] ) ) {
        return $obj->error( $command, $obj->errstr );
    }

    # new email
    if ($lineref->[4]
        && (   length( $lineref->[4] ) > 127
            || index( $lineref->[4], '\n' ) > -1
            || !is_valid_email( $lineref->[4] ) )
        )
    {
        return ( $command,
            MT->translate( "Invalid email address: [_1]", $lineref->[4] ) );
    }

    #language
    if ( $lineref->[5] && !is_language_tag( $lineref->[5] ) ) {
        return ( $command,
            MT->translate( "Invalid language: [_1]", $lineref->[5] ) );
    }

    return ( $lineref->[0], undef );
}

sub _parse_line_delete {
    my $obj       = shift;
    my ($lineref) = @_;
    my @line      = @$lineref;

    #keyword
    $lineref->[1] =~ s/^\s*$//;
    if ( length( $lineref->[1] ) != 0 ) {
        if (   ( length( $lineref->[1] ) < 1 )
            || ( length( $lineref->[1] ) > 255 )
            || ( index( $lineref->[1], '\n' ) > -1 ) )
        {
            return ( $lineref->[0],
                MT->translate( "Invalid user name: [_1]", $lineref->[1] ) );
        }
    }

    return ( $lineref->[0], undef );
}

sub register {
    my ( $obj, $app, $cb ) = @_;

    # Set the known, pre-parsed registration line components.
    my %line;
    @line{
        qw(
            author
            nickname
            email
            language
            password
            blog
            description
            subdomain
            site_url
            site_path
            timezone
            themeid
            )
        }
        = @_[ 4 .. 15 ];

    my $cfg    = $app->config;
    my $author = $obj->_load_author_by_name( $line{author} );
    if ($author) {
        my $error = MT->translate(
            "A user with the same name was found.  The registration was not processed: [_1]",
            $line{author}
        );
        $app->log(
            {   message  => $error,
                level    => MT::Log::ERROR(),
                class    => 'system',
                category => 'create_author_bulk'
            }
        );
        return $obj->error($error);
    }
    else {
        my $log = qw( );
        my $message;
        $author = $app->model('author')->new;
        $author->created_by( $app->user->id );
        $author->name( $line{author} );
        $author->nickname( $line{nickname} );
        $author->email( $line{email} );
        $author->preferred_language( $line{language} ) if $line{language};

        if ( $line{password} ) {
            $author->set_password( $line{password} );
        }
        else {
            $author->password('(none)');
        }
        $author->status( MT::Author::ACTIVE() );
        $author->type( MT::Author::AUTHOR() );
        $author->auth_type( MT->config->AuthenticationModule );

        $author->save
            or $app->log(
            {   message => MT->translate(
                    "User cannot be created: [_1].",
                    $line{author}
                ),
                level    => MT::Log::ERROR(),
                class    => 'system',
                category => 'create_author_bulk'
            }
            ),
            return $obj->error(
            MT->translate( "User cannot be created: [_1].", $line{author} ) );
        $app->log(
            {   message => MT->translate(
                    "User '[_1]' has been created.",
                    $line{author}
                ),
                level    => MT::Log::INFO(),
                class    => 'system',
                category => 'create_author_bulk'
            }
        );
        $author->add_default_roles;
        $message
            = MT->translate( "User '[_1]' has been created.", $line{author} );
        $cb->($message);
        $log .= $message;

        if ( ( $line{blog} ) && ( length( $line{blog} ) > 0 ) ) {
            require MT::Blog;
            my $blog = MT::Blog->create_default_blog( $line{blog} );
            $blog->description( $line{description} );
            if ( $line{site_url} && $line{site_url} !~ m!/$! ) {
                $line{site_url} .= '/';
            }
            $blog->site_url( $line{subdomain} . '/::/' . $line{site_url} );
            $blog->site_path( $line{site_path} );
            $blog->parent_id( $app->config->NewUserDefaultWebsiteId );
            $blog->server_offset( $line{timezone} );
            $blog->language( $cfg->DefaultLanguage );
            $message
                = MT->translate( "Blog for user '[_1]' can not be created.",
                $line{author} );
            $blog->theme_id( $line{themeid} );
            $blog->save
                or $app->log(
                {   message  => $message,
                    level    => MT::Log::ERROR(),
                    class    => 'system',
                    category => 'create_author_bulk'
                }
                ),
                return $obj->error($message);
            $blog->apply_theme();
            $blog->save;
            $message
                = MT->translate(
                "Blog '[_1]' for user '[_2]' has been created.",
                $line{blog}, $line{author} );
            $cb->($message);
            $log .= "\n$message";
            require MT::Role;
            require MT::Association;
            my $role = MT::Role->load_by_permission('administer_blog');

            if ($role) {
                MT::Association->link( $author => $role => $blog );
            }
            else {
                my $role_message
                    = MT->translate(
                    "Error assigning weblog administration rights to user '[_1] (ID: [_2])' for weblog '[_3] (ID: [_4])'. No suitable weblog administrator role was found.",
                    $author->name, $author->id, $blog->name, $blog->id );
                $app->log(
                    {   message  => $role_message,
                        level    => MT::Log::ERROR(),
                        class    => 'system',
                        category => 'new'
                    }
                );
                return $obj->error($role_message);
            }
        }
        else {
            if ( MT->config->NewUserAutoProvisioning ) {
                MT->run_callbacks( 'NewUserProvisioning', $author );
            }
        }
        $message = MT->translate( "Permission granted to user '[_1]'",
            $line{author} );
        $cb->($message);
        $log .= "\n$message";
        $app->log(
            {   message  => $log,
                level    => MT::Log::INFO(),
                class    => 'system',
                category => 'create_author_bulk'
            }
        );

        return 1;
    }
}

sub update {
    my $obj = shift;
    my ( $app, $cb, @line ) = @_;

    my $author = $obj->_load_author_by_name( $line[1] );
    require MT::Log;
    if ($author) {
        if ( $line[2] ) {
            my $new_author = $obj->_load_author_by_name( $line[2] );
            my $message    = MT->translate(
                "User '[_1]' already exists. The update was not processed: [_2]",
                $line[2], $line[1]
            );
            if ($new_author) {
                $app->log(
                    {   message  => $message,
                        level    => MT::Log::ERROR(),
                        class    => 'system',
                        category => 'create_author_bulk'
                    }
                );
                return $obj->error($message);
            }
            $author->name( $line[2] );
        }
        $author->nickname( $line[3] )
            if ( ( $line[3] ) && length $line[3] > 0 );
        $author->email( $line[4] ) if ( ( $line[4] ) && length $line[4] > 0 );
        $author->preferred_language( $line[5] )
            if ( ( $line[5] ) && length $line[5] > 0 );
        $author->save
            or $app->log(
            {   message => MT->translate(
                    "User cannot be updated: [_1].", $line[1]
                ),
                level    => MT::Log::ERROR(),
                class    => 'system',
                category => 'create_author_bulk'
            }
            ),
            $obj->error(
            MT->translate( "User cannot be updated: [_1].", $line[1] ) );
    }
    else {
        $app->log(
            {   message => MT->translate(
                    "User '[_1]' not found.  The update was not processed.",
                    $line[1]
                ),
                level    => MT::Log::ERROR(),
                class    => 'system',
                category => 'create_author_bulk'
            }
        );
        return $obj->error(
            MT->translate(
                "User '[_1]' not found.  The update was not processed.",
                $line[1]
            )
        );
    }
    $app->log(
        {   message =>
                MT->translate( "User '[_1]' has been updated.", $line[1] ),
            level    => MT::Log::INFO(),
            class    => 'system',
            category => 'create_author_bulk'
        }
    );
    $cb->( MT->translate( "User '[_1]' has been updated.", $line[1] ) );
    return 1;
}

sub delete {
    my $obj = shift;
    my ( $app, $cb, @line ) = @_;

    my $author = $obj->_load_author_by_name( $line[1] );
    require MT::Log;
    if ($author) {
        $author->remove
            or $app->log(
            {   message => MT->translate(
                    "User '[_1]' was found, but the deletion was not processed",
                    $line[1]
                ),
                level    => MT::Log::ERROR(),
                class    => 'system',
                category => 'create_author_bulk'
            }
            ),
            return $obj->error->(
            MT->translate(
                "User '[_1]' was found, but the deletion was not processed",
                $line[1]
            )
            );
    }
    else {
        $app->log(
            {   message => MT->translate(
                    "User '[_1]' not found.  The deletion was not processed.",
                    $line[1]
                ),
                level    => MT::Log::ERROR(),
                class    => 'system',
                category => 'create_author_bulk'
            }
        );
        return $obj->error(
            MT->translate(
                "User '[_1]' not found.  The deletion was not processed.",
                $line[1]
            )
        );
    }
    $app->log(
        {   message =>
                MT->translate( "User '[_1]' has been deleted.", $line[1] ),
            level    => MT::Log::INFO(),
            class    => 'system',
            category => 'create_author_bulk'
        }
    );
    $cb->( MT->translate( "User '[_1]' has been deleted.", $line[1] ) );
    return 1;
}

sub _load_author_by_name {

    # That is, load by username, which is unique for the author.
    my $obj = shift;
    my ($name) = @_;

    require MT::Author;
    my $author_iter
        = MT::Author->load_iter( { type => AUTHOR, name => $name },
        { sort => 'name' } );
    my $author;
    while ( my $au = $author_iter->() ) {
        my $row = $au->column_values;
        if ( $row->{name} eq $name ) {
            $author = MT::Author->load( $au->id );
            last;
        }
    }
    return $author;
}

1;
__END__

=head1 NAME

MT::Enterprise::BulkCreation - Utility package for managing the bulk user create,
update, delete facility.

=head1 DESCRIPTION

This module handles the Bulk User management operations of Movable Type.

=head1 METHODS

=head2 $obj->do_bulk_create(%param)

Parameters for this method:

=over 4

=item * App

The parent I<MT::App> application that is driving the process.

=item * Callback

A coderef of a routine that is used to send progress messages back from
this module. The callback routine is simply given a string containing
a message to relay to the end user.

=item * Line

An array reference of data from current line of the import file being
processed.

=item * LineNumber

The current line number of the file being processed.

=back

The 'Line' parameter is a data line in CSV format from the import file being
processed. This module processes three varieties of input data, all beginning
with an identifier that specifies the type of line being processed. That
first element is one of: register, update, delete.

Based on this command column, the appropriate method is called to parse
the rest of the line and apply the updates to the user table.

=head2 $obj->register($app, @line_data)

Processes a bulk user record of the 'register' type. Records processed
with a 'register' command will create new Movable Type user accounts.
The line is expected to be in CSV format and contains the following columns:

=over 4

=item * register

The literal word "register".

=item * username

The username of the user to create.

=item * display name

The name used when publishing the name of the author.

=item * email

The contact email address for this user.

=item * language

The language to assign to the new user account. Valid choices include: en,
ja, de, es, fr, nl (or if you have other MT localization packs installed,
those language codes would be also valid).

=item * password

A password the user will use to login to Movable Type.

=item * hint

A recovery hint the user can use to reset their password. The user
must know this hint in order to reset their password.
This word or phrase is not used from MT4.25 in the password recovery.

=item * blog name

The name to assign to a weblog that will be created and assigned to this
user.

=item * description

The description to assign to their weblog.

=item * site url

The site URL to assign to their weblog.

=item * site path

The site root path to assign to their weblog.

=item * timezone

The timezone to assign to their weblog.

=back

Note that the weblog fields (blog name, description, site url, site path
and timezone) may be blank if you do not wish to create a personal
weblog for the user being created. However, all columns must be in the
input record.

=head2 $obj->update($app, @line_data)

Processes a bulk user record of the 'update' type. Records processed
with a 'update' command will update existing Movable Type user accounts.
The line is expected to be in CSV format and contains the following columns:

=over 4

=item * update

The literal word "update".

=item * username

The username of the user to update. This must match with an existing
user account.

=item * display name

The new display name to assign to this user.

=item * email

The new contact email address to assign to this user.

=item * language

The new language to assign to the this user. Valid choices include: en,
ja, de, es, it, fr, nl.

=item * password

A new password to assign to this user.

=item * hint

A new recovery hint to assign to this user.
This hint are not in used password recovery since MT4.25.

=back

=head2 $obj->delete($app, @line_data)

Processes a bulk user record of the 'delete' type. Records processed
with a 'delete' command will delete existing Movable Type user accounts.
The line is expected to be in CSV format and contains the following columns:

=over 4

=item * delete

The literal word "delete".

=item * username

The username of the user to delete. This must match with an existing
user account.

=back

Note: Deleting Movable Type user accounts is not recommended. We would
advise disabling an account in favor of deleting it.

=head1 AUTHOR & COPYRIGHT

Please see the I<MT> manpage for author, copyright, and license information.

=cut
