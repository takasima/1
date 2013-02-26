var filter_active = 0;

jQuery(function(jQuery)
{
    set_header_height();
    var filter = "#" + jQuery('#item-type option:selected').val();
//    jQuery("#item-left .tabBox").not(filter).hide();
//    jQuery(filter).show();

    jQuery('.listing ul').not('.tabs').sortable({
        connectWith:['.listing ul'],
        containment:'#container',
        opacity: 0.5,
        cursor: 'move',
        items: 'li',
        receive: function(event, ui) {
            var position = jQuery(this).parents('.listing').attr('id');
            var li_class = ui.item.attr('class');

            if (position == 'item-left') {
                var child_num;
                if (li_class.indexOf('entry') > -1) {
                    jQuery('#item-left .tabs li:nth-child(1) a').click();
                    jQuery('#group_box_entry ul').append(ui.item);
                } else if (li_class.indexOf('category') > -1) {
                    jQuery('#item-left .tabs li:nth-child(2) a').click();
                    jQuery('#group_box_category ul').append(ui.item);
                } else if (li_class.indexOf('blog') > -1) {
                    jQuery('#item-left .tabs li:nth-child(3) a').click();
                    jQuery('#group_box_blog ul').append(ui.item);
                }  else if (li_class.indexOf('website') > -1) {
                    jQuery('#item-left .tabs li:nth-child(3) a').click();
                    jQuery('#group_box_blog ul').append(ui.item);
                }
            }
        },
        stop : function(event, ui) {
            jQuery('.dropBox').addClass('moved');
            recheck();
        }
    });
    jQuery('.listing ul').disableSelection();

    ////////// FILTERING
    jQuery('button#item-filter').click(function(){
        var target = "#" + jQuery('#item-type option:selected').val();
        if (target.indexOf('entry') > -1) {
            jQuery('#item-left h3').html(label_entry);
        } else if (target.indexOf('category') > -1) {
            jQuery('#item-left h3').html(label_category);
        } else if (target.indexOf('blog') > -1) {
            jQuery('#item-left h3').html(label_blog);
        } else if (target.indexOf('website') > -1) {
            jQuery('#item-left h3').html(label_blog);
        }

        if (calc_check_item('item-left')) {
            jQuery('#item-left .check_all .tabBox:visible input').attr('checked', 'checked');
        } else {
            jQuery('#item-left .check_all .tabBox:visible input').removeAttr('checked');
        }
    });

    // Toggle filter-field button
    jQuery('a#filter-link').click(function() {
        var filter_value = jQuery('#filter-col').val();
        initFilter();
        setFilterCol(filter_value);
        return false;
    });

    jQuery('#items_filter button.cancel')
        .not('#not-filter-change')
        .click(function(){
        jQuery('#items_filter, #filter-link').toggle();
        return false;
    });
    jQuery('#not-filter-change').click(function(){
        jQuery('#filter-link, #items_filter').toggle();
        return false;
    });

    jQuery('#filter-col').change(function(){
        var filter_value = jQuery(this).val();
        setFilterCol(filter_value);
    });
    jQuery('#filter-button').click(function(){
        extFilter('filter-col','category_id-val','exacttag-val')
    });

    jQuery('#not-filtering').click(function(){
        if (jQuery('.dropBox').attr('class').indexOf('moved') > -1 ) {
            return confirm(confirmMsg);
        }
    });
    jQuery('#filter-change').click(function(){
        initFilter();
    });

    ////////// GROUP SETTING
    jQuery('#add_filter-col').change(function(){
        add_setFilterCol(jQuery(this).val());
    });
    jQuery('#add_filter_link').click(function(){
        add_initFilter();
    });
    jQuery('#not-setting-term').click(function(){
        jQuery('#add_items_filter-field, #add_filter_link').toggle();
        return false;
    });

    ////////// CHECK ALL
    jQuery('.listing .check_all input').click(function() {
        var position = jQuery(this).parents('.listing').attr('id');
        var count = calc_check_item(position);

        if (jQuery(this).attr('checked')) {
            jQuery('#' + position  + ' .tabBox:visible .checkbox').attr('checked', 'checked');
            jQuery('#' + position  + ' .tabBox:visible li').addClass('checked');
        } else {
            jQuery('#' + position  + ' .tabBox:visible .checkbox').removeAttr('checked');
            jQuery('#' + position  + ' .tabBox:visible li').removeClass('checked');
        }
    });

    jQuery('.listing .check_all a').click(function() {
        var position = jQuery(this).parents('.listing').attr('id');

        jQuery('#' + position + ' .tabBox:visible li input').each(function() {
            var checked = jQuery(this).attr('checked');
            if (checked) {
                jQuery(this).removeAttr('checked');
            } else {
                jQuery(this).attr('checked', 'checked');
            }
        });

        var count = calc_check_item(position);
        if (count) {
            jQuery(this).prev().attr('checked', 'checked');
        } else {
            jQuery(this).prev().removeAttr('checked');
        }
        return false;
    });

    ////////// REVERSE
    jQuery('.reverse').click(function(){
        var position = jQuery(this).parents('.listing').attr('id');
        reverseItem(position);
        return false;
    });

    jQuery('.listing .entry-listing-content input').click(function() {
        var position = jQuery(this).parents('.listing').attr('id');
        var checked  = jQuery('#' + position + ' .check_all input');

        if (checked.attr('checked')) {
            checked.removeAttr('checked');
        } else {
            if (calc_check_item(position)) {
                checked.attr('checked', 'checked');
            }
        }
    });
    jQuery('.dropBox .tabs a').click(function() {
        var position = 'item-left';
        var target   = jQuery(this).attr('href');
        var count = calc_check_box(target);

        if (count) {
            jQuery('.listing .check_all input').attr('checked', 'checked');
        } else {
            jQuery('.listing .check_all input').removeAttr('checked');
        }
    });

    jQuery('#item_arrow img').click(function() {
        var move_class = jQuery(this).attr('class');

        if (move_class.indexOf('toRight') > -1) {
            var from = '#item-left';
            var to   = '#item-right';
            var checked = jQuery(from + ' .entry-listing-content .tabBox:visible input:checked').removeAttr('checked');
            var target = checked.parents('li');

            jQuery(to + ' .entry-listing-content ul').append(target);
        } else {
            var from = '#item-right';
            var to   = '#item-left';

            var checked = jQuery(from + ' .entry-listing-content input:checked').removeAttr('checked');
            checked.parents('li').each (function() {
                var target_box = jQuery(this).attr('class');
                if(target_box.indexOf('entry') > -1) {
                    var box = "#group_box_entry";
                } else if(target_box.indexOf('page') > -1) {
                    var box = "#group_box_entry";
                } else if(target_box.indexOf('category') > -1) {
                    var box = "#group_box_category";
                } else if(target_box.indexOf('folder') > -1) {
                    var box = "#group_box_category";
                } else if(target_box.indexOf('blog') > -1) {
                    var box = "#group_box_blog";
                } else if(target_box.indexOf('website') > -1) {
                    var box = "#group_box_blog";
                }

                jQuery(to + ' .entry-listing-content ' + box + ' ul').append(jQuery(this));
            });
        }

        check_all_attr();
    });

    jQuery('#item-left .tabs').bind('resize', set_header_height);
    jQuery(window).bind('resize', set_header_height);

});

