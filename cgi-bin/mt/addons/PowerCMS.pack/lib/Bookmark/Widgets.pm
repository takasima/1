package Bookmark::Widgets;
use strict;

sub _condition {
    my ( $page, $scope ) = @_;
    return $page eq 'dashboard';
}

sub _my_shortcut {
    my ( $app, $tmpl, $param ) = @_;
    my $user = $app->user;
    my $nickname = $user->nickname;
    $nickname = $user->name unless $nickname;
    $param->{ nickname } = $nickname;
}

1;
