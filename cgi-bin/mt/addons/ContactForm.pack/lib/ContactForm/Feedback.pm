package ContactForm::Feedback;
use strict;
use MT::Blog;
use MT::Author;
use MT::Request;
use MT::Log;
use ContactForm::Util qw( is_cms current_ts valid_ts is_application );
use MT::Util qw( trim is_valid_date );
use base qw( MT::Object );

my $datasource = 'feedback';
if ( lc( MT->config( 'ObjectDriver' ) ) =~ /oracle/ ) {
    $datasource = 'fb';
}

__PACKAGE__->install_properties( {
    column_defs => {
        'id' => 'integer not null auto_increment',
        # 'object_id' => 'integer',
        'blog_id' => 'integer',
        'author_id' => 'integer',
        'form_author_id' => 'integer',
        'contactform_group_id' => 'integer',
        'identifier' => 'string(255)',
        'email' => 'string(255)',
        'model' => 'string(25)',
        'object_id' => 'integer',
        'owner_id' => 'integer',
        'data' => 'blob',
        'remote_ip' => 'string(255)',
        'memo' => 'string(255)',
        'status' => 'integer',
        'class' => 'string(25)',
    },
    indexes => {
        # 'object_id' => 1,
        'blog_id' => 1,
        'author_id' => 1,
        'form_author_id' => 1,
        'contactform_group_id' => 1,
        'owner_id' => 1,
        'identifier' => 1,
        'email' => 1,
        'model' => 1,
        'object_id' => 1,
        'remote_ip' => 1,
        'created_on' => 1,
        'modified_on' => 1,
        'status' => 1,
        'class' => 1,
    },
    audit       => 1,
    child_of    => [ 'MT::Blog', 'MT::Website' ],
    datasource  => $datasource,
    primary_key => 'id',
    class_type  => 'feedback',
} );

sub HOLD     () { 1 }
sub PENDING  () { 1 }
sub CONFIRMED() { 2 }
sub RELEASE  () { 2 }
sub FLAGGED  () { 3 }

sub status_text {
    my $obj = shift;
    my $plugin = MT->component( 'ContactForm' );
    if ( $obj->status == HOLD() ) {
        return $plugin->translate( 'Unapproval' );
    }
    if ( $obj->status == RELEASE() ) {
        return $plugin->translate( 'Approval' );
    }
    if ( $obj->status == FLAGGED() ) {
        return $plugin->translate( 'Flagged' );
    }
}

sub status_int {
    my ( $obj, $status ) = @_;
    $status = lc( $status );
    if ( $status eq 'unapproval' ) {
        return 1;
    }
    if ( $status eq 'approval' ) {
        return 2;
    }
    if ( $status eq 'flagged' ) {
        return 3;
    }
    return 0;
}

sub class_label {
    my $plugin = MT->component( 'ContactForm' );
    return $plugin->translate( 'Feedback' );
}

sub class_label_plural {
    my $plugin = MT->component( 'ContactForm' );
    return $plugin->translate( 'Feedbacks' );
}

sub is_dirty {
    my $obj = shift;
    return $obj->{ __dirty };
}

sub thaw_data {
    my $obj = shift;
    # return $obj->{ __data } if $obj->{ __data };
    my $data = $obj->data || '';
    require MT::Serialize;
    my $out = MT::Serialize->unserialize( $data );
    if ( ref $out eq 'REF' ) {
        $obj->{ __data } = $$out;
    } else {
        $obj->{ __data } = {};
    }
    $obj->{ __dirty } = 0;
    return $obj->{ __data };
}

sub get {
    my $obj = shift;
    my ( $var ) = @_;
    my $data = $obj->thaw_data;
    $data->{ $var };
}

sub table_count {
    my $obj = shift;
    my @count = $obj->get_table;
    return scalar @count;
}

sub get_hash {
    my $obj = shift;
    return if $obj eq 'ContactForm::Feedback';
    require MT::Request;
    my $r = MT::Request->instance;
    my $k = 'cache_feedback_get_hash:' . $obj->id;
    my $hash = $r->cache( $k );
    if (! $hash ) {
        my $thaw_data = $obj->thaw_data;
        foreach my $number ( sort { $a <=> $b } keys %$thaw_data ) {
            my $value = $thaw_data->{ $number };
            $hash->{ @$value[2] } = $value;
        }
    }
    $r->cache( $k, $hash );
    return $hash;
}

sub get_table {
    my $obj = shift;
    return if $obj eq 'ContactForm::Feedback';
    require MT::Request;
    my $r = MT::Request->instance;
    my $k = 'cache_feedback_get_table:' . $obj->id;
    my $table = $r->cache( $k );
    if (! $table ) {
        my $thaw_data = $obj->thaw_data;
        foreach my $number ( sort { $a <=> $b } keys %$thaw_data ) {
            my $value = $thaw_data->{ $number };
            push ( @$table, [ @$value[0], @$value[1], @$value[2], @$value[3] ] );
        }
    }
    $r->cache( $k, $table );
    $table ||= [];
    return wantarray ? @$table : $table;
}

