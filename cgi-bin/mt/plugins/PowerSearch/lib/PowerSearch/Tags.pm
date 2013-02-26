package PowerSearch::Tags;
use strict;
use warnings;
use lib qw( addons/PowerCMS.pack/lib );

use MT;
use MT::Request;
use MT::Util qw( format_ts decode_html );
use PowerCMS::Util qw( utf8_on site_path site_url ceil normalize );

sub __param {
    my ( $app, $name ) = @_;
    if ( $app->can('param') && defined $app->param($name) ) {
        return $app->param($name);
    }
    return wantarray ? () : '';
}

sub _estraier_meta {
    my ( $ctx, $args, $cond ) = @_;
    my $app    = MT->instance;
    my $plugin = MT->component('PowerSearch');
    my $tokens  = $ctx->stash('tokens');
    my $builder = $ctx->stash('builder');
    my $vars    = $ctx->{__stash}{vars} ||= {};
    my @target  = __param( $app, 'target' );
    #my $c = '';
    #for my $id (@target) {
    #    if ( $id =~ /^[0-9]{1,}$/ ) {
    #        $c .= " $id";
    #    }
    #}
    #my $c = join ' ', grep /^[1-9][0-9]*$/, @target;
    #$c &&= " $c";
    my $tbid = join( ',', @target );
    my $query = __param( $app, 'query' );
    $query = normalize( $query );
    my $offset = __param( $app, 'offset' ) || 1;
    unless ($offset =~ /^(?:0|[1-9][0-9]*)$/) {
        $offset = 1;
    }
    my $suffix = __param( $app, 'suffix' );
    my $limit = __param( $app, 'limit' );
    unless ($limit =~ /^(?:0|[1-9][0-9]*)$/) {
        $limit = $plugin->get_config_value('default_res_limit');
    }
    $vars->{__offset__} = $offset;
    $vars->{__limit__}  = $limit;
    $vars->{__suffix__} = $suffix;
    $vars->{__query__}  = $query;
    $vars->{__target__} = $tbid;
    $vars->{__qurey__}  = $query;
    $ctx->stash('builder')->build( $ctx, $ctx->stash('tokens'), $cond );
}

sub __set_blog_id_condition {
    my ( $cond, $blog_id_str ) = @_;
    if ($blog_id_str) {
        $cond->add_attr( '@blog_id STROREQ' . $blog_id_str );
    }
    else {
        $cond->add_attr('@blog_id STROREQ DONOTHIT');
    }
}

