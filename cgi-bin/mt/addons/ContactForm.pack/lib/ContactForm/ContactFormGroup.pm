package ContactForm::ContactFormGroup;
use strict;
use base qw( MT::Object );

use ContactForm::Util qw( is_cms current_ts valid_ts );
use MT::Util qw( trim );

my $datasource = 'contactformgroup';
if ( lc( MT->config( 'ObjectDriver' ) ) =~ /oracle/ ) {
    $datasource = 'cfmg';
}

__PACKAGE__->install_properties( {
    column_defs => {
        'id'          => 'integer not null auto_increment',
        'blog_id'     => 'integer',
        'author_id'   => 'integer',
        'name'        => 'string(255)',
        # 'additem'     => 'boolean',
        # 'addposition' => 'boolean',
        'created_on'  => 'datetime',
        'modified_on' => 'datetime',
        'template_id' => 'integer',
        'addfilter'   => 'string(25)',
        'class'       => 'string(25)',
        # 'addfiltertag' => 'string(255)',
        # 'addfilter_blog_id' => 'integer',
        # 'confirm_tmpl' => 'integer',
        # 'submit_tmpl' => 'integer',
        'cms_tmpl' => 'integer',
        'mail_sender_tmpl' => 'integer',
        'mail_admin_tmpl' => 'integer',
        'mail_sender' => 'boolean',
        'mail_admin' => 'boolean',
        'send_mailto' => 'string(255)',
        'return_url' => 'string(255)',
        'message' => 'text',
        'error_message' => 'text',
        'confirm_message' => 'text',
        'information_message' => 'text',
        'preopen_message' => 'text',
        'closed_message' => 'text',
        'notify_subject' => 'string(255)',
        'sender_subject' => 'string(255)',
        'requires_login' => 'boolean',
        'post_limit' => 'integer',
        'set_limit' => 'integer', # 1(set)/2(none)
        'publishing_on'=> 'datetime',
        'period_on' => 'datetime',
        'status' => 'integer',
        'set_period' => 'integer', # 1(set)/2(none)
        'single_post' => 'boolean',
        'not_save' => 'boolean',
    },
    indexes => {
        'blog_id'     => 1,
        'author_id'   => 1,
        'name'        => 1,
        'created_on'  => 1,
        'modified_on' => 1,
        'publishing_on'  => 1,
        'period_on' => 1,
        'status' => 1,
        'set_period' => 1,
    },
    datasource    => $datasource,
    primary_key   => 'id',
    child_of      => [ 'MT::Blog', 'MT::Website' ],
    class_type    => 'contactformgroup',
    child_classes => [ 'ContactForm::ContactFormOrder' ],
    meta          => 1,
} );

sub class_label {
    my $plugin = MT->component( 'ContactForm' );
    return $plugin->translate( 'Form' );
}

sub class_label_plural {
    my $plugin = MT->component( 'ContactForm' );
    return $plugin->translate( 'Forms' );
}

sub status_int {
    my ( $obj, $status ) = @_;
    $status = uc( $status );
    if ( ( $status eq 'DRAFT' ) || ( $status eq 'HOLD' ) ) {
        return 1;
    }
    if ( ( $status eq 'PUBLISHED' ) || ( $status eq 'PUBLISHING' ) || ( $status eq 'RELEASE' ) ) {
        return 2;
    }
    if ( ( $status eq 'UNAPPROVED' ) || ( $status eq 'REVIEW' ) ) {
        return 3;
    }
    if ( ( $status eq 'RESERVED' ) || ( $status eq 'FUTURE' ) ) {
        return 4;
    }
    if ( ( $status eq 'FINISED' ) || ( $status eq 'CLOSED' ) ) {
        return 5;
    }
    return 0;
}

sub status_text {
    my $obj = shift;
    my $status = $obj;
    if ( ref $obj ) {
        $status = $obj->status;
    }
    if ( $status == 1 ) {
        return 'Draft';
    }
    if ( $status == 2 ) {
        return 'Publishing';
    }
    if ( $status == 3 ) {
        return 'Review';
    }
    if ( $status == 4 ) {
        return 'Future';
    }
    if ( $status == 5 ) {
        return 'Closed';
    }
}