sub get_keys {
    my $obj = shift;
    return if $obj eq 'ContactForm::Feedback';
    require MT::Request;
    my $r = MT::Request->instance;
    my $k = 'cache_feedback_get_keys:' . $obj->id;
    my $table = $r->cache( $k );
    if (! $table ) {
        my $thaw_data = $obj->thaw_data;
        foreach my $number ( sort { $a <=> $b } keys %$thaw_data ) {
            my $value = $thaw_data->{ $number };
            push ( @$table, @$value[0] );
        }
    }
    $r->cache( $k, $table );
    return wantarray ? @$table : $table;
}

sub get_types {
    my $obj = shift;
    return if $obj eq 'ContactForm::Feedback';
    require MT::Request;
    my $r = MT::Request->instance;
    my $k = 'cache_feedback_get_types:' . $obj->id;
    my $table = $r->cache( $k );
    if (! $table ) {
        my $thaw_data = $obj->thaw_data;
        foreach my $number ( sort { $a <=> $b } keys %$thaw_data ) {
            my $value = $thaw_data->{ $number };
            push ( @$table, @$value[ 3 ] );
        }
    }
    $r->cache( $k, $table );
    return wantarray ? @$table : $table;
}

sub get_data {
    my $obj = shift;
    return if $obj eq 'ContactForm::Feedback';
    require MT::Request;
    my $r = MT::Request->instance;
    my $k = 'cache_feedback_get_data:' . $obj->id;
    my $table = $r->cache( $k );
    if (! $table ) {
        my $thaw_data = $obj->thaw_data;
        foreach my $number ( sort { $a <=> $b } keys %$thaw_data ) {
            my $value = $thaw_data->{ $number };
            push ( @$table, @$value[ 1 ] );
        }
    }
    $r->cache( $k, $table );
    return ( wantarray && ref( $table ) eq 'ARRAY' ) ? @$table : $table;
}

sub get_string {
    my $obj = shift;
    my @table = $obj->get_data;
    return join( ',', @table );
}

sub get_download_data {
    my $obj = shift;
    return if $obj eq 'ContactForm::Feedback';
    my $form = $obj->form;
    my $types = $form->_types;
    my $thaw_data = $obj->thaw_data;
    my @table;
    foreach my $number ( sort { $a <=> $b } keys %$thaw_data ) {
        my $vals = $thaw_data->{ $number };
        my $label = @$vals[ 0 ];
        my $value = @$vals[ 1 ];
        my $type = @$vals[ 3 ];
        if ( $value && $types && ( ( $type eq 'date' ) || ( $type eq 'date-and-time' ) ) ) {
            if ( valid_ts( $value ) ) {
                $value = "\t" . $value;
            }
        }
        push ( @table, $value );
    }
    return wantarray ? @table : \@table;
}

sub object {
    my $obj = shift;
    my $model = $obj->model;
    my $object_id = $obj->object_id;
    if ( $model && $object_id ) {
        my $r = MT::Request->instance;
        my $object = $r->cache( 'cache_' . $model . ':' . $object_id );
        return $object if defined $object;
        $object = MT->model( $model )->load( $object_id );
        $r->cache( 'cache_' . $model . ':' . $object_id, $object );
        return $object;
    }
    return undef;
}

sub object_label {
    my $obj = shift;
    my $plugin = MT->component( 'ContactForm' );
    my $model = $obj->model;
    return $plugin->translate( ucfirst( $model ) );
}

sub object_name {
    my $obj = shift;
    my $object = $obj->object;
    if (! $object ) {
        my $plugin = MT->component( 'ContactForm' );
        return $plugin->translate( '(Unknown)' )
    }
    my $model = $obj->model;
    if ( $model eq 'page' || $model eq 'page' ) {
        return $object->title;
    }
    if ( $model eq 'category' || $model eq 'folder' || $model eq 'file' ||
        $model eq 'image' || $model eq 'video' || $model eq 'file' ) {
        return $object->label;
    }
    if ( $object->has_column( 'name' ) ) {
        return $object->name;
    }
    if ( $object->has_column( 'label' ) ) {
        return $object->label;
    }
    if ( $object->has_column( 'title' ) ) {
        return $object->title;
    }
}

