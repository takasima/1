package CustomObject::Util;
use strict;
use lib qw( addons/PowerCMS.pack/lib );
use base qw/Exporter/;

our @EXPORT_OK = qw(
    site_url site_path is_cms current_ts valid_ts is_user_can build_tmpl utf8_on
    is_application get_weblog_ids remove_item csv_new plugin_template_path
    encode_utf8_string_to_cp932_octets include_exclude_blogs trimj_to
    get_weblogs read_from_file make_zip_archive write2file upload
    get_config_inheritance permitted_blog_ids path2url is_oracle
);

use Encode qw( encode decode );
use File::Spec;
use File::Basename;
use File::Temp qw( tempdir );

use MT::Log;
use MT::FileMgr;
use MT::Request;
use MT::Permission;

use MT::Util qw( offset_time_list encode_url decode_url );
use PowerCMS::Util qw( uniq_array );

sub trimj_to {
    my ( $text, $trim_witdth, $ellipsis ) = @_;
    if (! $text ) {
        return $ellipsis;
    }
    $trim_witdth = $trim_witdth * 2;
    my @strs = split( //, $text );
    my $length = 0;
    my $out = '';
    for my $str ( @strs ) {
        $out .= $str;
        if ( bytes::length( $str ) > 1 ) {
            $length += 2;
        } else {
            $length += 1;
        }
        if ( $length >= $trim_witdth ) {
            last;
        }
    }
    if ( $out ne $text ) {
        $out .= $ellipsis;
    }
    return $out;
}

sub permitted_blog_ids {
    my ( $app, $permissions ) = @_;
    my @permissions = ref $permissions eq 'ARRAY' ? @$permissions : $permissions;
    my @blog_ids;
    my $blog = $app->blog;
    if ( $blog ) {
        push( @blog_ids, $blog->id );
        unless ( $blog->is_blog ) {
            push( @blog_ids, map { $_->id } @{ $blog->blogs } );
        }
    }
    my $user = $app->user;
    if ( $user->is_superuser ) {
        unless ( @blog_ids ) {
            my @all_blogs = MT::Blog->load( { class => '*' } );
            @blog_ids = map { $_->id } @all_blogs;
        }
        if ( @blog_ids ) {
            @blog_ids = uniq_array( \@blog_ids );
            return wantarray ? @blog_ids : \@blog_ids;
        }
    }
    require MT::Permission;
    my $iter = MT->model( 'permission' )->load_iter( { author_id => $user->id,
                                                       ( @blog_ids ? ( blog_id => \@blog_ids ) : ( blog_id => { not => 0 } ) ),
                                                     }
                                                   );
    my @permitted_blog_ids;
    while ( my $p = $iter->() ) {
        for my $permission ( @permissions ) {
            next unless $p->blog;
            if ( is_user_can( $p->blog, $user, $permission ) ) {
                push( @permitted_blog_ids, $p->blog->id );
                last;
            }
        }
    }
    if ( @permitted_blog_ids ) {
        @permitted_blog_ids = uniq_array( \@permitted_blog_ids );
        return wantarray ? @permitted_blog_ids : \@permitted_blog_ids;
    }
    return;
}

sub get_config_inheritance {
    my ( $plugin, $key, $blog ) = @_;
    my $get_from;
    if ( $blog ) {
        $get_from = 'blog:' . $blog->id;
    } else {
        $get_from = 'system';
    }
    my $plugin_data = $plugin->get_config_value( $key, $get_from );
    if ( (! $plugin_data ) && $blog ) {
        my $website;
        if ( MT->version_number < 5 ) {
            $get_from = 'system';
        } else {
            if (! $blog->is_blog ) {
                $get_from = 'system';
            } else {
                if ( $website = $blog->website ) {
                    if ( $website ) {
                        $get_from = 'blog:' . $website->id;
                    } else {
                        $website = $blog;
                        $get_from = 'blog:' . $blog->id;
                    }
                }
            }
        }
        $plugin_data = $plugin->get_config_value( $key, $get_from );
        if ( (! $plugin_data ) && $website ) {
            $plugin_data = $plugin->get_config_value( $key, 'system' );
        }
    }
    return $plugin_data;
}

sub make_zip_archive {
    my ( $directory, $out, $files ) = @_;
    eval { require Archive::Zip } || return undef;
    my $archiver = Archive::Zip->new();
    my $fmgr = MT::FileMgr->new( 'Local' ) or die MT::FileMgr->errstr;
    my $dir = File::Basename::dirname( $out );
    $dir =~ s!/$!! unless $dir eq '/';
    unless ( $fmgr->exists( $dir ) ) {
        $fmgr->mkpath( $dir ) or return undef;
    }
    if (-f $directory ) {
        my $basename = File::Basename::basename( $directory );
        $archiver->addFile( $directory, $basename );
        return $archiver->writeToFileNamed( $out );
    }
    $directory =~ s!/$!!;
    unless ( $files ) {
        @$files = get_children_filenames( $directory );
    }
    $directory = quotemeta( $directory );
    for my $file ( @$files ) {
        my $new = $file;
        $new =~ s/^$directory//;
        $new =~ s!^/!!;
        $new =~ s!^\\!!;
        $archiver->addFile( $file, $new );
    }
    return $archiver->writeToFileNamed( $out );
}

sub get_children_filenames {
    my ( $directory, $pattern ) = @_;
    my @wantedFiles;
    require File::Find;
    if ( $pattern ) {
        if ( $pattern =~ m!^(/)(.+)\1([A-Za-z]+)?$! ) {
            $pattern = $2;
            if ( my $opt = $3 ) {
                $opt =~ s/[ge]+//g;
                $pattern = "(?$opt)" . $pattern;
            }
            my $regex = eval { qr/$pattern/ };
            if ( defined $regex ) {
                my $command = 'File::Find::find ( sub { push ( @wantedFiles, $File::Find::name ) if ( /' . $pattern. '/ ) && -f ; }, $directory );';
                eval $command;
                if ( $@ ) {
                    return undef;
                }
            } else {
                return undef;
            }
        }
    } else {
        File::Find::find ( sub { push ( @wantedFiles, $File::Find::name ) unless (/^\./) || ! -f ; }, $directory );
    }
    return @wantedFiles;
}

sub read_from_file {
    my ( $path, $type, $blog ) = @_;
    my $fmgr = MT::FileMgr->new( 'Local' ) or die MT::FileMgr->errstr;
    if ( $blog ) {
        $path = relative2path( $path, $blog );
    }
    unless ( $fmgr->exists( $path ) ) {
       return '';
    }
    my $data = $fmgr->get_data( $path, $type );
    return $data;
}

sub is_application {
    my $app = shift || MT->instance();
    return (ref $app) =~ /^MT::App::/ ? 1 : 0;
}

sub is_cms {
    my $app = shift || MT->instance();
    return ( ref $app eq 'MT::App::CMS' ) ? 1 : 0;
}

sub valid_ts {
    my $ts = shift;
    return 0 unless ( $ts =~ m/^[0-9]{14}$/ );
    my $year = substr( $ts, 0, 4 );
    my $month = substr( $ts, 4, 2 );
    my $day = substr( $ts, 6, 2 );
    my ( @mlast ) = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );
    if ( $month < 1 || 12 < $month ) {
        return 0;
    }
    if ( $month == 2 ) {
        if ( ( ( $year % 4 == 0 ) && ( $year % 100 != 0 ) ) || ( $year % 400 == 0 ) ) {
            $mlast[1]++;
        }
    }
    if ( $day < 1 || $mlast[$month-1] < $day ) {
        return 0;
    }
    my $hour = substr( $ts, 8, 2 );
    my $min = substr( $ts, 10, 2 );
    my $sec = substr( $ts, 12, 2 );
    if ( ( $hour < 25 ) && ( $min < 61 ) && ( $sec < 61 ) ) {
        return 1;
    }
    return 0;
}