sub save {
    my $obj = shift;
    my $app = MT->instance();
    my $plugin = MT->component( 'ContactForm' );
    $obj->class( 'contactformgroup' );
    require MT::Log;
    my $is_new;
    if ( ( is_cms( $app ) ) && ( $app->mode eq 'save' )
        && ( $app->param( '_type' ) eq 'contactformgroup' ) ) {
        if (! $app->validate_magic ) {
            $app->return_to_dashboard();
            return 0;
        }
        if (! ContactForm::Plugin::_contactform_permission( $obj->blog ) ) {
            $app->return_to_dashboard( permission => 1 );
            return 0;
        }
        require ContactForm::ContactForm;
        my $publishing_on_date = trim( $app->param( 'publishing_on_date' ) );
        my $publishing_on_time = trim( $app->param( 'publishing_on_time' ) );
        my $period_on_date = trim( $app->param( 'period_on_date' ) ) || '000000';
        my $period_on_time = trim( $app->param( 'period_on_time' ) ) || '235959';
        $publishing_on_date =~ s/-+//g;
        $period_on_date =~ s/-+//g;
        $publishing_on_time =~ s/:+//g;
        $period_on_time =~ s/:+//g;
        my $publishing_on = $publishing_on_date . $publishing_on_time;
        my $period_on = $period_on_date . $period_on_time;
        if ( valid_ts( $publishing_on ) ) {
            $obj->publishing_on( $publishing_on );
        } elsif (! $obj->publishing_on ) {
            $obj->publishing_on( current_ts( $obj->blog ) );
        }
        if ( valid_ts( $period_on ) ) {
            $obj->period_on( $period_on );
        } elsif (! $obj->period_on ) {
            my $plugin_config = MT->component( 'ContactFormConfig' );
            my $default_period = $plugin_config->get_config_value( 'default_period' );
            require ContactForm::Plugin;
            my $period_on = ContactForm::Plugin::_end_date( $obj->blog, current_ts( $obj->blog ), $default_period );
            $obj->period_on( $period_on );
        }
        if (! ContactForm::Plugin::_contactform_permission( $obj->blog ) ) {
            $app->return_to_dashboard( permission => 1 );
            return 0;
        }
        my $g = ContactForm::ContactFormGroup->load( { name => $obj->name, blog_id => $obj->blog_id } );
        if ( $g ) {
            if (! $obj->id ) {
                die $plugin->translate( 'Another group already exists by that name.' );
            }
            if ( $obj->id != $g->id ) {
                die $plugin->translate( 'Another group already exists by that name.' );
            }
        }
        my @order_old;
        my $current_ts = current_ts( $app->blog );
        $obj->modified_on( $current_ts );
        if ( $obj->id ) {
            @order_old = ContactForm::ContactFormOrder->load( { group_id => $obj->id } );
            require MT::Author;
            my $author = MT::Author->load( $obj->author_id );
            if (! defined $author ) {
                $obj->author_id( $app->user->id );
            }
            if (! $obj->created_on ) {
                $obj->created_on( $current_ts );
            }
        } else {
            $obj->author_id( $app->user->id );
            $obj->created_on( $current_ts );
            $obj->SUPER::save( @_ );
            $is_new = 1;
            $app->log( {
                message => $plugin->translate( "Contact Form '[_1]' (ID:[_2]) created by '[_3]'", $obj->name, $obj->id, $app->user->name ),
                blog_id => $obj->blog_id,
                author_id => $app->user->id,
                class => 'contactform',
                level => MT::Log::INFO(),
            } );
        }
        my $sort = $app->param( 'sort' );
        my @sort_id = split( /,/, $sort );
        my $i = 500; my @add_items;
        for my $object_id ( @sort_id ) {
            my $contactform = ContactForm::ContactForm->load( $object_id );
            if ( $contactform ) {
                my $order = ContactForm::ContactFormOrder->get_by_key( { group_id => $obj->id,
                                                                   contactform_id => $object_id } );
                $order->blog_id( $obj->blog_id );
                $order->order( $i );
                $order->save or die $order->errstr;
                push ( @add_items, $order->id );
                $i++;
            }
        }
        for my $old ( @order_old ) {
            my $order_id = $old->id;
            if (! grep $_ eq $order_id, @add_items ) {
               $old->remove or die $old->errstr;
            }
        }
        unless ( $is_new ) {
            $app->log( {
                message => $plugin->translate( "Contact Form '[_1]' (ID:[_2]) edited by '[_3]'", $obj->name, $obj->id, $app->user->name ),
                blog_id => $obj->blog_id,
                author_id => $app->user->id,
                class => 'contactform',
                level => MT::Log::INFO(),
            } );
        }
    }
    unless ( $is_new ) {
        $obj->SUPER::save( @_ );
    }
    return 1;
}

