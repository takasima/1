package ImportExportObject::Util;
use strict;

use lib qw( addons/Commercial.pack/lib addons/PowerCMS.pack/lib );
use PowerCMS::Util qw( current_ts csv_new get_all_blogs association_link );

sub can_im_export {
    eval {
        require Archive::Zip;
    };
    return $@ ? 0 : 1;
}

sub import_author_from_csv {
    my ( $csv_path ) = @_;
    
    my $app = MT->instance();
    my $plugin = MT->component( 'UploadUser' );
    
    local *IN;
    open IN, $csv_path;
    my @list = <IN>; close IN;
    my $ts = current_ts();
    my $encoding = 'utf8';
    my $csv = csv_new() || return $app->error( $plugin->translate( 'Neither Text::CSV_XS nor Text::CSV is available.' ) );
    require MT::Blog;
    my $blogs = get_all_blogs();
    my $i = 0;
    my $j = 0;
    my @column_names;
    my $key_number;
    for my $line ( @list ) {
        chomp $line;
        my $guess_encoding = MT::I18N::guess_encoding( $line );
        unless ( $guess_encoding =~ /^utf-?8$/i ) {
            $line = MT::I18N::encode_text( $line, 'cp932', $encoding );
        }
        next unless $csv->parse( $line );
        my @columns = $csv->fields;
        if (! $i ) {
            for my $column ( @columns ) {
                if ( $column eq 'name' ) {
                    $key_number = $j;
                }
                push ( @column_names, $column );
                $j++;
            }
            $i = 1; next;
        }
        my $name = $columns[ $key_number ];
        next unless $name;
        my $count = scalar @columns;
        my $obj = MT::Author->get_by_key( { name => $name } );
        my $k = 0;
        my @assoc;
        my $password;
        for my $value ( @columns ) {
            if ( my $cname = $column_names[ $k ] ) {
                if ( $cname eq 'password' ) {
                    $password = $value;
                } else {
                    if ( $cname =~ /_on$/ ) {
                        if (! $value ) {
                            $value = $ts;
                        } else {
                            $value =~ s/^\t//;
                        }
                    }
                    if ( $obj->has_column( $cname ) ) {
                        $obj->$cname( $value );
                    }
                }
            } else {
                push @assoc, $value;
            }
            $k++;
        }
        next unless $obj->nickname;
        next unless $obj->email;
        my $orig_password;
#        next if ( (! $obj->id ) && (! $password ) );
        if ( $obj->id && $obj->password ) {
            if (! $password ) {
                $orig_password = 1;
            }
        }
        if ( (! $orig_password ) && (! $password ) ) {
            next;
        }
        $obj->preferred_language( 'ja' ) if (! $obj->preferred_language );
        $obj->type( 1 ) if (! $obj->type );
        $obj->auth_type( 'MT' ) if (! $obj->auth_type );
        if (! $orig_password ) {
            $obj->set_password( $password ) if $password;
        }
        if (! $obj->basename ) {
            my $basename = MT::Util::make_unique_author_basename( $obj );
            $obj->basename( $basename );
        }
        $obj->save or die $obj->errstr;
        for my $association ( @assoc ) {
            next unless $association;
            my @as = split ( /_/, $association );
            my $blog_id;
            if ( scalar @as == 2 ) {
                $blog_id = $as[0];
                $association = $as[1];
            }
            if ( ( $blog_id eq '0' ) && ( $association eq $app->translate( 'System Administrator' ) ) ) {
                my $permission = MT::Permission->get_by_key( { author_id => $obj->id, blog_id => 0 } );
                $permission->created_on( $ts );
                if ( MT->version_number >= 5 ) {
                    $permission->permissions( "'administer','create_blog','create_website','edit_templates','manage_plugins','view_log','access_cms'" );
                } else {
                    $permission->permissions( "'administer','create_blog','view_log','manage_plugins','edit_templates'" );
                }
                $permission->save or die $permission->errstr;
            } else {
                my $role = MT::Role->load( { name => $association } );
                if ( $role ) {
                    if ( $blog_id ) {
                        my @target = grep { $_->id == $blog_id } @$blogs;
                        my $blog = $target[ 0 ];
                        if ( $blog ) {
                            association_link( $app, $obj, $role, $blog );
                        }
                    } else {
                        for my $blog ( @$blogs ) {
                            association_link( $app, $obj, $role, $blog );
                        }
                    }
                }
            }
        }
        MT->run_callbacks( 'MT::App::CMS::import_author_from_csv', $app, $obj, \@column_names, \@columns );
        $i++;
    }
    
    $i;
}

1;