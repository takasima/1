/*
 * Power CMS 2 File API plugin
 * only Firefox 3.6+
 */
(function(jQuery) {
    var name_space = "PCMS2FileApi";
    var get   = false;
    var scrolled = 0;
    var moved    = 0;
    var permission = 0;
    jQuery.fn[name_space] = function(options) {
        var elements = this;
        var settings = jQuery.extend({
            boundary : '------multipartformboundary' + (new Date).getTime(),
            dashdash : '--',
            crlf     : '\n',
            eventMap : {
                'dragenter' : 'dragenter',
                'dragover'  : 'dragover',
                'dragleave' : 'dragexit',
                'drop'      : 'dragdrop'
            }
        }, options);
        var _hdlr_over = function(e)
        {
            e.stopPropagation();
            e.preventDefault();
            target.setAttribute("dragenter", true);
            if (moved == 0) {
                scrolled = jQuery(document).scrollTop();
            }
            moved++;
            jQuery('html,body').scrollTop(jQuery('html,body').scrollTop());
        };
        var _hdlr_leave = function(e) {
            e.stopPropagation();
            e.preventDefault();
            target.removeAttribute("dragenter");
            moved = 0;
        };
        var _hdlr_drop = function(e) {
            get = false;
            jQuery('.asset_list_box .list').html('');
            jQuery('.asset_list_box').hide();
            jQuery('#asset_all_list').show();
            jQuery('#asset_all_list .indicate').toggle();
            var dt    = e.dataTransfer;
            var files = dt.files;
            e.stopPropagation();
            e.preventDefault();
            var file_count = files.length;
            var next = 0;
            var ext  = '';
            var mode = 'all';
            var upload_token = 'ut_' + (new Date()).getTime();
            var file_num = files.length;
            if(!window.upload_count){
              window.upload_count = new Array();
            }
            window.upload_count[upload_token] = 0;
            window.file_reader = new Array();
            if (files.length > 0) {
                for (var i=0; i<files.length; i++) {
                    try {
                        var current = Number(i);
                        var next    = current + 1;
                        var file = files[i]
                        if (file.fileName || file.name) {
                            var file_name = file.fileName || file.name;
                            var obj = file;
                            
                            var now_ext;
                            if (file_name.match(/(gif|jpe?g|png|bmp|tiff?)$/i)) {
                                now_ext = 'image';
                            } else if (file_name.match(/(mov|avi|3gp|asf|mp4|qt|wmv|asx|mpg|flv|mkv|ogm)$/i)) {
                                now_ext = 'video';
                            } else if (file_name.match(/(mp3|ogg|aiff?|wav|wma|aac|flac|m4a)$/i)) {
                                now_ext = 'audio';
                            } else {
                                now_ext = 'other';
                            }
                            if (ext == '') {
                                ext = now_ext;
                            }
                            if (file_count > 1) {
                                if (now_ext != ext) {
                                    mode = 'all';
                                } else {
                                    mode = now_ext;
                                }
                            } else {
                                mode = now_ext;
                            }
                            ext = now_ext;
                            
                            var data_upload = function(binary,file){
                                var disposition = 'Content-Disposition: form-data; name="Filedata"; '
                                                + 'filename="' + encodeURIComponent( file.name ) + '"; '
                                                + 'magic_token="' + settings.magic_token + '";';
                                var ret = new Array();
                                ret.push(
                                    settings.dashdash + settings.boundary,
                                    'Content-Type: application/octet-stream',
                                    'Content-Length: ' + file.size,
                                    disposition,
                                    'Content-Transfer-Encoding: binary',
                                    '',
                                    binary,
                                    '',
                                    settings.dashdash + settings.boundary + settings.dashdash,
                                    ''
                                );
                                var content = ret.join('\r\n');
                                
                                /*
                                jQuery.ajax({
                                    type: 'POST',
                                    url: settings.url + '&upload_token=' + upload_token + '&file_num=' + file_num,
                                    dataType: 'text',
                                    beforeSend: function(xhr) {
                                        xhr.setRequestHeader('Content-Type', 'multipart/form-data; boundary=' + settings.boundary);
                                        xhr.setRequestHeader('Content-Length', content.length);
                                        xhr.sendAsBinary(content);    // sendAsBinary is not a function... (jQuery1.6)
                                    },
                                    success: function(txt){
                                        window.upload_count[upload_token]++;
                                        if(window.upload_count[upload_token] == file_num){
                                            asset_list.init_before_reload();
                                            get_list_data(mode);
                                        }
                                    },
                                    error: function(){
                                    }
                                });
                                */
                                
                                var xhr = new XMLHttpRequest();
                                xhr.onreadystatechange = function(){
                                    if (xhr.readyState == 4 && xhr.status == 200){
                                        window.upload_count[upload_token]++;
                                        if(window.upload_count[upload_token] == file_num){
                                            asset_list.init_before_reload();
                                            get_list_data(mode);
                                        }
                                    }
                                };
                                xhr.open('POST', (settings.url + '&upload_token=' + upload_token + '&file_num=' + file_num), true);
                                xhr.setRequestHeader('Content-type','multipart/form-data; boundary=' + settings.boundary);
                                xhr.setRequestHeader('Content-length',content.length);
                                xhr.sendAsBinary(content);
                            }
                            
                            var binary = '';
                            if(file.fileName){
                                binary = file.getAsBinary();
                                data_upload(binary,file);
                            }else if(file.name){
                                var key = 'file_' + i;
                                window.file_reader[key] = new FileReader();
                                window.file_reader[key].file = file;
                                window.file_reader[key].onload = function(event) {
                                    var binary = this.result;
                                    var file = this.file;
                                    data_upload(binary,file);
                                }
                                window.file_reader[key].readAsBinaryString(file);
                            }
                        }
                    }catch(e){
                        asset_list.init_before_reload();
                        get_list_data(mode);
                    }
                }
            }
        };
        var get_list_data = function(mode) {
            if (permission > 0) {
                alert(permission_denied);
            }
            if (get == false) {
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
                get = true;
            }
        }
        jQuery('#drop').show();
        var target = document.getElementById(settings.target_id);
        window.addEventListener("dragenter", _hdlr_over, true);
        window.addEventListener("dragleave", _hdlr_leave, true);
        target.addEventListener("dragover", _hdlr_over, true);
        target.addEventListener("drop", _hdlr_drop, true);
        is_dnd = true;
        return this;
    }
})(jQuery);
