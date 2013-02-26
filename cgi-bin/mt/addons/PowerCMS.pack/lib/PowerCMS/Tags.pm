package PowerCMS::Tags;

use strict;
use PowerCMS::Util qw( powercms_files_dir powercms_files_dir_path is_application is_cms );

sub _hdlr_if_cms {
    my ( $ctx, $args, $cond ) = @_;
    my $app = MT->instance();
    return is_cms( $app ) ? 1 : 0;
}

sub _hdlr_if_secure {
    my ( $ctx, $args, $cond ) = @_;
    my $app = MT->instance();
    return $app->is_secure;
}

sub _hdlr_maxupload { MT->config->CGIMaxUpload || 20_480_000 }

sub _hdlr_cms_param {
    my ( $ctx, $args, $cond ) = @_;
    my $app = MT->instance();
    return '' unless is_cms( $app );
    return '' unless $args->{ 'name' };
    if ( defined $app->param( $args->{ 'name' } ) ) {
        return $app->param( $args->{ 'name' } );
    }
    return '';
}

sub _hdlr_if_cms_param {
    my ( $ctx, $args, $cond ) = @_;
    my $app = MT->instance();
    return 0 unless is_cms( $app );
    return 0 unless $args->{ 'name' };
    if ( defined $app->param( $args->{ 'name' } ) ) {
        return 1;
    }
    return 0;
}

sub _hdlr_if_user_role {
    my ( $ctx, $args, $cond ) = @_;
    my $app = MT->instance();
    return 0 unless is_cms( $app );
    return 0 unless $app->user;
    my $author = $app->user;
    if ( my $author_id = $args->{ author_id } ) {
        $author = MT->model( 'author' )->load( { id => $author_id } );
    }
    return 0 unless $author;
    if ( $args->{ include_superuser } ) {
        return 1 if $author->is_superuser;
    }
    my $blog_id = $args->{ blog_id };
    unless ( $blog_id ) {
        $blog_id = ( $app->blog ? $app->blog->id : 0 );
    }
    return 0 unless $args->{ 'role' };
    my $role = MT->model( 'role' )->load( { name => $args->{ 'role' } } );
    if ( $role ) {
        my $association = MT::Association->load( { author_id => $author->id,
                                                   blog_id => $blog_id,
                                                   role_id => $role->id,
                                                 } );
        if ( $association ) {
            return 1;
        }
    }
    return 0;
}

sub _hdlr_entry_is_in_category {
    my ( $ctx, $args, $cond ) = @_;
    my $entry    = $ctx->stash('entry');
    my $category = $ctx->stash('category');
    return 0 unless defined $entry;
    return 0 unless defined $category;
    return 1 if $entry->is_in_category( $category );
    return 0;
}

# override default tag
sub _hdlr_entry_status {
    my $e = $_[0]->stash( 'entry' )
        or return $_[0]->_no_entry_error( $_[0]->stash( 'tag' ) );
    my %entry_status = (
        1   =>  'Draft',
        2   =>  'Publish',
        3   =>  'Review',
        4   =>  'Future',
        6   =>  'Prepublish',
        7   =>  'Template',
    );
    $entry_status{ $e->status };
}

sub _hdlr_powercms_version { MT->component( 'PowerCMS' )->version }

sub _hdlr_powercms_edition {
    my ( $ctx, $args, $cond ) = @_;
    if ( my $plugin_enterprise = MT->component( 'PowerCMSEnterprise' ) ) {
        return $plugin_enterprise->name;
    }
    if ( my $plugin_professional = MT->component( 'PowerCMSProfessional' ) ) {
        return $plugin_professional->name;
    }
    return MT->component( 'PowerCMS' )->name;
}

sub _hdlr_table_column_value {
    my ( $ctx, $args, $cond ) = @_;
    my $stash = $ctx->stash( $args->{ stash } ) || return '';
    my $model = $args->{ class } || $args->{ stash } || return '';
    my $column = $args->{ column } || return '';
    return if ( $model eq 'author' );
    return '' if ( $column =~ /password/ );
    if ( MT->model( $model )->has_column( $column ) ) {
        return $stash->$column if $stash->$column;
    }
    return '';
}

