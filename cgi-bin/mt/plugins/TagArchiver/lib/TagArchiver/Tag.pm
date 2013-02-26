package TagArchiver::Tag;
use strict;
use base qw( MT::ArchiveType::Date );
use MT::Request;
use MT::Entry;
use MT::Tag;

sub name {
    return 'Tag';
}

sub archive_label {
    MT->translate( 'Tag' );
}

sub default_archive_templates {
    return [
        {
            label    => 'tag/tag_id.html',
            template => 'tag/tag_<mt:var name="tag_id">.html',
            default  => 1,
        },
    ];
}

sub date_range {
    ( '18000101000000', '20380118235959' );
}

sub archive_file {
    my $app = MT->instance;
    return 0 if ( ref $app ne 'MT::App::CMS' );
    my $type = $app->param( 'type' );
    return 0 if ( $app->mode ne 'rebuild' );
    return 0 if ( $type =~ /^entry\-[0-9]{1,}$/ );
    my $r = MT::Request->instance;
    my $rebuild_tag = $r->cache( 'rebuild_tag' );
    return if $rebuild_tag;
    my $blog = $app->blog;
    return unless $blog;
    my $epr = MT->config->EntriesPerRebuild || 40;
    my $total = $app->param( 'total' );
    my $offset = $app->param( 'offset' ) || 0;
    my $current = _ceil ( $offset / $epr );
    require MT::ObjectTag;
    my $tag_count = MT::Tag->count( { is_private => 0 },
                                    { join => MT::ObjectTag->join_on( 'tag_id',
                                    { blog_id => $blog->id, object_datasource => 'entry', },
                                    { unique => 1, } ) } );
    my $request = _ceil( $total / $epr );
    my $rebuild = 1;
    if ( $tag_count > $request ) {
        $rebuild = _ceil( $tag_count / $request );
    }
    my $tag_offset = $current * $rebuild;
    my @tags = MT::Tag->load( { is_private => 0 },
                              { offset => $tag_offset, limit => $rebuild, sort => 'id',
                                join => MT::ObjectTag->join_on( 'tag_id',
                                              { blog_id => $blog->id, object_datasource => 'entry', },
                                              { unique => 1, } ) } );
    if ( scalar @tags ) {
        require TagArchiver::Plugin;
        TagArchiver::Plugin::_rebuild_tag_archives( $blog, \@tags );
    }
    $r->cache( 'rebuild_tag', 1 );
    return 0;
}

sub archive_group_iter {

}

sub archive_group_entries {

}

sub archive_entries_count {
    return 0;
}

sub _ceil {
    my $var = shift;
    my $a = 0;
    $a = 1 if ( $var > 0 and $var != int( $var ) );
    return int( $var + $a );
}

1;
