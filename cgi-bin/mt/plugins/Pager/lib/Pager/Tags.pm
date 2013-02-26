package Pager::Tags;
#use strict;

use MT::Util qw( archive_file_for );
use Pager::Util qw( ceil );

sub _pager_loop {
    my ( $ctx, $args, $cond ) = @_;
    my $app = MT->instance();
    if ( ( ref $app ) =~ /^MT::App::Search/ ) {
        require MT::Template::Tags::Pager;
        return MT::Template::Tags::Pager::_hdlr_pager_block( @_ );
    }
    my $total = $ctx->stash( 'total' ) || 0;
    $total = $args->{ items } if $args->{ items };
    my $blog = $ctx->stash( 'blog' );
    my $template = $ctx->stash( 'template' );
    my $is_pager = $ctx->stash( 'pager' );
    my $at_index = $ctx->stash( 'at_index' );
    my $tmpl_src = $template->text;
    my $limit;
    $limit = $1 if $tmpl_src =~ /<(?i:mt:?entries)(?=\s).*?\slimit\s*=\s*["']?([0-9]+)[^>]*>/s || 0;
    my $repeat = 1;
    if ( $limit < $total ) {
        $repeat = $total / $limit if 0 < $limit;
        $repeat = ceil( $repeat );
    }
    $repeat--;
    my $tokens = $ctx->stash( 'tokens' );
    my $builder = $ctx->stash( 'builder' );
    my $pager_link;
    if ( $at_index ) {
        $pager_link = $blog->site_url;
        $pager_link .= '/' if ( $pager_link !~ /\/$/ );
        $pager_link .= $template->outfile;
    } else {
        $pager_link = _hdlr_archive_link( $ctx, $cond );
    }
    if ( $pager_link =~ /(.*)\/$/ ) {
        $args->{extension} = 1;
        $pager_link .= _hdlr_index_basename( $ctx, $args, $cond );
    }
    my $res = ''; my $i = 1;
    my $vars = $ctx->{ __stash }{ vars } ||= {};
    my $var = $args->{var};
    my $glue = $args->{glue};
    if ( $repeat > 0 ) {
        local $ctx->{ __stash }{ 'next' } = 1 unless $is_pager;
        local $ctx->{ __stash }{ 'current' } = 1 unless $is_pager;
        local $ctx->{ __stash }{ 'current' } = $is_pager if $is_pager;
        local $ctx->{ __stash }{ 'prev_link' } = $pager_link;
        my $prev_link = $pager_link;
        my $prev_num = $is_pager - 1;
        $prev_link =~ s/(.*)(\..*)/$1_$prev_num$2/ if ( $prev_num > 0 );
        local $ctx->{ __stash }{ 'prev_link' } = $prev_link if ( $prev_num > 1 );
        my $next_link = $pager_link;
        $next_link =~ s/(.*)(\..*)/$1_2$2/ unless $is_pager;
        $is_pager++ if $is_pager;
        $next_link =~ s/(.*)(\..*)/$1_$is_pager$2/ if $is_pager;
        local $ctx->{ __stash }{ 'next_link' } = $next_link;
        local $ctx->{ __stash }{ 'header' } = 1;
        local $ctx->{ __stash }{ 'repeat' } = $repeat + 1;
        local $ctx->{ __stash }{ 'counter' } = $i;
        local $vars->{ __first__ } = 1;
        local $vars->{ __value__ } = $i;
        local $vars->{ __counter__ } = $i;
        local $vars->{ __index__ } = $i;
        local $vars->{ $var } = $i if defined $var;
        local $vars->{ __odd__ } = ( $i % 2 ) == 1;
        local $vars->{ __even__ } = ( $i % 2 ) == 0;
        local $ctx->{ __stash }{ 'pager_link' } = $pager_link;
        my $out = $builder->build( $ctx, $tokens, $cond );
        $res .= $out;
        $i++;
        for ( 1 .. $repeat ) {
            my $file_num = $_ + 1;
            my $new_link = $pager_link;
            $new_link =~ s/(.*)(\..*)/$1_$file_num$2/;
            local $ctx->{ __stash }{ 'repeat' } = $repeat + 1;
            local $ctx->{ __stash }{ 'counter' } = $i;
            local $ctx->{ __stash }{ 'pager_link' } = $new_link;
            local $ctx->{ __stash }{ 'header' } = 0;
            local $vars->{ __first__ } = 0;
            local $vars->{ __value__ } = $i;
            local $vars->{ __counter__ } = $i;
            local $vars->{ __index__ } = $i;
            local $vars->{ __odd__ } = ( $i % 2 ) == 1;
            local $vars->{ __even__ } = ( $i % 2 ) == 0;
            local $vars->{ $var } = $i if defined $var;
            local $ctx->{ __stash }{ 'footer' } = 1 if ( $i == ( $repeat + 1 ) );
            local $vars->{ __last__ } = 1 if ( $i == ( $repeat + 1 ) );
            my $out = $builder->build( $ctx, $tokens, $cond );
            $res .= $glue if ( $i > 1 && $glue );
            $res .= $out;
            $i++;
        }
    }
    $res;
}

sub _pager_current {
    my ( $ctx, $args, $cond ) = @_;
    return $ctx->stash( 'current' ) || 0;
}

sub _if_header {
    my ( $ctx, $args, $cond ) = @_;
    return $ctx->stash( 'header' ) || 0;
}

sub _if_footer {
    my ( $ctx, $args, $cond ) = @_;
    return $ctx->stash( 'footer' ) || 0;
}

sub _if_prev {
    my ( $ctx, $args, $cond ) = @_;
    return $ctx->stash( 'prev' ) || 0;
}

sub _if_next {
    my ( $ctx, $args, $cond ) = @_;
    return $ctx->stash( 'next' ) || 0;
}

sub _if_current {
    my ( $ctx, $args, $cond ) = @_;
    my $counter = $ctx->stash( 'counter' );
    my $current = $ctx->stash( 'current' );
    return $counter == $current ? 1 : 0;
}

sub _pager_next {
    my ( $ctx, $args, $cond ) = @_;
    return $ctx->stash( 'next_link' ) || '';
}

sub _pager_prev {
    my ( $ctx, $args, $cond ) = @_;
    return $ctx->stash( 'prev_link' ) || '';
}

sub _pager_link {
    my ( $ctx, $args, $cond ) = @_;
    my $app = MT->instance();
    if ( ( ref $app ) =~ /^MT::App::Search/ ) {
        require MT::Template::Tags::Pager;
        return MT::Template::Tags::Pager::_hdlr_pager_link( @_ );
    }
    return $ctx->stash( 'pager_link' ) || '';
}

sub _pager_counter {
    my ( $ctx, $args, $cond ) = @_;
    return $ctx->stash( 'counter' ) || '';
}

sub _pager_total {
    my ( $ctx, $args, $cond ) = @_;
    my $repeat = $ctx->stash( 'repeat' );
    return $repeat if $repeat;
    my $total = _hdlr_archive_count( $ctx );
    my $template = $ctx->stash( 'template' );
    my $tmpl_src = $template->text;
    my $limit;
    $limit = $1 if $tmpl_src =~ /<(?i:mt:?entries)(?=\s).*?\slimit\s*=\s*["']?([0-9]+)[^>]*>/s;
    $repeat = 1;
    if ( ( 0 < $limit ) && ( $limit < $total ) ) {
        $repeat = $total / $limit;
        $repeat = ceil( $repeat );
    }
    return $repeat;
}

# TODO: following is from MT::Template::Tags::Archive

sub _hdlr_archive_count {
    my ( $ctx, $args, $cond ) = @_;
    my $at = $ctx->{ current_archive_type } || $ctx->{ archive_type };
    my $archiver = MT->publisher->archiver( $at );
    if ( $ctx->{ inside_mt_categories } && !$archiver->date_based ) {
        return $ctx->invoke_handler( 'categorycount', $args, $cond );
    }
    if (my $count = $ctx->stash( 'archive_count' ) ) {
        return $ctx->count_format( $count, $args );
    }
    my $e = $ctx->stash( 'entries' );
    my @entries = @$e if ref( $e ) eq 'ARRAY';
    my $count = scalar @entries;
    return $ctx->count_format( $count, $args );
}

sub _hdlr_archive_link {
    my( $ctx, $args ) = @_;
    my $at = $args->{ type }
          || $args->{ archive_type }
          || $ctx->{ current_archive_type }
          || $ctx->{ archive_type };
    return $ctx->invoke_handler( 'categoryarchivelink', $args )
        if ($at && ('Category' eq $at)) ||
           ( $ctx->{ current_archive_type } && 'Category' eq $ctx->{ current_archive_type } );
    my $archiver = MT->publisher->archiver( $at )
        or return '';
    my $blog = $ctx->stash( 'blog' );
    my $entry;
    if ($archiver->entry_based) {
        $entry = $ctx->stash( 'entry' );
    }
    my $author = $ctx->stash( 'author' );
    my $cat;
    if ( $archiver->category_based ) {
        $cat = $ctx->stash( 'category' ) || $ctx->stash( 'archive_category' );
    }
    return $ctx->error( MT->translate(
        "You used an [_1] tag for linking into '[_2]' archives, but that archive type is not published.", '<$MTArchiveLink$>', $at))
        unless $blog->has_archive_type( $at );
    my $arch = $blog->archive_url;
    $arch = $blog->site_url if $entry && $entry->class eq 'page';
    $arch .= '/' unless $arch =~ m!/$!;
    $arch .= archive_file_for( $entry, $blog, $at, $cat, undef,
                               $ctx->{ current_timestamp }, $author );
    $arch = MT::Util::strip_index( $arch, $blog ) unless $args->{ with_index };
    return $arch;
}

sub _hdlr_index_basename {
    my ( $ctx, $args, $cond ) = @_;
    my $name = $ctx->{ config }->IndexBasename;
    if (!$args->{ extension }) {
        return $name;
    }
    my $blog = $ctx->stash( 'blog' );
    my $ext = $blog->file_extension;
    $ext = '.' . $ext if $ext;
    $name . $ext;
}

1;
