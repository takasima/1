package ContactForm::ContactFormOrder;
use strict;
use base qw( MT::Object );

my $datasource = 'contactformorder';
if ( lc( MT->config( 'ObjectDriver' ) ) =~ /oracle/ ) {
    $datasource = 'cfmo';
}

__PACKAGE__->install_properties( {
    column_defs => {
        'id'          => 'integer not null auto_increment',
        'order'       => 'integer',
        'group_id'    => 'integer',
        'contactform_id' => 'integer',
        'blog_id'     => 'integer',
    },
    indexes => {
        'order'       => 1,
        'group_id'    => 1,
        'contactform_id' => 1,
        'blog_id'     => 1,
    },
    child_of    => [ 'ContactForm::ContactFormGroup', 'MT::Blog', 'MT::Website' ],
    datasource  => $datasource,
    primary_key => 'id',
} );

sub class_label {
    my $plugin = MT->component( 'ContactForm' );
    return $plugin->translate( 'Contact Form Order' );
}

sub class_label_plural {
    my $plugin = MT->component( 'ContactForm' );
    return $plugin->translate( 'Contact Form Order' );
}

sub parents {
    my $obj = shift;
    {   contactform_id => MT->model( 'contactform' ),
        group_id => MT->model( 'contactformgroup' ),
    };
}

sub backup_terms_args {
    my $class = shift;
    my ( $blog_ids ) = @_;
    if ( defined( $blog_ids ) && scalar( @$blog_ids ) ) {
        return {
            terms   => undef,
            args    => {
                'join' => MT->model( 'contactformgroup' )->join_on(
                    undef,
                    {   id => \"= ${datasource}_group_id",
                        blog_id => $blog_ids,
                    }, {
                        unique => 1,
                    }
                )
            }
        };
    }
    return {
        terms   => undef,
        args    => {
            'join' => MT->model( 'contactformgroup' )->join_on(
                undef,
                {   id => \"= ${datasource}_group_id",
                }, {
                    unique => 1,
                }
            )
        }
    };
#    return { terms => undef, args => undef };
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
    $elem = 'contactformorder';
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
    $xml .= '>';
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
