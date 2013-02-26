package EntryWorkflow::Plugin;
use strict;

use lib qw( addons/PowerCMS.pack/lib );
use PowerCMS::Util qw( is_user_can send_mail is_power_edit is_cms str2array get_array_uniq
                       current_user
                     );
use MT::Util qw( encode_html encode_url );
use EntryWorkflow::Util;

my $plugin = MT->component( 'EntryWorkflow' );

sub _cb_tp_preview_strip {
    my ( $cb, $app, $param, $tmpl ) = @_;
    for my $key ( $app->param ) {
        if ( grep { $key eq $_ } ( 'wf_status_approval', 'entry-workflow-message', 'change_author_id' ) ) {
            my $input = {
                'data_name' => $key,
                'data_value' => $app->param( $key ),
            };
            push( @{ $param->{ 'entry_loop' } }, $input );
        }
    }
}

sub _cb_to_list_common {
    my ( $cb, $app, $tmpl ) = @_;
#    return 1 unless $app->param( '_type' ) eq 'page';
    unless ( is_user_can( $app->blog, current_user( $app ), 'publish_post' ) ) {
        $$tmpl =~ s!<a href="#publish".*?</a>!!g;
    }
}

sub _cb_cms_pre_load_filtered_list_entry {
    my ( $cb, $app, $filter, $load_options, $cols ) = @_;
    my $terms = $load_options->{ terms } || {};
    my $filter_key = $app->param( 'fid' );
    if ( $filter_key && $filter_key eq 'review' ) {
        if ( ref $terms eq 'ARRAY' ) {
            unshift( @$terms, [ { status => 3 } ] );
        } else {
            $terms->{ status } = 3;
        }
    }
}

sub _cb_alt_widget_tmpl {
    my ( $cb, $app, $tmpl ) = @_;
    my $tmpl_name = $cb->method;
    my $search = quotemeta( 'MT::App::CMS::template_source.' );
    $tmpl_name =~ s/$search//;
    unless ( $tmpl_name =~ /^.*\..*$/ ) {
        $tmpl_name .= '.tmpl';
    }
    my $fmgr = MT::FileMgr->new( 'Local' ) or die MT::FileMgr->errstr;
    my $alt_tmpl = File::Spec->catfile( $plugin->path, 'alt-tmpl', 'cms', 'widget', $tmpl_name );
    my $alt_tmpl_powercms;
    if ( my $powercms = MT->component( 'powercms' ) ) {
        $alt_tmpl_powercms = File::Spec->catfile( $powercms->path, 'alt-tmpl', 'cms', 'widget', $tmpl_name );
    }
    if ( $alt_tmpl_powercms && $fmgr->exists( $alt_tmpl_powercms ) ) {
        $$tmpl = $fmgr->get_data( $alt_tmpl_powercms );
    } elsif ( $fmgr->exists( $alt_tmpl ) ) {
        $$tmpl = $fmgr->get_data( $alt_tmpl );
    }
}

sub _cb_pre_run {
    my $app = MT->instance();
    if ( $app->mode eq 'view' ) {
        my $class = $app->param( '_type' );
        if ( $class && $class =~ /^(?:entry|page)$/ ) {
            if ( my $entry_id = $app->param( 'id' ) ) {
                return 1 if $app->param( 'duplicate' ) || $app->param( 'is_revision' ) || $app->param( 'edit_revision' );
                my $entry = MT->model( $class )->load( { id => $entry_id } );
                my $user = current_user( $app );
                unless ( EntryWorkflow::Util::can_edit_entry( $entry, $user ) ) {
                    return $app->return_to_dashboard( permission => 1 );
                }
            }
        }
    }
    if ( $app->mode eq 'search_replace' ) {
        my $registry = MT->registry( 'core', 'applications', 'cms', 'search_apis', 'entry' );
        $registry->{ perm_check } = sub {
            my ( $obj ) = @_;
            my $user = current_user( $app );
            if ( is_user_can( $obj->blog, $user, 'publish_post' ) ||
                 is_user_can( $obj->blog, $user, 'edit_all_posts' ) ||
                 is_user_can( $obj->blog, $user, 'create_post' )
            ) {
                return 1;
            }
            return 0;
        };
    }
}

