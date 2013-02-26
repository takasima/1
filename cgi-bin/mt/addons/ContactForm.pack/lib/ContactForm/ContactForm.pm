package ContactForm::ContactForm;
use strict;
use MT::Blog;
use MT::Author;
use MT::Request;
use MT::Log;
use MT::Tag;
use MT::Util qw( trim first_n_words dirify );
use MT::I18N qw( const );
use ContactForm::Util qw( is_cms current_ts valid_ts
                          read_from_file plugin_template_path utf8_on );
use ContactForm::ContactFormGroup;
use ContactForm::ContactFormOrder;
use base qw( MT::Object );

my $datasource = 'contactform';
if ( lc( MT->config( 'ObjectDriver' ) ) =~ /oracle/ ) {
    $datasource = 'cfm';
}

__PACKAGE__->install_properties( {
    column_defs => {
        'id'            => 'integer not null auto_increment',
        'blog_id'       => 'integer',
        'author_id'     => 'integer',
        'name'          => 'string(255)',
        'basename'      => 'string(255)',
        'type'          => 'string(25)',
                                        # text
                                        # textarea
                                        # checkbox
                                        # select
                                        # radio
                                        # checkbox-multiple
                                        # select-multiple
                                        # url
                                        # email
                                        # date
                                        # tel
                                        # zip-code
        'mtml_id'       => 'string(25)',
        'mtml'          => 'text',
        'options'       => 'text',
        'default'       => 'string(255)',
        'description'   => 'text',
        'required'      => 'boolean',
        'validate'      => 'boolean',
        'normalize'     => 'boolean',
        'editor_select' => 'boolean',
        'created_on'    => 'datetime',
        'modified_on'   => 'datetime',
        'status'        => 'integer',
        'class'         => 'string(25)',
        'show_fields'   => 'string meta',
        'size'          => 'integer',
        'max_length'    => 'integer',
        'check_length'  => 'boolean',
        'count_multibyte' => 'boolean',
    },
    indexes => {
        'author_id'     => 1,
        'name'          => 1,
        'basename'      => 1,
        'created_on'    => 1,
        'type'          => 1,
        'modified_on'   => 1,
        'status'        => 1,
    },
    child_of    => [ 'MT::Blog', 'MT::Website' ],
    datasource  => $datasource,
    primary_key => 'id',
    class_type  => 'contactform',
    meta        => 1,
} );

sub class_label {
    my $plugin = MT->component( 'ContactForm' );
    return $plugin->translate( 'Form Element' );
}

sub class_label_plural {
    my $plugin = MT->component( 'ContactForm' );
    return $plugin->translate( 'Form Elements' );
}

sub save {
    my $obj = shift;
    require ContactForm::Plugin;
    my $app = MT->instance();
    my $plugin = MT->component( 'ContactForm' );
    my $original;
    my $is_new;
    my $r = MT::Request->instance;
    $obj->blog_id( 0 );
    if ( is_cms( $app ) ) {
        if ( $obj->id ) {
            if ( $r->cache( 'saved_contactform:' . $obj->id ) ) {
                $obj->SUPER::save( @_ );
                return 1;
            }
        }
    }
    if ( is_cms( $app ) ) {
        if (! $app->validate_magic ) {
            $app->return_to_dashboard();
            return 0;
        }
        if (! ContactForm::Plugin::_formelement_permission() ) {
            $app->return_to_dashboard( permission => 1 );
            return 0;
        }
        my $ts = current_ts();
        my $columns = $obj->column_names;
        for my $column ( @$columns ) {
            if ( $column =~ /_on$/ ) {
                my $date = trim( $app->param( $column . '_date' ) );
                my $time = trim( $app->param( $column . '_time' ) );
                if ( $date && $time ) {
                    $date =~ s/-+//g;
                    $time =~ s/:+//g;
                    my $ts_on = $date . $time;
                    if ( valid_ts( $ts_on ) ) {
                        $obj->$column( $ts_on );
                    }
                }
            }
        }
        if (! $obj->created_on ) {
            $obj->created_on( $ts );
        }
        $obj->modified_on( $ts );
        if ( $obj->id ) {
            my $author = MT::Author->load( $obj->author_id );
            if (! defined $author ) {
                $obj->author_id( $app->user->id );
            }
        } else {
            $obj->author_id( $app->user->id );
        }
        if (! $obj->status ) {
            $obj->status( HOLD() );
        }
        if ( $obj->basename ) {
            my $basename_obj = $app->model( 'contactform' )->load( { basename => $obj->basename } );
            if ( $basename_obj ) {
                if ( (! $obj->id ) || ( $obj->id && $obj->id != $basename_obj->id ) ) {
                    $obj->basename( '' );
                }
            }
        }
        if (! defined( $obj->basename ) || ( $obj->basename eq '' ) ) {
            my $name = make_unique_basename( $obj );
            $obj->basename( $name );
        }
        $obj->mtml_id( $obj->type );
        my $create_mtml;
        if ( $obj->id ) {
            $original = $r->cache( 'contactform_original' . $obj->id );
            if (! $original ) {
                $original = $obj->clone_all();
            } elsif ( $original && $original->mtml_id ne $obj->type ) {
                $create_mtml = 1;
            }
        } else {
            $create_mtml = 1;
        }
        if ( $create_mtml ) {
            my $mtml = $obj->get_default_template;
            $obj->mtml( $mtml );
        }
    }
    if (! $obj->id ) {
        $is_new = 1;
    }
    $obj->class( 'contactform' );
    $obj->SUPER::save( @_ );
    $r->cache( 'saved_contactform:' . $obj->id, $obj );
    if ( $is_new ) {
        if ( is_cms( $app ) ) {
            if ( $app->mode eq 'save' ) {
                $app->log( {
                    message => $plugin->translate( 'Form Element \'[_1]\' (ID:[_2]) created by \'[_3]\'', utf8_on( $obj->name ), $obj->id, $app->user->name ),
                    blog_id => 0,
                    author_id => $app->user->id,
                    class => 'contactform',
                    level => MT::Log::INFO(),
                } );
            }
        }
    }
    if ( is_cms( $app ) ) {
        if ( $app->mode eq 'save' ) {
            if (! $is_new ) {
                $app->log( {
                    message => $plugin->translate( 'Form Element \'[_1]\' (ID:[_2]) edited by \'[_3]\'', utf8_on( $obj->name ), $obj->id, $app->user->name ),
                    blog_id => 0,
                    author_id => $app->user->id,
                    class => 'contactform',
                    level => MT::Log::INFO(),
                } );
            }
        }
    }
    return 1;
}

