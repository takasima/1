var filter_active = 0;

jQuery( function( jQuery )
{
    // ----------------------------------------
    // sort
    // ----------------------------------------
    var sort_option = {
        connectWith :[ '.listing ul' ],
        containment :'#container',
        opacity     : 0.5,
        cursor      : 'move',
        items       : 'li',
        stop        : itemsort.sort_stop
    };
    jQuery( '.listing ul' ).sortable( sort_option );
    jQuery( '.listing ul' ).disableSelection();

    // ----------------------------------------
    // Filter by page type
    // ----------------------------------------
    jQuery( '#page-type, #item-type' ).change( itemsort.pre_post_class );
    // ----------------------------------------
    // Toggle element
    // ----------------------------------------
    jQuery( '#filter-link' ).click( function() {
        var filter_value = jQuery( '#filter-col' ).val();
        return false;
    } );
    jQuery( '#additem' ).click( function(){
        jQuery( '#addposition' ).toggle();
        return true;
    });
    // CHECK ALL
    jQuery( '.listing .check_all input' ).click( function() {
        var position = jQuery( this ).parents( '.listing' ).attr( 'id' );
        var count = calc_check_item( position );
        if ( jQuery( this ).attr( 'checked' ) ) {
            jQuery( '#' + position + ' .checkbox' ).attr( 'checked', 'checked' );
            jQuery( '#' + position + ' li' ).addClass( 'checked' );
        } else {
            jQuery( '#' + position + ' .checkbox' ).removeAttr( 'checked' );
            jQuery( '#' + position + ' li' ).removeClass( 'checked' );
        }
    });
    jQuery( '.listing .check_all a' ).click( function() {
        var position = jQuery( this ).parents( '.listing' ).attr( 'id' );
        jQuery( '#' + position + ' li input' ).each( function() {
            var checked = jQuery( this ).attr( 'checked' );
            if ( checked ) {
                jQuery( this ).removeAttr( 'checked' );
            } else {
                jQuery( this ).attr( 'checked', 'checked' );
            }
        } );
        var count = calc_check_item( position );
        if ( count ) {
            jQuery( this ).prev().attr( 'checked', 'checked' );
        } else {
            jQuery( this ).prev().removeAttr( 'checked' );
        }
        return false;
    });
    // REVERSE
    jQuery( '.reverse' ).click( function(){
        var position = jQuery( this ).parents( '.listing' ).attr( 'id' );
        reverseItem( position );
        return false;
    } );
    jQuery( '.listing .object-listing-content input' ).click( function() {
        var position = jQuery( this ).parents( '.listing' ).attr( 'id' );
        var checked  = jQuery( '#' + position + ' .check_all input' );
        if ( checked.attr( 'checked' ) ) {
            checked.removeAttr( 'checked' );
        } else {
            if ( calc_check_item( position ) ) {
                checked.attr( 'checked', 'checked' );
            }
        }
    } );
    jQuery( '#item_arrow img' ).click( function() {
        var move_class = jQuery( this ).attr( 'class' );
        if ( move_class.indexOf( 'toRight' ) > -1) {
            var from = '#item-left';
            var to   = '#item-right';
        } else {
            var from = '#item-right';
            var to   = '#item-left';
        }
        var checked = jQuery( from + ' .object-listing-content input:checked' ).removeAttr( 'checked' );
        var target = checked.parents( 'li' );
        jQuery( to + ' .object-listing-content ul' ).append( target );
        check_all_attr();
    } );
} );

function calc_check_item( position ) {
    var items   = jQuery( '#' + position + ' li' ).size();
    var checked = jQuery( '#' + position + ' li input:checked' ).size();
    if ( items == 0 ) {
        return false;
    }
    return items == checked;
}

function recheck() {
    jQuery( '.listing .check_all input' ).each( function() {
        var position = jQuery( this ).parents( '.listing' ).attr( 'id' );
        if ( calc_check_item( position ) ) {
            jQuery( this ).attr( 'checked', 'checked' );
        } else {
            jQuery( this ).removeAttr( 'checked' );
        }
    } );
}

function check_all_attr() {
    jQuery( '.listing .check_all input' ).removeAttr( 'checked' );
}

function saveobject() {
    var list = jQuery( '#item-right li' );
    var ids  = new Array();
    var strs = new String();
    var i = 0;
    list.each(function(){
        var str = jQuery( this ).children( 'span' ).attr( 'id' ).split( 'objectID' )[1];
        ids[i] = str;
        if ( i < list.size() - 1 ) {
            strs += str + ',';
        } else {
            strs += str;
        }
        i++;
    } );
    var input = jQuery( document.createElement( 'input' ) );
    input
        .attr( {
            'type'  : 'hidden',
            'name'  : 'sort',
            'value' : strs
        } );
    jQuery( '#item_sort' ).append( input );
}

function reverseItem( position ){
    var list = jQuery( '#' + position + ' .object-listing-content li' );
    var count = list.size();
    if ( count > 1 ) {
        for( var i = 0; i < count; i++ ){
            list.parent( 'ul' ).append( list[ count - i - 1 ] );
        }
    }
}

var itemsort = {
    sort_stop: function() {
        jQuery('.dropBox').addClass( 'moved' );
        recheck();
    },
    // Filter by page type
    pre_post_class: function() {
        var is_moved = jQuery( '.dropBox' ).attr( 'class' ).indexOf( 'moved' );
        if ( jQuery( '#item-type' ).attr( 'value' ) != 'container_id' ) {
            jQuery( '#filter_container' ).css( 'display','none' );
        } else {
            jQuery( '#filter_container' ).css( 'display','inline' );
            if ( jQuery( '#filter_container' ).attr( 'value' ) == '' ) {
                return;
            }
        }
        if ( is_moved > -1 ) {
            var checkPage = confirm( confirmMsg );
            if ( checkPage == false ) {
                return false;
            }
        }
        if ( jQuery( '#item-type' ).attr( 'value' ) == 'tag' ) {
            var filter_tag = jQuery( '#filter_tag' ).attr( 'value' )
            var tag = window.prompt( trans( 'Tag is' ), filter_tag );
            jQuery( '#filter_container' ).css( 'display','none' );
            if ( tag == null || tag == '' ) {
                return false;
            }
            jQuery( '#filter_tag' ).attr( 'value', tag );
        } else {
            jQuery( '#filter_tag' ).attr( 'value', '' );
        }
        getByID( 'filter-select-form' ).submit();
        // jQuery( '#filter-select-form' ).submit();
    }
};