sub _cb_pre_redirect_entry {
    my ( $cb, $app, $return_url, $revision, $obj, $original ) = @_;
    if ( my $change_author_id = $app->param( 'change_author_id' ) ) {
        my $user = current_user( $app );
        if ( $change_author_id != $user->id ) {
            my $redirect_url = $app->uri( mode => 'list',
                                          args => { _type => 'powerrevision',
                                                    blog_id => $revision->blog_id,
                                                    filter => 'object_class',
                                                    filter_val => $revision->object_class,
                                                    saved => 1,
                                                    no_rebuild => 1,
                                                  },
                                        );
            my $location = $app->base . $app->uri( mode => 'wf_redirect',
                                                   args => {
                                                    return_url => encode_url( $redirect_url ),
                                                   },
                                                 );
            return $app->print( "Location: $location\n\n" );
        }
    }
}

sub _cb_tp_edit_entry {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $blog = $app->blog;
    my $user = current_user( $app );
    my $type = $app->param( '_type' );
    my $perm = $type . '_approval';
    my $wf_params = EntryWorkflow::Util::get_wf_params( $blog, $type, $app->user );
    $param->{ wf_administer } = $wf_params->{ wf_administer };
    $param->{ wf_can_publish } = $wf_params->{ wf_can_publish };
    $param->{ wf_publisher } = $wf_params->{ wf_publisher };
    $param->{ wf_approver } = $wf_params->{ wf_approver };
    $param->{ wf_creator } = $wf_params->{ wf_creator };
    $param->{ wf_not_edit_all_posts } = $wf_params->{ wf_not_edit_all_posts };
    $param->{ powercms_installed } = $wf_params->{ powercms_installed };
    $param->{ entry_class } = $type;
    my $entry_id = $app->param( 'id' );
    my $entry;
    if ( $entry_id ) {
        $entry = MT::Entry->load( { id => $entry_id } );
    }
    if ( $entry ) {
        if ( my $entry_author = $entry->author ) {
            $param->{ current_author_nickname } = $entry_author->nickname;
            if ( is_user_can( $blog, $entry_author, 'publish_post' ) ) {
                $param->{ wf_entry_author_can_publish } = 1;
            }
        }
        if ( my $entry_creator_id = $entry->creator_id ) {
            if ( $entry->author && $entry->author->id != $entry_creator_id ) {
                my $creator = MT->model( 'author' )->load( { id => $entry_creator_id } );
                if ( $creator ) {
                    $param->{ creator_nickname } = $creator->nickname;
                }
            }
        }
    }
    if ( my $pointer_field = $tmpl->getElementById( 'status' ) ) {
        my %options;
        $options{ is_duplicate } = $app->param( 'duplicate' );
        my ( $creator_loop, $approver_loop, $publisher_loop, $administer_loop )
            = EntryWorkflow::Util::get_loops( $blog, $type, $user, $entry, \%options );
        if ( $creator_loop || $approver_loop || $publisher_loop || $administer_loop ) {
            $param->{ approver_loop } = $approver_loop;
            $param->{ creator_loop } = $creator_loop;
            $param->{ publisher_loop } = $publisher_loop;
            $param->{ administer_loop } = $administer_loop;
            my $nodeset = $tmpl->createElement( 'app:setting',
                                                { id => 'change_author_id',
                                                  label_class => 'top-label',
                                                  label => $plugin->translate( 'Approve for' ),
                                                  required => 0,
                                                },
                                              );
            my $innerHTML = <<MTML;
<__trans_section component="EntryWorkflow">
<div style="margin-bottom:5px;">
    <select name="change_author_id" id="change_author_id" onchange="toggle_notification_approve( this )">
        <option value=""><__trans phrase="None"></option>
    <mt:loop name="creator_loop">
        <mt:if name="__first__"><optgroup label="<__trans phrase="Creator">" id="optgroup_creator"></mt:if>
        <option class="creator" value="<mt:var name="author_id">"><mt:var name="author_nickname" escape="html"></option>
        <mt:if name="__last__"></optgroup></mt:if>
    </mt:loop>
    <mt:loop name="approver_loop">
        <mt:if name="__first__"><optgroup label="<__trans phrase="Approver">" id="optgroup_approver"></mt:if>
        <option class="approver" value="<mt:var name="author_id">"><mt:var name="author_nickname" escape="html"></option>
        <mt:if name="__last__"></optgroup></mt:if>
    </mt:loop>
    <mt:if name="wf_approver">
        <mt:setvar name="show_publisher" value="1">
        <mt:setvar name="show_administer" value="1">
    </mt:if>
    <mt:if name="wf_can_publish">
        <mt:setvar name="show_publisher" value="1">
        <mt:setvar name="show_administer" value="1">
    </mt:if>
    <mt:if name="show_publisher">
        <mt:loop name="publisher_loop">
            <mt:if name="__first__"><optgroup label="<__trans phrase="Publisher">" id="optgroup_publisher"></mt:if>
            <option class="publisher" value="<mt:var name="author_id">"><mt:var name="author_nickname" escape="html"></option>
            <mt:if name="__last__"></optgroup></mt:if>
        </mt:loop>
    </mt:if>
    <mt:if name="show_administer">
        <mt:loop name="administer_loop">
            <mt:if name="__first__"><optgroup label="<__trans phrase="Administer">" id="optgroup_administer"></mt:if>
            <option class="administer" value="<mt:var name="author_id">"><mt:var name="author_nickname" escape="html"></option>
            <mt:if name="__last__"></optgroup></mt:if>
        </mt:loop>
    </mt:if>
    </select>
</div>
<mt:if name="id">
    <mt:unless name="wf_entry_author_can_publish">
        <mt:if name="wf_can_publish">
<p class="alert-warning-inline" id="change-author-warning">
<img src="<mt:var name="static_uri">/images/status_icons/warning.gif" alt="<__trans phrase="Warning">" width="9" height="9" />
    <__trans phrase="Warning: If, when you publish the page has been owned by an unauthorized user public ownership will be changed to your page.">
</p>
        </mt:if>
    </mt:unless>
</mt:if>
<p class="alert-warning-inline" id="creator-warning" style="display:none">
<img src="<mt:var name="static_uri">/images/status_icons/warning.gif" alt="<__trans phrase="Warning">" width="9" height="9" />
    <__trans phrase="Warning: If the page is notified to the authority in Creator, status on the page is automatically drafted.">
</p>
<p class="alert-warning-inline" id="approver-warning" style="display:none">
<img src="<mt:var name="static_uri">/images/status_icons/warning.gif" alt="<__trans phrase="Warning">" width="9" height="9" />
    <__trans phrase="Warning: If the page is notified to the authority in Approver, status on the page is automatically drafted.">
</p>
<p class="alert-warning-inline" id="not-edit_all_posts-warning" style="display:none">
<img src="<mt:var name="static_uri">/images/status_icons/warning.gif" alt="<__trans phrase="Warning">" width="9" height="9" />
    <__trans phrase="Warning: If the page is notified to the other user, As for you, the authority to edit the page is lost.">
</p>
<p class="alert-warning-inline" id="approval-warning" style="display:none">
<img src="<mt:var name="static_uri">/images/status_icons/warning.gif" alt="<__trans phrase="Warning">" width="9" height="9" />
    <__trans phrase="Warning: If the request for approval, As for you, the authority to edit the page is lost.">
</p>
<div id="entry-workflow-textarea-wrapper" style="display:none">
    <label for="entry-workflow-message">
        <__trans phrase="E-mail Notification">
    </label>
    <mt:if name="powercms_installed">
    <label id="wf_status_approval-wrapper" style="display:none">
        &nbsp;&nbsp;<input onchange="toggle_approval_warning( this )" type="checkbox" value="3" name="wf_status_approval" id="wf_status_approval" /> <__trans phrase="Request the Approve.">
    </label>
    </mt:if>
    <div class="field-content" id="entry-workflow-wrapper">
        <textarea name="entry-workflow-message" id="entry-workflow-message" class="text full row" style="height:100px;"></textarea>
    </div>
</div>
<script type="text/javascript">
<mt:if name="powercms_installed">
    function toggle_approval_warning( cb ) {
        if ( cb.checked ) {
            <mt:unless name="wf_can_publish">
            if ( getByID( 'not-edit_all_posts-warning' ).style.display == 'none' ) {
                getByID( 'approval-warning' ).style.display = 'block';
            }
            </mt:unless>
        } else {
            getByID( 'approval-warning' ).style.display = 'none';
        }
    }
    var ex_status = getByID( '<MTIfPlugin component="PowerRevision">ex_</MTIfPlugin>status' );
    var orig_ex_status;
    if ( ex_status ) {
    <mt:unless name="wf_can_publish">
        ex_status.disabled = 'disabled';
    </mt:unless>
        orig_ex_status = ex_status.selectedIndex;
    }
</mt:if>
    function toggle_notification_approve ( sel, selected_value ) {
        var area = getByID( 'entry-workflow-textarea-wrapper' );
        if ( sel.selectedIndex == 0 ) {
            area.style.display = 'none';
            getByID( 'not-edit_all_posts-warning' ).style.display = 'none';
        } else {
            area.style.display = 'block';
    <mt:if name="entry_class" eq="entry">
        <mt:if name="wf_not_edit_all_posts">
            getByID( 'not-edit_all_posts-warning' ).style.display = 'block';
        </mt:if>
    <mt:else>
    <mt:if name="wf_not_edit_all_posts">
        <mt:if name="powercms_installed">
            getByID( 'not-edit_all_posts-warning' ).style.display = 'block';
        </mt:if>
    </mt:if>
    </mt:else>
    </mt:if>
        }
        var opt = sel.options[ sel.selectedIndex ];
        var classname = opt.className;
    <mt:unless name="wf_creator">
        if ( classname.indexOf( 'creator' ) == 0 ) {
            getByID( 'creator-warning' ).style.display = 'block';
        }
    </mt:unless>
    <mt:if name="wf_can_publish">
        if ( classname.indexOf( 'approver' ) == 0 ) {
            getByID( 'approver-warning' ).style.display = 'block';
        }
    </mt:if>
        if ( classname.indexOf( 'creator' ) != 0 ) {
            getByID( 'creator-warning' ).style.display = 'none';
        }
        if ( classname.indexOf( 'approver' ) != 0 ) {
            getByID( 'approver-warning' ).style.display = 'none';
        }
    <mt:if name="powercms_installed">
        if ( classname.indexOf( 'administer' ) == 0 ) {
            getByID( 'wf_status_approval-wrapper' ).style.display = 'inline';
        } else if ( classname.indexOf( 'publisher' ) == 0 ) {
            getByID( 'wf_status_approval-wrapper' ).style.display = 'inline';
        } else {
            getByID( 'wf_status_approval-wrapper' ).style.display = 'none';
            getByID('wf_status_approval').checked = '';
        }
        var ex_status = getByID( '<MTIfPlugin component="PowerRevision">ex_</MTIfPlugin>status' );
        if ( ex_status ) {
            if ( classname.indexOf( 'approver' ) == 0 ) {
                ex_status.selectedIndex = 0;
            } else if ( classname.indexOf( 'creator' ) == 0 ) {
                ex_status.selectedIndex = 0;
            } else {
                if ( selected_value && ( selected_value == 2 || selected_value == 4 || selected_value == 7 ) ) {
                
                } else {
<mt:unless name="new_object">
    <mt:unless name="request.reedit">
                    ex_status.selectedIndex = orig_ex_status;
    </mt:unless>
</mt:unless>
                }
            }
        }
    </mt:if>
    }
    function ex_status_change() {
        ex_status = getByID('ex_status');
        selected_value = ex_status.value;
        if((selected_value == 2)||(selected_value == 4)||(selected_value == 7)) {
            getByID('change_author_id-field').style.display = 'none';
            var owner_select = getByID('change_author_id');
            owner_select.selectedIndex = 0;
            toggle_notification_approve(owner_select,selected_value);
        } else {
            getByID('change_author_id-field').style.display = 'block';
            if(selected_value == 1) {
                getByID('wf_status_approval').checked = '';
            }else if(selected_value == 3) {
                wf_status_approval = getByID('wf_status_approval');
                wf_status_approval_display = wf_status_approval.style.display;
                if ((wf_status_approval_display == '')||(wf_status_approval_display == 'block')){
                    getByID('wf_status_approval').checked = 'checked';
                }else{
                    getByID('wf_status_approval').checked = '';
                }
            }
        }
    }
<mt:setvarblock name="jq_js_include" append="1">
    jQuery('#ex_status').change(function() {
        ex_status_change();
    });
    jQuery('#wf_status_approval').change(function() {
        checked = this.checked;
        ex_status = getByID('<MTIfPlugin component="PowerRevision">ex_</MTIfPlugin>status');
        if(checked) {
            ex_status.value = 3;
        } else {
            ex_status.value = 1;
        }
    });
</mt:setvarblock>
    function hide_change_author_section() {
        ex_status = getByID('<MTIfPlugin component="PowerRevision">ex_</MTIfPlugin>status');
        selected_status = ex_status.value;
        if((selected_status != 1)&&(selected_status != 3)) {
            getByID('change_author_id-field').style.display = 'none';
        }
    }
    hide_change_author_section();
</script>
</__trans_section>
MTML
            $nodeset->innerHTML( $innerHTML );
            $tmpl->insertAfter( $nodeset, $pointer_field );
        }
        if ( $entry ) {
            my $nodeset = $tmpl->createElement( 'app:setting',
                                                { id => 'current_author',
                                                  label_class => 'top-label',
                                                  label => $plugin->translate( 'Current Author ( Creater )' ),
                                                  required => 0,
                                                },
                                              );
            my $innerHTML = <<'MTML';
<__trans_section component="EntryWorkflow">
    <mt:var name="current_author_nickname"> ( <mt:if name="creator_nickname"><mt:var name="creator_nickname"><mt:else><mt:var name="current_author_nickname"></mt:if> )
</__trans_section>
MTML
            $nodeset->innerHTML( $innerHTML );
            $tmpl->insertAfter( $nodeset, $pointer_field );
        }
    }
    my $status;
    if ( my $revision_id = $app->param( 'revision_id' ) ) {
        if ( my $powerrevision = MT->model( 'powerrevision' ) ) {
            my $revision = $powerrevision->load( { id => $revision_id } );
            if ( $revision ) {
                $status = $revision->status;
            }
        }
    } else {
        my $entry_id = $app->param( 'id' );
        my $entry = MT->model( $type )->load( { id => $entry_id } );
        if ( $entry ) {
            $status = $entry->status;
        }
    }
    if ( $status ) {
        if ( $status == MT::Entry::REVIEW() ) {
            $param->{ status_review } = 1;
        }
    }
    if ( $app->param( '_type' ) eq 'entry' ) {
        my $perms = $app->permissions;
        if ( my $categories = $perms->categories ) {
            $param->{ categories } = $categories;
            my $category_id = $param->{ category_id };
            my @can_post = split( /,/, $categories );
            my $cat_tree = $param->{ category_tree };
            my @new_cat_tree;
            my $category_ok;
            my $new_cat_id;
            for my $cat ( @$cat_tree ) {
                my $cid = $cat->{ id };
                if ( grep( /^$cid$/, @can_post ) ) {
                    push ( @new_cat_tree, $cat );
                }
            }
            $param->{ category_tree } = \@new_cat_tree;
            my $selected_category_loop = $param->{ selected_category_loop };
            my @new_selected_category_loop;
            for my $cat ( @$selected_category_loop ) {
                my $cid = $cat->{ id };
                if ( grep( /^$cid$/, @can_post ) ) {
                    if (! $new_cat_id ) {
                        $new_cat_id = $cid;
                    }
                    push ( @new_selected_category_loop, $cat );
                    if ( $cid == $category_id ) {
                        $category_ok = 1;
                    }
                }
            }
            $param->{ selected_category_loop } = \@new_selected_category_loop;
            if ( $category_id && !$category_ok ) {
                $param->{ category_id } = $new_cat_id;
            }
        }
    }
}

