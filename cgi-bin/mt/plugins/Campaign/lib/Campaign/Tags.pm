package Campaign::Tags;
#use strict;

# use Campaign::Campaign;
# use Campaign::CampaignGroup;
# use Campaign::CampaignOrder;
use File::Spec;
use Fcntl qw( :DEFAULT :flock );
use lib qw( addons/PowerCMS.pack/lib );
use PowerCMS::Util qw( current_ts write2file is_application
                       include_exclude_blogs is_cms format_LF valid_ip );

our $plugin_campaign = MT->component( 'Campaign' );

sub _hdlr_campaigns {
    my ( $ctx, $args, $cond ) = @_;
    require Campaign::Campaign;
    my $tokens = $ctx->stash( 'tokens' );
    my $builder = $ctx->stash( 'builder' );
    my $blog = $ctx->stash( 'blog' );
    my $blog_id = $args->{ blog_id };
    my $orig_blog_id = $blog_id;
    if ( $blog_id && ( $blog_id != $blog->id ) ) {
        $blog = MT::Blog->load( $blog_id );
    }
    $blog_id ||= $blog->id;
    my $active = $args->{ active };
    my $lastn  = $args->{ lastn };
    my $limit  = $lastn || $args->{ limit } || 9999;
    my $offset = $args->{ offset } || 0;
    my $sort_order = $args->{ sort_order } || 'ascend';
    my $sort_by = $args->{ sort_by } || 'publishing_on';
    my $group = $args->{ group };
    my $group_id = $args->{ group_id };
    my $tag_name = $args->{ tag };
    my %terms;
    my %params;
    # $terms{ blog_id } = $blog_id if $blog_id;
    if (! $args->{ include_draft } ) {
        $terms{ status } = 2;
    }
    if ( $active ) {
        my $ts = current_ts( $blog );
        $terms{ publishing_on } = { '<' => $ts };
        $terms{ period_on }     = { '>' => $ts };
        $terms{ status } = 2;
    }
    my @ids;
    if ( my $idstr = $args->{ ids } ) {
        $idstr =~ s/^,+//;
        $idstr =~ s/,+$//;
        @ids = split( /,/, $idstr );
    } elsif ( my $id = $args->{ id } ) {
        push ( @ids, $id );
    }
    if ( $group || $group_id ) {
        require Campaign::CampaignGroup;
        require Campaign::CampaignOrder;
        if (! $group_id ) {
            my $cg = Campaign::CampaignGroup->load( { name => $group, blog_id => $blog_id } )
                or return '';
            $group_id = $cg->id;
        }
        $params { 'join' } = [ 'Campaign::CampaignOrder', 'campaign_id',
                   { group_id => $group_id, },
                   { 'sort' => 'order',
                     limit  => $limit,
                     offset => $offset,
                     direction => $sort_order,
                   } ];
    } elsif ( $tag_name ) {
        require MT::Tag;
        my $tag = MT::Tag->load( { name => $tag_name }, { binary => { name => 1 } } )
            or return '';
        $params{ limit }     = $limit;
        $params{ offset }    = $offset;
        $params{ direction } = $sort_order;
        $params{ 'sort' }    = $sort_by;
        require MT::ObjectTag;
        $params { 'join' } = [ 'MT::ObjectTag', 'object_id',
                   { tag_id => $tag->id,
                     # blog_id => $blog_id,
                     object_datasource => 'campaign' }, ];
    } else {
        $params{ limit }     = $limit;
        $params{ offset }    = $offset;
        $params{ direction } = $sort_order;
        $params{ 'sort' }    = $sort_by;
    }
    # my $include_blogs = $args->{ include_blogs } || $args->{ blog_ids };
    # if (! $include_blogs ) {
    #     $terms{ blog_id } = $blog_id if $blog_id;
    # }
    if ( (! $group ) && (! @ids ) ) {
       # my @blog_ids = include_blogs( $blog, $include_blogs );
        if ( $orig_blog_id ) {
            $terms{ blog_id } = $orig_blog_id;
        } else {
            my @blog_ids = include_exclude_blogs( $ctx, $args );
            $terms{ blog_id } = \@blog_ids if scalar @blog_ids;
        }
    }
    if ( @ids ) {
        $terms{ id } = \@ids;
    }
    my @terms;
    if ( $active ) {
        $terms{ set_period } = 1;
        my %another_terms = %terms;
        delete $another_terms{ publishing_on };
        delete $another_terms{ period_on };
        $another_terms{ set_period } = { 'not' => 1 };
        @terms = ( \%terms, '-or', \%another_terms );
    }
#    my @campaigns = MT->model( 'campaign' )->load( \%terms, \%params );
    my @campaigns = MT->model( 'campaign' )->load( @terms ? \@terms : \%terms, \%params );
    my $shuffle = $args->{ shuffle };
    _shuffle( \@campaigns ) if $shuffle;
    my $i = 0;
    my $res = '';
    my $glue = $args->{ glue };
    my $vars = $ctx->{ __stash }{ vars } ||= +{};
    for my $campaign ( @campaigns ) {
        local $ctx->{ __stash }{ campaign } = $campaign;
        my $other_blog;
        if ( $blog->id != $campaign->blog_id ) {
            $other_blog = $campaign->blog;
        }
        local $ctx->{ __stash }{ blog }    = $other_blog || $blog;
        local $ctx->{ __stash }{ blog_id } = $other_blog ? $other_blog->id : $blog->id;
        my ( $url, $w, $h );
        if ( $campaign->image_id ) {
            ( $url, $w, $h ) = $campaign->banner;
        } else {
            $w = $campaign->banner_width;
            $h = $campaign->banner_height;
        }
        my $last = !defined $campaigns[$i + 1];
        local $ctx->{ __stash }{ campaign_banner_url }    = $url;
        local $ctx->{ __stash }{ campaign_banner_width }  = $w;
        local $ctx->{ __stash }{ campaign_banner_height } = $h;
        local $ctx->{ __stash }{ campaign_asset_image }   = $campaign->image if $campaign->image_id;
        local $vars->{ __first__ }   = !$i;
        local $vars->{ __counter__ } = $i + 1;
        local $vars->{ __odd__ }     = $i % 2 ? 0 : 1;
        local $vars->{ __even__ }    = $i % 2;
        local $vars->{ __last__ }    = $last;
        my $out = $builder->build( $ctx, $tokens, {
            %$cond,
            BannersHeader => !$i, BannersFooter => $last,
            # Backcompat
            CampaignsHeader => !$i, CampaignsFooter => $last,
        } );
        if ( !defined( $out ) ) { return $ctx->error( $builder->errstr ) };
        $res .= $glue if defined $glue && $i && length($res) && length($out);
        $res .= $out;
        $i++;
    }
    return $res;
}