sub __estraier_block {
    my ( $ctx, $args, $cond, $use_param ) = @_;
    my $plugin  = MT->component('PowerSearch');
    my $tokens  = $ctx->stash('tokens');
    my $builder = $ctx->stash('builder');
    my $vars    = $ctx->{__stash}{vars} ||= {};
    eval { require Estraier };
    unless ($@) {
        require MT::Blog;
        my $app    = MT->instance;
        my $casket = MT->config('EstcmdIndex');
        my ( @target, @suffix );
        if ($use_param) {
            @target = __param( $app, 'target' );
            @suffix = __param( $app, 'suffix' );
        }
        else {
            my $includeblogs
                = defined $args->{includeblogs}
                ? $args->{includeblogs}
                : '';
            @target = split( /,/, $includeblogs );
            my $sfxes
                = defined $args->{suffix}
                ? $args->{suffix}
                : '';
            @suffix = split( /,/, $sfxes );
        }
        my $blog;
        my $blog_id;
        if ( $app->can('blog') && $app->blog ) {
            $blog    = $app->blog;
            $blog_id = $blog->id;
        }
        my $wwidth = $args->{wwidth} || 120;
        my $hwidth = $args->{hwidth} || 3;
        my $awidth = $args->{awidth} || 60;
        my $query
            = $use_param ? __param( $app, 'query' )
            : defined $args->{query} ? $args->{query}
            :                          '';
        $query = normalize( $query );
        my $operator  = $args->{operator}  || 'AND';
        my $separator = $args->{separator} || ' ';
        $separator = quotemeta($separator);
        #        return '' if ( (! $query ) || (! $casket ) );
        if ( __param( $app, 'no_query' ) || $args->{no_query} ) {
            return '' if !$casket;
        }
        elsif ( !$query || !$casket ) {
            return '';
        }
        my $offset
            = $use_param
                ? __param( $app, 'offset' )
                : defined $args->{offset}
                    ? $args->{offset}
                    : '';
        $offset = 1 unless ( $offset =~ /^(?:0|[1-9][0-9]*)$/ );
        $offset-- if $offset;
        my $limit
            = $use_param ? __param( $app, 'limit' )
            : defined $args->{limit} ? $args->{limit}
            :                          '';
        $limit = $plugin->get_config_value('default_res_limit')
            unless ( $limit =~ /^(?:0|[1-9][0-9]*)$/ );
        $limit ||= 20;
        my $last = $limit;
        $last = $offset + $last - 1;
        my $db = new Database();
        # open the database
        unless ( $db->open( $casket, 'Database::DBREADER' ) ) {
            return $app->error( $db->err_msg( $db->error() ) );
        }
        my $condition = new Condition();
        # set the search phrase to the search condition object
        $query =~ s/\s{1,}/ /g;
        $query =~ s/$separator/ $operator /g;
        unless ( __param( $app, 'no_query' ) || $args->{no_query} ) {
            $condition->set_phrase($query);
        }
        my $tbid;
        if (@target) {
            my $count = MT::Blog->count(
                {   class          => [ 'website', 'blog' ],
                    id             => \@target,
                    exclude_search => 1
                }
            );
            my $c = '';
            for my $id (@target) {
                my $target_blog = MT::Blog->load( { id => $id } );
                next unless $target_blog;
                if ( $target_blog->has_column( 'is_members' ) && $target_blog->is_members ) {
                    if (!MT::App::CMS::SearchEstraier::_is_login(
                            $app, $target_blog, $plugin
                        )
                        )
                    {
                        next;
                    }
                }
                if ( $id =~ /^(?:0|[1-9][0-9]*)$/ ) {
                    if ( !$count ) {
                        $c .= " $id";
                    }
                    elsif ( $blog_id && $blog_id == $id ) {
                        $c .= " $id";
                    }
                    else {
                        if (   ($target_blog)
                            && ( !$target_blog->exclude_search ) )
                        {
                            $c .= " $id";
                        }
                    }
                }
            }
            __set_blog_id_condition( $condition, $c );
            $tbid = join( ',', @target ) if $c;
        }
        else {    # default case
            my @blogs = MT::Blog->load(
                {   class => [ 'website', 'blog' ],
                    exclude_search =>
                        [ { op => '!=', value => 1 }, \'is null' ],
                }
            );
            my $c = $blog_id ? " $blog_id" : '';
            for (@blogs) {
                if ( $_->has_column( 'is_members' ) && $_->is_members ) {
                    if (!MT::App::CMS::SearchEstraier::_is_login(
                            $app, $_, $plugin
                        )
                        )
                    {
                        next;
                    }
                }
                $c .= ' ' . $_->id;
            }
            __set_blog_id_condition( $condition, $c );
        }
        my $sfx;
        if (@suffix) {
            my $s = '';
            for my $ext (@suffix) {
                if ( $ext =~ /(html|pdf|xls|doc|ppt)$/i ) {
                    $s .= " $ext";
                }
            }
            $condition->add_attr( '@suffix STROREQ' . $s ) if $s;
            $sfx = join( ',', @suffix ) if $s;
        }
        my @arr = split( /\s/, $query );
        # get the result of search
        # my $separator = $args->{separator} || ',';
        # my $_add_attrs = $args->{add_attr};
        # my @add_attrs = split( /,/, $_add_attrs );
        # my $_add_conditions = $args->{add_condition};
        # my @add_conditions = split( /,/, $_add_conditions );
        # my $_add_queries = $args->{add_query};
        # my @add_queries = split( /,/, $_add_queries );

        my $add_attrs = $args->{add_attr};
        my @add_attrs = ref( $add_attrs ) eq 'ARRAY' ? @$add_attrs : $add_attrs;
        my $add_conditions = $args->{add_condition};
        my @add_conditions = ref( $add_conditions ) eq 'ARRAY' ? @$add_conditions : $add_conditions;
        my $add_queries = $args->{add_query};
        my @add_queries = ref( $add_queries ) eq 'ARRAY' ? @$add_queries : $add_queries;

        if (! @add_conditions ) {
            @add_conditions = ['STROREQ'];
        }
        my $attr = 0;
        for my $add_attr(@add_attrs) {
            # MT->log($add_attr);
            my $add_cond = $add_conditions[$attr];
            my $add_query = $add_queries[$attr] || __param( $app, $add_attr );
            if ( $add_query ) {
                $condition->add_attr( "$add_attr $add_cond $add_query" );
            }
            $attr++;
        }
        # $condition->add_attr( 'parent STROREQ test' );
        my $set_order = $args->{set_order};
        my $order_condition = $args->{order_condition};
        if ( $set_order && $order_condition ) {
            $condition->set_order( "$set_order $order_condition" );
        }
        $app->run_callbacks( 'pre_estraier_search', $app, \$condition );
        my $result = $db->search($condition);
        # for each document in the result
        my $dnum       = $result->doc_num();
        my $res        = '';
        my $counter    = 1;
        my $prevoffset = $offset - $limit + 1;
        $prevoffset = 1 if ( $prevoffset < 1 );
        my $nextoffset = $last + 2;
        $last = $dnum - 1 if ( $dnum <= $last );
        $ctx->{__stash}{dnum}    = $dnum;
        $vars->{__dnum__}        = $dnum;
        $vars->{__start__}       = $offset + 1;
        $vars->{__suffix__}      = $sfx;
        $vars->{__limit__}       = $limit;
        $vars->{__last__}        = $last + 1;
        $vars->{__nextoffset__}  = $nextoffset;
        $vars->{__prevoffset__}  = $prevoffset;
        $vars->{__query__}       = $query;
        $vars->{__target__}      = $tbid;
        $vars->{__qurey__}       = $query;
        $ctx->{__stash}{if_next} = 1 if ( $nextoffset <= $dnum );
        $ctx->{__stash}{if_prev} = 1 if ( $offset != 0 );
        $ctx->{__stash}{limit}   = $limit;
        $ctx->{__stash}{offset}  = $offset + 1;
        unless ( $offset >= $dnum ) {
            for my $i ( $offset .. $last ) {
                last if ( $dnum == $i );
                my $doc   = $db->get_doc( $result->get_doc_id($i), 0 );
                my $uri   = utf8_on( $doc->attr('@uri') );
                my $title = utf8_on( $doc->attr('@title') );
                my $cdate = utf8_on( $doc->attr('@cdate') );
                my $entry_blog_id = $doc->attr('@blog_id');
                my $entry_id      = $doc->attr('@entry_id');
                my $text          = utf8_on( $doc->cat_texts() );
                my $snippet       = utf8_on(
                    $doc->make_snippet( \@arr, $wwidth, $hwidth, $awidth ) );
                $snippet = _highlight( $snippet, @arr );
                $snippet .= '...' unless ( $text eq $snippet );
                local $vars->{__id__}          = $i;
                local $vars->{__cdate__}       = $cdate;
                local $ctx->{__stash}{title}   = $title;
                local $ctx->{__stash}{uri}     = $uri;
                local $ctx->{__stash}{cdate}   = $cdate;
                local $ctx->{__stash}{snippet} = $snippet;
                local $ctx->{__stash}{blog}    = $blog    if defined $blog;
                local $ctx->{__stash}{blog_id} = $blog_id if defined $blog;
                local $ctx->{__stash}{entry_blog_id} = $entry_blog_id
                    if defined $entry_blog_id;
                local $ctx->{__stash}{entry_id} = $entry_id
                    if defined $entry_id;
                local $ctx->{__stash}{estraier_doc} = $doc;
                local $vars->{__counter__} = $counter;
                my $out = $builder->build(
                    $ctx, $tokens,
                    {   %$cond,
                        lc('EstResultHeader') => $i == $offset,
                        lc('EstResultFooter') => $i == $last,
                    }
                );
                $res .= $out;
                $counter++;
            }
        }
        $db->close();
        unless ($res) {
            return $ctx->stash('builder')
                ->build( $ctx, $ctx->stash('tokens'), $cond );
        }
        return $res;
    }
}