sub _cb_pre_save_entry {
    my ( $cb, $app, $obj, $original ) = @_;
    return 1 if is_power_edit( $app );
    return 1 unless is_cms( $app );
    if ( defined $original ) {
        if ( ( $original->status == MT::Entry::RELEASE() ) && ( $obj->status != MT::Entry::RELEASE() ) ) {
            $obj->approver_ids( undef );
        }
    }
    my $user = current_user( $app );
    if ( my $orig_id = $app->param( 'orig_id' ) ) {
        # for PowerRevision
        my $orig = MT->model( 'entry' )->load( { id => abs $orig_id } );
        if ( $orig ) {
            $obj->creator_id( $orig->creator_id );
        }
    } else {
        if ( $obj->has_column( 'creator_id' ) ) {
            if (! $obj->id ) {
                $obj->creator_id( $user->id );
            } elsif (! $obj->creator_id ) {
                $obj->creator_id( $user->id );
            }
        }
    }
    my $change_author_id = $app->param( 'change_author_id' );
    my $entry_author = $obj->author;
    my $blog = $obj->blog;
    if ( $obj->status != MT::Entry::HOLD() ) {
        if ( is_user_can( $blog, $user, 'publish_post' ) ) {
            if (! is_user_can( $blog, $entry_author, 'publish_post' ) ) {
                $obj->author_id( $user->id );
            }
        }
    }
    if ( ! $app->param( 'status' ) && ! $obj->status ) {
        $obj->status( MT::Entry::HOLD() );
    }
    unless ( $change_author_id ) {
        return 1;
    }
    my $change_author = MT->model( 'author' )->load( { id => $change_author_id,
                                                       status => MT::Author::ACTIVE(),
                                                     }
                                                   );
    unless ( $change_author ) {
        return 1;
    }
    my $perm = $obj->class eq 'page' ? 'manage_pages' : 'create_post';
    if (! is_user_can( $blog, $change_author, $perm ) ) {
        return 0;
    }
    if ( $obj->author_id == $change_author_id ) {
        # return 1;
    }
    my $type = $app->param( '_type' );
    my $approve_perm = $type . '_approval';
    unless ( is_user_can( $blog, $change_author, 'publish_post' ) ) {
        if ( $obj->status != MT::Entry::HOLD() ) {
            $obj->status( MT::Entry::HOLD() );
            $app->param( 'status', MT::Entry::HOLD() );
            $app->param( 'ex_status', MT::Entry::HOLD() ); # for PowerCMS
        }
    }
    if ( ( is_user_can( $blog, $change_author, $approve_perm ) ) ||
         ( is_user_can( $blog, $change_author, 'publish_post' ) )
    ) {
        if ( $app->param( 'wf_status_approval' ) ) {
            if ( $obj->status != MT::Entry::REVIEW() ) {
                $obj->status( MT::Entry::REVIEW() );
                $app->param( 'status', MT::Entry::REVIEW() );
                $app->param( 'ex_status', MT::Entry::REVIEW() ); # for PowerCMS
            }
        }
    }
    $obj = EntryWorkflow::Util::set_approver_ids_to_obj( $obj, $user->id, $change_author->id );
    $obj->author_id( $change_author_id );
    EntryWorkflow::Util::workflow_log( $obj->class, $obj->title, $user, $entry_author, $change_author );
    return 1;
}

