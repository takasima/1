package EntryWorkflow::Util;
use strict;

use lib qw( addons/PowerCMS.pack/lib );
use PowerCMS::Util qw( is_user_can is_cms build_tmpl send_mail str2array get_array_uniq
                       current_user load_registered_template_for );
use MT::Util qw( encode_html );

my %__templates = (
    wf_message => {
        path => {
            text    => 'wf_message.tmpl',
            subject => 'wf_message_subject.tmpl',
        },
    },
    wf_published_message => {
        path => {
            text    => 'wf_published_message.tmpl',
            subject => 'wf_published_message_subject.tmpl',
        },
    },
);

sub author_post_limit_in_blog {
    my $blog_id = shift;
    my $blog;
    my $app = MT->instance;
    my $user = $app->user;
    return 1 if $user->is_superuser;
    return 0 if (! $blog_id );
    if ( ref $blog_id ) {
        $blog = $blog_id;
        $blog_id = $blog->id;
    }
    my $perms = $user->permissions( $blog_id );
    return 0 unless $perms;
    if ( $perms->can_administer_blog ) {
        return 0;
    }
    if ( my $categories = $perms->categories ) {
        return 1;
    }
    return 0;
}

sub can_create_in_category {
    my $category_id = shift;
    my $category;
    my $app = MT->instance;
    my $user = $app->user;
    return 1 if $user->is_superuser;
    return 0 if (! $category_id );
    if ( ref $category_id ) {
        $category = $category_id;
        $category_id = $category->id;
    } else {
        $category = MT->model( 'category' )->load( $category_id );
    }
    if (! $category ) {
        return 0;
    }
    return 0 if ( $category->class ne 'category' );
    my $perms = $user->permissions( $category->blog_id );
    return 0 unless $perms;
    if ( $perms->can_administer_blog ) {
        return 1;
    }
    if (! $perms->can_create_post ) {
        return 0;
    }
    if ( my $categories = $perms->categories ) {
        my @cats = split( /,/, $categories );
        if ( grep( /^$category_id$/, @cats ) ) {
            return 1;
        } else {
            return 0;
        }
    } else {
        return 1;
    }
    return 0;
}

sub can_edit_revision {
    my ( $revision, $author ) = @_;
    my $has_permission = 0;
    eval { 
        require PowerRevision::Util;
    };
    unless ( $@ ) {
        if ( PowerRevision::Util::is_user_can_revision( $revision, $author, 'can_edit_revision' ) ) {
            $has_permission++;
        }
    }
    return $has_permission;
}

sub can_edit_entry {
    my ( $entry, $author ) = @_;
    return 0 unless $entry;
    return 0 unless $author;
    my $blog = $entry->blog or return 0;
    my $admin = $author->is_superuser || is_user_can( $blog, $author, 'administer_blog' );
    if ( $admin ) {
        return 1;
    }
    my $publish_post = is_user_can( $blog, $author, 'publish_post' );
    my $edit_all_posts = is_user_can( $blog, $author, 'edit_all_posts' );
    if ( $edit_all_posts && $publish_post ) {
        return 1;
    }
    my $create_post = is_user_can( $blog, $author, 'create_post' );
    if ( $entry->approver_ids &&
         $entry->author_id ne $author->id
    ) { # under workflow
         return 0;
    }
#     elsif ( $edit_all_posts ) {
#         return 1;
#     }
    elsif ( ( $publish_post || $create_post ) &&
              $entry->author_id eq $author->id
    ) {
        return 1;
    }
    elsif ( $edit_all_posts &&
            ( $entry->status == MT::Entry::HOLD() )
    ){
        return 1;
    }
}

sub set_approver_ids_to_obj {
    my ( $obj, @push_ids ) = @_;
    return unless $obj;
    return unless $obj->has_column( 'approver_ids' );
    my $approver_ids = $obj->approver_ids;
    my @ids;
    if ( $approver_ids ) {
        @ids = str2array( $approver_ids );
    }
    if ( @push_ids ) {
        push( @ids, @push_ids );
    }
    @ids = get_array_uniq( @ids );
    $obj->approver_ids( join( ',', @ids ) );
    return $obj;
}