sub _hdlr_campaign {
    my ( $ctx, $args, $cond ) = @_;
    my $blog = $ctx->stash( 'blog' );
    my $blog_id = $args->{ blog_id };
    if ( $blog_id && ( $blog_id != $blog->id ) ) {
        $blog = MT::Blog->load( $blog_id );
    }
    $blog_id ||= $blog->id;
    my $basename = $args->{ basename };
    $basename    = $args->{ identifier } if $args->{ identifier };
    my $id = $args->{ id };
    my $title  = $args->{ title };
    my $active = $args->{ active };
    my %terms;
    if (! $id ) {
        $terms{ blog_id } = $blog_id if $blog_id;
    }
    $terms{ basename } = $basename if $basename;
    $terms{ title }    = $title if $title;
    $terms{ id }       = $id if $id;
    $terms{ status }   = 2;
    my @terms;
    if ( $active ) {
        my $ts = current_ts( $blog );
        $terms{ publishing_on } = { '<' => $ts };
        $terms{ period_on }     = { '>' => $ts };
        $terms{ set_period } = 1;
        my %another_terms = %terms;
        delete $another_terms{ publishing_on };
        delete $another_terms{ period_on };
        $another_terms{ set_period } = { 'not' => 1 };
        @terms = ( \%terms, '-or', \%another_terms );
    }
#    my $campaign = MT->model( 'campaign' )->load( \%terms, { limit => 1 } );
                                            # or return $ctx->error();
    my $campaign = MT->model( 'campaign' )->load( @terms ? \@terms : \%terms, { limit => 1 } );
    return '' unless defined $campaign;
    local $ctx->{ __stash }{ 'blog' } = $blog;
    local $ctx->{ __stash }{ 'blog_id' } = $blog_id;
    local $ctx->{ __stash }{ 'campaign' } = $campaign;
    my ( $url, $w, $h );
    if ( $campaign->image_id ) {
        ( $url, $w, $h ) = $campaign->banner;
    } else {
        $w = $campaign->banner_width;
        $h = $campaign->banner_height;
    }
    local $ctx->{ __stash }{ 'campaign_banner_url' } = $url;
    local $ctx->{ __stash }{ 'campaign_banner_width' } = $w;
    local $ctx->{ __stash }{ 'campaign_banner_height' } = $h;
    local $ctx->{ __stash }{ 'campaign_asset_image' } = $campaign->image if $campaign->image_id;
    my $tokens  = $ctx->stash( 'tokens' );
    my $builder = $ctx->stash( 'builder' );
    my $content = $builder->build( $ctx, $tokens, $cond );
    return $content;
}

