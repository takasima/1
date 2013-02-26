package ContactForm::Tags;

use strict;
use ContactForm::Util qw( build_tmpl current_ts );

sub _hdlr_contactforms {
    my ( $ctx, $args, $cond ) = @_;
    my $tokens = $ctx->stash( 'tokens' );
    my $builder = $ctx->stash( 'builder' );
    my $id = $args->{ id };
    my %params;
    require ContactForm::ContactFormGroup;
    my $group = ContactForm::ContactFormGroup->load( $id );
    return '' unless $group;
    require ContactForm::ContactFormOrder;
    $params { 'join' } = [ 'ContactForm::ContactFormOrder', 'contactform_id',
                           { group_id => $id, },
                           { sort   => 'order',
                             direction => 'ascend',
                           } ];
    my @contactforms = MT->model( 'contactform' )->load( undef, \%params );
    my $i = 0; my $res = '';
    my $vars = $ctx->{__stash}{vars} ||= +{};
    for my $contactform ( @contactforms ) {
        local $ctx->{ __stash }{ contactform }      = $contactform;
        local $ctx->{ __stash }{ contactformgroup } = $group;
        local $vars->{ __first__ }   = !$i;
        local $vars->{ __counter__ } = $i + 1;
        local $vars->{ __odd__ }     = $i % 2 ? 0 : 1;
        local $vars->{ __even__ }    = $i % 2;
        local $vars->{ __last__ }    = !defined $contactforms[ $i + 1 ];
        my $out = $builder->build( $ctx, $tokens, $cond );
        if ( !defined( $out ) ) { return $ctx->error( $builder->errstr ) };
        #$res .= $glue if $i && length($res) && length($out);
        $res .= $out;
        $i++;
    }
    return $res;
}

sub _hdlr_contactformscript {
    return MT->config( 'ContactFormScript' ) || 'mt-contactform.cgi';
}

sub _hdlr_contactform_name {
    my ( $ctx, $args ) = @_;
    my $contactformgroup = $ctx->stash( 'contactformgroup' );
    return $contactformgroup->name;
}

sub _hdlr_formelement_html {
    my ( $ctx, $args ) = @_;
    my $app = MT->instance;
    my $contactform = $ctx->stash( 'contactform' );
    my $feedback = $ctx->stash( 'feedback' );
    my $mtml = $contactform->get_template;
    my $type = $contactform->type;
    my $entry = $ctx->stash( 'entry' ) || undef;
    my $category = $ctx->stash( 'category' ) || undef;
    my $author = $ctx->stash( 'author' ) || undef;
    my $blog = $ctx->stash( 'blog' ) || $contactform->blog;
    my $basename = $contactform->basename;
    my $default;
    if ( $feedback ) {
        my $get_data = $feedback->get_hash;
        $get_data = $get_data->{ $basename };
        $default = @$get_data[1];
    } else {
        $default = $contactform->default;
    }
    my %args = ( blog => $blog,
                 entry => $entry,
                 category => $category,
                 author => $author,
                 ctx => $ctx,
                );
    my %params = ( field_basename => $contactform->basename,
                   field_name => $contactform->name,
                   field_required => $contactform->required,
                   field_default => $default,
                   field_description => $contactform->description,
                   field_option => $contactform->options,
                   field_size => $contactform->size,
                  );
    my $option = $contactform->options;
    # my $default = $contactform->default;
    my @options = $option ? split( /,/, $option ) : ();
    my @defauld_vals;
    @defauld_vals = split( /,/, $default ) if $default;
    my @field_loop;
    my $i = 1;
    my $opt_len = scalar @options;
    for my $opt ( @options ) {
        my $option_default;
        if ( $opt eq $default ) {
            $option_default = 1;
        }
        if ( @defauld_vals && grep $_ eq $opt, @defauld_vals ) {
            $option_default = 1;
        }
        push @field_loop, {
            option_value   => $opt,
            option_default => $option_default,
            __first__      => $i == 1,
            __last__       => $i == $opt_len,
        };
        $i++;
    }
    $params{ field_loop } = \@field_loop;
    my $html = build_tmpl( $app, $mtml, \%args, \%params );
    return $html;
}

