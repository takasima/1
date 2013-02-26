package PowerCMS::BackupRestore;
use strict;

sub init {
    1;
}

no warnings 'redefine';
require MT::BackupRestore;
*MT::BackupRestore::_create_obj_to_backup = sub {
    my $pkg = shift;
    my ( $class, $blog_ids, $obj_to_backup, $populated, $order ) = @_;

    my $instructions = MT->registry('backup_instructions');
    my $columns      = $class->column_names;

# PATCH
my $r = MT::Request->instance();
my $cache_key = 'reserved:' . $class;
# /PATCH
    foreach my $column (@$columns) {
        if ( $column =~ /^(\w+)_id$/ ) {
            my $parent  = $1;
            my $p_class = MT->model($parent);
            next unless $p_class;
            next if exists $populated->{$p_class};
            next
                if exists( $instructions->{$parent} )
                    && exists( $instructions->{$parent}{skip} )
                    && $instructions->{$parent}{skip};
# PATCH
next if $r->cache( $cache_key );
# /PATCH
            my $p_order
                = exists( $instructions->{$parent} )
                && exists( $instructions->{$parent}{order} )
                ? $instructions->{$parent}{order}
                : 500;
# PATCH
$r->cache( $cache_key, 1 );
# /PATCH
            $pkg->_create_obj_to_backup( $p_class, $blog_ids, $obj_to_backup,
                $populated, $p_order );
        }
    }

    if ( $class->can('backup_terms_args') ) {
        push @$obj_to_backup,
            {
            $class  => $class->backup_terms_args($blog_ids),
            'order' => $order
            };
    }
    else {
        push @$obj_to_backup,
            $pkg->_default_terms_args( $class, $blog_ids, $order );
    }
    $populated->{$class} = 1;
};

*MT::BackupRestore::_populate_obj_to_backup = sub {
    my $pkg = shift;
    my ($blog_ids) = @_;

    my %populated;
    if ( defined($blog_ids) && scalar(@$blog_ids) ) {

        # author will be handled at last
        $populated{ MT->model('author') } = 1;

        my $blog_class = MT->model('blog');
        if ( my @blogs
            = $blog_class->load( { id => \@$blog_ids, class => '*' } ) )
        {
            my $is_blog;
            foreach my $blog (@blogs) {
                $is_blog = 1, last
                    if $blog->is_blog();
            }
            if ($is_blog) {
                $populated{ MT->model('website') } = 1;
            }
        }

    }

    my @object_hashes;
    my $types        = MT->registry('object_types');
    my $instructions = MT->registry('backup_instructions');

# PATCH
my $r = MT::Request->instance();
# /PATCH

    foreach my $key ( keys %$types ) {
        next if $key =~ /\w+\.\w+/;    # skip subclasses
        my $class = MT->model($key);
        next unless $class;
        next if $class eq $key;    # FIXME: to remove plugin object_classes
        next
            if exists( $instructions->{$key} )
                && exists( $instructions->{$key}{skip} )
                && $instructions->{$key}{skip};
        next if exists $populated{$class};

# PATCH
my $cache_key = 'reserved:' . $class;
next if $r->cache( $cache_key );
# /PATCH

        my $order
            = exists( $instructions->{$key} )
            && exists( $instructions->{$key}{order} )
            ? $instructions->{$key}{order}
            : 500;

# PATCH
$r->cache( $cache_key, 1 );
# /PATCH

        if ( $class->can('create_obj_to_backup') ) {
            $class->create_obj_to_backup( $blog_ids, \@object_hashes,
                \%populated, $order );
        }
        else {
            $pkg->_create_obj_to_backup( $class, $blog_ids, \@object_hashes,
                \%populated, $order );
        }
    }

    if ( defined($blog_ids) && scalar(@$blog_ids) ) {

        # Author has two ways to be associated to a blog
        my $class = MT->model('author');
        unshift @object_hashes,
            {
            $class => {
                terms => undef,
                args  => {
                    'join' => [
                        MT->model('association'), 'author_id',
                        { blog_id => $blog_ids }, { unique => 1 }
                    ]
                }
            },
            'order' => 500
            };
        unshift @object_hashes,
            {
            $class => {
                terms => undef,
                args  => {
                    'join' => [
                        MT->model('permission'), 'author_id',
                        { blog_id => $blog_ids }, { unique => 1 }
                    ]
                }
            },
            'order' => 500
            };

        # Author could also be in objectscore table.
        unshift @object_hashes,
            {
            $class => {
                terms => undef,
                args  => {
                    'join' => [
                        MT->model('objectscore'), 'author_id',
                        undef, { unique => 1 }
                    ],
                }
            },
            'order' => 500
            };
        unshift @object_hashes,
            {
            $class => {
                terms => undef,
                args  => {
                    'join' => [
                        MT->model('objectscore'), 'object_id',
                        { object_ds => 'author' }, { unique => 1 }
                    ],
                }
            },
            'order' => 500
            };

        # And objectscores.
        my $oc = MT->model('objectscore');
        push @object_hashes,
            {
            $oc => {
                terms => { object_ds => 'author' },
                args  => undef,
            },
            'order' => 510,
            };
    }
    @object_hashes = sort { $a->{order} <=> $b->{order} } @object_hashes;
    my @obj_to_backup;
    foreach my $hash (@object_hashes) {
        delete $hash->{order};
        push @obj_to_backup, $hash;
    }
    return \@obj_to_backup;
};


