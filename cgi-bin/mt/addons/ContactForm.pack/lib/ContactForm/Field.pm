package ContactForm::Field;

use strict;
use lib qw( addons/Commercial.pack/lib );
use CustomFields::Util qw( get_meta );
use ContactForm::Util qw( is_application );
use MT::Util qw( encode_html );

sub _init_tags {
    my $app = MT->instance();
    return 1 if ( ref $app ) eq 'MT::App::Upgrader';
    require MT::Request;
    my $r = MT::Request->instance;
    my $cache = $r->cache( 'plugin-contactform-init' );
    return 1 if $cache;
    $r->cache( 'plugin-contactform-init', 1 );
    unless ( $ENV{FAST_CGI} || MT->config->PIDFilePath ) {
        if ( ref $app eq 'MT::App::CMS' ) {
            if ( $^O eq 'MSWin32' && lc $ENV{ 'REQUEST_METHOD' } eq 'post' ) {
                # pass
            } else {
                require CGI;
                $CGI::POST_MAX = $app->config->CGIMaxUpload;
                my $q = new CGI;
                my $mode = $q->param( '__mode' )
                    or return;
                $mode =~ s/_.*$//;
                my @load_at = qw/view rebuild preview save delete cfg default recover itemset publish/;
                unless ( grep { $mode =~ /^\Q$_\E/ } @load_at ) {
                    return;
                }
                my $type = $q->param( '_type' );
                if ( $type && ( $type eq 'field' ) ) {
                    return;
                }
            }
        }
    }
    my $core = MT->component( 'commercial' ); # FIXME: 'contactform' is before
    my $registry = $core->registry( 'tags', 'block' );
    my $registry_function = $core->registry( 'tags', 'function' );
    my @fields = MT->model( 'field' )->load( { type => 'contactform' } );
    my $commercial = MT->component( 'commercial' );
    my $tags = $commercial->registry( 'tags' );
    for my $field ( @fields ) {
        my $tag = $field->tag;
        $tag = lc( $tag );
        delete( $registry_function->{ $tag } );
        $registry_function->{ $tag } = sub { 
            my ( $ctx, $args, $cond ) = @_;
            my $app = MT->instance;
            my $contactform;
            if ( is_application( $app ) ) {
                if ( my $mode = $app->mode ) {
                    if ( ( $mode eq 'confirm' ) || ( $mode eq 'submit' ) ) {
                        $contactform = 1;
                    }
                }
            }
            my $this_tag = lc ( $ctx->stash( 'tag' ) );
            my ( $start, $end );
            if (! $contactform ) {
                $start = '<mt:' . $this_tag . 'loop>';
                $end = '</mt:' . $this_tag . 'loop>';
            } else {
                $start = '<mt:Loop name="field_loop">';
                $end = '</mt:Loop>';
            }
            require ContactForm::Plugin;
            my $template = ContactForm::Plugin::_module_mtml();
            require MT::Template::Tags::Filters;
            return MT::Template::Tags::Filters::_fltr_mteval( $start . $template . $end, 1, $ctx );
        };
        $registry->{ $tag . 'loop' } = sub { 
            my ( $ctx, $args, $cond ) = @_;
            my $this_tag = lc ( $ctx->stash( 'tag' ) );
            $this_tag =~ s/loop$//i;
            $ctx->stash( 'tag', $this_tag );
            require ContactForm::Tags;
            require CustomFields::Template::ContextHandlers;
            my $field = CustomFields::Template::ContextHandlers::find_field_by_tag( $ctx, $this_tag )
                or return _no_field( $ctx );
            local $ctx->{ __stash }{ field } = $field;
            my $res = '';
            my $value = CustomFields::Template::ContextHandlers::_hdlr_customfield_value( @_ );
            return '' unless $value;
            if ( $args->{ raw } ) {
                return $value;
            }
            $args->{ id } = $value;
            return ContactForm::Tags::_hdlr_contactforms( $ctx, $args, $cond );
        };
    }
}

