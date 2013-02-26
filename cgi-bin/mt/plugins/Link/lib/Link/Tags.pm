package Link::Tags;

use strict;
use MT::Util qw( encode_html );
use PowerCMS::Util qw( include_exclude_blogs );

our $plugin_link = MT->component( 'Link' );

sub _hdlr_links {
    my ( $ctx, $args, $cond ) = @_;
    require Link::Link;
    require Link::LinkGroup;
    require Link::LinkOrder;
    my $tokens = $ctx->stash( 'tokens' );
    my $builder = $ctx->stash( 'builder' );
    my $blog = $ctx->stash( 'blog' );
    my $blog_id = $args->{ blog_id };
    if ( $blog_id && ( $blog_id != $blog->id ) ) {
        $blog = MT::Blog->load( $blog_id );
    }
    $blog_id = $blog->id if (! $blog_id );
    my $lastn  = $args->{ lastn };
    my $limit  = $args->{ limit };
    $limit = $lastn if $lastn;
    my $offset = $args->{ offset };
    my $sort_order = $args->{ sort_order };
    $sort_order = 'ascend' unless $sort_order;
    $limit = 9999 unless $limit;
    my $sort_by = $args->{ sort_by };
    $sort_by = 'id' unless $sort_by;
    $offset = 0 unless $offset;
    my $rating = $args->{ rating };
    my $group = $args->{ group };
    my $group_id = $args->{ group_id };
    my @ids;
    if ( my $idstr  = $args->{ ids } ) {
        $idstr =~ s/^,//;
        $idstr =~ s/,$//;
        @ids = split( /,/, $idstr );
    } elsif ( my $id = $args->{ id } ) {
        push ( @ids, $id );
    }
    my $tag_name = $args->{ tag };
    my $url_active = $args->{ url_active };
    my $rss_active = $args->{ rss_active };
    my $image_active = $args->{ image_active };
    my %terms;
    my %params;
    # $terms{ blog_id } = $blog_id;
    $terms{ status } = Link::Link::RELEASE();
    $terms{ rating } = $rating if defined $rating;
    if ( $url_active ) {
        $terms{ broken_link } = { not => 1 };
        $terms{ url } = { not => '' };
    }
    if ( $rss_active ) {
        $terms{ broken_rss } = { not => 1 };
        $terms{ rss_address } = { not => '' };
    }
    if ( $image_active ) {
        $terms{ broken_image } = { not => 1 };
        $terms{ image_address } = { not => '' };
    }
    my $more = $args->{ more };
    my $less = $args->{ less };
#    if (! $rating ) {
    if (! defined $rating ) {
        if ( $more ) {
            $more--;
            $terms{ rating } = { '>' => $more };
        }
        if ( $less ) {
            $less++;
            $terms{ rating } = { '<' => $less };
        }
    }
    if ( $group || $group_id ) {
        if (! $group_id ) {
            my $g = Link::LinkGroup->load( { name => $group, blog_id => $blog_id } );
            return '' unless $g;
            $group_id = $g->id;
        }
        $params { 'join' } = [ 'Link::LinkOrder', 'link_id',
                   { group_id => $group_id },
                   { sort   => 'order',
                     limit  => $limit,
                     offset => $offset,
                     direction => $sort_order,
                   } ];
    } elsif ( $tag_name ) {
        require MT::Tag;
        my $tag = MT::Tag->load( { name => $tag_name }, { binary => { name => 1 } } );
        return '' unless $tag;
        $params{ limit }     = $limit;
        $params{ offset }    = $offset;
        $params{ direction } = $sort_order;
        $params{ 'sort' }    = $sort_by;
        require MT::ObjectTag;
        $params { 'join' } = [ 'MT::ObjectTag', 'object_id',
                   { tag_id  => $tag->id,
                     # blog_id => $blog_id,
                     object_datasource => 'link' }, ];
    } else {
        $params{ limit }     = $limit;
        $params{ offset }    = $offset;
        $params{ direction } = $sort_order;
        $params{ sort }      = $sort_by;
    }
    # my $include_blogs = $args->{ include_blogs };
    # if (! $include_blogs ) {
    #     $include_blogs = $args->{ blog_ids };
    # }
    # if (! $include_blogs ) {
    #     $terms{ blog_id } = $blog_id if $blog_id;
    # }
    if ( (! $group_id ) && (! @ids ) ) {
       # my @blog_ids = include_blogs( $blog, $include_blogs );
       my @blog_ids = include_exclude_blogs( $ctx, $args );
       $terms{ blog_id } = \@blog_ids if scalar @blog_ids;
    }
    if ( @ids ) {
        $terms{ id } = \@ids;
    }
    my @links = MT->model( 'link' )->load( \%terms, \%params );
    my $i = 0; my $res = '';
    my $odd = 1; my $even = 0;
    for my $link ( @links ) {
        local $ctx->{ __stash }{ 'link' } = $link;
        my $othor_blog;
        if ( $blog->id != $link->blog_id ) {
            $othor_blog = $link->blog;
        }
        local $ctx->{ __stash }{ blog } = $othor_blog if $othor_blog;
        local $ctx->{ __stash }{ blog_id } = $othor_blog->id if $othor_blog;
        local $ctx->{ __stash }->{ vars }->{ __first__ } = 1 if ( $i == 0 );
        local $ctx->{ __stash }->{ vars }->{ __counter__ } = $i + 1;
        local $ctx->{ __stash }->{ vars }->{ __odd__ } = $odd;
        local $ctx->{ __stash }->{ vars }->{ __even__ } = $even;
        local $ctx->{ __stash }->{ vars }->{ __last__ } = 1 if ( !defined( $links[ $i + 1 ] ) );
        my $out = $builder->build( $ctx, $tokens, {
            %$cond,
            'linksheader' => $i == 0,
            'linksfooter' => !defined( $links[ $i + 1 ] ),
        } );
        if ( !defined( $out ) ) { return $ctx->error( $builder->errstr ) };
        $res .= $out;
        if ( $odd == 1 ) { $odd = 0 } else { $odd = 1 };
        if ( $even == 1 ) { $even = 0 } else { $even = 1 };
        $i++;
    }
    return $res;
}

