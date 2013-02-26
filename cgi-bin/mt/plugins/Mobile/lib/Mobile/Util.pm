package Mobile::Util;
use strict;
use warnings;
use base qw( Exporter );

our @EXPORT_OK = qw( _get_uploader );

sub _get_uploader {
    my ( $app, $blog_id ) = @_;
    $app ||= MT->instance;
    $blog_id ||= ( $app->blog ? $app->blog_id : 0 );
    my $permission = "%'upload'%";
    my %args;
    $args{'join'} = MT->model('permission')->join_on(
        'author_id',
        {   blog_id     => $blog_id,
            permissions => { like => $permission },
        }
    );
    if ( my @authors = MT->model('author')->load( undef, \%args ) ) {
        return \@authors;
    }
}

1;
