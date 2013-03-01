jQuery(function(){
    jQuery('.trigger_sidebarassets a').click(function() {
        asset_list.click_global_tab(this);
        return false;
    });
    jQuery('body')
        .bind('click', asset_list.remove_context)
        .bind('contextmenu', asset_list.remove_context);
    
    jQuery('.multi_upload div.trigger').click(function(){
        asset_list.toggle_multi(this);
    });
    jQuery('.multi_upload input[type="file"]').change(function(){
        asset_list.add_form(this,false);
    });
    jQuery('.multi_upload img').click(function(){
        asset_list.remove_form(this);
    });
    asset_list.set_css();
    jQuery('.multi_upload .primary-button').click(function(){
        asset_list.send(this);
        return false;
    });
    jQuery('.multi_upload .cancel').click(function(){
        asset_list.cancel(this);
        return false;
    });
    jQuery('#upload_form input[type="file"]').change(function(){
        asset_list.set_css();
    });
    jQuery('.asset_list_box').scroll(function() {
        var list_height = jQuery(this).height();
        var box_height  = jQuery(this).children('.list').height();
        var scroll      = jQuery(this).scrollTop();
        var id          = jQuery(this).attr('id');
        var offset = box_height - list_height;
        if (offset - 10 < scroll) {
            jQuery('#' + id + ' .indicate').addClass('load_add');
            asset_list.load_page(id);
        }
    });
})