sub save {
    my $obj = shift;
    my $app = MT->instance();
    my $plugin = MT->component( 'ContactForm' );
    my $is_new;
    my $r = MT::Request->instance;
    my $cache_key = 'saved_feedback:' . $obj->id;
    if ( is_cms( $app ) ) {
        if (! $app->validate_magic ) {
            $app->return_to_dashboard();
            return 0;
        }
        if (! ContactForm::Plugin::_feedback_permission( $obj->blog ) ) {
            $app->return_to_dashboard( permission => 1 );
            return 0;
        }
    }
    if ( is_application( $app ) ) {
        if ( my $user = $app->user ) {
            $obj->author_id( $user->id );
            if ( ! $obj->id && ! $obj->created_by ) {
                $obj->created_by( $obj->author_id );
            }
        }
        if ( $obj->id ) {
            if ( $r->cache( $cache_key ) ) {
                if ( my $data = $obj->{ __data } ) {
                    require MT::Serialize;
                    my $ser = MT::Serialize->serialize( \$data );
                    $obj->data( $ser );
                }
                $obj->{ __dirty } = 0;
                if (! $obj->status ) {
                    $obj->status( HOLD() );
                }
                $obj->modified_on( current_ts( $obj->blog ) );
                $obj->SUPER::save( @_ );
                $app->run_callbacks( 'saved.feedback', $app, $obj );
                return 1;
            }
        }
        if ( ( $app->mode eq 'save' && $app->param( '_type' ) eq 'feedback' ) ||
             ( $app->mode eq 'update_feedback' ) ) {
            my $data;
            my $count = $obj->table_count;
            my @labels = $obj->get_keys;
            for ( 1 .. $count ) {
                my $value = $app->param( 'field_data-' . $_ );
                if ( $value && $value eq 'contact-form-type-date' ) {
                    if ( my $field_date = $app->param( 'field_data-date-' . $_ ) ) {
                        my $field_time = $app->param( 'field_data-time-' . $_ );
                        $field_date =~ s/-+//g;
                        $field_time =~ s/:+//g;
                        $field_date = trim( $field_date );
                        $field_time = trim( $field_time );
                        $value = $field_date . $field_time;
                    }
                }
                my $basename = $app->param( 'field_basename-' . $_ );
                my $type = $app->param( 'field_type-' . $_ );
                $data->{ $_ } = [ $labels[ $_ - 1 ], $value, $basename, $type ];
            }
            $obj->{ __data } = $data;
        }
    }
    my $blog = $obj->blog;
    if (! $obj->id ) {
        $is_new = 1;
    }
    $obj->class( 'feedback' );
    if ( my $data = $obj->{ __data } ) {
        require MT::Serialize;
        my $ser = MT::Serialize->serialize( \$data );
        $obj->data( $ser );
    }
    $obj->{ __dirty } = 0;
    if (! $obj->status ) {
        $obj->status( HOLD() );
    }
    $obj->modified_on( current_ts( $obj->blog ) );
    if ( is_cms( $app ) ) {
        my $created_on_date = $app->param( 'created_on_date' );
        if ( $created_on_date ) {
            my $created_on_time = $app->param( 'created_on_time' ) || '000000';
            $created_on_date =~ s/\D//g;
            $created_on_time =~ s/\D//g;
            my $created_on = $created_on_date . $created_on_time;
            if ( is_valid_date( $created_on ) ) {
                $obj->created_on( $created_on );
            }
        }
    }
    unless ( $obj->created_on ) {
        $obj->created_on( current_ts( $obj->blog ) );
    }
    $obj->SUPER::save( @_ );
    $app->run_callbacks( 'saved.feedback', $app, $obj );
    $r->cache( $cache_key, $obj );
    return 1;
}

sub remove {
    my $obj = shift;
    if ( ref $obj ) {
        my $app = MT->instance();
        my $plugin = MT->component( 'ContactForm' );
        if ( is_cms( $app ) ) {
            if (! $app->validate_magic ) {
                $app->return_to_dashboard();
                return 0;
            }
            if (! ContactForm::Plugin::_feedback_permission( $obj->blog ) ) {
                $app->return_to_dashboard( permission => 1 );
                return 0;
            }
        }
        $obj->SUPER::remove( @_ );
        if ( is_cms( $app ) ) {
            $app->log( {
                message => $plugin->translate( 'Feedback (ID:[_1]) deleted by \'[_2]\'', $obj->id, $app->user->name ),
                blog_id => $obj->blog_id,
                author_id => $app->user->id,
                class => 'contactform',
                level => MT::Log::INFO(),
            } );
        }
        return 1;
    }
    $obj->SUPER::remove( @_ );
}