sub _hdlr_campaign_random {
    my ( $ctx, $args, $cond ) = @_;
    require Campaign::Campaign;
    my $tokens = $ctx->stash( 'tokens' );
    my $builder = $ctx->stash( 'builder' );
    my $blog = $ctx->stash( 'blog' );
    my $blog_id = $args->{ blog_id };
    if ( $blog_id && ( $blog_id != $blog->id ) ) {
        $blog = MT::Blog->load( $blog_id );
    }
    $blog_id ||= $blog->id;
    my $active = $args->{ active };
    my $group = $args->{ group };
    my $tag_name = $args->{ tag };
    my %terms;
    my %params;
    $terms{ blog_id } = $blog_id if $blog_id;
    $terms{ status }  = 2;
    if ( $active ) {
        my $ts = current_ts( $blog );
        $terms{ publishing_on } = { '<' => $ts };
        $terms{ period_on }     = { '>' => $ts };
    }
    if ( $group ) {
        require Campaign::CampaignGroup;
        require Campaign::CampaignOrder;
        my $cg = Campaign::CampaignGroup->load( { name => $group, blog_id => $blog_id } )
            or return '';
        $params { 'join' } = [ 'Campaign::CampaignOrder', 'campaign_id',
                   { group_id => $cg->id, }, ];
    } elsif ( $tag_name ) {
        require MT::Tag;
        my $tag = MT::Tag->load( { name => $tag_name }, { binary => { name => 1 } } )
            or return;
        require MT::ObjectTag;
        $params { 'join' } = [ 'MT::ObjectTag', 'object_id',
                   { tag_id  => $tag->id,
                     blog_id => $blog_id,
                     object_datasource => 'campaign' }, ];
    }
    my @terms;
    if ( $active ) {
        $terms{ set_period } = 1;
        my %another_terms = %terms;
        delete $another_terms{ publishing_on };
        delete $another_terms{ period_on };
        $another_terms{ set_period } = { 'not' => 1 };
        @terms = ( \%terms, '-or', \%another_terms );
    }
#    my @campaigns = MT->model( 'campaign' )->load( \%terms, \%params );
    my @campaigns = MT->model( 'campaign' )->load( @terms ? \@terms : \%terms, \%params );
    my $max = scalar( @campaigns );
    my $counter = int( rand ( $max ) );
    my $campaign = $campaigns[ $counter ];
    return '' unless defined $campaign;
    $ctx->stash( 'blog', $blog );
    $ctx->stash( 'campaign', $campaign );
    if ( $campaign->image_id ) {
        my ( $url, $w, $h ) = $campaign->banner;
        $ctx->stash( 'campaign_banner_url', $url );
        $ctx->stash( 'campaign_banner_width', $w );
        $ctx->stash( 'campaign_banner_height', $h );
        $ctx->stash( 'campaign_asset_image', $campaign->image );
    } else {
        $ctx->stash( 'campaign_banner_width',  $campaign->banner_width );
        $ctx->stash( 'campaign_banner_height', $campaign->banner_height );
    }
    my $content = $builder->build( $ctx, $tokens, $cond );
    return $content;
}