sub _cb_post_recover_entry {
    my ( $cb, $app, $entry, $revision ) = @_;
    return unless $revision;
    $entry = MT->model( $entry->class )->load( { id => $entry->id } ); # neccesary for permalink, at saving at entry edit mode.
    my $user = current_user( $app );
    my $options;
    $options->{ tmpl } = 'wf_published_message';
    $options->{ revision } = $revision;
    $options->{ params } = {
        entry_permalink => $entry->permalink,
    };
    my ( $subject, $body ) = EntryWorkflow::Util::build_mail( $app, $entry, $user, $options );
    my $from = MT->config->EmailAddressMain || $user->email;
    my $approver_ids = $revision->approver_ids;
    my @ids;
    if ( $approver_ids ) {
        @ids = str2array( $approver_ids );
    }
    @ids = get_array_uniq( @ids );
    my @emails;
    if ( @ids ) {
        my @approver_authors = MT->model( 'author' )->load( { id => \@ids,
                                                              status => MT::Author::ACTIVE(),
                                                            }
                                                          );
        for my $author ( @approver_authors ) {
            next if $author->id eq $user->id;
            push( @emails, $author->email );
        }
        @emails = get_array_uniq( @emails );
        my $to = join( ',', @emails );
        if ( send_mail( $from, $to, $subject, $body ) ) {
            $revision->approver_ids( undef );
            $revision->save or die $revision->errstr;
        }
    }
    if ( $entry->status == MT::Entry::RELEASE() ) {
        EntryWorkflow::Util::publish_log( $entry->class, $entry->title );
    }
}

