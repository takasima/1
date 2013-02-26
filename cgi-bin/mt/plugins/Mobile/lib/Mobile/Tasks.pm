package Mobile::Tasks;
use strict;
use warnings;
use lib qw( addons/PowerCMS.pack/lib );
use base qw( Exporter );

our @EXPORT_OK = qw( _entry_from_email );

use PowerCMS::Util qw(
    save_asset site_path get_mail remove_item is_user_can create_entry
    set_upload_filename uniq_filename move_file file_label allow_upload
);

# following is from MailPost
sub _entry_from_email {
    my $app    = MT::instance();
    my $plugin = MT->component('Mobile');

    require MT::Blog;
    require File::Basename;

    my $iter = MT::Blog->load_iter( { allow_mailpost => 1 } );
    while ( my $blog = $iter->() ) {
        next unless $blog && $blog->class eq 'blog';
        eval {
            my $blog_id = $blog->id;
            my $server  = $plugin->get_config_value( 'mailpost_server',
                'blog:' . $blog_id );
            my $account = $plugin->get_config_value( 'mailpost_account',
                'blog:' . $blog_id );
            my $password = $plugin->get_config_value( 'mailpost_password',
                'blog:' . $blog_id );
            my $protocol = $plugin->get_config_value( 'mailpost_protocol',
                'blog:' . $blog_id );
            my $outdir = $plugin->get_config_value( 'mailpost_outdir',
                'blog:' . $blog_id );
            my $imagewidth = $plugin->get_config_value( 'mailpost_imagewidth',
                'blog:' . $blog_id );
            my $imagemarkup
                = $plugin->get_config_value( 'mailpost_imagemarkup',
                'blog:' . $blog_id );
            my @imagemarkups = split( /,/, $imagemarkup ) if $imagemarkup;
            $outdir = File::Spec->catdir( site_path($blog), $outdir );
            return if ( ( !$server ) || ( !$account ) || ( !$password ) );
            my $mails
                = get_mail( $server, $account, $password, $protocol, 1 );

            for my $mail (@$mails) {
                my $from      = $mail->{from};
                my $subject   = $mail->{subject};
                my $body      = $mail->{body};
                my $files     = $mail->{files};
                my $directory = $mail->{directory};
                my $parsed_files = $mail->{parsed_files};
                my @authors
                    = MT::Author->search_by_meta( mobile_address => $from );
                my $author;
                my $can_publish;
                for my $user (@authors) {
                    unless ( defined $author ) {
                        if ( is_user_can( $blog, $user, 'create_post' ) ) {
                            $author = $user;
                        }
                    }
                    if ( is_user_can( $blog, $user, 'publish_post' ) ) {
                        $author      = $user;
                        $can_publish = 1;
                    }
                }
                unless ( defined $author ) {
                    remove_item($directory);
                    next;
                }
                my $status = $blog->status_default;
                unless ($can_publish) {
                    $status = MT::Entry::HOLD();
                }
                my %args = (
                    title     => $subject,
                    text      => $body,
                    author_id => $author->id,
                    status    => $status,
                );
                my $permission = MT->model( 'permission' )->load( { blog_id => $blog_id,
                                                                    author_id => $author->id,
                                                                  }
                                                                );
                if ( $permission ) {
                    my $category_id = $permission->mobile_categories;
                    my $exists = MT->model( 'category' )->count( { id => $category_id,
                                                                   blog_id => $blog_id,
                                                                 }
                                                               );
                    if ( $exists ) {
                        $args{ category_id } = $category_id;
                    }
                }
                my $entry = create_entry( $app, $blog, \%args );
                my $more = '';
                if ( is_user_can( $blog, $author, 'upload' ) ) {
                    my $counter = 1;
                    for my $file (@$files) {
                        if (! allow_upload($file) ) {
                            unlink $file;
                            next;
                        }
                        my $label = file_label($file);
                        my $new   = set_upload_filename($file);
                        $new = File::Spec->catfile( MT->config->TempDir,
                            $new );
                        $new = uniq_filename($new);
                        # for multipart
                        my $filename = File::Basename::basename( $file );
                        unless ( $filename =~ /.+\..+$/ ) {
                            if ( my $new_filename = $parsed_files->{ $file } ) {
                                $new_filename = MT::I18N::utf8_off( $new_filename );
                                $label = file_label( $new_filename );
                                my $dir = File::Basename::dirname( $file );
                                $new = File::Spec->catfile( $dir, $new_filename );
                                $new = uniq_filename( $new );
                            }
                        }
                        # /for multipart
                        if ( $file ne $new ) {
                            move_file( $file, $new, $blog );
                        }
                        my $basename = File::Basename::basename($new);
                        my $outfile
                            = File::Spec->catfile( $outdir, $basename );
                        $outfile = uniq_filename($outfile);
                        move_file( $new, $outfile, $blog );
                        if ( -f $outfile ) {
                            my $tag;
                            my %params = (
                                file   => $outfile,
                                author => $author,
                                label  => $label,
                                object => $entry,
                            );
                            my $asset = save_asset( $app, $blog, \%params );
                            next unless ( defined $asset );
                            if ( $asset->class eq 'image' ) {
                                my $alt
                                    = $plugin->translate(
                                    '[_1]\'s image([_2])',
                                    $subject, $counter );
                                my $url = $asset->url;
                                my $w   = $asset->image_width;
                                my $h   = $asset->image_height;
                                $tag
                                    = "<img src=\"$url\" alt=\"$alt\" width=\"$w\" height=\"$h\" />";
                                if (   ($imagewidth)
                                    && ( $asset->image_width > $imagewidth ) )
                                {
                                    my ( $thumbnail, $n_w, $n_h )
                                        = $asset->thumbnail_file(
                                        Width => $imagewidth );
                                    if ($thumbnail) {
                                        my $thumbnail_label
                                            = $plugin->translate(
                                            '[_1]\' s thumbnail', $label );
                                        my %params = (
                                            file   => $thumbnail,
                                            author => $author,
                                            label  => $thumbnail_label,
                                            object => $entry,
                                            parent => $asset->id,
                                        );
                                        my $thumb = save_asset( $app, $blog,
                                            \%params );
                                        my $t_url = $thumb->url;
                                        my $t_w   = $thumb->image_width;
                                        my $t_h   = $thumb->image_height;
                                        $tag
                                            = "<a href=\"$url\" target=\"_blank\">";
                                        $tag
                                            .= "<img src=\"$t_url\" alt=\"$alt\" width=\"$t_w\" height=\"$t_h\" /></a>";
                                    }
                                }
                                if ($imagemarkup) {
                                    $tag
                                        = $imagemarkups[0]
                                        . $tag
                                        . $imagemarkups[1];
                                }
                                $more .= $tag;
                            }
                        }
                        $counter++;
                    }
                }
                remove_item($directory);
                %args = (
                    id        => $entry->id,
                    text_more => $more,
                );
                my %params;
                if ( $entry->status == MT::Entry::RELEASE() ) {
                    %params = (
                        rebuildme    => 1,
                        dependencies => 1,
                    );
                }
                $entry = create_entry( $app, $blog, \%args, \%params );
                my $message = $app->translate(
                    "[_1] '[_2]' (ID:[_3]) added by user '[_4]'",
                    $entry->class_label, $entry->title,
                    $entry->id,          $author->name
                );
                require MT::Log;
                $app->log(
                    {   message  => $message,
                        level    => MT::Log::INFO(),
                        class    => $entry->class,
                        category => 'new',
                        metadata => $entry->id
                    }
                );
            }
        };
        if ($@) {
            my $error = $@;
            my $message = $plugin->translate(
                'An error occured at importing mail post: [_1]', $error );
            $app->log(
                {   message => $message,
                    level   => MT::Log::ERROR(),
                }
            );
        }
    }
    return 1;
}

1;
