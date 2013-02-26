/*============================================================**
        make object
**============================================================*/

var tinymce_editor = new Object();
tinymce_editor.temp = new Object();
tinymce_editor.sub_init = new Object();
tinymce_editor.trans = new Object();
tinymce_editor.ed = new Array();


/*============================================================**
        tinymce_editor.init
**============================================================*/

tinymce_editor.init = {
    mode : 'exact',
    theme : 'advanced',
    convert_urls : false,
    cleanup : true,
    dialog_type : 'modal',
    height: 355,
    script_url : StaticURI + 'plugins/TinyMCE/lib/tinymce/tiny_mce.js',
    theme_advanced_toolbar_location : 'top',
    theme_advanced_toolbar_align : 'left',
    theme_advanced_statusbar_location : 'bottom',
    theme_advanced_resizing : true,
    theme_advanced_resize_horizontal : false,
    theme_advanced_resizing_min_height : 100,
    loading : function(id) {
        jQuery('#' + id)
            .parent()
            .css({
                'min-height': '200px',
                'background': '#fff url(' + StaticURI + 'images/indicator.gif) no-repeat 50% 50%'
            });
    },
    setup : function(ed) {
        tinymce_editor.init.loading(ed.id);
        ed.onPostRender.add(function(ed, cm){
            tinymce_editor.ed[ed.id] = ed;
            if(jQuery('#' + ed.id).hasClass('full-width')){
                jQuery('#' + ed.id + '_parent').css({'width':'100%'});
            }
        });
        ed.onBeforeRenderUI.add(function(ed, o) {
            jQuery('#' + ed.id)
                .parent()
                .css({
                    'min-height': '0px',
                    'background': 'none'
                });
        });
        ed.addButton('mt-image', {
            title : tinymce_editor.trans['Insert_Image'],
            image : StaticURI + 'plugins/TinyMCE/images/photo.png',
            onclick : function() {
                if(ed.getContent()){
                    if(ed.id == 'mce_fullscreen'){
                        var ed_fs = jQuery('#' + ed.id).tinymce();
                        ed_fs.focus();
                        tinymce_editor.bookmark = ed_fs.selection.getBookmark();
                    }else{
                        ed.focus();
                        tinymce_editor.bookmark = ed.selection.getBookmark();
                    }
                }else{
                    tinymce_editor.bookmark = false;
                }
                jQuery.fn.mtDialog.open(ScriptURI + '?__mode=list&_type=asset&edit_field=' + ed.id + '&blog_id=' + tinymce_editor.sub_init['blog_id'] + '&dialog_view=1&filter=class&filter_val=image');
                jQuery('#mt-dialog-iframe').focus();
                tinymce_editor.check_field();
            }
        });
        ed.addButton('mt-file', {
            title : tinymce_editor.trans['Insert_File'],
            image : StaticURI + 'plugins/TinyMCE/images/page_white_text.png',
            onclick : function() {
                if(ed.getContent()){
                    if(ed.id == 'mce_fullscreen'){
                        var ed_fs = jQuery('#' + ed.id).tinymce();
                        ed_fs.focus();
                        tinymce_editor.bookmark = ed_fs.selection.getBookmark();
                    }else{
                        ed.focus();
                        tinymce_editor.bookmark = ed.selection.getBookmark();
                    }
                }else{
                    tinymce_editor.bookmark = false;
                }
                jQuery.fn.mtDialog.open(ScriptURI + '?__mode=list&_type=asset&edit_field=' + ed.id + '&blog_id=' + tinymce_editor.sub_init['blog_id'] + '&dialog_view=1');
                jQuery('#mt-dialog-iframe').focus();
                tinymce_editor.check_field();
            }
        });
        ed.addButton('mt-link', {
            title : tinymce_editor.trans['Insert_Link'],
            image : StaticURI + 'plugins/TinyMCE/images/link.png',
            onclick : function() {
                if(ed.getContent()){
                    if(ed.id == 'mce_fullscreen'){
                        var ed_fs = jQuery('#' + ed.id).tinymce();
                        ed_fs.focus();
                        tinymce_editor.bookmark = ed_fs.selection.getBookmark();
                    }else{
                        ed.focus();
                        tinymce_editor.bookmark = ed.selection.getBookmark();
                    }
                }else{
                    tinymce_editor.bookmark = false;
                }
                jQuery.fn.mtDialog.open(ScriptURI + '?__mode=list_link&edit_field=' + ed.id + '&blog_id=' + tinymce_editor.sub_init['blog_id'] + '&dialog_view=1');
                jQuery('#mt-dialog-iframe').focus();
                tinymce_editor.check_field();
            }
        });
    },
    extended_valid_elements : 'form[action|accept|accept-charset|enctype|method|class|style|name]'
}