sub remove {
    my $obj = shift;
    if ( ref $obj ) {
        require ContactForm::ContactForm;
        my $id = $obj->id;
        my $name = $obj->name;
        my $app = MT->instance();
        if ( is_cms( $app ) ) {
            unless ( $app->validate_magic ) {
                $app->return_to_dashboard();
                return 0;
            }
            unless ( ContactForm::Plugin::_contactform_permission( $obj->blog ) ) {
                $app->return_to_dashboard( permission => 1 );
                return 0;
            }
        }
        $obj->SUPER::remove( @_ );
        my @order = ContactForm::ContactFormOrder->load( { group_id => $id } );
        for my $item ( @order ) {
            $item->remove or die $item->errstr;
        }
        if ( is_cms( $app ) ) {
            my $plugin = MT->component( 'ContactForm' );
            require MT::Log;
            $app->log( {
                message => $plugin->translate( "Contact Form '[_1]' (ID:[_2]) deleted by '[_3]'", $name, $id, $app->user->name ),
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
    require MT::Request;
    my $r = MT::Request->instance;
    my $author = $r->cache( 'cache_author:' . $obj->author_id );
    return $author if defined $author;
    require MT::Author;
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

sub blog {
    my $obj = shift;
    require MT::Request;
    my $r = MT::Request->instance;
    my $blog = $r->cache( 'cache_blog:' . $obj->blog_id );
    return $blog if defined $blog;
    require MT::Blog;
    $blog = MT::Blog->load( $obj->blog_id );
    $r->cache( 'cache_blog:' . $obj->blog_id, $blog );
    return $blog;
}

sub children {
    my $obj = shift;
    require MT::Request;
    my $r = MT::Request->instance;
    my $contactforms = $r->cache( 'cache_contactform_children:' . $obj->id );
    unless ( $contactforms ) {
        my %params;
        require ContactForm::ContactFormOrder;
        $params { 'join' } = [ 'ContactForm::ContactFormOrder', 'contactform_id',
                               { group_id => $obj->id },
                               { sort   => 'order',
                                 direction => 'ascend',
                               } ];
        my @forms = MT->model( 'contactform' )->load( undef, \%params );
        $contactforms = \@forms;
        $r->cache( 'cache_contactform_children:' . $obj->id, $contactforms );
    }
    if ( wantarray ) {
        return @$contactforms;
    }
    return $contactforms;
}

sub feedback_count {
    my $obj = shift;
    require MT::Request;
    my $r = MT::Request->instance;
    my $feedbacks = $r->cache( 'cache_contactform_feedback_count:' . $obj->id );
    unless ( $feedbacks ) {
        my %params;
        require ContactForm::Feedback;
        $feedbacks = ContactForm::Feedback->count( { contactform_group_id => $obj->id } );
        $r->cache( 'cache_contactform_feedback_count:' . $obj->id, $feedbacks );
    }
    return $feedbacks;
}

sub _nextprev {
    my ( $obj, $direction ) = @_;
    my $r = MT::Request->instance;
    my $nextprev = $r->cache( "contactformgroup_$direction:" . $obj->id );
    return $nextprev if defined $nextprev;
    $nextprev = $obj->nextprev(
        direction => $direction,
        terms     => undef,
        by        => 'created_on',
    );
    $r->cache( "contactformgroup_$direction:" . $obj->id, $nextprev );
    return $nextprev;
}

sub _types {
    my $obj = shift;
    require MT::Request;
    my $r = MT::Request->instance;
    my $types = $r->cache( 'cache_contactform_types:' . $obj->id );
    unless ( $types ) {
        if ( my @children = $obj->children ) {
            for my $child ( @children ) {
                $types->{ $child->name } = $child->type;
            }
        }
        $r->cache( 'cache_contactform_types:' . $obj->id, $types );
    }
    return $types;
}

sub is_open {
    my $obj = shift;
    my $set_limit = $obj->set_limit;
    my $set_period = $obj->set_period;
    if ( ( $set_limit != 1 ) && ( $set_period != 1 ) ) {
        return 1;
    }
    if ( (! $obj->is_closed ) && (! $obj->is_preopen ) ) {
        return 1;
    }
    return 0;
}

sub is_preopen {
    my $obj = shift;
    my $set_period = $obj->set_period;
    if ( $set_period != 1 ) {
        return 0;
    }
    if ( my $publishing_on = $obj->publishing_on ) {
        if ( current_ts( $obj->blog ) < $publishing_on ) {
            return 1;
        }
    }
}

sub is_closed {
    my $obj = shift;
    my $set_limit = $obj->set_limit;
    my $set_period = $obj->set_period;
    if ( ( $set_period != 1 ) && ( $set_limit != 1 ) ) {
        return 0;
    }
    my $closed;
    if ( $obj->status == 5 ) {
        return 1;
    }
#    if ( $obj->feedback_count >= $obj->post_limit ) {
    if ( ( $set_limit && $set_limit eq '1' ) && $obj->feedback_count >= $obj->post_limit ) {
        $closed = 1;
    }
    if ( ( $set_period && $set_period eq '1' ) && current_ts( $obj->blog ) >= $obj->period_on ) {
        $closed = 1;
    }
    if ( $closed ) {
        if ( $obj->status != 5 ) {
            $obj->status( 5 );
            $obj->save or die $obj->errstr;
        }
        return 1;
    }
    return 0;
}

sub is_limit {
    my $obj = shift;
    my $set_limit = $obj->set_limit;
    if ( $set_limit == 1 ) {
        if ( $obj->feedback_count >= $obj->post_limit ) {
            if ( $obj->status != 5 ) {
                $obj->status( 5 );
                $obj->save or die $obj->errstr;
            }
            return 1;
        }
    }
    return 0;
}

sub parents {
    my $obj = shift;
    +{  blog_id => {
            class    => [ MT->model( 'blog' ), MT->model( 'website' ) ],
            optional => 1,
        },
        template_id => {
            class    => MT->model( 'template' ),
            optional => 1,
        },
        cms_tmpl => {
            class    => MT->model( 'template' ),
            optional => 1,
        },
        mail_sender_tmpl => {
            class    => MT->model( 'template' ),
            optional => 1,
        },
        mail_admin_tmpl => {
            class    => MT->model( 'template' ),
            optional => 1,
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
    $elem = 'contactformgroup';
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

sub child_key { 'group_id'; }

1;