sub author {
    my $obj = shift;
    my $column = shift;
    $column ||= 'author_id';
    my $r = MT::Request->instance;
    my $author;
    if ( $obj->$column ) {
        $author = $r->cache( 'cache_author:' . $obj->$column );
        return $author if defined $author;
        $author = MT::Author->load( $obj->$column ) if $obj->$column;
    }
    unless ( defined $author ) {
        $author = MT::Author->new;
        my $plugin = MT->component( 'ContactForm' );
        $author->name( $plugin->translate( '(Unknown)' ) );
        $author->nickname( $plugin->translate( '(Unknown)' ) );
    }
    $r->cache( 'cache_author:' . $obj->$column, $author ) if $obj->$column;
    return $author;
}

sub form_author {
    my $obj = shift;
    return $obj->author( 'form_author_id' );
}

sub form {
    my $obj = shift;
    my $r = MT::Request->instance;
    my $k = 'cache_formgroup:' . $obj->contactform_group_id;
    my $contactform_group = $r->cache( $k );
    return $contactform_group if defined $contactform_group;
    require ContactForm::ContactFormGroup;
    $contactform_group = ContactForm::ContactFormGroup->load( $obj->contactform_group_id );
    $r->cache( $k, $contactform_group );
    if (! $contactform_group ) {
        $contactform_group = ContactForm::ContactFormGroup->new;
        my $plugin = MT->component( 'ContactForm' );
        $contactform_group->name( $plugin->translate( '(Unknown)' ) );
    }
    return $contactform_group;
}

sub form_name {
    my $obj = shift;
    return $obj->form->name;
}

sub blog {
    my $obj = shift;
    my $r = MT::Request->instance;
    my $k = 'cache_blog:' . $obj->blog_id;
    my $blog = $r->cache( $k );
    return $blog if defined $blog;
    $blog = MT::Blog->load( $obj->blog_id );
    $r->cache( $k, $blog );
    return $blog;
}

sub _nextprev {
    my ( $obj, $direction ) = @_;
    my $r = MT::Request->instance;
    my $k = "feedback_$direction:" . $obj->id;
    my $nextprev = $r->cache( $k );
    return $nextprev if defined $nextprev;
    $nextprev = $obj->nextprev(
        direction => $direction,
        terms     => { blog_id => $obj->blog_id },
        by        => 'created_on',
    );
    $r->cache( $k, $nextprev );
    return $nextprev;
}

sub parents {
    my $obj = shift;
    {   blog_id => {
            class    => [ MT->model( 'blog' ), MT->model( 'website' ) ],
            optional => 1
        },
        author_id => {
            class => MT->model( 'author' ),
            optional => 1
        },
        contactform_group_id => MT->model( 'contactformgroup' ),
        object_id => {
            relations => {
                key     => 'model',
                class   => [    MT->model( 'page' ),     MT->model( 'entry' ),
                                MT->model( 'category' ), MT->model( 'folder' ),
                                MT->model( 'file' ),     MT->model( 'image' ),
                                MT->model( 'video' ),    MT->model( 'author' ) ]
            }
        },
        form_author_id => {
            class => MT->model( 'author' ),
            optional => 1
        },
        owner_id => {
            class => MT->model( 'author' ),
            optional => 1
        },
    };
}

sub restore_parent_ids {
    my $obj = shift;
    my ( $data, $objects ) = @_;

    my $parents = $obj->parents;
    my $count   = scalar( keys %$parents );

    my $done = 0;
    while ( my ( $key, $val ) = each(%$parents) ) {
        $val = [$val] unless ( ref $val );
        if ( 'ARRAY' eq ref($val) ) {
            $done += $obj->_restore_id( $key, $val, $data, $objects );
        }
        elsif ( 'HASH' eq ref($val) ) {
            my $v = $val->{class};
            $v = [$v] unless ( ref $v );
            my $result = 0;
            if ( my $relations = $val->{relations} ) {
                my $col = $relations->{key};
                my $ds  = $data->{$col};
                if ( $ds ) {
                    my $ev  = $relations->{ $ds . '_id' } || MT->model($ds)
                        or return 0;
                    $ev = [$ev] unless ( ref $ev );
                    $done += $obj->_restore_id( $key, $ev, $data, $objects );
                } else {
                    # case model = NULL (ex CustomObject)
                    $done += 1
                }
            }
            else {
                $result = $obj->_restore_id( $key, $v, $data, $objects );
                $result = 1 if exists( $val->{optional} ) && $val->{optional};
                $data->{$key} = -1
                    if !$result
                        && ( exists( $val->{orphanize} )
                            && $val->{orphanize} );
                $done += $result;
            }
        }
    }
    ( $count == $done ) ? 1 : 0;
}

sub restore_blob {
    my $obj = shift;
    my ( $column_name, $data, $objects ) = @_;

    if ( $column_name eq 'data' && ref $data eq 'REF' ) {
        require MT::Serialize;
        $$data = MT::Serialize->serialize( $data );
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
    $elem = 'feedback';
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
