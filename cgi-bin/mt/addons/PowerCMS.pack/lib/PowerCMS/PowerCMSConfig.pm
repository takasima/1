package PowerCMS::PowerCMSConfig;
use strict;
use base qw( MT::Object );

use PowerCMS::Util qw( set_powercms_config get_powercms_config );

__PACKAGE__->install_properties(
    {   column_defs => {
            'id'   => 'integer not null auto_increment',
            'data' => 'blob',
            'restored' => 'integer',
        },
        primary_key => 'id',
        datasource  => 'pcmsconfig',
    }
);

sub class_label {
    'PowerCMS ' . MT->translate("Configuration");
}

sub class_label_plural {
    'PowerCMS ' . MT->translate("Configuration");
}

sub restore_blob {
    my $obj = shift;
    my ( $column_name, $data, $objects ) = @_;
    if ( ( ref $data ) eq 'REF' ) {
        my $hash = $$data;
        if ( ( ref $hash ) eq 'HASH' ) {
            for my $plugin ( keys %$hash ) {
                my $values = $hash->{ $plugin };
                for my $key ( keys %$values ) {
                    next if defined get_powercms_config( $plugin, $key ); # already exists, so skip
#                    next if $key eq 'get_weblog_ids_cache';
                    if ( $key eq 'get_weblog_ids_cache' ) {
                        set_powercms_config( $plugin, $key, {} );
                    } else {
                        set_powercms_config( $plugin, $key, $values->{ $key } );
                    }
                }
            }
        }
    }
1;
}

# following for datasource, 
# original is from MT::Object::to_xml written in MT::BackupRestore.
sub to_xml {
    my $obj = shift;
    my ( $namespace, $metacolumns ) = @_;

    my $coldefs  = $obj->column_defs;
    my $colnames = $obj->column_names;
    my $xml;

    my $elem = $obj->datasource;
    
    # PATCH
    $elem = 'powercmsconfig';
    # /PATCH

    unless ( UNIVERSAL::isa( $obj, 'MT::Log' ) ) {
        if ( $obj->properties
            && ( my $ccol = $obj->properties->{class_column} ) )
        {
            if ( my $class = $obj->$ccol ) {

                # use class_type value instead if
                # the value resolves to a Perl package
                $elem = $class
                    if defined( MT->model($class) );
            }
        }
    }

    $xml = '<' . $elem;
    $xml .= " xmlns='$namespace'" if defined($namespace) && $namespace;

    my ( @elements, @blobs, @meta );
    for my $name (@$colnames) {
        if ($obj->column($name)
            || ( defined( $obj->column($name) )
                && ( '0' eq $obj->column($name) ) )
            )
        {
            if ( ( $obj->properties->{meta_column} || '' ) eq $name ) {
                push @meta, $name;
                next;
            }
            elsif ( $obj->_is_element( $coldefs->{$name} ) ) {
                push @elements, $name;
                next;
            }
            elsif ( 'blob' eq $coldefs->{$name}->{type} ) {
                push @blobs, $name;
                next;
            }
            $xml .= " $name='"
                . MT::Util::encode_xml( $obj->column($name), 1 ) . "'";
        }
    }
    my ( @meta_elements, @meta_blobs );
    if ( defined($metacolumns) && @$metacolumns ) {
        foreach my $metacolumn (@$metacolumns) {
            my $name = $metacolumn->{name};
            if ( $obj->$name
                || ( defined( $obj->$name ) && ( '0' eq $obj->$name ) ) )
            {
                if ( 'vclob' eq $metacolumn->{type} ) {
                    push @meta_elements, $name;
                }
                elsif ( 'vblob' eq $metacolumn->{type} ) {
                    push @meta_blobs, $name;
                }
                else {
                    $xml .= " $name='"
                        . MT::Util::encode_xml( $obj->$name, 1 ) . "'";
                }
            }
        }
    }
#    $xml .= '>';
    $xml .= " restored='1'>";
    $xml .= "<$_>" . MT::Util::encode_xml( $obj->column($_), 1 ) . "</$_>"
        foreach @elements;
    require MIME::Base64;
    foreach my $blob_col (@blobs) {
        my $val = $obj->column($blob_col);
        if ( substr( $val, 0, 4 ) eq 'SERG' ) {
            $xml
                .= "<$blob_col>"
                . MIME::Base64::encode_base64( $val, '' )
                . "</$blob_col>";
        }
        else {
            $xml .= "<$blob_col>"
                . MIME::Base64::encode_base64(
                Encode::encode( MT->config->PublishCharset, $val ), '' )
                . "</$blob_col>";
        }
    }
    foreach my $meta_col (@meta) {
        my $hashref = $obj->$meta_col;
        $xml .= "<$meta_col>"
            . MIME::Base64::encode_base64(
            MT::Serialize->serialize( \$hashref ), '' )
            . "</$meta_col>";
    }
    $xml .= "<$_>" . MT::Util::encode_xml( $obj->$_, 1 ) . "</$_>"
        foreach @meta_elements;
    foreach my $vblob_col (@meta_blobs) {
        my $vblob = $obj->$vblob_col;
        $xml .= "<$vblob_col>"
            . MIME::Base64::encode_base64(
            MT::Serialize->serialize( \$vblob ), '' )
            . "</$vblob_col>";
    }
    $xml .= '</' . $elem . '>';
    $xml;
}

1;