sub _hdlr_campaign_tags {
    my ( $ctx, $args, $cond ) = @_;
    my $tokens = $ctx->stash( 'tokens' );
    my $builder = $ctx->stash( 'builder' );
    my $campaign = $ctx->stash( 'campaign' );
    return $ctx->error() unless defined $campaign;
    require MT::ObjectTag;
    require MT::Asset;
    my $glue = $args->{ glue };
    local $ctx->{ __stash }{ tag_max_count } = undef;
    local $ctx->{ __stash }{ tag_min_count } = undef;
    local $ctx->{ __stash }{ all_tag_count } = undef;
    local $ctx->{ __stash }{ class_type } = 'campaign';
    my $iter = MT::Tag->load_iter( undef, { 'sort' => 'name',
                                            'join' => MT::ObjectTag->join_on( 'tag_id',
                                                    { object_id => $campaign->id,
                                                      blog_id => $campaign->blog_id,
                                                      object_datasource => 'campaign' },
                                                    { unique => 1 } ) } );
    my $res = '';
    while ( my $tag = $iter->() ) {
        next if $tag->is_private && !$args->{ include_private };
        local $ctx->{ __stash }{ Tag } = $tag;
        local $ctx->{ __stash }{ tag_count } = undef;
        local $ctx->{ __stash }{ tag_campaign_count } = undef;
        defined(my $out = $builder->build( $ctx, $tokens, $cond ) )
            or return $ctx->error( $builder->errstr );
        $res .= $glue if defined $glue && length( $res ) && length( $out );
        $res .= $out;
    }
    return $res;
}

sub _hdlr_if_campaign_tagged {
    my ( $ctx, $args, $cond ) = @_;
    return unless $ctx;
    my $campaign = $ctx->stash( 'campaign' );
    return $ctx->error() unless defined $campaign;
    my $tag = defined $args->{ name } ? $args->{ name } : ( defined $args->{ tag } ? $args->{ tag } : '' );
    if ( $tag ne '' ) {
        $campaign->has_tag( $tag );
    } else {
        my @tags = $campaign->tags;
        @tags = grep /^[^\@]/, @tags
            if !$args->{ include_private };
        return @tags ? 1 : 0;
    }
}

sub _hdlr_campaign_author {
    my ( $ctx, $args, $cond ) = @_;
    my $campaign = $ctx->stash( 'campaign' );
    return $ctx->error() unless defined $campaign;
    $ctx->stash( 'author', $campaign->author );
    $ctx->stash( 'builder' )->build( $ctx, $ctx->stash( 'tokens' ), $cond );
}

sub _hdlr_pass_tokens {
    my ( $ctx, $args, $cond ) = @_;
    $ctx->stash( 'builder' )->build( $ctx, $ctx->stash( 'tokens' ), $cond );
}

sub _hdlr_campaign_asset {
    my ( $ctx, $args, $cond ) = @_;
    my $campaign = $ctx->stash( 'campaign' );
    return $ctx->error() unless defined $campaign;
    my $class = lc($args->{ class } || $args->{ type } || 'image');
    my $asset;
    if ( $class eq 'image' ) {
        $asset = $campaign->image;
    } elsif ( $class eq 'movie' ) {
        $asset = $campaign->movie;
    }
    return '' unless $asset;
    $ctx->stash( 'asset', $asset );
    $ctx->stash( 'builder' )->build( $ctx, $ctx->stash( 'tokens' ), $cond );
}

sub _hdlr_if_campaign_has_image {
    my ( $ctx, $args, $cond ) = @_;
    my $campaign = $ctx->stash( 'campaign' );
    return $ctx->error() unless defined $campaign;
    return 0 unless $campaign->image_id;
    my $image = $campaign->image;
    return defined $image ? 1 : 0;
}

sub _hdlr_if_campaign_has_movie {
    my ( $ctx, $args, $cond ) = @_;
    my $campaign = $ctx->stash( 'campaign' );
    return $ctx->error() unless defined $campaign;
    return 0 unless $campaign->movie_id;
    my $movie = $campaign->movie;
    return defined $movie ? 1 : 0;
}

sub _hdlr_campaign_active {
    my ( $ctx, $args, $cond ) = @_;
    my $campaign = $ctx->stash( 'campaign' );
    return $ctx->error() unless defined $campaign;
    return 0 unless $campaign->status == 2;
    return 1 unless $campaign->set_period eq '1';
    my $blog = $ctx->stash( 'blog' );
    my $ts = current_ts( $blog );
    if ( ( $campaign->publishing_on < $ts ) && ( $campaign->period_on > $ts ) ) {
        return 1;
    }
    return 0;
}

sub _hdlr_campaign_column {
    my ( $ctx, $args, $cond ) = @_;
    my $tag = $ctx->stash( 'tag' );
    $tag =lc( $tag );
    $tag =~ s/^banner//i;
    $tag =~ s/^campaign//i; # BACKWARD
    my $campaign = $ctx->stash( 'campaign' );
    return $ctx->error() unless defined $campaign;
    return $campaign->$tag || '';
}

