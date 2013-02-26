package CustomObject::CMS;

use strict;
use CustomObject::Util qw( current_ts valid_ts site_path );
use MT::Util qw( trim );

sub _preview_customobject {
    my $app = shift;
    $app->validate_magic or
        return $app->trans_error( 'Permission denied.' );
    my $_type = $app->param( '_type' );
    if ( (! $app->blog ) || (! $_type ) ) {
        return $app->trans_error( 'Permission denied.' );
    }
    require CustomObject::Plugin;
    if (! CustomObject::Plugin::_customobject_permission( $app->blog, $_type ) ) {
        return $app->trans_error( 'Permission denied.' );
    }
    my $customobject = _create_temp_customobject( $app );
    return _build_customobject_preview( $app, $customobject );
}

sub _create_temp_customobject {
    my $app     = shift;
    my $type    = $app->param( '_type' ) || 'customobject';
    my $model   = $app->model( $type );
    my $blog_id = $app->param( 'blog_id' );
    my $blog    = $app->blog;
    my $id      = $app->param( 'id' );
    my $customobject;
    my $user_id = $app->user->id;
    if ( $id ) {
        $customobject = $model->load( { id => $id, blog_id => $blog_id } )
            or return $app->errtrans( "Invalid request." );
        $user_id = $customobject->author_id;
    } else {
        $customobject = $model->new;
        $customobject->author_id( $user_id );
        $customobject->id( -1 );
        $customobject->blog_id( $blog_id );
    }
    my $names = $customobject->column_names;
    my %values = map { $_ => scalar $app->param( $_ ) } @$names;
    delete $values{ 'id' } unless $app->param( 'id' );
    $customobject->set_values( \%values );
    return $customobject;
}