sub is_user_can {
    my ( $blog, $user, $permission ) = @_;
    $permission = 'can_' . $permission;
    my $perm = $user->is_superuser;
    unless ( $perm ) {
        if ( $blog ) {
            my $admin = 'can_administer_blog';
            $perm = $user->permissions( $blog->id )->$admin;
            $perm = $user->permissions( $blog->id )->$permission unless $perm;
        } else {
            $perm = $user->permissions()->$permission;
        }
    }
    return $perm;
}

sub current_ts {
    my $blog = shift;
    my @tl = offset_time_list( time, $blog );
    my $ts = sprintf '%04d%02d%02d%02d%02d%02d', $tl[5]+1900, $tl[4]+1, @tl[3,2,1,0];
    return $ts;
}

sub build_tmpl {
    my ( $app, $tmpl, $args, $params ) = @_;
#     my %args = ( ctx => $ctx,
#                  blog => $blog,
#                  entry => $entry,
#                  category => $category,
#                  author => $author,
#                  start => 'YYYYMMDDhhmmss',
#                  end => 'YYYYMMDDhhmmss',
#                 );
#     my %params = ( foo => 'bar', # => <mt:var name="foo">
#                    bar =>'buz', # => <mt:var name="bar">
#                  );
#    my $tmpl = MT::Template->load( { foo => 'bar' } ); # or text
#    return build_tmpl( $app, $tmpl, \%args, \%params );
    if ( ( ref $tmpl ) eq 'MT::Template' ) {
        $tmpl = $tmpl->text;
    }
    $tmpl = $app->translate_templatized( $tmpl );
    require MT::Template;
    require MT::Builder;
    my $ctx = $args->{ ctx };
    if (! $ctx ) {
        require MT::Template::Context;
        $ctx = MT::Template::Context->new;
    }
    my $blog = $args->{ blog };
    my $entry = $args->{ entry };
    my $category = $args->{ category };
    if ( (! $blog ) && ( $entry ) ) {
        $blog = $entry->blog;
    }
    if ( (! $blog ) && ( $category ) ) {
        $blog = MT::Blog->load( $category->blog_id );
    }
    my $author = $args->{ author };
    my $start = $args->{ start };
    my $end = $args->{ end };
    $ctx->stash( 'blog', $blog );
    $ctx->stash( 'blog_id', $blog->id ) if $blog;
    $ctx->stash( 'entry', $entry );
    $ctx->stash( 'page', $entry );
    $ctx->stash( 'category', $category );
    $ctx->stash( 'category_id', $category->id ) if $category;
    $ctx->stash( 'author', $author );
    if ( $start && $end ) {
        if ( ( valid_ts( $start ) ) && ( valid_ts( $end ) ) ) {
            $ctx->{ current_timestamp } = $start;
            $ctx->{ current_timestamp_end } = $end;
        }
    }
    for my $stash ( keys %$args ) {
        if (! $ctx->stash( $stash ) ) {
            if ( ( $stash ne 'start' ) && ( $stash ne 'end' ) ) {
                $ctx->stash( $stash, $args->{ $stash } );
            }
        }
    }
    for my $key ( keys %$params ) {
        $ctx->{ __stash }->{ vars }->{ $key } = $params->{ $key };
    }
    if ( is_application( $app ) ) {
        $ctx->{ __stash }->{ vars }->{ magic_token } = $app->current_magic if $app->user;
    }
    my $build = MT::Builder->new;
    my $tokens = $build->compile( $ctx, $tmpl )
        or return $app->error( $app->translate(
            "Parse error: [_1]", $build->errstr ) );
    defined( my $html = $build->build( $ctx, $tokens ) )
        or return $app->error( $app->translate(
            "Build error: [_1]", $build->errstr ) );
    unless ( MT->version_number < 5 ) {
        $html = utf8_on( $html );
    }
    return $html;
}