use MT::BackupRestore::BackupFileHandler;
package MT::BackupRestore::BackupFileHandler;

no warnings 'redefine';

*MT::BackupRestore::BackupFileHandler::end_element = sub {
    my $self = shift;
    my $data = shift;

    if ( $self->{skip} ) {
        $self->{skip} -= 1;
        return;
    }

    my $name  = $data->{LocalName};
    my $ns    = $data->{NamespaceURI};
    my $class = MT->model($name);

    if ( my $obj = $self->{current} ) {
        if ( my $text_data = delete $self->{current_text} ) {
            my $column_name = shift @$text_data;
            my $text;
            $text .= $_ foreach @$text_data;

            my $defs = $obj->column_defs;
            if ( exists( $defs->{$column_name} ) ) {
                if ( 'blob' eq $defs->{$column_name}->{type} ) {
                    $text = MIME::Base64::decode_base64($text);
                    if ( substr( $text, 0, 4 ) eq 'SERG' ) {
                        $text = MT::Serialize->unserialize($text);
                    }
# PATCH
                    if ( $obj->can( 'restore_blob' ) ) {
                        $obj->restore_blob( $column_name, $text, $self->{objects} );
                    }
# /PATCH
                    $obj->$column_name($$text);
                }
                else {
                    $obj->column( $column_name, _decode($text) );
                }
            }
            elsif ( my $metacolumns = $self->{metacolumns}{ ref($obj) } ) {
                if ( my $type = $metacolumns->{$column_name} ) {
                    if ( 'vblob' eq $type ) {
                        $text = MIME::Base64::decode_base64($text);
                        $text = MT::Serialize->unserialize($text);
                        $obj->$column_name($$text);
                    }
                    else {
                        $obj->$column_name( _decode($text) );
                    }
                }
            }
        }
        else {
            my $old_id = $obj->id;
            unless (
                (      ( 'author' eq $name )
                    || ( 'template'   eq $name )
                    || ( 'filter'     eq $name )
                    || ( 'plugindata' eq $name )
                )
                && ( exists $self->{loaded} )
                )
            {
                delete $obj->{column_values}->{id};
                delete $obj->{changed_cols}->{id};
            }
            else {
                delete $self->{loaded};
            }
            my $exists = 0;
            if ( 'tag' eq $name ) {
                if (my $tag = MT::Tag->load(
                        { name   => $obj->name },
                        { binary => { name => 1 } }
                    )
                    )
                {
                    $exists = 1;
                    $self->{objects}->{"$class#$old_id"} = $tag;
                    $self->{callback}->("\n");
                    $self->{callback}->(
                        MT->translate(
                            "Tag '[_1]' exists in the system.", $obj->name
                        )
                    );
                }
            }
            elsif ( 'trackback' eq $name ) {
                my $term;
                my $message;
                if ( $obj->entry_id ) {
                    $term = { entry_id => $obj->entry_id };
                }
                elsif ( $obj->category_id ) {
                    $term = { category_id => $obj->category_id };
                }
                if ( my $tb = $class->load($term) ) {
                    $exists = 1;
                    my $changed = 0;
                    if ( $obj->passphrase ) {
                        $tb->passphrase( $obj->passphrase );
                        $changed = 1;
                    }
                    if ( $obj->is_disabled ) {
                        $tb->is_disabled( $obj->is_disabled );
                        $changed = 1;
                    }
                    $tb->save if $changed;
                    $self->{objects}->{"$class#$old_id"} = $tb;
                    my $records = $self->{records};
                    $self->{callback}->(
                        $self->{state} . " "
                            . MT->translate(
                            "[_1] records restored...", $records
                            ),
                        $data->{LocalName}
                    ) if $records && ( $records % 10 == 0 );
                    $self->{records} = $records + 1;
                }
            }
            elsif ( 'permission' eq $name ) {
                my $perm = $class->exist(
                    {   author_id => $obj->author_id,
                        blog_id   => $obj->blog_id
                    }
                );
                $exists = 1 if $perm;
            }
            elsif ( 'objectscore' eq $name ) {
                my $score = $class->exist(
                    {   author_id => $obj->author_id,
                        object_id => $obj->object_id,
                        object_ds => $obj->object_ds,
                    }
                );
                $exists = 1 if $score;
            }
            elsif ( 'field' eq $name ) {

                # Available in propack only
                if ( $obj->blog_id == 0 ) {
                    my $field = $class->exist(
                        {   blog_id  => 0,
                            basename => $obj->basename,
                        }
                    );
                    $exists = 1 if $field;
                }
            }
            elsif ( 'role' eq $name ) {
                my $role = $class->load( { name => $obj->name } );
                if ($role) {
                    my $old_perms = join '',
                        sort { $a <=> $b } split( ',', $obj->permissions );
                    my $cur_perms = join '',
                        sort { $a <=> $b } split( ',', $role->permissions );
                    if ( $old_perms eq $cur_perms ) {
                        $self->{objects}->{"$class#$old_id"} = $role;
                        $exists = 1;
                    }
                    else {

                        # restore in a different name
                        my $i        = 1;
                        my $new_name = $obj->name . " ($i)";
                        while ( $class->exist( { name => $new_name } ) ) {
                            $new_name = $obj->name . ' (' . ++$i . ')';
                        }
                        $obj->name($new_name);
                        MT->log(
                            {   message => MT->translate(
                                    "The role '[_1]' has been renamed to '[_2]' because a role with the same name already exists.",
                                    $role->name,
                                    $new_name
                                ),
                                level    => MT::Log::INFO(),
                                class    => 'system',
                                category => 'restore',
                            }
                        );
                    }
                }
            }
            elsif ( 'filter' eq $name ) {
                my $objects = $self->{objects};

                # Callback for restoring ID in the filter items
                MT->run_callbacks( 'restore_filter_item_ids', $obj, undef,
                    $objects );
            }
            elsif ( 'plugindata' eq $name ) {

                # Skipping System level plugindata
                # when it was found in the database.

                if ( $obj->key !~ /^configuration:blog:(\d+)$/i ) {
                    if ( my $obj
                        = MT->model('plugindata')
                        ->load( { key => $obj->key, } ) )
                    {
                        $exists = 1;
                        $self->{callback}->("\n");
                        $self->{callback}->(
                            MT->translate(
                                "The system level settings for plugin '[_1]' already exist.  Skipping this record.",
                                $obj->plugin
                            )
                        );
                    }
                }
            }
# PATCH
if ( 'powercmsconfig' eq $name ) {
    my $cfg_class = MT->model( 'powercmsconfig' );
    if ( my $cfg = $cfg_class->load() ) {
        $self->{objects}->{"$class#@{[ $cfg->id ]}"} = $cfg;
        $self->{records} = $self->{records} + 1;
    }
    $exists = 1;
}
# /PATCH
            unless ($exists) {
                my $result;
                if ( $obj->id ) {
                    $result = $obj->update();
                }
                else {
                    $result = $obj->insert();
                }
                if ($result) {
                    if ( $class =~ /MT::Asset(::.+)*/ ) {
                        $class = 'MT::Asset';
                    }
                    $self->{objects}->{"$class#$old_id"} = $obj;
                    my $records = $self->{records};
                    $self->{callback}->(
                        $self->{state} . " "
                            . MT->translate(
                            "[_1] records restored...", $records
                            ),
                        $data->{LocalName}
                    ) if $records && ( $records % 10 == 0 );
                    $self->{records} = $records + 1;
                    my $cb = "restored.$name";
                    $cb .= ":$ns"
                        if MT::BackupRestore::NS_MOVABLETYPE() ne $ns;
                    MT->run_callbacks( $cb, $obj, $self->{callback} );
                    $obj->call_trigger( 'post_save', $obj );
                }
                else {
                    push @{ $self->{errors} }, $obj->errstr;
                    $self->{callback}->( $obj->errstr );
                }
            }
            delete $self->{current};
        }
    }
};