var asset_list = {
    loading  : false,
    trigger_height : 45,
    blocks : 1,
    page_all : {
        'page' : 1,
        'offset' : 20
    },
    page_file : {
        'page' : 1,
        'offset' : 20
    },
    page_image : {
        'page' : 1,
        'offset' : 20
    },
    page_audio : {
        'page' : 1,
        'offset' : 20
    },
    page_video : {
        'page' : 1,
        'offset' : 20
    },
    click_global_tab: function(a){
        if(!asset_list.first){
            asset_list.first = true;
            asset_list.first_load(a);
        }else{
        }
    },
    first_load: function(a){
        jQuery('.asset_tab li').click(function(){
            asset_list.tab(jQuery(this).attr('id'))
        });
        

        asset_list.t_h = jQuery('.asset_tab').eq(0).outerHeight();
        asset_list.d_h = jQuery('#drop').outerHeight();
        asset_list.mu_h = jQuery('.multi_upload').eq(0).outerHeight();
        // from Sidebar.js
        asset_list.v_height = get_browser_height();
        
        asset_list.set_position();
        
        jQuery(window).resize(function(){
            asset_list.v_height = get_browser_height();
            asset_list.set_position();
        });
        jQuery(window).scroll(function(){
            asset_list.set_position();
        });
        asset_list.load_list(a);
    },
    set_position: function(){
        jQuery('.multi_upload').css({
            'bottom': asset_list.d_h + 'px'
        });
        
        // from Sidebar.js
        var scroll_val = jQuery(window).scrollTop();
        if(scroll_val >= sidebar.pos_header){
            var m_h = asset_list.v_height - 15;
        }else{
            var m_h = (asset_list.v_height - sidebar.ele_top) + scroll_val;
        }
        
        jQuery('.asset_list_box').css({
            'height': (m_h - asset_list.t_h - (asset_list.mu_h + asset_list.d_h) - 20) + 'px'
        });
    },
    context: function(e) {
        var asset  = jQuery(this).parents('table');
        var id     = jQuery(this).attr('mt:asset_id');
        var edit   = false;
        var save   = false;
        var upload = false;
        if (asset.hasClass('image')) {
            var type = 'image';
        } else if (asset.hasClass('audio')) {
            var type = 'audio';
        } else if (asset.hasClass('video')) {
            var type = 'video';
        } else if (asset.hasClass('file')) {
            var type = 'file';
        } else {
            var type = 'all';
        }
        if (jQuery(this).hasClass("can_upload")) {
            upload = true;
        }
        if (jQuery(this).hasClass("can_edit")) {
            edit = true;
        }
        if (jQuery(this).hasClass("can_save")) {
            save = true;
        }
        asset_list.show_context(id, type, e.pageX, e.pageY, upload, edit, save);
        return false;
    },
    show_context: function(id, type, x, y, upload, edit, save){
        asset_list.remove_context();
        var menu_list = '';
        if (edit) {
          menu_list += '<div><a class="mt-open-dialog" href="' + ScriptURI + '?__mode=view&sidebar=1&_type=asset&id=' + id + '&blog_id=' + blog_id + '">' + asset_list.trans['Edit'] + '</a></div>';
        }
        if (type == 'image') {
            if (is_edit_entry) {
                menu_list += '<div><a class="mt-open-dialog" href="' + ScriptURI + '?__mode=complete_insert';
                menu_list += '&_type=asset';
                menu_list += '&return_args=__mode=list_assets&filter=class&_type=asset&blog_id=' + blog_id + '&filter_val=image';
                menu_list += '&magic_token=' + magic_token;
                menu_list += '&dialog_view=1';
                menu_list += '&no_insert=0';
                menu_list += '&dialog=1';
                menu_list += '&id=' + id;
                menu_list += '&edit_field=editor-content-textarea';
                menu_list += '&blog_id=' + blog_id;
                menu_list += '&direct_asset_insert=1';
                menu_list += '&entry_insert=1">' + asset_list.trans['text_paste'] + '</a></div>';
            }
        }
        if (edit) {
            menu_list += '<div><a onclick="asset_list.asset_delete(' + id + ',' + blog_id + ');" href="javascript:void(0);">' + asset_list.trans['text_delete'] + '</a></div>';
        }
        if (menu_list != "") {
            var menu = jQuery('<div>').addClass('asset_context')
                                 .append(menu_list)
                                 .css({
                                     'top'  : y + 'px',
                                     'left' : x + 'px'
                                 });
            jQuery('body').append(menu);
            jQuery('.asset_context a.mt-open-dialog').mtDialog();
            jQuery(window).scroll(function() {
                jQuery('.asset_context').hide();
            });
            jQuery('.asset_list_box').scroll(function() {
                jQuery('.asset_context').hide();
            });
            menu.show();
        }
        return false;
    },
    remove_context: function() {
        jQuery('body .asset_context').remove();
    },
    toggle_multi: function(trigger){
        var parent = jQuery(trigger).parent('form');
        parent.toggleClass('open').toggleClass('close');
        if (parent.hasClass('close')) { // Close Form
            var list_height   = jQuery('#asset_all_list').outerHeight();
            list_height = list_height + asset_list.trigger_height;
            if (jQuery('#drop').css('display') == 'none') {
                list_height += 45;
            }
            jQuery('.multi_upload')
                .animate({
                    'height' : list_height + "px"
                });
        } else {
            jQuery('.multi_upload')
                .animate({
                    'height' : "45px"
                });
        }
    },
    send: function(){
       jQuery('#upload_form').ajaxSubmit({
            beforeSubmit : function(formData, jqForm, options) {
                jQuery('#uploads_button')
                    .attr('disabled', 'disabled')
                    .addClass('disabled-button');
                jQuery('#upload_form .sidebar_blocks img').attr('src', StaticURI + 'images/indicator-login.gif');
                asset_list.init_before_reload();
            },
            success : function(data) {
                asset_list.cancel();
                jQuery('.asset_tab').removeClass('current loaded end');
                jQuery('#asset_all').addClass('current');
                jQuery('.asset_list_box .list').html('');
                jQuery('.asset_list_box').hide();
                jQuery('#asset_all_list').show();
                jQuery('#asset_all_list .indicator').show();
                jQuery('#menu_tabs .trigger_item a').removeClass('loaded');
                asset_list.load_list(jQuery('#menu_tabs .trigger_item a'));
                jQuery('#uploads_button')
                    .removeAttr('disabled')
                    .removeClass('disabled-button');
                jQuery('.asset_tab li').removeClass('current end loaded');
                jQuery('.asset_tab li#asset_all').addClass('current');
            }
        });
        return false;
    },
    init_before_reload: function() {
        jQuery('.asset_list_box').removeClass('end');
        asset_list.page_all.page   = 1;
        asset_list.page_all.offset = 20;
        asset_list.page_file.page   = 1;
        asset_list.page_file.offset = 20;
        asset_list.page_image.page   = 1;
        asset_list.page_image.offset = 20;
        asset_list.page_audio.page   = 1;
        asset_list.page_audio.offset = 20;
        asset_list.page_video.page   = 1;
        asset_list.page_video.offset = 20;
    },
    clear: function() {
        jQuery('#upload_form input')
            .removeAttr('disabled')
            .removeClass('disabled');
        jQuery('#upload_form .sidebar_blocks').remove();
        jQuery('#upload_form .sidebar_blocks img').attr('src', StaticURI + 'images/status_icons/close.gif');
        asset_list.blocks = 1;
        asset_list.add_form('',true);
    },
    cancel: function(ipt) {
        asset_list.clear();
        jQuery('.multi_upload').animate({
            'height' : asset_list.trigger_height + 'px'
        });
        jQuery('#upload_form')
               .toggleClass('open')
               .toggleClass('close');
        return false;
    },
    set_css: function(){
        if (jQuery('#upload_form input[name="flds"]').val() < 1) {
        } else {
            jQuery('.multi_upload #uploads_button')
                .removeClass('disabled-button')
                .removeAttr('disabled');
        }
        jQuery('.MultiFile-list li').removeClass('even odd');
        jQuery('.MultiFile-list li:odd').addClass('even');
        jQuery('.MultiFile-list li:even').addClass('odd');
    },
    tab: function(target){
        jQuery('.asset_list_box').scrollTop(0);
        var current = jQuery('.asset_tab li.current').attr('id');
        var current_id = "#" + current;
        var target_id  = "#" + target;
        if (current_id != target_id) {
            if (!jQuery(target_id).hasClass('loaded')) {
                var type = target_id.replace("#asset_","");
                if (target_id != "#asset_all") {
                    jQuery('#asset_' + type + '_list .indicate').show();
                    jQuery.ajax({
                        'url'      : sidebar_options.data_url + '&class=' + type + '&__=' + (new Date()).getTime(),
                        'method'   : 'get',
                        'dataType' : 'text',
                        success : function(data, dataType) {
                            if (data.match('<head>')) {
                                asset_list.load_error();
                                return;
                            }
                            jQuery(target_id + "_list .list").append(data);
                            jQuery('.asset_list_box').scrollTop(0);
                            asset_list.set_loaded_css(type);
                            asset_list.set_next_loading(1, type);
                        }
                    });
                }
            }
            jQuery('.asset_list_box').hide();
            jQuery(target_id + '_list').show();
            jQuery('.asset_tab li').removeClass('current');
            jQuery(target_id).addClass('current');
        }
    },
    /*
     * ページの自動読み込み
     */
    load_page: function(id) {
        var type = id.replace("asset_","").replace("_list","");
        var page   = Number(asset_list['page_' + type]['page']);
        var offset = Number(asset_list['page_' + type]['offset']);
        var count  = Number(asset_count[type]);
        if ( !jQuery('#' + id).hasClass('end') && count > 20 && asset_list.loading == false) {
            asset_list.loading = true;
            jQuery('#' + id + ' .indicate').toggle();
            var load_url = sidebar_options.data_url + '&offset=' + offset;
            if (type != 'all') {
                load_url += '&class=' + type;
            }
            jQuery.ajax({
                'url'      : load_url + '&__=' + (new Date()).getTime(),
                'method'   : 'get',
                'dataType' : 'text',
                success : function(data, dataType) {
                    if (data.match('<head>')) {
                        asset_list.load_error();
                        return;
                    }
                    jQuery('#' + id + ' .list').append(data);
                    asset_list.set_loaded_css(type);
                    asset_list.set_next_loading(page, type);
                    asset_list.loading = false;
                }
            });
        }
        var max = page * 20;
        if (count < max) {
            jQuery('#' + id).addClass('end');
        }
    },
    load_list: function(elem){
        if (!jQuery(elem).hasClass('loaded')) {
            jQuery('#asset_all_list .indicate').show();
            jQuery(elem).addClass('loaded');
            jQuery.ajax({
                'url'      : sidebar_options.data_url + '&__=' + (new Date()).getTime(),
                'method'   : 'get',
                'dataType' : 'text',
                success : function(data, dataType) {
                    if (data.match('<head>')) {
                        asset_list.load_error();
                        return;
                    }
                    jQuery('#asset_all_list .list').append(data);
                    // For Next Loading
                    asset_list.set_loaded_css('all');
                    asset_list.set_next_loading(1, 'all');
                    jQuery('#asset_all_list .thumbnail .thumbnail_footer a').bind('contextmenu', asset_list.context);
                }
            });
        }
        return false;
    },
    set_next_loading: function(page, type){
        asset_list['page_' + type]['offset'] = page * 20;
        asset_list['page_' + type]['page']   = page + 1;
    },
    set_loaded_css: function(type){
        jQuery('#asset_' + type + '_list .indicate').hide();
        jQuery('#asset_' + type + '_list .list a.mt-open-dialog').mtDialog();
        jQuery('#asset_' + type + '_list .list .thumbnail_footer a')
            .mousedown(
                function(e) {
                    var menu_offset = (jQuery('#menu').css('top')).replace('px', '');
                    jQuery(this).children('span').css({
                        'top'  : e.clientY - 10 - menu_offset + "px",
                        'left' : e.pageX + "px"
                    });
                }
            )
            .bind('contextmenu', asset_list.context);
        jQuery('#asset_' + type + '_list .list .thumbnail_footer a span').css('opacity', 0);
        if (jQuery.browser.msie) {
            jQuery('#asset_' + type + '_list .list .thumbnail_footer a').hover(
                function() {
                    var range = document.body.createTextRange();
                    range.moveToElementText(this);
                    range.select();
                },
                function() {
                }
            );
        }
        jQuery('#asset_' + type).addClass('loaded');
    },
    mouseon_icon: function(id) {
        var text = document.getElementById(id);
        if (jQuery.browser.msie) {
            var range = document.body.createTextRange();
            range.moveToElementText(text);
            range.select();
        } else if (jQuery.browser.mozilla || jQuery.browser.opera) {
            var selection = window.getSelection();
            var range     = document.createRange();
            range.selectNodeContents(text);
            selection.removeAllRanges();
            selection.addRange(range);
        } else if (jQuery.browser.safari) {
        }
    },
    add_form : function(ipt,reset){
        asset_list.blocks++;
        jQuery(ipt).addClass('selected');
        if (reset != true) {
            var file_name = jQuery(ipt).val();
            var name_id   = jQuery(ipt).attr('name').replace('sidebar_image_','');
            jQuery('#sidebar_name_' + name_id).attr('value', file_name).focus();
        }
        if (jQuery(ipt).hasClass('selected') || reset == true) {
            var count = jQuery('#upload_form input[name="flds"]').val();
            jQuery('#upload_form input[name="flds"]').attr('value', Number(count) + 1);
            var id = 'sidebar_block_' + asset_list.blocks;
            jQuery('<div>')
                .addClass('sidebar_blocks add_blocks')
                .attr('id', id)
                .appendTo('form#upload_form .input');
            jQuery('<img>')
                .attr({
                    'src' : StaticURI + 'images/status_icons/close.gif',
                    'width' : 9,
                    'height' : 9
                })
                .bind('click', asset_list.remove_form)
                .appendTo("#" + id);
            jQuery("#" + id).append('\n');
            var name = jQuery('<input>').attr({
                    'type' : 'text',
                    'name' : 'sidebar_name_' + asset_list.blocks,
                    'id'   : 'sidebar_name_' + asset_list.blocks
                }).addClass('file_name text');
            name.appendTo("#" + id);
            var file = jQuery('<input>').attr({
                'type' : 'file',
                'name' : 'sidebar_image_' + asset_list.blocks
            })
            .addClass('multi_files');
            
            file.change(function(){
                asset_list.add_form(this,false);
            })
            
            jQuery('<span>')
                .attr({
                    'class' : 'cabinet'
                })
                .append(file)
                .appendTo("#" + id);
        }
    },
    remove_form : function(){
        var count = jQuery('.sidebar_blocks').size();
        if (count > 1 ) {
            var count = jQuery('#upload_form input[name="flds"]').val();
            jQuery('#upload_form input[name="flds"]').attr('value', Number(count) - 1);
            var target = jQuery(this).parent('div').attr('id');
            jQuery('#' + target).remove();
        }
    },
    asset_delete: function(id, blog_id){
        if (!confirm(asset_list.trans['Do you really want to delete files?\nThere is no way to undo this operation.'])) {
            return false;
        }
        asset_list.remove_context();
        jQuery(".sidebar_asset-" + id).css('opacity', '0.5');
        jQuery('.asset_tab li').removeClass('current end loaded');
        jQuery('#asset_all').addClass('current');
        jQuery('.asset_list_box .list').html('');
        jQuery('.asset_list_box').hide();
        jQuery('#asset_all_list').show();
        jQuery('#asset_all_list .indicate').show();
        jQuery('.asset_tab li#asset_all').addClass('current');
        jQuery.ajax({
            'url'      : ScriptURI,
            'type'     : 'POST',
            'method'   : 'POST',
            'dataType' : 'text',
            'data'     : {
                '__mode'      : 'delete',
                '_type'       : 'asset',
                'blog_id'     : blog_id,
                'id'          : id,
                'magic_token' : magic_token
            },
            success : function(data, dataType) {
                asset_list.init_before_reload();
                asset_list.load_list();
            }
        });
        return false;
    },
    load_error: function() {
        alert(asset_list.trans['Failed to load items list.\nPlease retry to login.']);
    },
    reload: function(){
        jQuery('.asset_tab li').removeClass('current end loaded');
        jQuery('#asset_all').addClass('current');
        jQuery('.asset_list_box .list').html('');
        jQuery('.asset_list_box').hide();
        jQuery('#asset_all_list').show();
        jQuery('#asset_all_list .indicate').show();
        jQuery('.asset_tab li#asset_all').addClass('current');
        asset_list.init_before_reload();
        asset_list.remove_context();
        asset_list.load_list();
    }
}
