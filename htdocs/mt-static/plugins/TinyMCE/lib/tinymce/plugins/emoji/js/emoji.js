tinyMCEPopup.requireLangPack();
var EmojiDialog = {
    init : function(ed) {
        tinyMCEPopup.resizeToInnerSize();
    },

    insert : function(file, a) {
        var ed = tinyMCEPopup.editor, dom = ed.dom;
        var title = a.getElementsByTagName('img')[0].alt;
        tinyMCEPopup.execCommand('mceInsertContent', false, dom.createHTML('img', {
            src : window.img_path + file,
            alt : title,
            title : title
        }));
        tinyMCEPopup.close();
        ed.focus();
    },
	
	write_img: function(file,alt){
		document.write('<a href="#" onclick="EmojiDialog.insert(\''+ file + '\',this);return false;"><img src="' + window.img_path + file + '" alt="' + alt + '"/></a>')
	}
};

window.img_path = parent.tinymce_editor.sub_init['emoji_path'];
if(!window.img_path){
    window.img_path = tinyMCEPopup.getWindowArg('plugin_url') + '/img/';
}

tinyMCEPopup.onInit.add(EmojiDialog.init, EmojiDialog);