*MT::BackupRestore::BackupFileHandler::start_element = sub {
    my $self = shift;
    my $data = shift;

    return if $self->{skip};

    my $name  = $data->{LocalName};
    my $attrs = $data->{Attributes};
    my $ns    = $data->{NamespaceURI};

    if ( $self->{start} ) {
        die MT->translate(
            'Uploaded file was not a valid Movable Type backup manifest file.'
            )
            if !(      ( 'movabletype' eq $name )
                    && ( MT::BackupRestore::NS_MOVABLETYPE() eq $ns )
            );

        #unless ($self->{ignore_schema_conflicts}) {
        my $schema = $attrs->{'{}schema_version'}->{Value};

#if (('ignore' ne $self->{schema_version}) && ($schema > $self->{schema_version})) {
        if ( $schema != $self->{schema_version} ) {
            $self->{critical} = 1;
            my $message = MT->translate(
                'Uploaded file was backed up from Movable Type but the different schema version ([_1]) from the one in this system ([_2]).  It is not safe to restore the file to this version of Movable Type.',
                $schema, $self->{schema_version}
            );
            MT->log(
                {   message  => $message,
                    level    => MT::Log::ERROR(),
                    class    => 'system',
                    category => 'restore',
                }
            );
            die $message;
        }

        #}
        $self->{start} = 0;
        return 1;
    }

    my $objects  = $self->{objects};
    my $deferred = $self->{deferred};
    my $callback = $self->{callback};

    if ( my $current = $self->{current} ) {

        # this is an element for a text column of the object
        $self->{current_text} = [$name];
    }
    else {
        if ( MT::BackupRestore::NS_MOVABLETYPE() eq $ns ) {
            my $class = MT->model($name);
            unless ($class) {
# PATCH
unless ( $self->{ current_class } eq 'ContactForm::ContactForm' || $name =~ /^(?:mtml|options)$/ ) {
# /PATCH
                push @{ $self->{errors} },
                    MT->translate(
                    '[_1] is not a subject to be restored by Movable Type.',
                    $name );
# PATCH
}
# /PATCH
            }
            else {
                if ( $self->{current_class} ne $class ) {
                    if ( my $c = $self->{current_class} ) {
                        my $state   = $self->{state};
                        my $records = $self->{records};
                        $callback->(
                            $state . " "
                                . MT->translate(
                                "[_1] records restored.", $records
                                ),
                            $c->class_type || $c->datasource
                        );
                    }
                    $self->{records}       = 0;
                    $self->{current_class} = $class;
                    my $state
                        = MT->translate( 'Restoring [_1] records:', $class );
                    $callback->( $state, $name );
                    $self->{state} = $state;
                }
                my %column_data
                    = map { $attrs->{$_}->{LocalName} => $attrs->{$_}->{Value} }
                    keys(%$attrs);
                my $obj;
                if ( 'author' eq $name ) {
                    $obj = $class->load( { name => $column_data{name} } );
                    if ($obj) {
                        if ( UNIVERSAL::isa( MT->instance, 'MT::App' )
                            && ( $obj->id == MT->instance->user->id ) )
                        {
                            MT->log(
                                {   message => MT->translate(
                                        "User with the same name as the name of the currently logged in ([_1]) found.  Skipped the record.",
                                        $obj->name
                                    ),
                                    level => MT::Log::INFO(),
                                    metadata =>
                                        'Permissions and Associations have been restored.',
                                    class    => 'system',
                                    category => 'restore',
                                }
                            );
                            $objects->{ "$class#" . $column_data{id} } = $obj;
                            $objects->{ "$class#" . $column_data{id} }
                                ->{no_overwrite} = 1;
                            $self->{current} = $obj;
                            $self->{loaded}  = 1;
                            $self->{skip} += 1;
                        }
                        else {
                            MT->log(
                                {   message => MT->translate(
                                        "User with the same name '[_1]' found (ID:[_2]).  Restore replaced this user with the data backed up.",
                                        $obj->name,
                                        $obj->id
                                    ),
                                    level => MT::Log::INFO(),
                                    metadata =>
                                        'Permissions and Associations have been restored as well.',
                                    class    => 'system',
                                    category => 'restore',
                                }
                            );
                            my $old_id = delete $column_data{id};
                            $objects->{"$class#$old_id"} = $obj;
                            $objects->{"$class#$old_id"}->{no_overwrite} = 1;
                            delete $column_data{userpic_asset_id}
                                if exists $column_data{userpic_asset_id};

                            my $child_classes
                                = $obj->properties->{child_classes} || {};
                            for my $class ( keys %$child_classes ) {
                                eval "use $class;";
                                $class->remove(
                                    { author_id => $obj->id, blog_id => '0' }
                                );
                            }
                            my $success
                                = $obj->restore_parent_ids( \%column_data,
                                $objects );
                            if ($success) {
                                my %realcolumns = map {
                                    $_ =>
                                        _decode( delete( $column_data{$_} ) )
                                } @{ $obj->column_names };
                                $obj->set_values( \%realcolumns );
                                $obj->$_( $column_data{$_} )
                                    foreach keys(%column_data);
                                $obj->column( 'external_id',
                                    $realcolumns{external_id} )
                                    if defined $realcolumns{external_id};
                                $self->{current} = $obj;
                            }
                            else {
                                $deferred->{ $class . '#' . $column_data{id} }
                                    = 1;
                                $self->{deferred} = $deferred;
                                $self->{skip} += 1;
                            }
                            $self->{loaded} = 1;
                        }
                    }
                }
                elsif ( 'template' eq $name ) {
                    if ( !$column_data{blog_id} ) {
                        $obj = $class->load(
                            {   blog_id => 0,
                                (   $column_data{identifier}
                                    ? ( identifier =>
                                            $column_data{identifier} )
                                    : ( name => $column_data{name} )
                                ),
                            }
                        );
                        if ($obj) {
                            my $old_id = delete $column_data{id};
                            $objects->{"$class#$old_id"} = $obj;
                            if ( $self->{overwrite_template} ) {
                                my %realcolumns = map {
                                    $_ =>
                                        _decode( delete( $column_data{$_} ) )
                                } @{ $obj->column_names };
                                $obj->set_values( \%realcolumns );
                                $obj->$_( $column_data{$_} )
                                    foreach keys(%column_data);
                                $self->{current} = $obj;
                                $self->{loaded}  = 1;
                            }
                            else {
                                $self->{skip} += 1;
                            }
                        }
                    }
                }
                elsif ( 'filter' eq $name ) {
                    if ($objects->{ "MT::Author#"
                                . $column_data{author_id} } )
                    {
                        $obj = $class->load(
                            {   author_id => $column_data{author_id},
                                label     => $column_data{label},
                                object_ds => $column_data{object_ds},
                            }
                        );
                        if ($obj) {
                            $obj->restore_parent_ids( \%column_data,
                                $objects );
                            my $old_id = $column_data{id};
                            $objects->{"$class#$old_id"} = $obj;
                            $self->{current}             = $obj;
                            $self->{loaded}              = 1;

                            $self->{skip} += 1;
                        }
                    }
                }

                unless ($obj) {
                    $obj = $class->new;
                }
                unless ( $obj->id ) {

                    # Pass through even if an blog doesn't restore
                    # the parent object
                    my $success
                        = $obj->restore_parent_ids( \%column_data, $objects );
# Patch
if ( $success == 99 ) { # skip
    $self->{skip} += 1;
} else {
# /Patch
                    if ( $success || ( !$success && 'blog' eq $name ) ) {
                        require MT::Meta;
                        my @metacolumns
                            = MT::Meta->metadata_by_class( ref($obj) );
                        my %metacolumns
                            = map { $_->{name} => $_->{type} } @metacolumns;
                        $self->{metacolumns}{ ref($obj) } = \%metacolumns;
                        my %realcolumn_data
                            = map { $_ => _decode( $column_data{$_} ) }
                            grep { !exists( $metacolumns{$_} ) }
                            keys %column_data;

                        if ( !$success && 'blog' eq $name ) {
                            $realcolumn_data{parent_id} = undef;
                        }

                        $obj->set_values( \%realcolumn_data );
                        $obj->column( 'external_id',
                            $realcolumn_data{external_id} )
                            if $name eq 'author'
                                && defined $realcolumn_data{external_id};
                        foreach my $metacol ( keys %metacolumns ) {
                            next
                                if ( 'vclob' eq $metacolumns{$metacol} )
                                || ( 'vblob' eq $metacolumns{$metacol} );
                            $obj->$metacol( $column_data{$metacol} );
                        }
                        $self->{current} = $obj;
                    }
                    else {
                        $deferred->{ $class . '#' . $column_data{id} } = 1;
                        $self->{deferred} = $deferred;
                        $self->{skip} += 1;
                    }
# Patch
}
# /Patch
                }
            }
        }
        else {
            my $obj = MT->run_callbacks( "Restore.$name:$ns",
                $data, $objects, $deferred, $callback );
            $self->{current} = $obj if defined($obj) && ( '1' ne $obj );
        }
    }
    1;
};