sub _hdlr_cms_context {
    my ( $ctx, $args, $cond ) = @_;
    my $r = MT::Request->instance;
    my $app = MT->instance();
    my $author = $app->user;
    my $blog = $app->blog;
    my $q = $app->param;
    my $type = $q->param( '_type' );
    my $mode = $q->param( '__mode' );
    my $reedit = $q->param( 'reedit' );
    my $id = $q->param( 'id' );
    my $tokens = $ctx->stash( 'tokens' );
    my $builder = $ctx->stash( 'builder' );
    local $ctx->{__stash}{ blog } = $blog;
    local $ctx->{__stash}{ blog_id } = $blog->id if $blog;
    my $class = MT->model( $type );
    my $entry = $r->cache( 'cms_cache_entry' );
    unless ( defined $entry ) {
        $entry = $class->load( $id ) if ( ( $id ) && ( $mode eq 'view' )
                                                    && ( ( $type eq 'entry') || ( $type eq 'page') ) );
        $r->cache( 'cms_cache_entry', $entry ) if ( $entry );
    }
    $entry = $class->new if ( (! $id ) && ( $mode eq 'view' )
                                          && ( ( $type eq 'entry') || ( $type eq 'page') ) );
    if ( defined $entry ) {
        if ( $reedit ) {
            my @clumns = $entry->column_names;
            for my $key ( $q->param ) {
                if ( grep( /^$key$/, @clumns ) ) {
                    $entry->$key( $q->param ( $key ) );
                } else {
                    if ( $key eq 'tags' ) {
                        my $tag_delim = chr( $author->entry_prefs->{ tag_delim } );
                        my @tags = MT::Tag->split( $tag_delim, $q->param ( $key ) );
                        $entry->set_tags( @tags );
                    }
                }
            }
        }
    }
    my $category = $r->cache( 'cms_cache_category' );
    unless ( defined $category ) {
        $category = $class->load( $id ) if ( ( $id ) && ( $mode eq 'view' )
                                          && ( ( $type eq 'category') || ( $type eq 'folder') ) );
        $r->cache( 'cms_cache_category', $category ) if ( $category );
    }
    local $ctx->{ __stash }{ entry } = $entry if ( defined $entry );
    local $ctx->{ __stash }{ category } = $category if ( $type eq 'category' );
    local $ctx->{ __stash }{ folder } = $category if ( $type eq 'folder' );
    local $ctx->{ __stash }{ author } = $app->user;
    my $out = $builder->build( $ctx, $tokens, $cond );
    $out;
}

sub _hdlr_set_loop {
    my ( $text, $arg, $ctx ) = @_;
    my ( $name, $sep, $func );
    if ( ref $arg && ref $arg eq 'ARRAY' ) {
        ( $name, $sep, $func ) = ( $$arg[ 0 ], $$arg[ 1 ], $$arg[ 2 ] );
    } else {
        $name = $arg;
    }
    return '' unless $name;
    if ( $text ) {
        $sep ||= ',';
        my @datas = split( /$sep/, $text );
        my $data = $ctx->var( $name );
        if ( defined $func ) {
            if ( 'undef' eq lc( $func ) ) {
                $data = undef;
                $ctx->var( $name, $data );
            }
            else {
                $data ||= [];
                return $ctx->error( MT->translate( "'[_1]' is not an array.", $name ) )
                    unless 'ARRAY' eq ref( $data );
                if ( 'push' eq lc( $func ) ) {
                    push @$data, @datas;
                }
                elsif ( 'unshift' eq lc( $func ) ) {
                    $data ||= [];
                    unshift @$data, @datas;
                }
                else {
                    return $ctx->error(
                        MT->translate( "'[_1]' is not a valid function.", $func )
                    );
                }
                $ctx->var( $name, $data );
            }
        } else {
            $ctx->var( $name, \@datas );
        }
    }
    return '';
}