sub build_mail {
    my ( $app, $obj, $user, $options ) = @_;
    return unless $app;
    return unless $obj;
    return unless $user;
    my $change_author = $options->{ change_author };
    my $blog = $obj->blog;
    my $revision = $options->{ revision };
    my $plugin = MT->component( 'EntryWorkflow' );
    my $status = $revision ? $revision->status : $obj->status;
    my $status_text;
    if ( $status == MT::Entry::HOLD() ) {
        $status_text = 'Unpublished';
    } elsif ( $status == MT::Entry::RELEASE() ) {
        $status_text = 'Published';
    } elsif ( $status == MT::Entry::FUTURE() ) {
        $status_text = 'Scheduled';
    } elsif ( $status == MT::Entry::REVIEW() ) {
        $status_text = 'Draft(Prepublish)';
    } elsif ( $status == 7 ) {
        $status_text = 'Template';
    }
    $status_text = $plugin->translate( $status_text );
    my $param = $options->{ params } || {};
    $param->{ blog_id } = $blog->id;
    $param->{ blog_name } = $blog->name;
    $param->{ author_name } = $user->name;
    $param->{ author_nickname } = $user->nickname;
    $param->{ author_email } = $user->email;
    $param->{ entry_title } = $obj->title;
    $param->{ entry_id } = $obj->id;
    $param->{ entry_class } = $obj->class;
    $param->{ status_text } = $status_text;
    $param->{ message } = $options->{ message };
    $param->{ script_uri } = $app->base . $app->uri;
    $param->{ change_author_can_publish_post } = is_user_can( $blog, $change_author, 'publish_post' );
    $param->{ wf_status_approval } = $options->{ is_approval };
    if ( $revision ) {
        $param->{ is_revision } = 1;
        my $revision_id = $revision->id;
        $param->{ revision_id } = $revision_id;
        $param->{ entry_id } = $revision->object_id;
        $param->{ entry_title } = $revision->object_name;
    }
    my ( $tmpl_subect, $tmpl_body ) = load_registered_template_for( $blog->id, $plugin, ( $options->{ tmpl } || 'wf_message' ), \%__templates );
    my $subject;
    if ( ref $tmpl_subect && $tmpl_subect->can( 'subject' ) ) {
        $subject = build_tmpl( $app, $tmpl_subect->subject, {}, $param );
    } else {
        $subject = $app->build_page( $tmpl_subect, $param );
    }
    my $body = $app->build_page( $tmpl_body, $param );
    return ( $subject, $body );
}

sub get_wf_params {
    my ( $blog, $type, $user ) = @_;
    return unless $blog;
    return unless $type;
    return unless $user;
    my %wf_params;
    if ( is_user_can( $blog, $user, 'administer' ) ) {
        $wf_params{ wf_administer } = 1;
        $wf_params{ wf_can_publish } = 1;
    } elsif ( is_user_can( $blog, $user, 'publish_post' ) ) {
        $wf_params{ wf_publisher } = 1;
        $wf_params{ wf_can_publish } = 1;
    } elsif ( is_user_can( $blog, $user, $type . '_approval' ) ) {
        $wf_params{ wf_approver } = 1;
    } else {
        $wf_params{ wf_creator } = 1;
    }
    if (! is_user_can( $blog, $user, 'edit_all_posts' ) ) {
        $wf_params{ wf_not_edit_all_posts } = 1;
    }
    my $component = MT->component( 'PowerCMS' );
    if ( $component ) {
        $wf_params{ powercms_installed } = 1;
    }
    return \%wf_params;
}

sub get_loops {
    my ( $blog, $type, $user, $entry, $options ) = @_;
    return unless $blog;
    return unless $type;
    my $perm = $type . '_approval';
    my @authors = load_creater_entry( $blog, $type );
    my ( @creator_loop, @approver_loop, @publisher_loop, @administer_loop );
    my $i = 0;
    for my $author ( @authors ) {
        next if $user && $user->id == $author->id;
        unless ( $options->{ is_duplicate } ) {
            next if $entry && $entry->author_id == $author->id;
        }
        my $values = { author_id => $author->id,
                       author_email => $author->email,
                       author_name => $author->name,
                       author_nickname => $author->nickname,
                     };
        if ( is_user_can( $blog, $author, 'administer' ) ) {
            push( @administer_loop, $values );
            $i++;
        } elsif ( $type eq 'page' ) {
            if ( is_user_can( $blog, $author, 'manage_pages' ) ) {
                if ( is_user_can( $blog, $author, 'publish_post' ) ) {
                    push( @publisher_loop, $values );
                    $i++;
                } elsif ( is_user_can( $blog, $author, $perm ) ) {
                    push( @approver_loop, $values );
                    $i++;
                } else {
                    push( @creator_loop, $values );
                    $i++;
                }
            }
        } elsif ( is_user_can( $blog, $author, 'publish_post' ) ) {
            push( @publisher_loop, $values );
            $i++;
        } elsif ( is_user_can( $blog, $author, $perm ) ) {
            push( @approver_loop, $values );
            $i++;
        } elsif ( is_user_can( $blog, $author, 'create_post' ) ) {
            push( @creator_loop, $values );
            $i++;
        }
    }
    return ( \@creator_loop, \@approver_loop, \@publisher_loop, \@administer_loop );
}

