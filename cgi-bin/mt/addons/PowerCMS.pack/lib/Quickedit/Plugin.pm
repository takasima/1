package Quickedit::Plugin;
use strict;

sub _quickedit {
    my $app = shift;
    require MT::FileInfo;
    my $permalink = $app->param( 'permalink' );
    my $url = $permalink;
    $url =~ s{^https?://[^/]*}{};
    $url =~ s{/$}{/index.html};
    my @classes = [ 'Individual', 'Page', 'Category' ];
    my $finfos = MT::FileInfo->load_iter( { url => $url,
                                            archive_type => \@classes, } );
    my $o;
    while ( my $fi = $finfos->() ) {
        if ( $fi->entry_id ) {
            require MT::Entry;
            $o = MT::Entry->load( $fi->entry_id );
            if ( defined $o ) {
                if ( $permalink eq $o->permalink ) {
                    last;
                }
            }
        } elsif ( $fi->category_id ) {
            require MT::Category;
            $o = MT::Category->load( $fi->category_id );
            if ( defined $o ) {
                last;
            }
        }
    }
    if ( defined $o ) {
        $app->redirect( $app->uri( mode => 'view', args => { 'blog_id' => $o->blog_id,
                                                             '_type'   => $o->class,
                                                             'id'      => $o->id,
                                                            } ) );
    } else {
        my $finfo = MT::FileInfo->load( { url => $url,
                                          archive_type => 'index', } );
        if ( defined $finfo ) {
            $app->redirect( $app->uri( mode => 'dashboard', args => { 'blog_id' => $finfo->blog_id, } ) );
        } else {
            $app->redirect( $app->uri );
        }
    }
}

sub _this_is_you {
    my ( $cb, $app, $param, $tmpl ) = @_;
    if ( ( $param->{ can_list_entries } ) || ( $param->{ can_list_pages } ) ) {
        $param->{ can_quick_edit } = 1;
    }
}

sub _this_is_you_source {
    my ( $cb, $app, $tmpl ) = @_;
    my $edit_uri = $app->base . $app->uri( mode => 'quickedit' );
    my $description = '<__trans phrase="Drag this link to your browser\'s toolbar, then click it when you are visiting a entry(page) that you want to edit entry(page).">';
    $edit_uri = '<br /><a title="' . $description . '" href="javascript:window.document.location.href=\'' . $edit_uri . '&permalink=\'+document.location.href;"><__trans phrase="Quick Edit"></a>';
    $edit_uri = '<mt:if name="can_quick_edit"><__trans_section component="PowerCMS">' . $edit_uri . '</__trans_section></mt:if>';
    $$tmpl =~ s!(</p>\s*</div>.</mtapp:widget>)!$edit_uri$1!s;
}

1;