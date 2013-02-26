package PowerRevision::Listing;
use strict;

use MT::Util qw( encode_html );
use lib qw( addons/PowerCMS.pack/lib addons/Commercial.pack/lib );
use PowerCMS::Util qw( is_user_can current_user );
use PowerRevision::Util;

sub html_object_name {
    my ( $prop, $obj, $app ) = @_;
    my $plugin = MT->component( 'PowerRevision' );
    my $object_name = $obj->object_name || MT->translate( 'Untitled' ) . '(id:' . $obj->id . ')';
    my $url = $app->base . $app->uri( mode => 'edit_revision',
                                      args => {
                                        _type => $obj->object_class,
                                        blog_id => $obj->blog_id,
                                        entry_id => $obj->object_id,
                                        revision_id => $obj->id,
                                      },
                                    );
    my $html = '';
    my $can_edit_revision = PowerRevision::Util::is_user_can_revision( $obj, $app->user, 'edit_revision' );
    if ( $can_edit_revision ) {
        $html .= '<a href="' . encode_html( $url ) . '" title="' . $plugin->translate( 'Edit this revision data' ) . '">';
        $html .= encode_html( $object_name );
        $html .= '</a>';
    } else {
        $html = encode_html( $object_name );
    }
    my $filter_url = $app->base . $app->uri( mode => 'list',
                                             args => {
                                                _type => 'powerrevision',
                                                blog_id => $obj->blog_id,
                                                filter => 'object_id',
                                                filter_val => $obj->object_id,
                                             },
                                           );
    $html .= ' <a href="' . $filter_url . '" title="' . $plugin->translate( $obj->object_class eq 'entry' ? 'Only show this entry\'s revision data' : 'Only show this page\'s revision data' ) . '">';
    $html .= '<img alt="' . $plugin->translate( 'Do filter' ) . '" src="' . MT->static_path . 'images/filter.gif" width="8" height="8" border="0" />';
    $html .= '</a>';
    return $html;
}

sub html_object_class {
    my ( $prop, $obj, $app ) = @_;
    my $plugin = MT->component( 'PowerRevision' );
    my $object_class = $obj->object_class;
    unless ( $object_class ) {
        return $plugin->translate( '(Unknown object class)' );
    }
    my $label = $object_class eq 'entry' ? $app->translate( 'Entry' ) : $app->translate( 'Page' );
    my $url = $app->base . $app->uri( mode => 'list',
                                      args => {
                                        _type => 'powerrevision',
                                        blog_id => $obj->blog_id,
                                        filter => 'object_class',
                                        filter_val => $object_class,
                                      },
                                    );
    my $html = '<a href="' . encode_html( $url ) . '">' . $label . '</a>';
    return $html;
}

sub html_class {
    my ( $prop, $obj, $app ) = @_;
    my $plugin = MT->component( 'PowerRevision' );
    my $class = $obj->class;
    unless ( $class ) {
        return $plugin->translate( '(Unknown class)' );
    }
    my $label = $class eq 'workflow' ? $plugin->translate( 'Workflow' ) : $plugin->translate( 'Backup' );
    my $url = $app->base . $app->uri( mode => 'list',
                                      args => {
                                        _type => 'powerrevision',
                                        blog_id => $obj->blog_id,
                                        filter => 'class',
                                        filter_val => $class,
                                      },
                                    );
    my $html = '<a href="' . encode_html( $url ) . '">' . $label . '</a>';
    return $html;
}

sub html_view {
    my ( $prop, $obj, $app ) = @_;
    my $plugin = MT->component( 'PowerRevision' );
    my $icon_url = MT->static_path . 'images/status_icons/view.gif';
    my $url = $app->base . $app->uri( mode => 'preview_history',
                                      args => {
                                        _type => $obj->object_class,
                                        blog_id => $obj->blog_id,
                                        entry_id => $obj->object_id,
                                        revision_id => $obj->id,
                                      },
                                    );
    my $can_edit_revision = PowerRevision::Util::is_user_can_revision( $obj, $app->user, 'edit_revision' );
    my $icon_src = '<img width="13" height="9" alt="' . $app->translate( 'View' ) . '" src="' . $icon_url . '" />';
    my $html = '';
    if ( $can_edit_revision ) {
        $html = '<a href="' . encode_html( $url ) . '" target="_blank" title="' . $app->translate( 'View' ) . '">' . $icon_src . '</a>';
    } else {
        $html = $icon_src;
    }
    return $html;
}

