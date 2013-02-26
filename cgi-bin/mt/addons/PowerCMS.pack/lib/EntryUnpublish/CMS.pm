package EntryUnpublish::CMS;
use strict;

use PowerCMS::Util qw( current_user is_user_can );
use MT::Util qw( offset_time_list );
use EntryUnpublish::Util;

sub _mode_entry_unpublish {
    my $app = shift;
    $app->validate_magic or
        return $app->trans_error( 'Permission denied.' );
    my $plugin = MT->component( 'PowerCMS' );
    my @titles;
    if ( my $blog = $app->blog ) {
        unless ( is_user_can( $app->blog, $app->user, 'publish_post' ) ) {
            return $app->trans_error( 'Permission denied.' );
        }
        @titles = EntryUnpublish::Util::change_status( $app, $blog );
    } else {
        my $user = current_user( $app );
        unless ( $user->is_superuser ) {
            return $app->trans_error( 'Permission denied.' );
        }
        my @blogs = MT::Blog->load( { class => '*' } );
        for my $blog ( @blogs ) {
            push( @titles, EntryUnpublish::Util::change_status( $app, $blog ) );
        }
    }
    my %param;
    $param{ page_title } = $plugin->translate( 'Unpublish Entry' );
    $param{ changed_entry } = $plugin->translate( 'Unpublished Entry' );
    my @tmpl_loop; my $odd = 1;
    for my $title ( @titles ) {
        push ( @tmpl_loop, { title => $title,
                             odd => $odd,
                           }
             );
        if ( $odd == 1 ) { $odd = 0 } else { $odd = 1 };
    }
    $param{ tmpl_loop } = \@tmpl_loop;
    $app->{ plugin_template_path } = File::Spec->catdir( $plugin->path, 'tmpl' );
    if ( @titles ) {
        $param{ titles } = 1;
        $param{ msg } = $plugin->translate( 'Entry status changed &amp; Blog has been rebuilt.' );
    } else {
        $param{ msg } = $plugin->translate( 'No entry to change status.' );
    }
    my $tmpl = 'entryunpublish_unpublished.tmpl';
    return $app->build_page( $tmpl, \%param );
}

1;