package ExtFields::Extfields;

sub parents {
    my $obj = shift;
    return {
        entry_id => [ MT->model( 'entry' ), MT->model( 'page' ) ],
        blog_id  => [ MT->model( 'blog' ),  MT->model( 'website' ) ],
        asset_id  => MT->model( 'asset' ),
    };
}

# for PowerCMS
package MT::ObjectTag;
*MT::ObjectTag::parents = sub {
    my $obj = shift;
    {   blog_id   => [ MT->model( 'blog' ), MT->model( 'website' ) ],
        tag_id    => MT->model( 'tag' ),
        object_id => {
            relations => {
                key      => 'object_datasource',
                entry_id => [ MT->model( 'entry' ), MT->model( 'page' ) ],
# Patch
                campaign_id => MT->model( 'campaign' ),
                link_id => MT->model( 'link' ),
# /Patch
            }
        }
    };
};

# for PowerCMS.pack
package MT::Blog;
sub restore_blob {
    my $obj = shift;
    my ( $column_name, $data, $objects ) = @_;
    if ( $column_name eq 'powercms_config' && ref $data eq 'REF'  ) {
        require MT::Serialize;
        $$data = MT::Serialize->serialize( $data );
    }
    1;
}

# for TemplateSelector
package MT::Template;
*MT::Template::parents = sub {
    my $obj = shift;
    {   blog_id => [ MT->model('blog'), MT->model('website') ],
# Patch
        default_entry_id => [ MT->model( 'entry' ), MT->model( 'page' ) ],
# /Patch
    };
};