sub _estraier_result {
    my ( $ctx, $args, $cond ) = @_;
    return __estraier_block( $ctx, $args, $cond, 1 );
}

sub _estraier_block {
    my ( $ctx, $args, $cond ) = @_;
    return __estraier_block( $ctx, $args, $cond );
}

sub _estraier_target {
    my ( $ctx, $args, $cond ) = @_;
    my $app     = MT->instance;
    my $tokens  = $ctx->stash('tokens');
    my $builder = $ctx->stash('builder');
    my $vars    = $ctx->{__stash}{vars} ||= {};
    my @target  = __param( $app, 'target' );
    if (@target) {
        my $res = '';
        for my $id (grep /^(?:0|[1-9][0-9]*)$/, @target) {
            local $vars->{__target__} = $id;
            my $out = $builder->build( $ctx, $tokens, $cond );
            $res .= $out;
        }
        return $res;
    }
    return '';
}

sub _estraier_suffix {
    my ( $ctx, $args, $cond ) = @_;
    my $app     = MT->instance;
    my $tokens  = $ctx->stash('tokens');
    my $builder = $ctx->stash('builder');
    my $vars    = $ctx->{__stash}{vars} ||= {};
    my @suffix  = __param( $app, 'suffix' );
    if (@suffix) {
        my $res = '';
        for my $ext (@suffix) {
            local $vars->{__suffix__} = $ext;
            my $out = $builder->build( $ctx, $tokens, $cond );
            $res .= $out;
        }
        return $res;
    }
    return '';
}

