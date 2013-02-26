package StylePreview::Plugin;
#use strict;
use lib qw( addons/PowerCMS.pack/lib );

use File::Basename;

use MT::Template::Context;
use MT::Util qw( encode_html offset_time_list format_ts );
use PowerCMS::Util qw( site_url site_path read_from_file url2path build_tmpl
                       current_ts current_user );

sub _style_preview {
    my ( $cb, $app, $tmpl, $param ) = @_;
    return 0 if $app->param( '__mode' ) eq 'preview_customobject';
    my $plugin = MT->component( 'ExtFields' );
    my $method = $cb->method;
    my $user = current_user( $app );
    my $blog = $app->blog;
    my $blog_id = $blog->id;
    my $at = $app->param( '_type' );
    my $entry_type = $at;
    $at = $at eq 'entry' ? 'Individual' : 'Page';
    my $entry_id = $app->param( 'id' );
    my $entry;
    if ( $entry_id ) {
        if ( $at eq 'Individual' ) {
            $entry = MT->model( 'entry' )->load( { id => $entry_id } );
        } else {
            $entry = MT->model( 'page' )->load( { id => $entry_id } );
        }
    } else {
        if ( $at eq 'Individual' ) {
            $entry = MT->model( 'entry' )->load( { id => -1 } );
            unless ( defined $entry ) {
                $entry = MT->model( 'entry' )->new;
            }
        } else {
            $entry = MT->model( 'page' )->load( { id => -1 } );
            unless ( defined $entry ) {
                $entry = MT->model( 'page' )->new;
            }
        }
        $entry_id = -1;
    }
    # PATCH
    my $key = 'preview:' . $entry->class_type . ':' . $app->user->id . ':' . $entry_id;
    my $r = MT::Request->instance();
    if ( $r->cache( $key ) ) {
        $entry = $r->cache( $key );
    }
    # /PATCH
    my $file = $param->{ 'preview_url' };
    my $site_url = site_url( $blog );
    my $site_path = site_path( $blog );
    my $permalink;
    unless ( $file ) {
        my $preview_basename = $app->preview_object_basename;
        $permalink = $site_url . '/';
        $permalink .= $preview_basename;
        if ( $blog->file_extension ) {
            $permalink .= '.' . $blog->file_extension;
        }
        $file = $permalink;
    }
    $file = url2path( $file, $blog );
    my $fmgr = $blog->file_mgr;
    my $path = dirname( $file );
    $path =~ s!/$!! unless $path eq '/';
    unless ( $fmgr->exists( $path ) ) {
        $fmgr->mkpath( $path );
    }
    my $ctx = MT::Template::Context->new;
    $ctx->stash( 'blog', $blog );
    $ctx->stash( 'blog_id', $blog_id );
    $ctx->{ archive_type } = $at;
    $ctx->{ current_archive_type } = $at;
    $ctx->{ entry_type } = $entry_type;
    for my $key ( $app->param ) {
        my $input = { 'key' => $key,
                      'value' => $app->param( $key ),
                    };
        push( @{ $ctx->{ 'param' } }, $input );
    }
    my $names = $entry->column_names;
    my %values = map { $_ => scalar $app->param( $_ ) } @$names;
    for my $col ( qw( text excerpt text_more keywords ) ) {
        if ( $values{ $col } ) {
            $values{ $col } =~ tr/\r//d;
        }
    }
    $entry->set_values( \%values );
    my $templatemap = MT->model( 'templatemap' )->load( { blog_id => $blog_id,
                                                          archive_type => $at,
                                                          is_preferred => 1,
                                                        }
                                                      );
    my $template;
    my $preview_tmpl;
    if ( defined $templatemap ) {
        $template = MT->model( 'template' )->load( { id => $templatemap->template_id } );
        my %args = ( blog => $blog,
                     entry => $entry,
                   );
#         my %params = ( preview_template => 1,
#                        $entry->class . '_template' => 1, );
        my %params;
        if ( my $archiver = MT->publisher->archiver( $at ) ) {
            if ( my $tmpl_param = $archiver->template_params ) {
                %params = %$tmpl_param;
            }
        }
        $params{ entry_template } = 1 if $at eq 'Individual';
        $params{ page_template } = 1 if $at eq 'Page';
        $params{ preview_template } = 1;
        my $date = $app->param( 'authored_on_date' );
        my $time = $app->param( 'authored_on_time' );
        my $ts   = $date . $time;
        $ts =~ s/\D//g;
        $entry->authored_on( $ts );
        if ( $app->param( 'id' ) ) {
            $preview_tmpl = build_tmpl( $app, $template, \%args, \%params );
        } else {
            my $template_ctx = $template->context;
            unless ( $template_ctx->stash( 'entry' ) ) {
                $template_ctx->stash( 'entry', $entry );
            }
            $preview_tmpl = $app->translate_templatized( $template->output );
        }
    } else {
        return if $method =~ /preview_strip$/;
        my $file_template = File::Spec->catfile( $app->config( 'TemplatePath' ), 'cms', 'preview_strip.tmpl' );
        $param->{ 'preview_url' } = $permalink;
        $$tmpl = $app->build_page( $file_template, $param );
        my $search_1 = quotemeta( '<link rel="stylesheet" href="' );
        my $search_2 = quotemeta( 'powercms.css?v=' );
        my $search_3 = quotemeta( 'type="text/css" />' );
        $$tmpl =~ s/$search_1.*?$search_2.*$search_3//;
        my $preview_template = read_from_file( File::Spec->catfile( $app->config( 'TemplatePath' ), 'cms', 'preview_entry_content.tmpl' ) );
        my %args = ( blog => $blog,
                     entry => $entry,
                   );
        my %params;
        $params{ entry_template } = 1 if $at eq 'Individual';
        $params{ page_template } = 1 if $at eq 'Page';
        $params{ preview_template } = 1;
        $preview_tmpl = build_tmpl( $app, $preview_template, \%args, \%params );
    }
    my $finfo = MT->model( 'fileinfo' )->new;
    $finfo->blog_id( $blog_id );
    $finfo->entry_id( $entry->id );
    $finfo->archive_type( $at );
    $finfo->template_id( $template->id ) if $template;
    $finfo->templatemap_id( $templatemap->id ) if $templatemap;
    MT->run_callbacks(
        'build_page',
        Context      => $ctx,
        context      => $ctx,
        ArchiveType  => 'preview',
        archive_type => 'preview',
        Content => \$preview_tmpl,
        content => \$preview_tmpl,
        BuildResult  => \$preview_tmpl,
        build_result => \$preview_tmpl,
        RawContent   => \$preview_tmpl,
        raw_content  => \$preview_tmpl,
        TemplateMap  => $templatemap,
        template_map => $templatemap,
        Blog         => $blog,
        blog         => $blog,
        BlogID       => $blog_id,
        blog_id      => $blog_id,
        Entry        => $entry,
        entry        => $entry,
        EntryID      => $entry_id,
        entry_id     => $entry_id,
        FileInfo     => $finfo,
        file_info    => $finfo,
        File         => $file,
        file         => $file,
        Template     => $template,
        template     => $template,
        PeriodStart  => undef,
        period_start => undef,
        Category     => undef,
        category     => undef,
        );
        my $temp_file = "$file.new";
        $fmgr->put_data( $preview_tmpl, $temp_file );
        $fmgr->rename( $temp_file, $file );
    MT->run_callbacks(
        'build_file',
        Context      => $ctx,
        context      => $ctx,
        ArchiveType  => 'preview',
        archive_type => 'preview',
        Content => \$preview_tmpl,
        content => \$preview_tmpl,
        BuildResult  => \$preview_tmpl,
        build_result => \$preview_tmpl,
        RawContent   => \$preview_tmpl,
        raw_content  => \$preview_tmpl,
        TemplateMap  => $templatemap,
        template_map => $templatemap,
        Blog         => $blog,
        blog         => $blog,
        BlogID       => $blog_id,
        blog_id      => $blog_id,
        Entry        => $entry,
        entry        => $entry,
        EntryID      => $entry_id,
        entry_id     => $entry_id,
        FileInfo     => $finfo,
        file_info    => $finfo,
        File         => $file,
        file         => $file,
        Template     => $template,
        template     => $template,
        PeriodStart  => undef,
        period_start => undef,
        Category     => undef,
        category     => undef,
        );

    my $sess_obj = MT::Session->get_by_key( { id => $preview_basename,
                                              kind => 'TF',
                                              name => $file,
                                              blog_id => $entry->blog_id,
                                              entry_id => $entry->id,
                                              class => ( $plugin->key || lc ( $plugin->id ) ),
                                            }
                                          );
    $sess_obj->start( time );
    $sess_obj->save;

#     my $tempfile = MT->model( 'tempfile' )->load( { tempfile_path => $file } );
#     unless ( defined $tempfile ) {
#         $tempfile = MT->model( 'tempfile' )->new;
#     }
#     $tempfile->entry_id( $entry_id );
#     $tempfile->blog_id( $blog_id );
#     $tempfile->tempfile_path( $file );
#     my @tl = offset_time_list( time, undef );
#     $tempfile->build_on( current_ts( $blog ) );
#     $tempfile->author_id( $user->id );
#     my $preview_basename = $app->preview_object_basename;
#     $tempfile->preview_basename( $preview_basename );
#     $tempfile->save
#         or return $app->trans_error( 'Error saving tempfile record: [_1]', $tempfile->errstr );
#     my $search = quotemeta( '</body>' );
#     my $tmpfile_id = $tempfile->id;
#     my $script_url = $app->app_uri;
#     my $js = <<"HTML";
# <script type="text/javascript">
# var counter = 0;
# var eid;
# function func() {
#     if (counter != 0) {
#         clearTimeout(eid);
#         counter = 0;
#     } else {
#         counter = 1;
#         eid = setTimeout("func(remove_tmp($tmpfile_id))", 2200);
#     }
# }
# func();
# function remove_tmp (id) {
#     var rem_obj = new Image();
#     rem_obj.src = "$script_url?__mode=cleanup_temp&id=" + id;
# }
# </script>
# HTML
#     $$tmpl =~ s/($search)/$js$1/;
    my $search;
    $search = quotemeta( '<input type="hidden" name="parent_entry_id" value="" />' );
    $$tmpl =~ s/$search//;
    $search = quotemeta( '<input type="hidden" name="is_dynamic" value="" />' );
    $$tmpl =~ s/$search//;
    $search = quotemeta( '<input type="hidden" name="owner_id" value="" />' );
    $$tmpl =~ s/$search//;
    $search = quotemeta( '<input type="hidden" name="next_id" value="" />' );
    $$tmpl =~ s/$search//;
    $search = quotemeta( '<input type="hidden" name="next_status" value="" />' );
    $$tmpl =~ s/$search//;
    $search = quotemeta( '<input type="hidden" name="master_id" value="" />' );
    $$tmpl =~ s/$search//;
    $search = quotemeta( '<input type="hidden" name="temporary_id" value="" />' );
    $$tmpl =~ s/$search//;
    $search = quotemeta( '<input type="hidden" name="next_author_id" value="" />' );
    $$tmpl =~ s/$search//;
    $search = quotemeta( '<input type="hidden" name="unpublished_on" value="" />' );
    $$tmpl =~ s/$search//;
    $search = quotemeta( '<input type="hidden" name="released_on" value="" />' );
    $$tmpl =~ s/$search//;
    my $pointer = quotemeta( '<input type="hidden" name="__mode" value="save_entry" />' );
    # set parameta for Customfields
    my @params = $app->param;
    for my $name ( @params ) {
        next unless $name;
        next unless $name =~ /^customfield_/i;
        my $value = $app->param( $name );
        my $insert = "\n" . '<input type="hidden" name="' . encode_html( $name ) . '" value="' . encode_html( $value ) . '" />' . "\n";
        $$tmpl =~ s/($pointer)/$1$insert/;
    }
    # TODO: following shoud be in each plugins...
    if ( my $is_next = $app->param( 'is_next' ) ) {
        my $insert .= '<input type="hidden" name="is_next" value="1" />'. "\n";
        $$tmpl =~ s/($pointer)/$1$insert/;
    }
    if ( my $duplicate = $app->param( 'duplicate' ) ) {
        my $insert .= '<input type="hidden" name="duplicate" value="1" />'. "\n";
        $$tmpl =~ s/($pointer)/$1$insert/;
    }
    if ( my $return_args = $app->param( 'return_args' ) ) {
        my $insert .= '<input type="hidden" name="return_args" value="' . $return_args . '" />'. "\n";
        $$tmpl =~ s/($pointer)/$1$insert/;
    }
    if ( my $notification_message = $app->param( 'notification_message' ) ) {
        my $insert .= '<input type="hidden" name="notification_message" value="' . encode_html( $notification_message ) . '" />'. "\n";
        $$tmpl =~ s/($pointer)/$1$insert/;
    }
    if ( my $ex_status = $app->param( 'ex_status' ) ) {
        my $insert .= '<input type="hidden" name="ex_status" value="' . encode_html( $ex_status ) . '" />'. "\n";
        $$tmpl =~ s/($pointer)/$1$insert/;
    }
    if ( my $send_notification = $app->param( 'send_notification' ) ) {
        my $insert .= '<input type="hidden" name="send_notification" value="' . encode_html( $send_notification ) . '" />'. "\n";
        $$tmpl =~ s/($pointer)/$1$insert/;
    }
    if ( my @send_notices = $app->param( 'send_notice' ) ) {
        my $insert;
        for my $send_notice ( @send_notices ) {
            $insert .= '<input type="hidden" name="send_notice" value="' . encode_html( $send_notice ) . '" />'. "\n";
        }
        $$tmpl =~ s/($pointer)/$1$insert/;
    }
}

1;