sub _hdlr_cms_html {
    my ( $ctx, $args ) = @_;
    my $type = $ctx->{ __stash }{ vars }{ field_type } ||
               $args->{ type };
    require ContactForm::Plugin;
    if ( my $cms_tmpl = ContactForm::Plugin::__get_registry( $type, 'cms_tmpl' ) ) {
        $cms_tmpl = MT->handler_to_coderef( $cms_tmpl );
        return $cms_tmpl->();
    }
    return ContactForm::Plugin::_cms_tmpl_default();
}

sub _hdlr_contactform_author {
    my ( $ctx, $args, $cond ) = @_;
    my $contactformgroup = $ctx->stash( 'contactformgroup' );
    return $ctx->error() unless defined $contactformgroup;
    $ctx->stash( 'author', $contactformgroup->author );
    $ctx->stash( 'builder' )->build( $ctx, $ctx->stash( 'tokens' ), $cond );
}

sub _hdlr_formelement_column {
    my ( $ctx, $args, $cond ) = @_;
    return unless $ctx;
    my $tag = $ctx->stash( 'tag' );
    $tag = lc( $tag );
    $tag =~ s/^formelement//;
    if ( $tag eq 'column' ) {
        $tag = $args->{ column };
    } else {
        $tag =~ s/(?<!^descripti)(?=on$)/_/;
    }
    my $contactform = $ctx->stash( 'contactform' );
    return $ctx->error() unless defined $contactform;
    if ( $contactform->has_column( $tag ) ) {
        if ( $tag =~ /_on$/ ) {
            if ( my $datetime = $contactform->$tag ) {
                $args->{ ts } = $datetime;
                return $ctx->build_date( $args );
            }
        }
        return $contactform->$tag || '';
    }
    return '';
}

sub _hdlr_if_formelement {
    my ( $ctx, $args, $cond ) = @_;
    return unless $ctx;
    my $tag = $ctx->stash( 'tag' );
    $tag =lc( $tag );
    $tag =~ s/^ifformelement//i;
    if ( $tag eq 'column' ) {
        $tag = $args->{ column };
    }
    my $contactform = $ctx->stash( 'contactform' );
    return $ctx->error() unless defined $contactform;
    return 0 unless $contactform->has_column( $tag );
    my $bool = $contactform->$tag;
    return 1 if $bool;
    return 0;
}

sub _hdlr_if_open {
    my ( $ctx, $args, $cond ) = @_;
    return unless $ctx;
    my $group = $ctx->stash( 'contactformgroup' );
    return 0 unless $group;
    return $group->is_open;
}

sub _hdlr_if_closed {
    my ( $ctx, $args, $cond ) = @_;
    return unless $ctx;
    my $group = $ctx->stash( 'contactformgroup' );
    return 0 unless $group;
    return $group->is_closed;
}

sub _hdlr_if_preopen {
    my ( $ctx, $args, $cond ) = @_;
    return unless $ctx;
    my $group = $ctx->stash( 'contactformgroup' );
    return 0 unless $group;
    return $group->is_preopen;
}

sub _hdlr_contactformfieldscope {
    my ( $ctx, $args ) = @_;
    return MT->config( 'ContactFormFieldScope' ) || 'blog';
}

sub _hdlr_if_not_sent {
    my ( $ctx, $args, $cond ) = @_;
    require MT::Request;
    my $r = MT::Request->instance;
    my $key = $args->{ key };
    if ( $r->cache( $key ) ) {
        return 0;
    } else {
        $r->cache( $key, 1 );
        return 1;
    }
}