sub remove {
    my $obj = shift;
    require ContactForm::Plugin;
    if ( ref $obj ) {
        my $app = MT->instance();
        my $plugin = MT->component( 'ContactForm' );
        if ( is_cms( $app ) ) {
            if (! $app->validate_magic ) {
                $app->return_to_dashboard();
                return 0;
            }
            if (! ContactForm::Plugin::_formelement_permission( $app->blog ) ) {
                $app->return_to_dashboard( permission => 1 );
                return 0;
            }
        }
        $obj->SUPER::remove( @_ );
        if ( is_cms( $app ) ) {
            $app->log( {
                message => $plugin->translate( 'Form Element \'[_1]\' (ID:[_2]) deleted by \'[_3]\'', utf8_on( $obj->name ), $obj->id, $app->user->name ),
                blog_id => 0,
                author_id => $app->user->id,
                class => 'contactform',
                level => MT::Log::INFO(),
            } );
        }
        my @order = ContactForm::ContactFormOrder->load( { contactform_id => $obj->id } );
        for my $ord ( @order ) {
            $ord->remove or die $ord->errstr;
        }
        return 1;
    }
    $obj->SUPER::remove( @_ );
}

sub author {
    my $obj = shift;
    my $r = MT::Request->instance;
    my $author = $r->cache( 'cache_author:' . $obj->author_id );
    return $author if defined $author;
    $author = MT::Author->load( $obj->author_id ) if $obj->author_id;
    unless ( defined $author ) {
        $author = MT::Author->new;
        my $plugin = MT->component( 'ContactForm' );
        $author->name( $plugin->translate( '(Unknown)' ) );
        $author->nickname( $plugin->translate( '(Unknown)' ) );
    }
    $r->cache( 'cache_author:' . $obj->author_id, $author );
    return $author;
}

sub _nextprev {
    my ( $obj, $direction ) = @_;
    my $r = MT::Request->instance;
    my $nextprev = $r->cache( "contactform_$direction:" . $obj->id );
    return $nextprev if defined $nextprev;
    $nextprev = $obj->nextprev(
        direction => $direction,
        terms     => undef,
        by        => 'created_on',
    );
    $r->cache( "contactform_$direction:" . $obj->id, $nextprev );
    return $nextprev;
}

sub make_unique_basename {
    my $obj = shift;
    my $name = $obj->name;
    $name = '' if !defined $name;
    $name =~ s/^\s+//;
    $name =~ s/\s+$//;
    if ( $name eq '' ) {
        if ( my $text = $obj->description ) {
            $name = first_n_words( $text, const( 'LENGTH_ENTRY_TITLE_FROM_TEXT' ) );
        }
        $name = 'Contact Form' if $name eq '';
    }
    my $limit = 30;
    $limit = 15 if $limit < 15; $limit = 250 if $limit > 250;
    my $base = substr( dirify( $name ), 0, $limit );
    $base =~ s/_+$//;
    $base = 'contact_form' if $base eq '';
    my $i = 1;
    my $base_copy = $base;
    my $class = ref $obj;
    return MT::Util::_get_basename( $class, $base );
}

sub get_template {
    my $obj = shift;
    if ( my $mtml = $obj->mtml ) {
        return $mtml;
    }
    return $obj->get_default_template;
}