# sub load_creater_entry {
#     my ( $blog, $class ) = @_;
#     my $create_perm  = $class eq 'page' ? '%manage_pages%' : '%create_post%';
#     my %params1 = ( blog_id     => $blog->id,
#                     permissions => { like => $create_perm } );
#     my %params2 = ( blog_id     => $blog->id,
#                     permissions => { like => '%publish_post%' } );
#     my %params3 = ( blog_id     => $blog->id,
#                     permissions => { like => '%administer%' } );
#     require MT::Permission;
#     my $terms   = { status => MT::Author::ACTIVE() }; # Ineffectual
#     my $params  = { 'join' => [ 'MT::Permission',
#                                 'author_id',
#                                 [ \%params1, '-or', \%params2, '-or', \%params3 ],
#                                 { unique => 1, },
#                               ],
#                   };
#     my @authors = MT->model( 'author' )->load( $terms, $params );
#     @authors = grep { $_->status == MT::Author::ACTIVE() } @authors;
#     return @authors;
# }

sub load_creater_entry {
    my ( $blog, $class ) = @_;
    my $join_terms = [ { blog_id => $blog->id, },
                       '-and',
                       [ { permissions => { like => ( $class eq 'page' ? '%manage_pages%' : '%create_post%' ) } },
                         '-or',
                         { permissions => { like => '%publish_post%' } },
                         '-or',
                         { permissions => { like => '%administer%' } },
                       ],
                     ];
    require MT::Permission;
    my $terms   = { status => MT::Author::ACTIVE() };
    my $args  = { 'join' => [ 'MT::Permission',
                              'author_id',
                              $join_terms,
                              { unique => 1, },
                            ],
                            sort => 'nickname',
                };
    my @authors = MT->model( 'author' )->load( $terms, $args );
    return @authors;
}

sub publish_log {
    my ( $class, $title ) = @_;
    my $plugin = MT->component( 'EntryWorkflow' );
    my $message = $plugin->translate( 'Publish [_1]\'[_2]\' was done.', 
                                      $plugin->translate( $class ),
                                      encode_html( $title ),
                                    );
    return save_log( $message );
}

sub workflow_log {
    my ( $class, $title, $user, $original_author, $changed_author ) = @_;
    return unless $class;
    return unless $user;
    return unless $original_author;
    return unless $changed_author;
    my $plugin = MT->component( 'EntryWorkflow' );
    my $phrase = $class eq 'entry'
                    ? "Entry '[_1]' was changed author to '[_2]'(ID:[_3]) from '[_4]'(ID:[_5]) by '[_6]'(ID:[_7])"
                    : "Page '[_1]' was changed author to '[_2]'(ID:[_3]) from '[_4]'(ID:[_5]) by '[_6]'(ID:[_7])";
    my $message = $plugin->translate( $phrase,
                                      encode_html( $title || '' ),
                                      encode_html( $changed_author->nickname || $changed_author->name ),
                                      encode_html( $changed_author->id ),
                                      encode_html( $original_author->nickname || $original_author->name ),
                                      encode_html( $original_author->id ),
                                      encode_html( $user->nickname || $user->name ),
                                      encode_html( $user->id ),
                                    );
    return save_log( $message );
}

sub save_log {
    my ( $message, $blog_id, $author_id ) = @_;
    return unless $message;
    my $app = MT->instance;
    unless ( $blog_id ) {
        if ( is_cms( $app ) ) {
            if ( my $blog = $app->blog ) {
                $blog_id = $blog->id;
            }
        }
    }
    unless ( $author_id ) {
        my $user = current_user( $app );
        if ( $user ) {
            $author_id = $user->id;
        }
    }
    require MT::Log;
    my $log = MT::Log->new;
    $log->message( $message );
    $log->class( 'workflow' );
    $log->blog_id( ( $blog_id || 0 ) );
    $log->author_id( ( $author_id || () ) );
    $log->level( MT::Log::INFO() );
    $log->save or die $log->errstr;
    return $log;
}

1;