sub _hdlr_campaign_int {
    my ( $ctx, $args, $cond ) = @_;
    my $tag = $ctx->stash( 'tag' );
    $tag =lc( $tag );
    $tag =~ s/^banner//i;
    $tag =~ s/^campaign//i; # BACKWARD
    my $campaign = $ctx->stash( 'campaign' );
    return $ctx->error() unless defined $campaign;
    return $campaign->$tag || '0';
}

sub _hdlr_campaign_max {
    my ( $ctx, $args, $cond ) = @_;
    my $tag = $ctx->stash( 'tag' );
    $tag =lc( $tag );
    $tag =~ s/^bannermax/max_/i;
    $tag =~ s/^campaignmax/max_/i; # BACKWARD
    my $campaign = $ctx->stash( 'campaign' );
    return $ctx->error() unless defined $campaign;
    return $campaign->$tag || '0';
}

sub _hdlr_campaign_date {
    my ( $ctx, $args, $cond ) = @_;
    my $tag = $ctx->stash( 'tag' );
    $tag =~ s/^banner//i;
    $tag =~ s/^campaign//i; # BACKWARD
    $tag =~ s/on$//i;
    $tag =lc( $tag ) . '_on';
    my $campaign = $ctx->stash( 'campaign' );
    return $ctx->error() unless defined $campaign;
    my $date = $campaign->$tag;
    $args->{ ts } = $date;
    $date = $ctx->build_date( $args );
    return $date || '';
}

sub _hdlr_campaign_banner_url {
    my ( $ctx, $args, $cond ) = @_;
    return $ctx->stash( 'campaign_banner_url' ) || '';
}

sub _hdlr_campaign_banner_width {
    my ( $ctx, $args, $cond ) = @_;
    return $ctx->stash( 'campaign_banner_width' ) || '';
}

sub _hdlr_campaign_banner_height {
    my ( $ctx, $args, $cond ) = @_;
    return $ctx->stash( 'campaign_banner_height' ) || '';
}

sub _hdlr_campaign_movie_url {
    my ( $ctx, $args, $cond ) = @_;
    my $campaign = $ctx->stash( 'campaign' );
    return $ctx->error() unless defined $campaign;
    if ( $campaign->movie_id ) {
        if ( my $movie = $campaign->movie ) {
            return $movie->url;
        }
    }
    return '';
}

sub _hdlr_author_displayname {
    my ( $ctx, $args, $cond ) = @_;
    my $campaign = $ctx->stash( 'campaign' );
    return $ctx->error() unless defined $campaign;
    my $author_name = $campaign->author->nickname ||
                      $campaign->author->name;
    return $author_name;
}

sub _hdlr_campaign_counter {
    my ( $ctx, $args, $cond ) = @_;
    my $campaign = $ctx->stash( 'campaign' );
    return $ctx->error() unless defined $campaign;
    if ( my $dynamic = $args->{ dynamic } ) {
        #Task : Set displays ( check cookie and uniq user count )
    }
    return $campaign->displays || 0;
}

sub _hdlr_campaign_conversioncounter {
    my ( $ctx, $args, $cond ) = @_;
    my $campaign = $ctx->stash( 'campaign' );
    return $ctx->error() unless defined $campaign;
    if ( my $dynamic = $args->{ dynamic } ) {
        #Task : Set displays ( check cookie and uniq user count )
    }
    return $campaign->conversion || 0;
}