sub get_default_template {
    my $obj = shift;
    my $plugin = MT->component( 'ContactForm' );
    my $contactform_objects = MT->registry( 'contactform_objects' );
    my $contactform_object = $contactform_objects->{ $obj->type }
        or return;
    if ( my $component = $contactform_object->{ plugin } ) {
        my $plugin_id = $component->{ id };
        if ( $plugin_id eq 'contactform' ) {
            $plugin_id = 'contactformconfig';
        }
        $plugin = MT->component( $plugin_id );
    }
    my $type = $contactform_objects->{ $obj->type }->{ template_type };
    my $mtml = $plugin->get_config_value( "template_type_$type" );
    if (! $mtml ) {
        my $tmpl_path = plugin_template_path( $plugin, 'templates' );
        my $tmpl = File::Spec->catfile( $tmpl_path, $type . '.mtml' );
        if (-f $tmpl ) {
            $mtml = utf8_on( read_from_file( $tmpl ) );
        }
    }
    return $mtml;
}

sub get_registry {
    my ( $obj, $registry ) = @_;
    my $contactform_objects = MT->registry( 'contactform_objects' );
    if ( my $contactform_object = $contactform_objects->{ $obj->type } ) {
        my $registry = $contactform_object->{ $registry };
        return $registry;
    }
}

sub label {
    my $obj = shift;
    my $contactform_objects = MT->registry( 'contactform_objects' );
    if ( my $contactform_object = $contactform_objects->{ $obj->type } ) {
        if ( my $component = $contactform_object->{ plugin } ) {
            if ( my $plugin = MT->component( $component->{ id } ) ) {
                my $label = $contactform_object->{ name };
                return $plugin->translate( $label );
            }
        }
    }
}

sub backup_terms_args {
    my $class = shift;
    my ( $blog_ids ) = @_;
    if ( defined( $blog_ids ) && scalar( @$blog_ids ) ) {
        my $order_datasource = MT->model( 'contactformorder' )->datasource;
        my @contactformorders = MT->model( 'contactformorder' )->load( undef, {
            'join' => MT->model( 'contactformgroup' )->join_on(
                undef,
                {   id => \"= ${order_datasource}_group_id",
                    blog_id => $blog_ids,
                }, {
                    unique => 1,
                }
            )
        } );
        my @contactformorder_ids = map { $_->id } @contactformorders;
        my $terms_args = {
            terms   => undef,
            args    => {
                'join' => MT->model( 'contactformorder' )->join_on(
                    undef,
                    {   id => \@contactformorder_ids,
                        contactform_id => \"= ${datasource}_id"
                    }, {
                        unique => 1,
                    }
                )
            }
        };
        return $terms_args;
    }
    return { terms => undef, args => undef };
}

sub parents {
    my $obj = shift;
    {   blog_id => {
            class    => [ MT->model( 'blog' ), MT->model( 'website' ) ],
            optional => 1
        },
    };
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
    $elem = 'contactform';
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

sub _restore_id {
    my $obj = shift;
    my ( $key, $val, $data, $objects ) = @_;

    return 0 unless 'ARRAY' eq ref($val);
    return 1 if 0 == $data->{$key};

    my $new_obj;
    my $old_id = $data->{$key};
    foreach (@$val) {
        $new_obj = $objects->{"$_#$old_id"};
        last if $new_obj;
    }
    return 0 unless $new_obj;
    $data->{$key} = $new_obj->id;
    return 1;
}

# sub restore_parent_ids {
#     my $obj = shift;
#     my ( $data, $objects ) = @_;
#
#     my $parents = $obj->parents;
#     my $count   = scalar( keys %$parents );
#
#     my $done = 0;
#     while ( my ( $key, $val ) = each(%$parents) ) {
#         $val = [$val] unless ( ref $val );
#         if ( 'ARRAY' eq ref($val) ) {
#             $done += $obj->_restore_id( $key, $val, $data, $objects );
#         }
#         elsif ( 'HASH' eq ref($val) ) {
#             my $v = $val->{class};
#             $v = [$v] unless ( ref $v );
#             my $result = 0;
#             if ( my $relations = $val->{relations} ) {
#                 my $col = $relations->{key};
#                 my $ds  = $data->{$col};
#                 my $ev  = $relations->{ $ds . '_id' };
#                 $ev = MT->model($ds) unless $ev;
#                 return 0 unless $ev;
#                 $ev = [$ev] unless ( ref $ev );
#                 $done += $obj->_restore_id( $key, $ev, $data, $objects );
#             }
#             else {
#                 $result = $obj->_restore_id( $key, $v, $data, $objects );
#                 $result = 1 if exists( $val->{optional} ) && $val->{optional};
#                 $data->{$key} = -1
#                     if !$result
#                         && ( exists( $val->{orphanize} )
#                             && $val->{orphanize} );
#                 $done += $result;
#             }
#         }
#     }
#     ( $count == $done ) ? 1 : 0;
# }

sub restore_parent_ids {
    my $obj = shift;
    my ( $data, $objects ) = @_;
    return 0 unless $obj->SUPER::restore_parent_ids( @_ );

    my $basename = $data->{ basename };

    my $cf = MT->model( 'contactform' )->load({basename => $basename })
        or return 1;

    $objects->{ ref($obj) . '#' . $data->{ id } } = $cf;

    return 99;
}

1;
