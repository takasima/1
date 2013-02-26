# Movable Type (r) (C) 2007-2012 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package MT::Community::Tags;

use strict;

use MT::Util qw( offset_time_list epoch2ts ts2epoch );

###########################################################################

=head2 SignInLink

Overrides the core MT SignInLink tag to refer the sign-in link to the
Community script.

=cut

sub _hdlr_sign_in_link {
    my ( $ctx, $args ) = @_;
    my $cfg  = $ctx->{config};
    my $blog = $ctx->stash('blog');
    my $path = $ctx->invoke_handler('cgipath');
    $path .= '/' unless $path =~ m!/$!;
    my $community_script = $cfg->CommunityScript;
    my $static_arg = $args->{static} ? "&static=" . $args->{static} : '';
    my $e          = $ctx->stash('entry');
    return
          "$path$community_script?__mode=login$static_arg"
        . ( $blog ? '&blog_id=' . $blog->id : '' )
        . ( $e    ? '&entry_id=' . $e->id   : '' );
}

###########################################################################

=head2 SignOutLink

Outputs a link to the MT Comment script to allow a signed-in user to
sign out from the blog.

=cut

sub _hdlr_sign_out_link {
    my ( $ctx, $args ) = @_;
    my $cfg  = $ctx->{config};
    my $blog = $ctx->stash('blog');
    my $path = $ctx->invoke_handler('cgipath');
    $path .= '/' unless $path =~ m!/$!;
    my $community_script = $cfg->CommunityScript;
    my $static_arg;
    if ( $args->{no_static} ) {
        $static_arg = q();
    }
    else {
        my $url = $args->{static};
        if ( $url && ( $url ne '1' ) ) {
            $static_arg = "&static=" . MT::Util::encode_url($url);
        }
        elsif ($url) {
            $static_arg = "&static=1";
        }
        else {
            $static_arg = "&static=0";
        }
    }
    my $e = $ctx->stash('entry');
    return "$path$community_script?__mode=logout$static_arg"
        . ( $blog ? '&blog_id=' . $blog->id : '' )
        . ( $e ? "&amp;entry_id=" . $e->id : '' );
}

###########################################################################

=head2 CommunityScript

Returns the CGI script name for the Community script. The value of
the C<CommunityScript> configuration setting.

=for tags configuration

=cut

sub _hdlr_community_script {
    return MT->config('CommunityScript');
}

###########################################################################

=head2 IfEntryRecommended

A conditional tag that is true if one or more users have 'favorited'
(or 'recommended') the entry in context.

B<Example:>

    <mt:IfEntryRecommended>
        <mt:
    </mt:IfEntryRecommended>

=for tags entries, favorites

=cut

sub _hdlr_if_recommended {
    my ( $ctx, $args ) = @_;
    my $entry = $ctx->stash('entry')
        or return $ctx->_no_entry_error( $ctx->stash('tag') );

    $ctx->stash( 'cp_if_recommended_else', 1 );
    my $false_block = $ctx->else($args);
    if ( !$false_block && $ctx->errstr ) {
        return $ctx->error( $ctx->errstr );
    }
    $ctx->stash( 'cp_if_recommended_else', 0 );
    $ctx->stash( 'cp_if_recommended',      1 );
    my $true_block = $ctx->slurp($args);
    if ( !$true_block && $ctx->errstr ) {
        return $ctx->error( $ctx->errstr );
    }
    $ctx->stash( 'cp_if_recommended', 0 );

    my $arg_class = $args->{class} || 'scored';
    if ($arg_class) {
        $arg_class = MT::Util::remove_html($arg_class);
        $arg_class = ' class="' . $arg_class . '"';
    }
    my $arg_class_else = $args->{class_else} || 'scored-else';
    if ($arg_class_else) {
        $arg_class_else = MT::Util::remove_html($arg_class_else);
        $arg_class_else = ' class="' . $arg_class_else . '"';
    }

    my $cgi_path = $ctx->invoke_handler('cgipath');
    my $cp       = $ctx->{config}->CommunityScript;
    my $entry_id = $entry->id;
    my $blog_id  = $entry->blog_id;
    my $script   = <<SCRIPT;
<script type="text/javascript">
function scoredby_script_vote(id) {
    var xh = getXmlHttp();  
    if (!xh) return false;  
    xh.open('POST', '$cgi_path$cp', true);  
    xh.onreadystatechange = function() {  
        if ( xh.readyState == 4 ) {  
            if (xh.status && ( xh.status != 200 ) ) {  
                // error - ignore  
            } else {  
                eval( xh.responseText );  
            }  
         }  
   };  
   xh.setRequestHeader( 'Content-Type', 'application/x-www-form-urlencoded' );  
   xh.send( '__mode=vote&id=' + id + '&blog_id=$blog_id&f=scored,sum&jsonp=scoredby_script_callback' );  
}
function scoredby_script_callback(scores_hash) {
    var true_block = getByID('scored_' + $entry_id);
    var false_block = getByID('scored_' + $entry_id + '_else');
    var span;
    if (scores_hash['$entry_id'] && scores_hash['$entry_id'].scored) {
        span = getByID('cp_total_' + $entry_id);
        if (true_block)
            true_block.style.display = '';
        if (false_block) 
            false_block.style.display = 'none';
    }
    else {
        span = getByID('cp_total_' + $entry_id + '_else');
        if (true_block)
            true_block.style.display = 'none';
        if (false_block) 
            false_block.style.display = '';
    }
    if (span) {
        if (scores_hash['$entry_id'] && scores_hash['$entry_id'].sum)
            span.innerHTML = scores_hash['$entry_id'].sum;
        else
            span.innerHTML = 0;
    }
}
</script>
SCRIPT
    my $out = <<OUTPUT;
$script
<div id="scored_$entry_id"$arg_class style="display:none">
    $true_block
</div>
<div id="scored_${entry_id}_else"$arg_class_else style="display:none">
    $false_block
</div>
<script type="text/javascript" src="${cgi_path}${cp}?__mode=score&blog_id=$blog_id&id=$entry_id&f=scored,sum&jsonp=scoredby_script_callback"></script>
OUTPUT

    return $ctx->build($out);
}

sub _context_error {
    my ( $ctx, $tag ) = @_;
    $tag = 'MT' . $tag unless $tag =~ m/^MT/i;
    return $ctx->error(
        MT->translate(
            "You used an '[_1]' tag outside of the block of MTIfEntryRecommended; "
                . "perhaps you mistakenly placed it outside of an 'MTIfEntryRecommended' container?",
            $tag
        )
    );
}

###########################################################################

=head2 EntryRecommendedTotal