function initFilter() {
    jQuery('#items_filter').show();
    jQuery('#filter-link').hide();

    jQuery('#filter-col').selectedIndex = 0;
    jQuery('#category_id-val').selectedIndex = 0;

    jQuery('#category_id-val').show();
    jQuery('#exacttag-val').hide();
}


function calc_check_item(position)
{
    var items   = jQuery('#' + position + ' .tabBox:visible li').size();
    var checked = jQuery('#' + position + ' .tabBox:visible li input:checked').size();

    if (items == 0) {
        return false;
    }
    return items == checked;
}

function calc_check_box(id)
{
    var items   = jQuery(id + ' li').size();
    var checked = jQuery(id + ' li input:checked').size();

    if (items == 0) {
        return false;
    }
    return items == checked;
}

function recheck()
{
    jQuery('.listing .check_all input').each(function() {
        var position = jQuery(this).parents('.listing').attr('id');
        if (calc_check_item(position)) {
            jQuery(this).attr('checked', 'checked');
        } else {
            jQuery(this).removeAttr('checked');
        }
    });
}

function check_all_attr()
{
    jQuery('.listing .check_all input').removeAttr('checked');
}

function saveEntry()
{
    var list = jQuery('#item-right li');
    var ids = new Array();
    var strs = "";
    var i = 0;

    list.each(function(){
        var str = jQuery(this).attr('id').split('li_')[1];
        ids[i]  = str;
        if (i < list.size() - 1) {
            strs = strs + str + ',';
        } else {
            strs = strs + str;
        }
        i++;
    });
//"console"in window&&typeof console.log==="function"&&console.log(strs);
//    return false;
    jQuery('#sort').attr('value', strs);
}

function add_setFilterCol(choice)
{
    var ctrl_cat = jQuery('#add_category_id-val');
    var ctrl_tag = jQuery('#add_exacttag-val');
    var flag     = jQuery('#add_filter_flag');

    if (choice != 'none') {
        if (choice == 'category_id') {
            ctrl_cat.show();
            ctrl_tag.hide();
        } else if (choice == 'exacttag') {
            ctrl_cat.hide();
            ctrl_tag.show();
        }
        flag.attr('value', 1);
    } else {
        flag.attr('value', 0);
    }
}

function extFilter(filterTypeEleID,categoryEleID,tagEleID)
{
    return;
    if (jQuery('.dropBox').attr('class').indexOf('moved') > -1 ) {
        dialogCheck = confirm(confirmMsg)

        if(dialogCheck){
            this.jumpFilter(filterTypeEleID,categoryEleID,tagEleID);
        }
    }else{
        this.jumpFilter(filterTypeEleID,categoryEleID,tagEleID);
    }
}

function setFilterCol(choice) {
    var sel = jQuery('#filter-select');

    if (!sel) {
        return;
    }

    var filter_class = "filter-" + choice;
    sel.attr('class', filter_class);

    var ctrl = choice + "-val";

    ctrl_cat = jQuery('#category_id-val');
    ctrl_tag = jQuery('#exacttag-val');

    if (choice != 'none') {
        var fld = jQuery('#filter-col');

        if (choice == 'category_id') {
            ctrl_cat.show();
            ctrl_tag.hide();
        } else if (choice == 'exacttag') {
            ctrl_tag.show();
            ctrl_cat.hide();
        }

    }
}

function set_header_height()
{
    var tabs_height  = get_element_height('#item-left .tabs');
    var right_height = get_element_height('#item-right h3');
	var padding = tabs_height - (right_height + 12);
	function get_element_height(selector){
        var element = jQuery(selector);
        var height = element.outerHeight();
        if (!isNaN(height) && height) {
            return height;
        }
        return false;
    }
	if(padding < 0){
		return false;
	}
    jQuery('#item-right').css({
        'padding-top' : padding + 'px'
    });
}

function reverseItem(position){
    var list = jQuery('#' + position + ' .entry-listing-content .tabBox:visible li');

    var count = list.size();

    if(count > 1){
        for(var i = 0; i < count; i++){
            list.parent('ul').append(list[count - i - 1]);
        }
    }
}