sub upload {
    my ( $app, $blog, $name, $dir, $params ) = @_;
    my $limit = $app->config( 'CGIMaxUpload' ) || 20480000;
#    my %params = ( object => $obj,
#                   author => $author,
#                   rename => 1,
#                   label => 'foo',
#                   description => 'bar',
#                   format_LF => 1,
#                   singler => 1,
#                   no_asset => 1,
#                   );
#    my $upload = upload( $app, $blog, $name, $dir, \%params );
    my $obj = $params->{ object };
    my $rename = $params->{ 'rename' };
    my $label = $params->{ label };
    my $format_LF = $params->{ format_LF };
    my $singler = $params->{ singler };
    my $no_asset = $params->{ no_asset };
    my $description = $params->{ description };
    my $force_decode_filename = $params->{ force_decode_filename };
    my $fmgr = MT::FileMgr->new( 'Local' ) or die MT::FileMgr->errstr;
    my $q = $app->param;
    my @files = $q->upload( $name );
    my @assets;
    my $upload_total;
    for my $file ( @files ) {
        my $size = ( -s $file );
        $upload_total = $upload_total + $size;
        if ( $limit < $upload_total ) {
            return ( undef, 1 ); # Upload file size over CGIMaxUpload;
        }
    }
    for my $file ( @files ) {
        my $orig_filename = file_basename( $file );
        $orig_filename = decode_url( $orig_filename ) if $force_decode_filename;
        my $file_label = file_label( $orig_filename );
        $orig_filename = set_upload_filename( $orig_filename );
        my $out = File::Spec->catfile( $dir, $orig_filename );
        if ( $rename ) {
            $out = uniq_filename( $out );
        }
        $dir =~ s!/$!! unless $dir eq '/';
        unless ( $fmgr->exists( $dir ) ) {
            $fmgr->mkpath( $dir ) or return MT->trans_error( "Error making path '[_1]': [_2]",
                                    $out, $fmgr->errstr );
        }
        my $temp = "$out.new";
        open ( my $fh, ">$out" ) or die "Can't open $out!";
        binmode ( $fh );
        while( read ( $file, my $buffer, 1024 ) ) {
            $buffer = format_LF( $buffer ) if $format_LF;
            print $fh $buffer;
        }
        close ( $fh );
        $fmgr->rename( $temp, $out );
        my $user = $params->{ author };
        $user = current_user( $app ) unless defined $user;
        if ( $singler ) {
            return $out;
        }
        push ( @assets, $out );
    }
    return \@assets;
}