sub html_object_status {
    my ( $prop, $obj, $app ) = @_;
    my $plugin = MT->component( 'PowerRevision' );
    my $original = $obj->original;
    my ( $original_status, $url_edit_entry );
    if ( $original ) {
        $original_status = $original ? $original->status() : 0;
        $url_edit_entry = $app->base . $app->uri( mode => 'view',
                                                  args => { _type => $original->class,
                                                            blog_id => $original->blog_id,
                                                            id => $original->id,
                                                          },
                                                );
    }
    my $icon_src;
    if ( $original_status == MT::Entry::HOLD() ) {
        my $icon_url = MT->static_path . 'images/status_icons/draft.gif';
        $icon_src = '<img src="' . $icon_url . '" width="9" height="9" alt="' . $app->translate( 'Unpublished (Draft)' ) . '" />';
    } elsif ( $original_status == MT::Entry::RELEASE() ) {
        my $icon_url = MT->static_path . 'images/status_icons/success.gif';
        $icon_src = '<img src="' . $icon_url . '" width="9" height="9" alt="' . $app->translate( 'Published' ) . '" />';
    } elsif ( $original_status == MT::Entry::FUTURE() ) {
        my $icon_url = MT->static_path . 'images/status_icons/future.gif';
        $icon_src = '<img src="' . $icon_url . '" width="9" height="9" alt="' . $app->translate( 'Scheduled' ) . '" />';
    } elsif ( $original_status == MT::Entry::REVIEW() ) {
        my $icon_url = MT->static_path . 'addons/PowerCMS.pack/images/status_review.gif';
        $icon_src = '<img src="' . $icon_url . '" width="11" height="9" alt="' . $app->translate( 'Unpublished (Review)' ) . '" />';
    } elsif ( $original_status == 7 ) {
        my $icon_url = MT->static_path . 'addons/PowerCMS.pack/images/status_template.gif';
        $icon_src = '<img src="' . $icon_url . '" width="9" height="9" alt="' . $app->translate( 'Unpublished (Review)' ) . '" />';
    } else {
        my $icon_url = MT->static_path . 'images/nav_icons/mini/delete.gif';
        $icon_src = '<img src="' . $icon_url . '" width="9" height="9" alt="' . $plugin->translate( 'Removed' ) . '" />';
    }
    my $can_edit_entry = PowerRevision::Util::is_user_can_revision( $obj, $app->user, 'edit_entry' );
    my $html = '';
    if ( $can_edit_entry && $url_edit_entry ) {
        $html = '<a href="' . encode_html( $url_edit_entry ) . '" title="' . $plugin->translate( 'Edit this entry' ) . '">' . $icon_src . '</a>';
    } else {
        $html = $icon_src;
    }
    return $html;
}