sub _estraier_blog_ctx {
    my ( $ctx, $args, $cond ) = @_;
    my $blog_id = $args->{blog_id};
    my $r    = MT::Request->instance;
    my $blog = $r->cache( 'entry_blog:' . $blog_id );
    unless ($blog) {
        $blog = MT::Blog->load($blog_id);
        $r->cache( 'entry_blog:' . $blog_id, $blog );
    }
    if ($blog) {
        my $tokens  = $ctx->stash('tokens');
        my $builder = $ctx->stash('builder');
        local $ctx->{__stash}{'blog'}    = $blog;
        local $ctx->{__stash}{'blog_id'} = $blog->id;
        my $out = $builder->build( $ctx, $tokens, $cond );
        return $out;
    }
    return '';
}

sub _estraier_entry_ctx {
    my ( $ctx, $args, $cond ) = @_;
    my $entry_id = $args->{entry_id};
    return '' unless ( defined($entry_id) && $entry_id =~ m/^\d+$/ );
    my $r     = MT::Request->instance;
    my $entry = $r->cache( 'entry:' . $entry_id );
    unless ($entry) {
        $entry = MT::Entry->load($entry_id);
        if ($entry) {
            if ( $entry->class eq 'page' ) {
                $entry = MT::Page->load($entry_id);
            }
            $r->cache( 'entry:' . $entry_id, $entry );
        }
    }
    if ($entry) {
        my $tokens  = $ctx->stash('tokens');
        my $builder = $ctx->stash('builder');
        local $ctx->{__stash}{'blog'}    = $entry->blog;
        local $ctx->{__stash}{'blog_id'} = $entry->blog_id;
        local $ctx->{__stash}{'entry'}   = $entry;
        local $ctx->{__stash}{'page'}    = $entry
            if ( $entry->class eq 'page' );
        my $out = $builder->build( $ctx, $tokens, $cond );
        return $out;
    }
    return '';
}

sub _estresult_pager {
    my ( $ctx, $args, $cond ) = @_;
    my $tokens  = $ctx->stash('tokens');
    my $builder = $ctx->stash('builder');
    my $vars    = $ctx->{__stash}{vars} ||= {};
    my $dnum    = $ctx->stash('dnum');
    my $limit   = $ctx->stash('limit');
    my $offset  = $ctx->stash('offset');
    my $pages   = ceil( $dnum / $limit );
    my $res     = '';
    for my $i ( 1 .. $pages ) {
        local $vars->{__counter__} = $i;
        local $vars->{__offset__}  = $i * $limit - $limit + 1;
        local $vars->{__current__} = 1 if $vars->{__offset__} == $offset;
        my $out = $builder->build(
            $ctx, $tokens,
            {   %$cond,
                lc('EstResultPagerHeader') => $i == 1,
                lc('EstResultPagerFooter') => $i == $pages,
            }
        );
        $res .= $out;
    }
    $res;
}