sub write2file {
    my ( $path, $data, $type, $blog ) = @_;
    my $fmgr = MT::FileMgr->new( 'Local' ) or return 0; # die MT::FileMgr->errstr;
    if ( $blog ) {
        $path = relative2path( $path, $blog );
    }
    my $dir = dirname( $path );
    $dir =~ s!/$!! unless $dir eq '/';
    unless ( $fmgr->exists( $dir ) ) {
        $fmgr->mkpath( $dir ) or return 0; # MT->trans_error( "Error making path '[_1]': [_2]",
                                # $path, $fmgr->errstr );
    }
    $fmgr->put_data( $data, "$path.new", $type );
    if ( $fmgr->rename( "$path.new", $path ) ) {
        if ( $fmgr->exists( $path ) ) {
            return 1;
        }
    }
    return 0;
}

sub remove_item {
    my ( $remove, $blog ) = @_;
    my $fmgr = MT::FileMgr->new( 'Local' ) or die MT::FileMgr->errstr;
    if ( $blog ) {
        $remove = relative2path( $remove, $blog );
    }
    unless ( $fmgr->exists( $remove ) ) {
        return 0;
    }
    if ( -f $remove ) {
        return $fmgr->delete( $remove );
    }
    if ( -d $remove ) {
        File::Path::rmtree( [ $remove ] );
        unless ( -d $remove ) {
            return 1;
        }
    }
    return 0;
}