sub _hdlr_campaign_redirect {
    my ( $ctx, $args, $cond ) = @_;
    my $app = MT->instance();
    if ( !is_application( $app ) || is_cms( $app ) ) {
        return '';
    }
    my $campaign_id = $app->param( 'campaign_id' )
        or return '';
    my $campaign = $app->model( 'campaign' )->load( $campaign_id )
        or return '';
    require Campaign::Tools;
    if ( my $campaign_dir = Campaign::Tools::_make_campaign_dir() ) {
        my $exclude_ip_table = $plugin_campaign->get_config_value( 'exclude_ip_table', 'blog:'. $campaign->blog_id );
        $exclude_ip_table = format_LF( $exclude_ip_table );
        my @ip_table = split( /\n/, $exclude_ip_table );
        if ( valid_ip( $app->remote_ip, \@ip_table ) ) {
            if ( $campaign->url ) {
                $app->redirect( $campaign->url );
            }
            return '';
        }
        my $file = File::Spec->catfile( $campaign_dir, 'clickcount_' . $campaign->id . '.dat' );
        if (! -f $file ) {
            write2file( $file, '0' );
        }
        if ( -f $file ) {
            open my $fh, '+<', $file or die "$!:$file";
            flock $fh, LOCK_EX;
            my $count = <$fh>;
            $count++;
            seek $fh, 0, 0;
            print $fh $count;
            close $fh;
            $campaign->clicks( $count );
            if ( $campaign->max_clicks ) {
                if ( $campaign->max_clicks <= $count ) {
                    $campaign->status( 4 );
                }
            }
            # $campaign->save or die $campaign->errstr;
        }
        my $cookie = $app->cookie_val( 'mt_campaign_c' ) || '';
        my $cookie_expire = $plugin_campaign->get_config_value( 'cookie_expire', 'blog:'. $campaign->blog_id );
        my $timeout = time + $cookie_expire * 86400;
        my $uniq;
        if (! $cookie ) {
            $uniq = 1;
            my %new_cookie = ( -name    => 'mt_campaign_c',
                               -value   => $campaign_id . '-',
                               -expires => "+${timeout}s"
                               );
            $app->bake_cookie( %new_cookie );
        } else {
            my @cookie_id = split( /-/, $cookie );
            if ( grep( /^$campaign_id$/, @cookie_id ) ) {
                $uniq = 0;
                my %new_cookie = ( -name    => 'mt_campaign_c',
                                   -value   => $cookie,
                                   -expires => "+${timeout}s"
                                   );
                $app->bake_cookie( %new_cookie );
            } else {
                $uniq = 1;
                my %new_cookie = ( -name    => 'mt_campaign_c',
                                   -value   => $campaign_id . '-' . $cookie,
                                   -expires => "+${timeout}s"
                                   );
                $app->bake_cookie( %new_cookie );
            }
        }
        if ( $uniq ) {
            my $file = File::Spec->catfile( $campaign_dir, 'clickcount_uniq_' . $campaign->id . '.dat' );
            if (! -f $file ) {
                write2file( $file, '0' );
            }
            if ( -f $file ) {
                open my $fh, '+<', $file or die "$!:$file";
                flock $fh, LOCK_EX;
                my $count = <$fh>;
                $count++;
                seek $fh, 0, 0;
                print $fh $count;
                close $fh;
                $campaign->uniqclicks( $count );
                if ( $campaign->max_uniqclicks ) {
                    if ( $campaign->max_uniqclicks <= $count ) {
                        $campaign->status( 4 );
                    }
                }
            }
        }
        $campaign->save or die $campaign->errstr;
    }
    if ( $campaign->url ) {
        $app->redirect( $campaign->url );
    }
    return '';
}

sub _hdlr_campaign_script {
    return MT->config( 'BannerScript' ) || MT->config( 'CampaignScript' ) || 'mt-banner.cgi';
}

sub _hdlr_campaign_field_scope {
    my ( $ctx, $args, $cond ) = @_;
    return MT->config( 'BannerCustomFieldScope' ) || MT->config( 'CampaignCustomFieldScope' ) || 'blog';
}

sub _hdlr_if_not_sent {
    my ( $ctx, $args, $cond ) = @_;
    require MT::Request;
    my $r = MT::Request->instance;
    my $key = $args->{ key };
    $r->cache( $key )
        and return 0
        or $r->cache( $key, 1 );
    return 1;
}

sub _hdlr_if_ie {
    my ( $ctx, $args, $cond ) = @_;
    my $app = MT->instance();
    return 0 unless is_application( $app );
    my $user_agent = $app->get_header( 'User-Agent' );
    if ( $user_agent =~ /Windows/ ) {
        if ( $user_agent =~ /; MSIE (([1-9]\d*)(?:\.\d+)?);/ ) {
            $ctx->{ __stash }{ vars }{ ie_version }    = $2;
            $ctx->{ __stash }{ vars }{ ie_version_id } = $1;
            return 1;
        }
    }
    return 0;
}

sub _shuffle {
    my $array = shift;
    my $len = scalar( @$array );
    for ( my $i = $len - 1; $i >= 0; --$i ) {
        my $j = int( rand( $i + 1 ) );
        next if( $i == $j );
        @$array[ $i, $j ] = @$array[ $j, $i ];
    }
}

1;
