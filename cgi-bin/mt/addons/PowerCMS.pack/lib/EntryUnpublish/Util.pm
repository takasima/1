package EntryUnpublish::Util;
use strict;

use MT::Util qw( offset_time_list );

# PATCH
no warnings 'redefine';
require MT::Template::Tags::Category;
*MT::Template::Tags::Category::_hdlr_category_count = sub {
    my ( $ctx, $args, $cond ) = @_;
    my $cat = ( $ctx->stash('category') || $ctx->stash('archive_category') )
        or return $ctx->error(
        MT->translate(
            "You used an [_1] tag outside of the proper context.",
            '<$MT' . $ctx->stash('tag') . '$>'
        )
        );
    my $count = $ctx->stash('category_count');
    $cat->clear_cache( 'blog_id' => $cat->blog_id ); # PATCH
    $count = $cat->entry_count unless defined $count;
    $cat->clear_cache( 'blog_id' => $cat->blog_id ); # PATCH
    return $ctx->count_format( $count, $args );
};

sub change_status {
    my ( $app, $blog ) = @_;
    return unless $blog;
    my $plugin = MT->component( 'PowerCMS' );
    my $blog_id = $blog->id;
    my @tl = &offset_time_list( time, $blog );
    my $ts = sprintf "%04d%02d%02d%02d%02d%02d", $tl[ 5 ] + 1900, $tl[ 4 ] + 1, @tl[ 3, 2, 1, 0 ];
    my @entries = MT::Entry->load( { blog_id =>  $blog_id,
                                     class =>  '*',
                                     unpublished => 1,
                                     status => MT::Entry::RELEASE(),
                                   }, {
                                     'sort' => 'unpublished_on',
                                     start_val => $ts,
                                     direction => 'descend',
                                   }
                                 );
    my @titles; my $pub; my $rebuild = 0;
    require MT::WeblogPublisher;
    $pub = MT::WeblogPublisher->new();
    my $fmgr = $blog->file_mgr;
    for my $entry ( @entries ) {
        $pub->start_time( time );
        # my $orig_entry = $entry;
        $entry->status( MT::Entry::HOLD() );
        if ( $entry->title ) {
            push ( @titles, $entry->title );
        }
        $entry->save
            or $app->error( $plugin->translate( 'Change status of entry failed: [_1]', $entry->errstr ) );
# comment out because of patch 'MT::Template::Tags::Category::_hdlr_category_count'
#         if ( my $category = $entry->category ) {
#             $category->cache_property( 'entry_count', undef, undef );
#         }
        MT->run_callbacks( 'scheduled_post_unpublished', $app, $entry );
        $pub->rebuild_entry( Entry => $entry,
                             Blog => $entry->blog,
                             BuildDependencies => 1,
                           );
#         $pub->rebuild_deleted_entry( Entry => $entry,
#                                      Blog => $entry->blog,
#                                    );
        if ( my $categories = $entry->categories ) {
            for my $category ( @$categories ) {
                unless ( $category->entry_count ) {
                    my @finfo = MT->model( 'fileinfo' )->load(
                        { archive_type => 'Category',
                          blog_id => $blog_id,
                          category_id => $category->id,
                        }
                    );
                    for my $f ( @finfo ) {
                        $fmgr->delete( $f->file_path );
                        $f->remove;
                    }
                }
            }
        }
# FIXME
#         my $archive_types = MT->registry( 'archive_types' );
#         for my $at ( keys %$archive_types ) {
        my @archive_types = ( 'Monthly', 'Daily', 'Weekly', 'Yearly' );
        for my $at ( @archive_types ) {
            my $archiver = $pub->archiver( $at );
            unless ( $archiver->archive_entries_count( $entry->blog, $at, $entry ) ) {
                if ( $archiver->date_based() && $archiver->can('date_range') ) {
                    my ( $start, $end ) = $archiver->date_range( $entry->authored_on );
                    if ( $start ) {
                        my @finfo = MT->model( 'fileinfo' )->load(
                            { archive_type => $at,
                              blog_id => $blog_id,
                              ( $start ? ( startdate => $start ) : () ),
                            }
                        );
                        for my $f ( @finfo ) {
                            $fmgr->delete( $f->file_path );
                            $f->remove;
                        }
                    }
                }
            }
        }
        MT->instance->request( '__cached_maps', {} );
        MT->instance->request( '__published:' . $entry->blog_id, {} );
        $rebuild++;
        # FIXME: do log?
        if ( MT->config->MultiBlogTriggerAtUnpublished ) {
            if ( my $multiblog = MT->component( 'MultiBlog' ) ) {
                $entry->status( MT::Entry::RELEASE() );
                $multiblog->runner( 'post_entry_save', undef, $app, $entry );
            }
        }
    }
    if ( $rebuild ) {
        $pub->start_time( time );
        $pub->rebuild_indexes( Blog => $blog )
            or $app->error( $plugin->translate( 'Rebuild error: [_1]', $pub->errstr ) );
    }
    for my $entry ( @entries ) {
        my $class = $entry->class;
        my $at = $class eq 'page' ? 'Page' : 'Individual';
        $pub->remove_entry_archive_file( Entry => $entry,
                                         ArchiveType => $at,
                                       );
    }
    return @titles;
}

1;