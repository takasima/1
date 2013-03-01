/**
 * Power CMS 2 Gears plugin
 */

var global_counter   = 0;
var global_files     = null;
var global_max       = 0;
var global_uploading = 0;
var global_mode      = '';
var global_now_ext   = '';

(function(jQuery) {

    var name_space = "PCMS2Gears";
    window.get   = false;
    var scrolled = 0;
    var moved    = 0;
    var permission = 0;

    jQuery.fn[name_space] = function(options) {
        var elements = this;

        // 設定の構築
        window.settings = jQuery.extend({
            boundary : '------multipartformboundary' + (new Date).getTime(),
            dashdash : '--',
            crlf     : '\r\n',
            eventMap : {
                'dragenter' : 'dragenter',
                'dragover'  : 'dragover',
                'dragleave' : 'dragexit',
                'drop'      : 'dragdrop'
            }
        }, options);


        /**
         * イベントの追加
         */
        var add_event = function(element, name, handler)
        {
            if( settings.browser != 'MSIE' && settings.browser != "Explorer") {
                var event_name;
                if (settings.browser != 'Firefox') {
                    event_name = name;
                } else {
                    event_name = settings.eventMap[name]
                }
                if (settings.browser == 'Firefox' && settings.version < '3.5') {
                    name = settings.eventMap[name];
                }
                target.addEventListener(name, handler, false);
            } else {
                target.attachEvent('on' + name, handler);
            }
        };

        /**
         * ドロップ領域にマウスが入った
         */
        var _hdlr_over = function(e)
        {
            jQuery('#drop').addClass('hover_box');
            e.returnValue = false;
            desktop.setDragCursor(e, 'copy');

            if (moved == 0) {
                scrolled = jQuery(document).scrollTop();
            }
            moved++;
//            jQuery('html,body').scrollTop(0);
            jQuery('html,body').scrollTop(jQuery('html,body').scrollTop());
        };

        /**
         * ドロップ領域からマウスが外れた
         */
        var _hdlr_leave = function(e)
        {
            jQuery('#drop').removeClass('hover_box');
            e.returnValue = false;
            desktop.setDragCursor(e, 'none');
            moved = 0;

        };

        /**
         * ドロップ領域にドロップされた
         */
        var _hdlr_drop = function(e)
        {
            if (global_uploading == 1) {
                alert(trans('Another uploading process is in progress.'));
                return;
            }
            global_uploading = 1;
            e.stopPropagation && e.stopPropagation();
            var data       = desktop.getDragData(e, 'application/x-gears-files');
            //if ( data.count > 10 ) {
            //    alert(trans('It is [_1] files to upload at one time.', 10));
            //    global_uploading = 0;
            //    return;
            //}
            //if ( <MTCGIMaxUpload> < data.totalLength ) {
            //    alert(trans('Exceeded the size limit for uploading files at one time.'));
            //    global_uploading = 0;
            //    return;
            //}
            var files      = data && data.files;
            global_files   = files;
            global_counter = 0;
            global_max = data.count;
            global_upload_token = 'ut_' + (new Date()).getTime();
            jQuery('.asset_list_box .list').html('');
            jQuery('.asset_list_box').hide();

            jQuery('#asset_all_list').show();
            jQuery('#asset_all_list .indicate').toggle();

            setTimeout('handleUpload2()', 100 );

            /* Prevent FireFox opening the dragged file. */
            if (jQuery.browser.mozilla) {
                e.stopPropagation();
            }
        };

        var get_list_data = function(mode)
        {
            if (permission > 0) {
                alert(permission_denied);
            }
            if (window.get == false) {
                jQuery.ajax({
                    'url'      : settings.data_url + '&__=' + (new Date()).getTime(),
                    'method'   : 'get',
                    'dataType' : 'text',
                    success : function(data, dataType){
                        if(data.match('<head>')){
                            asset_list.load_error();
                            return;
                        }
                        jQuery('#asset_all_list .list').append(data);
                        jQuery('#asset_all_list .indicate').toggle();
                        jQuery('#asset_all_list .thumbnail a')
                            .mousedown(
                                function(e) {
                                    var menu_offset = pcms_util.px2int(jQuery('#menu').css('top'));
                                    jQuery(this).children('span').css({
                                        'top'  : e.pageY - menu_offset + "px",
                                        'left' : e.pageX + "px"
                                    });
                                }
                            );
                        jQuery('#asset_all_list .thumbnail a span').css('opacity', 0);
                        mode = 'all';

                        jQuery('.asset_tab li').removeClass('current end loaded');
                        jQuery('.asset_tab li#asset_all').addClass('current');
                        jQuery('#asset_all_list .thumbnail a').bind('contextmenu', asset_list.context);

                        jQuery('.asset_list_box').removeClass('end');
                        asset_list.set_loaded_css('all');
                        asset_list.set_next_loading(1, 'all');
                    }
                });
                /*
                jQuery('#asset_all_list .list').load(
                    settings.data_url + '&__=' + (new Date()).getTime(),
                    function(){
                        jQuery('#asset_all_list .indicate').toggle();
                        jQuery('#asset_all_list .thumbnail a')
                            .mousedown(
                                function(e) {
                                    var menu_offset = pcms_util.px2int(jQuery('#menu').css('top'));
                                    jQuery(this).children('span').css({
                                        'top'  : e.pageY - menu_offset + "px",
                                        'left' : e.pageX + "px"
                                    });
                                }
                            );
                        jQuery('#asset_all_list .thumbnail a span').css('opacity', 0);
                        mode = 'all';

                        jQuery('.asset_tab li').removeClass('current end loaded');
                        jQuery('.asset_tab li#asset_all').addClass('current');
                        jQuery('#asset_all_list .thumbnail a').bind('contextmenu', asset_list.context);

                        jQuery('.asset_list_box').removeClass('end');
                        asset_list.set_loaded_css('all');
                        asset_list.set_next_loading(1, 'all');
                    }
                );
                */
                window.get = true;
            }
        }

        window.get_list_data2 = get_list_data;

        var desktop = null;
        var action  = ['install', trans('install')];

        try {
            if(!window.google || !window.google.gears)
              throw null;
            action = ['upgrade', trans('upgrade')];
            desktop = google.gears.factory.create('beta.desktop');
        } catch(e) {
            var message = trans('Do you want to [_1] Gears now?', action[1]);
            var install_url = 'http://gears.google.com/?action=' + action[0]
                             + '&message=' + encodeURIComponent(message)
                             + '&return=' + encodeURIComponent(window.location.href);
            if(!jQuery.cookie('no_gears')){
                if (window.confirm(message)) {
                    window.location.href = install_url;
                    is_dnd = true;
                } else {
                    is_dnd = true;
                    jQuery.cookie('no_gears','1');
                }
            }
        }

        jQuery('#drop').show();

        var target  = document.getElementById(settings.target_id);
        add_event(target, 'dragenter', _hdlr_over);
        add_event(target, 'dragover',  _hdlr_over);
        add_event(target, 'dragleave', _hdlr_leave);
        add_event(target, 'drop',      _hdlr_drop);

        return this;
    }

})(jQuery);