sub _hdlr_table2tag {
    my( $text, $arg, $ctx ) = @_;
    if ( $text =~ /<!--NO_TABLE2TAG-->/i ) {
        $text =~ s/<!--NO_TABLE2TAG-->//ig;
        return $text;
    }
    if ( $arg ne '1' ) {
        my @tag = split( /,/, $arg );
        if ( $tag[0] ) {
            $text =~ s/<table.*?>(.*?)<\/table>/<$tag[0]>$1<\/$tag[0]>/isg;
        } else {
            $text =~ s/<table.*?>(.*?)<\/table>/$1/isg;
        }
        if ( $tag[1] ) {
            $text =~ s/<tr.*?>(.*?)<\/tr>/<$tag[1]>$1<\/$tag[1]>/isg;
        } else {
            $text =~ s/<tr.*?>(.*?)<\/tr>/$1/isg;
        }
        if ( $tag[2] ) {
            $text =~ s/<td.*?>(.*?)<\/td>/<$tag[2]>$1<\/$tag[2]>/isg;
        } else {
            $text =~ s/<td.*?>(.*?)<\/td>/$1/isg;
        }
        if ( $tag[3] ) {
            $text =~ s/<thead.*?>(.*?)<\/thead>/<$tag[3]>$1<\/$tag[3]>/isg;
        } else {
            $text =~ s/<thead.*?>(.*?)<\/thead>/$1/isg;
        }
        if ( $tag[4] ) {
            $text =~ s/<tfoot.*?>(.*?)<\/tfoot>/<$tag[4]>$1<\/$tag[4]>/isg;
        } else {
            $text =~ s/<tfoot.*?>(.*?)<\/tfoot>/$1/isg;
        }
        if ( $tag[5] ) {
            $text =~ s/<caption.*?>(.*?)<\/caption>/<$tag[5]>$1<\/$tag[5]>/isg;
        } else {
            $text =~ s/<caption.*?>(.*?)<\/caption>/$1/isg;
        }
    } else {
        $text =~ s/<table.*?>(.*?)<\/table>/$1/isg;
        $text =~ s/<tr.*?>(.*?)<\/tr>/$1/isg;
        $text =~ s/<td.*?>(.*?)<\/td>/$1/isg;
        $text =~ s/<thead.*?>(.*?)<\/thead>/$1/isg;
        $text =~ s/<tfoot.*?>(.*?)<\/tfoot>/$1/isg;
        $text =~ s/<caption.*?>(.*?)<\/caption>/$1/isg;
    }
    return $text;
}

sub _hdlr_tabsplitdata {
    my ( $ctx, $args, $cond ) = @_;
    my $tokens = $ctx->stash( 'tokens' );
    my $builder = $ctx->stash( 'builder' );
    my $obj = $args->{ object };
    my $column = $args->{ column };
    my $object;
    if ( $obj eq 'blog' ) {
        $object = $ctx->stash( 'blog' );
    } elsif ( $obj eq 'category' ) {
        $object = $ctx->stash( 'category' );
    } elsif ( $obj eq 'entry' ) {
        $object = $ctx->stash( 'entry' );
    }
    if ( $object ) {
        if ( $object->has_column( $column ) ) {
            if ( my $text = $object->$column ) {
                my @lines = split( /\r\n|[\r\n]/, $text );
                my $res = '';
                for my $line ( @lines ) {
                    local $ctx->{ __stash }{ 'line' } = $line;
                    my $out = $builder->build( $ctx, $tokens, $cond );
                    $res .= $out;
                }
                return $res;
            }
        }
    }
    return '';
}

sub _hdlr_tabsplitline {
    my ( $ctx, $args, $cond ) = @_;
    my $line = $ctx->stash( 'line' );
    if ( $line ) {
        my $field = $args->{ field };
        if ( $field && $field =~ /^\d{1,}$/ ) {
            $field--;
            my @items = split( /\t/, $line );
            return $items[ $field ];
        }
    }
    return '';
}

sub _hdlr_pass_tokens {
    my ( $ctx, $args, $cond ) = @_;
    $ctx->stash( 'builder' )->build( $ctx, $ctx->stash( 'tokens' ), $cond );
}

sub _hdlr_if_dir_available {
    return powercms_files_dir();
}

sub _hdlr_powercms_files_dir {
    return MT->config->PowerCMSFilesDir || powercms_files_dir_path();
}

sub _hdlr_this_url {
    my ( $ctx, $args, $cond ) = @_;
    my $app = MT->instance;
    my $this_url = $app->uri;
    if ( $args->{ include_base } ) {
        $this_url = $app->base . $this_url;
    }
    if ( my $q = $app->query_string ) {
        my $qs = join '&',
                 grep !/^(?:password|username|magic_token)=/,
                 split /\s*;\s*/, $q;
        $qs &&= "?$qs";
        $this_url .= $qs;
    }
    return $this_url;
}

