package CustomObject::Patch;
use strict;

use MT::Util qw( format_ts );

sub init {
    # Only for override.
    # Do nothing.
}

no warnings 'redefine';
require MT::CMS::Template;
*MT::CMS::Template::edit = sub {
    my $cb = shift;
    my ( $app, $id, $obj, $param ) = @_;

    my $q       = $app->param;
    my $blog_id = $q->param('blog_id');

    # FIXME: enumeration of types
    unless ($blog_id) {
        my $type = $q->param('type') || ( $obj ? $obj->type : '' );
        return $app->return_to_dashboard( redirect => 1 )
            if $type eq 'archive'
                || $type eq 'individual'
                || $type eq 'category'
                || $type eq 'page'
                || $type eq 'index';
    }

    my $blog = $app->blog;
    if ( defined $blog && !$blog->is_blog ) {
        my $type = $q->param('type') || ( $obj ? $obj->type : '' );
        return $app->return_to_dashboard( redirect => 1 )
        # PATCH
#             if $type eq 'archive'
#                 || $type eq 'individual';
            if $type eq 'individual';
        # /PATCH
    }

    # to trigger autosave logic in main edit routine
    $param->{autosave_support} = 1;

    my $type  = $q->param('_type');
    my $cfg   = $app->config;
    my $perms = $app->blog ? $app->permissions : $app->user->permissions;
    my $can_preview = 0;

    if ( $q->param('reedit') ) {
        $param->{'revision-note'} = $q->param('revision-note');
        if ( $q->param('save_revision') ) {
            $param->{'save_revision'} = 1;
        }
        else {
            $param->{'save_revision'} = 0;
        }
    }
    if ($blog) {

        # include_system/include_cache are only applicable
        # to blog-level templates
        $param->{include_system} = $blog->include_system;
        $param->{include_cache}  = $blog->include_cache;
    }

    if ( $obj && ( $obj->type eq 'widgetset' ) ) {
        return $app->redirect(
            $app->uri(
                'mode' => 'edit_widget',
                args   => { blog_id => $obj->blog_id, id => $obj->id }
            )
        );
    }

    if ($id) {
        if ( $blog && $blog->use_revision ) {
            my $rn = $q->param('r') || 0;
            if ( $obj->current_revision > 0 || $rn != $obj->current_revision )
            {
                my $rev = $obj->load_revision( { rev_number => $rn } );
                if ( $rev && @$rev ) {
                    $obj = $rev->[0];
                    my $values = $obj->get_values;
                    $param->{$_} = $values->{$_} foreach keys %$values;
                    $param->{loaded_revision} = 1;
                }
                $param->{rev_number} = $rn;
                $param->{rev_date}   = format_ts( "%Y-%m-%d %H:%M:%S",
                    $obj->modified_on, $blog,
                    $app->user ? $app->user->preferred_language : undef );
                $param->{no_snapshot} = 1 if $q->param('no_snapshot');
            }
        }
        $param->{nav_templates} = 1;
        my $tab;

        # FIXME: Template types should not be enumerated here
        if ( $obj->type eq 'index' ) {
            $tab = 'index';
            $param->{template_group_trans} = $app->translate('index');
        }
        elsif ($obj->type eq 'archive'
            || $obj->type eq 'individual'
            || $obj->type eq 'category'
            || $obj->type eq 'page' )
        {

            # FIXME: enumeration of types
            $tab = 'archive';
            $param->{template_group_trans} = $app->translate('archive');
        }
        elsif ( $obj->type eq 'custom' ) {
            $tab = 'module';
            $param->{template_group_trans} = $app->translate('module');
        }
        elsif ( $obj->type eq 'widget' ) {
            $tab = 'widget';
            $param->{template_group_trans} = $app->translate('widget');
        }
        elsif ( $obj->type eq 'email' ) {
            $tab = 'email';
            $param->{template_group_trans} = $app->translate('email');
        }
        elsif ( $obj->type eq 'backup' ) {
            $tab = 'backup';
            $param->{template_group_trans} = $app->translate('backup');
        }
        else {
            $tab = 'system';
            $param->{template_group_trans} = $app->translate('system');
        }
        $param->{template_group} = $tab;
        $blog_id = $obj->blog_id;

        # FIXME: enumeration of types
        $param->{has_name} 
            = $obj->type  eq 'index'
            || $obj->type eq 'custom'
            || $obj->type eq 'widget'
            || $obj->type eq 'archive'
            || $obj->type eq 'category'
            || $obj->type eq 'page'
            || $obj->type eq 'individual';
        if ( !$param->{has_name} ) {
            $param->{ 'type_' . $obj->type } = 1;
            $param->{name} = $obj->name;
        }
        $app->add_breadcrumb( $param->{name} );
        $param->{has_outfile} = $obj->type eq 'index';
        $param->{has_rebuild} = ( ( $obj->type eq 'index' )
                && ( ( $blog->custom_dynamic_templates || "" ) ne 'all' ) );

        # FIXME: enumeration of types
        $param->{is_special} 
            = $param->{type}  ne 'index'
            && $param->{type} ne 'archive'
            && $param->{type} ne 'category'
            && $param->{type} ne 'page'
            && $param->{type} ne 'individual';
        $param->{has_build_options} 
            = $param->{has_build_options}
            && $param->{type} ne 'custom'
            && $param->{type} ne 'widget'
            && !$param->{is_special};
        $param->{search_label} = $app->translate('Templates');
        $param->{object_type}  = 'template';
        my $published_url = $obj->published_url;
        $param->{published_url} = $published_url if $published_url;
        $param->{saved_rebuild} = 1 if $q->param('saved_rebuild');
        require MT::PublishOption;
        $param->{static_maps}
            = (    $obj->build_type != MT::PublishOption::DYNAMIC()
                && $obj->build_type != MT::PublishOption::DISABLED() );

        my $filter = $app->param('filter_key');
        if ( $param->{template_group} eq 'email' ) {
            $app->param( 'filter_key', 'email_templates' );
        }
        elsif ( $param->{template_group} eq 'system' ) {
            $app->param( 'filter_key', 'system_templates' );
        }
        elsif ( $obj->type eq 'backup' ) {
            $app->param( 'filter_key', 'backup_templates' );
        }
        $app->load_list_actions( 'template', $param );
        $app->param( 'filter_key', $filter );

        $obj->compile;
        if ( $obj->{errors} && @{ $obj->{errors} } ) {
            $param->{error} = $app->translate(
                "One or more errors were found in this template.");
            $param->{error} .= "<ul>\n";
            foreach my $err ( @{ $obj->{errors} } ) {
                $param->{error}
                    .= "<li>"
                    . MT::Util::encode_html( $err->{message} )
                    . "</li>\n";
            }
            $param->{error} .= "</ul>\n";
        }

        # Populate list of included templates
        foreach my $tag (qw( Include IncludeBlock )) {
            my $includes = $obj->getElementsByTagName($tag);
            if ($includes) {
                my @includes;
                my @widgets;
                my %seen;
                foreach my $tag (@$includes) {
                    my $include = {};
                    my $attr    = $tag->attributes;
                    my $mod     = $include->{include_module} = $attr->{module}
                        || $attr->{widget};
                    next unless $mod;
                    next if $mod =~ /^\$.*/;
                    my $type = $attr->{widget} ? 'widget' : 'custom';
                    if (   $tag->[1]->{blog_id}
                        && $tag->[1]->{blog_id} =~ m/^\$/ )
                    {
                        $include->{include_from} = 'error';
                        $include->{include_blog_name}
                            = $app->translate('Unknown blog');
                    }
                    else {
                        my $inc_blog_id
                            = $tag->[1]->{global}
                            ? 0
                            : $tag->[1]->{blog_id}
                            ? [ $tag->[1]->{blog_id}, 0 ]
                            : $tag->[1]->{parent} ? $obj->blog
                                ? $obj->blog->website->id
                                : 0
                            : [ $obj->blog_id, 0 ];

                        my $mod_id
                            = $mod . "::"
                            . (
                            ref $inc_blog_id
                            ? $inc_blog_id->[0]
                            : $inc_blog_id );
                        next if exists $seen{$type}{$mod_id};
                        $seen{$type}{$mod_id} = 1;

                        my $other = MT::Template->load(
                            {   blog_id => $inc_blog_id,
                                name    => $mod,
                                type    => $type,
                            },
                            {   limit => 1,
                                ref $inc_blog_id
                                ? ( sort      => 'blog_id',
                                    direction => 'descend',
                                    )
                                : ()
                            }
                        );

                        if ($other) {
                            $include->{include_link} = $app->mt_uri(
                                mode => 'view',
                                args => {
                                    blog_id => $other->blog_id || 0,
                                    '_type' => 'template',
                                    id      => $other->id
                                }
                            );
                            $include->{can_link}
                                = $app->user->is_superuser
                                || $app->user->permissions(0)
                                ->can_do('edit_templates')
                                ? 1
                                : $other->blog_id
                                ? $app->user->permissions( $other->blog_id )
                                ->can_do('edit_templates')
                                    ? 1
                                    : 0
                                : 0;

                            # Try to compile template module
                            # if using MTInclude in this template.
                            $other->compile;
                            if ( $other->{errors} && @{ $other->{errors} } ) {
                                $param->{error} = $app->translate(
                                    "One or more errors were found in included template module ([_1]).",
                                    $other->name
                                );
                                $param->{error} .= "<ul>\n";
                                foreach my $err ( @{ $other->{errors} } ) {
                                    $param->{error}
                                        .= "<li>"
                                        . MT::Util::encode_html(
                                        $err->{message} )
                                        . "</li>\n";
                                }
                                $param->{error} .= "</ul>\n";
                            }

                            if ( $other->blog_id ) {
                                if ( $other->blog_id eq $blog_id ) {
                                    $include->{include_from}      = 'self';
                                    $include->{include_blog_name} = 'self';
                                }
                                else {
                                    $include->{include_from}
                                        = $other->blog->is_blog
                                        ? 'blog'
                                        : 'website';
                                    $include->{include_blog_name}
                                        = $other->blog->name;
                                }
                            }
                            else {
                                $include->{include_from}
                                    = $blog_id
                                    ? 'global'
                                    : 'self';
                                $include->{include_blog_name}
                                    = $blog_id
                                    ? $app->translate('Global Template')
                                    : 'self';
                            }
                        }
                        else {
                            my $target_blog_id
                                = ref $inc_blog_id
                                ? $inc_blog_id->[0]
                                : $inc_blog_id;
                            $include->{create_link} = $app->mt_uri(
                                mode => 'view',
                                args => {
                                    blog_id => $target_blog_id,
                                    '_type' => 'template',
                                    type    => $type,
                                    name    => $mod,
                                }
                            );

                            my $target_blog;
                            $target_blog
                                = MT->model('blog')->load($target_blog_id)
                                if $target_blog_id;

                            if ($target_blog_id) {
                                if ($target_blog) {
                                    $include->{include_from}
                                        = $target_blog->id eq $blog_id
                                        ? 'self'
                                        : $target_blog->is_blog ? 'blog'
                                        :                         'website';
                                    $include->{include_blog_name}
                                        = $target_blog->name;
                                }
                                else {
                                    $include->{include_from} = 'error';
                                    $include->{include_blog_name}
                                        = $app->translate('Invalid Blog');
                                }
                            }
                            else {
                                $include->{include_from}
                                    = !$blog_id
                                    ? 'self'
                                    : 'global';
                                $include->{include_blog_name}
                                    = !$blog_id
                                    ? 'self'
                                    : $app->translate('Global Template');
                            }
                        }
                    }
                    if ( $type eq 'widget' ) {
                        push @widgets, $include;
                    }
                    else {
                        push @includes, $include;
                    }
                }

                push @{ $param->{include_loop} }, @includes if @includes;
                push @{ $param->{widget_loop} },  @widgets  if @widgets;
            }
        }
        my @sets = (
            @{ $obj->getElementsByTagName('WidgetSet') || [] },
            @{ $obj->getElementsByTagName('WidgetManager') || [] }
        );
        if (@sets) {
            my @widget_sets;
            my %seen;
            foreach my $set (@sets) {
                my $name = $set->attributes->{name};
                next unless $name;
                next if $seen{$name};
                $seen{$name} = 1;
                my $wset = MT::Template->load(
                    {   blog_id => [ $obj->blog_id, 0 ],
                        name    => $name,
                        type    => 'widgetset',
                    },
                    {   sort      => 'blog_id',
                        direction => 'descend',
                    }
                );
                if ($wset) {
                    my $include = {
                        include_link => $app->mt_uri(
                            mode => 'edit_widget',
                            args => {
                                blog_id => $wset->blog_id,
                                id      => $wset->id,
                            },
                        ),
                        include_module => $name,
                    };
                    $include->{include_from}
                        = $wset->blog_id ? 'self'
                        : $blog_id       ? 'global'
                        :                  'self';

                    my $inc_blog;
                    $inc_blog = MT->model('blog')->load( $wset->blog_id )
                        if $wset->blog_id;
                    $include->{include_blog_name}
                        = $inc_blog ? $inc_blog->name
                        : $blog_id  ? $app->translate('Global')
                        :             'self';
                    push @widget_sets, $include;
                }
                else {
                    push @widget_sets,
                        {
                        create_link => $app->mt_uri(
                            mode => 'edit_widget',
                            args => {
                                blog_id => $blog_id,
                                name    => $name
                            },
                        ),
                        include_module    => $name,
                        include_from      => 'self',
                        include_blog_name => $blog ? $blog->name : '',
                        };
                }
            }
            $param->{widget_set_loop} = \@widget_sets if @widget_sets;
        }
        $param->{have_includes} = 1
            if $param->{widget_set_loop}
                || $param->{include_loop}
                || $param->{widget_loop};

        # Populate archive types for creating new map
        my $obj_type = $obj->type;
        if (   $obj_type eq 'individual'
            || $obj_type eq 'page'
            || $obj_type eq 'author'
            || $obj_type eq 'category'
            || $obj_type eq 'archive' )
        {
            my @at = $app->publisher->archive_types;
            my @archive_types;
            for my $at (@at) {
                my $archiver      = $app->publisher->archiver($at);
                my $archive_label = $archiver->archive_label;
                $archive_label = $at unless $archive_label;
                $archive_label = $archive_label->()
                    if ( ref $archive_label ) eq 'CODE';
                if (   ( $obj_type eq 'archive' )
                    || ( $obj_type eq 'author' )
                    || ( $obj_type eq 'category' ) )
                {

                    # only include if it is NOT an entry-based archive type
                    next if $archiver->entry_based;
                }
                elsif ( $obj_type eq 'page' ) {

                   # only include if it is a entry-based archive type and page
                    next unless $archiver->entry_based;
                    next if $archiver->entry_class ne 'page';
                }
                elsif ( $obj_type eq 'individual' ) {

                  # only include if it is a entry-based archive type and entry
                    next unless $archiver->entry_based;
                    next if $archiver->entry_class eq 'page';
                }
                push @archive_types,
                    {
                    archive_type_translated => $archive_label,
                    archive_type            => $at,
                    };
                @archive_types
                    = sort { MT::App::CMS::archive_type_sorter( $a, $b ) }
                    @archive_types;
            }
            $param->{archive_types} = \@archive_types;

            # Populate template maps for this template
            # PATCH
#            my $maps = _populate_archive_loop( $app, $blog, $obj );
            my $maps = MT::CMS::Template::_populate_archive_loop( $app, $blog, $obj );
            # /PATCH
            if (@$maps) {
                $param->{object_loop} = $param->{template_map_loop} = $maps
                    if @$maps;
                my %at;
                foreach my $map (@$maps) {
                    $at{ $map->{archive_label} } = 1;
                    $param->{static_maps}
                        ||= (
                        $map->{map_build_type} != MT::PublishOption::DYNAMIC()
                            && $map->{map_build_type}
                            != MT::PublishOption::DISABLED() );
                }
                $param->{enabled_archive_types} = join( ", ", sort keys %at );
            }
            else {
                $param->{can_rebuild} = 0;
            }
        }

        # publish options
        $param->{build_type} = $obj->build_type;
        $param->{ 'build_type_' . ( $obj->build_type || 0 ) } = 1;

        #my ( $period, $interval ) = _get_schedule( $obj->build_interval );
        #$param->{ 'schedule_period_' . $period } = 1;
        #$param->{schedule_interval} = $interval;
        $param->{type} = 'custom' if $param->{type} eq 'module';
    }
    else {
        my $new_tmpl = $q->param('create_new_template');
        my $template_type;
        if ($new_tmpl) {
            if ( $new_tmpl =~ m/^blank:(.+)/ ) {
                $template_type = $1;
                $param->{type} = $1;
            }
            elsif ( $new_tmpl =~ m/^default:([^:]+):(.+)/ ) {
                $template_type = $1;
                $template_type = 'custom' if $template_type eq 'module';
                my $template_id = $2;
                my $set = $blog ? $blog->template_set : undef;
                require MT::DefaultTemplates;
                my $def_tmpl = MT::DefaultTemplates->templates($set) || [];
                my ($tmpl)
                    = grep { $_->{identifier} eq $template_id } @$def_tmpl;

                my $lang
                    = $blog_id
                    ? $blog->language
                    : MT->config->DefaultLanguage;
                my $current_lang = MT->current_language;
                MT->set_language($lang);
                $param->{text} = $app->translate_templatized( $tmpl->{text} )
                    if $tmpl;
                MT->set_language($current_lang);
                $param->{type} = $template_type;
            }
        }
        else {
            $template_type = $q->param('type');
            $template_type = 'custom' if 'module' eq $template_type;
            $param->{type} = $template_type;
        }
        return $app->errtrans("Create template requires type")
            unless $template_type;
        $param->{nav_templates} = 1;
        my $tab;

        # FIXME: enumeration of types
        if ( $template_type eq 'index' ) {
            $tab = 'index';
            $param->{template_group_trans} = $app->translate('index');
        }
        elsif ($template_type eq 'archive'
            || $template_type eq 'individual'
            || $template_type eq 'category'
            || $template_type eq 'page' )
        {
            $tab                           = 'archive';
            $param->{template_group_trans} = $app->translate('archive');
            $param->{type_archive}         = 1;
            my @types = (
                {   key   => 'archive',
                    label => $app->translate('Archive')
                },
                {   key   => 'individual',
                    label => $app->translate('Entry or Page')
                },
            );
            $param->{new_archive_types} = \@types;
        }
        elsif ( $template_type eq 'custom' ) {
            $tab = 'module';
            $param->{template_group_trans} = $app->translate('module');
        }
        elsif ( $template_type eq 'widget' ) {
            $tab = 'widget';
            $param->{template_group_trans} = $app->translate('widget');
        }
        else {
            $tab = 'system';
            $param->{template_group_trans} = $app->translate('system');
        }
        $param->{template_group} = $tab;
        $app->translate($tab);
        $app->add_breadcrumb( $app->translate('New Template') );

        # FIXME: enumeration of types
        $param->{has_name} 
            = $template_type  eq 'index'
            || $template_type eq 'custom'
            || $template_type eq 'widget'
            || $template_type eq 'archive'
            || $template_type eq 'category'
            || $template_type eq 'page'
            || $template_type eq 'individual';
        $param->{has_outfile} = $template_type eq 'index';
        $param->{has_rebuild} = ( ( $template_type eq 'index' )
                && ( ( $blog->custom_dynamic_templates || "" ) ne 'all' ) );
        $param->{custom_dynamic}
            = $blog && $blog->custom_dynamic_templates eq 'custom';
        $param->{has_build_options} = $blog
            && ( $blog->custom_dynamic_templates eq 'custom'
            || $param->{has_rebuild} );

        # FIXME: enumeration of types
        $param->{is_special} 
            = $param->{type}  ne 'index'
            && $param->{type} ne 'archive'
            && $param->{type} ne 'category'
            && $param->{type} ne 'page'
            && $param->{type} ne 'individual';
        $param->{has_build_options} 
            = $param->{has_build_options}
            && $param->{type} ne 'custom'
            && $param->{type} ne 'widget'
            && !$param->{is_special};
        $param->{name} = $app->param('name') if $app->param('name');
    }
    $param->{publish_queue_available}
        = eval 'require List::Util; require Scalar::Util; 1;';

    my $set = $blog ? $blog->template_set : undef;
    require MT::DefaultTemplates;
    my $tmpls = MT::DefaultTemplates->templates($set);
    my @tmpl_ids;
    foreach my $dtmpl (@$tmpls) {
        if ( !$param->{has_name} ) {
            if ( $obj->type eq 'email' ) {
                if ( $dtmpl->{identifier} eq $obj->identifier ) {
                    $param->{template_name_label} = $dtmpl->{label};
                    $param->{template_name}       = $dtmpl->{name};
                }
            }
            else {
                if ( $dtmpl->{type} eq $obj->type ) {
                    $param->{template_name_label} = $dtmpl->{label};
                    $param->{template_name}       = $dtmpl->{name};
                }
            }
        }
        if ( $dtmpl->{type} eq 'index' ) {
            push @tmpl_ids,
                {
                label    => $dtmpl->{label},
                key      => $dtmpl->{key},
                selected => $dtmpl->{key} eq
                    ( ( $obj ? $obj->identifier : undef ) || '' ),
                };
        }
    }
    $param->{index_identifiers} = \@tmpl_ids;

    $param->{"type_$param->{type}"} = 1;
    if ($perms) {
        my $pref_param = $app->load_template_prefs( $perms->template_prefs );
        %$param = ( %$param, %$pref_param );
    }

    # Populate structure for template snippets
    if ( my $snippets = $app->registry('template_snippets') || {} ) {
        my @snippets;
        for my $snip_id ( keys %$snippets ) {
            my $label = $snippets->{$snip_id}{label};
            $label = $label->() if ref($label) eq 'CODE';
            push @snippets,
                {
                id      => $snip_id,
                trigger => $snippets->{$snip_id}{trigger},
                label   => $label,
                content => $snippets->{$snip_id}{content},
                };
        }
        @snippets = sort { $a->{label} cmp $b->{label} } @snippets;
        $param->{template_snippets} = \@snippets;
    }

    # Populate structure for tag documentation
    my $all_tags = MT::Component->registry("tags");
    my $tag_docs = {};
    foreach my $tag_set (@$all_tags) {
        my $url = $tag_set->{help_url};
        $url = $url->() if ref($url) eq 'CODE';

        # hey, at least give them a google search
        $url ||= 'http://www.google.com/search?q=mt%t';
        my $tag_list = '';
        foreach my $type (qw( block function )) {
            my $tags = $tag_set->{$type} or next;
            $tag_list
                .= ( $tag_list eq '' ? '' : ',' ) . join( ",", keys(%$tags) );
        }
        $tag_list =~ s/(^|,)plugin(,|$)/,/;
        if ( exists $tag_docs->{$url} ) {
            $tag_docs->{$url} .= ',' . $tag_list;
        }
        else {
            $tag_docs->{$url} = $tag_list;
        }
    }
    $param->{tag_docs} = $tag_docs;
    $param->{link_doc} = $app->help_url('appendices/tags/');

    $param->{screen_id} = "edit-template-" . $param->{type};

    # template language
    $param->{template_lang} = 'html';
    if ( $obj && $obj->outfile ) {
        if ( $obj->outfile =~ m/\.(css|js|html|php|pl|asp)$/ ) {
            $param->{template_lang} = {
                css  => 'css',
                js   => 'javascript',
                html => 'html',
                php  => 'php',
                pl   => 'perl',
                asp  => 'asp',
            }->{$1};
        }
    }

    if ( ( $param->{type} eq 'custom' ) || ( $param->{type} eq 'widget' ) ) {
        if ($blog) {
            $param->{include_with_ssi}      = 0;
            $param->{cache_path}            = '';
            $param->{cache_expire_type}     = 0;
            $param->{cache_expire_period}   = '';
            $param->{cache_expire_interval} = 0;
            $param->{ssi_type}              = uc $blog->include_system;
        }
        if ($obj) {
            $param->{include_with_ssi} = $obj->include_with_ssi
                if defined $obj->include_with_ssi;
            $param->{cache_path} = $obj->cache_path
                if defined $obj->cache_path;
            $param->{cache_expire_type} = $obj->cache_expire_type
                if defined $obj->cache_expire_type;
            my ( $period, $interval )
            # PATCH
#                = _get_schedule( $obj->cache_expire_interval );
                = MT::CMS::Template::_get_schedule( $obj->cache_expire_interval );
            # /PATCH
            $param->{cache_expire_period}   = $period   if defined $period;
            $param->{cache_expire_interval} = $interval if defined $interval;
            my @events = split ',', ( $obj->cache_expire_event || '' );
            foreach my $name (@events) {
                $param->{ 'cache_expire_event_' . $name } = 1;
            }
        }
    }

    # if unset, default to 30 so if they choose to enable caching,
    # it will be preset to something sane.
    $param->{cache_expire_interval} ||= 30;

    $param->{dirty} = 1
        if $app->param('dirty');

    $param->{can_preview} = 1
        if ( !$param->{is_special} )
        && ( !$obj
        || ( $obj && ( $obj->outfile || '' ) !~ m/\.(css|xml|rss|js)$/ ) )
        && ( !exists $param->{can_preview} );

    if ( $blog && $blog->use_revision ) {
        $param->{use_revision} = 1;

 #TODO: the list of revisions won't appear on the edit screen.
 #$param->{revision_table} = $app->build_page(
 #    MT::CMS::Common::build_revision_table(
 #        $app,
 #        object => $obj || MT::Template->new,
 #        param => {
 #            template => 'include/revision_table.tmpl',
 #            args     => {
 #                sort_order => 'rev_number',
 #                direction  => 'descend',
 #                limit      => 5,              # TODO: configurable?
 #            },
 #            revision => $obj ? $obj->revision || $obj->current_revision : 0,
 #        }
 #    ),
 #    { show_actions => 0, hide_pager => 1 }
 #);
    }
    1;
};

1;