sub _filter_format_ts {
    my ( $ts, $format, $ctx ) = @_;
    if ( $ts =~ /^[0-9]{8}$/ ) {
        $ts .= '000000';
    }
    my $args;
    $args->{ ts } = $ts;
    if ( ( $format ) && ( $format =~ /\W/ ) ) {
        $args->{ format } = $format;
    }
    my $date = $ctx->build_date( $args );
    return $date;
}

sub _hdlr_trans {
    my ( $ctx, $args, $cond ) = @_;
    my $phrase = $args->{ phrase };
    my $param = $args->{ params } || '';
    my @params = split( /%%/, $param );
    if ( my $component = $args->{ component } ) {
        if ( my $plugin = MT->component( $component ) ) {
            return $plugin->translate( $phrase, @params );
        }
    }
    return MT->translate( $phrase, @params );
}

sub _hdlr_form_message {
    my ( $ctx, $args, $cond ) = @_;
    return unless $ctx;
    my $tag = $ctx->stash( 'tag' );
    $tag = lc( $tag );
    my $col = 'message';
    if ( $tag =~ /confirm/ ) {
        $col = 'confirm_' . $col;
    } elsif ( $tag =~ /error/ ) {
        $col = 'error_' . $col;
    } elsif ( $tag =~ /preopen/ ) {
        $col = 'preopen_' . $col;
    } elsif ( $tag =~ /closed/ ) {
        $col = 'closed_' . $col;
    } elsif ( $tag =~ /information/ ) {
        $col = 'information_' . $col;
    }
    my $contactform = $ctx->stash( 'contactformgroup' );
    if ( $contactform ) {
        my $msg = $contactform->$col || '';
        require MT::Template::Tags::Filters;
        $msg = MT::Template::Tags::Filters::_fltr_mteval( $msg, 1, $ctx );
        return $msg;
    }
    return '';
}

sub _hdlr_contactform_column {
    my ( $ctx, $args, $cond ) = @_;
    return unless $ctx;
    my $tag = $ctx->stash( 'tag' );
    $tag = lc( $tag );
    $tag =~ s/^contactform//;
    if ( $tag eq 'column' ) {
        $tag = $args->{ column };
    } else {
        $tag =~ s/(?<!^descripti)(?=on$)/_/;
    }
    my $contactformgroup = $ctx->stash( 'contactformgroup' );
    return $ctx->error() unless defined $contactformgroup;
    if ( $contactformgroup->has_column( $tag ) ) {
        if ( $tag =~ /_on$/ ) {
            if ( my $datetime = $contactformgroup->$tag ) {
                $args->{ ts } = $datetime;
                return $ctx->build_date( $args );
            }
        }
        return $contactformgroup->$tag || '';
    }
    return '';
}

sub _hdlr_author_displayname {
    my ( $ctx, $args ) = @_;
    my $contactformgroup = $ctx->stash( 'contactformgroup' );
    return $ctx->error() unless defined $contactformgroup;
    my $author_name = $contactformgroup->author->nickname;
    $author_name = $contactformgroup->author->name unless $author_name;
    return $author_name;
}

sub _hdlr_formelement_options {
    my ( $ctx, $args, $cond ) = @_;
    # TODO::set default value
    my $contactform = $ctx->stash( 'contactform' );
    return '' unless $contactform;
    my $text = $contactform->options;
    my $glue = defined $args->{glue} ? $args->{glue} : '';
    my @vals = split( /,/, $text );
    return '' unless @vals;
    my $tokens = $ctx->stash( 'tokens' );
    my $builder = $ctx->stash( 'builder' );
    my $vars = $ctx->{ __stash }{ vars } ||= {};
    my $res = '';
    my $i = 1;
    my $count = scalar @vals;
    for my $val ( @vals ) {
        local $vars->{ option_value } = $val;
        local $vars->{ __counter__ }  = $i;
        local $vars->{ __first__ }    = $i == 1;
        local $vars->{ __last__ }     = $i == $count ? 1 : 0;
        local $vars->{ __odd__ }      = $i % 2;
        local $vars->{ __even__ }     = $i % 2 ? 0 : 1;
        my $out = $builder->build( $ctx, $tokens, $cond );
        $res .= $out;
        $res .= $glue if $i != $count;
        $i++;
    }
    $res;
}