sub relative2path {
    my ( $path, $blog ) = @_;
    my $app = MT->instance();
    my $static_file_path = static_or_support();
    my $archive_path = archive_path( $blog );
    my $site_path = site_path( $blog );
    $path =~ s/%s/$static_file_path/;
    $path =~ s/%r/$site_path/;
    if ( $archive_path ) {
        $path =~ s/%a/$archive_path/;
    }
    return $path;
}

sub path2relative {
    my ( $path, $blog, $exclude_archive_path ) = @_;
    my $app = MT->instance();
    my $static_file_path = quotemeta( static_or_support() );
    my $archive_path = quotemeta( archive_path( $blog ) );
    my $site_path = quotemeta( site_path( $blog, $exclude_archive_path ) );
    $path =~ s/$static_file_path/%s/;
    $path =~ s/$site_path/%r/;
    if ( $archive_path ) {
        $path =~ s/$archive_path/%a/;
    }
    if ( $path =~ m!^https{0,1}://! ) {
        my $site_url = quotemeta( site_url( $blog ) );
        $path =~ s/$site_url/%r/;
    }
    return $path;
}

sub path2url {
    my ( $path, $blog, $exclude_archive_path ) = @_;
    my $site_path = quotemeta ( site_path( $blog, $exclude_archive_path ) );
    my $site_url = site_url( $blog );
    $path =~ s/^$site_path/$site_url/;
    if ( is_windows() ) {
        $path =~ s!/!\\!g;
    }
    return $path;
}

sub relative2url {
    my ( $path, $blog ) = @_;
    return path2url( relative2path( $path,$blog ), $blog );
}

sub url2path {
    my ( $url, $blog ) = @_;
    my $site_url = quotemeta ( site_url( $blog ) );
    my $site_path = site_path( $blog );
    $url =~ s/^$site_url/$site_path/;
    if ( is_windows() ) {
        $url =~ s!/!\\!g;
    }
    return $url;
}

sub site_path {
#     my $blog = shift;
#     my $site_path = $blog->archive_path;
#     $site_path = $blog->site_path unless $site_path;
#     return chomp_dir( $site_path );
    my ( $blog, $exclude_archive_path ) = @_;
    my $site_path;
    unless ( $exclude_archive_path ) {
        $site_path = $blog->archive_path;
    }
    $site_path = $blog->site_path unless $site_path;
    return chomp_dir( $site_path );
}

sub archive_path {
    my $blog = shift;
    my $archive_path = $blog->archive_path;
    return chomp_dir( $archive_path );
}

sub site_url {
    my $blog = shift;
    my $site_url = $blog->site_url;
    $site_url =~ s{/+$}{};
    return $site_url;
}

sub static_or_support {
    my $app = MT->instance();
    my $static_or_support;
    if ( MT->version_number < 5 ) {
        $static_or_support = $app->static_file_path;
    } else {
        $static_or_support = $app->support_directory_path;
    }
    return $static_or_support;
}

sub support_dir {
    my $app = MT->instance();
    my $support_dir;
    if ( MT->version_number < 5 ) {
        $support_dir = File::Spec->catdir( $app->static_file_path, 'support' );
    } else {
        $support_dir = $app->support_directory_path;
    }
    return $support_dir;
}

sub current_user {
    my $app = shift || MT->instance();
    my $user;
    eval { $user = $app->user };
    unless ( $@ ) {
        return $user if defined $user;
    }
    return undef;
}

sub get_user {
    my $app = shift || MT->instance();
    my $user; my $sess;
    if ( is_application( $app ) ) {
        require MT::Session;
        eval { $user = $app->user };
        unless ( defined $user ) {
            eval { ( $sess, $user ) = $app->get_commenter_session() };
            unless ( defined $user ) {
                if ( $app->param( 'sessid' ) ) {
                    my $sess = MT::Session->load ( { id => $app->param( 'sessid' ),
                                                     kind => 'US' } );
                    if ( defined $sess ) {
                       my $sess_timeout = $app->config->UserSessionTimeout;
                       if ( ( time - $sess->start ) < $sess_timeout ) {
                            $user = MT::Author->load( { name => $sess->name, status => MT::Author::ACTIVE() } );
                            $sess->start( time );
                            $sess->save or die $sess->errstr;
                        }
                    }
                }
            }
        }
        unless ( defined $user ) {
            if ( my $mobile_id = get_mobile_id( $app ) ) {
                my @authors = MT::Author->search_by_meta( mobile_id => $mobile_id );
                if ( my $author = $authors[0] ) {
                    if ( $author->status == MT::Author::ACTIVE() ) {
                        $user = $author;
                    }
                }
            }
        }
    }
    return $user if defined $user;
    return undef;
}