/*============================================================**
        tinymce_editor.show
**============================================================*/

tinymce_editor.show = function(target){
    target.tinymce(tinymce_editor.init);
}


/*============================================================**
        tinymce_editor.remove
**============================================================*/

tinymce_editor.remove = function(target){
    var id = target.attr('id');
    if(tinymce_editor.ed[id]){
        target.tinymce().remove();
        delete tinymce_editor.ed[id];
    }
}


/*============================================================**
        tinymce_editor.insert_HTML
**============================================================*/

tinymce_editor.insert_HTML = function(html, field){
    //alert(field)
    if(field == 'mce_fullscreen'){
        var ed = jQuery('#' + field).tinymce();
    }else{
        var ed = tinymce_editor.ed[field];
    }
    if(ed){
        ed.focus();
        ed.selection.moveToBookmark(tinymce_editor.bookmark);
        ed.execCommand('mceInsertContent',false,html);
    }else{
        try{
            window.app.fixHTML( window.app.editor.insertHTML( html ) );
        }catch(e){
        
        }
    }
}


/*============================================================**
        tinymce_editor.check_field
**============================================================*/

tinymce_editor.check_field = function(){
    if(!tinymce_editor.checked_field){
        if(window.app.insertHTML){
        }else{
            window.app.insertHTML = tinymce_editor.insert_HTML;
        }
        
        tinymce_editor.insertCustomFieldAsset = window.insertCustomFieldAsset;
        window.insertCustomFieldAsset = function(html, id, preview_html){
            if(getByID(id + '_remove_asset')){
                tinymce_editor.insertCustomFieldAsset(html, id, preview_html);
            }else{
                tinymce_editor.insert_HTML(html, id, preview_html);
            }
        }
        tinymce_editor.checked_field = true;
    }
}

/*============================================================**
        Overwrite
**============================================================*/

jQuery(function(){
    App.singletonConstructor =
    MT.App = new Class( MT.App, {
        insertHTML: function( html, field ) {
            if(!field){
                this.fixHTML( this.editor.insertHTML( html ) );
            }else{
                tinymce_editor.insert_HTML(html, field);
            }
        }
    });
});

/*============================================================**
        load
**============================================================*/

jQuery(function(){
    // load
    tinymce_editor.init.loading();
    tinymce_editor.show(jQuery('textarea.editor'));
    //tinymce_editor.show(jQuery('textarea#excerpt')); // debug
    //tinymce_editor.show(jQuery('textarea')); // debug

    // sort problem
    jQuery('#sortable').bind('sortstart', function(event, ui) {
        var target = ui.item;
        var editors = target.find('.mceEditor');
        if(editors.length){
            tinymce_editor.temp.editors_id = new Array();
            editors.each(function(i){
                var id = jQuery(this).attr('id').split('_parent')[0];
                tinymce_editor.remove(jQuery('#' + id));
                tinymce_editor.temp.editors_id.push(id);
            });
        }
    });
    jQuery('#sortable').bind('sortstop', function(event, ui) {
        var editors_id = tinymce_editor.temp.editors_id;
        if(editors_id){
            for(var i = 0; i < editors_id.length; i++){
                tinymce_editor.show(jQuery('#' + editors_id[i]));
            }
            tinymce_editor.temp.editors_id = new Array();
        }
    });
})