sub html_revision_status { # TODO: filter(only entry/page etc...)
    my ( $prop, $obj, $app ) = @_;
    my $plugin = MT->component( 'PowerRevision' );
    my $status = $obj->status;
    my $icon_src = '';
    my $anchor_title = '';
    if ( $status == MT::Entry::HOLD() ) {
        my $icon_url = MT->static_path . 'images/status_icons/draft.gif';
        $anchor_title = $plugin->translate( 'Only show unpublished revision data' );
        $icon_src = '<img src="' . $icon_url . '" width="9" height="9" title="' . $anchor_title . '" alt="' . $app->translate( 'Unpublished (Draft)' ) . '" />';
    } elsif ( $status == MT::Entry::FUTURE() ) {
        my $icon_url = MT->static_path . 'images/status_icons/future.gif';
        $anchor_title = $plugin->translate( 'Only show scheduled revision data' );
        $icon_src = '<img src="' . $icon_url . '" width="9" height="9" title="' . $anchor_title . '" alt="' . $app->translate( 'Scheduled' ) . '" />';
    } elsif ( $status == MT::Entry::REVIEW() ) {
        my $icon_url = MT->static_path . 'addons/PowerCMS.pack/images/status_review.gif';
        $anchor_title = $plugin->translate( 'Only show revision data as under approval' );
        $icon_src = '<img src="' . $icon_url . '" width="11" height="9" title="' . $anchor_title . '" alt="' . $app->translate( 'Unpublished (Review)' ) . '" />';
    } elsif ( $status == 7 ) {
        my $icon_url = MT->static_path . 'addons/PowerCMS.pack/images/status_template.gif';
        $anchor_title = $plugin->translate( 'Only show entry template revision data' );
        $icon_src = '<img src="' . $icon_url . '" width="9" height="9" title="' . $anchor_title . '" alt="' . $app->translate( 'Unpublished (Review)' ) . '" />';
    }
    my $url = $app->base . $app->uri( mode => 'list',
                                      args => {
                                        _type => 'powerrevision',
                                        blog_id => $obj->blog_id,
                                        filter => 'status',
                                        filter_val => $obj->status,
                                      },
                                    );
    my $html = '<a href="' . encode_html( $url ) . '" title="' . $anchor_title . '">' . $icon_src . '</a>';
    return $html;
}

sub html_recover {
    my ( $prop, $obj, $app ) = @_;
    my $plugin = MT->component( 'PowerRevision' );
    my $url = $app->base . $app->uri( mode => 'recover_entry',
                                      args => {
                                        _type => $obj->object_class,
                                        blog_id => $obj->blog_id,
                                        entry_id => $obj->object_id,
                                        revision_id => $obj->id,
                                      },
                                    );
    my $alert_message = $plugin->translate( 'Are you sure you want to recover this [_1]?', $app->translate( $obj->object_class ) );
    my $anchor_title = $plugin->translate( 'Recover from this version' );
    my $img_alt = $plugin->translate( 'Recover' );
    my $icon_url = MT->static_path . 'addons/PowerCMS.pack/images/revision.gif';
    my $html = '';
    if ( PowerRevision::Util::is_user_can_revision( $obj, $app->user, 'recover' ) ) {
        $html .= '<a onclick="return confirm(\'' . $alert_message  . '\')" href="' . encode_html( $url ) . '" title="' . $anchor_title . '">';
        $html .= '<img src="' . $icon_url . '" alt="' . $img_alt . '" width="8" height="9" />';
        $html .= '</a>';
    }
    return $html;
}