# for EntryWorkflow
package MT::Entry;
*MT::Entry::parents = sub {
    my $obj = shift;
    {   blog_id => [ MT->model('blog'), MT->model('website') ],
        author_id =>
            { class => MT->model('author'), optional => 1, orphanize => 1 },
# Patch
        creator_id => {
            class => MT->model('author'),
            optional => 1,
        },
        owner_id => {
            class => MT->model('author'),
            optional => 1,
        },
# /Patch
    };
};

sub restore_parent_ids {
    my $obj = shift;
    my ( $data, $objets ) = @_;
    
    my $result = $obj->SUPER::restore_parent_ids( @_ );
    
    my $text = $data->{ approver_ids };
    if ( $text ) {
        my @approver_ids = split( /,/, $text );
        my @new_approver_ids;
        foreach my $approver_id ( @approver_ids ) {
            my $new_author = $objets->{ 'MT::Author#' . $approver_id };
            push( @new_approver_ids, $new_author->id ) if $new_author;
        }
        $data->{ approver_ids } = join( ',', @new_approver_ids );
    }
    
    $result;
}

package MT::Permission;

sub restore_parent_ids {
    my $obj = shift;
    my ( $data, $objets ) = @_;
    
    my $result = $obj->SUPER::restore_parent_ids( @_ );
    
    my $text = $data->{ categories };
    if ( $text ) {
        my @cateogry_ids = split( /,/, $text );
        my @new_cateogry_ids;
        foreach my $category_id ( @cateogry_ids ) {
            my $new_category = $objets->{ 'MT::Category#' . $category_id };
            push( @new_cateogry_ids, $new_category->id ) if $new_category;
        }
        $data->{ categories } = join( ',', @new_cateogry_ids );
    }
    
    $result;
}