sub _hdlr_if_result_match {
    my ( $ctx, $args, $cond ) = @_;
    my $dnum = $ctx->stash('dnum');
    return 1 if $dnum;
    return 0;
}

sub _hdlr_if_result_next {
    my ( $ctx, $args, $cond ) = @_;
    my $if_next = $ctx->stash('if_next');
    return $if_next if $if_next;
    return 0;
}

sub _hdlr_if_result_prev {
    my ( $ctx, $args, $cond ) = @_;
    my $if_prev = $ctx->stash('if_prev');
    return $if_prev if $if_prev;
    return 0;
}

sub _estresult_count {
    my ( $ctx, $args, $cond ) = @_;
    my $dnum = $ctx->stash('dnum');
    return $dnum if $dnum;
    return 0;
}

sub _estresult_title {
    my ( $ctx, $args, $cond ) = @_;
    my $title = $ctx->stash('title');
    return $title if $title;
    return '';
}

sub _estresult_entry_blog_id {
    my ( $ctx, $args, $cond ) = @_;
    my $entry_blog_id = $ctx->stash('entry_blog_id');
    return $entry_blog_id if $entry_blog_id;
    return '';
}

sub _estresult_entry_id {
    my ( $ctx, $args, $cond ) = @_;
    my $entry_id = $ctx->stash('entry_id');
    return $entry_id if $entry_id;
    return '';
}

sub _estresult_url {
    my ( $ctx, $args, $cond ) = @_;
    my $uri = $ctx->stash('uri');
    return $uri if $uri;
    return '';
}

sub _estresult_date {
    my ( $ctx, $args, $cond ) = @_;
    my $cdate = $ctx->stash('cdate');
    if ($cdate) {
        $cdate =~ s/[^0-9]//g;
        $cdate =~ s/(^[0-9]{14}).*$/$1/;
        my $format = $args->{format};
        $cdate = format_ts( $format, $cdate );
        return $cdate;
    }
    return '';
}

sub _estresult_excerpt {
    my ( $ctx, $args, $cond ) = @_;
    my $snippet = $ctx->stash('snippet');
    return $snippet if $snippet;
    return '';
}

sub _estresult_attribute {
    my ( $ctx, $args, $cond ) = @_;
    my $attribute = $args->{ attribute }
        or return '';
    my $doc = $ctx->stash( 'estraier_doc' );
    my $res = utf8_on( $doc->attr( $attribute ) );
    return $res if $res;
    return '';
}

sub _estraier_script {
    return MT->config('EstraierScript') || 'mt-estraier.cgi';
}

sub _estdbpath {
    my $estdbpath = MT->config('EstcmdIndex');
    return $estdbpath if $estdbpath;
    return '';
}

sub _estcmdpath {
    return MT->config('EstcmdPath') || '/usr/local/bin/estcmd';
    # return $plugin->get_config_value( 'estcmdpath' );
}

sub _hdlr_pass_tokens {
    my ( $ctx, $args, $cond ) = @_;
    $ctx->stash('builder')->build( $ctx, $ctx->stash('tokens'), $cond );
}

sub _is_draft {
    my ( $text, $arg, $ctx ) = @_;
    $text =~ s/<script.{1,}?<\/script>//sg;
    $text =~ s/<!--.*?-->//sg;
    $text =~ s/<img[^>]*?alt=*["']([^"'>]*)["'][^>]*?>/$1/gi;
    $text =~ s/<[^>]*>//g;
    $text =~ s/["\n|\t]+//g; # FIXME? s/["\n\t]+//g
    $text = normalize( $text );
    return decode_html($text);
}

sub _tag_highlight {
    my ( $text, $arg, $ctx ) = @_;
    my $app = MT->instance;
    my $query = __param( $app, 'query' ) || '';
    $query = normalize( $query );
    $query =~ s/^\s+//;
    $query =~ s/\s+$//;
    my @arr = split( /\s+/, $query );
    my $new_text = $text;
    for my $q (@arr) {
        my $qq = quotemeta($q);
        $new_text =~ s!($qq)!<strong>$1</strong>!gi;
    }
    return $new_text;
}

sub _highlight {
    my ( $snippet, @arr ) = @_;
    for my $query (@arr) {
        my $q = quotemeta($query);
        $snippet =~ s!($q)\t$q!<strong>$1</strong>!gi;
    }
    return $snippet;
}

1;
