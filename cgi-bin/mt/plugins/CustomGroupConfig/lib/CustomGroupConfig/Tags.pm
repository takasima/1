package CustomGroupConfig::Tags;
use strict;

sub _hdlr_item_group_entries {
    my ( $ctx, $args, $cond ) = @_;
    my $model = MT->model( 'entrypagegroup' );
    my $tag = $model->tag;
    my $stash = $model->stash;
    my $child_class = $model->child_class;
    my $child_object_ds = $model->child_object_ds;
    $args->{ class } = 'entrypagegroup';
    $args->{ stash } = $stash;
    $args->{ child_class } = $child_class;
    $args->{ child_object_ds } = $child_object_ds;
    require CustomGroup::Tags;
    return CustomGroup::Tags::_hdlr_group_objects( $ctx, $args, $cond );
}

sub _hdlr_item_group_entries_count {
    my ( $ctx, $args, $cond ) = @_;
    my $model = MT->model( 'entrypagegroup' );
    my $tag = $model->tag;
    my $stash = $model->stash;
    my $child_class = $model->child_class;
    my $child_object_ds = $model->child_object_ds;
    $args->{ class } = 'entrypagegroup';
    $args->{ stash } = $stash;
    $args->{ child_class } = $child_class;
    $args->{ child_object_ds } = $child_object_ds;
    $args->{ count } = 1;
    require CustomGroup::Tags;
    return CustomGroup::Tags::_hdlr_group_objects( $ctx, $args, $cond );
}

sub _hdlr_item_group_categories {
    my ( $ctx, $args, $cond ) = @_;
    my $model = MT->model( 'categoryfoldergroup' );
    my $tag = $model->tag;
    my $stash = $model->stash;
    my $child_class = $model->child_class;
    my $child_object_ds = $model->child_object_ds;
    $args->{ class } = 'categoryfoldergroup';
    $args->{ stash } = $stash;
    $args->{ child_class } = $child_class;
    $args->{ child_object_ds } = $child_object_ds;
    require CustomGroup::Tags;
    return CustomGroup::Tags::_hdlr_group_objects( $ctx, $args, $cond );
}

sub _hdlr_item_group_categories_count {
    my ( $ctx, $args, $cond ) = @_;
    my $model = MT->model( 'categoryfoldergroup' );
    my $tag = $model->tag;
    my $stash = $model->stash;
    my $child_class = $model->child_class;
    my $child_object_ds = $model->child_object_ds;
    $args->{ class } = 'categoryfoldergroup';
    $args->{ stash } = $stash;
    $args->{ child_class } = $child_class;
    $args->{ child_object_ds } = $child_object_ds;
    $args->{ count } = 1;
    require CustomGroup::Tags;
    return CustomGroup::Tags::_hdlr_group_objects( $ctx, $args, $cond );
}

sub _hdlr_item_group_blogs {
    my ( $ctx, $args, $cond ) = @_;
    my $model = MT->model( 'blogwebsitegroup' );
    my $tag = $model->tag;
    my $stash = $model->stash;
    my $child_class = $model->child_class;
    my $child_object_ds = $model->child_object_ds;
    $args->{ class } = 'blogwebsitegroup';
    $args->{ stash } = $stash;
    $args->{ child_class } = $child_class;
    $args->{ child_object_ds } = $child_object_ds;
    require CustomGroup::Tags;
    return CustomGroup::Tags::_hdlr_group_objects( $ctx, $args, $cond );
}

sub _hdlr_item_group_blogs_count {
    my ( $ctx, $args, $cond ) = @_;
    my $model = MT->model( 'blogwebsitegroup' );
    my $tag = $model->tag;
    my $stash = $model->stash;
    my $child_class = $model->child_class;
    my $child_object_ds = $model->child_object_ds;
    $args->{ class } = 'blogwebsitegroup';
    $args->{ stash } = $stash;
    $args->{ child_class } = $child_class;
    $args->{ child_object_ds } = $child_object_ds;
    $args->{ count } = 1;
    require CustomGroup::Tags;
    return CustomGroup::Tags::_hdlr_group_objects( $ctx, $args, $cond );
}

sub _hdlr_item_group_header {
    my ( $ctx, $args, $cond ) = @_;
    if ( $ctx->{ __stash }{ vars }{ __first__ } ) {
        return _hdlr_pass_tokens( @_ );
    }
    return '';
}

sub _hdlr_item_group_footer {
    my ( $ctx, $args, $cond ) = @_;
    if ( $ctx->{ __stash }{ vars }{ __last__ } ) {
        return _hdlr_pass_tokens( @_ );
    }
    return '';
}

sub _hdlr_category_class {
    my ( $ctx, $args, $cond ) = @_;
    my $cat = $ctx->stash( 'category' ) || $ctx->stash( 'archive_category' )
        or return '';
    return $cat->class;
}

sub _hdlr_pass_tokens {
    my ( $ctx, $args, $cond ) = @_;
    $ctx->stash( 'builder' )->build( $ctx, $ctx->stash( 'tokens' ), $cond );
}

1;