sub _build_customobject_preview {
    my $app = shift;
    my ( $customobject, %param ) = @_;
    my $type = $app->param( '_type' ) || 'customobject';
    my $custom_objects = MT->registry( 'custom_objects' );
    my $at = $custom_objects->{ $type }->{ id };
    my $plugin = MT->component( $at );
    my $model   = $app->model( $type );
    my $blog_id = $app->param( 'blog_id' );
    my $blog    = $app->blog;
    my $id      = $app->param( 'id' );
    my $user_id = $app->user->id;
    my $tag_delim = chr( $app->user->entry_prefs->{ tag_delim } );
    my @tag_names = MT::Tag->split( $tag_delim, $app->param( 'tags' ) );
    if ( @tag_names ) {
        my @tags;
        foreach my $tag_name ( @tag_names ) {
            my $tag = MT::Tag->new;
            $tag->name( $tag_name );
            push @tags, $tag;
        }
        $customobject->{ __tags }        = \@tag_names;
        $customobject->{ __tag_objects } = \@tags;
    }
    if (! defined( $customobject->basename ) || ( $customobject->basename eq '' ) ) {
        $customobject->basename( $customobject->make_unique_basename );
    }
    my $ts = current_ts( $customobject->blog );
    my $columns = $customobject->column_names;
    for my $column ( @$columns ) {
        if ( $column =~ /_on$/ ) {
            my $date = trim( $app->param( $column . '_date' ) ) if $app->param( $column . '_date' );
            my $time = trim( $app->param( $column . '_time' ) ) if $app->param( $column . '_time' );
            if ( $date && $time ) {
                $date =~ s/\-//g;
                $time =~ s/://g;
                my $ts_on = $date . $time;
                if ( valid_ts( $ts_on ) ) {
                    $customobject->$column( $ts_on );
                }
            }
        }
    }
    if (! $customobject->created_on ) {
        $customobject->created_on( $ts );
    }
    $customobject->modified_on( $ts );
    if (! $customobject->status ) {
        $customobject->status( 1 );
    }
    my $preview_basename = $app->preview_object_basename;
    require MT::TemplateMap;
    require MT::Template;
    my $tmpl_map = MT::TemplateMap->load(
        {   archive_type => $at,
            is_preferred => 1,
            blog_id      => $blog_id,
        }
    );
    my $tmpl;
    my $fullscreen;
    my $archive_file;
    my $orig_file;
    my $file_ext;
    my $file_template;
    require MT::Template::Context;
    require ArchiveType::CustomObject;
    my $ctx = MT::Template::Context->new;
    $ctx->stash( 'blog', $blog );
    $ctx->stash( 'blog_id', $blog->id );
    $ctx->stash( 'customobject', $customobject );
    if ( $tmpl_map ) {
        $tmpl          = MT::Template->load( $tmpl_map->template_id );
        $file_ext      = $blog->file_extension || '';
        $file_template = $tmpl_map->file_template;
        my $at_lc = lc( $at );
        $file_template = $tmpl_map->file_template || $at_lc . '/%f';
        $archive_file = ArchiveType::CustomObject::get_publish_path( $ctx, $file_template );
        my $blog_path = site_path( $blog );
        require File::Basename;
        my $path;
        ( $orig_file, $path ) = File::Basename::fileparse( $archive_file );
        $file_ext = '.' . $file_ext if $file_ext ne '';
        $archive_file = File::Spec->catfile( $path, $preview_basename . $file_ext );
    } else {
        # $tmpl = $app->load_tmpl( 'preview_entry_content.tmpl' );
        # $fullscreen = 1;
    }
    return $app->error( $app->translate( 'Can\'t load template.' ) )
        unless $tmpl;
    MT::Util::translate_naughty_words( $customobject );
    my @data = ( { data_name => 'author_id', data_value => $user_id } );
    $app->run_callbacks( 'cms_pre_preview', $app, $customobject, \@data );
    $ctx->{ current_archive_type } = $at;
    $ctx->var( 'archive_class', 'customobject-archive' );
    $ctx->var( 'customobject_class', $type );
    $ctx->var( 'customobject_archive', 1 );
    $ctx->var( 'archive_template', 1 );
    $ctx->var( 'preview_template', 1 );
    $tmpl->context( $ctx );
    my $html = $tmpl->output;
    unless ( defined( $html ) ) {
        my $preview_error = $app->translate( "Publish error: [_1]",
            MT::Util::encode_html( $tmpl->errstr ) );
        $param{ preview_error } = $preview_error;
        my $tmpl_plain = $app->load_tmpl( 'preview_entry_content.tmpl' );
        $tmpl->text( $tmpl_plain->text );
        $html = $tmpl->output;
        defined( $html )
            or return $app->error(
            $app->translate( "Publish error: [_1]", $tmpl->errstr ) );
        $fullscreen = 1;
    }
    my ( $old_url, $new_url );
    if ( $app->config( 'LocalPreviews' ) ) {
        $old_url = $blog->site_url;
        $old_url =~ s!^(https?://[^/]+?/)(.*)?!$1!;
        $new_url = $app->base . '/';
        $html =~ s!\Q$old_url\E!$new_url!g;
    }
    if (! $fullscreen ) {
        my $fmgr = $blog->file_mgr;
        require File::Basename;
        my $path = File::Basename::dirname( $archive_file );
        $path =~ s!/$!!
            unless $path eq '/';
        unless ( $fmgr->exists( $path ) ) {
            $fmgr->mkpath( $path );
        }
        if ( $fmgr->exists( $path ) && $fmgr->can_write( $path ) ) {
            $fmgr->put_data( $html, $archive_file );
            $param{ preview_file } = $preview_basename;
            $ctx->stash( 'blog', $blog );
            $ctx->stash( 'blog_id', $blog->id );
            $ctx->stash( 'customobject', $customobject );
            my $preview_url = ArchiveType::CustomObject::get_publish_path( $ctx, $file_template, 'url' );
            $preview_url
                =~ s! / \Q$orig_file\E ( /? ) $!/$preview_basename$file_ext$1!x;
            if ( defined $new_url ) {
                $preview_url =~ s!^\Q$old_url\E!$new_url!;
            }
            $param{ preview_url } = $preview_url;
            require MT::Session;
            my $sess_obj = MT::Session->get_by_key(
                {   id   => $preview_basename,
                    kind => 'TF',
                    name => $archive_file,
                }
            );
            $sess_obj->start( time );
            $sess_obj->save;
        } else {
            $fullscreen = 1;
            $param{ preview_error }
                = $app->translate(
                "Unable to create preview file in this location: [_1]",
                $path );
            my $tmpl_plain = $app->load_tmpl( 'preview_entry_content.tmpl' );
            $tmpl->text( $tmpl_plain->text );
            $tmpl->reset_tokens;
            $html = $tmpl->output;
            $param{ preview_body } = $html;
        }
    } else {
        $param{ preview_body } = $html;
    }
    $param{ id } = $id if $id;
    $param{ new_object } = $param{id} ? 0 : 1;
    $param{ title }      = $customobject->name;
    $param{ status }     = $customobject->status;
    my $cols = $model->column_names;
    for my $col ( @$cols ) {
        next
            if $col eq 'created_on'
                || $col eq 'created_by'
                || $col eq 'modified_on'
                || $col eq 'modified_by'
                || $col eq 'authored_on'
                || $col eq 'author_id'
                || $col eq 'period_on'
                || $col eq 'class'
                || $col eq 'current_revision';
        push @data,
            { data_name  => $col,
              data_value => scalar $app->param( $col ) };
    }
    for my $data (
        qw( class authored_on_date authored_on_time period_on_date period_on_time tags save_revision revision-note ) )
        {
        push @data,
            { data_name  => $data,
             data_value => scalar $app->param( $data ) };
    }
    $param{ entry_loop } = \@data;
    my $list_title = $plugin->translate( $at );
    my $list_mode  = $type;
    if ( $id ) {
        $app->add_breadcrumb(
            $app->translate( $list_title ),
            $app->uri(
                'mode' => 'list',
                args   => {
                    '_type' => $list_mode,
                    blog_id => $blog_id
                }
            )
        );
        $app->add_breadcrumb( $customobject->name
                || $app->translate('(untitled)') );
    } else {
        $app->add_breadcrumb(
            $app->translate( $list_title ),
            $app->uri(
                'mode' => 'list',
                args   => {
                    '_type' => $list_mode,
                    blog_id => $blog_id
                }
            )
        );
        $app->add_breadcrumb(
            $app->translate( 'New [_1]', $model->class_label ) );
        $param{ nav_new_entry } = 1;
    }
    $param{ object_type } = 'customobject';
    $param{ object_label } = $model->class_label;
    $param{ diff_view } = $app->param( 'rev_numbers' )
        || $app->param( 'collision' );
    $param{ collision } = 1;
    if ( $app->param( 'rev_numbers' ) ) {
        if ( my @rev_numbers = split /,/, $app->param( 'rev_numbers' ) ) {
            $param{ comparing_revisions } = 1;
            $param{ rev_a }               = $rev_numbers[ 0 ];
            $param{ rev_b }               = $rev_numbers[ 1 ];
        }
    }
    $param{ dirty } = $app->param( 'dirty' ) ? 1 : 0;
    if ( $fullscreen ) {
        return $app->load_tmpl( 'preview_entry.tmpl', \%param );
    } else {
        $app->request( 'preview_object', $customobject );
        return $app->load_tmpl( 'preview_strip.tmpl', \%param );
    }
}

sub _preview_strip {
    my ( $cb, $app, $tmpl ) = @_;
    if ( $app->mode eq 'preview_customobject' ) {
        my $type = $app->param( '_type' );
        my $custom_objects = MT->registry( 'custom_objects' );
        my $at = $custom_objects->{ $type }->{ id };
        $$tmpl =~ s/name="_type"/name="_type" id="_type"/;
        $$tmpl =~ s/\spage/ $at/g;
        my $mode = quotemeta( 'mt:mode="save_entry"' );
        my $script = "     onclick=\"getByID('_type').value='$type';\"";
        $$tmpl =~ s/$mode/mt:mode="save"\n$script/g;
        $$tmpl = "<__trans_section component=\"$at\">" . $$tmpl . "</__trans_section>";
    }
    return 1;
}

1;