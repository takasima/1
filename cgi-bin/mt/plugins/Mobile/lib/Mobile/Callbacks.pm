package Mobile::Callbacks;
use strict;
use warnings;

use File::Basename;

use lib qw( addons/PowerCMS.pack/lib );
use PowerCMS::Util qw( save_asset copy_item is_cms uniq_filename );

use Mobile::Util qw( _get_uploader );

sub _cb_ts_mobile_config_blog {
    my ( $cb, $app, $tmpl ) = @_;
    if ( my $blog = $app->blog ) {
        if ( $blog->class eq 'website' ) {
            $$tmpl =~ s!<mt:unless name="is_website">.*</mt:unless>!!si;
        }
    }
}

sub _cb_tp_asset_upload {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $plugin = MT->component('Mobile');

    if ( my $blog = $app->blog ) {
        if ( my $pointer_node = $tmpl->getElementById('file') ) {
            my $scope = 'blog:' . $blog->id;
            my $create_other_fomatted_image_is_default
                = $plugin->get_config_value(
                'create_other_fomatted_image_is_default', $scope );
            my $nodeset = $tmpl->createElement(
                'app:setting',
                {   id    => 'convert_other_format',
                    label => $plugin->translate(
                        'Create other formatted images if image.'),
                    label_class => 'top-level',
                }
            );
            my $inner_html
                = '<label><input type="checkbox" name="create_other_format" id="create_other_format" '
                . (
                $create_other_fomatted_image_is_default
                ? ' checked="checked"'
                : ''
                )
                . ' /> '
                . $plugin->translate('Create')
                . '</label>';
            $nodeset->innerHTML($inner_html);
            $tmpl->insertAfter( $nodeset, $pointer_node );
        }
    }
}

sub _cb_ts_asset_replace {
    my ( $cb, $app, $tmpl ) = @_;
    if ( my $create_other_format = $app->param('create_other_format') ) {
        my $search = quotemeta('</form>');
        my $insert
            = '<input type="hidden" name="create_other_format" id="create_other_format" value="1" />';
        $$tmpl =~ s/($search)/$insert$1/;
    }
}

sub _cb_tp_asset_insert {
    my ( $cb, $app, $tmpl ) = @_;
    if ( my $new_entry = $app->param('new_entry') ) {
        if ( my $asset_id = $app->param('id') ) {
            if ( my $original_asset
                = MT->model('asset')->load( { id => $asset_id } ) )
            {
                my @assets
                    = MT->model('asset')->load( { parent => $asset_id } );
                for my $asset (@assets) {
                    $asset->label( $original_asset->label . '('
                            . $asset->file_ext
                            . ')' );
                    $asset->save or die $asset->errstr;
                }
            }
        }
    }
}

sub _cb_cms_upload_image {
    my ( $cb, %param ) = @_;
    if ( my $asset = $param{asset} ) {
        my $file_name = $asset->file_name;
        my $file_path = $asset->file_path;
        my ( $file_basename, $dir_path, $ext )
            = fileparse( $file_path, ( '.jpg', '.gif', '.png' ) );
        my $blog = $param{blog};
        my $fmgr = MT::FileMgr->new('Local') or die MT::FileMgr->errstr;
        my $app  = MT->instance;
        if ( ( ref $app ) eq 'MT::App::Upgrader' ) {
            return 1;
        }
        my ( $author, $create_other_format );
        if ( is_cms($app) ) {
            $author              = $app->user;
            $create_other_format = $app->param('create_other_format');
        }
        else {
            if ( my @uploader = _get_uploader( $app, $blog->id ) ) {
                $author = $uploader[0];
            }
            $create_other_format = $param{create_other_format};
        }
        return unless $create_other_format;
        if ( my $image_type = $param{image_type} ) {
            my ( @new_exts, @new_file_path );
            if ( $image_type =~ /jpe?g/i ) {
                @new_exts = ( 'gif', 'png' );
            }
            elsif ( $image_type =~ /gif/i ) {
                @new_exts = ( 'png', 'jpg' );
            }
            elsif ( $image_type =~ /png/i ) {
                @new_exts = ( 'jpg', 'gif' );
            }
            for my $ext (@new_exts) {
                my $new_file_path = File::Spec->catfile( $dir_path,
                    $file_basename . '.' . $ext );
                $new_file_path = uniq_filename($new_file_path);
                if ( copy_item( $file_path, $new_file_path, $blog ) ) {
                    my $image = MT::Image->new( Filename => $new_file_path );
                    if ( my $data = $image->convert( Type => $ext ) ) {
                        if ($fmgr->put_data(
                                $data, $new_file_path, 'upload'
                            )
                            )
                        {
                            my %params = (
                                file   => $new_file_path,
                                author => $author,
                                label  => $asset->label . '(' . $ext . ')',
                                parant => $asset->id,
                            );
                            my $asset = save_asset( $app, $blog, \%params, 1 )
                                or die;
                        }
                    }
                }
            }
        }
    }
}

sub _edit_author_param {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $plugin = MT->component('Mobile');

    if ( $app->param('id') ) {
        my $author = MT::Author->load( $app->param('id') );
        if ( defined $author ) {
            $param->{mobile_address} = $author->mobile_address;
        }
    }
    my $pointer_field = $tmpl->getElementById('email');
    my $nodeset       = $tmpl->createElement(
        'app:setting',
        {   id       => 'mobile_address',
            label    => $plugin->translate('Moblie E-mail'),
            required => 0
        }
    );
    my $innerHTML
        = '<input type="text" class="full-width text" name="mobile_address" id="mobile_address" class="full-width short" value="<$mt:var name="mobile_address" escape="html"$>" />';
    $nodeset->innerHTML($innerHTML);
    $tmpl->insertAfter( $nodeset, $pointer_field );
}

sub _post_save_author {
    my ( $cb, $app, $obj, $original ) = @_;
    if ( $app->mode eq 'save' ) {
        my $mobile_address = $app->param('mobile_address');
        $obj->mobile_address($mobile_address);
        $obj->save or die $obj->errstr;
    }
    return 1;
}

sub _cfg_prefs_param {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $plugin = MT->component('Mobile');

    return unless $app->blog->class eq 'blog';

    my $pointer_field = $tmpl->getElementById('description');
    my $nodeset       = $tmpl->createElement(
        'app:setting',
        {   id       => 'allow_mailpost',
            label    => $plugin->translate('Mailpost'),
            required => 0,
        }
    );
    my $label     = $plugin->translate('Allow Mailpost');
    my $innerHTML = <<"    __EOF__";
    <div><label>
    <input type="checkbox" name="allow_mailpost" id="allow_mailpost" value="1"
                                             <mt:if name="allow_mailpost">checked="checked"</mt:if> />
    $label</label><input type="hidden" name="allow_mailpost" value="0" />
    </div>
    __EOF__
    $nodeset->innerHTML($innerHTML);
    $tmpl->insertAfter( $nodeset, $pointer_field );
}

sub _cb_cms_post_delete_category {
    my ( $cb, $app, $obj, $original ) = @_;
    my $category_id = $obj->id;
    my @permissions = MT->model( 'permission' )->load( { mobile_categories => $category_id } );
    for my $permission ( @permissions ) {
        $permission->mobile_categories( undef );
        $permission->save or die $permission->errstr;
    }
    return 1;
}

1;