sub csv_new {
    my $csv = do {
    eval { require Text::CSV_XS };
    unless ( $@ ) { Text::CSV_XS->new ( { binary => 1 } ); } else
    { eval { require Text::CSV };
        return undef if $@; Text::CSV->new ( { binary => 1 } ); } };
    return $csv;
}

sub set_upload_filename {
    my $file = shift;
    $file = File::Basename::basename( $file );
    my $ctext = encode_url( $file );
    if ( $ctext ne $file ) {
        unless ( MT->version_number < 5 ) {
            $file = utf8_off( $file );
        }
        my $extension = file_extension( $file );
        my $ext_len = length( $extension ) + 1;
        require Digest::MD5;
        $file = Digest::MD5::md5_hex( $file );
        $file = substr ( $file, 0, 255 - $ext_len );
        $file .= '.' . $extension;
    }
    return $file;
}

sub uniq_filename {
    my $file = shift;
    require File::Basename;
    my $dir = File::Basename::dirname( $file );
    my $tilda = quotemeta( '%7E' );
    $file =~ s/$tilda//g;
    $file = File::Spec->catfile( $dir, set_upload_filename( $file ) );
    return $file unless ( -f $file );
    my $file_extension = file_extension( $file );
    my $base = $file;
    $base =~ s/(.{1,})\.$file_extension$/$1/;
    $base = $1 if ( $base =~ /(^.*)_[0-9]{1,}$/ );
    my $i = 0;
    do { $i++;
         $file = $base . '_' . $i . '.' . $file_extension;
       } while ( -e $file );
    return $file;
}

sub format_LF {
    my $data = shift;
    $data =~ s/\r\n?/\n/g;
    return $data;
}

sub file_extension {
    my ( $file, $nolc ) = @_;
    my $extension = '';
    if ( $file =~ /\.([^.]+)\z/ ) {
        $extension = $1;
        $extension = lc( $extension ) unless $nolc;
    }
    return $extension;
}

sub file_label {
    my $file = shift;
    $file = file_basename( $file );
    my $file_extension = file_extension( $file, 1 );
    my $base = $file;
    $base =~ s/(.{1,})\.$file_extension$/$1/;
    $base = Encode::decode_utf8( $base ) unless Encode::is_utf8( $base );
    return $base;
}

sub file_basename {
    my $file = shift;
    if (! is_windows() && $file =~ m/\\/ ) { # Windows Style Path on Not-Win
        my $prev = File::Basename::fileparse_set_fstype( 'MSWin32' );
        $file = File::Basename::basename( $file );
        File::Basename::fileparse_set_fstype( $prev );
    } else {
        $file = File::Basename::basename( $file );
    }
    return $file;
}

sub get_utf {
    my $text = shift;
    eval { require Unicode::Japanese } || return undef;
    my $t = Unicode::Japanese->new( $text, 'utf8' );
    $text = $t->getu();
    return $text;
}

sub utf8_on {
    my $text = shift;
    if (! Encode::is_utf8( $text ) ) {
        Encode::_utf8_on( $text );
    }
    return $text;
}

sub utf8_off {
    my $text = shift;
    return MT::I18N::utf8_off( $text );
}

sub to_utf8 {
    my $text = shift;
    return MT::I18N::encode_text( $text, undef, 'utf-8' );
}

sub chomp_dir {
    my $dir = shift;
    my @path = File::Spec->splitdir( $dir );
    $dir = File::Spec->catdir( @path );
    return $dir;
}

