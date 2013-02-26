package ExtFields::Util;
use strict;

use lib qw( addons/PowerCMS.pack/lib );
use PowerCMS::Util qw( is_user_can utf8_off );

sub can_extfields {
    my ( $blog, $author, $class ) = @_;
    return 0 unless $blog;
    return 0 unless $author;
    return 0 unless $class;
    my $plugin = MT->component( 'ExtFields' );
    my $permission = $class eq 'entry'
                                ? $plugin->get_config_value( 'entry_permission' )
                                : $plugin->get_config_value( 'page_permission' );
    my $can_extfields = 0;
    if ( $author->is_superuser ) {
        $can_extfields = 1;
    } elsif ( is_user_can( $blog, $author, $permission ) ) {
        $can_extfields = 1;
    }
    return $can_extfields;
}

sub can_upload {
    my ( $file, @ext_check ) = @_;
    my @suffix = split( /\./, $file );
    my $ext = pop( @suffix );
    $ext = lc( $ext );
    for my $check ( @ext_check ) {
        if ( $ext eq $check ) {
            return 1;
            last;
        }
    }
    return 0;
}

sub amp_escape {
    my ( $text ) = @_;
    $text =~ s/&/&amp;/g;
    return $text;
}

sub get_field {
    my ( $entry, $label ) = @_;
    return unless $entry;
    return unless $label;
    require Digest::MD5;
    require MT::Request;
    my $r = MT::Request->instance;
    my $entry_id = $entry->id;
    my $hash = Digest::MD5::md5_hex( utf8_off( $label ) );
    my $stash_key = 'extfield-' . $entry_id . '-' . $hash;
    my $extfield;
    if ( $extfield = $r->cache( $stash_key ) ) {
        return $extfield;
    }
    $extfield = MT->model( 'extfields' )->load( { entry_id => $entry_id,
                                                  status => 1,
                                                  label => $label,
                                                } 
                                              );
    $r->cache( $stash_key, $extfield );
    return $extfield;
}

sub remove_last_slash {
    my ( $str ) = @_;
    return unless $str;
    $str =~ s/(^.*)\/$/$1/;
    return $str;
}

sub format_text {
    my ( $textformat, $text ) = @_;
    return $text unless $textformat;
    my $formatted_text;
    if ( $textformat == 2 ) {
        $formatted_text = MT::Util::html_text_transform( $text );
    } elsif ( $textformat == 3 or $textformat == 4 or $textformat == 5 or $textformat == 6 ) {
        my @lines = split(/\r\n|\r|\n/, $text, -1);
        @lines = grep( !/^$/, @lines );
        if ( $#lines == -1 ) {
            $formatted_text = '';
        } else {
            $formatted_text = '<table border="1">'."\n";
            if ( $textformat == 4 or $textformat == 6 ) {
                $formatted_text .= '<tr>';
                my @values = split( /\t/, shift(@lines), -1);
                foreach ( @values ) {
                    $formatted_text .= '<th>' . $_ . '</th>';
                }
                $formatted_text .= '</tr>' . "\n";
            }
            foreach ( @lines ) {
                $formatted_text .= '<tr>';
                my @values = split( /\t/, $_, -1);
                if ( $textformat == 5 or $textformat == 6 ) {
                    $formatted_text .= '<th>' . shift( @values ) . '</th>';
                }
                foreach ( @values ) {
                    $formatted_text .= '<td>' . $_ . '</td>';
                }
                $formatted_text .= '</tr>' . "\n";
            }
            $formatted_text .= '</table>' . "\n";
        }
    } elsif ( $textformat == 7 or $textformat == 8 ) {
        my @lines = split( /\r\n|\r|\n/, $text, -1 );
        @lines = grep( !/^$/, @lines );
        if ( $#lines == -1 ) {
            $formatted_text = '';
        } else {
            if ( $textformat == 7 ) {
                $formatted_text = '<ul>' . "\n";
            } else {
                $formatted_text = '<ol>' . "\n";
            }
            foreach ( @lines ) {
                $formatted_text .= '<li>' . $_ . '</li>'."\n";
            }
            if ( $textformat == 7 ) {
                $formatted_text .= '</ul>' . "\n";
            } else {
                $formatted_text .= '</ol>' . "\n";
            }
        }
    } elsif ( $textformat == 11 or $textformat == 12 or $textformat == 13 ) {
        my $text_filter_name;
        if ( $textformat == 11 ) {
            $text_filter_name = 'markdown';
        } elsif ( $textformat == 12 ) {
            $text_filter_name = 'markdown_with_smartypants';
        } elsif ( $textformat == 13 ) {
            $text_filter_name = 'textile_2';
        }
        my @filters;
        push @filters, $text_filter_name;
        $formatted_text = MT->apply_text_filters($text, \@filters);
    } else {
        $formatted_text = $text;
    }
    return $formatted_text;
}

1;