sub html_revision {
    my ( $prop, $obj, $app ) = @_;
    my $plugin = MT->component( 'PowerRevision' );
    my $entry_id = $obj->id;
    use PowerRevision::Tags;
    my $revision_count = PowerRevision::Tags::_hdlr_revision_count( undef, { id => $entry_id } );
    my $url_create_revision = $app->base . $app->uri( mode => 'view',
                                                      args => {
                                                        _type => $obj->class,
                                                        id => $entry_id,
                                                        blog_id => $obj->blog_id,
                                                        duplicate => 1,
                                                        is_revision => 1,
                                                      },
                                                    );
    my $html = '';
    $html .= '<span class="icon-revision">';
    $html .= '<span class="icon-create-revision">';
    if ( PowerRevision::Util::can_create_revision( current_user( $app ), $obj ) ) {
        $html .= '<a title="' . $plugin->translate( 'Create New Revision' ) . '" href="' . $url_create_revision . '">';
        $html .= '<img src="' . MT->static_path . 'images/status_icons/create.gif" width="9" height="9" alt="' . $plugin->translate( 'New Revision' ) . '" />';
        $html .= '</a>';
    } else {
        $html .= '-';
    }
    $html .= '</span>';
    $html .= '<span class="icon-revision-status">';
    if ( $revision_count > 0 ) {
        my $latest_revision_status = PowerRevision::Tags::_hdlr_latest_revision_value( undef, { id => $entry_id, name=> 'status' } );
        my $latest_revision_id = PowerRevision::Tags::_hdlr_latest_revision_value( undef, { id => $entry_id, name=> 'id' } );
        my $url_edit_latest_revision = $app->base . $app->uri( mode => 'edit_revision',
                                                               args => {
                                                                    _type => $obj->class,
                                                                    entry_id => $entry_id,
                                                                    blog_id => $obj->blog_id,
                                                                    revision_id => $latest_revision_id,
                                                               },
                                                             );
        my $can_edit_revision = 0;
        if ( is_user_can( $obj->blog, $app->user, 'publish_post' ) ) {
            $can_edit_revision = 1;
        } else {
            my $latest_revision_author_id = PowerRevision::Tags::_hdlr_latest_revision_value( undef, { id => $entry_id, name=> 'author_id' } );
            if ( $latest_revision_author_id && $latest_revision_author_id eq $app->user->id ) {
                $can_edit_revision = 1;
            }
        }
        if ( $latest_revision_status == MT::Entry::HOLD() ) {
            if ( $can_edit_revision ) {
                my $icon_src = '<img src="' . MT->static_path . 'images/status_icons/draft.gif" width="9" height="9" alt="' . $plugin->translate( 'Unpublished (Draft)' ) . '" />';
                $html .= '<a href="' . $url_edit_latest_revision . '">';
                $html .= $icon_src;
                $html .= '</a>';
            } else {
                my $icon_src = '<img src="' . MT->static_path . 'addons/PowerCMS.pack/images/draft_mono.gif" width="9" height="9" alt="' . $plugin->translate( 'Unpublished (Draft)' ) . '" />';
                $html .= $icon_src;
            }
        } elsif ( $latest_revision_status == MT::Entry::FUTURE() ) {
            if ( is_user_can( $obj->blog, $app->user, 'publish_post' ) ) {
                my $icon_src = '<img src="' . MT->static_path . 'images/status_icons/future.gif" width="9" height="9" alt="' . $plugin->translate( 'Scheduled' ) . '" />';
                $html .= '<a href="' . $url_edit_latest_revision . '">';
                $html .= $icon_src;
                $html .= '</a>';
            } else {
                my $icon_src = '<img src="' . MT->static_path . 'addons/PowerCMS.pack/images/future_mono.gif" width="9" height="9" alt="' . $plugin->translate( 'Scheduled' ) . '" />';
                $html .= $icon_src;
            }
        } elsif ( $latest_revision_status == MT::Entry::REVIEW() ) {
            if ( is_user_can( $obj->blog, $app->user, 'publish_post' ) ) {
                my $icon_src = '<img src="' . MT->static_path . 'addons/PowerCMS.pack/images/status_review.gif" width="9" height="9" alt="' . $plugin->translate( 'Unpublished (Review)' ) . '" />';
                $html .= '<a href="' . $url_edit_latest_revision . '">';
                $html .= $icon_src;
                $html .= '</a>';
            } else {
                my $icon_src = '<img src="' . MT->static_path . 'addons/PowerCMS.pack/images/status_review_mono.gif" width="9" height="9" alt="' . $plugin->translate( 'Unpublished (Review)' ) . '" />';
                $html .= $icon_src;
            }
        } else {
            $html .= '-';
        }
    } else {
        $html .= '-';
    }
    $html .= '</span>';
    $html .= '<span class="icon-revision-list">';
    if ( $revision_count > 0 ) {
        my $url_open_dialog = $app->base . $app->uri( mode => 'select_powerrevision',
                                                      args => {
                                                        blog_id => $obj->blog_id,
                                                        filter => 'object_id',
                                                        filter_val => $entry_id,
                                                        class_type => 'workflow',
#                                                         filter_key => 'entry_revision_workflow',
#                                                         object_id => $entry_id,
                                                        dialog => 1,
                                                        object_class => $obj->class,
                                                      },
                                                    );
#        $html .= '<a class="mt-open-dialog" href="' . encode_html( $url_open_dialog ) . '">';
        $html .= '<a href="#" onclick="jQuery.fn.mtDialog.open(\'' . encode_html( $url_open_dialog ) . '\');return false">';
        $html .= '(' . $revision_count . ')';
        $html .= '</a>';
    } else {
        $html .= '-';
    }
    $html .= '</span>';
    $html .= '</span>';
    return $html;
}

1;