sub get_weblogs {
    my $blog = shift;
    my @blogs;
    if ( MT->version_number < 5 ) {
        push ( @blogs, $blog );
        return @blogs;
    }
    push ( @blogs, $blog );
    if ( $blog->class eq 'website' ) {
        my $weblogs = $blog->blogs || [];
        push ( @blogs, @$weblogs );
    }
    return @blogs;
}

sub get_weblog_ids {
    my $website = shift;
    my $plugin = MT->component( 'PowerCMS' );
    my $app = MT->instance();
    if ( $website && ( $website->class eq 'blog' ) ) {
        $website = $website->website;
    }
    my $r = MT::Request->instance();
    my $blog_ids;
    my $cache;
    if ( $website ) {
        $blog_ids = $r->cache( 'powercms_get_weblog_ids_blog:' . $website->id );
        if ( $plugin ) {
            $cache = $plugin->get_config_value( 'get_weblog_ids_cache', 'blog:'. $website->id );
        }
    } else {
        $blog_ids = $r->cache( 'powercms_get_weblog_ids_system' );
        if ( $plugin ) {
            $cache = $plugin->get_config_value( 'get_weblog_ids_cache' );
        }
    }
    return $blog_ids if $blog_ids;
    if ( $cache ) {
        @$blog_ids = split( /,/, $cache );
        return $blog_ids;
    }
    my $weblogs;
    if (! $website ) {
        $weblogs = $r->cache( 'powercms_all_weblogs' );
        if (! $weblogs ) {
            @$weblogs = MT::Blog->load( { class => '*' } );
            $r->cache( 'powercms_all_weblogs', $weblogs );
        }
    } else {
        @$weblogs = get_weblogs( $website );
    }
    for my $blog ( @$weblogs ) {
        push ( @$blog_ids, $blog->id );
    }
    if ( $website ) {
        $r->cache( 'powercms_get_weblog_ids_blog:' . $website->id, $blog_ids );
        if ( $plugin ) {
            $plugin->set_config_value( 'get_weblog_ids_cache', join ( ',', @$blog_ids ), 'blog:'. $website->id );
        }
    } else {
        $r->cache( 'powercms_get_weblog_ids_system', $blog_ids );
        if ( $plugin ) {
            $plugin->set_config_value( 'get_weblog_ids_cache', join ( ',', @$blog_ids ) );
        }
    }
#     if ( wantarray ) {
#         return @$blog_ids;
#     }
    return $blog_ids;
}

sub include_exclude_blogs {
    my ( $ctx, $args ) = @_;
    unless ( $args->{ blog_id } || $args->{ include_blogs } || $args->{ exclude_blogs } ) {
        $args->{ include_blogs } = $ctx->stash( 'include_blogs' );
        $args->{ exclude_blogs } = $ctx->stash( 'exclude_blogs' );
        $args->{ blog_ids } = $ctx->stash( 'blog_ids' );
    }
    my ( %blog_terms, %blog_args );
    $ctx->set_blog_load_context( $args, \%blog_terms, \%blog_args ) or return $ctx->error($ctx->errstr);
    my @blog_ids = $blog_terms{ blog_id };
    return undef if ! @blog_ids;
    if ( wantarray ) {
        return @blog_ids;
    } else {
        return \@blog_ids;
    }
}

sub plugin_template_path {
    my ( $component, $dirname ) = @_;
    return unless $component;
    $dirname ||= 'tmpl';
    return File::Spec->catdir( $component->path, $dirname );
}

sub encode_utf8_string_to_cp932_octets {
    my ( $str ) = @_;
    #$str = Encode::encode_utf8( $str );
    Encode::from_to( $str, 'utf8', 'cp932' );
    return $str;
}

sub is_windows { $^O eq 'MSWin32' ? 1 : 0 }

sub is_oracle {
    return lc( MT->config( 'ObjectDriver' ) ) =~ /oracle/ ? 1 : 0;
}

1;