function handleUpload2() {
    var files      = global_files;
    var i = global_counter;
    window.get = false;
    var ext  = '';
    var file = files[i];
    try{
        var dummy = file.name;
    }catch(e){
        asset_list.init_before_reload();
        get_list_data2(global_mode);
        return;
    }
    if (file.name) {
        var now_ext;
        if (global_mode != 'all') {
            if (file.name.match(/(gif|jpe?g|png|bmp|tiff?)$/i)) {
                now_ext = 'image';
            } else if (file.name.match(/(mov|avi|3gp|asf|mp4|qt|wmv|asx|mpg|flv|mkv|ogm)$/i)) {
                now_ext = 'video';
            } else if (file.name.match(/(mp3|ogg|aiff?|wav|wma|aac|flac|m4a)$/i)) {
                now_ext = 'audio';
            } else {
                now_ext = 'other';
            }
            if (global_counter > 0) {
                if (global_now_ext != now_ext) {
                    global_mode = 'all';
                } else {
                    global_mode = global_now_ext;
                }
            } else {
                global_mode = now_ext;
            }
            global_now_ext = now_ext;
        }

        var builder = google.gears.factory.create('beta.blobbuilder');

        builder.append(settings.dashdash);
        builder.append(settings.boundary);
        builder.append(settings.crlf);

        /* Generate headers. */
        var disposition = 'Content-Disposition: form-data; name="Filedata"; '
                        + 'filename="' + encodeURIComponent(file.name) + '"; '
                        + 'magic_token="' + settings.magic_token + '";';
        builder.append(disposition);
        builder.append(settings.crlf);

        builder.append('Content-Type: application/octet-stream');
        builder.append(settings.crlf);
        builder.append(settings.crlf);

        /* Append binary data. */
        builder.append(file.blob);
        builder.append(settings.crlf);

        /* Write boundary. */
        builder.append(settings.dashdash);
        builder.append(settings.boundary);
        builder.append(settings.crlf);

        /* Mark end of the request. */
        builder.append(settings.dashdash);
        builder.append(settings.boundary);
        builder.append(settings.dashdash);
        builder.append(settings.crlf);

        var request = google.gears.factory.create('beta.httprequest');
        request.onreadystatechange = function() {
            switch(request.readyState) {
                case 4:
                global_counter++;
                if ( global_counter < global_max ) {
                    setTimeout('handleUpload2()', 100 );
                } else {
                    //alert('owari!')
                    //alert('Complete!'+global_mode);
                    global_counter   = 0;
                    global_files     = null;
                    global_max       = 0;
                    global_uploading = 0;
                    global_mode      = '';
                    global_now_ext   = '';

                    asset_list.init_before_reload();
                    get_list_data2(global_mode);
                }
            }
        };
        /* Use Gears to submit the data. */
        //alert(options.url + '&upload_token=' + global_upload_token + '&file_num=' + global_max)
        request.open("POST", settings.url + '&upload_token=' + global_upload_token + '&file_num=' + global_max);
        request.setRequestHeader('content-type', 'multipart/form-data; boundary=' + settings.boundary);
        request.send(builder.getAsBlob());
    }
}