sub _hdlr_link {
    my ( $ctx, $args, $cond ) = @_;
    require Link::Link;
    my $blog = $ctx->stash( 'blog' );
    my $blog_id = $args->{ blog_id };
    if ( $blog_id && ( $blog_id != $blog->id ) ) {
        $blog = MT::Blog->load( $blog_id );
    }
    # $blog_id = $blog->id if (! $blog_id );
    my $id = $args->{ id };
    my %terms;
    # $terms{ blog_id }  = $blog_id if $blog_id;
    $terms{ id } = $id;
    $terms{ status }   = Link::Link::RELEASE();
    my $obj = MT->model( 'link' )->load( \%terms, { limit => 1 } );
                                            # or return $ctx->error();
    return '' unless defined $obj;
    $ctx->stash( 'blog', $blog );
    $ctx->stash( 'link', $obj );
    my $tokens  = $ctx->stash( 'tokens' );
    my $builder = $ctx->stash( 'builder' );
    my $content = $builder->build( $ctx, $tokens, $cond );
    return $content;
}

sub _hdlr_pass_tokens {
    my ( $ctx, $args, $cond ) = @_;
    $ctx->stash( 'builder' )->build( $ctx, $ctx->stash( 'tokens' ), $cond );
}

sub _hdlr_link_tags {
    my ( $ctx, $args, $cond ) = @_;
    my $tokens = $ctx->stash( 'tokens' );
    my $builder = $ctx->stash( 'builder' );
    my $link = $ctx->stash( 'link' );
    return $ctx->error() unless defined $link;
    require MT::ObjectTag;
    require MT::Asset;
    my $glue = $args->{ glue };
    local $ctx->{ __stash }{ tag_max_count } = undef;
    local $ctx->{ __stash }{ tag_min_count } = undef;
    local $ctx->{ __stash }{ all_tag_count } = undef;
    local $ctx->{ __stash }{ class_type } = 'link';
    my $iter = MT::Tag->load_iter( undef, { 'sort' => 'name',
                                            'join' => MT::ObjectTag->join_on( 'tag_id',
                                                    { object_id => $link->id,
                                                      blog_id => $link->blog_id,
                                                      object_datasource => 'link' },
                                                    { unique => 1 } ) } );
    my $res = '';
    while ( my $tag = $iter->() ) {
        next if $tag->is_private && !$args->{ include_private };
        local $ctx->{ __stash }{ Tag } = $tag;
        local $ctx->{ __stash }{ tag_count } = undef;
        local $ctx->{ __stash }{ tag_link_count } = undef;
        defined( my $out = $builder->build( $ctx, $tokens, $cond ) )
            or return $ctx->error( $builder->errstr );
        $res .= $glue if defined $glue && length( $res ) && length( $out );
        $res .= $out;
    }
    return $res;
}

