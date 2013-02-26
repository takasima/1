package AltSearch::Plugin;
#use strict;

sub __entry_indexing_extfields {
    my ( $entry ) = @_;
    eval { require ExtFields::Extfields };
    return '' if $@; # this process needs ExtFields
    my $res = '';
    my @fields = ExtFields::Extfields->load( { entry_id => $entry->id } );
    for my $field ( @fields ) {
        if ( ( $field->type eq 'text' ) || ( $field->type eq 'textarea' ) ) {
            $res .= $field->text . "\n" if ( $field->text );
        }
        if ( $field->type eq 'file' ) {
            $res .= $field->alternative . "\n" if ( $field->alternative );
            $res .= $field->description . "\n" if ( $field->description );
        }
    }
    return $res;
}

sub __entry_indexing_customfields {
    my ( $entry ) = @_;
    eval { require CustomFields::Util };
    return '' if $@; # this process needs CustomFields::Util
    my $res = '';
    my $meta = CustomFields::Util::get_meta( $entry );
    for my $basename ( keys %$meta ) {
        my $val = $meta->{ $basename };
        $val = '' if ( !defined $val );
        $res .= $val;
        $res .= "\n";
    }
    return $res;
}

sub _entry_indexing {
    my ( $cb, $app, $entry ) = @_;
    my $res = '';
    my $tmp = __entry_indexing_extfields( $entry );
    $res .= $tmp if $tmp;
    $tmp = __entry_indexing_customfields( $entry );
    $res .= $tmp if $tmp;
    return unless $res; # no entry indexing data
    $res =~ s/\n$//;
    $entry->ext_datas( $res );
    # $entry->ext_data( $res );
    $entry->save or die $entry->errstr;
}

1;
