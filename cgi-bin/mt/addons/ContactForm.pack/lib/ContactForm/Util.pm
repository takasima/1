package ContactForm::Util;
use strict;
use base qw/Exporter/;

our @EXPORT_OK = qw(
    is_cms current_ts is_user_can build_tmpl upload utf8_on utf8_off to_utf8
    is_application get_weblog_ids remove_item csv_new plugin_template_path
    encode_utf8_string_to_cp932_octets include_exclude_blogs include_blogs is_windows
    read_from_file valid_url valid_email valid_ts format_LF multibyte_length
    valid_phone_number valid_postal_code send_mail register_templates_to trim_j
    permitted_blog_ids normalize ceil
);

use File::Spec;
use File::Basename;
use File::Temp qw( tempdir );
use Encode qw( encode decode );

use MT::Log;
use MT::FileMgr;
use MT::Request;
use MT::Permission;
use MT::Util qw( offset_time_list encode_url decode_url is_valid_email
                 is_valid_url
               );

sub multibyte_length {
    my $text = shift;
    return 0 unless $text;
    my @strs = split( //, $text );
    my $length = 0;
    for my $str ( @strs ) {
        if ( bytes::length( $str ) > 1 ) {
            $length += 1;
        } else {
            $length += 0.5;
        }
    }
    return $length;
}

sub trim_j {
    my ( $text, $trim_witdth, $ellipsis ) = @_;
    if (! $ellipsis ) {
        $ellipsis = '';
    }
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

sub register_templates_to {
    my ( $blog_id, $component, $templates ) = @_;
    return unless ( ref $templates eq 'HASH' );
    $blog_id ||= 0;
    return unless ( $blog_id =~ m/^\d+$/ );
    my $ret = 1;
    for my $ident ( keys( %$templates ) ) {
        my $v = $templates->{ $ident };
        next unless ref $v eq 'HASH';
        $v = { %$v };
        my $path = delete $v->{ path };
        next unless $path;
        my %param = (
            blog_id => $blog_id,
            ( $component ? ( component => $component ) : () ),
            %$v,
        );
        $ret = 0 unless register_template( $ident, $path, \%param );
    }
    return $ret;
}

sub register_template {
    my ( $identifier, $path, $params ) = @_;
    # identifier is required
    return unless ( defined( $identifier ) && $identifier ne '' );
    $params = ref $params eq 'HASH' ? { %$params } : {}; # for safe
    my $terms = { identifier => $identifier };
    $terms->{ blog_id } = $params->{ blog_id } ? delete $params->{ blog_id } : 0;
    require MT::Template;
    my $tmpl = MT::Template->get_by_key( $terms );
    return if ( $tmpl->id ); # Do nothing if already exists
    # if $path is scalar, $path is for 'text' column
    # if $path is hash must have 'text' key
    my $path_info = ref $path ? $path : { text => $path };
    return unless ( ref $path_info eq 'HASH' && defined( $path_info->{ text } ) );
    # make values for MT::Template object
    my $plugin = $params->{ component }       ? delete $params->{ component } : MT->app;
    my $name   = defined( $params->{ name } ) ? delete $params->{ name }      : $identifier;
    $name = _check_template_name( $plugin, $terms->{ blog_id }, $name );
    my %values;
    $values{ type }       = $params->{ type }       ? delete $params->{ type }       : 'custom';
    $values{ rebuild_me } = $params->{ rebuild_me } ? delete $params->{ rebuild_me } : 0;
    $values{ name }       = $plugin->translate( $name );
    for my $col ( keys( %$params ) ) {
        if ( MT::Template->has_column( $col ) ) {
            $values{ $col } = $params->{ $col };
        }
    }
    for my $col ( keys( %$path_info ) ) {
        my $tmpl_path = _abs_template_path( $plugin, $path_info->{ $col } );
        next unless -f $tmpl_path; # cannot find template file
        $values{ $col } = $plugin->translate_templatized( scalar( _slurp( $tmpl_path ) ) )
            unless exists $values{ $col }; # dont override exists column like type
    }
    return unless exists $values{ text }; # at least needs 'text' column
    $tmpl->set_values( \%values );
    $tmpl->save
        or die $tmpl->errstr;
}

sub _check_template_name {
    my ( $app, $blog_id, $name ) = @_;
    unless ( MT::Template->exist( { name => $name, blog_id => $blog_id } ) ) {
        return $name; # OK, template object with same name doesn't exist
    }
    # see MT::CMS::Template::clone_templates
    my $new_basename = $app->translate( "Copy of [_1]", $name );
    my $new_name = $new_basename;
    my $i = 0;
    while ( MT::Template->exist( { name => $new_name, blog_id => $blog_id } ) ) {
        $new_name = $new_basename . ' (' . ++$i . ')';
    }
    return $new_name;
}

sub _abs_template_path {
    my ( $plugin, $path ) = @_;
    my $tmpl_path = File::Spec->canonpath( $path );
    unless ( File::Spec->file_name_is_absolute( $tmpl_path ) ) {
        if ( $plugin->can( 'path' ) ) {
            $tmpl_path = File::Spec->catdir( $plugin->path, 'tmpl', $tmpl_path );
        }
    }
    return $tmpl_path;
}

sub _slurp {
    my ( $path ) = @_;
    require IO::File;
    my $fh = IO::File->new( $path, 'r' );
    local $/ unless wantarray;
    return <$fh>;
}

sub is_application {
    my $app = shift || MT->instance();
    return ( ref $app ) =~ /^MT::App::/ ? 1 : 0;
}

sub is_cms {
    my $app = shift || MT->instance();
    return ( ref $app eq 'MT::App::CMS' ) ? 1 : 0;
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
    return $html;
}

sub upload {
    my ( $app, $blog, $name, $dir, $params ) = @_;
    my $limit = $app->config( 'CGIMaxUpload' ) || 20_480_000;
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
        $path =~ tr{/}{\\};
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
        $url =~ tr{/}{\\};
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
    my $static_or_support = $app->support_directory_path;
    return $static_or_support;
}

sub support_dir {
    my $app = MT->instance();
    my $support_dir = $app->support_directory_path;
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
    $file =~ s/%7[Ee]//g;
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
    if ( !is_windows() && $file =~ /\\/ ) { # Windows Style Path on Not-Win
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
    push ( @blogs, $blog );
    if ( $blog->class eq 'website' ) {
        my $weblogs = $blog->blogs || [];
        push ( @blogs, @$weblogs );
    }
    return @blogs;
}

sub include_blogs {
    my ( $blog, $include_blogs ) = @_;
    $include_blogs = '' unless $include_blogs;
    my @blog_ids;
    if ( $include_blogs eq 'all' ) {
        return undef;
    } elsif ( $include_blogs eq 'children' ) {
        my $children = $blog->blogs;
        push ( @blog_ids, $blog->id );
        for my $child ( @$children ) {
            push ( @blog_ids, $child->id );
        }
    } elsif ( $include_blogs eq 'siblings' ) {
        my $website = $blog->website;
        if ( $website ) {
            my $children = $website->blogs;
            my @blog_ids;
            push ( @blog_ids, $website->id );
            for my $child ( @$children ) {
                push ( @blog_ids, $child->id );
            }
        } else {
            push ( @blog_ids, $blog->id );
        }
    } else {
        if ( $include_blogs ) {
            @blog_ids = split( /\s*,\s*/, $include_blogs );
            # push ( @blog_ids, $blog->id );
        } else {
            if ( $blog->class eq 'website' ) {
                my @children = $blog->blogs;
                push ( @blog_ids, $blog->id );
                for my $child( @children ) {
                    push ( @blog_ids, $child->id );
                }
            }
        }
    }
    return wantarray ? @blog_ids : \@blog_ids;
}

sub get_weblog_ids {
    my $website = shift;
    my $app = MT->instance();
    if ( $website && ( $website->class eq 'blog' ) ) {
        $website = $website->website;
    }
    my $r = MT::Request->instance();
    #my $cache;
    my $key = 'contactform_get_weblog_ids_' . ($website ? 'blog:' . $website->id : 'system');
    my $blog_ids = $r->cache($key);
    return $blog_ids if $blog_ids;
    #if ( $cache ) {
    #    @$blog_ids = split( /,/, $cache );
    #    return $blog_ids;
    #}
    my $weblogs;
    if (! $website ) {
        $key = 'contactform_all_weblogs';
        $weblogs = $r->cache( $key );
        if (! $weblogs ) {
            @$weblogs = MT::Blog->load( { class => '*' } );
            $r->cache( $key, $weblogs );
        }
    } else {
        @$weblogs = get_weblogs( $website );
    }
    @$blog_ids = map $_->id, @$weblogs;
    $key = 'contactform_get_weblog_ids_' . ($website ? 'blog:' . $website->id : 'system');
    $r->cache( $key, $blog_ids );
    return wantarray ? @$blog_ids : $blog_ids;
}

sub include_exclude_blogs {
    my ( $ctx, $args ) = @_;
    unless ( $args->{ blog_id } || $args->{ include_blogs } || $args->{ exclude_blogs } ) {
        $args->{ include_blogs } = $ctx->stash( 'include_blogs' );
        $args->{ exclude_blogs } = $ctx->stash( 'exclude_blogs' );
        $args->{ blog_ids }      = $ctx->stash( 'blog_ids' );
    }
    my ( %blog_terms, %blog_args );
    $ctx->set_blog_load_context( $args, \%blog_terms, \%blog_args ) or return $ctx->error($ctx->errstr);
    my @blog_ids = $blog_terms{ blog_id };
    return undef unless @blog_ids;
    return wantarray ? @blog_ids : \@blog_ids;
}

sub plugin_template_path {
    my ( $component, $dirname ) = @_;
    return unless $component;
    $dirname ||= 'tmpl';
    return File::Spec->catdir( $component->path, $dirname );
}

sub encode_utf8_string_to_cp932_octets {
    my ( $str ) = @_;
    $str = Encode::encode_utf8( $str );
    Encode::from_to( $str, 'utf8', 'cp932' );
    return $str;
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

sub valid_ts {
    my $ts = shift;
    if ( ( ref $ts ) eq 'ARRAY' ) {
        $ts = @$ts[0];
    }
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

sub valid_phone_number { # TODO: L10N
    my $str = shift;
    if ( ( ref $str ) eq 'ARRAY' ) {
        $str = @$str[0];
    }
    $str =~ /\A(?:0\d{1,4}-?\d{1,4}-?\d{3,5}|\+[1-9][-\d]+\d)\z/ ? 1 : 0; # TODO
}

sub valid_postal_code { # TODO: L10N
    my $str = shift;
    if ( ( ref $str ) eq 'ARRAY' ) {
        $str = @$str[0];
    }
    $str =~ /\A[0-9]{3}-?[0-9]{4}\z/ ? 1 : 0;
}

sub valid_email {
    my $email = shift;
    if ( ( ref $email ) eq 'ARRAY' ) {
        $email = @$email[0];
    }
    return 0 unless is_valid_email( $email );
    if ( $email =~ /^[^\@]+\@[^.]+\../ ) {
        return 1;
    }
    return 0;
}

sub valid_url {
    my $url = shift;
    if ( ( ref $url ) eq 'ARRAY' ) {
        $url = @$url[0];
    }
    if ( $url !~ m!^https{0,1}://! ) {
        return 0;
    }
    return is_valid_url( $url );
}

sub send_mail {
    my ( $from, $to, $subject, $body,
                     $cc, $bcc, $params4cb ) = @_; #old interface
    my ( $args, $params );
    my $content_type;
    if ( ref $from eq 'HASH' ) { # new interface
        $args    = $from;
        $params  = $to;
        $from    = $args->{ from };
        $to      = $args->{ to };
        $subject = $args->{ subject };
        $body    = $args->{ body };
        $cc      = $args->{ cc };
        $bcc     = $args->{ bcc };
        $content_type = $args->{ content_type };
    }
    else {
        $args = {
            from    => $from,
            to      => $to,
            subject => $subject,
            body    => $body,
            cc      => $cc,
            bcc     => $bcc,
        };
        $params = $params4cb;
    }
    return unless defined( $subject );
    return unless defined( $body );
    return unless ( $from && $to && $subject ne '' && $body ne '' );
    $params = { key => 'default' } unless defined $params;
    $params->{ key } = 'default' unless defined $params->{ key };
    my $app = MT->instance();
    my $mgr = MT->config;
    my $enc = $mgr->PublishCharset;
    my $mail_enc = lc ( $mgr->MailEncoding || $enc );
    $body = MT::I18N::encode_text( $body, $enc, $mail_enc );
    return unless
        $app->run_callbacks( ( ref $app ) . '::pre_send_mail', $app, \$args, \$params );
    $from = $args->{ from },
    $to = $args->{ to },
    $subject = $args->{ subject },
    $body = $args->{ body },
    $cc = $args->{ cc },
    $bcc = $args->{ bcc },
    my %head;
    %head = (
        To => $to,
        From => $from,
        Subject => $subject,
        ( ref $cc eq 'ARRAY' ? ( Cc => $cc ) : () ),
        ( ref $bcc eq 'ARRAY' ? ( Bcc => $bcc ) : () ),
        ( $content_type ? ( 'Content-Type' => $content_type ) : () ),
        ( MT->config->ContactFormMailReplyTo ? ( 'Reply-To' => MT->config->ContactFormMailReplyTo ) : () ),
    );
    require MT::Mail;
    force_background_task(
       sub { MT::Mail->send( \%head, $body )
            or return ( 0, "The error occurred.", MT::Mail->errstr ); } );
}

sub force_background_task {
    my $app = MT->instance();
    my $force = $app->config->FourceBackgroundTasks;
    if ( $force ) {
        my $default = $app->config->LaunchBackgroundTasks;
        $app->config( 'LaunchBackgroundTasks', 1 );
        my $res = MT::Util::start_background_task( @_ );
        $app->config( 'LaunchBackgroundTasks', $default );
        return $res;
    }
    return MT::Util::start_background_task( @_ );
}

sub is_windows { $^O eq 'MSWin32' ? 1 : 0 }

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
        return wantarray ? @blog_ids : \@blog_ids;
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
                next;
            }
        }
    }
    return wantarray ? @permitted_blog_ids : \@permitted_blog_ids;
}

sub normalize {
    my $text = shift;
    require Unicode::Normalize;
    $text = Unicode::Normalize::NFKC( $text );
    return $text;
}

sub ceil {
    my $var = shift;
    my $a = 0;
    $a = 1 if ( $var > 0 and $var != int ( $var ) );
    return int ( $var + $a );
}

1;