package MT::ObjectAsset;

sub _restore_id {
    my $obj = shift;
    my ( $key, $val, $data, $objects ) = @_;

    return 0 unless 'ARRAY' eq ref($val);
    return 1 if 0 == $data->{$key};

    my $new_obj;
    my $old_id = $data->{$key};
    foreach (@$val) {
        $new_obj = $objects->{"$_#$old_id"};
        if ( ! $new_obj && $data->{ 'object_ds' } && $data->{ 'object_ds' } eq 'customobject' ) {
            my $custom_objects = MT->registry( 'custom_objects' );
            for my $class ( keys( %$custom_objects ) ) {
                $new_obj = $objects->{ MT->model( $class ) . "#$old_id"};
                last if $new_obj;
            }
        }
        last if $new_obj;
    }
    return 0 unless $new_obj;
    $data->{$key} = $new_obj->id;
    return 1;
}

package MT::FileInfo;

sub backup_terms_args {
    my $class = shift;
    my ( $blog_ids ) = @_;
    my @valid_blog_ids = ();
    
    if ( defined($blog_ids) && scalar(@$blog_ids) ) {
        foreach my $blog_id ( @$blog_ids ) {
            next unless $blog_id;
            my $blog = MT->model( 'blog' )->load( $blog_id );
            next unless $blog;
            push @valid_blog_ids, $blog->id;
        }
    } else {
        my @blogs = MT->model( 'blog' )->load( { class => '*' }, undef );
        foreach my $blog ( @blogs ) {
            push @valid_blog_ids, $blog->id;
        }
    }
    
    return {
        terms => { 'blog_id' => \@valid_blog_ids },
        args  => undef,
    };
}

1;
