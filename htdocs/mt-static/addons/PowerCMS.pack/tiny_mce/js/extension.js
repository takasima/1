(function($) {


/*
 * MT.Editor.TinyMCE クラスの拡張
 */
$.extend(MT.Editor.TinyMCE.prototype, {
    /*
     * エディタを一時的に取り除く
     * (JavaScript のドラッグ・アンド・ドロップする際に退避する必要がある)
     */
    powercmsStash: function() {
        this.powercmsSavedFormat =
            this.tinymce.execCommand('mtGetStatus')['format'];
        var savedContent;
        if (this.editor) {
            try {
                if (this.powercmsSavedFormat != 'richtext') {
                    savedContent = this.getContent();
                    this.setFormat('richtext');
                }
                this.tinymce.remove();
            }
            catch(e) {
                $('#' + this.id + '_parent').remove();
                delete tinyMCE.editors[this.id];
            }
        }
        delete this.tinymce;
        delete this.editor;

        var $input = $('#' + this.id)
            .css('visibility', 'hidden')
        if (savedContent) {
            $input.val(savedContent);
        }
        var $siblings = $input.siblings();
        $siblings.prependTo($siblings.parent());
    },

    /*
     * 退避したエディタを元に戻す
     */
    powercmsRestore: function() {
        if (! this.editor && this.powercmsSavedFormat) {
            $('#' + this.id).css('visibility', '');

            this.initEditor(this.powercmsSavedFormat);
            delete this.powercmsSavedFormat;
        }
    }
});


/*
 * PowerCMS 用の TinyMCE プラグイン
 */
tinymce.create('tinymce.plugins.PowerCMS', {
    init : function(ed, url) {
        this.buttonIDs = {};

        var blogId = $('#blog-id').val() || 0;

        ed.addButton('mt-link', {
            title: trans('Insert Link'),
            image: StaticURI + 'addons/PowerCMS.pack/tiny_mce/images/link.png',
            onclick : function() {
                ed.execCommand('mtSaveBookmark');
                jQuery.fn.mtDialog.open(ScriptURI + '?__mode=list_link&edit_field=' + ed.id + '&blog_id=' + blogId + '&dialog_view=1');
            }
        });

        ed.addButton('mt-image', $.extend({}, ed.buttons['mt_insert_image'], {
            image: StaticURI + 'addons/PowerCMS.pack/tiny_mce/images/photo.png'
        }));
        ed.addButton('mt-file', $.extend({}, ed.buttons['mt_insert_file'], {
            image: StaticURI + 'addons/PowerCMS.pack/tiny_mce/images/page_white_text.png'
        }));
    },

    /*
     * 絵文字や画像挿入のボタンをソース編集モードでも利用できるようにする
     */
    createControl : function(name, cm) {
        var editor = cm.editor;
        var ctrl   = editor.buttons[name];

        if (
                (name == 'emoji')
                || (name == 'mt-link')
                || (name == 'mt-image')
                || (name == 'mt-file')
        ) {
            if (! this.buttonIDs[name]) {
                this.buttonIDs[name] = [];
            }

            var id = name + '_' + this.buttonIDs[name].length;
            this.buttonIDs[name].push(id);

            return cm.createButton(id, $.extend({}, ctrl, {
                'class': 'mce_' + name
            }));
        }

        return null;
    }
}); 
tinymce.PluginManager.add('powercms', tinymce.plugins.PowerCMS, ['mt']);


/*
 * TinyMCE の初期設定
 */
var config                 = MT.Editor.TinyMCE.config;
var init_instance_callback = config.init_instance_callback || function() {};
var setup                  = config.setup || function() {};
$.extend(config, {
    skin : 'default',
    inlinepopups_skin: 'clearlooks2',
    plugins: config.plugins + ',mt,mt_fullscreen,powercms',
    setup: function(ed) {
        setup.apply(this, arguments);

        // 「本文」と「続き」欄以外は高さを固定する
        switch (ed.id) {
            case 'editor-input-content':
            case 'editor-input-extended':
                break;
            default:
                ed.settings.height = 355;
                break;
        }

        // .full-width を持つテキストエリアの幅を100%にする
        ed.onPostRender.add(function(ed, cm){
            if($('#' + ed.id).hasClass('full-width')){
                $('#' + ed.id + '_parent').css({'width':'100%'});
            }
        });

        // indicator の表示と除去
        $('#' + ed.id)
            .parent()
            .css({
                'min-height': '200px',
                'background': '#fff url(' + StaticURI + 'images/indicator.gif) no-repeat 50% 50%'
            });
        ed.onBeforeRenderUI.add(function(ed, o) {
            $('#' + ed.id)
                .parent()
                .css({
                    'min-height': '0px',
                    'background': 'none'
                });
        });
    },
    init_instance_callback: function(ed) {
        init_instance_callback.apply(this, arguments);


        // 不要な要素にフォーカスが移るのを防ぐ
        $('#' + this.id + '_toolbargroup + a').attr('tabindex', -1);


        var $container = $(ed.getContainer());
        var $common_buttons_row = $container.find('.mceToolbarRow1');

        // PowerCMS で利用しないボタンを隠す
        $common_buttons_row.hide();


        if (ed.getParam('fullscreen_is_enabled')) {
            var parent = $('#' + ed.settings.fullscreen_editor_id)
                .data('mt-editor');
            $('#mce_fullscreen').data('mt-editor', parent);

            setTimeout(function() {
                tinyMCE
                    .editors[ed.settings.fullscreen_editor_id]
                    .plugins.fullscreen.resizeFunc();
            }, 0);

            return;
        }


        ed.onExecCommand.add(function(ed, cmd, status) {
            // スキンの切り替え
            if (cmd == 'mtSetStatus') {
                if (status['mode'] == 'source') {
                    $container.removeClass('defaultSkin');
                    $container.addClass('mtSkin');
                }
                else {
                    $container.removeClass('mtSkin');
                    $container.addClass('defaultSkin');
                    $common_buttons_row.hide();
                }
            }

            // MT独自のフルスクリーン機能に関する調整
            if (cmd == 'mtFullScreen') {
                if (ed.execCommand('mtFullScreenIsEnabled')) {
                    $('#text-label, #editor_select').parent().hide();
                    $('.field-content').css({
                        margin: 0,
                        padding: 0
                    });
                }
                else {
                    $('#text-label, #editor_select').parent().show();
                    $('.field-content').css({
                        margin: '',
                        padding: ''
                    });
                }
            }
        });
    }
});


$(function() {
    // フォーマット切替時の確認ダイアログの表示を抑制
    if (($('.edit-screen').length != 0) && window.changedTextFormat) {
        var original_changedTextFormat = window.changedTextFormat;
        window.changedTextFormat = function() {
          var original_confirm = window.confirm;
          window.confirm = function() { return true };
          original_changedTextFormat.apply(this, arguments);
          window.confirm = original_confirm;
        };
    }


    // ソートの開始時にエディタを退避し、終了時に復元する
    $('#sortable').bind('sortstart', function(event, ui) {
        ui.item.find(':input').each(function() {
            var manager = $(this).data('mt-editor');
            if (manager) {
                manager.currentEditor.powercmsStash();
            }
        });
    });

    $('#sortable').bind('sortstop', function(event, ui) {
        ui.item.find(':input').each(function() {
            var manager = $(this).data('mt-editor');
            if (manager) {
                manager.currentEditor.powercmsRestore();
            }
        });
    });
});


})(jQuery);


jQuery(function($) {
    $('textarea.editor').each(function() {
        var id = this.id;
        if (! id) {
            id = this.id = this.name;
        }
        new MT.EditorManager(id);
    });
});