sub _hdlr_link_author {
    my ( $ctx, $args, $cond ) = @_;
    my $link = $ctx->stash( 'link' );
    return $ctx->error() unless defined $link;
    $ctx->stash( 'author', $link->author );
    $ctx->stash( 'builder' )->build( $ctx, $ctx->stash( 'tokens' ), $cond );
}

sub _hdlr_if_link_tagged {
    my ( $ctx, $args, $cond ) = @_;
    return unless $ctx;
    my $link = $ctx->stash( 'link' );
    return $ctx->error() unless defined $link;
    my $tag = defined $args->{ name } ? $args->{ name } : ( defined $args->{ tag } ? $args->{ tag } : '' );
    if ( $tag ne '' ) {
        $link->has_tag( $tag );
    } else {
        my @tags = $link->tags;
        @tags = grep /^[^@]/, @tags
            if !$args->{ include_private };
        return @tags ? 1 : 0;
    }
}

sub _hdlr_link_html {
    my ( $ctx, $args, $cond ) = @_;
    return unless $ctx;
    my $link = $ctx->stash( 'link' );
    return $ctx->error() unless defined $link;
    my $name = $link->name;
    my $url = $link->url;
    if ( (! $name ) || (! $url ) ) {
        return '';
    }
    my $title = $link->title;
    my $target = $link->target;
    my $rel = $link->rel;
    $name = encode_html( $name );
    my $tag = "<a href=\"$url\"";
    if ( $title ) {
        $title = encode_html( $title );
        $tag .= " title=\"$title\"";
    }
    if ( $target ) {
        $target = encode_html( $target );
        $tag .= " target=\"$target\"";
    }
    if ( $rel ) {
        $rel = encode_html( $rel );
        $tag .= " rel=\"$rel\"";
    }
    $tag .= ">$name</a>";
    return $tag;
}

sub _hdlr_link_column {
    my ( $ctx, $args, $cond ) = @_;
    return unless $ctx;
    my $tag = $ctx->stash( 'tag' );
    $tag =lc( $tag );
    $tag =~ s/^link//i;
    $tag = 'blog_id' if $tag eq 'blogid';
    my $link = $ctx->stash( 'link' );
    return $ctx->error() unless defined $link;
    if ( $link->has_column( $tag ) ) {
        return $link->$tag;
    }
    return '';
}

sub _hdlr_link_date {
    my ( $ctx, $args, $cond ) = @_;
    return unless $ctx;
    my $tag = $ctx->stash( 'tag' );
    $tag =~ s/^link//i;
    $tag =~ s/on$//i;
    $tag =lc( $tag ) . '_on';
    my $link = $ctx->stash( 'link' );
    return $ctx->error() unless defined $link;
    if (! $link->has_column( $tag ) ) {
        return '';
    }
    my $date = $link->$tag;
    $args->{ ts } = $date;
    $date = $ctx->build_date( $args );
    return $date || '';
}

sub _hdlr_if_link_broken {
    my ( $ctx, $args, $cond ) = @_;
    return unless $ctx;
    my $tag = $ctx->stash( 'tag' );
    $tag =lc( $tag );
    $tag =~ s/^ifbroken/broken_/i;
    my $link = $ctx->stash( 'link' );
    return $ctx->error() unless defined $link;
    if (! $link->has_column( $tag ) ) {
        return 0;
    }
    my $bool = $link->$tag;
    return $bool if $bool;
    return 0;
}

sub _hdlr_if_link_active {
    my ( $ctx, $args, $cond ) = @_;
    return unless $ctx;
    my $tag = $ctx->stash( 'tag' );
    $tag =lc( $tag );
    $tag =~ s/^ifactive/broken_/i;
    my $link = $ctx->stash( 'link' );
    return $ctx->error() unless defined $link;
    if (! $link->has_column( $tag ) ) {
        return 0;
    }
    my $bool = $link->$tag;
    return 0 if ( $bool == 1 );
    return 1;
}

sub _hdlr_author_displayname {
    my ( $ctx, $args, $cond ) = @_;
    my $link = $ctx->stash( 'link' );
    return $ctx->error() unless defined $link;
    my $author_name = $link->author->nickname;
    $author_name = $link->author->name unless $author_name;
    return $author_name;
}

sub _hdlr_link_field_scope {
    my ( $ctx, $args, $cond ) = @_;
    return MT->config( 'LinkCustomFieldScope' ) || 'blog';
}

1;