This tag returns the total number of votes an entry has received. It will
generate the text inside of a span tag. For example (where 45 is the
current entry's id):

    <span id="cp_total_45" class="recommended"></span>

A javascript function will then populate this tag with the proper value
when the page has loaded, to ensure the most accurate count.

B<Attributes:>

=over 4

=item * class

The CSS class name to assign to the element returned.

=back

=for tags entries, favorities

=cut

sub _hdlr_recommended_total {
    my ( $ctx, $args ) = @_;
    my $else = $ctx->stash('cp_if_recommended_else');
    unless ($else) {
        $ctx->stash('cp_if_recommended')
            or return _context_error( $ctx, $ctx->stash('tag') );
    }

    my $entry = $ctx->stash('entry')
        or return $ctx->_no_entry_error( $ctx->stash('tag') );

    my $class = $args->{class} || '';
    if ($class) {
        $class = MT::Util::remove_html($class);
        $class = ' class="' . $class . '"';
    }
    my $entry_id = $entry->id;
    my $id       = "cp_total_$entry_id";
    $id .= "_else" if $else;

    return "<span id=\"$id\"$class></span>";
}

###########################################################################

=head2 EntryRecommendVoteLink

When used within the context of an entry, this tag will return a link
that will allow someone to vote for the current item, if they have not
already voted.

The link generated will look something like this:

    <a href="javascript:void(0)" onclick="scoredby_script_vote('1');" 
        class="recommend">Click here</a>

B<Attributes:>

=over 4

=item * class

The CSS class name to assign to the HTML C<a> tag.

=item * text

The text to include inside the link, e.g. "Click here to recommend"

=back

B<Namespace:>

The recommendations/votes are recorded in the "community_pack_recommend"
namespace.

=for tags entries, favorites

=cut

sub _hdlr_recommend_votelink {
    my ( $ctx, $args ) = @_;
    $ctx->stash('cp_if_recommended_else') || $ctx->stash('cp_if_recommended')
        or return _context_error( $ctx, $ctx->stash('tag') );

    my $entry = $ctx->stash('entry')
        or return $ctx->_no_entry_error( $ctx->stash('tag') );

    my $class = $args->{class} || '';
    if ($class) {
        $class = MT::Util::remove_html($class);
        $class = ' class="' . $class . '"';
    }

    my $text = $args->{text} || MT->translate('Click here to recommend');
    if ($text) {
        $text = MT::Util::remove_html($text);
    }
    my $entry_id = $entry->id;

    return
        "<a href=\"javascript:void(0)\" onclick=\"scoredby_script_vote('$entry_id');\"$class>$text</a>";
}

###########################################################################

=head2 IfAnonymousRecommendAllowed

Returns true if the blog in the current context allows anonymous readers
to vote for entries.

Anonymous users are allowed to vote only once for a given entry. They are
throttled by IP address to help prevent fraud. In other words, no entry
is allowed to be voted for twice from the same IP address. This keeps
from anonymous users from artificially inflating scores just voting for
the same entry over and over again.

To toggle your settings for allowing anonymous users to vote on an entry,
navigate to your Blog Preferences menu. From there select "Community
Preferences."

=for tags configuration, favorites

=cut

sub _hdlr_if_anon_recommend {
    my ( $ctx, $args ) = @_;
    my $blog = $ctx->stash('blog')
        or return $ctx->_no_entry_error( $ctx->stash('tag') );

    my $class = MT->model('blog.community');
    unless ( $class eq ref($blog) ) {
        $blog = $class->load( $blog->id );
    }
    if (   $blog->has_meta('allow_anon_recommend')
        && $blog->allow_anon_recommend )
    {
        $ctx->slurp($args);
    }
    else {
        $ctx->else($args);
    }
}

###########################################################################

=head2 IfLoggedIn

This template tag actually outputs two segments of HTML text. However only
one of them will be rendered visible if the user is logged in. For example,
suppose you want to show users that were logged in the text "Edit Your
Profile" and users that were not logged in the text "Register Now!". Then
this is the template tag you would use:

    <mt:IfLoggedIn script="show" id ="logged_in">
      <a href="<MTEditProfileLink>">Edit Profile</a>
    <mt:Else>
      <a href="<MTRegisterLink>">Register Now!</a>
    </mt:IfLoggedIn>

B<Attributes:>

=over 4

=item * element_id

The base DOM id of the element you wish to pass to the javascript callback
identified by the script argument.

=item * script

The JavaScript function name you will invoke (see JavaScript Callback).

=back

B<JavaScript Callback>

One can optionally make a call to a JavaScript function and pass to it
the logged-in state of the current user, along with an element id.

Here is an example JavaScript function you can call:

    function show( isLoggedIn, domId ) {
      if (isLoggedIn) {
        show(domId);
      } else {
        show(domId + "_else");
      }
    }

=for tags authors

=cut

sub _hdlr_if_logged_in {
    my ( $ctx, $args ) = @_;

    $ctx->stash( 'cp_if_logged_in_else', 1 );
    my $false_block = $ctx->else($args);
    if ( !$false_block && $ctx->errstr ) {
        return $ctx->error( $ctx->errstr );
    }
    $ctx->stash( 'cp_if_logged_in_else', 0 );
    $ctx->stash( 'cp_if_logged_in',      1 );
    my $true_block = $ctx->slurp($args);
    if ( !$true_block && $ctx->errstr ) {
        return $ctx->error( $ctx->errstr );
    }
    $ctx->stash( 'cp_if_logged_in', 0 );

    my $elem_id = $args->{element_id} || 'logged_in';
    if ($elem_id) {
        $elem_id = MT::Util::remove_html($elem_id);
    }
    my $arg_class      = q();
    my $arg_class_else = q();
    if ( exists $args->{class} ) {
        $arg_class      = $args->{class};
        $arg_class      = MT::Util::remove_html($arg_class);
        $arg_class_else = ' class="' . $arg_class . '-else"';
        $arg_class      = ' class="' . $arg_class . '"';
    }

    my $script_block = q();
    my $script       = $args->{script};
    if ($script) {
        $script_block = <<SCRIPT;
<script type="text/javascript">
var is_loggedin = false;
if ( typeof(mtGetUser) == 'undefined' )
    is_loggedin = user ? true : false;
else {
    var u = mtGetUser();
    is_loggedin = u && u.name ? true : false;
}
$script(is_loggedin ? 1 : 0, '$elem_id');
</script>
SCRIPT
    }

    my $out = <<TMPL;
<div id="$elem_id"$arg_class style="display:none" class=\"inline\">
$true_block
</div>
<div id="${elem_id}_else"$arg_class_else style="display:none" class=\"inline\">
$false_block
</div>
$script_block
TMPL
    $out;
}

###########################################################################

=head2 AuthorComments

This template tag is used to retrieve a list of all the comments left by
the current author in context. It is used for example on a user's
profile page to list the comments they have left within the system.

B<Attributes:>

This template tag uses all the same attributes as the L<Comments>
template tag.

=for tags authors, comments

=cut

sub _hdlr_author_comments {
    my ( $ctx, $args, $cond ) = @_;
    my $blog_id = 0;
    my $blog    = $ctx->stash('blog');
    $blog_id = $blog->id if $blog;
    my $author = $ctx->stash('author');
    return '' unless $author;
    require MT::Comment;
    my @comments = MT::Comment->load(
        {   commenter_id => $author->id,
            ( $blog_id ? ( blog_id => $blog_id ) : () ),
            visible => 1,
        },
        {   'sort'    => 'created_on',
            direction => 'descend',
            limit     => ( $args->{lastn} || 20 ),
        }
    );
    local $ctx->{__stash}{comments} = \@comments;
    return $ctx->tag( 'Comments', $args, $cond );
}

###########################################################################

=head2 AuthorCommentResponses

This template tag is used to retrieve a list of all the comments that
have followed comments left by the author currently in context. In other
words, say Joe leaves a comment on entry foo. Then Jay, Kate and Ezra
leave comments after Joe. This template tag will retrieve all the
comments left by Jay, Kate and Ezra on entry foo, in addition to all
of the comments left by other users on other posts that Joe has
commented on.

B<Attributes:>

This template tag uses all the same attributes as the L<Comments>
template tag (excluding MultiBlog related attributes such as
include_blogs, exclude_blogs and blog_ids).

=for tags authors, comments

=cut

sub _hdlr_author_comment_responses {
    my ( $ctx, $args, $cond ) = @_;
    my $blog_id = 0;
    my $blog    = $ctx->stash('blog');
    $blog_id = $blog->id if $blog;
    my $author = $ctx->stash('author');
    return '' unless $author;
    local $ctx->{__stash}{comments} = comments_from_threads(
        {   author_id => $author->id,
            blog_id   => $blog_id,
            lastn     => ( $args->{lastn} || 20 )
        }
    );
    return $ctx->tag( 'Comments', $args, $cond );
}

sub comments_from_threads {
    my ($args) = @_;

    my $author_id = $args->{author_id};
    my $blog_id = $args->{blog_id} || 0;

    # Vox-style listing of all comments posted to entries a commenter
    # has participated in, subsequent to their own first comment to that
    # entry.

    # Recently commented on entries for threads they've posted to
    require MT::Entry;
    require MT::Comment;
    my $entry_iter = MT::Entry->load_iter(
        { ( $blog_id ? ( blog_id => $blog_id ) : () ) },
        {   join => MT::Comment->join_on(
                'entry_id',
                {   ( $blog_id ? ( blog_id => $blog_id ) : () ),
                    commenter_id => $author_id,
                    visible      => 1,
                },
                { unique => 1 }
            ),
            'sort'    => 'created_on',
            direction => 'descend',
        }
    );

    my $lastn = $args->{lastn};

    my @threads;
    while ( my $entry = $entry_iter->() ) {
        my $first_post = MT::Comment->load(
            {   entry_id     => $entry->id,
                commenter_id => $author_id,
            },
            {   'sort'    => 'created_on',
                direction => 'ascend',
                limit     => 1,
            }
        );
        my $comment_iter = MT::Comment->load_iter(
            {   entry_id     => $entry->id,
                created_on   => [ $first_post->created_on, undef, ],
                id           => [ $first_post->id, undef ],
                commenter_id => $author_id,
                visible      => 1,
            },
            {

                # Only consider comments with a creation date
                # following the date of the first comment by
                # author in context.
                range_incl => { created_on => 1 },

                # Select only comments _following_ the first comment
                # by the author in context.
                range => { id => 1 },

                # Skip replies by author in context.
                not               => { commenter_id => 1 },
                'sort'            => 'created_on',
                direction         => 'descend',
                no_cached_prepare => 1,
            }
        );
        push @threads, $comment_iter if $comment_iter;
    }

    my $picker = sub {
        my ( $candidate, $existing ) = @_;
        ( $candidate->created_on gt $existing->created_on );
    };
    require MT::Util;
    my $master_iter = MT::Util::multi_iter( \@threads, $picker );

    my @comments;
    while ( my $comment = $master_iter->() ) {
        push @comments, $comment;
        if ( @comments == $lastn ) {
            $master_iter->end;
            last;
        }
    }
    \@comments;
}

###########################################################################

=head2 AuthorFavoriteEntries

This template tag returns a list of entries flagged as a favorite by the
current author in context.

=for tags authors, favorites, entries, loop

=cut

sub _hdlr_author_favorite_entries {
    my ( $ctx, $args, $cond ) = @_;
    my $blog_id = 0;
    my $blog    = $ctx->stash('blog');
    $blog_id = $blog->id if $blog;
    my $author = $ctx->stash('author');
    return '' unless $author;

    require MT::ObjectScore;
    require MT::Entry;
    require MT::App::Community;
    my @entries = MT::Entry->load(
        {   status => MT::Entry->RELEASE(),
            ( $blog_id ? ( blog_id => $blog_id ) : () ),
        },
        {   join => MT::ObjectScore->join_on(
                'object_id',
                {   author_id => $author->id,
                    object_ds => MT::Entry->datasource,
                    namespace => MT::App::Community->NAMESPACE(),
                },
                {   limit     => 5,
                    sort_by   => 'created_on',
                    direction => 'descend',
                    unique    => 1,
                }
            ),
        }
    );
    local $ctx->{__stash}{entries} = \@entries;
    return $ctx->tag( 'Entries', $args, $cond );
}

sub _smart_objects_from_sets {
    my (%param) = @_;
    my ( $sets, $sort_field, $sort_dir, $limit )
        = @param{qw( sets sort_field sort_dir limit )};

    my %next;
    @next{ keys %$sets } = map { shift @$_ } values %$sets;

    my @objects;
    while ( %next && ( !$limit || ( $limit < @objects ) ) ) {
        my @nexts = map { [ $_, $next{$_}, $next{$_}->$sort_field() ] }
            keys %$sets;
        my ($next)
            = $sort_dir eq 'ascend'
            ? sort { $a->[2] cmp $b->[2] } @nexts
            : sort { $b->[2] cmp $a->[2] } @nexts;
        push @objects, $next;

        my ($type) = $next->[0];
        $next{$type} = shift @{ $sets->{$type} }
            or delete $sets->{$type};
    }

    return \@objects;
}

sub _naive_objects_from_sets {
    my (%param) = @_;
    my ( $sets, $sort_field, $sort_dir, $limit, $default_sort )
        = @param{qw( sets sort_field sort_dir limit default_sort )};

    my @objects;
    my $default_sort_field = {
        entry   => 'authored_on',
        comment => 'created_on',
        score   => 'created_on',
    };
    while ( my ( $type, $set ) = each %$sets ) {
        my $sort = $default_sort ? $default_sort_field->{$type} : $sort_field;
        for my $obj (@$set) {
            push @objects, [ $type, $obj, $obj->$sort() ];
        }
    }

    @objects
        = $sort_dir eq 'ascend'
        ? sort { $a->[2] cmp $b->[2] } @objects
        : sort { $b->[2] cmp $a->[2] } @objects;
    delete @objects[ $limit .. $#objects ] if $limit;

    return \@objects;
}

sub set_author_load_context {
    my $ctx = shift;
    my ( $attr, $terms, $args ) = @_;

    my (%author_terms);
    my %author_fields = (
        nickname => 'display_name',
        id       => 'author_id',
        name     => 'username',
    );
    while ( my ( $au_field, $arg_field ) = each %author_fields ) {
        $author_terms{$au_field} = $attr->{$arg_field}
            if exists $attr->{$arg_field};
    }
    if (%author_terms) {
        my @authors = MT->model('author')
            ->load( \%author_terms, { fetchonly => ['id'] } );
        $terms->{author_id}
            = 1 == @authors ? $authors[0]->id : [ map { $_->id } @authors ];
    }
    elsif ( my $author = $ctx->stash('author') ) {
        $terms->{author_id} = $author->id;
    }

    return 1;
}

sub actions {
    my ( $terms, $args, %opts ) = @_;
    my $default_sort = $opts{default_sort};
    my $lastn        = $opts{lastn};

    my %sets;
    {
        my %entry_terms = %$terms;
        delete $entry_terms{namespace};
        $entry_terms{authored_on} = delete $entry_terms{$default_sort}
            if $default_sort && $entry_terms{$default_sort};
        $entry_terms{status} = MT::Entry::RELEASE();
        $entry_terms{class} = { op => '!=', value => 'page' };

        my %entry_args = %$args;
        $entry_args{sort} = 'authored_on' if ( $default_sort || $lastn );
        if ( $args->{days} ) {
            $entry_args{range_incl} = { %{ $entry_args{range_incl} } };
            $entry_args{range_incl}{authored_on}
                = delete $entry_args{range_incl}{created_on};
        }

        $sets{entry}
            = [ MT->model('entry')->load( \%entry_terms, \%entry_args ) ];
    }
    {
        my %comment_terms = %$terms;
        delete $comment_terms{namespace};
        $comment_terms{commenter_id} = delete $comment_terms{author_id}
            if $comment_terms{author_id};
        $comment_terms{visible} = 1;
        $sets{comment}
            = [ MT->model('comment')->load( \%comment_terms, $args ) ];
    }
    {
        my %score_terms = %$terms;
        if ( !$score_terms{namespace} ) {
            require MT::App::Community;
            $score_terms{namespace} = MT::App::Community->NAMESPACE();
        }
        $score_terms{object_ds} = 'entry';    # entries only for now
        delete $score_terms{blog_id};
        my %score_args = %$args;
        $score_args{join} = MT->model('entry')->join_on(
            undef,
            {   id     => \'=objectscore_object_id',
                status => MT::Entry::RELEASE(),
            },
            { unique => 1 }
        );
        $sets{score} = [
            MT->model('objectscore')->load( \%score_terms, \%score_args ) ];
    }

    my $objects = _naive_objects_from_sets(
        sets         => \%sets,
        sort_field   => $args->{'sort'} || 'created_on',
        sort_dir     => $args->{direction} || 'descend',
        limit        => $args->{limit},
        default_sort => ( $default_sort || $lastn ),
    );

    return $objects;
}

###########################################################################

=head2 Actions

A container tag for actions. By default it will loop over all of the
actions associated with the current user in context. The author_id tag
can be used to indicated which author to load and display actions for.
Once inside the loop, additional tags can be used to display details
about each action as Movable Type iterates through each action.

B<Attributes:>

=over 4

=item * sort

Acceptable values: C<authored_on> and C<created_on>.

=item * days

The number of days to display actions for (default is 25).

=item * range_incl

=item * namespace

=item * author_id

=item * object_ds

=item * direction

Acceptable values: C<descend> and C<ascend>.

=item * limit

=item * lastn

=item * sort_by

=item * sort_order

=back

B<Example:>

    <mt:Actions namespace="community_pack_recommend" include_blogs="all" sort_order="descend" lastn="30">
        <mt:ActionsHeader>
        <ul class="recent-actions">
        </mt:ActionsHeader>
        <mt:ActionsEntry>
            <li class="entry icon-entry">
                Posted <a href="<$mt:EntryLink>"><$mt:EntryTitle encode_html="1"$></a> to 
                <a href="<$MTEntryBlogURL$>" class="icon-blog"><$MTEntryBlogName$></a>
                <div class="excerpt"><$MTEntryExcerpt$></div>
            </li>
        </mt:ActionsEntry>
        <mt:ActionsComment>
            <li class="comment icon-comment">
                Commented on
                <mt:CommentEntry>
                <a href="<$mt:CommentLink$>"><$mt:EntryTitle encode_html="1"$></a>
                </mt:CommentEntry>
                <div class="excerpt"><$mt:CommentBody words="40"$>...</div>
            </li>
        </mt:ActionsComment>
        <mt:ActionsFavorite>
            <li class="favorite icon-favorite">
                Favorited <$mt:EntryTitle encode_html="1"$></a> on 
                <a href="<$mt:EntryLink$>">%%<a href="<$MTEntryBlogURL$>" class="icon-blog"><$MTEntryBlogName$></a>
            </li>
        </mt:ActionsFavorite>
        <mt:ActionsFooter>
        </ul>
        </mt:ActionsFooter>
    <mt:else>
        <p class="note">No recent actions.</p>
    </mt:Actions>

=for tags actions, loop

=cut

###########################################################################

=head2 ActionsComment

This template tag must be contained by the L<Actions> tag and will
display its contents only if the current action in context is a comment.
In other words, if the current action relates to a user posting a comment
then this tag can then be used to output details relating to that comment
using all of Movable Type's comment tags.

B<Example:>

    <mt:Actions namespace="community_pack_recommend" include_blogs="all" sort_order="descend" lastn="30">
        <mt:ActionsHeader>
        <ul class="recent-actions">
        </mt:ActionsHeader>
        <mt:ActionsComment>
            <li class="comment icon-comment">
                Commented on
                <mt:CommentEntry>
                <a href="<$mt:CommentLink$>"><$mt:EntryTitle encode_html="1"$></a>
                </mt:CommentEntry>
                <div class="excerpt"><$mt:CommentBody words="40"$>...</div>
            </li>
        </mt:ActionsComment>
        <mt:ActionsFooter>
        </ul>
        </mt:ActionsFooter>
    </mt:Actions>

=for tags comments, actions

=cut

###########################################################################

=head2 ActionsEntry

This template tag must be contained by the L<Actions> tag and will
display its contents only if the current action in context is an
entry. In other words, if the current action relates to a user
creating an entry then this tag can then be used to output details
relating to that entry using all of Movable Type's entry tags.

    <mt:Actions namespace="community_pack_recommend" include_blogs="all" sort_order="descend" lastn="30">
        <mt:ActionsHeader>
        <ul class="recent-actions">
        </mt:ActionsHeader>
        <mt:ActionEntry>
            <li class="entry icon-entry">
                Posted <a href="<$mt:EntryLink>"><$mt:EntryTitle encode_html="1"$></a> to 
                <a href="<$MTEntryBlogURL$>" class="icon-blog"><$MTEntryBlogName$></a>
                <div class="excerpt"><$MTEntryExcerpt$></div>
            </li>
        </mt:ActionEntry>
        <mt:ActionsFooter>
        </ul>
        </mt:ActionsFooter>
    </mt:Actions>

=for tags entries, actions

=cut

###########################################################################

=head2 ActionsFavorite

This template tag must be contained by the L<Actions> tag and will display
its contents only if the current action in context is a "favorite." A
"favorite" being when a user votes for, recommends or marks an entry as
a favorite entry. In other words, if the current action relates to a
user favoriting an entry, this tag can then be used to output details
relating to that entry using all of Movable Type's entry tags.

B<Example:>

    <mt:Actions namespace="community_pack_recommend" include_blogs="all" sort_order="descend" lastn="30">
        <mt:ActionsHeader>
        <ul class="recent-actions">
        </mt:ActionsHeader>
        <mt:ActionFavorite>
            <li class="entry icon-favorite">
                Favorited <$mt:EntryTitle encode_html="1"> on <$mt:EntryBlogName$>
            </li>
        </mt:ActionEntry>
        <mt:ActionsFooter>
        </ul>
        </mt:ActionsFooter>
    </mt:Actions>

=for tags actions, favorites

=cut

sub _hdlr_actions {
    my ( $ctx, $args, $cond ) = @_;
    my ( %terms, %args );

    my $objects;
    if ( $objects = $ctx->stash('actions') ) {

        # All done, let's build.
    }
    else {
        $ctx->set_blog_load_context( $args, \%terms, \%args )
            or return;
        set_author_load_context( $ctx, $args, \%terms, \%args )
            or return;

        # TODO: support offset argument?
        my $lastn = $args->{lastn};
        my $limit = $lastn || $args->{limit};
        $limit ||= 25 if $args->{days};
        my $default_sort;
        my $sort_field = $args->{sort_by} || ( $default_sort = 'created_on' );
        my $sort_dir
            = !$args->{sort_order} ? 'ascend'
            : $args->{sort_order} eq 'ascend' ? 'ascend'
            :                                   'descend';

        my ( $re_sort_field, $re_sort_dir );
        if ( $lastn && !$default_sort ) {
            ( $re_sort_field, $re_sort_dir ) = ( $sort_field, $sort_dir );
            ( $sort_field, $sort_dir ) = ( 'created_on', 'descend' );
        }
        if ( my $days = $args->{days} ) {
            my @ago = offset_time_list( time - 3600 * 24 * $days,
                $ctx->stash('blog_id') );
            my $ago = sprintf '%04d%02d%02d%02d%02d%02d',
                $ago[5] + 1900, $ago[4] + 1, @ago[ 3, 2, 1, 0 ];
            $terms{created_on} = [$ago];
            $args{range_incl}{created_on} = 1;
        }

        @args{qw( limit sort direction )}
            = ( $limit, $sort_field, $sort_dir );

        $terms{namespace} = $args->{namespace};

        $objects = actions(
            \%terms,
            \%args,
            default_sort => $default_sort,
            lastn        => $lastn,
        );

        return $ctx->else( $args, $cond )
            if !@$objects;

        if ($re_sort_field) {
            my @new_objects
                = map { [ $_->[0], $_->[1], $_->[1]->$re_sort_field() ] }
                @$objects;
            $objects
                = $re_sort_dir eq 'ascend'
                ? [ sort { $a->[2] cmp $b->[2] } @new_objects ]
                : [ sort { $b->[2] cmp $a->[2] } @new_objects ];
        }
    }

    # build
    my $res     = '';
    my $count   = 0;
    my $vars    = $ctx->{__stash}{vars} ||= {};
    my $builder = $ctx->{__stash}{builder};
    my $tokens  = $ctx->{__stash}{tokens};
OBJ: for my $obj_info (@$objects) {
        my ( $type, $obj ) = @$obj_info;

        my %data;
        my %type_cond = (
            ActionsEntry    => 0,
            ActionsComment  => 0,
            ActionsFavorite => 0
        );
        local $vars->{activity_type} = $type;
        if ( $type eq 'entry' ) {
            $type_cond{ActionsEntry} = 1;
            $data{entry}             = $obj;
            $data{author}            = $obj->author;
            $data{blog}              = $obj->blog;
            $data{blog_id}           = $obj->blog_id;
        }
        elsif ( $type eq 'comment' ) {
            $type_cond{ActionsComment} = 1;
            $data{comment}             = $obj;
            $data{entry}               = $obj->entry;
            my $author_id = $obj->commenter_id
                or next OBJ;
            $data{author} = MT->model('author')->load($author_id)
                or next OBJ;
            $data{blog}    = $obj->blog;
            $data{blog_id} = $obj->blog_id;
        }
        elsif ( $type eq 'score' ) {
            my $entry = MT->model( $obj->object_ds )->load( $obj->object_id );
            if ( my $score_blog_id = $terms{blog_id} ) {
                if ( !ref $score_blog_id ) {
                    next OBJ if $entry->blog_id != $score_blog_id;
                }
                elsif ( 'ARRAY' eq ref $score_blog_id ) {

                    # next unless entry's blog id is in the list
                    next OBJ
                        if !grep { $_ == $entry->blog_id } @$score_blog_id;
                }
            }

            $type_cond{ActionsFavorite} = 1;
            $data{score}                = $obj;
            $data{entry}                = $entry;
            $data{author} = MT->model('author')->load( $obj->author_id )
                or next OBJ;
            $data{blog}    = $entry->blog;
            $data{blog_id} = $entry->blog_id;
        }

        local @{ $ctx->{__stash} }{ keys %data } = values %data;

        $count++;
        local $vars->{__first__}   = $count == 1;
        local $vars->{__last__}    = $count == @$objects;
        local $vars->{__odd__}     = ( $count % 2 ) == 1;
        local $vars->{__even__}    = ( $count % 2 ) == 0;
        local $vars->{__counter__} = $count;

        my $out = $builder->build(
            $ctx, $tokens,
            {   ActionsHeader => $vars->{__first__} ? 1 : 0,
                ActionsFooter => $vars->{__last__}  ? 1 : 0,
                %type_cond,
                %$cond,
            }
        );

        return $ctx->error( $builder->errstr )
            if !defined $out;
        $res .= $out;
    }
    return $res;
}

###########################################################################

=head2 ActionsHeader

A conditional block tag that is true when the first action is published
in a L<Actions> loop tag.

B<Example:>

    <mt:Actions>
        <mt:ActionsHeader>
            <h3>Actions</h3>
            <ul>
        </mt:ActionsHeader>
        <mt:ActionsEntry>
            <li>
                Posted <a href="<$mt:EntryLink$>">
                    <$mt:EntryTitle encode_html="1"$></a>
            </li>
        </mt:ActionsEntry>
        <mt:ActionsFooter>
            </ul>
        </mt:ActionsFooter>
    </mt:Actions>

=for tags actions

=cut

###########################################################################

=head2 ActionsFooter

A conditional block tag that is true when the last action is published
in a L<Actions> loop tag.

B<Example:>

    <mt:Actions>
        <mt:ActionsHeader>
            <h3>Actions</h3>
            <ul>
        </mt:ActionsHeader>
        <mt:ActionsEntry>
            <li>
                Posted <a href="<$mt:EntryLink$>">
                    <$mt:EntryTitle encode_html="1"$></a>
            </li>
        </mt:ActionsEntry>
        <mt:ActionsFooter>
            </ul>
        </mt:ActionsFooter>
    </mt:Actions>

=for tags actions

=cut

###########################################################################

=head2 ScoreDate

Provides the date of the 'score' in context. See L<Date> for formatting
attributes.

=for tags scoring, date

=cut

sub _hdlr_score_date {
    my ( $ctx, $args, $cond ) = @_;
    my $c_on = $ctx->stash('score')->created_on;
    local $args->{ts};
    if ($c_on) {

        # friending has no blog context, so needs to be converted from GMT
        require MT::Community::Friending;
        if ( $ctx->stash('score')->namespace eq
            MT::Community::Friending::FRIENDING() )
        {
            $args->{ts}
                = epoch2ts( $ctx->stash('blog'), ts2epoch( undef, $c_on ) );
        }
        else {
            $args->{ts} = $c_on;
        }
    }
    $ctx->invoke_handler( 'date', $args );
}

## Friending related tags

###########################################################################

=head2 AuthorFollowersCount

Provides the number of people following the current author in context.

B<Examples:>

    <h2><$mt:AuthorName escape="html"$></h2>
    <h3><$mt:AuthorFollowersCount$> readers</h3>

=for tags authors, community, friending, count

=cut

sub _hdlr_followers_count {
    my ( $ctx, $args, $cond ) = @_;
    my $author = $ctx->stash('author')
        or return $ctx->_no_author_error('MTAuthorFollowersCount');

    require MT::Community::Friending;
    return $ctx->count_format(
        MT->model('objectscore')->count(
            {   object_id => $author->id,
                object_ds => 'author',
                score     => [ MT::Community::Friending::CONTACT(), undef ],
                namespace => MT::Community::Friending::FRIENDING()
            },
            { range_incl => { score => 1 }, }
        ),
        $args
    );
}

###########################################################################

=head2 AuthorFollowingCount

Provides the number of authors the current author in context is following.

B<Examples:>

    <h2><$mt:AuthorName escape="html"$></h2>
    <h3>Reading <$mt:AuthorFollowingCount$> authors</h3>

=for tags authors, community, friending, count

=cut

sub _hdlr_following_count {
    my ( $ctx, $args, $cond ) = @_;
    my $author = $ctx->stash('author')
        or return $ctx->_no_author_error('MTAuthorFollowingCount');

    require MT::Community::Friending;
    return $ctx->count_format(
        MT->model('objectscore')->count(
            {   author_id => $author->id,
                object_ds => 'author',
                score     => [ MT::Community::Friending::CONTACT(), undef ],
                namespace => MT::Community::Friending::FRIENDING()
            },
            { range_incl => { score => 1 }, }
        ),
        $args
    );
}

###########################################################################

=head2 AuthorFollowLink

Provides the HTML code for a clickable link that adds the author in context to
the authors the viewer is following.

B<Attributes:>

=over 4

=item class (optional)

An HTML class or space-separated list of classes to use on the link tag.

=item text (optional; default "Click here to follow")

The clickable text to display in the link.

=back

B<Examples:>

    <h2><$mt:AuthorName escape="html"$></h2>
    <mt:AuthorIfFollowed>
    <mt:Else>
        <mt:AuthorFollowLink text="Follow this author">
    </mt:AuthorIfFollowed>

=for tags authors, community, friending

=cut

sub _hdlr_follow_link {
    my ( $ctx, $args, $cond ) = @_;
    my $author = $ctx->stash('author')
        or return $ctx->_no_author_error('MTAuthorFollowLink');
    my $class = $args->{class} || '';
    if ($class) {
        $class = MT::Util::remove_html($class);
        $class = ' class="' . $class . '"';
    }

    my $plugin = MT->component("community");

    # TODO: don't use "Click here"
    my $text = $args->{text} || $plugin->translate('Click here to follow');
    if ($text) {
        $text = MT::Util::remove_html($text);
    }
    my $author_id = $author->id;

    # TODO: don't use javascript: href
    # TODO: don't use an id for a repeatable construct
    # TODO: probably don't even hardcode HTML here at all
    return
        "<a id=\"follow-link\" href=\"javascript:void(0)\" onclick=\"script_follow('$author_id');\"$class>$text</a>";
}

###########################################################################

=head2 AuthorUnfollowLink

Provides the HTML code for a clickable link that removes the author in context
from the authors the viewer is following.

B<Attributes:>

=over 4

=item class (optional)

An HTML class or space-separated list of classes to use on the link tag.

=item text (optional; default "Click here to follow")

The clickable text to display in the link.

=back

B<Examples:>

    <h2><$mt:AuthorName escape="html"$></h2>
    <mt:AuthorIfFollowed>
        <mt:AuthorUnfollowLink text="Stop following this author">
    </mt:AuthorIfFollowed>

=for tags authors, community, friending

=cut

sub _hdlr_unfollow_link {
    my ( $ctx, $args, $cond ) = @_;
    my $author = $ctx->stash('author')
        or return $ctx->_no_author_error('MTAuthorUnfollowLink');
    my $class = $args->{class} || '';
    if ($class) {
        $class = MT::Util::remove_html($class);
        $class = ' class="' . $class . '"';
    }

    my $plugin = MT->component("community");
    my $text = $args->{text} || $plugin->translate('Click here to leave');
    if ($text) {
        $text = MT::Util::remove_html($text);
    }
    my $author_id = $author->id;

    return
        "<a id=\"unfollow-link\" href=\"javascript:void(0)\" onclick=\"script_leave('$author_id');\"$class>$text</a>";
}

###########################################################################

=head2 AuthorFollowingEntries

Lists entries that were authored by authors whom the author currently in
context is following.

B<Attributes:>

=over 4

=item lastn (optional; default 20)

The number of entries to list. If given, the most recently submitted entries
are listed.

=item sort_order (optional)

If given in absence of C<lastn>, the entries are listed in order of the field
specified by C<sort_by>. If C<sort_order> is C<ascend>, the entries are listed
in ascending (I<A> to I<Z>, oldest to newest) order; if C<descend>, descending
(I<Z> to I<A>, newest to oldest) order.

=item sort_by (optional)

If C<sort_order> is given in absence of C<lastn>, entries are listed in order
of the comment field specified here. By default, entries are ordered by their
published date and time.

=back

In addition, other attributes of the L<Entries> tag are also honored.

B<Examples:>

    <h2>Entries by people <$mt:AuthorName escape="html"$> &hearts;s</h2>
    <mt:AuthorFollowingEntries>
        <h3>
            <a href="<$mt:EntryPermalink escape="html"$>">
                <$mt:EntryTitle escape="html"$>
            </a>
        </h3>
    </mt:AuthorFollowingEntries>

=for tags authors, community, friending, entries

=cut

sub _hdlr_following_entries {
    my ( $ctx, $args, $cond ) = @_;

    my $author = $ctx->stash('author');
    return q() unless $author;
    my $blog = $ctx->stash('blog');
    my $blog_id = $blog->id if $blog;
    my %args;
    if ( $args->{lastn} ) {
        $args{limit}     = $args->{lastn};
        $args{'sort'}    = 'authored_on';
        $args{direction} = 'descend';
    }
    elsif ( exists $args->{sort_order} ) {
        $args{'sort'} = $args->{sort_by} ? $args->{sort_by} : 'authored_on';
        $args{direction} = $args->{sort_order};
    }
    if ( !exists( $args{limit} ) && exists( $args->{limit} ) ) {
        $args{limit} = $args->{limit};
    }

    require MT::Community::Friending;
    my $entries = MT::Community::Friending::entries_by_followings(
        $author,
        {   status => MT::Entry::RELEASE(),
            ( $blog_id ? ( blog_id => $blog_id ) : () )
        },
        \%args
    );
    return q() unless $entries && @$entries;
    local $ctx->{__stash}{entries} = $entries;
    return $ctx->tag( 'Entries', $args, $cond );
}

###########################################################################

=head2 AuthorFollowingComments

Lists comments left by authors whom the author currently in context is
following.

B<Attributes:>

=over 4

=item lastn (optional; default 20)

The number of comments to list. If given, the most recently submitted comments
are listed.

=item sort_order (optional)

If given in absence of C<lastn>, the comments are listed in order of the field
specified by C<sort_by>. If C<sort_order> is C<ascend>, the comments are listed
in ascending (I<A> to I<Z>, oldest to newest) order; if C<descend>, descending
(I<Z> to I<A>, newest to oldest) order.

=item sort_by (optional)

If C<sort_order> is given in absence of C<lastn>, comments are listed in order
of the comment field specified here. By default, comments are ordered by the
date and time of their submission.

=back

In addition, other attributes of the L<Comments> tag are also honored.

B<Examples:>

    <h2>Comments by people <$mt:AuthorName escape="html"$> &hearts;s</h2>
    <ul>
        <mt:AuthorFollowingComments>
            <li>
                "<$mt:CommentBody words="40"$>..."
                by <$mt:CommentAuthorName escape="html"$>
                <mt:CommentEntry>
                    on <a href="<$mt:EntryPermalink escape="html"$>">
                        <$mt:EntryTitle escape="html"$>
                    </a>
                </mt:CommentEntry>
            </li>
        </mt:AuthorFollowingComments>
    </ul>

=for tags authors, community, friending, comments

=cut

sub _hdlr_following_comments {
    my ( $ctx, $args, $cond ) = @_;

    my $author = $ctx->stash('author');

    # TODO: throw the standard incorrect context error if there's no author
    return q() unless $author;
    my $blog = $ctx->stash('blog');
    my $blog_id = $blog->id if $blog;
    my %args;

    # TODO: honor the standard selection attributes in the standard ways
    if ( $args->{lastn} ) {
        $args{limit}     = $args->{lastn};
        $args{'sort'}    = 'authored_on';
        $args{direction} = 'descend';
    }
    elsif ( exists $args->{sort_order} ) {
        $args{'sort'} = $args->{sort_by} ? $args->{sort_by} : 'authored_on';
        $args{direction} = $args->{sort_order};
    }
    if ( !exists( $args{limit} ) && exists( $args->{limit} ) ) {
        $args{limit} = $args->{limit};
    }

    require MT::Community::Friending;
    my $comments = MT::Community::Friending::comments_by_followings(
        $author,
        {   visible => 1,
            ( $blog_id ? ( blog_id => $blog_id ) : () )
        },
        \%args
    );

    # TODO: return Else content if there are no comments
    return q() unless $comments && @$comments;
    local $ctx->{__stash}{comments} = $comments;
    return $ctx->tag( 'Comments', $args, $cond );
}

###########################################################################

=head2 AuthorFollowingFavorites

Lists entries that were saved as favorites by authors whom the author currently
in context is following.

B<Attributes:>

=over 4

=item lastn (optional; default 20)

The number of entries to list. If given, the most recently submitted entries
are listed.

=item sort_order (optional)

If given in absence of C<lastn>, the entries are listed in order of the field
specified by C<sort_by>. If C<sort_order> is C<ascend>, the entries are listed
in ascending (I<A> to I<Z>, oldest to newest) order; if C<descend>, descending
(I<Z> to I<A>, newest to oldest) order.

=item sort_by (optional)

If C<sort_order> is given in absence of C<lastn>, entries are listed in order
of the comment field specified here. By default, entries are ordered by their
published date and time.

=back

In addition, other attributes of the L<Entries> tag are also honored.

B<Examples:>

    <h2>Entries &hearts;ed by people <$mt:AuthorName escape="html"$> &hearts;s</h2>
    <mt:AuthorFollowingFavorites>
        <h3>
            <a href="<$mt:EntryPermalink escape="html"$>">
                <$mt:EntryTitle escape="html"$>
            </a>
        </h3>
    </mt:AuthorFollowingFavorites>

=for tags authors, community, friending, favorites

=cut

sub _hdlr_following_favorites {
    my ( $ctx, $args, $cond ) = @_;

    my $author = $ctx->stash('author');

    # TODO: throw the standard incorrect context error if there's no author
    return q() unless $author;
    my $blog = $ctx->stash('blog');
    my $blog_id = $blog->id if $blog;
    my %args;

    # TODO: honor the standard selection attributes in the standard ways
    if ( $args->{lastn} ) {
        $args{limit}     = $args->{lastn};
        $args{'sort'}    = 'authored_on';
        $args{direction} = 'descend';
    }
    elsif ( exists $args->{sort_order} ) {
        $args{'sort'} = $args->{sort_by} ? $args->{sort_by} : 'authored_on';
        $args{direction} = $args->{sort_order};
    }
    if ( !exists( $args{limit} ) && exists( $args->{limit} ) ) {
        $args{limit} = $args->{limit};
    }

    require MT::Community::Friending;
    my $entries = MT::Community::Friending::favorites_by_followings(
        $author,
        {   status => MT::Entry::RELEASE(),
            ( $blog_id ? ( blog_id => $blog_id ) : () )
        },
        \%args
    );

    # TODO: return Else content if there are no comments
    return q() unless $entries && @$entries;
    local $ctx->{__stash}{entries} = $entries;
    return $ctx->tag( 'Entries', $args, $cond );
}

###########################################################################

=head2 AuthorFollowers

Lists the authors following the author currently in context.

B<Attributes:>

=over 4

=item lastn (optional; default 20)

The number of followers to list.

=item glue (optional)

Text with which to combine the generated template content.

=back

B<Examples:>

    <h2>Five people who &heart; <$mt:AuthorName escape="html"$></h2>
    <ul>
        <mt:AuthorFollowers lastn="5">
            <li><$mt:AuthorName escape="html"$></li>
        <mt:Else>
            <li>Nobody &hearts;s <$mt:AuthorName escape="html"$>.</li>
        </mt:AuthorFollowers>
    </ul>

=for tags authors, community, friending

=cut

sub _hdlr_followers {
    my ( $ctx, $args, $cond ) = @_;

    my $user = $ctx->stash('author')
        or return $ctx->_no_author_error('MTAuthorFollowers');

    my %args = ( $args->{lastn} ? ( limit => $args->{lastn} ) : () );
    require MT::Community::Friending;
    my @followers = MT::Community::Friending::followers( $user,
        { status => MT::Author::ACTIVE() }, \%args );

    if (@followers) {
        my $glue    = $args->{glue};
        my $res     = '';
        my $vars    = $ctx->{__stash}{vars} ||= {};
        my $count   = 0;
        my $total   = scalar(@followers);
        my $builder = $ctx->stash('builder');
        my $tokens  = $ctx->stash('tokens');
        for my $author (@followers) {
            $count++;
            local $ctx->{__stash}{author}    = $author;
            local $ctx->{__stash}{author_id} = $author->id;
            local $vars->{__first__}         = $count == 1;
            local $vars->{__last__}          = ( $count == $total );
            local $vars->{__odd__}           = ( $count % 2 ) == 1;
            local $vars->{__even__}          = ( $count % 2 ) == 0;
            local $vars->{__counter__}       = $count;
            defined( my $out = $builder->build( $ctx, $tokens, $cond ) )
                or return $ctx->error( $builder->errstr );
            $res .= $glue if defined($glue) && ( $count > 1 );
            $res .= $out;
        }
        $res;
    }
    else {
        return $ctx->else( $args, $cond );
    }
}

###########################################################################

=head2 AuthorFollowing

Lists the authors whom the author currently in context is following.

B<Attributes:>

=over 4

=item lastn (optional; default 20)

The number of followed authors to list.

=item glue (optional)

Text with which to combine the generated template content.

=back

B<Examples:>

    <h2>Five people <$mt:AuthorName escape="html"$> &hearts;s</h2>
    <ul>
        <mt:AuthorFollowing lastn="5">
            <li><$mt:AuthorName escape="html"$></li>
        <mt:Else>
            <li><$mt:AuthorName escape="html"$> doesn't &heart; anybody.</li>
        </mt:AuthorFollowing>
    </ul>

=for tags authors, community, friending

=cut

sub _hdlr_following {
    my ( $ctx, $args, $cond ) = @_;

    my $user = $ctx->stash('author')
        or return $ctx->_no_author_error('MTAuthorFollowing');
    my %args = ( $args->{lastn} ? ( limit => $args->{lastn} ) : () );
    require MT::Community::Friending;
    my @followings = MT::Community::Friending::followings( $user,
        { status => MT::Author::ACTIVE() }, \%args );

    if (@followings) {
        my $glue    = $args->{glue};
        my $res     = '';
        my $vars    = $ctx->{__stash}{vars} ||= {};
        my $count   = 0;
        my $total   = scalar(@followings);
        my $builder = $ctx->stash('builder');
        my $tokens  = $ctx->stash('tokens');
        for my $author (@followings) {
            $count++;
            local $ctx->{__stash}{author}    = $author;
            local $ctx->{__stash}{author_id} = $author->id;
            local $vars->{__first__}         = $count == 1;
            local $vars->{__last__}          = ( $count == $total );
            local $vars->{__odd__}           = ( $count % 2 ) == 1;
            local $vars->{__even__}          = ( $count % 2 ) == 0;
            local $vars->{__counter__}       = $count;
            defined( my $out = $builder->build( $ctx, $tokens, $cond ) )
                or return $ctx->error( $builder->errstr );
            $res .= $glue if defined($glue) && ( $count > 1 );
            $res .= $out;
        }
        $res;
    }
    else {
        return $ctx->else( $args, $cond );
    }
}

###########################################################################

=head2 AuthorIfFollowed

A conditional tag indicating whether the viewer of the page is following the
current author in context.

B<Attributes:>

=over 4

=item id (optional; default C<followed>)

The prefix for the HTML C<id>s of the code generated by the C<AuthorIfFollowed>
tag. The C<id> is appended with the author's numeric ID and, on the tag
containing the code for when the viewer is not following the current author,
the word C<else>. For example, when C<AuthorIfFollowed> is used with author #4
the current author and C<id> not specified, the HTML content tags will have
HTML C<id>s of C<followed_4> and C<followed_4_else>.

=item class (optional; default C<followed>)

The HTML class used on the content tag containing the template results showing
the viewer I<is> following the current author in context.

=item class_else (optional; default C<followed_else>)

The HTML class used on the content tag containing the template results showing
the viewer I<is not> following the current author in context.

=item script (optional)

The HTML code with which to invoke the Javascript that determines the viewer's
relationship to the author. By default, MT will generate this code itself.

=back

B<Examples:>

    <h2><$mt:AuthorName escape="html"$></h2>
    <mt:AuthorIfFollowed>
        <p>
            You are following <$mt:AuthorName escape="html"$>.
            <$mt:AuthorUnfollowLink text="Stop following"$>
        </p>
    <mt:Else>
        <p><$mt:AuthorFollowLink text="Follow this person"$></p>
    </mt:AuthorIfFollowed>

Note that during static publishing, both the regular template contents and the
contents of any contained L<Else> tags will be evaluated. Any side effects of
that template code will occur at publish time whether or not the viewer,
undetermined at publish time, is followed by the author in context.

=for tags authors, community, friending

=cut

sub _hdlr_author_if_followed {
    my ( $ctx, $args, $cond ) = @_;
    $args->{class}      ||= 'followed';
    $args->{class_else} ||= 'followed_else';
    $args->{id}         ||= 'followed';
    _core_author_if_relations(@_);
}

###########################################################################

=head2 AuthorIfFollowing

A conditional tag indicating whether the current author in context is following
the viewer of the page.

B<Attributes:>

=over 4

=item id (optional; default C<following>)

The prefix for the HTML C<id>s of the code generated by the
C<AuthorIfFollowing> tag. The C<id> is appended with the author's numeric ID
and, on the tag containing the code for when the viewer is not following the
current author, the word C<else>. For example, when C<AuthorIfFollowing> is
used with author #4 the current author and C<id> not specified, the HTML
content tags will have HTML C<id>s of C<following_4> and C<following_4_else>.

=item class (optional; default C<following>)

The HTML class used on the content tag containing the template results showing
the current author in context I<is> following the viewer.

=item class_else (optional; default C<following_else>)

The HTML class used on the content tag containing the template results showing
the current author in context I<is not> following the viewer.

=item script (optional)

The HTML code with which to invoke the Javascript that determines the viewer's
relationship to the author. By default, MT will generate this code itself.

=back

B<Examples:>

    <h2><$mt:AuthorName escape="html"$></h2>
    <mt:AuthorIfFollowing>
        <p><$mt:AuthorName escape="html"$> follows you.</p>
    </mt:AuthorIfFollowing>

Note that during static publishing, both the regular template contents and the
contents of any contained L<Else> tags will be evaluated. Any side effects of
that template code will occur at publish time whether or not the viewer,
undetermined at publish time, is following the author in context.

=for tags authors, community, friending

=cut

sub _hdlr_author_if_following {
    my ( $ctx, $args, $cond ) = @_;
    $args->{class}      ||= 'following';
    $args->{class_else} ||= 'following_else';
    $args->{id}         ||= 'following';
    _core_author_if_relations(@_);
}

sub _core_author_if_relations {
    my ( $ctx, $args, $cond ) = @_;
    my $tag    = lc $ctx->stash('tag');
    my $author = $ctx->stash('author')
        or return $ctx->_no_author_error($tag);
    my $author_id = $author->id;

    # TODO: pass inherited conditions to child tokens
    my $false_block = $ctx->else($args);

    # TODO: check for failed build with defined()
    if ( !$false_block && $ctx->errstr ) {
        return $ctx->error( $ctx->errstr );
    }
    my $true_block = $ctx->slurp($args);
    if ( !$true_block && $ctx->errstr ) {
        return $ctx->error( $ctx->errstr );
    }

    my $id        = $args->{id};
    my $arg_class = $args->{class};
    if ($arg_class) {
        $arg_class = MT::Util::remove_html($arg_class);
        $arg_class = ' class="' . $arg_class . '"';
    }
    my $arg_class_else = $args->{class_else};
    if ($arg_class_else) {
        $arg_class_else = MT::Util::remove_html($arg_class_else);
        $arg_class_else = ' class="' . $arg_class_else . '"';
    }
    my $script = q();
    if ( exists( $args->{script} ) && $args->{script} ) {
        my $cgi_path  = $ctx->invoke_handler('cgipath');
        my $cp_script = $ctx->{config}->CommunityScript;

        # TODO: escape ampersand
        $script = <<SCRIPT;
<script type="text/javascript" src="$cgi_path$cp_script?__mode=relations_js&author_id=$author_id"></script>
SCRIPT
    }

    # TODO: move default hidden style into community blog CSS?
    my $out = <<OUTPUT;
<span id="${id}_$author_id"$arg_class style="display:none">$true_block</span>
<span id="${id}_${author_id}_else"$arg_class_else style="display:none">$false_block</span>
$script
OUTPUT

    $out;
}

1;
__END__