sub _hdlr_if_module {
    my ( $ctx, $args, $cond ) = @_;
    my $module = $args->{ module };
    $module =~ s/\s+//g;
    if ( $module ) {
        die  "Invalid module name " . $module if $module =~ /[^\w:]/;
        eval "require $module";
        if (! $@ ) {
            return 1;
        }
    }
    return 0;
}

sub _hdlr_if_component {
    my ( $ctx, $args, $cond ) = @_;
    my $component = $args->{ component };
    $component = $args->{ plugin } unless $component;
    if ( $component ) {
        my $plugin = MT->component( $component );
        return 1 if $plugin;
    }
    return 0;
}

sub _hdlr_plugin_setting {
    my ( $ctx, $args, $cond ) = @_;
    if ( my $setting_name = $args->{ name } ) {
        my $component = ( $args->{ component } ? MT->component( $args->{ component } ) : MT->component( 'PowerCMS' ) );
        if ( $component ) {
            my $scope = ( $args->{ blog_id } ? 'blog:' . $args->{ blog_id } : 'system' );
            return $component->get_config_value( $setting_name, $scope ) || '';
        }
    }
    return '';
}

sub _hdlr_if_can {
    my ( $ctx, $args, $cond ) = @_;
    my $app = MT->instance;
    my $user = $app->user;
    return 0 unless defined $user;
    my $perm = $user->is_superuser;
    return 1 if $perm;
    my $permission = $args->{ permission };
    return 0 unless $permission;
    $permission = 'can_' . $permission;
    my $blog = $ctx->stash( 'blog' );
    my $blog_id = $args->{ blog_id };
    if ( defined( $blog_id ) && $blog_id =~ m/^\d+$/ ) {
        $perm = $user->permissions( $blog_id )->$permission;
    } elsif ( $blog ) {
        $perm = $user->permissions( $blog->id )->$permission;
    }
    return $perm;
}

sub _hdlr_if_ie {
    my ( $ctx, $args, $cond ) = @_;
    my $app = MT->instance(); return 0 if (! is_application( $app ) );
    my $user_agent = $app->get_header( 'User-Agent' );
    if ( $user_agent =~ /Windows/ ) {
        if ( $user_agent =~ /; MSIE (([1-9]\d+)\.\d+);/ ) {
            $ctx->{ __stash }{ vars }{ ie_version_id } = $1;
            $ctx->{ __stash }{ vars }{ ie_version }    = $2;
            return 1;
        }
    }
    return 0;
}

sub _filter_tab2table {
    my ( $text, $arg, $ctx ) = @_;
    my $textformat = $arg;
    if ( $textformat && $textformat =~ /^\d{1,}$/ ) {
        my @lines = split( /\r\n|[\r\n]/, $text, -1 );
        @lines = grep( ! /^$/, @lines );
        my $formatted_text = '<table>' . "\n";
        if ( $textformat == 2 or $textformat == 4 ) {
            $formatted_text .= '<tr>';
            my @values = split( /\t/, shift( @lines ), -1 );
            foreach ( @values ) {
                $formatted_text .= '<th>' . $_ . '</th>';
            }
            $formatted_text .= '</tr>' . "\n";
        }
        foreach ( @lines ) {
            $formatted_text .= '<tr>';
            my @values = split( /\t/, $_, -1 );
            if ( $textformat == 3 or $textformat == 4 ) {
                $formatted_text .= '<th>'. shift( @values ) . '</th>';
            }
            foreach ( @values ) {
                $formatted_text .= '<td>' . $_ . '</td>';
            }
            $formatted_text .= '</tr>' . "\n";
        }
        $formatted_text .= '</table>' . "\n";
        $text = $formatted_text;
    }
    return $text;
}

sub _fltr_strip_emptylines {
    my ( $text ) = @_;
    $text =~ s/^[ \n\r\t\f]*(?:\r\n|[\r\n]|\z)//mg;
    return $text;
}

sub _filter_translate_templatized {
    my $text = shift;
    my $app = MT->instance();
    $text = $app->translate_templatized( $text );
    return $text;
}

sub _hdlr_members_only {
    my ( $ctx, $args, $cond ) = @_;
    my $blog = $ctx->stash('blog');
    if( $blog->has_column('is_members') ){
        return 1 if $blog->is_members;
    }
    return '0';
}

1;