sub _cb_post_save_entry {
    my ( $cb, $app, $obj, $original, $revision ) = @_;
    return 1 if is_power_edit( $app );
    return 1 unless is_cms( $app );
    if ( $app->param( 'update_revision' ) || $app->param( 'save_revision' ) ) {
        unless ( $revision ) {
            return 1;
        }
    } elsif ( $revision ) {
        return 1;
    }
    if ( $revision && ( ref $revision ) ne 'PowerRevision::PowerRevision' ) {
        $revision = undef;
    }
    my $user = current_user( $app );
    my $blog = $obj->blog;
    my $save_revision = $app->param( 'save_revision' );
    my $notify;
    if ( $save_revision && $revision && $obj->status == MT::Entry::RELEASE() ) {
        $notify = 1;
    }
    if ( ! $revision &&
         defined $original &&
         $original->status != MT::Entry::RELEASE() &&
         $obj->status == MT::Entry::RELEASE()
    ) {
        $notify = 1;
    }
    if ( $notify ) {
        my $options;
        $options->{ tmpl } = 'wf_published_message';
        $options->{ revision } = $revision;
        $options->{ params } = {
            entry_permalink => $obj->permalink,
            entry_class => ( $revision ? $revision->object_class : $obj->class ),
        };
        my ( $subject, $body ) = EntryWorkflow::Util::build_mail( $app, $obj, $user, $options );
        my $from = MT->config->EmailAddressMain || $user->email;
        my $approver_ids = $obj->approver_ids;
        my @ids;
        if ( $approver_ids ) {
            @ids = str2array( $approver_ids );
        }
        @ids = get_array_uniq( @ids );
        my @emails;
        if ( @ids ) {
            my @approver_authors = MT->model( 'author' )->load( { id => \@ids,
                                                                  status => MT::Author::ACTIVE(),
                                                                }
                                                              );
            for my $author ( @approver_authors ) {
                push( @emails, $author->email );
            }
            @emails = get_array_uniq( @emails );
            my $to = join( ',', @emails );
            if ( send_mail( $from, $to, $subject, $body ) ) {
                $obj->approver_ids( undef );
                $app->run_callbacks( ( ref $app ) . '::entryworkflow_post_notify', $app, $obj, $revision );
            }
        }
        EntryWorkflow::Util::publish_log( $obj->class, $obj->title );
    }
    my $change_author_id = $app->param( 'change_author_id' );
    unless ( $change_author_id ) {
        return 1;
    }
    if ( MT->component( 'PowerRevision' ) && ( $save_revision ) && (! $revision ) ) {
        return 1;
    }
    my $change_author = MT->model( 'author' )->load( { id => $change_author_id,
                                                       status => MT::Author::ACTIVE(),
                                                     }
                                                   );
    my $options;
    $options->{ message } = $app->param( 'entry-workflow-message' );
    $options->{ is_approval } = $app->param( 'wf_status_approval' );
    $options->{ revision } = $revision;
    if ( $app->param( 'duplicate' ) && ! $app->param( 'orig_id' ) ) { # FIXME: ad hoc
        delete $$options{ revision };
    }
    $options->{ change_author } = $change_author;
    $options->{ params } = {
        entry_class => ( $revision ? $revision->object_class : $obj->class ),
    };
    my ( $subject, $body ) = EntryWorkflow::Util::build_mail( $app, $obj, $user, $options );
    my $from = MT->config->EmailAddressMain || $user->email;
    my $to = $change_author->email;
    my $res = send_mail( $from, $to, $subject, $body );
    $app->run_callbacks( ( ref $app ) . '::entryworkflow_post_change_author', $app, $obj, $revision, $change_author );
    if ( $user->id == $obj->author_id ) {
        return;
    }
#     my $component = MT->component( 'PowerCMS' );
#     if ( (! $component ) && ( $obj->class eq 'page' ) ) {
#         return;
#     }
#     if ( $obj->class eq 'page' ) {
#         return;
#     }
    my $redirect_url;
    if ( ! EntryWorkflow::Util::can_edit_entry( $obj, $user ) ) {
        $redirect_url = $app->base . $app->uri( mode => 'list',
                                                args => { blog_id => $app->blog->id,
                                                          _type => $obj->class,
                                                          saved => 1,
                                                          no_rebuild => 1,
                                                        },
                                              );
    } elsif (! is_user_can( $obj->blog, $user, 'edit_all_posts' ) ) { # for backward
        if (! $app->param( 'duplicate' ) ) {
            $redirect_url = $app->base . $app->uri( mode => 'list',
                                                    args => { blog_id => $app->blog->id,
                                                              _type => $obj->class,
                                                              saved => 1,
                                                              no_rebuild => 1,
                                                            },
                                                  );
        }
    }
    if ( $redirect_url ){
        my $location = $app->base . $app->uri( mode => 'wf_redirect',
                                               args => {
                                                   return_url => encode_url( $redirect_url ),
                                               },
                                             );
        return $app->print( "Location: $location\n\n" );
    }
}

sub _cb_ts_edit_entry {
    my ( $cb, $app, $tmpl ) = @_;
    my $plugin = MT->component( 'EntryWorkflow' );
    my $search = quotemeta( q{<mt:setvarblock name="html_body" append="1">} );
    my $plugin_tmpl = File::Spec->catdir( $plugin->path, 'tmpl', 'wf_edit_entry.tmpl' );
    my $insert = qq{<mt:include name="$plugin_tmpl" component="EntryWorkflow">};
    $$tmpl =~ s/($search)/$insert$1/;
}

1;