sub _hdlr_cms_form_status_msg {
    my $app = MT->instance;
    my $plugin = MT->component( 'ContactForm' );
    my $status = $app->param( 'status' );
    my $obj = MT->model( 'contactformgroup' )->new;
    $obj->status( $status );
    $status = $plugin->translate( $obj->status_text );
    if ( $app->param( 'not_status_contactformgroup' ) ) {
        return $plugin->translate( 'The Form status not changed to [_1].', $status );
    } else {
        return $plugin->translate( 'The Form status changed to [_1].', $status );
    }
}

sub _hdlr_contact_form_static_link {
    my($ctx, $args) = @_;
    # TODO
    #   * require by words
    #     e.g.: require="jQuery,jQueryUI,default_style"
    my $i  = 0;
    my %bf = ();
    $bf{$_} = 1 << $i++
        for qw/jQuery jQueryUI default_style/;
    my $whole   = (1 << scalar keys %bf) - 1;
    my $type    = uc($args->{type} || '');
    my $html    = $args->{html} || '';
    my $require = (defined $args->{'require'} ? $args->{'require'}
                                              : $whole) =~ /(\d+)/ ? $1 : $whole;
    my $delim   = defined $args->{delimiter} ? $args->{delimiter} : "\n";
    my $mtml    = '';
    if ($type ne 'JS') {
        my $close     = $html        ? '' : ' /';
        my $type_attr = $html eq '5' ? '' : ' type="text/css"';
        $mtml .= join $delim,
            map qq{<link rel="stylesheet" href="<\$MTStaticWebPath encode_html="1"\$>addons/ContactForm.pack/css/$_.css"$type_attr$close>},
                (($require & $bf{jQueryUI}      ? 'smoothness/jquery-ui.custom' : ()),
                 ($require & $bf{default_style} ? 'default-style' : ()));
    }
    if ($type ne 'CSS') {
        my $type_attr = $html eq '5' ? '' : ' type="text/javascript"';
        $mtml &&= "$mtml$delim";
        $mtml .= join $delim,
            map qq{<script$type_attr src="<\$MTStaticWebPath encode_html="1"\$>addons/ContactForm.pack/js/$_.js"></script>},
                (($require & $bf{jQuery}        ? 'jquery.min' : ()),
                 ($require & $bf{jQueryUI}      ? 'jquery-ui.custom.min' : ()),
                 ($require & $bf{default_style} ? 'default-style' : ()));
    }
    build_tmpl( MT->instance, $mtml );
}

sub _hdlr_feedback_count {
    my ( $ctx, $args ) = @_;
    my $terms;
    my $form_id = $args->{ form_id };
    if (! $form_id ) {
        $form_id = $args->{ contactform_group_id };
    }
    if ( $form_id ) {
        $terms->{ contactform_group_id } = $form_id;
    }
    if ( my $model = $args->{ model } ) {
        $terms->{ model } = $model;
    }
    if ( my $object_id = $args->{ object_id } ) {
        $terms->{ object_id } = $object_id;
    }
    if ( my $blog_id = $args->{ blog_id } ) {
        $terms->{ blog_id } = $blog_id;
    }
    if ( my $status = $args->{ status } ) {
        $terms->{ status } = $status;
    }
    return MT->model( 'feedback' )->count( $terms );
}

sub _hdlr_feedback_already_posted {
    my ( $ctx, $args, $cond ) = @_;
    my $terms;
    my $form_id = $args->{ form_id };
    if (! $form_id ) {
        $form_id = $args->{ contactform_group_id };
    }
    $terms->{ contactform_group_id } = $form_id;
    $terms->{ email } = $args->{ email };
    if ( my $count = MT->model( 'feedback' )->count( $terms ) ) {
        return 1;
    }
    return 0;
}

1;