sub _no_field {
    my ( $ctx ) = @_;
    return $ctx->error( MT->translate(
        "You used an '[_1]' tag outside of the context of the correct content; ",
        $ctx->stash( 'tag' ) ) );
}

sub _customfield_types {
    my $customfield_types = {
        contactform => {
            label             => 'Form',
            column_def        => 'vchar',
            order             => 2050,
            no_default        => 1,
            field_html        => \&_field_html,
            field_html_params => \&_field_html_params,
        },
    };
}

# sub _options_field {
#     return '';
# }

sub _field_html {
    return <<'MTML';
<__trans_section component="ContactForm">
<span class="field-content" id="field_value-<mt:var name="field_id" escape="html">" style="padding:0px;display:block;margin-bottom:6px;line-height:1.4em">
<mt:if name="object_exists">
<span id="obj-<mt:var name="field_id" escape="html">-<mt:var name="id" escape="html">">
<mt:var name="name" escape="html"> (ID:<mt:var name="id" escape="html">)
<a href="javascript:;" onclick="jQuery(this).parent().remove();contactformgroup_remove_val('<mt:var name="id" escape="html">','<mt:var name="field_id" escape="html">');"><img src="<mt:var name="static_uri">images/status_icons/close.gif" alt="<__trans phrase="Delete">" title="<__trans phrase="Delete">" /></a>
</span>
</mt:if>
</span>
<MTContactFormFieldScope setvar="fieldscope">
<mt:if name="fieldscope" eq="blog">
<mt:setvar name="field_blog_id" value="$blog_id">
<mt:else>
<mt:setvar name="field_blog_id" value="$curr_website_id">
</mt:else>
</mt:if>
<input name="<mt:var name="field_name" escape="html">" id="<mt:var name="field_id" escape="html">" type="hidden" value="<mt:var name="value" escape="html">" />
<input id="<mt:var name="field_id" escape="html">-checker" type="hidden" value="" />
<span class="actions-bar" style="clear:none;margin-top:4px">
    <span class="actions-bar-inner pkg actions">
        <a href="<mt:var name="script_url">?__mode=list_contactformgroup&amp;blog_id=<mt:var name="field_blog_id">&amp;dialog_view=1&amp;edit_field=<mt:var name="field_id">&amp;contactformgroup_select=1" class="mt-open-dialog button">
        <__trans phrase="Select Form">
        </a>
    </span>
</span>
<mt:IfNotSent key="contactformgroup_js_remove_val">
<script type="text/javascript">
    function contactformgroup_remove_val(n,fld){
        var val_new = '';
        jQuery('#' + fld).val(val_new);
    }
</script>
</mt:IfNotSent>
</__trans_section>
MTML
}

sub _field_html_params {
    my ( $key, $tmpl, $param ) = @_;
    if ( my $field_id = $param->{ field_value } ) {
        require ContactForm::ContactFormGroup;
        my $obj = ContactForm::ContactFormGroup->load( $field_id );
        if ( $obj ) {
            $param->{ object_exists } = 1;
            my $column_names = $obj->column_names;
            foreach my $column_name ( @$column_names ) {
                if ( $obj->has_column( $column_name ) ) {
                    $param->{ $column_name } = $obj->$column_name;
                }
            }
            my $meta = get_meta( $obj );
            foreach my $field ( keys %$meta ) {
                my $column_name = 'field.' . $field;
                if ( $obj->has_column( $column_name ) ) {
                    $param->{ $column_name } = $obj->$column_name;
                }
            }
        }
    }
    my $app = MT->instance;
    if ( my $blog = $app->blog ) {
        $param->{ blog_id } = $blog->id;
        if ( $blog->is_blog ) {
            $param->{ curr_website_id } = $blog->parent_id;
        } else {
            $param->{ curr_website_id } = $blog->id;
        }
    }
    return 1;
}

1;
