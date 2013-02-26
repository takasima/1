package EntryUnpublish::Plugin;
use strict;

use lib qw(addons/PowerCMS.pack/lib);
use PowerCMS::Util qw( is_power_edit is_cms );
use MT::Util qw( offset_time_list );

sub _cb_tp_preview_strip {
    my ( $cb, $app, $param, $tmpl ) = @_;
    for my $key ( $app->param ) {
        if ( $key =~ /^unpublished_on/ ) {
            my $input = {
                'data_name' => $key,
                'data_value' => $app->param( $key ),
            };
            push( @{ $param->{ 'entry_loop' } }, $input );
        }
    }
}

sub _cb_cms_pre_save_entry {
    my ( $cb, $app, $obj, $original ) = @_;
    return 1 if is_power_edit( $app );
    return 1 unless is_cms( $app );
    my $plugin = MT->component( 'PowerCMS' );
    my $unpublished_on_date = $app->param( 'unpublished_on_date' );
    my $unpublished_on_time = $app->param( 'unpublished_on_time' );
    my $unpublished_on = $unpublished_on_date . ' ' . $unpublished_on_time; # FIXME: has possible to occur perl warnings.
    # following is check unpublished on, from Entry.pm
    my %param = ();
    unless (
        $unpublished_on =~ m!^(\d{4})-(\d{1,2})-(\d{1,2})\s+(\d{1,2}):(\d{1,2})(?::(\d{1,2}))?$! )
    {
        $param{ error } = $plugin->translate(
"Invalid date '[_1]'; unpublished on dates must be in the format YYYY-MM-DD HH:MM:SS.",
$unpublished_on
        );
    }
    my $s = $6 || 0;
        $param{ error } = $plugin->translate(
            "Invalid date '[_1]'; unpublished on dates should be real dates.",
            $unpublished_on
      )
      if (
           $s > 59
        || $s < 0
        || $5 > 59
        || $5 < 0
        || $4 > 23
        || $4 < 0
        || $2 > 12
        || $2 < 1
        || $3 < 1
        || ( MT::Util::days_in( $2, $1 ) < $3
            && ! MT::Util::leap_day( $0, $1, $2 ) )
      );
    $param{ return_args } = $app->param( 'return_args' );
    return $app->forward( 'view', \%param ) if $param{ error };
    if ( $unpublished_on ) {
        $unpublished_on =~ s/\D//g;
        $obj->unpublished_on( $unpublished_on );
    }
    return 1;
}

sub _cb_tp_edit_entry {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $plugin = MT->component( 'PowerCMS' );
    if ( my $pointer = $tmpl->getElementById( 'authored_on' ) ) {
        my $unpublished_cb = '<input type="checkbox" name="unpublished" value="1" <mt:if name="unpublished">checked="checked"</mt:if> /> ' . $plugin->translate( 'Unpublish' );
        my $nodeset = $tmpl->createElement( 'app:setting', { id => 'unpublished_on',
                                                             label => $unpublished_cb,
                                                             label_class => 'top-label',
                                                             help_page => 'entries',
                                                             help_section => 'date',
                                                             required => 0,
                                                           }
                                          );
        my $innerHTML = <<'MTML'; # FIXME: TODO: Why cannot set style? > Fixed.
<style type="text/css">
    div#entry-publishing-widget div#unpublished_on-field {
        margin-top: 15px;
    }
</style>
<div class="date-time-fields">
    <input type="text" id="unpublished-on" class="text date text-date" name="unpublished_on_date" value="<$mt:var name="unpublished_on_date" escape="html"$>" /> @ <input type="text" class="post-time" name="unpublished_on_time" value="<$mt:var name="unpublished_on_time" escape="html"$>" />
    <input type="hidden" name="unpublished" value="0" />
</div>
MTML
        $nodeset->innerHTML( $innerHTML );
        $tmpl->insertAfter( $nodeset, $pointer );
    }
    my $id = $app->param( 'id' );
    if ( $app->param( 'reedit' ) ) { # FIXME: When can I get parameta 'reedit'? > Fixed.
        for my $key ( $app->param ) {
            if ( $key =~ /^unpublished_/ ) {
                $param->{ $key } = $app->param( $key );
            }
        }
    } else {
        my $set_unpublished_on;
        unless ( $app->param( 'duplicate' ) ) {
            if ( $id ) {
                my $entry = MT::Entry->load( { id => $id } );
                if ( defined $entry ) {
                    if ( my $unpublished_on = $entry->unpublished_on ) {
                        my $unpublished_on_date = substr( $unpublished_on, 0, 4 ) . '-' . substr( $unpublished_on, 4, 2 ) . '-' . substr( $unpublished_on, 6, 2 );
                        my $unpublished_on_time = substr( $unpublished_on, 8, 2 ) . ':' . substr( $unpublished_on, 10, 2 ) . ':' . substr( $unpublished_on, 12, 2 );
                        $param->{ 'unpublished_on_date' } = $unpublished_on_date;
                        $param->{ 'unpublished_on_time' } = $unpublished_on_time;
                        $set_unpublished_on = 1;
                    }
                }
            }
        }
        unless ( $set_unpublished_on ) {
            my @tl = &offset_time_list( time, $app->blog );
            $param->{ unpublished_on_date } = sprintf( '%04d-%02d-%02d', $tl[ 5 ] + 1900, $tl[ 4 ] + 1, $tl[ 3 ] );
            $param->{ unpublished_on_time } = sprintf( '%02d:%02d:%02d', $tl[ 2 ], $tl[ 1 ], $tl[ 0 ] );
        }
    }
}

1;
